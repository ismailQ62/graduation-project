import 'package:flutter_test/flutter_test.dart';
import 'package:lorescue/models/user_model.dart';

void main() {
  group('User Model Unit Tests', () {
    test('Should create a valid user', () {
      final user = User(
        name: 'Ali Ahmad',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Responder',
      );
      expect(user.name, 'Ali Ahmad');
      expect(user.nationalId, '1234567890');
      expect(user.password, 'Valid@123');
      expect(user.role, 'Responder');
      expect(user.isBlocked, isFalse);
    });

    test('Should throw error for short name via setter', () {
      final user = User(
        name: 'Valid Name',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Admin',
      );

      expect(() => user.name = 'Al', throwsA(isA<ArgumentError>()));
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
        role: 'Responder',
      );

      expect(() => user.role = 'Guest', throwsA(isA<ArgumentError>()));
    });

    test('Should throw error for empty connectedZoneId', () {
      final user = User(
        name: 'Test User',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Responder',
      );
      expect(() => user.connectedZoneId = '', throwsA(isA<ArgumentError>()));
    });

    test('Should convert user to map correctly', () {
      final user = User(
        id: 1,
        name: 'Map User',
        nationalId: '1234567890',
        password: 'Valid@123',
        role: 'Admin',
        connectedZoneId: 'Zone_5',
        createdAt: '2025-05-29T10:00:00Z',
        isBlocked: true,
      );

      final map = user.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Map User');
      expect(map['isBlocked'], 1);
    });

    test('Should deserialize from map correctly', () {
      final userMap = {
        'id': 1,
        'name': 'From Map',
        'nationalId': '1234567890',
        'password': 'Valid@123',
        'role': 'Admin',
        'connectedZoneId': 'Zone_3',
        'createdAt': '2025-01-01T00:00:00Z',
        'isBlocked': 1,
      };
      final user = User.fromMap(userMap);
      expect(user.name, 'From Map');
      expect(user.role, 'Admin');
      expect(user.isBlocked, isTrue);
    });
  });
}
