import 'package:flutter_test/flutter_test.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/models/user_model.dart';

void main() {
  group('Channel Model', () {
    test('should create valid channel', () {
      final channel = Channel(name: 'Main', type: 'chat');
      expect(channel.name, 'Main');
      expect(channel.type, 'chat');
    });

    test('should throw error if channel name is empty', () {
      expect(
        () => Channel(name: '', type: 'chat'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error if channel type is empty', () {
      expect(
        () => Channel(name: 'Main', type: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error when setting empty name', () {
      final channel = Channel(name: 'News', type: 'info');
      expect(() => channel.name = '', throwsA(isA<ArgumentError>()));
    });

    test('should throw error when setting empty type', () {
      final channel = Channel(name: 'Alerts', type: 'urgent');
      expect(() => channel.type = '', throwsA(isA<ArgumentError>()));
    });

    test('should convert to map and back from map', () {
      final original = Channel(id: 1, name: 'Chat', type: 'group');
      final map = original.toMap();
      final fromMap = Channel.fromMap(map);

      expect(fromMap.name, 'Chat');
      expect(fromMap.type, 'group');
      expect(fromMap.id, 1);
    });
  });

  group('Channel search logic', () {
    final channels = [
      {'name': 'General Channel'},
      {'name': 'Alert Channel'},
      {'name': 'Responder Zone'},
    ];

    test('Search filters correctly', () {
      final search = 'alert'.toLowerCase();
      final filtered =
          channels
              .where((c) => c['name']!.toLowerCase().contains(search))
              .toList();
      expect(filtered.length, 1);
      expect(filtered[0]['name'], 'Alert Channel');
    });

    test('Empty search returns all', () {
      final search = '';
      final filtered =
          channels
              .where((c) => c['name']!.toLowerCase().contains(search))
              .toList();
      expect(filtered.length, channels.length);
    });
  });

  group('User deduplication logic', () {
    test('New user should be added if not in list', () {
      final users = <User>[
        User(
          name: 'Alice',
          nationalId: '1234567890',
          password: 'Valid@123',
          role: 'Admin',
          connectedZoneId: '',
        ),
      ];

      final incoming = {
        'type': 'GetUsers',
        'national_id': '4567890123',
        'name': 'Bob',
      };

      final alreadyExists = users.any(
        (u) => u.nationalId == incoming['national_id'],
      );
      expect(alreadyExists, isFalse);

      users.add(
        User(
          name: incoming['name']!,
          nationalId: incoming['national_id']!,
          password: 'Valid@123',
          role: 'Responder',
          connectedZoneId: '',
        ),
      );

      expect(users.length, 2);
    });

    test('Duplicate user should not be added', () {
      final users = <User>[
        User(
          name: 'Alice',
          nationalId: '1234567890',
          password: 'Valid@123',
          role: 'Admin',
          connectedZoneId: '',
        ),
      ];

      final incoming = {
        'type': 'GetUsers',
        'national_id': '1234567890',
        'name': 'Alice',
      };

      final alreadyExists = users.any(
        (u) => u.nationalId == incoming['national_id'],
      );
      expect(alreadyExists, isTrue);
    });
  });
}
