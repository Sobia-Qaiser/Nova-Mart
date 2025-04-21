import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../controllers/auth_controller.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? _errorText;
  bool _isLoading = false;

  void resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        await _auth.sendPasswordResetEmail(email: _emailController.text);
        Get.snackbar(
          "Success",
            "Password reset email sent! Check Inbox.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blueGrey[800], // Error वाले dark blue background
          colorText: Colors.white, // White text
          icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30), // Bright green icon
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3), // Same duration

        );
        await Future.delayed(Duration(seconds: 2));

        Get.off(() => LoginScreen());
      } catch (e) {
        setState(() {
          _errorText = "Something went wrong. Try again.";
        });

        // Show Snackbar for error
        Get.snackbar(
          "Error",
          "Failed to send reset email. Please try again.",
          backgroundColor: Colors.blueGrey[800], // Dark Blue
          colorText: Colors.white,
          icon: Icon(Icons.cancel, color: Colors.white, size: 30),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 3),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Forgot password",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please, enter your email address. You will receive a link to create a new password via email.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              /// Email Input Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  errorText: _errorText,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter your email";
                  } else if (!RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$').hasMatch(value)) {
                    return "Not a valid email address";
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _errorText = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              /// Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : resetPassword, // Disable button while loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Keep the button red
                    foregroundColor: Colors.white, // Ensure text color stays white
                    disabledBackgroundColor: Colors.red, // Keep red color when disabled
                    disabledForegroundColor: Colors.white, // Keep white text when disabled
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white, // Keep spinner white
                      strokeWidth: 2,
                    ),
                  )
                      : const Text("SEND", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}