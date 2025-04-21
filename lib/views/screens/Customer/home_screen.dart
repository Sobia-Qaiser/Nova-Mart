import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/profile_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/shophome_screen.dart';

import 'cart_screen.dart';
import 'category_screen.dart';
import 'favorite_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int pageIndex;
  int cartItemCount = 0;
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref('carts');
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    pageIndex = widget.initialIndex;
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadCartCount();
  }

  void _loadCartCount() {
    _cartRef.child(_currentUser?.uid ?? '').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final totalItems = data.values.fold<int>(0, (sum, item) {
          return sum + (item['quantity'] as int? ?? 1);
        });
        setState(() => cartItemCount = totalItems);
      } else {
        setState(() => cartItemCount = 0);
      }
    });
  }

  List<Widget> pages = [
    ShopHome(),
    CategoryScreen(),
    CartScreen(),
    FavoriteScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (value) => setState(() => pageIndex = value),
        currentIndex: pageIndex,
        selectedItemColor: const Color(0xFFFF4A49),
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.black,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        items: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'HOME', 0),
          _buildNavItem(Icons.category_outlined, Icons.category, 'CATEGORIES', 1),
          _buildNavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'CART', 2),
          _buildNavItem(Icons.favorite_border, Icons.favorite, 'FAVORITE', 3),
          _buildNavItem(Icons.person_outline, Icons.person, 'ACCOUNT', 4),
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

    // Base icon widget
    Widget iconWidget = Container(
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
    );

    // Add badge only for cart icon
    if (label == 'CART' && cartItemCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                cartItemCount.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      );
    }

    return BottomNavigationBarItem(
      icon: iconWidget,
      label: label,
    );
  }
}