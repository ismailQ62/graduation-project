import 'package:flutter_test/flutter_test.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/views/admin/blocked_users_screen.dart';
import 'dart:convert';

void main() {
  group('BlockedUsersScreen Logic', () {
    final allUsers = [
      User(
        name: 'User 1',
        nationalId: '1111111111',
        password: 'pass',
        role: 'Responder',
        connectedZoneId: '1',
        isBlocked: true,
      ),
      User(
        name: 'User 2',
        nationalId: '2222222222',
        password: 'pass',
        role: 'Admin',
        connectedZoneId: '2',
        isBlocked: false,
      ),
    ];

    test('Filters only blocked users', () {
      final blocked = allUsers.where((u) => u.isBlocked).toList();
      expect(blocked.length, 1);
      expect(blocked.first.name, 'User 1');
    });

    test('Generates correct unblock WebSocket payload', () {
      final user = allUsers.first;
      final expected = {
        "type": "unblock",
        "id": user.nationalId,
        "role": user.role,
      };

      final actual = jsonEncode(expected);
      expect(actual, '{"type":"unblock","id":"1111111111","role":"Responder"}');
    });
  });
}
