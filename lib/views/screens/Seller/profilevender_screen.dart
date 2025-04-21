import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/favorite_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/myorders.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/shophome_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/wlscreen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/ManageOrders.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/helpcentervendor.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/main_vendor_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/storedetails.dart';

import '../../../controllers/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  bool _notifications = true;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? _customerName;
  String? _customerEmail;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    if (_currentUser == null) return;

    final userSnapshot = await _database.child("users").child(_currentUser!.uid).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.value as Map<dynamic, dynamic>?;
      if (userData != null && userData["role"]?.toString().toLowerCase() == "vendor") {
        setState(() {
          _customerName = userData["businessName"]?.toString();
          _customerEmail = userData["email"]?.toString();
        });
      }
    }
  }

  Color _getIconColor(BuildContext context) {
    return themeController.isDarkMode.value
        ? Colors.white70
        : Colors.grey[700]!;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return const MainVendorScreen(initialIndex: 0);
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300), // optional
            ),
          ),



        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 10),
            _buildSettingsCard(context),
            const SizedBox(height: 10),
            _buildSupportCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      elevation: 1,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: themeController.isDarkMode.value
                  ? Colors.blueGrey[800]
                  : Colors.blue.shade100,
              child: Icon(
                Icons.store,
                size: 30,
                color: themeController.isDarkMode.value
                    ? Colors.blueGrey[200]
                    : Colors.blue.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _customerName ?? 'Guest User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified,
                      color: themeController.isDarkMode.value
                          ? Colors.blue[200]
                          : Colors.blue.shade700,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _customerEmail ?? 'No email provided',
                  style: TextStyle(
                    color: themeController.isDarkMode.value
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      elevation: 1,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'SETTINGS & PREFERENCES',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          _buildSettingItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: Switch(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          _buildDivider(context),
          _buildSettingItem(
            context,
            icon: Icons.store_mall_directory_outlined,
            title: 'My Store',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => StoreDetails(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Fade transition example
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          _buildDivider(context),
          _buildSettingItem(
            context,
            icon: Icons.language_outlined,
            title: 'Language',
            trailing: Text(
              'English',
              style: TextStyle(
                fontSize: 14,
                color: themeController.isDarkMode.value
                    ? Colors.grey[300]
                    : Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          _buildDivider(context),
          _buildSettingItem(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Obx(() => Switch(
              value: themeController.isDarkMode.value,
              onChanged: (value) => themeController.toggleTheme(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Card(
      elevation: 1,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'SUPPORT',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          _buildSettingItem(
            context,
            icon: Icons.help_outline_outlined,
            title: 'Help Center',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => HelpCenterScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Fade transition example
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },


          ),
          _buildDivider(context),
          _buildSettingItem(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            color: const Color(0xFFFF4A49),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: themeController.isDarkMode.value
          ? Colors.grey[700]
          : Colors.grey[200],
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        Widget? trailing,
        Function()? onTap,
        Color? color,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(
        icon,
        size: 22,
        color: color ?? _getIconColor(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      minLeadingWidth: 24,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Log Out',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: themeController.isDarkMode.value
                  ? Colors.grey[800]
                  : Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: themeController.isDarkMode.value
                    ? Colors.white70
                    : Colors.grey.shade800,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ShoppingScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: const Color(0xFFFF4A49),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}