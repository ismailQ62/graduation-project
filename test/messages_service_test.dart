import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lorescue/models/message_model.dart';
import 'package:lorescue/services/database/message_service.dart';
import 'package:lorescue/services/database/database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final messageService = MessageService();

  setUp(() async {
    final db = await DatabaseService().database;
    await db.delete('messages');
  });

  group('Message Model and Service Tests (with channelId)', () {
    final now = DateTime.now().toIso8601String();

    test('Create and test valid Message object', () {
      final msg = Message(
        senderId: '1234567890',
        receiverId: '0987654321',
        content: 'Hello, this is a test message.',
        timestamp: now,
        channelId: 1,
      );

      expect(msg.senderId, '1234567890');
      expect(msg.receiverId, '0987654321');
      expect(msg.content, 'Hello, this is a test message.');
      expect(msg.timestamp, now);
      expect(msg.channelId, 1);
    });

    test('Empty message content should throw an error via setter', () {
      final msg = Message(
        senderId: '1234567890',
        receiverId: '0987654321',
        content: 'Initial content',
        timestamp: now,
        channelId: 1,
      );

      expect(() => msg.content = '', throwsArgumentError);
    });

    /* test('Send and retrieve all messages from DB by channelId', () async {
      final message1 = Message(
        senderId: '1234567890',
        receiverId: '0987654321',
        content: 'First message',
        timestamp: now,
        channelId: 1,
      );
      final message2 = Message(
        senderId: '1111111111',
        receiverId: '2222222222',
        content: 'Second message',
        timestamp: now,
        channelId: 2,
      );

      await messageService.sendMessage(message1);
      await messageService.sendMessage(message2);

      final allMessages = await messageService.getAllMessages();
      expect(allMessages.length, 2);

      final channel1Messages = await messageService.getMessagesByChannel(1);
      expect(channel1Messages.length, 1);
      expect(channel1Messages.first.content, 'First message');
    }); */
  });
}
