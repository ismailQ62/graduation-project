import 'package:lorescue/models/user_model.dart';

import 'package:lorescue/services/database/database_service.dart';

class UserService {
  final DatabaseService _dbService = DatabaseService();

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

  Future<bool> doesNationalIdExist(String nationalId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'users',
      where: 'nationalId = ?',
      whereArgs: [nationalId],
    );
    return result.isNotEmpty;
  }

  Future<void> updateUserZoneId(String nationalId, String zoneId) async {
    final db = await _dbService.database;
    await db.update(
      'users',
      {'connectedZoneId': zoneId},
      where: 'nationalId = ?',
      whereArgs: [nationalId],
    );
  }

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
}
