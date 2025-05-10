import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class UserService {
  final DatabaseService _dbService = DatabaseService();

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

  // Login with National ID and Password
  Future<User?> loginUser(String nationalId, String password) async {
    final db = await _dbService.database;
    final users = await db.query(
      'users',
      where: 'nationalId = ? AND password = ?',
      whereArgs: [nationalId, password],
    );
    if (users.isNotEmpty) {
      return User(
        id: users.first['id'] as int?,
        name: users.first['name'] as String,
        nationalId: users.first['nationalId'] as String,
        password: users.first['password'] as String,
        role: users.first['role'] as String,
        connectedZoneId: users.first['connectedZoneId'] as String?,
      );
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

    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['id'] as int?,
        name: maps[i]['name'] as String,
        nationalId: maps[i]['nationalId'] as String,
        password: maps[i]['password'] as String,
        role: maps[i]['role'] as String,
        connectedZoneId: maps[i]['connectedZoneId'] as String?,
      );
    });
  }

  Future<void> deleteUser(String nationalId) async {
    final db = await _dbService.database;
    await db.delete('users', where: 'nationalId = ?', whereArgs: [nationalId]);
  }

  Future<void> insertUser(User user) async {
    final db = await _dbService.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAllUsers() async {
    final db = await _dbService.database;
    await db.delete('users');
  }
}
