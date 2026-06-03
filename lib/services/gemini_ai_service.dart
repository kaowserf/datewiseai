import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/chat_message.dart';
import '../models/photo_analysis.dart';
import '../models/tier.dart';
import 'ai_service.dart';

/// Real AI coach backed by Google Gemini (PRD section 6.2 names a Gemini flash
/// model behind the Lovable AI Gateway). Wired automatically when an API key is
/// configured; otherwise the app uses [MockAIService].
class GeminiAIService implements AIService {
  GeminiAIService({
    required String apiKey,
    required String model,
    required this.systemPromptBuilder,
  })  : _apiKey = apiKey,
        _modelName = model;

  final String _apiKey;
  final String _modelName;
  final String Function(SubscriptionTier) systemPromptBuilder;

  @override
  String get providerLabel => 'Gemini ($_modelName)';

  GenerativeModel _modelFor(SubscriptionTier tier) => GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(systemPromptBuilder(tier)),
      );

  @override
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required SubscriptionTier tier,
  }) async* {
    final model = _modelFor(tier);
    final contents = history
        .where((m) => m.text.trim().isNotEmpty || m.imageBase64 != null)
        .map(_toContent)
        .toList();

    try {
      final stream = model.generateContentStream(contents);
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } catch (e) {
      yield "I hit a snag reaching my brain just now. Mind trying that again in a moment?";
    }
  }

  Content _toContent(ChatMessage m) {
    final role = m.isUser ? 'user' : 'model';
    final parts = <Part>[];
    if (m.imageBase64 != null) {
      parts.add(DataPart('image/jpeg', base64Decode(m.imageBase64!)));
    }
    if (m.text.trim().isNotEmpty) {
      parts.add(TextPart(m.text));
    }
    if (parts.isEmpty) parts.add(TextPart(' '));
    return Content(role, parts);
  }

  @override
  Future<PhotoAnalysis> analyzePhoto({
    required String imageBase64,
    required SubscriptionTier tier,
    String? userNote,
  }) async {
    final model = _modelFor(tier);
    final prompt = '''
Analyse this dating-profile photo as DateWise AI. Respond with ONLY valid JSON, no
markdown, matching exactly this shape:
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
}
${userNote != null && userNote.isNotEmpty ? 'User note: $userNote' : ''}''';

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', base64Decode(imageBase64)),
      ]),
    ]);

    final raw = (response.text ?? '').trim();
    final jsonStr = _extractJson(raw);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PhotoAnalysis.fromJson(map);
  }

  /// Strips ```json fences or surrounding prose the model may add.
  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return raw;
    return raw.substring(start, end + 1);
  }
}
