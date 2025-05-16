import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:multi_vendor_ecommerce_app/controllers/auth_controller.dart';



class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key});

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  final AuthController _authController = AuthController();
  String userName = "Vendor";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorName();
  }

  Future<void> _loadVendorName() async {
    try {
      final name = await _authController.getCurrentVendorName();
      if (mounted) {
        setState(() {
          userName = name ?? "Vendor";
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint("Error loading vendor name: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
      appBar: AppBar(

        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFFFF4A49) : const Color(0xFFFF4A49),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hi, $userName! 👋",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(
        child: Text(
          'Earning Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}