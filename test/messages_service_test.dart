import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lorescue/models/message_model.dart';
import 'package:lorescue/services/database/message_service.dart';
import 'package:lorescue/services/database/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final messageService = MessageService();

  setUp(() async {
    final db = await DatabaseService().database;
    await db.delete('messages');
  });

  group('Message Model and Service Tests', () {
    final now = DateTime.now().toIso8601String();

    test('Create and test valid Message object', () {
      final msg = Message(
        senderId: '1234567890',
        receiverId: '0987654321',
        content: 'Hello, this is a test message.',
        timestamp: now,
      );

      // Test all properties of the Message
      expect(msg.senderId, '1234567890');
      expect(msg.receiverId, '0987654321');
      expect(msg.content, 'Hello, this is a test message.');
      expect(msg.timestamp, now);
      //  expect(msg.isRead, isFalse);
    });

    test('Empty message content should throw an error via setter', () {
      final msg = Message(
        senderId: '1234567890',
        receiverId: '0987654321',
        content: 'Initial valid content',
        timestamp: now,
      );
      expect(() => msg.content = '', throwsArgumentError);
    });

    test('Send and retrieve all messages from DB', () async {
      final message1 = Message(
        senderId: '1234567890',
        receiverId: '0987654321',
        content: 'First message',
        timestamp: now,
      );
      final message2 = Message(
        senderId: '1111111111',
        receiverId: '2222222222',
        content: 'Second message',
        timestamp: now,
      );

      await messageService.sendMessage(message1);
      await messageService.sendMessage(message2);

      final allMessages = await messageService.getAllMessages();
      expect(allMessages.length, 2);
      expect(allMessages.any((m) => m.content == 'First message'), isTrue);
      expect(allMessages.any((m) => m.content == 'Second message'), isTrue);
    });
  });
}
