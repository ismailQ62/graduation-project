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

  Future<String?> loginUser(String nationalId, String password) async {
    final db = await _dbService.database;
    final users = await db.query(
      'users',
      where: 'nationalId = ? AND password = ?',
      whereArgs: [nationalId, password],
    );
    if (users.isNotEmpty) {
      return users.first['role'] as String?;
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
}
