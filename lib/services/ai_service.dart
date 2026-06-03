import '../models/chat_message.dart';
import '../models/photo_analysis.dart';
import '../models/tier.dart';
import 'ai_config.dart';
import 'gemini_ai_service.dart';
import 'mock_ai_service.dart';
import 'persona.dart';

/// Abstraction over the AI coach so the UI never depends on a concrete
/// provider. The real Gemini client and the offline mock both implement this.
abstract class AIService {
  /// Streams the coach's reply token-by-token for real-time rendering
  /// (PRD non-functional requirement: responses stream in real-time).
  ///
  /// [history] is the full thread (oldest first), with the latest user message
  /// already appended. [tier] gates which capabilities the coach will use.
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required SubscriptionTier tier,
  });

  /// Analyses an uploaded photo (Magnet tier only). Returns a structured
  /// score/verdict/feedback result.
  Future<PhotoAnalysis> analyzePhoto({
    required String imageBase64,
    required SubscriptionTier tier,
    String? userNote,
  });

  /// Human-readable provider label for diagnostics / settings.
  String get providerLabel;
}

/// Decides which [AIService] implementation to use based on [AIConfig].
class AIServiceFactory {
  static AIService create() {
    if (AIConfig.hasRealProvider) {
      return GeminiAIService(
        apiKey: AIConfig.geminiApiKey,
        model: AIConfig.geminiModel,
        systemPromptBuilder: CoachPersona.systemPrompt,
      );
    }
    return MockAIService();
  }
}
