import 'photo_analysis.dart';

enum MessageRole { user, coach }

/// A single message within a coaching thread.
///
/// A message may carry an attached photo (base64, for the Magnet photo coach)
/// and/or a structured [PhotoAnalysis] result rendered as a rich card.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.imageBase64,
    this.analysis,
    this.isStreaming = false,
  });

  final String id;
  final MessageRole role;
  String text;
  final DateTime createdAt;

  /// Base64-encoded image bytes attached by the user (no data: prefix).
  final String? imageBase64;

  /// Structured photo-coach result attached to a coach message.
  final PhotoAnalysis? analysis;

  /// True while the coach reply is still streaming in.
  bool isStreaming;

  bool get isUser => role == MessageRole.user;

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'imageBase64': imageBase64,
    'analysis': analysis?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: MessageRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => MessageRole.coach,
    ),
    text: json['text'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime(2026),
    imageBase64: json['imageBase64'] as String?,
    analysis: json['analysis'] == null
        ? null
        : PhotoAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
  );
}
