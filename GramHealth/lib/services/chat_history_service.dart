import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/local_database.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

/// Durable, user-scoped local chat history.
///
/// Chat history intentionally lives in the offline database so conversations
/// survive app restarts and remain available when the network is unavailable.
/// Every query is scoped by the authenticated user id to prevent one account
/// from seeing another account's conversations on a shared device.
class ChatHistoryService {
  ChatHistoryService._();

  static final ChatHistoryService instance = ChatHistoryService._();
  static const _uuid = Uuid();

  Future<String> _requireUserId() async {
    final user = await AuthService.getUser();
    final rawId = user?['id'] ?? user?['userId'];
    final userId = rawId?.toString().trim() ?? '';
    if (userId.isEmpty) {
      throw StateError('Cannot access chat history without an authenticated user id.');
    }
    return userId;
  }

  String newConversationId() => _uuid.v4();

  String newMessageId() => _uuid.v4();

  String titleForMessage(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return 'Health chat';
    if (compact.length <= 48) return compact;
    return '${compact.substring(0, 48).trimRight()}…';
  }

  Future<ChatConversation> createConversation({String title = 'New health chat'}) async {
    final userId = await _requireUserId();
    final now = DateTime.now().toIso8601String();
    final conversation = ChatConversation(
      id: newConversationId(),
      userId: userId,
      title: title,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );

    final db = await LocalDatabase.instance.database;
    await db.insert('chat_conversations', {
      'id': conversation.id,
      'user_id': conversation.userId,
      'title': conversation.title,
      'created_at': now,
      'updated_at': now,
    });
    return conversation;
  }

  Future<List<ChatConversation>> listConversations() async {
    final userId = await _requireUserId();
    final db = await LocalDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.user_id, c.title, c.created_at, c.updated_at,
             COUNT(m.id) AS message_count
      FROM chat_conversations c
      LEFT JOIN chat_messages m ON m.conversation_id = c.id
      WHERE c.user_id = ?
      GROUP BY c.id, c.user_id, c.title, c.created_at, c.updated_at
      ORDER BY c.updated_at DESC
    ''', [userId]);
    return rows.map(ChatConversation.fromDatabase).toList();
  }

  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final userId = await _requireUserId();
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'chat_messages',
      where: 'conversation_id = ? AND user_id = ?',
      whereArgs: [conversationId, userId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(ChatMessage.fromDatabase).toList();
  }

  Future<void> saveMessage({
    required String conversationId,
    required ChatMessage message,
  }) async {
    final userId = await _requireUserId();
    final db = await LocalDatabase.instance.database;

    await db.transaction((txn) async {
      final conversation = await txn.query(
        'chat_conversations',
        columns: ['id'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [conversationId, userId],
        limit: 1,
      );
      if (conversation.isEmpty) {
        throw StateError('Chat conversation does not belong to the current user.');
      }

      await txn.insert(
        'chat_messages',
        message.toDatabase(conversationId: conversationId, userId: userId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final title = message.sender == 'user' ? titleForMessage(message.text) : null;
      await txn.update(
        'chat_conversations',
        {
          'updated_at': message.timestamp.toIso8601String(),
          if (title != null) 'title': title,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [conversationId, userId],
      );
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    final userId = await _requireUserId();
    final db = await LocalDatabase.instance.database;
    await db.delete(
      'chat_conversations',
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, userId],
    );
  }
}
