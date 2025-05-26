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
    return await openDatabase(
      path,
      version: 8, // Incremented version
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute("DROP TABLE IF EXISTS users");
        await db.execute("DROP TABLE IF EXISTS channels");
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
        phoneNumber TEXT,
        address TEXT,
        bloodType TEXT,
        role TEXT,
        password TEXT,
        connectedZoneId TEXT,
        credential TEXT,
        verified INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT,
        isBlocked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        receiverId TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        channelId INTEGER NOT NULL DEFAULT 1,
        zoneId TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL,
        receiverZone TEXT 
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS channels (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute(''' 
      CREATE TABLE IF NOT EXISTS zones (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    final existing = await db.query('channels');
    final existingIds = existing.map((e) => e['id']).toList();

    if (!existingIds.contains(1)) {
      await db.insert('channels', {
        'id': 1,
        'name': 'Main Channel',
        'type': 'main',
      });
    }
    if (!existingIds.contains(2)) {
      await db.insert('channels', {
        'id': 2,
        'name': 'Alert Channel',
        'type': 'alert',
      });
    }
    if (!existingIds.contains(3)) {
      await db.insert('channels', {
        'id': 3,
        'name': 'News Channel',
        'type': 'news',
      });
    }
    if (!existingIds.contains(4)) {
      await db.insert('channels', {
        'id': 4,
        'name': 'Contacts',
        'type': 'chat',
      });
    }
  }

  Future<void> insertMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String content,
    required String timestamp,
    required String type,
    required String receiverZone,
    required int channelId,
  }) async {
    final db = await database;
    await db.insert('messages', {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'type': type,
      'zoneId': receiverZone,
      'channelId': channelId,
      'receiverZone': receiverZone,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    print(
      'Message inserted: $senderId, $content, $type, $receiverZone, $channelId',
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String type) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesForChannel(
    String type,
    int channelId,
    String zoneId,
    String? receiverId,
  ) async {
    final db = await database;
    final whereClause =
        receiverId != null
            ? '(senderId = ? OR receiverId = ?) AND channelId = ? AND receiverZone = ? AND type = ?'
            : 'channelId = ? AND receiverZone = ? AND type = ?';
    final whereArgs =
        receiverId != null
            ? [receiverId, receiverId, channelId, zoneId, type]
            : [channelId, zoneId, type];

    return await db.query(
      'messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp ASC',
    );
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

  Future<void> deleteUser(String nationalId) async {
    final db = await database;
    await db.delete('users', where: 'nationalId = ?', whereArgs: [nationalId]);
  }

  Future<List<Map<String, dynamic>>> getZones() async {
    final db = await database;
    return await db.query('zones');
  }

  Future<void> addZone(String zoneId, String zoneName) async {
    final db = await database;
    await db.insert('zones', {'id': zoneId, 'name': zoneName});
  }

  Future<void> deleteZone(String zoneId) async {
    final db = await database;
    await db.delete('zones', where: 'id = ?', whereArgs: [zoneId]);
  }

  Future<String?> getChannelType(int channelId) async {
    final db = await database;
    final result = await db.query(
      'channels',
      where: 'id = ?',
      whereArgs: [channelId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['type'] as String;
    }
    return null;
  }
}
