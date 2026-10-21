/// A summary row for a stored AI assistant conversation.
class ChatConversation {
  final String id;
  final String title;
  final DateTime lastMessageAt;
  final int messageCount;

  const ChatConversation({
    required this.id,
    required this.title,
    required this.lastMessageAt,
    required this.messageCount,
  });
}
