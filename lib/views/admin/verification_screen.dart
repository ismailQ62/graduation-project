import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _verify() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    await Future.delayed(
      const Duration(seconds: 2),
    ); // simulate verification delay

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Verified successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // go back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/verification_icon.png',
              width: 100.w,
              height: 100.h,
            ),

            SizedBox(height: 20.h),

            Text(
              "Verification",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 5.h),

            Text(
              "Please Upload Your Credential",
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),

            SizedBox(height: 30.h),

            ElevatedButton.icon(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
              ),
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text(
                "Upload",
                style: TextStyle(fontSize: 16.sp, color: Colors.white),
              ),
            ),

            SizedBox(height: 20.h),

            _selectedImage != null
                ? Column(
                  children: [
                    Image.file(_selectedImage!, width: 200.w, height: 200.h),
                    SizedBox(height: 10.h),
                  ],
                )
                : const SizedBox.shrink(),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    "Verify",
                    style: TextStyle(fontSize: 18.sp, color: Colors.white),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
