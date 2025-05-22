import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/services/WebSocketService.dart';
import 'package:lorescue/widgets/custom_text_field.dart';
import 'package:lorescue/widgets/custom_button.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/services/database/user_service.dart';

import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:crypto/crypto.dart'; // Hashing package

// Hash function using SHA-256
String hashPassword(String password) {
  final bytes = utf8.encode(password); // Convert password to bytes
  final digest = sha256.convert(bytes); // Apply SHA-256 hash
  return digest.toString(); // Return hashed string
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

// Check if connected to Wi-Fi
Future<bool> connectedToWifi() async {
  final info = NetworkInfo();
  final ssid = await info.getWifiName();
  return ssid != null && ssid.contains("Lorescue");
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedRole;
  final List<String> roles = ["Individual", "Admin", "Responder"];
  final webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    checkWebSocket();
  }
void checkWebSocket() {
    if (!webSocketService.isConnected) {
      webSocketService.connect('ws://192.168.4.1:81');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _register() async {
    bool isConnectedToWifi = await connectedToWifi();
    if (!isConnectedToWifi) {
      showDialog(
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
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for existing user
    bool exists = await _userService.doesNationalIdExist(
      _nationalIdController.text,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("National ID already exists"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hashedPassword = hashPassword(_passwordController.text);
    print("🔐 Hashed password: $hashedPassword");

    final now = DateTime.now().toIso8601String();

    // Create user object
    User newUser = User(
      name: _usernameController.text,
      nationalId: _nationalIdController.text,
      password: hashedPassword,
      role: _selectedRole!,
      connectedZoneId: "0",
      createdAt: now,
    );

    await _userService.registerUser(newUser);

    // Prepare JSON to send via WebSocket
    Map<String, dynamic> accountData = {
      "type": "register",
      "name": _usernameController.text,
      "national_id": _nationalIdController.text,
      "password": hashedPassword,
      "role": _selectedRole,
      "connectedZoneId": "0",
      "createdAt": now,
    };

    //_channel.sink.add(jsonEncode(accountData));
    webSocketService.send(jsonEncode(accountData));


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registration successful!"),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to login after delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromRGBO(247, 247, 246, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Image.asset(
                  'assets/images/logo.png',
                  width: 120.w,
                  height: 120.h,
                ),
                SizedBox(height: 20.h),
                Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  "Create a new account",
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                ),
                SizedBox(height: 30.h),

                // Username
                CustomTextField(
                  label: "Username",
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Username is required";
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

                // National ID
                CustomTextField(
                  label: "National ID",
                  controller: _nationalIdController,
                  isNumber: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "National ID is required";
                    if (!RegExp(r'^\d{10}$').hasMatch(value))
                      return "National ID must be exactly 10 digits";
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: "Select Role",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  items:
                      roles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator:
                      (value) => value == null ? "Please select a role" : null,
                ),
                SizedBox(height: 15.h),

                // Password
                CustomTextField(
                  label: "Create Password",
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Password is required";
                    if (value.length < 8)
                      return "Password must be at least 8 characters";
                    if (!RegExp(r'(?=.*[a-z])').hasMatch(value))
                      return "Include a lowercase letter";
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value))
                      return "Include an uppercase letter";
                    if (!RegExp(r'(?=.*[!@#\$&*~%^])').hasMatch(value))
                      return "Include a special character";
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

                // Confirm Password
                CustomTextField(
                  label: "Confirm Password",
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Please confirm your password";
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                CustomButton(text: "Sign up", onPressed: _register),
                SizedBox(height: 15.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.pushNamed(context, AppRoutes.login),
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.blue, fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
