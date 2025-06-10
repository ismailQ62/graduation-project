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
      version: 9,
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
        nationalId TEXT NOT NULL UNIQUE,
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
        isSent INTEGER DEFAULT 0,
        isRead INTEGER DEFAULT 0,
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
        longitude REAL NOT NULL,
        notifiedDisconnected INTEGER NOT NULL DEFAULT 0
      )
    ''');

    final existing = await db.query('channels');
    final existingIds = existing.map((e) => e['id']).toList();

    Future<void> insertChannelIfNotExist(
      int id,
      String name,
      String type,
    ) async {
      if (!existingIds.contains(id)) {
        await db.insert('channels', {'id': id, 'name': name, 'type': type});
      }
    }

    await insertChannelIfNotExist(1, 'Main Channel', 'main');
    await insertChannelIfNotExist(2, 'Alert Channel', 'alert');
    await insertChannelIfNotExist(3, 'News Channel', 'news');
    await insertChannelIfNotExist(4, 'Contacts', 'chat');
  }

  Future<void> insertMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String content,
    required String timestamp,
    required String type,
    required String zoneId,
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
      'zoneId': zoneId,
      'channelId': channelId,
      'receiverZone': receiverZone,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    print(
      'Message inserted: $senderId, $content, $type, $receiverZone, $channelId',
    );
  }

  Future<int?> getLastInsertedMessageId() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT id FROM messages ORDER BY id DESC LIMIT 1',
    );
    return result.isNotEmpty ? result.first['id'] as int : null;
  }

  Future<void> markMessageAsSent(int messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isSent': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markMessageAsRead(int messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [messageId],
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
  ) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'type = ? AND channelId = ? AND zoneId = ?',
      whereArgs: [type, channelId, zoneId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesForContacts(
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
    await db.insert('zones', {
      'id': zoneId,
      'name': zoneName,
      'status': 'safe',
      'latitude': 0.0,
      'longitude': 0.0,
      'notifiedDisconnected': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteZone(String zoneId) async {
    final db = await database;
    await db.delete('zones', where: 'id = ?', whereArgs: [zoneId]);
  }

  Future<String?> getChannelType(int channelId) async {
    final db = await database;
    final result = await db.query(
      'channels',
      columns: ['type'],
      where: 'id = ?',
      whereArgs: [channelId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['type'] as String : null;
  }

  Future<List<Map<String, Object?>>> getAllChannels() async {
    final db = await database;
    return await db.query('channels');
  }
Future<Map<String, dynamic>?> getUserById(String id) async {
  final db = await database;
  final result = await db.query('users', where: 'nationalId = ?', whereArgs: [id]);
  if (result.isNotEmpty) {
    return result.first;
  }
  return null;
}

}
