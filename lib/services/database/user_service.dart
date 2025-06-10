import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class LoginResult {
  final User? user;
  final String? error;

  LoginResult({this.user, this.error});
}

class UserService {
  final DatabaseService _dbService = DatabaseService();

  // Hash password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Register a new user
  Future<String> registerUser(User user) async {
    final db = await _dbService.database;
    final existingUsers = await db.query(
      'users',
      where: 'nationalId = ?',
      whereArgs: [user.nationalId],
    );
    if (existingUsers.isNotEmpty) {
      return 'National ID already exists!';
    }
    await db.insert('users', user.toMap());
    return 'Registration successful!';
  }

  // New: Login with result (success or error reason)
  Future<LoginResult> loginUserWithResult(
    String nationalId,
    String password,
  ) async {
    final db = await _dbService.database;
    final hashed = hashPassword(password);

    final users = await db.query(
      'users',
      where: 'nationalId = ? AND password = ?',
      whereArgs: [nationalId, hashed],
    );

    if (users.isNotEmpty) {
      final user = User.fromMap(users.first);

      if (user.isBlocked) {
        return LoginResult(
          error: "This account has been blocked by the admin.",
        );
      }

      return LoginResult(user: user);
    }

    return LoginResult(error: "Invalid National ID or Password.");
  }

  // Standard login (if you still need it)
  Future<User?> loginUser(String nationalId, String password) async {
    final db = await _dbService.database;
    final hashed = hashPassword(password);

    final users = await db.query(
      'users',
      where: 'nationalId = ? AND password = ?',
      whereArgs: [nationalId, hashed],
    );

    if (users.isNotEmpty) {
      final user = User.fromMap(users.first);
      if (user.isBlocked) return null;
      return user;
    }

    return null;
  }

  // Check if a National ID already exists
  Future<bool> doesNationalIdExist(String nationalId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'users',
      where: 'nationalId = ?',
      whereArgs: [nationalId],
    );
    return result.isNotEmpty;
  }

  // Update user's connected zone ID
  Future<void> updateUserZoneId(String nationalId, String zoneId) async {
    final db = await _dbService.database;
    await db.update(
      'users',
      {'connectedZoneId': zoneId},
      where: 'nationalId = ?',
      whereArgs: [nationalId],
    );
  }

  // Get all users from the database
  Future<List<User>> getAllUsers() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  // Delete a user by national ID
  Future<void> deleteUser(String nationalId) async {
    final db = await _dbService.database;
    await db.delete('users', where: 'nationalId = ?', whereArgs: [nationalId]);
  }

  // Insert or replace a user
  Future<void> insertUser(User user) async {
    final db = await _dbService.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete all users from the database
  Future<void> deleteAllUsers() async {
    final db = await _dbService.database;
    await db.delete('users');
  }

  // Block a user
  Future<void> blockUser(String nationalId) async {
    final db = await _dbService.database;
    await db.update(
      'users',
      {'isBlocked': 1},
      where: 'nationalId = ?',
      whereArgs: [nationalId],
    );
  }

  // Unblock a user
  Future<void> unblockUser(String nationalId) async {
    final db = await _dbService.database;
    await db.update(
      'users',
      {'isBlocked': 0},
      where: 'nationalId = ?',
      whereArgs: [nationalId],
    );
  }

  Future<List<User>> getUsersByRole(String role) async {
    final db = await DatabaseService().database;
    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role],
    );
    return result.map((e) => User.fromMap(e)).toList();
  }
}
