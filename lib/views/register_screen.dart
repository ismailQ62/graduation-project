import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/user_controller.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/widgets/custom_button.dart';
import 'package:lorescue/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = UserController();

  final List<String> roles = ["Individual", "Admin", "Responder"];

  @override
  void initState() {
    super.initState();
    _controller.initWebSocket();
  }

  void _handleRegister() async {
    final result = await _controller.register(context, _formKey);

    if (result == "wifi_error") {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("No Wi-Fi Connection"),
              content: const Text("Please connect to any WiFi."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } else if (result == "password_mismatch") {
      _showError("Passwords do not match");
    } else if (result == "duplicate_id") {
      _showError("National ID already exists");
    } else if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration successful!"),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamed(context, AppRoutes.login);
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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

                CustomTextField(
                  label: "Username",
                  controller: _controller.usernameController,
                  validator:
                      (value) => value!.isEmpty ? "Username is required" : null,
                ),
                SizedBox(height: 15.h),

                CustomTextField(
                  label: "National ID",
                  controller: _controller.nationalIdController,
                  isNumber: true,
                  validator: (value) {
                    if (value!.isEmpty) return "National ID is required";
                    if (!RegExp(r'^\d{10}$').hasMatch(value))
                      return "Must be 10 digits";
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

                DropdownButtonFormField<String>(
                  value: _controller.selectedRole,
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
                  onChanged:
                      (value) =>
                          setState(() => _controller.selectedRole = value),
                  validator:
                      (value) => value == null ? "Please select a role" : null,
                ),
                SizedBox(height: 15.h),

                CustomTextField(
                  label: "Create Password",
                  controller: _controller.passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value!.isEmpty) return "Password is required";
                    if (value.length < 8) return "Min 8 characters";
                    if (!RegExp(r'(?=.*[a-z])').hasMatch(value))
                      return "Include lowercase";
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value))
                      return "Include uppercase";
                    if (!RegExp(r'(?=.*[!@#\$&*~%^])').hasMatch(value))
                      return "Include special char";
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

                CustomTextField(
                  label: "Confirm Password",
                  controller: _controller.confirmPasswordController,
                  isPassword: true,
                  validator:
                      (value) =>
                          value!.isEmpty ? "Confirm your password" : null,
                ),
                SizedBox(height: 20.h),

                CustomButton(text: "Sign up", onPressed: _handleRegister),
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
