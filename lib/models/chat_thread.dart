import 'chat_message.dart';

/// A named conversation session with the AI coach (PRD section 5.4).
class ChatThread {
  ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  String get preview {
    final last = lastMessage;
    if (last == null) return 'New conversation';
    if (last.imageBase64 != null && last.text.isEmpty) return '📷 Photo';
    final text = last.text.replaceAll('\n', ' ').trim();
    return text.isEmpty ? 'New conversation' : text;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime(2026),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime(2026),
    messages: (json['messages'] as List? ?? [])
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}
