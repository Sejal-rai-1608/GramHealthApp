/// Role constants for a persisted chat turn.
class ChatRole {
  static const String user = 'user';
  static const String assistant = 'assistant';

  const ChatRole._();
}

/// A single persisted chat turn between the patient and the GramHealth AI.
///
/// [content] always holds the *raw* assistant answer. The emergency banner
/// and the "consult a professional" notice are display decorations that are
/// applied when the bubble is rendered, never written into [content]. That
/// keeps a message reloaded from the local database byte-identical to the
/// version that was first shown, and prevents the decorations from being
/// duplicated on every reload.
class ChatMessage {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;
  final bool isOffline;
  final String? urgency;
  final String? intent;
  final String? routingMethod;
  final bool requiresProfessionalReview;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isOffline = false,
    this.urgency,
    this.intent,
    this.routingMethod,
    this.requiresProfessionalReview = false,
  });

  bool get isUser => role == ChatRole.user;

  factory ChatMessage.fromRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'] as String? ?? '',
      conversationId: row['conversation_id'] as String? ?? '',
      role: row['role'] as String? ?? ChatRole.assistant,
      content: row['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      isOffline: (row['is_offline'] as int? ?? 0) == 1,
      urgency: row['urgency'] as String?,
      intent: row['intent'] as String?,
      routingMethod: row['routing_method'] as String?,
      requiresProfessionalReview: (row['requires_review'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toRow() {
    return <String, dynamic>{
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'is_offline': isOffline ? 1 : 0,
      'urgency': urgency,
      'intent': intent,
      'routing_method': routingMethod,
      'requires_review': requiresProfessionalReview ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Compact wire format sent to the backend as conversation context.
  Map<String, dynamic> toContextJson() {
    return <String, dynamic>{'role': role, 'content': content};
  }
}
