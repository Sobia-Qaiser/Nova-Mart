import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/main_vendor_screen.dart';

class ManageOrders extends StatelessWidget {
  const ManageOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Manage Orders',
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
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontFamily: 'Poppins',
            ),
            tabs: [
              Tab(text: 'New'),
              Tab(text: 'Processing'),
              Tab(text: 'Delivered'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Content for New orders tab
            Center(child: Text('New Orders Content')),
            // Content for Processing orders tab
            Center(child: Text('Processing Orders Content')),
            // Content for Delivered orders tab
            Center(child: Text('Delivered Orders Content')),
            // Content for Cancelled orders tab
            Center(child: Text('Cancelled Orders Content')),
          ],
        ),
      ),
    );
  }
}