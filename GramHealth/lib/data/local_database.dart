import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Centralized Offline-First Database instance.
/// Mirrors the core backend tables by storing raw JSON payloads (data TEXT)
/// to ensure robust, flexible offline reconstruction without schema migrations.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gramhealth_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_doctors(
          id TEXT PRIMARY KEY,
          data TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_records(
          id TEXT PRIMARY KEY,
          data TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_pharmacies(
          id TEXT PRIMARY KEY,
          data TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await _createChatTables(db);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    /// Holds mutating operations [POST, PATCH, DELETE] when offline.
    await db.execute('''
      CREATE TABLE sync_queue(
        id TEXT PRIMARY KEY,
        entity_type TEXT,
        operation TEXT,
        endpoint TEXT,
        payload TEXT,
        created_at TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_consultations(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_prescriptions(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_users(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_doctors(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cached_records(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_pharmacies(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    await _createChatTables(db);
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_conversations(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages(
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        text TEXT NOT NULL,
        sender TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_offline INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_updated
      ON chat_conversations(user_id, updated_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_timestamp
      ON chat_messages(conversation_id, timestamp ASC)
    ''');
  }

  // ── Sync Queue Helpers ──

  Future<void> enqueueSync({
    required String id,
    required String entityType,
    required String operation,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final db = await instance.database;
    await db.insert(
      'sync_queue',
      {
        'id': id,
        'entity_type': entityType,
        'operation': operation,
        'endpoint': endpoint,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await instance.database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeSyncItem(String id) async {
    final db = await instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(String id, int currentCount) async {
    final db = await instance.database;
    await db.update(
      'sync_queue',
      {'retry_count': currentCount + 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Generic caching Helpers ──

  Future<void> cacheData(String table, String id, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert(
      table,
      {'id': id, 'data': jsonEncode(data)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedData(String table, String id) async {
    final db = await instance.database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return jsonDecode(results.first['data'] as String);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllCachedData(String table) async {
    final db = await instance.database;
    final results = await db.query(table);
    return results.map((e) => jsonDecode(e['data'] as String) as Map<String, dynamic>).toList();
  }
}
