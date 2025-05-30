import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/controllers/user_controller.dart';
import 'package:lorescue/widgets/custom_text_field.dart';
import 'package:lorescue/widgets/custom_button.dart';
import 'package:lorescue/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _viewModel = UserController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _onLoginPressed() {
    _viewModel.login(
      context: context,
      nationalId: _nationalIdController.text,
      password: _passwordController.text,
      formKey: _formKey,
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
                    if (value == null || value.isEmpty)
                      return "National ID is required";
                    if (!RegExp(r'^\d{10}$').hasMatch(value))
                      return "Must be exactly 10 digits";
                    return null;
                  },
                ),
                SizedBox(height: 15.h),
                CustomTextField(
                  label: "Password",
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Password is required";
                    if (value.length < 8)
                      return "Must be at least 8 characters";
                    if (!RegExp(
                      r'(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$&*~%^])',
                    ).hasMatch(value))
                      return "Include uppercase, lowercase & special character";
                    return null;
                  },
                ),
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
                CustomButton(text: "Login", onPressed: _onLoginPressed),
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
