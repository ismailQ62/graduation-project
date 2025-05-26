import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/views/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final nationalId = AuthService.getCurrentUser()?.nationalId;
      if (nationalId == null) {
        setState(() {
          _isLoading = false;
          _userData = null;
        });
        return;
      }
      final db = await _dbService.database;
      final users = await db.query(
        'users',
        where: 'nationalId = ?',
        whereArgs: [nationalId],
        limit: 1,
      );
      setState(() {
        _userData = users.isNotEmpty ? users.first : null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
        _userData = null;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return const Scaffold(body: Center(child: Text('No user data found')));
    }

    final fullName = _userData!['name'] ?? '';
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : 'N/A';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'N/A';

    final imagePath = _userData!['credential'] as String?;
    final imageKey = UniqueKey();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                child: ClipOval(
                  child:
                      imagePath != null &&
                              imagePath.isNotEmpty &&
                              File(imagePath).existsSync()
                          ? Image.file(
                            File(imagePath),
                            key: imageKey, // 👈 force re-render
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                          : const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RectangularField(
                        label: 'First Name',
                        value: firstName,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RectangularField(
                        label: 'Last Name',
                        value: lastName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RectangularField(
                  label: 'National ID',
                  value: _userData!['nationalId'] ?? 'N/A',
                ),
                const SizedBox(height: 20),
                RectangularField(
                  label: 'Phone Number',
                  value: _userData!['phoneNumber'] ?? 'N/A',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: RectangularField(
                        label: 'Blood Type',
                        value: _userData!['bloodType'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RectangularField(
                        label: 'Role',
                        value: _userData!['role'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RectangularField(
                  label: 'Address',
                  value: _userData!['address'] ?? 'N/A',
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete Account"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final updatedPath = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EditProfileScreen(userData: _userData!),
                          ),
                        );

                        if (updatedPath != null && updatedPath.isNotEmpty) {
                          setState(() {
                            _userData!['credential'] = updatedPath;
                          });
                        }
                      },
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RectangularField extends StatelessWidget {
  final String label;
  final String value;

  const RectangularField({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(45, 37, 95, 255).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromRGBO(56, 75, 112, 1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(80, 118, 135, 1),
            ),
          ),
        ],
      ),
    );
  }
}
