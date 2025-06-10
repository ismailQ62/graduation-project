import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:lorescue/services/database/user_service.dart';
import 'package:lorescue/routes.dart';
import 'package:network_info_plus/network_info_plus.dart';

class UserController extends ChangeNotifier {
  final UserService _userService = UserService();
  final WebSocketService webSocketService = WebSocketService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  String? selectedRole;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  List<User> _users = [];
  List<User> filteredUsers = [];
  List<User> _blockedUsers = [];
  List<User> get blockedUsers => _blockedUsers;
  List<User> get users => _users;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  Future<void> login({
    required BuildContext context,
    required String nationalId,
    required String password,
    required GlobalKey<FormState> formKey,
  }) async {
    if (!formKey.currentState!.validate()) return;

    final result = await _userService.loginUserWithResult(nationalId, password);

    if (result.user != null) {
      AuthService.setCurrentUser(result.user!);

      if (result.user!.role == 'Admin') {
        Navigator.pushNamed(context, AppRoutes.homeAdmin);
      } else if (result.user!.role == 'Responder') {
        Navigator.pushNamed(context, AppRoutes.homeResponder);
      } else {
        Navigator.pushNamed(context, AppRoutes.home);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? "Login failed."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> connectedToWifi() async {
    final info = NetworkInfo();
    final ssid = await info.getWifiName();
    return ssid != null && ssid.isNotEmpty;
  }

  void initWebSocket() {
    if (!webSocketService.isConnected) {
      webSocketService.connect('ws://192.168.4.1:81');
    }
  }

  Future<String?> register(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    final isConnected = await connectedToWifi();
    if (!isConnected) {
      // ! to be added or deleted
      await showDialog(
        context: context,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, size: 60, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    Text(
                      'No Wi-Fi Connection',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please connect to any WiFi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
      return "no_wifi";
    }

    if (!formKey.currentState!.validate()) return "validation_error";

    if (passwordController.text != confirmPasswordController.text) {
      return "password_mismatch";
    }

    final nationalId = nationalIdController.text;
    final exists = await _userService.doesNationalIdExist(nationalId);
    if (exists) return "duplicate_id";
    if (selectedRole == "Admin") {
      final admins = await _userService.getUsersByRole("Admin");
      if (admins.isNotEmpty) return "admin_exists";
    }

    final hashedPassword = hashPassword(passwordController.text);
    final now = DateTime.now().toIso8601String();

    final newUser = User(
      name: usernameController.text,
      nationalId: nationalId,
      password: hashedPassword,
      role: selectedRole!,
      connectedZoneId: "0",
      createdAt: now,
    );

    await _userService.registerUser(newUser);

    final jsonData = {
      "type": "register",
      "name": usernameController.text,
      "national_id": nationalId,
      "role": selectedRole,
      "connectedZoneId": "0",
      "createdAt": now,
    };
    webSocketService.send(jsonEncode(jsonData));

    return null; // success
  }

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final nationalId = AuthService.getCurrentUser()?.nationalId;
      if (nationalId == null) {
        _userData = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final db = await _dbService.database;
      final users = await db.query(
        'users',
        where: 'nationalId = ?',
        whereArgs: [nationalId],
        limit: 1,
      );

      _userData = users.isNotEmpty ? users.first : null;
    } catch (e) {
      print('Error loading user data: $e');
      _userData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteAccount(BuildContext context) async {
    if (_userData == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: const Text(
              "Are you sure you want to delete your account?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _dbService.deleteUser(_userData!['nationalId']);
      AuthService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void updateProfileImage(String path) {
    if (_userData != null) {
      _userData!['credential'] = path;
      notifyListeners();
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> decoded) async {
    try {
      final type = decoded['type'] ?? '';
      final nationalId = decoded['national_id'] ?? '';
      final name = decoded['name'] ?? '';
      final role = decoded['role'] ?? '';
      final zoneID = decoded['zoneID'] ?? '';

      if (type == 'NewUser') {
        final exists = _users.any((u) => u.nationalId == nationalId);
        if (!exists) {
          final newUser = User(
            name: name,
            nationalId: nationalId,
            password: " ",
            role: role,
            connectedZoneId: zoneID,
          );
          await _userService.insertUser(newUser);
          await fetchUsers();
        }
      }
    } catch (e) {
      debugPrint("Error handling WebSocket message: $e");
    }
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    final fetchedUsers = await _userService.getAllUsers();
    _users = fetchedUsers;
    filteredUsers = fetchedUsers;

    _broadcastUserList(fetchedUsers);

    _isLoading = false;
    notifyListeners();
  }

  void _broadcastUserList(List<User> users) {
    final userListJson = users.map((u) => u.toJson()).toList();
    final payload = {"type": "sync_users", "users": userListJson};
    webSocketService.send(jsonEncode(payload));
  }

  void searchUsers(String query) {
    final results =
        _users.where((user) {
          final nameMatch = user.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          final roleMatch = user.role.toLowerCase().contains(
            query.toLowerCase(),
          );
          return nameMatch || roleMatch;
        }).toList();

    filteredUsers = results;
    notifyListeners();
  }

  Future<void> blockUser(User user, BuildContext context) async {
    final currentUser = AuthService.getCurrentUser();

    if (currentUser?.nationalId == user.nationalId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot block your own admin account."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final payload = {"type": "block", "id": user.nationalId, "role": user.role};
    webSocketService.send(jsonEncode(payload));

    await _userService.blockUser(user.nationalId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${user.name} has been blocked.")));

    await fetchUsers();
  }

  void listenToWebSocket() {
    if (!webSocketService.isConnected) {
      webSocketService.connect('ws://192.168.4.1:81');
    }
    webSocketService.addListener(_handleWebSocketMessage);
  }

  void removeWebSocketListener() {
    webSocketService.removeListener(_handleWebSocketMessage);
  }

  Future<void> fetchBlockedUsers() async {
    final allUsers = await _userService.getAllUsers();
    _blockedUsers = allUsers.where((u) => u.isBlocked).toList();
    notifyListeners();
  }

  Future<bool> unblockUser({
    required User user,
    required Future<bool> Function(User user) confirmUnblock,
  }) async {
    final confirmed = await confirmUnblock(user);
    if (!confirmed) return false;

    await _userService.unblockUser(user.nationalId);

    final payload = {
      "type": "unblock",
      "id": user.nationalId,
      "role": user.role,
    };
    webSocketService.send(jsonEncode(payload));

    await fetchBlockedUsers();
    return true;
  }
}
