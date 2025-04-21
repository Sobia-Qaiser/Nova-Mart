import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/admin_dashboard.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/sidebar_screen/category_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/sidebar_screen/orders_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/sidebar_screen/products_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/sidebar_screen/upload_banner_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/sidebar_screen/vendor_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/sidebar_screen/withdrawl_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Customer/login_screen.dart';
import 'component.dart';

class DrawerContent extends StatefulWidget {
  const DrawerContent({super.key});

  @override
  State<DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<DrawerContent> {
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFFF4A49),
            ),
            accountName: const Text("NovaMart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Lora',)),
            accountEmail: const Text("Welcome To Admin Panel"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 50,
              child: Image.asset('assets/images/logo3.png', width: 50),
            ),
          ),
          _buildSpacedListTile(
            icon: Icons.dashboard,
            title: "Dashboard",
            onTap: () => _navigateTo(AdminDashboard()),
          ),
          _buildSpacedListTile(
            icon: Icons.person_3,
            title: "Vendors",
            onTap: () => _navigateTo(SellerManagementPage()),
          ),
          _buildSpacedListTile(
            icon: Icons.attach_money,
            title: "Withdraw",
            onTap: () => _navigateTo(WithdrawlScreen()),
          ),
          _buildSpacedListTile(
            icon: Icons.shopping_cart,
            title: "Orders",
            onTap: () => _navigateTo(OrderScreen()),
          ),
          _buildSpacedListTile(
            icon: Icons.category,
            title: "Categories",
            onTap: () => _navigateTo(CategoryScreen()),
          ),
          _buildSpacedListTile(
            icon: Icons.shop,
            title: "Products",
            onTap: () => _navigateTo(ProductScreen()),
          ),
          _buildSpacedListTile(
            icon: Icons.add,
            title: "Upload Banners",
            onTap: () => _navigateTo(UploadBannerScreen()),
          ),
          Container(
            margin: const EdgeInsets.only(top: 0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFFF4A49)),
              title: const Text("Log Out", style: CustomTextStyles.customTextStyle),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacedListTile({required IconData icon, required String title, required Function() onTap}) {
    return Container(
      margin: const EdgeInsets.only(top: 1),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF4A49)),
        title: Text(title, style: CustomTextStyles.customTextStyle),
        onTap: onTap,
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}