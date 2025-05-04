import 'package:flutter/material.dart';
import 'package:lorescue/services/database/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({required this.userData, super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController nationalIdController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController passwordController;

  String selectedBloodType = 'A+';
  String selectedRole = 'Individual';

  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> roles = ['Responder', 'Admin', 'Individual'];

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    final fullName = widget.userData['name'] ?? '';
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    firstNameController = TextEditingController(text: firstName);
    lastNameController = TextEditingController(text: lastName);
    nationalIdController = TextEditingController(
      text: widget.userData['nationalId'],
    );
    phoneController = TextEditingController(
      text: widget.userData['phoneNumber'],
    );
    addressController = TextEditingController(text: widget.userData['address']);
    passwordController = TextEditingController(
      text: widget.userData['password'],
    );
    selectedBloodType = widget.userData['bloodType'] ?? 'A+';
    selectedRole = widget.userData['role'] ?? 'Individual';
  }

  Future<void> _saveChanges() async {
    final db = await _dbService.database;
    try {
      final fullName =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}';

      await db.update(
        'users',
        {
          'name': fullName,
          'phoneNumber': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'bloodType': selectedBloodType,
          'role': selectedRole,
          'password': passwordController.text.trim(),
        },
        where: 'nationalId = ?',
        whereArgs: [nationalIdController.text.trim()],
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  Widget _buildFieldCard(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(45, 37, 95, 255).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  Widget _buildDropdownCard(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(45, 37, 95, 255).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items:
            items
                .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildFieldCard('First Name', firstNameController),
            _buildFieldCard('Last Name', lastNameController),
            _buildFieldCard(
              'National ID',
              nationalIdController,
              readOnly: true,
            ),
            _buildFieldCard('Phone Number', phoneController),
            _buildFieldCard('Address', addressController),
            _buildFieldCard('Password', passwordController),
            _buildDropdownCard(
              'Blood Type',
              bloodTypes,
              selectedBloodType,
              (val) => setState(() => selectedBloodType = val!),
            ),
            _buildDropdownCard(
              'Role',
              roles,
              selectedRole,
              (val) => setState(() => selectedRole = val!),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel, color: Colors.black),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
