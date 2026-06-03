/// Configuration for the AI backend.
///
/// DateWise AI ships with a fully-working **mock** coach so the app runs
/// end-to-end with zero setup. To use a real model (Google Gemini, as named in
/// the PRD), drop your key here — or, preferably, pass it at build/run time:
///
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///
/// When a non-empty key is present, [AIServiceFactory] wires the real Gemini
/// client; otherwise it falls back to the mock. No key is ever committed.
class AIConfig {
  AIConfig._();

  /// Read from a --dart-define first (recommended), then any inline fallback.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: _inlineKey,
  );

  /// Optional inline key for quick local testing. Leave empty for production.
  static const String _inlineKey = '';

  /// Model id from the PRD's spirit (latest fast Gemini flash model).
  static const String geminiModel = 'gemini-1.5-flash';

  static bool get hasRealProvider => geminiApiKey.trim().isNotEmpty;
}
