import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Sellersidevendorhistory.dart';

class VendorPaymentsScreen extends StatefulWidget {
  const VendorPaymentsScreen({super.key});

  @override
  State<VendorPaymentsScreen> createState() => _VendorPaymentsScreenState();
}

class _VendorPaymentsScreenState extends State<VendorPaymentsScreen> {
  final DatabaseReference _paymentsRef = FirebaseDatabase.instance.ref('vendorPayments');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> _vendorPayments = [];
  List<Map<String, dynamic>> _displayedVendors = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _vendorsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<Map<String, dynamic>> createStripeTransfer({
    required int amount,
    required String destinationAccountId,
    required String serverUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'destinationAccountId': destinationAccountId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create transfer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating transfer: $e');
    }
  }

  void _fetchPaymentData() async {
    setState(() => _isLoading = true);
    _paymentsRef.onValue.listen((event) async {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        _vendorPayments.clear();

        if (data != null) {
          final vendors = data.entries.toList();

          // Sort by earned amount (descending)
          vendors.sort((a, b) {
            final aAmount = (b.value["earned"] ?? 0).toInt();
            final bAmount = (a.value["earned"] ?? 0).toInt();
            return aAmount.compareTo(bAmount);
          });

          for (int i = 0; i < vendors.length; i++) {
            try {
              final vendorData = Map<String, dynamic>.from(vendors[i].value as Map);
              final vendorDetails = await _fetchVendorDetails(vendors[i].key);
              final stripeAccountId = vendorDetails?['stripeAccountId']?.toString() ?? '';

              _vendorPayments.add({
                "vendorId": vendors[i].key,
                "srNo": i + 1,
                "vendorName": vendorData["vendorName"] ?? "Unknown",
                "businessName": vendorData["businessName"] ?? "Unknown",
                "weeklyEarning": (vendorData["earned"] ?? 0).toInt(),
                "paid": vendorData["paid"] ?? false,
                "stripeAccountId": stripeAccountId,
              });
            } catch (e) {
              debugPrint('Error processing vendor ${vendors[i].key}: $e');
            }
          }
        }

        _updateDisplayedVendors();
      } catch (e) {
        debugPrint('Error in payments listener: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }).onError((error) {
      debugPrint('Payments stream error: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchVendorDetails(String vendorId) async {
    try {
      final snapshot = await _usersRef.child(vendorId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching vendor details: $e');
      return null;
    }
  }

  void _updateDisplayedVendors() {
    final startIndex = (_currentPage - 1) * _vendorsPerPage;
    final endIndex = startIndex + _vendorsPerPage;

    setState(() {
      _displayedVendors.clear();
      if (startIndex < _vendorPayments.length) {
        _displayedVendors.addAll(
          _vendorPayments.sublist(
            startIndex,
            endIndex < _vendorPayments.length ? endIndex : _vendorPayments.length,
          ),
        );
      }
    });
  }

  void _nextPage() {
    if (_currentPage * _vendorsPerPage < _vendorPayments.length) {
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

  Future<void> _processPayment(String vendorId, int amount, String stripeAccountId) async {
    try {
      // Check if vendor has earnings to transfer
      if (amount <= 0) {
        Get.snackbar(
          "No Revenue",
          "No earnings to transfer this week",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.info, color: Colors.orange, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
        );
        return;
      }

      // Check for Stripe account
      if (stripeAccountId.isEmpty) {
        Get.snackbar(
          "Account",
          "Stripe account not found for this vendor",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.info, color: Colors.orange, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
        );
        return;
      }

      // Confirm payment
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text('Transfer \$${NumberFormat('#,##0').format(amount)} to this vendor?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        // Process payment
        final result = await createStripeTransfer(
          amount: amount * 100,
          destinationAccountId: stripeAccountId,
          serverUrl: 'http://192.168.0.103:3000/create-transfer',
        );

        // Get current timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // Create payment history record
        final paymentHistoryRef = _paymentsRef.child(vendorId).child('paymentHistory').push();
        await paymentHistoryRef.set({
          "amount": amount,
          "timestamp": timestamp,
          "status": "completed",
        });

        // Update payment status in database
        await _paymentsRef.child(vendorId).update({
          "paid": true,
          "earned": 0, // Reset earned amount after payment
          "lastUpdated": timestamp,
          "lastPaymentAmount": amount, // Save the payment amount
          "lastPaymentDate": timestamp, // Save the payment date
        });

        // Close loading dialog
        Get.back();

        Get.snackbar(
          "Success",
          "Payment transferred successfully!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
        );

        // Refresh data
        _fetchPaymentData();
      } catch (e) {
        // Close loading dialog if there's an error
        Get.back();
        Get.snackbar(
          "Payment Failed",
          "Error: ${e.toString()}",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.error, color: Colors.red, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
        );
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vendor Payments',
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
          ))
          : _vendorPayments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Payment Data Available',
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
                                label: Text('Vendor Name',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Business',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Weekly Earning',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                              label: Padding(
                                padding: EdgeInsets.only(left: 12), // Adjust the value as needed
                                child: Text(
                                  'Action',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            DataColumn(
                                label: Text('Payment History',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: _displayedVendors.map((vendor) {
                            final amount = vendor['weeklyEarning'];
                            final isPaid = vendor['paid'] ?? false;
                            final stripeAccountId = vendor['stripeAccountId'] ?? '';
                            return DataRow(
                              cells: [
                                DataCell(Text(vendor['srNo'].toString(),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins'))),
                                DataCell(Text(vendor['vendorName'],
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins'))),
                                DataCell(Text(vendor['businessName'],
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins'))),
                                DataCell(
                                  Text(
                                    '\$${NumberFormat('#,##0').format(amount)}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins'),
                                  ),
                                ),
                                DataCell(
                                  amount == 0
                                      ? TextButton(
                                    onPressed: null,
                                    child: const Text(
                                      'No amount to transfer',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                      : TextButton(
                                    onPressed: () {
                                      _processPayment(vendor['vendorId'], amount, stripeAccountId);
                                    },
                                    child: Text(
                                      'Pay \$${NumberFormat('#,##0').format(amount)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VendorPaymentHistoryScreen(
                                            vendorId: vendor['vendorId'],
                                            vendorName: vendor['vendorName'],
                                            businessName: vendor['businessName'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,

                                      ),
                                    ),
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
                  color: _currentPage > 1
                      ? const Color(0xFFFF4A49)
                      : Colors.grey,
                ),
                Text(
                  'Page $_currentPage of ${(_vendorPayments.length / _vendorsPerPage).ceil()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _nextPage,
                  color: _currentPage * _vendorsPerPage <
                      _vendorPayments.length
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
}