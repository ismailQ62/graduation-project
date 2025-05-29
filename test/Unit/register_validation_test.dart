import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:mockito/mockito.dart';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  group('hashPassword()', () {
    test('Returns a SHA-256 hash of the password', () {
      final hash = hashPassword('StrongPassword!');
      expect(hash.length, 64);
    });

    test('Consistent hash for same input', () {
      final hash1 = hashPassword('MyPassword123!');
      final hash2 = hashPassword('MyPassword123!');
      expect(hash1, equals(hash2));
    });

    test('Different inputs yield different hashes', () {
      final hash1 = hashPassword('Password1!');
      final hash2 = hashPassword('Password2!');
      expect(hash1, isNot(equals(hash2)));
    });
  });
}
