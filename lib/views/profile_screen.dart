import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lorescue/controllers/user_controller.dart';
import 'package:lorescue/views/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UserController();
    _controller.loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<UserController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final userData = controller.userData;
          if (userData == null) {
            return const Scaffold(
              body: Center(child: Text('No user data found')),
            );
          }

          final fullName = userData['name'] ?? '';
          final nameParts = fullName.split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts[0] : 'N/A';
          final lastName =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'N/A';

          final imagePath = userData['credential'] as String?;
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
                                  key: imageKey,
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
                  const SizedBox(height: 20),
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
                    value: userData['nationalId'] ?? 'N/A',
                  ),
                  const SizedBox(height: 20),
                  RectangularField(
                    label: 'Phone Number',
                    value: userData['phoneNumber'] ?? 'N/A',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: RectangularField(
                          label: 'Blood Type',
                          value: userData['bloodType'] ?? 'N/A',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RectangularField(
                          label: 'Role',
                          value: userData['role'] ?? 'N/A',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  RectangularField(
                    label: 'Address',
                    value: userData['address'] ?? 'N/A',
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.deleteAccount(context),
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
                                      EditProfileScreen(userData: userData),
                            ),
                          );
                          if (updatedPath != null && updatedPath.isNotEmpty) {
                            controller.updateProfileImage(updatedPath);
                          }
                        },
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
