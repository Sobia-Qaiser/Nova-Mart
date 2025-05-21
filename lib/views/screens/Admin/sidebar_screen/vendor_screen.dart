import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class SellerManagementPage extends StatefulWidget {
  const SellerManagementPage({super.key});

  @override
  State<SellerManagementPage> createState() => _SellerManagementPageState();
}

class _SellerManagementPageState extends State<SellerManagementPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('users');
  final List<Map<String, dynamic>> _vendorList = [];
  final List<Map<String, dynamic>> _displayedVendors = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _vendorsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  void _fetchVendors() {
    setState(() => _isLoading = true);
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
      _updateDisplayedVendors();
      setState(() => _isLoading = false);
    }).onError((error) {
      setState(() => _isLoading = false);
      Get.snackbar(
        "Error",
        "Failed to load vendors: ${error.toString()}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
    });
  }

  void _updateDisplayedVendors() {
    final startIndex = (_currentPage - 1) * _vendorsPerPage;
    final endIndex = startIndex + _vendorsPerPage;

    setState(() {
      _displayedVendors.clear();
      if (startIndex < _vendorList.length) {
        _displayedVendors.addAll(
          _vendorList.sublist(
            startIndex,
            endIndex < _vendorList.length ? endIndex : _vendorList.length,
          ),
        );
      }
    });
  }

  void _nextPage() {
    if (_currentPage * _vendorsPerPage < _vendorList.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedVendors();
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateDisplayedVendors();
      });
    }
  }

  Future<void> _updateSellerStatus(String userId, String newStatus) async {
    try {
      await _database.child(userId).update({'status': newStatus});
      final index = _vendorList.indexWhere((v) => v['userId'] == userId);
      if (index != -1) {
        setState(() {
          _vendorList[index]['status'] = newStatus;
          _updateDisplayedVendors();
        });
      }
      Get.snackbar(
        "Success",
        "Status updated successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
        shouldIconPulse: false,
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
        margin: const EdgeInsets.all(10),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Update failed",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
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
        title: const Text(
          'Vendors',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF4A49),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF4A49)),
        ),
      )
          : _vendorList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Vendors Found',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Poppins',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
                ),
              ),
              child: Padding(
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
                                label: Text('Sr#',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Full Name',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Email',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Business Name',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Phone Number',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Address',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Status',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Action',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: _displayedVendors.asMap().entries.map((entry) {
                            final index = entry.key + 1 + ((_currentPage - 1) * _vendorsPerPage);
                            final vendor = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text(index.toString(),
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(vendor['fullName'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(vendor['email'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(vendor['businessName'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(vendor['phoneNumber'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(vendor['address'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
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
                                            fontFamily: 'Poppins'),
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
                                                fontFamily: 'Poppins')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'rejected',
                                        child: Text('Rejected',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'Poppins')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'pending',
                                        child: Text('Pending',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'Poppins')),
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
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: _prevPage,
                  color: _currentPage > 1 ? const Color(0xFFFF4A49) : Colors.grey,
                ),
                Text(
                  'Page $_currentPage of ${(_vendorList.length / _vendorsPerPage).ceil()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _nextPage,
                  color: _currentPage * _vendorsPerPage < _vendorList.length
                      ? const Color(0xFFFF4A49)
                      : Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
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