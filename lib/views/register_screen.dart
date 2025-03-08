import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/widgets/custom_text_field.dart';

import 'package:lorescue/widgets/custom_button.dart';

import 'package:lorescue/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedRole;

  final List<String> roles = ["Individual", "Admin", "Responder"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 120.w, height: 120.h),
            SizedBox(height: 20.h),
            Text(
              "Register",
              style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5.h),
            Text(
              "Create a new account",
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            SizedBox(height: 30.h),

            // Username Field
            CustomTextField(label: "Username", controller: _usernameController),

            SizedBox(height: 15.h),

            // National ID Field
            CustomTextField(
              label: "National ID",
              controller: _nationalIdController,
              isNumber: true,
            ),

            SizedBox(height: 15.h),

            // Select Role Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: "Select Role",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              items:
                  roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
            ),

            SizedBox(height: 15.h),

            // Password Field
            CustomTextField(
              label: "Create Password",
              controller: _passwordController,
              isPassword: true,
            ),

            SizedBox(height: 15.h),

            // Confirm Password Field
            CustomTextField(
              label: "Confirm Password",
              controller: _confirmPasswordController,
              isPassword: true,
            ),

            SizedBox(height: 20.h),

            // Register Button
            CustomButton(
              text: "Sign up",
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            SizedBox(height: 15.h),

            // Login Redirect
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?",
                  style: TextStyle(fontSize: 14.sp),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(color: Colors.blue, fontSize: 14.sp),
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
