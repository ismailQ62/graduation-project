import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/services/database/database_service.dart';

class ChannelService {
  final DatabaseService _dbService = DatabaseService();

  Future<void> createChannel(Channel channel) async {
    final db = await _dbService.database;
    await db.insert('channels', channel.toMap());
  }

  Future<List<Channel>> getAllChannels() async {
    final db = await _dbService.database;
    final result = await db.query('channels');
    return result.map((c) => Channel.fromMap(c)).toList();
  }

  Future<void> updateChannel(Channel channel) async {
    final db = await _dbService.database;
    await db.update(
      'channels',
      channel.toMap(),
      where: 'id = ?',
      whereArgs: [channel.id],
    );
  }

  Future<void> deleteChannel(int id) async {
    final db = await _dbService.database;
    await db.delete('channels', where: 'id = ?', whereArgs: [id]);
  }
}
