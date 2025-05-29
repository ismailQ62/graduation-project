import 'package:flutter_test/flutter_test.dart';

void main() {
  group('National ID Validation', () {
    test('Valid National ID passes', () {
      final value = '1234567890';
      final isValid = RegExp(r'^\d{10}$').hasMatch(value);
      expect(isValid, isTrue);
    });

    test('Too short ID fails', () {
      final value = '12345';
      final isValid = RegExp(r'^\d{10}$').hasMatch(value);
      expect(isValid, isFalse);
    });

    test('ID with letters fails', () {
      final value = '12345abcd1';
      final isValid = RegExp(r'^\d{10}$').hasMatch(value);
      expect(isValid, isFalse);
    });
  });

  group('Password Validation', () {
    test('Valid password passes', () {
      final value = 'Strong@Pass1';
      final isValid =
          RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$&*~%^])').hasMatch(value) &&
          value.length >= 8;
      expect(isValid, isTrue);
    });

    test('Password missing special character fails', () {
      final value = 'StrongPass1';
      final isValid = RegExp(
        r'(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$&*~%^])',
      ).hasMatch(value);
      expect(isValid, isFalse);
    });

    test('Password too short fails', () {
      final value = 'Sh@1';
      final isLongEnough = value.length >= 8;
      expect(isLongEnough, isFalse);
    });

    test('Password missing uppercase fails', () {
      final value = 'weak@password';
      final isValid = RegExp(r'(?=.*[A-Z])').hasMatch(value);
      expect(isValid, isFalse);
    });
  });
}
