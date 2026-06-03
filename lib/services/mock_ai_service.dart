import 'dart:async';

import '../models/chat_message.dart';
import '../models/photo_analysis.dart';
import '../models/tier.dart';
import 'ai_service.dart';

/// Offline, deterministic coach that lets DateWise AI run end-to-end with no
/// API key. It keys off intent in the user's latest message and answers in
/// DateWise AI's voice, respecting tier capabilities (PRD section 8 + tier matrix).
///
/// Replies are streamed word-by-word to mimic the real-time streaming UX.
class MockAIService implements AIService {
  @override
  String get providerLabel => 'DateWise AI (offline demo)';

  // Pseudo-randomness without dart:math global state surprises — varies by
  // message length so repeated identical asks don't read identically.
  int _seedFrom(String s) => s.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0xffff);

  @override
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required SubscriptionTier tier,
  }) async* {
    final lastUser = history.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(
        id: 'x',
        role: MessageRole.user,
        text: '',
        createdAt: DateTime(2026),
      ),
    );
    final reply = _composeReply(lastUser, tier, history);

    // Stream word-by-word with a small delay for a live-typing feel.
    final words = reply.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 22));
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }

  String _composeReply(
    ChatMessage userMsg,
    SubscriptionTier tier,
    List<ChatMessage> history,
  ) {
    final info = TierInfo.of(tier);
    final text = userMsg.text.toLowerCase();

    // Photo sent but not on Magnet → gate it.
    if (userMsg.imageBase64 != null && !info.can(Capability.photoCoach)) {
      return _upsell(
        'photo coaching',
        tier,
        teaser:
            "I can see you want eyes on a photo — that's my **AI Photo Coach**, "
            "and it lives on **Magnet**. Quick freebie though: the strongest "
            "main photo is a **clear, well-lit shot of just you, smiling, eyes "
            "to camera**. No sunglasses, no group, no hat.",
      );
    }

    if (_matches(text, ['bio', 'about me', 'rewrite my profile', 'prompt'])) {
      return _bioRewrite(tier);
    }
    if (_matches(text, [
      'opener',
      'opening line',
      'first message',
      'what do i say',
      'how to start',
    ])) {
      return _openers(tier);
    }
    if (_matches(text, ['ghost', 'stopped replying', 'left me on read'])) {
      return info.can(Capability.conversationScripts)
          ? _ghosting()
          : _upsell('ghosting recovery scripts', tier);
    }
    if (_matches(text, ['date', 'where should we go', 'plan a date'])) {
      return info.can(Capability.datePlanning)
          ? _datePlan(text)
          : _upsell('date planning', tier);
    }
    if (_matches(text, ['photo', 'picture', 'pics', 'headshot', 'selfie'])) {
      return info.can(Capability.photoCoach)
          ? _photoInvite()
          : _upsell('photo coaching', tier);
    }
    if (_matches(text, ['review', 'is this message ok', 'should i send'])) {
      return info.can(Capability.messageReviews)
          ? _messageReview()
          : _upsell('message reviews', tier);
    }
    if (_matches(text, ['audit', 'roast', 'feedback on my profile', 'rate my profile'])) {
      return _audit(tier);
    }
    if (_matches(text, ['tip', 'advice', 'daily'])) {
      return _dailyTip();
    }

    // First contact / unknown → orient + one sharp question.
    if (history.where((m) => m.isUser).length <= 1) {
      return _onboard(userMsg, tier);
    }
    return _general(userMsg, tier);
  }

  bool _matches(String text, List<String> needles) =>
      needles.any(text.contains);

  String _onboard(ChatMessage userMsg, SubscriptionTier tier) {
    final t = userMsg.text.trim();
    final app = _detectApp(t);
    final appLine = app != null
        ? "**$app** — great, that changes the playbook. "
        : "";
    return "${appLine}Love it, let's get to work. 💫\n\n"
        "To make my advice land, tell me three fast things:\n"
        "• **Your goal** — serious, casual, or just more matches?\n"
        "• **Your vibe** in real life (funny / sincere / adventurous / chill)?\n"
        "• **One thing** about your current profile you already suspect is weak.\n\n"
        "Answer those and I'll come back with something you can paste in tonight.";
  }

  String? _detectApp(String text) {
    final t = text.toLowerCase();
    if (t.contains('hinge')) return 'Hinge';
    if (t.contains('tinder')) return 'Tinder';
    if (t.contains('bumble')) return 'Bumble';
    if (t.contains('raya')) return 'Raya';
    return null;
  }

  String _bioRewrite(SubscriptionTier tier) {
    return "Here's a full rewrite — punchy, specific, and built to earn a reply. "
        "Paste this as your bio:\n\n"
        "> Probably over-researching our first coffee spot as we speak. "
        "Weekends are trail runs, a stubborn sourdough starter named Kevin, and "
        "finding the city's best taco. **Tell me your hill to die on — pineapple "
        "on pizza counts.**\n\n"
        "Why it works:\n"
        "• **Concrete details** (Kevin, tacos) > adjectives like \"fun\" or \"easygoing.\"\n"
        "• Ends on a **playful prompt** so matches have an obvious way in.\n"
        "• Reads warm, a little witty, never try-hard.\n\n"
        "Want me to spin a **second version** in a more sincere tone, or tailor "
        "this to a specific app?";
  }

  String _openers(SubscriptionTier tier) {
    return "Skip \"hey\" — here are three copy-paste openers, ranked. "
        "Pick the one that matches their energy:\n\n"
        "1. **Playful:** \"Be honest — is your dog the one screening my messages?\"\n"
        "2. **Specific:** \"That ramen photo is dangerous. Settle a debate: "
        "broth-first or noodles-first?\"\n"
        "3. **Direct & warm:** \"You seem genuinely interesting and I'd kick "
        "myself for a boring opener — what's been the best part of your week?\"\n\n"
        "Rule of thumb: **reference one specific thing** from their profile in "
        "the first line. Who are you messaging — want me to tailor these to their photos or prompts?";
  }

  String _ghosting() {
    return "Ghosted? Don't spiral — one clean re-engage, then you move on. 🔥\n\n"
        "Send this **once**:\n"
        "> \"Taking your silence as a sign you got swept into something good. "
        "If not — I still owe you that taco debate. 🌮\"\n\n"
        "• **Light, zero guilt-trip**, gives them an easy on-ramp back.\n"
        "• If no reply in a few days, **close the tab and reinvest** that energy.\n\n"
        "Want a slightly warmer version, or one with a touch more edge?";
  }

  String _datePlan(String text) {
    return "Let's design a date that does the work for you. ✨\n\n"
        "**The formula:** low-pressure + a built-in conversation engine + an "
        "easy exit *or* extend.\n\n"
        "• **Plan A:** A walkable specialty coffee spot, then a nearby bookshop "
        "or market. Movement = natural pauses, no awkward staring across a table.\n"
        "• **Plan B (if it's clicking):** Pivot to a wine bar with small plates.\n\n"
        "Text to lock it in:\n"
        "> \"There's a tiny coffee place I've been wanting to try Saturday — "
        "good people-watching and an easy escape if I turn out to be boring. You in?\"\n\n"
        "**What city are you in?** I'll name specific spots.";
  }

  String _photoInvite() {
    return "Yes — let's get your photos *working* for you. 📸\n\n"
        "Tap the **photo icon** below (or drag one in) and I'll score it "
        "**1-10**, give you a **KEEP / RESHOOT / DELETE** verdict, and break "
        "down lighting, expression, outfit, framing, and overall vibe — plus "
        "the match-rate lift if you fix it.\n\n"
        "**Start with your main profile photo** — that's the one doing 80% of "
        "the work.";
  }

  String _messageReview() {
    return "Drop the message and I'll give you a verdict + a tightened version. "
        "Here's how I'll score it:\n\n"
        "• **Spark** — does it invite a reply or dead-end?\n"
        "• **Length** — under ~3 sentences early on.\n"
        "• **Subtext** — confident, not needy.\n\n"
        "Paste exactly what you were about to send (and a line of context), and "
        "I'll tell you **send / tweak / scrap** with the fix.";
  }

  String _audit(SubscriptionTier tier) {
    final extra = TierInfo.of(tier).can(Capability.photoCoach)
        ? "\n\nAnd since you're on **Magnet** — upload your main photo and I'll "
            "score it 1-10 with a KEEP / RESHOOT / DELETE call."
        : "";
    return "Profile audit time — here's my checklist. Tell me how each one lands "
        "and we'll fix the weakest first:\n\n"
        "1. **Lead photo** — clear face, real smile, you alone? (This is 80% of it.)\n"
        "2. **Photo set** — one full-body, one \"in your element,\" one social proof. No 4 selfies.\n"
        "3. **Bio** — specific and a little funny, ends with a hook.\n"
        "4. **Prompts** — story or opinion, never \"just ask 😊.\"\n\n"
        "**Which one feels weakest to you right now?** That's where we start.$extra";
  }

  String _dailyTip() {
    return "**Today's tip:** Your second photo is doing more work than you think. 📸\n\n"
        "Make it a **full-body shot in motion** — walking, laughing, mid-activity. "
        "It answers the silent question every match asks after your face: "
        "*\"what's their actual vibe?\"*\n\n"
        "Swap it tonight and watch your reply rate. Want tomorrow's tip queued up too?";
  }

  String _general(ChatMessage userMsg, SubscriptionTier tier) {
    return "Got it. Here's my read, no hedging:\n\n"
        "The move is to make your profile **specific and a little brave** — "
        "generic is the only real mistake out here. Give me the concrete detail "
        "(the app, who you're after, the moment that stalled) and I'll hand you "
        "**exact words** to use.\n\n"
        "So — **what's the one situation you want to crack first?**";
  }

  String _upsell(String feature, SubscriptionTier tier, {String? teaser}) {
    final next = tier == SubscriptionTier.spark
        ? TierInfo.flame
        : TierInfo.magnet;
    final body = teaser ??
        "That's **$feature** — it unlocks on **${next.name}** "
            "(${next.priceLabel}/wk).";
    return "$body\n\n"
        "Here's what I *can* do for you right now, and it's plenty: tighten your "
        "bio, hand you opener lines, and audit your profile. Want to start there — "
        "or jump to **${next.name}** for the full toolkit?";
  }

  @override
  Future<PhotoAnalysis> analyzePhoto({
    required String imageBase64,
    required SubscriptionTier tier,
    String? userNote,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // Deterministic-but-varied score derived from the image payload so the
    // same photo always scores the same, but different photos differ.
    final seed = _seedFrom(imageBase64.length.toString() + imageBase64.substring(0, imageBase64.length.clamp(0, 24)));
    final overall = 5 + (seed % 5); // 5..9
    final verdict = PhotoVerdict.fromScore(overall);

    return PhotoAnalysis(
      overallScore: overall,
      verdict: verdict,
      headline: _verdictHeadline(verdict, overall),
      matchRateDelta: 8 + (seed % 18), // +8..+25
      dimensions: [
        PhotoDimension(
          name: 'Lighting',
          score: (overall - 1).clamp(1, 10),
          note: overall >= 8
              ? 'Soft, flattering, front-lit. Keep it.'
              : 'A touch flat — shoot near a window in soft daylight for more depth.',
        ),
        PhotoDimension(
          name: 'Expression',
          score: overall.clamp(1, 10),
          note: overall >= 7
              ? 'Genuine, approachable smile that reaches the eyes.'
              : 'Reads a little guarded — try laughing at something off-camera.',
        ),
        PhotoDimension(
          name: 'Outfit',
          score: (overall - 2).clamp(1, 10),
          note: 'Fit is fine; one pop of color would make you stand out in the grid.',
        ),
        PhotoDimension(
          name: 'Framing',
          score: (seed % 4) + 5,
          note: overall >= 8
              ? 'Clean composition, uncluttered background.'
              : 'Crop tighter to the chest-up and lose the busy background.',
        ),
        PhotoDimension(
          name: 'Overall vibe',
          score: overall.clamp(1, 10),
          note: 'Signals warmth; we can push it from "nice" to "magnetic."',
        ),
      ],
      tips: _verdictTips(verdict),
    );
  }

  String _verdictHeadline(PhotoVerdict verdict, int score) {
    switch (verdict) {
      case PhotoVerdict.keep:
        return 'Strong main-photo material — this earns the right swipe.';
      case PhotoVerdict.reshoot:
        return 'Good bones, but a quick reshoot turns this from skippable to scroll-stopping.';
      case PhotoVerdict.delete:
        return 'This one\'s working against you — cut it and we\'ll replace it.';
    }
  }

  List<String> _verdictTips(PhotoVerdict verdict) {
    switch (verdict) {
      case PhotoVerdict.keep:
        return [
          'Make this your **lead photo** if it isn\'t already.',
          'Pair it with a full-body action shot in slot two.',
          'Don\'t over-edit — the authenticity is the asset.',
        ];
      case PhotoVerdict.reshoot:
        return [
          'Reshoot in **soft daylight** near a window or in open shade.',
          'Crop **chest-up** with eyes to camera.',
          'Add one warm color and a real, off-camera laugh.',
        ];
      case PhotoVerdict.delete:
        return [
          'Replace with a **clear solo shot** — no group, hat, or sunglasses.',
          'Prioritise a genuine smile over a posed one.',
          'Keep the background simple so *you* are the subject.',
        ];
    }
  }
}
