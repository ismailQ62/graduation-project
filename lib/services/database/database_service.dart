import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lorescue.db');

    print("Database Path: $path");

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      nationalId TEXT NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      senderId TEXT NOT NULL,
      receiverId TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      isRead INTEGER NOT NULL DEFAULT 0,
      channelId INTEGER NOT NULL DEFAULT 1,
      type TEXT NOT NULL
    )
  ''');

    // NOTE: no AUTOINCREMENT to allow manual ID for static channels
    await db.execute('''
    CREATE TABLE IF NOT EXISTS channels (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL
    )
  ''');

    // Insert default channels with fixed IDs
    final existing = await db.query('channels');
    final existingIds = existing.map((e) => e['id']).toList();

    if (!existingIds.contains(1)) {
      await db.insert('channels', {'id': 1, 'name': 'Main Channel'});
    }
    if (!existingIds.contains(2)) {
      await db.insert('channels', {'id': 2, 'name': 'News Channel'});
    }
  }

  Future<void> insertMessage({
    required String sender,
    required String text,
    required String timestamp,
    required String type,
    required int channelId
  }) async {
    final db = await database;
    await db.insert('messages', {
      'senderId': sender,
      'content': text,
      'timestamp': timestamp,
      'type': type,
      'channelId': channelId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMessages(String type) async {
    final db = await database;
    return await db.query('messages', where: 'type = ?' , whereArgs: [type] ,orderBy: 'timestamp DESC');
  }

  Future<void> deleteOldMessages() async {
    final db = await database;
    int twentyFourHoursAgo =
        DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000);
    await db.delete(
      'messages',
      where: 'timestamp < ?',
      whereArgs: [twentyFourHoursAgo],
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

Future<List<Map<String, dynamic>>> getMessagesForChannel(String type, int channelId) async {
  final db = await database;
  return await db.query(
    'messages',
    where: 'type = ? AND channelId = ?',
    whereArgs: [type, channelId],
    orderBy: 'timestamp DESC',
  );
}



  // Future<void> deleteUser(int id) async {
}