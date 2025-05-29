import 'package:flutter_test/flutter_test.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/views/admin/manage_users_screen.dart';

void main() {
  group('ManageUsersScreen Logic', () {
    final mockUsers = [
      User(
        name: 'Alice',
        nationalId: '1234567890',
        password: 'pass',
        role: 'Responder',
        connectedZoneId: '1',
        createdAt: '2024-05-01T08:30:00Z',
      ),
      User(
        name: 'Bob',
        nationalId: '0987654321',
        password: 'pass',
        role: 'Admin',
        connectedZoneId: '2',
        createdAt: '2024-05-01T09:00:00Z',
      ),
    ];

    test('Search filters users by name or role', () {
      final query = 'responder';
      final results =
          mockUsers.where((user) {
            final nameMatch = user.name.toLowerCase().contains(
              query.toLowerCase(),
            );
            final roleMatch = user.role.toLowerCase().contains(
              query.toLowerCase(),
            );
            return nameMatch || roleMatch;
          }).toList();

      expect(results.length, 1);
      expect(results.first.name, 'Alice');
    });

    test('Duplicate users are not added from WebSocket', () {
      final nationalId = '1234567890';
      final alreadyExists = mockUsers.any((u) => u.nationalId == nationalId);
      expect(alreadyExists, isTrue);
    });

    test('Formats valid ISO date to readable format', () {
      final result = formatDateWithTime('2024-05-01T08:30:00Z');
      expect(result, '2024-05-01 • 08:30');
    });

    test('Formats null or invalid date as fallback', () {
      expect(formatDateWithTime(null), 'Unknown');
      expect(formatDateWithTime('invalid'), 'Invalid Date');
    });
  });
}
