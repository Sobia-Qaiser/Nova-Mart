import 'package:flutter/material.dart';
import 'package:multi_vendor_ecommerce_app/draweradminside.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: DrawerContent(),
      body: Column(
        children: [

        ],
      ),
    );
  }
}
