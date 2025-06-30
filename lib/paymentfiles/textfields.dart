import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReusableTextField extends StatefulWidget {
  const ReusableTextField({super.key, required this.title, required this.hint, this.isNumber, required this.controller, required this.formkey,required this.readOnly});
  final String title, hint;
  final bool? isNumber;
  final TextEditingController controller;
  final Key formkey;
  final bool readOnly;
  @override
  State<ReusableTextField> createState() => _ReusableTextFieldState();
}

class _ReusableTextFieldState extends State<ReusableTextField> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formkey,
      child: TextFormField(keyboardType: widget.isNumber == null
          ? TextInputType.text
          : TextInputType.number,
        decoration: InputDecoration(
            label: Text(widget.title),
            hintText: widget.hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.blue, // Color when the input field is focused
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value!.isEmpty ? "Cannot be empty" : null,
        controller: widget.controller,
        readOnly: widget.readOnly,
      ),
    );
  }
}