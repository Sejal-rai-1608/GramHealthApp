class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final bool isOffline;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isOffline = false,
  });

  factory ChatMessage.fromDatabase(Map<String, Object?> row) {
    return ChatMessage(
      id: row['id']?.toString() ?? '',
      text: row['text']?.toString() ?? '',
      sender: row['sender']?.toString() ?? 'ai',
      timestamp: DateTime.tryParse(row['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isOffline: (row['is_offline'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toDatabase({
    required String conversationId,
    required String userId,
  }) {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'is_offline': isOffline ? 1 : 0,
    };
  }
}

class ChatConversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const ChatConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  factory ChatConversation.fromDatabase(Map<String, Object?> row) {
    return ChatConversation(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      title: row['title']?.toString() ?? 'Health chat',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      messageCount: (row['message_count'] as int?) ?? 0,
    );
  }
}
