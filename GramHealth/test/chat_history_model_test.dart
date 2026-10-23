import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare_flutter/models/chat_message.dart';
import 'package:ruralcare_flutter/services/chat_history_service.dart';

void main() {
  test('ChatMessage database serialization preserves the chat payload', () {
    final original = ChatMessage(
      id: 'message-1',
      text: 'I have a headache',
      sender: 'user',
      timestamp: DateTime.parse('2026-10-23T10:15:00.000Z'),
      isOffline: true,
    );

    final restored = ChatMessage.fromDatabase(
      original.toDatabase(
        conversationId: 'conversation-1',
        userId: 'user-1',
      ),
    );

    expect(restored.id, original.id);
    expect(restored.text, original.text);
    expect(restored.sender, original.sender);
    expect(restored.timestamp, original.timestamp);
    expect(restored.isOffline, isTrue);
  });

  test('chat titles are compact and bounded', () {
    final service = ChatHistoryService.instance;

    expect(service.titleForMessage('  fever   and headache  '), 'fever and headache');
    expect(service.titleForMessage(''), 'Health chat');
    expect(service.titleForMessage('a' * 60), '${'a' * 48}…');
  });
}
