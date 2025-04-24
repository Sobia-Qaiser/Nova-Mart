import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/Upload_Screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/earning_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/edit_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/profilevender_screen.dart';


class MainVendorScreen extends StatefulWidget {
  final int initialIndex;

  const MainVendorScreen({super.key, this.initialIndex = 0});


  @override
  State<MainVendorScreen> createState() => _MainVendorScreenState();
}

class _MainVendorScreenState extends State<MainVendorScreen> {
  late int pageIndex;

  List<Widget> pages = [
    EarningScreen(),
    UploadScreen(),
    VendorOrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    pageIndex = widget.initialIndex; // 👈 This solves the late init error
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (value) => setState(() => pageIndex = value),
        currentIndex: pageIndex,
        selectedItemColor: const Color(0xFFFF4A49), // Brand color remains same
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.black,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        items: [
          _buildNavItem(Icons.wallet_outlined, Icons.wallet, 'Earning', 0),
          _buildNavItem(Icons.add, Icons.add, 'Add', 1),
          _buildNavItem(Icons.list_outlined, Icons.list_rounded, 'Orders', 2),
          _buildNavItem(Icons.person_outline, Icons.person, 'Account', 3),
        ],
      ),
      body: pages[pageIndex],
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData outlineIcon,
      IconData filledIcon,
      String label,
      int index,
      ) {
    final bool isSelected = pageIndex == index;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.grey[800] : const Color(0xFFEEC7C8))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isSelected ? filledIcon : outlineIcon,
          size: 25,
          color: isSelected
              ? const Color(0xFFFF4A49)
              : (isDarkMode ? Colors.grey[400] : Colors.black),
        ),
      ),
      label: label,
    );
  }
}