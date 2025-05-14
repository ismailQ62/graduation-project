import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lorescue/services/auth_service.dart';
import 'package:lorescue/routes.dart';

class UploadVerificationScreen extends StatefulWidget {
  const UploadVerificationScreen({super.key});

  @override
  State<UploadVerificationScreen> createState() =>
      _UploadVerificationScreenState();
}

class _UploadVerificationScreenState extends State<UploadVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String? _selectedRole;
  late IOWebSocketChannel _channel;

  final List<String> _roles = ['Police', 'Fire', 'Paramedic'];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');
  }

  @override
  void dispose() {
    _channel.sink.close();
    _descController.dispose();
    super.dispose();
  }

  void _sendTextCredentials() async {
    final user = AuthService.getCurrentUser();
    if (!_formKey.currentState!.validate() || user == null) return;

    setState(() => _isSending = true);

    final payload = {
      "type": "license_text",
      "senderID": user.nationalId,
      "username": user.name,
      "role": _selectedRole,
      "description": _descController.text.trim(),
    };

    print("📤 Sending Credentials:");
    print("👤 Name       : ${user.name}");
    print("🆔 National ID: ${user.nationalId}");
    print("🎓 Role       : $_selectedRole");
    print("📝 Description: ${_descController.text.trim()}");

    try {
      _channel.sink.add(jsonEncode(payload));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Credentials sent to admin!")),
      );
    } catch (e) {
      print("❌ Error sending WebSocket message: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to send.")));
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  "Responder Credential Verification",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Role",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  items:
                      _roles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                  value: _selectedRole,
                  onChanged: (val) => setState(() => _selectedRole = val),
                  validator:
                      (val) => val == null ? 'Please select a role' : null,
                ),
                SizedBox(height: 20.h),

                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Description ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  validator:
                      (val) =>
                          val == null || val.trim().isEmpty
                              ? "Please enter a description"
                              : null,
                ),
                SizedBox(height: 30.h),

                if (_isSending)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _sendTextCredentials,
                    icon: const Icon(Icons.send),
                    label: const Text("Send to Admin"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
