import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/home_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/register_screen.dart';

import '../../../controllers/auth_controller.dart';
import '../Admin/admin_dashboard.dart';
import '../Seller/main_vendor_screen.dart';
import '../Seller/seller_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController= AuthController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool isLoading= false;

  late String email = "";
  late String Password = "";

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegEx = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegEx.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }


  /*void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        String res = await authController.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() => isLoading = false);

        // Convert to lowercase once and use consistently
        final role = res.toLowerCase();

        if (role == 'customer' || role == 'admin') {
          // Handle non-seller roles (customer, admin)
          Get.snackbar(
            "Success",
            "Successfully Signed In!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
            margin: const EdgeInsets.all(10),
          );

          // Redirect based on role
          await Future.delayed(Duration(seconds: 2));
          switch(role) {
            case 'customer':
              Get.offAll(() => HomeScreen());
              break;
            case 'admin':
              Get.offAll(() => AdminDashboard());
              break;
          }
        } else if (role == 'vendor') {
          // Handle seller role
          final snapshot = await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(FirebaseAuth.instance.currentUser!.uid)
              .once();

          if (snapshot.snapshot.value != null) {
            final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
            String status = userData['status']?.toString().toLowerCase() ?? 'approved';

            if (status == 'approved') {
              // Seller is approved
              Get.snackbar(
                "Success",
                "Successfully Signed In!",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );

              await Future.delayed(Duration(seconds: 2));
              Get.offAll(() => MainVendorScreen());
            } else if (status == 'pending') {
              // Seller is pending approval
              Get.snackbar(
                "Pending Approval",
                "Your account is pending approval. Please wait for admin approval.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.info, color: Colors.orange, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );
            } else if (status == 'rejected') {
              // Seller is rejected
              Get.snackbar(
                "Account Rejected",
                "Your account has been rejected.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );
            }
          }
        } else {
          // Handle invalid credentials
          Get.snackbar(
            "Error",
            "Invalid credentials! This User is not registered",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
            margin: const EdgeInsets.all(10),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        // Handle any exceptions here
        Get.snackbar(
          "Error",
          "There is something wrong",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );
      }
    }
  }*/


  /*void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        String res = await authController.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() => isLoading = false);

        // ✅ Handle unverified email case first
        if (res == 'email_not_verified') {
          Get.snackbar(
            "Email Not Verified",
            "Please verify your email first. Check your inbox for the verification email.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.warning, color: Colors.orange, size: 30),
            duration: const Duration(seconds: 5),
          );
          return;
        }

        // ✅ Proceed with role-based logic
        final role = res.toLowerCase();

        if (role == 'customer' || role == 'admin') {
          Get.snackbar(
            "Success",
            "Successfully Signed In!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
            margin: const EdgeInsets.all(10),
          );

          await Future.delayed(const Duration(seconds: 2));

          switch (role) {
            case 'customer':
              Get.offAll(() => HomeScreen());
              break;
            case 'admin':
              Get.offAll(() => AdminDashboard());
              break;
          }
        } else if (role == 'vendor') {
          final snapshot = await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(FirebaseAuth.instance.currentUser!.uid)
              .once();

          if (snapshot.snapshot.value != null) {
            final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
            String status = userData['status']?.toString().toLowerCase() ?? 'approved';

            if (status == 'approved') {
              Get.snackbar(
                "Success",
                "Successfully Signed In!",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );

              await Future.delayed(const Duration(seconds: 2));
              Get.offAll(() => MainVendorScreen());
            } else if (status == 'pending') {
              Get.snackbar(
                "Pending Approval",
                "Your account is pending approval. Please wait for admin approval.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.info, color: Colors.orange, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );
            } else if (status == 'rejected') {
              Get.snackbar(
                "Account Rejected",
                "Your account has been rejected.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );
            }
          }
        } else {
          Get.snackbar(
            "Error",
            "Invalid credentials! This User is not registered",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
            margin: const EdgeInsets.all(10),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        Get.snackbar(
          "Error",
          "There is something wrong",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );
      }
    }
  }*/


  /*void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        String res = await authController.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // ✅ Move loading state down so email_not_verified can exit early
        if (res == 'email_not_verified') {
          setState(() => isLoading = false); // 👈 ensure loader stops
          Get.snackbar(
            "Email Not Verified",
            "Please verify your email first. Check your inbox for the verification email.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.warning, color: Colors.orange, size: 30),
            duration: const Duration(seconds: 5),
          );
          return;
        }

        setState(() => isLoading = false); // ✅ keep this after email check

        // ✅ Proceed with role-based logic
        final role = res.toLowerCase();

        if (role == 'customer' || role == 'admin') {
          Get.snackbar(
            "Success",
            "Successfully Signed In!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
            margin: const EdgeInsets.all(10),
          );

          await Future.delayed(const Duration(seconds: 2));

          switch (role) {
            case 'customer':
              Get.offAll(() => HomeScreen());
              break;
            case 'admin':
              Get.offAll(() => AdminDashboard());
              break;
          }
        } else if (role == 'vendor') {
          final snapshot = await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(FirebaseAuth.instance.currentUser!.uid)
              .once();

          if (snapshot.snapshot.value != null) {
            final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
            String status = userData['status']?.toString().toLowerCase() ?? 'approved';

            if (status == 'approved') {
              Get.snackbar(
                "Success",
                "Successfully Signed In!",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );

              await Future.delayed(const Duration(seconds: 2));
              Get.offAll(() => MainVendorScreen());
            } else if (status == 'pending') {
              Get.snackbar(
                "Pending Approval",
                "Your account is pending approval. Please wait for admin approval.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.info, color: Colors.orange, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );
            } else if (status == 'rejected') {
              Get.snackbar(
                "Account Rejected",
                "Your account has been rejected.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                shouldIconPulse: false,
                snackStyle: SnackStyle.FLOATING,
                isDismissible: true,
                margin: const EdgeInsets.all(10),
              );
            }
          }
        } else {
          Get.snackbar(
            "Error",
            "Invalid credentials! This User is not registered",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
            margin: const EdgeInsets.all(10),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        Get.snackbar(
          "Error",
          "There is something wrong",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );
      }
    }
  }*/

  /*void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        String res = await authController.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() => isLoading = false);

        // ✅ If email is not verified
        if (res == 'email_not_verified') {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Email Not Verified"),
              content: const Text(
                "Please verify your email address. Would you like us to resend the verification email?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Re-sign-in to make sure currentUser is not null
                    try {
                      UserCredential userCredential =
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );

                      if (!userCredential.user!.emailVerified) {
                        await userCredential.user!.sendEmailVerification();
                        Get.snackbar(
                          "Verification Sent",
                          "Check your inbox. We've sent a new verification email.",
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.white,
                          colorText: Colors.black,
                          icon: const Icon(Icons.mark_email_read,
                              color: Colors.blue, size: 30),
                          duration: const Duration(seconds: 5),
                        );
                      }
                    } catch (e) {
                      Get.snackbar(
                        "Error",
                        "Could not resend verification email.",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.white,
                        colorText: Colors.black,
                        icon: const Icon(Icons.error, color: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4A49),
                  ),
                  child: const Text("Resend"),
                ),
              ],
            ),
          );
          return;
        }

        // ✅ Proceed with role-based logic
        final role = res.toLowerCase();

        if (role == 'customer' || role == 'admin') {
          Get.snackbar(
            "Success",
            "Successfully Signed In!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
          );

          await Future.delayed(const Duration(seconds: 2));

          switch (role) {
            case 'customer':
              Get.offAll(() => HomeScreen());
              break;
            case 'admin':
              Get.offAll(() => AdminDashboard());
              break;
          }
        } else if (role == 'vendor') {
          final snapshot = await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(FirebaseAuth.instance.currentUser!.uid)
              .once();

          if (snapshot.snapshot.value != null) {
            final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
            String status =
                userData['status']?.toString().toLowerCase() ?? 'approved';

            if (status == 'approved') {
              Get.snackbar(
                "Success",
                "Successfully Signed In!",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
              );

              await Future.delayed(const Duration(seconds: 2));
              Get.offAll(() => MainVendorScreen());
            } else if (status == 'pending') {
              Get.snackbar(
                "Pending Approval",
                "Your account is pending approval. Please wait for admin approval.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.info, color: Colors.orange, size: 30),
              );
            } else if (status == 'rejected') {
              Get.snackbar(
                "Account Rejected",
                "Your account has been rejected.",
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.white,
                colorText: Colors.black,
                icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              );
            }
          }
        } else {
          Get.snackbar(
            "Error",
            "Invalid credentials! This user is not registered.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        Get.snackbar(
          "Error",
          "Something went wrong.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    }
  }*/

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        String res = await authController.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // First check for email verification status
        if (res == 'email_not_verified') {
          setState(() => isLoading = false);
          _showEmailNotVerifiedDialog();
          return;
        }

        setState(() => isLoading = false);

        // Now handle role-based logic
        final role = res.toLowerCase();

        if (role == 'customer' || role == 'admin') {
          _handleSuccessfulLogin(role);
        }
        else if (role == 'vendor') {
          await _handleVendorLogin();
        }
        else if (res == 'pending_approval') {
          Get.snackbar(
            "Pending Approval",
            "Your account is pending approval. Please wait for admin approval.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.info, color: Colors.orange, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
          );
        }
        else if (res == 'Account rejected') {
          Get.snackbar(
            "Account Rejected",
            "Your account has been rejected.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
          );
        }
        else {
          // Handle invalid credentials
          Get.snackbar(
            "Error",
            "Invalid credentials! This user is not registered.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        Get.snackbar(
          "Error",
          e.toString(), // Show actual error message
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.error, color: Colors.red),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
        );
      }
    }
  }

 /* void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Email Not Verified"),
        content: const Text(
          "Please verify your email address. Would you like us to resend the verification email?",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8), // Less bottom padding
            child: GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                  Get.snackbar(
                    "Verification Sent",
                    "Check your inbox. We've sent a new verification email.",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.white,
                    colorText: Colors.black,
                    icon: const Icon(Icons.mark_email_read, color: Colors.orange, size: 30),
                    shouldIconPulse: false,
                    snackStyle: SnackStyle.FLOATING,
                    isDismissible: true,
                  );
                } catch (e) {
                  Get.snackbar(
                    "Error",
                    "Could not resend verification email: ${e.toString()}",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.white,
                    colorText: Colors.black,
                    icon: const Icon(Icons.error, color: Colors.red),
                    shouldIconPulse: false,
                    snackStyle: SnackStyle.FLOATING,
                    isDismissible: true,
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Reduced vertical padding
                child: Text(
                  "Resend",
                  style: TextStyle(
                    color: Color(0xFFFF4A49),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }*/// resend email code

  void _showEmailNotVerifiedDialog() {
    Get.snackbar(
      "Email Not Verified",
      "Please verify your email. Check your inbox for the verification email.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black,
      icon: const Icon(Icons.mark_email_read, color: Colors.orange, size: 30),
      shouldIconPulse: false,
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      margin: const EdgeInsets.all(10),
    );
  }




  void _handleSuccessfulLogin(String role) async {
    Get.snackbar(
      "Success",
      "Successfully Signed In!",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black,
      icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
      shouldIconPulse: false,
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
    );

    await Future.delayed(const Duration(seconds: 2));

    switch (role) {
      case 'customer':
        Get.offAll(() => HomeScreen());
        break;
      case 'admin':
        Get.offAll(() => AdminDashboard());
        break;
      default:
        Get.offAll(() => HomeScreen());
    }
  }

  Future<void> _handleVendorLogin() async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once();

    if (snapshot.snapshot.value != null) {
      final userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      String status = userData['status']?.toString().toLowerCase() ?? 'approved';

      if (status == 'approved') {
        Get.snackbar(
          "Success",
          "Successfully Signed In!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(() => MainVendorScreen());
      } else if (status == 'pending') {
        Get.snackbar(
          "Pending Approval",
          "Your account is pending approval. Please wait for admin approval.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.info, color: Colors.orange, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );
      } else if (status == 'rejected') {
        Get.snackbar(
          "Account Rejected",
          "Your account has been rejected.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFF4A49),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Welcome to NovaMart!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Icon(
                      Icons.shopping_cart,
                      size: 50,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        TextFormField(
                            onChanged: (value) {
                              email = value;
                            },
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: Color(0xFF333333),
                                fontFamily: 'Poppins',
                              ),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (value) => _validateEmail(value!),
                          ),

                        const SizedBox(height: 15), // Ye ek standalone widget hona chahiye
                        TextFormField(
                          onChanged: (value) {
                            Password = value;
                          },
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                              color: Color(0xFF333333),
                              fontFamily: 'Poppins',
                            ),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 9.0, bottom: 10.0), // Different padding for top and bottom
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>  ForgotPasswordScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                                },
                                ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),



                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4A49),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(color: Colors.white):
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) {
                                      return SignUpScreen();
                                    },
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Color(0xFFFF4A49),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
