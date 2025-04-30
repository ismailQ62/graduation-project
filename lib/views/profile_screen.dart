import 'package:flutter/material.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:lorescue/services/auth_service.dart'; // Add this import

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
      final nationalId = AuthService.getCurrentUserNationalId();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        body: Center(child: Text('No user data found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/profile_picture.jpg'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${_userData!['firstName']} ${_userData!['lastName']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _userData!['email'] ?? 'No email provided',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RectangularField(
                        label: 'First Name',
                        value: _userData!['firstName'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RectangularField(
                        label: 'Last Name',
                        value: _userData!['lastName'] ?? 'N/A',
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
                // ... rest of your buttons code
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Widget for Rectangular Fields
class RectangularField extends StatelessWidget {
  final String label;
  final String value;

  const RectangularField({
   required this.label,
    required this.value,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(45, 37, 95, 255).withOpacity(0.2), // Light blue background
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: const Color.fromRGBO(56, 75, 112, 1),
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              
              color: const Color.fromRGBO(80, 118, 135, 1),
            ),
          ),
        ],
      ),
    );
  }
}