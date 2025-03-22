import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/widgets/custom_text_field.dart';
import 'package:lorescue/widgets/custom_button.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/services/database/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    String? userRole = await _userService.loginUser(
      _nationalIdController.text,
      _passwordController.text,
    );

    if (userRole != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login successful! Role: $userRole"),
          backgroundColor: Colors.green,
        ),
      );

      // Redirect based on role
      if (userRole == 'Admin') {
        Navigator.pushNamed(context, AppRoutes.channels);
      } else if (userRole == 'Responder') {
        Navigator.pushNamed(context, AppRoutes.verification);
      } else {
        Navigator.pushNamed(context, AppRoutes.home);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid National ID or Password"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  "Welcome to LoRescue",
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  "Login to your account",
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                ),
                SizedBox(height: 30.h),

                CustomTextField(
                  label: "National ID",
                  controller: _nationalIdController,
                  isNumber: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "National ID is required";
                    }
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return "National ID must be exactly 10 digits";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

                CustomTextField(
                  label: "Password",
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 8) {
                      return "Password must be at least 8 characters";
                    }
                    if (!RegExp(
                      r'(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$&*~%^])',
                    ).hasMatch(value)) {
                      return "Must include uppercase, lowercase & special character";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.h),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.red, fontSize: 14.sp),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                CustomButton(text: "Login", onPressed: _login),

                SizedBox(height: 15.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    TextButton(
                      onPressed:
                          () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                      child: Text(
                        "Create Now",
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
