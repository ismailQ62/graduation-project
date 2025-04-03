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
      channelId INTEGER NOT NULL DEFAULT 1
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS channels (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  ''');
  }

  Future<void> insertMessage({
    required String sender,
    required String text,
    required String timestamp,
  }) async {
    final db = await database;

    await db.insert('messages', {
      'senderId': sender,
      'content': text,
      'timestamp': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
    );
    return result;
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
    return await db.query('users'); // Fetch all users
  }
}
