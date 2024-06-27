import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool? readOnly;

  CustomTextField({
    required this.controller,
    required this.label,
    this.obscureText = false, this.keyboardType, this.readOnly
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: TextField(
        inputFormatters: [
          keyboardType == TextInputType.number ? FilteringTextInputFormatter.digitsOnly : FilteringTextInputFormatter.singleLineFormatter,
        ],
        keyboardType: keyboardType,
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly ?? false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }
}
