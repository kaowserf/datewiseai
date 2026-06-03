/**
 * DateWise AI — Photo Coach backend (Cloudflare Worker).
 *
 * FREE TEST VERSION: uses Cloudflare Workers AI (built-in, free daily quota,
 * no API key needed) with a Llama 3.2 Vision model. Requires an "AI" binding on
 * the Worker (Settings → Bindings → Workers AI → variable name: AI).
 *
 * Request  (POST, JSON): { imageBase64, tier, userNote? }
 * Response (JSON): a PhotoAnalysis object matching the Flutter model.
 */

const MODEL = '@cf/llava-hf/llava-1.5-7b-hf';
const ALLOWED_ORIGIN = '*'; // lock to 'https://kaowserf.github.io' in production

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  });
}

const PROMPT = `You are DateWise AI, an elite, brutally honest dating coach.
Analyse this dating-profile photo. Reply with ONLY valid JSON (no markdown, no
commentary) in exactly this shape:
{
  "overallScore": <int 1-10>,
  "verdict": "KEEP" | "RESHOOT" | "DELETE",
  "headline": "<one punchy sentence>",
  "matchRateDelta": <int, predicted % match-rate change if tips applied>,
  "dimensions": [
    {"name":"Lighting","score":<1-10>,"note":"<short>"},
    {"name":"Expression","score":<1-10>,"note":"<short>"},
    {"name":"Outfit","score":<1-10>,"note":"<short>"},
    {"name":"Framing","score":<1-10>,"note":"<short>"},
    {"name":"Overall vibe","score":<1-10>,"note":"<short>"}
  ],
  "tips": ["<actionable>", "<actionable>", "<actionable>"]
}`;

// Decodes a base64 string to a plain array of byte values (what Workers AI wants).
function base64ToBytes(b64) {
  const bin = atob(b64);
  const arr = new Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }
    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }
    if (!env.AI) {
      return json(
        { error: 'Workers AI binding "AI" is not configured on this Worker.' },
        500,
      );
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Invalid JSON body' }, 400);
    }

    const { imageBase64, tier, userNote } = body || {};

    // Soft tier gate (client-sent; for real paywalls verify a session/payment).
    if (tier !== 'magnet') {
      return json({ error: 'The AI Photo Coach is a Magnet-tier feature.' }, 403);
    }
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      return json({ error: 'Missing imageBase64' }, 400);
    }

    let result;
    try {
      result = await env.AI.run(MODEL, {
        image: base64ToBytes(imageBase64),
        prompt: userNote ? `${PROMPT}\nUser note: ${userNote}` : PROMPT,
        max_tokens: 700,
      });
    } catch (e) {
      return json({ error: 'Workers AI error', detail: String(e) }, 502);
    }

    const text = (result && (result.response ?? result.description)) || '';
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start === -1 || end === -1) {
      return json({ error: 'Model returned no JSON', raw: text }, 502);
    }

    let analysis;
    try {
      analysis = JSON.parse(text.slice(start, end + 1));
    } catch {
      return json({ error: 'Could not parse model JSON', raw: text }, 502);
    }
    return json(analysis, 200);
  },
};
