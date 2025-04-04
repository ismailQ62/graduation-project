import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/widgets/custom_text_field.dart';
import 'package:lorescue/widgets/custom_button.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/services/database/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
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

  void _register() async {
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

    bool exists = await _userService.doesNationalIdExist(
      _nationalIdController.text,
    );
    if (exists) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("National ID already exists"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    User newUser = User(
      name: _usernameController.text,
      nationalId: _nationalIdController.text,
      password: _passwordController.text,
      role: _selectedRole!,
    );

    await _userService.registerUser(newUser);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registration successful!"),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      // ignore: use_build_context_synchronously
      Navigator.pushNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color.fromRGBO(247, 247, 246, 1),
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

                CustomTextField(
                  label: "Username",
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Username is required";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

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
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (value) {
                    if (value == null) {
                      return "Please select a role";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 15.h),

                CustomTextField(
                  label: "Create Password",
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    // ignore: unused_label
                    validator:
                    (value) {
                      if (value == null || value.isEmpty) {
                        return "Password is required";
                      }
                      if (value.length < 8) {
                        return "Password must be at least 8 characters";
                      }
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                        return "Password must contain a lowercase letter";
                      }
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                        return "Password must contain an uppercase letter";
                      }
                      if (!RegExp(r'(?=.*[!@#\$&*~%^])').hasMatch(value)) {
                        return "Password must include a special character";
                      }
                      return null;
                    };
                  },
                ),
                SizedBox(height: 15.h),

                CustomTextField(
                  label: "Confirm Password",
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your password";
                    }
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
