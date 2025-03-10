import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/widgets/custom_text_field.dart';
import 'package:lorescue/widgets/custom_button.dart';
import 'package:lorescue/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // ignore: unused_field
  final bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // ✅ Prevents UI shifting when keyboard appears
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // ✅ Prevents overflow errors
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
              ), // ✅ Adjusted top spacing

              Image.asset(
                'assets/images/logo.png',
                width: 120.w,
                height: 120.h,
              ),

              SizedBox(height: 20.h),
              Text(
                "Welcome",
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5.h),
              Text(
                "Login to your account",
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
              SizedBox(height: 30.h),

              CustomTextField(
                label: "Username",
                controller: _usernameController,
              ),
              SizedBox(height: 15.h),

              CustomTextField(
                label: "Password",
                controller: _passwordController,
                isPassword: true,
              ),
              SizedBox(height: 10.h),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Forgot password logic
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              CustomButton(
                text: "Login",
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.home);
                },
              ),

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
                        () => Navigator.pushNamed(context, AppRoutes.register),
                    child: Text(
                      "Create Now",
                      style: TextStyle(color: Colors.blue, fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ), // ✅ Adjust bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}
