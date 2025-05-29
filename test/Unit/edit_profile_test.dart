import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Name parsing logic', () {
    test('Full name is split correctly into first and last name', () {
      String fullName = 'Ismail Qwasmi';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      expect(firstName, 'Ismail');
      expect(lastName, 'Qwasmi');
    });

    test('Single name returns only first name', () {
      String fullName = 'Ismail';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      expect(firstName, 'Ismail');
      expect(lastName, '');
    });
  });

  group('Image logic (non-mocked test)', () {
    test('Image path is checked for existence', () {
      final fakePath = '/some/fake/path.png';
      final exists = File(fakePath).existsSync();
      expect(exists, isFalse);
    });
  });

  group('Blood Type and Role dropdowns', () {
    final validBloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final validRoles = ['Responder', 'Admin', 'Individual'];

    test('Valid blood type is in the list', () {
      expect(validBloodTypes.contains('A+'), isTrue);
      expect(validBloodTypes.contains('Z+'), isFalse);
    });

    test('Valid role is in the list', () {
      expect(validRoles.contains('Admin'), isTrue);
      expect(validRoles.contains('Guest'), isFalse);
    });
  });
}
