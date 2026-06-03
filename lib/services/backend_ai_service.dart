import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/photo_analysis.dart';
import '../models/tier.dart';
import 'ai_service.dart';

/// Routes the premium **AI Photo Coach** through a secure backend (a Cloudflare
/// Worker that holds the Gemini key server-side), while delegating chat replies
/// to [chatFallback] (the offline mock by default).
///
/// This keeps the API key out of the web build entirely — the app only knows
/// the Worker's public URL.
class BackendAIService implements AIService {
  BackendAIService({required this.endpoint, required this.chatFallback});

  final String endpoint;
  final AIService chatFallback;

  @override
  String get providerLabel => 'Gemini · secure backend';

  // Chat stays on the fallback (the photo coach is the premium real-AI piece).
  @override
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required SubscriptionTier tier,
  }) =>
      chatFallback.streamReply(history: history, tier: tier);

  @override
  Future<PhotoAnalysis> analyzePhoto({
    required String imageBase64,
    required SubscriptionTier tier,
    String? userNote,
  }) async {
    final res = await http
        .post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'imageBase64': imageBase64,
            'mimeType': 'image/jpeg',
            'tier': tier.name,
            if (userNote != null && userNote.isNotEmpty) 'userNote': userNote,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode != 200) {
      throw Exception(
        'Photo coach backend error (${res.statusCode}): ${res.body}',
      );
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return PhotoAnalysis.fromJson(map);
  }
}
