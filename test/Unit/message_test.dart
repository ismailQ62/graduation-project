import 'package:flutter_test/flutter_test.dart';
import 'package:lorescue/models/message_model.dart';
import 'package:lorescue/models/user_model.dart';

void main() {
  group('User model', () {
    test('Should create valid user', () {
      final user = User(
        name: 'Valid Name',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Admin',
      );

      expect(user.name, 'Valid Name');
      expect(user.nationalId, '1234567890');
      expect(user.role, 'Admin');
    });

    test('Should throw error for invalid national ID', () {
      final user = User(
        name: 'Test User',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Admin',
      );

      expect(() => user.nationalId = 'abc123', throwsA(isA<ArgumentError>()));
    });

    test('Should throw error for weak password', () {
      final user = User(
        name: 'Weak User',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Responder',
      );

      expect(() => user.password = '12345678', throwsA(isA<ArgumentError>()));
    });

    test('Should throw error for invalid role', () {
      final user = User(
        name: 'User One',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Admin',
      );

      expect(() => user.role = 'Guest', throwsA(isA<ArgumentError>()));
    });
  });

  group('Message model', () {
    test('Should create valid message', () {
      final message = Message(
        senderId: '123',
        receiverId: '456',
        content: 'Hello there!',
        timestamp: DateTime.now().toIso8601String(),
        channelId: 1,
      );

      expect(message.senderId, '123');
      expect(message.receiverId, '456');
      expect(message.content, 'Hello there!');
      expect(message.channelId, 1);
    });

    test('Should throw error if senderId is empty', () {
      expect(
        () => Message(
          senderId: '',
          receiverId: '456',
          content: 'Hi!',
          timestamp: DateTime.now().toIso8601String(),
          channelId: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Should throw error if receiverId is empty', () {
      expect(
        () => Message(
          senderId: '123',
          receiverId: '',
          content: 'Hi!',
          timestamp: DateTime.now().toIso8601String(),
          channelId: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Should throw error if content is empty', () {
      expect(
        () => Message(
          senderId: '123',
          receiverId: '456',
          content: '',
          timestamp: DateTime.now().toIso8601String(),
          channelId: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Should throw error when setting empty content', () {
      final message = Message(
        senderId: '123',
        receiverId: '456',
        content: 'Hello!',
        timestamp: DateTime.now().toIso8601String(),
        channelId: 1,
      );

      expect(() => message.content = '', throwsA(isA<ArgumentError>()));
    });

    test('Should throw error when setting invalid channelId', () {
      final message = Message(
        senderId: '123',
        receiverId: '456',
        content: 'Hello!',
        timestamp: DateTime.now().toIso8601String(),
        channelId: 1,
      );

      expect(() => message.channelId = 0, throwsA(isA<ArgumentError>()));
    });
  });
}
