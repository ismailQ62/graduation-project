import 'package:lorescue/models/message_model.dart';
import 'package:lorescue/services/database/database_service.dart';

class MessageService {
  final DatabaseService _dbService = DatabaseService();

  Future<void> sendMessage(Message message) async {
    final db = await _dbService.database;

    await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getAllMessages() async {
    final db = await _dbService.database;
    final result = await db.query('messages', orderBy: 'timestamp ASC');
    return result.map((m) => Message.fromMap(m)).toList();
  }

  Future<List<Message>> getMessagesByChannel(int channelId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'messages',
      where: 'channelId = ?',
      whereArgs: [channelId],
      orderBy: 'timestamp ASC',
    );
    return result.map((m) => Message.fromMap(m)).toList();
  }

  Future<void> clearMessages() async {
    final db = await _dbService.database;
    await db.delete('messages');
  }
}
