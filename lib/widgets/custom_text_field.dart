import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final bool isNumber; // ✅ Added validation for number-only fields

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.isNumber = false, // Default is false
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword,
          keyboardType:
              widget.isNumber ? TextInputType.number : TextInputType.text,
          onChanged: (value) {
            setState(() {
              if (widget.isNumber &&
                  value.isNotEmpty &&
                  !RegExp(r'^\d+$').hasMatch(value)) {
                _errorMessage =
                    "Invalid format! Only numbers allowed."; // ✅ Show error message
              } else {
                _errorMessage = null; // ✅ Clear error message
              }
            });
          },
          decoration: InputDecoration(
            labelText: widget.label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            errorText: _errorMessage, // ✅ Show error message in red if invalid
          ),
        ),
      ],
    );
  }
}
