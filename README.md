# DateWise AI 💗

An AI-powered dating coach built in Flutter (web · Android · iOS), implementing
the **Lumière** PRD: a premium, blush-toned coaching experience with a
three-tier subscription model, threaded AI chat, and a Magnet-tier photo coach.

## Features

- **Landing & conversion funnel** — hero, feature highlights, how-it-works,
  pricing comparison, testimonials, and CTA (PRD §5.1).
- **Tiered coaching** — Spark / Flame / Magnet, each unlocking deeper
  capabilities exactly per the PRD pricing matrix (PRD §4).
- **Threaded AI chat** — create, rename, delete conversations; persistent
  sidebar on desktop, drawer on mobile; real-time streamed replies in Lumière's
  voice (PRD §5.2, §5.4, §8).
- **AI Photo Coach (Magnet)** — upload a photo, get a 1-10 score, a
  KEEP / RESHOOT / DELETE verdict, per-dimension critique (lighting, expression,
  outfit, framing, vibe), and a predicted match-rate lift (PRD §5.3).
- **Private by design** — tier and chat history persist locally via
  `shared_preferences` (localStorage on web). No server-side storage (PRD §9).

## Architecture

```
lib/
  main.dart              app bootstrap (storage + AI + provider)
  app.dart               routing: returning users → chat, new → landing
  theme/                 Romantic Blush design system
  models/                tier (capability matrix), thread, message, photo analysis
  services/
    ai_service.dart      AIService abstraction + factory
    mock_ai_service.dart offline coach — app works with zero setup
    gemini_ai_service.dart  real Google Gemini client (used when a key is set)
    persona.dart         Lumière system prompt + tier-gated greetings
    storage_service.dart local persistence
  state/app_state.dart   provider ChangeNotifier orchestrating everything
  screens/               landing_screen, chat_screen
  widgets/               brand, pricing card, message bubble, photo card, input, sidebar
```

## AI backend

DateWise AI ships with a fully-working **offline mock coach**, so it runs
end-to-end with no API key. To use a real model (Google Gemini, per PRD §6.2),
pass a key at run time — the factory wires the real client automatically:

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key_here
```

See [lib/services/ai_config.dart](lib/services/ai_config.dart). No key is ever
committed.

## Run

```bash
flutter pub get
flutter run -d chrome      # web
flutter run                # pick a device (Android emulator, etc.)
flutter test               # unit + widget tests
```

> iOS builds require macOS + Xcode; the iOS target is scaffolded but cannot be
> built from Windows.
