import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:lorescue/services/database/database_service.dart'; // 👈 Added for DB access

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final userService = UserService();

  //  Clear users before each test to avoid conflicts
  setUp(() async {
    final db = await DatabaseService().database;
    await db.delete('users');
  });

  group('UserService Validation & DB Tests', () {
    final validUser = User(
      name: 'Test User',
      nationalId: '1234567890',
      password: 'Secure1@',
      role: 'Admin',
    );

    test('Register valid user should succeed', () async {
      String result = await userService.registerUser(validUser);
      expect(result, 'Registration successful!');
    });

    test('Register with duplicate National ID should fail', () async {
      await userService.registerUser(validUser);
      String result = await userService.registerUser(validUser);
      expect(result, 'National ID already exists!');
    });

    test('Login with correct credentials should return role', () async {
      await userService.registerUser(validUser);
      String? role = await userService.loginUser('1234567890', 'Secure1@');
      expect(role, 'Admin');
    });

    test('Login with wrong password should return null', () async {
      await userService.registerUser(validUser);
      String? role = await userService.loginUser('1234567890', 'WrongPass1');
      expect(role, isNull);
    });

    test('Invalid National ID (not 10 digits) should throw error', () {
      final user = User(
        name: 'Invalid',
        nationalId: '1234567890',
        password: 'Valid1A@',
        role: 'Admin',
      );
      expect(() => user.nationalId = '12345', throwsArgumentError);
    });

    test('Invalid password (no uppercase) should throw error', () {
      final user = User(
        name: 'Invalid',
        nationalId: '1234567890',
        password: 'Valid1A@',
        role: 'Admin',
      );
      expect(() => user.password = 'password1@', throwsArgumentError);
    });

    test('Invalid password (no lowercase) should throw error', () {
      final user = User(
        name: 'Invalid',
        nationalId: '1234567890',
        password: 'Valid1A@',
        role: 'Admin',
      );
      expect(() => user.password = 'PASSWORD1@', throwsArgumentError);
    });

    test('Invalid password (no digit) should throw error', () {
      final user = User(
        name: 'Invalid',
        nationalId: '1234567890',
        password: 'Valid1A@',
        role: 'Admin',
      );
      expect(() => user.password = 'Password@', throwsArgumentError);
    });

    test('Password under 6 characters should throw error', () {
      final user = User(
        name: 'Invalid',
        nationalId: '1234567890',
        password: 'Valid1A@',
        role: 'Admin',
      );
      expect(() => user.password = 'Pw@1', throwsArgumentError);
    });
  });
}
