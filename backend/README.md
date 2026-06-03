# DateWise AI — Photo Coach backend (Cloudflare Worker)

This tiny Worker is the secure proxy for the **AI Photo Coach**. It holds the
Gemini API key server-side and exposes one POST endpoint the app calls. The key
is never shipped to the browser.

## 1. Get a free Gemini API key
1. Go to <https://aistudio.google.com/app/apikey>
2. **Create API key** → copy it.

## 2. Create the Worker (no CLI needed)
1. Go to <https://dash.cloudflare.com> → **Workers & Pages** → **Create** → **Create Worker**.
2. Give it a name, e.g. `datewise-photo-coach`, and **Deploy** the starter.
3. Click **Edit code**, delete the sample, paste the contents of [`worker.js`](worker.js), and **Deploy**.

## 3. Add your key as a secret
1. Worker → **Settings** → **Variables and Secrets**.
2. **Add** → type **Secret** → name **`GEMINI_API_KEY`**, value = the key from step 1 → **Save and deploy**.

## 4. Copy the Worker URL
It looks like `https://datewise-photo-coach.<your-subdomain>.workers.dev`.

## 5. Point the app at it
The URL is public (not a secret), so either:

- **Easiest:** paste it into `lib/services/ai_config.dart` →
  `_inlinePhotoCoachUrl = 'https://....workers.dev';`, commit, push. The GitHub
  Action rebuilds and the photo coach goes live for Magnet users.
- **Or** pass it at build time:
  `flutter build web --release --dart-define=PHOTO_COACH_URL=https://....workers.dev`

## Test it
```bash
curl -X POST https://your-worker.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"tier":"magnet","imageBase64":"<base64 jpeg>"}'
```
Returns the analysis JSON (score, verdict, dimensions, tips).

## Notes & hardening
- **Tier check is soft.** `tier` comes from the client and can be spoofed. The
  real win here is that the **key is protected**. For true paywall enforcement,
  verify a signed session / payment (e.g. Stripe) inside the Worker before
  calling Gemini.
- **Restrict origins.** In `worker.js`, set `ALLOWED_ORIGIN` to your site
  (`https://kaowserf.github.io`) instead of `*` so others can't use your Worker.
- **Cost:** Cloudflare Workers free tier = 100k requests/day. Gemini Flash has a
  generous free tier; check current limits in Google AI Studio.
- **Privacy:** the Worker forwards the image to Gemini and does **not** store it.
