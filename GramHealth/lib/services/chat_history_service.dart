import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

/// Persists AI assistant conversations in the offline-first SQLite cache.
///
/// Without this, the chatbot transcript only lives in the widget state of
/// `ChatBotScreen` and is destroyed the moment the user navigates back to
/// another screen. With it, the transcript survives navigation, app restarts
/// and re-logins (scoped per user id), and the trailing turns can be handed
/// back to the backend so the assistant answers with conversational context.
class ChatHistoryService {
  static final ChatHistoryService instance = ChatHistoryService._init();
  ChatHistoryService._init();

  /// Maximum number of messages retained per conversation. Older messages are
  /// dropped oldest-first so the local database cannot grow without bound on
  /// a low-end device.
  static const int maxMessagesPerConversation = 500;

  /// Number of trailing messages handed to the backend as conversation
  /// context. Kept small on purpose: the backend bills per token and the
  /// offline device has to stay responsive.
  static const int contextWindowSize = 12;

  String? _activeConversationId;

  Future<String?> _currentUserId() async {
    final user = await AuthService.getUser();
    final id = user?['id'] as String?;
    return (id == null || id.isEmpty) ? null : id;
  }

  /// Returns the active conversation id, creating a conversation on first use.
  Future<String> activeConversationId() async {
    if (_activeConversationId != null) return _activeConversationId!;

    final db = await LocalDatabase.instance.database;
    final userId = await _currentUserId();

    final rows = await db.query(
      LocalDatabase.conversationsTable,
      where: userId == null ? null : 'user_id = ?',
      whereArgs: userId == null ? null : <Object?>[userId],
      orderBy: 'last_message_at DESC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      _activeConversationId = rows.first['id'] as String;
      return _activeConversationId!;
    }

    _activeConversationId = await _insertConversation(db, userId);
    return _activeConversationId!;
  }

  Future<String> _insertConversation(Database db, String? userId) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.insert(
      LocalDatabase.conversationsTable,
      <String, dynamic>{
        'id': id,
        'user_id': userId,
        'title': null,
        'created_at': now,
        'last_message_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  /// Loads every stored message of a conversation in chronological order.
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      LocalDatabase.chatMessagesTable,
      where: 'conversation_id = ?',
      whereArgs: <Object?>[conversationId],
      orderBy: 'created_at ASC, rowid ASC',
    );
    return rows.map(ChatMessage.fromRow).toList();
  }

  /// Persists a single turn and bumps the conversation timestamp.
  Future<void> saveMessage(ChatMessage message) async {
    final db = await LocalDatabase.instance.database;
    final userId = await _currentUserId();

    final row = message.toRow();
    row['user_id'] = userId;

    await db.insert(
      LocalDatabase.chatMessagesTable,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.update(
      LocalDatabase.conversationsTable,
      <String, dynamic>{
        'last_message_at': message.createdAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[message.conversationId],
    );

    await _trimConversation(db, message.conversationId);
  }

  /// Returns the trailing messages of a conversation, oldest first, ready to be
  /// sent as assistant context.
  Future<List<ChatMessage>> contextMessages(String conversationId) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      LocalDatabase.chatMessagesTable,
      where: 'conversation_id = ?',
      whereArgs: <Object?>[conversationId],
      orderBy: 'created_at DESC, rowid DESC',
      limit: contextWindowSize,
    );
    return rows.reversed.map(ChatMessage.fromRow).toList();
  }

  /// Starts a fresh conversation. The previous transcript stays on disk so the
  /// user can come back to it later.
  Future<String> startNewConversation() async {
    final db = await LocalDatabase.instance.database;
    final userId = await _currentUserId();
    _activeConversationId = await _insertConversation(db, userId);
    return _activeConversationId!;
  }

  /// Switches the active conversation and returns its stored messages.
  Future<List<ChatMessage>> openConversation(String conversationId) async {
    _activeConversationId = conversationId;
    return loadMessages(conversationId);
  }

  /// Lists every stored conversation for the current user, most recent first.
  /// The title is taken from the first question the user asked in that
  /// conversation so the list stays recognisable.
  Future<List<ChatConversation>> listConversations() async {
    final db = await LocalDatabase.instance.database;
    final userId = await _currentUserId();

    final where = userId == null ? '' : 'WHERE c.user_id = ?';
    final args = <Object?>[ChatRole.user];
    if (userId != null) args.add(userId);

    final rows = await db.rawQuery(
      '''
      SELECT c.id AS id,
             c.last_message_at AS last_message_at,
             (SELECT m.content FROM ${LocalDatabase.chatMessagesTable} m
               WHERE m.conversation_id = c.id AND m.role = ?
               ORDER BY m.created_at ASC, m.rowid ASC LIMIT 1) AS first_question,
             (SELECT COUNT(*) FROM ${LocalDatabase.chatMessagesTable} m
               WHERE m.conversation_id = c.id) AS message_count
      FROM ${LocalDatabase.conversationsTable} c
      $where
      ORDER BY c.last_message_at DESC
      ''',
      args,
    );

    return rows.map((row) {
      final question = (row['first_question'] as String? ?? '').trim();
      return ChatConversation(
        id: row['id'] as String,
        title: question.isEmpty ? 'Health conversation' : question,
        lastMessageAt:
            DateTime.tryParse(row['last_message_at'] as String? ?? '') ??
                DateTime.now(),
        messageCount: (row['message_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// Deletes a conversation and all of its messages.
  Future<void> deleteConversation(String conversationId) async {
    final db = await LocalDatabase.instance.database;
    await db.delete(
      LocalDatabase.chatMessagesTable,
      where: 'conversation_id = ?',
      whereArgs: <Object?>[conversationId],
    );
    await db.delete(
      LocalDatabase.conversationsTable,
      where: 'id = ?',
      whereArgs: <Object?>[conversationId],
    );
    if (_activeConversationId == conversationId) _activeConversationId = null;
  }

  /// Drops the in-memory handle so the next read resolves the conversation
  /// from the database again. Used after a logout.
  void reset() {
    _activeConversationId = null;
  }

  Future<void> _trimConversation(Database db, String conversationId) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${LocalDatabase.chatMessagesTable} WHERE conversation_id = ?',
            <Object?>[conversationId],
          ),
        ) ??
        0;

    if (count <= maxMessagesPerConversation) return;

    final excess = count - maxMessagesPerConversation;
    final oldest = await db.query(
      LocalDatabase.chatMessagesTable,
      columns: <String>['id'],
      where: 'conversation_id = ?',
      whereArgs: <Object?>[conversationId],
      orderBy: 'created_at ASC, rowid ASC',
      limit: excess,
    );
    if (oldest.isEmpty) return;

    final ids = oldest.map((r) => r['id']).toList();
    final placeholders = List<String>.filled(ids.length, '?').join(',');
    await db.delete(
      LocalDatabase.chatMessagesTable,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
}
