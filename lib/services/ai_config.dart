/// Configuration for the AI backend.
///
/// DateWise AI ships with a fully-working **mock** coach so the app runs
/// end-to-end with zero setup.
///
/// The premium **AI Photo Coach** calls a secure backend (a Cloudflare Worker —
/// see `backend/worker.js`) that holds the Gemini key server-side. The app only
/// knows the Worker's public URL; the key is never shipped to the browser.
///
/// Set the URL at build/run time (recommended):
///   flutter run --dart-define=PHOTO_COACH_URL=https://your-worker.workers.dev
/// or paste it into [_inlinePhotoCoachUrl] below (the URL is not a secret).
class AIConfig {
  AIConfig._();

  // --- Secure photo-coach backend (Cloudflare Worker) ---------------------

  /// Public URL of the photo-coach Worker. Read from a --dart-define first,
  /// then any inline fallback. When empty, the photo coach uses the mock.
  static const String photoCoachUrl = String.fromEnvironment(
    'PHOTO_COACH_URL',
    defaultValue: _inlinePhotoCoachUrl,
  );

  /// Paste your deployed Worker URL here (safe to commit — not a secret).
  static const String _inlinePhotoCoachUrl =
      'https://datewise-photo-coach.kaowserprobd.workers.dev';

  static bool get hasPhotoCoachBackend => photoCoachUrl.trim().isNotEmpty;

  // --- Optional direct (client-side) Gemini key ---------------------------
  // NOTE: a key shipped in the web build is publicly visible. Prefer the
  // backend above for anything real. This exists only for quick local tests.

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: _inlineKey,
  );
  static const String _inlineKey = '';
  static const String geminiModel = 'gemini-2.0-flash';

  static bool get hasClientGeminiKey => geminiApiKey.trim().isNotEmpty;
}
