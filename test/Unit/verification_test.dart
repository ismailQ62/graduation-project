import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Verification Logic', () {
    final List<Map<String, dynamic>> pendingResponders = [];

    Map<String, dynamic> createResponder(String id, String name) {
      return {
        'id': id,
        'name': name,
        'role': 'Paramedic',
        'description': 'Experienced in emergency response',
      };
    }

    test('Add responder only if not duplicate', () {
      final newResponder = createResponder('123', 'Alice');
      final duplicateResponder = createResponder('123', 'Alice');

      if (!pendingResponders.any((e) => e['id'] == newResponder['id'])) {
        pendingResponders.add(newResponder);
      }

      expect(pendingResponders.length, 1);

      if (!pendingResponders.any((e) => e['id'] == duplicateResponder['id'])) {
        pendingResponders.add(duplicateResponder);
      }

      expect(
        pendingResponders.length,
        1,
        reason: 'Duplicate should not be added',
      );
    });

    test('Simulate responder adds new entry', () {
      final demo = {
        'id': '999',
        'name': 'Demo User',
        'role': 'Firefighter',
        'description': 'Trained in rescue operations',
      };

      if (!pendingResponders.any((e) => e['id'] == demo['id'])) {
        pendingResponders.add(demo);
      }

      expect(pendingResponders.any((e) => e['name'] == 'Demo User'), isTrue);
    });

    test('Approve payload structure is valid', () {
      final user = createResponder('456', 'Bob');
      final messageJson = {
        'type': 'verify',
        'id': user['id'],
        'status': 'approved',
      };

      expect(messageJson['type'], equals('verify'));
      expect(messageJson['status'], equals('approved'));
      expect(messageJson['id'], equals('456'));
    });

    test('Reject payload structure is valid', () {
      final user = createResponder('789', 'Charlie');
      final messageJson = {
        'type': 'verify',
        'id': user['id'],
        'status': 'rejected',
      };

      expect(messageJson['status'], equals('rejected'));
    });
  });
}
