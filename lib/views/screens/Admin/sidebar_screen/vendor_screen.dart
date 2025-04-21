import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SellerManagementPage extends StatefulWidget {
  const SellerManagementPage({super.key});

  @override
  State<SellerManagementPage> createState() => _SellerManagementPageState();
}

class _SellerManagementPageState extends State<SellerManagementPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('users');
  final List<Map<String, dynamic>> _vendorList = [];

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  void _fetchVendors() {
    EasyLoading.show(
      status: 'Loading Vendors...',
      maskType: EasyLoadingMaskType.black,
    );
    _database.orderByChild('role').equalTo('Vendor').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      _vendorList.clear();
      if (data != null) {
        data.forEach((key, value) {
          _vendorList.add({
            "userId": key,
            "fullName": value["fullName"] ?? "No Name",
            "email": value["email"] ?? "No Email",
            "businessName": value["businessName"] ?? "N/A",
            "phoneNumber": value["phoneNumber"]?.toString() ?? "N/A",
            "address": value["address"] ?? "N/A",
            "status": value["status"] ?? "pending",
          });
        });
      }
      setState(() {});
      EasyLoading.dismiss();
    }).onError((error) {
      EasyLoading.dismiss();
      EasyLoading.showError('Failed to load vendors\n${error.toString()}');
    });
  }
  Future<void> _updateSellerStatus(String userId, String newStatus) async {
    try {
      await _database.child(userId).update({'status': newStatus});

      // Update local state immediately
      final index = _vendorList.indexWhere((v) => v['userId'] == userId);
      if (index != -1) {
        setState(() {
          _vendorList[index]['status'] = newStatus;
        });
      }
    } catch (e) {
      EasyLoading.showError('Update failed');
    }
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vendors',
            style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lora')),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF4A49),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.grey.shade50],
          ),
        ),
        child: _vendorList.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'No Vendors Found',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Lora',
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 8,
            radius: const Radius.circular(4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: DataTable(
                    headingRowColor:
                    MaterialStateProperty.resolveWith<Color>(
                            (states) => Colors.pink.shade50),
                    columnSpacing: 30,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(
                          label: Text('Full Name',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Email',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Business Name',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Phone Number',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Address',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Action',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.bold))),
                    ],
                    rows: _vendorList.map((vendor) {
                      return DataRow(
                        cells: [
                          DataCell(Text(vendor['fullName'],
                              style: const TextStyle(
                                  fontSize: 15, fontFamily: 'Lora'))),
                          DataCell(Text(vendor['email'],
                              style: const TextStyle(
                                  fontSize: 15, fontFamily: 'Lora'))),
                          DataCell(Text(vendor['businessName'],
                              style: const TextStyle(
                                  fontSize: 15, fontFamily: 'Lora'))),
                          DataCell(Text(vendor['phoneNumber'],
                              style: const TextStyle(
                                  fontSize: 15, fontFamily: 'Lora'))),
                          DataCell(Text(vendor['address'],
                              style: const TextStyle(
                                  fontSize: 15, fontFamily: 'Lora'))),
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                        vendor['status']),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _capitalizeFirstLetter(
                                      vendor['status']),
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: _getStatusColor(
                                          vendor['status']),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Lora'),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            DropdownButton<String>(
                              value: vendor['status'],
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'approved',
                                  child: Text('Approved',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Lora')),
                                ),
                                DropdownMenuItem(
                                  value: 'rejected',
                                  child: Text('Rejected',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Lora')),
                                ),
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Pending',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Lora')),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _updateSellerStatus(
                                      vendor['userId'], value);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      case 'pending':
      default:
        return Colors.orange.shade600;
    }
  }
}