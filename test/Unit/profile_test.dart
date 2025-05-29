import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:lorescue/services/auth_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('ProfileScreen Logic', () {
    test('Name is split correctly into first and last names', () {
      String fullName = 'Ismail Qwasmi';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : 'N/A';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'N/A';

      expect(firstName, 'Ismail');
      expect(lastName, 'Qwasmi');
    });

    test('Name with no space has only first name', () {
      String fullName = 'Ismail';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : 'N/A';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'N/A';

      expect(firstName, 'Ismail');
      expect(lastName, 'N/A');
    });

    test('Handle null nationalId during user loading', () async {
      final nationalId = null;
      expect(nationalId, isNull);
    });

    test('Check if image path exists', () {
      final path = '/invalid/path/to/image.png';
      final fileExists = File(path).existsSync();
      expect(fileExists, isFalse);
    });
  });
}
