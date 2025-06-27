import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../innerscreens/adminorderdetailscreen.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('orders');
  final List<Map<String, dynamic>> _orderList = [];
  final List<Map<String, dynamic>> _displayedOrders = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _ordersPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is int) {
      return DateFormat('dd MMM yyyy').format(
          DateTime.fromMillisecondsSinceEpoch(timestamp));
    }
    if (timestamp is String) {
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(timestamp));
      } catch (e) {
        return timestamp;
      }
    }
    return "N/A";
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'pending':
        return Colors.purple; // Changed from grey to purple
      default:
        return Colors.grey;
    }
  }

  String _determineOrderStatus(List<dynamic> items) {
    if (items.isEmpty) return "Pending";

    int deliveredCount = 0;
    int processingCount = 0;

    for (var item in items) {
      if (item is Map) {
        String? vendorStatus = item['vendorStatus']?.toString().toLowerCase();
        if (vendorStatus == 'delivered') {
          deliveredCount++;
        } else if (vendorStatus == 'processing') {
          processingCount++;
        }
      }
    }

    if (deliveredCount == items.length) {
      return "Delivered";
    } else if (processingCount == items.length) {
      return "Processing";
    } else {
      return "Pending";
    }
  }

  String _determinePaymentStatus(Map<String, dynamic> order) {
    if (order['paymentMethod']?.toString().toLowerCase() == 'stripe') {
      return 'Paid';
    }

    if (order['paymentMethod']?.toString().toLowerCase() == 'cod') {
      final items = order['items'] ?? [];
      if (items is List) {
        bool allDelivered = true;
        for (var item in items) {
          if (item is Map && item['vendorStatus']?.toString().toLowerCase() != 'delivered') {
            allDelivered = false;
            break;
          }
        }
        if (allDelivered) {
          return 'Paid';
        }
      }
      return 'Unpaid';
    }

    return order['paymentStatus'] ?? 'N/A';
  }

  void _fetchOrders() {
    setState(() => _isLoading = true);
    _database.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      _orderList.clear();
      if (data != null) {
        data.forEach((key, value) {
          dynamic items = value["items"] ?? [];
          if (items is Map) {
            items = items.values.toList();
          }

          final orderData = {
            "orderId": key,
            "orderNumber": value["orderNumber"] ?? "N/A",
            "customerName": value["name"] ?? "No Name",
            "createdAt": _formatDate(value["createdAt"]),
            "status": _determineOrderStatus(items),
            "paymentMethod": value["paymentMethod"] ?? "N/A",
            "items": items,
            "totalAmount": (value["totalAmount"] ?? 0).toString(),
            "email": value["email"] ?? "No Email",
            "phone": value["phone"]?.toString() ?? "N/A",
            "itemsCount": items.length.toString(), // Add items count
          };

          orderData["paymentStatus"] = _determinePaymentStatus(orderData);
          _orderList.add(orderData);
        });
      }

      _orderList.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      _updateDisplayedOrders();
      setState(() => _isLoading = false);
    }).onError((error) {
      setState(() => _isLoading = false);
      Get.snackbar(
        "Error",
        "Failed to load orders: ${error.toString()}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
    });
  }

  void _updateDisplayedOrders() {
    final startIndex = (_currentPage - 1) * _ordersPerPage;
    final endIndex = startIndex + _ordersPerPage;

    setState(() {
      _displayedOrders.clear();
      if (startIndex < _orderList.length) {
        _displayedOrders.addAll(
          _orderList.sublist(
            startIndex,
            endIndex < _orderList.length ? endIndex : _orderList.length,
          ),
        );
      }
    });
  }

  void _nextPage() {
    if (_currentPage * _ordersPerPage < _orderList.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedOrders();
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateDisplayedOrders();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders',
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
          : _orderList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Orders Found',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Poppins',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.grey.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
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
                                label: Text('Order #',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Customer',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Items',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Date and Time',
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
                                label: Text('Payment',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Total',
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
                          rows: _displayedOrders.map((order) {
                            return DataRow(
                              cells: [
                                DataCell(Text(order['orderNumber'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(order['customerName'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(order['itemsCount'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(Text(order['createdAt'],
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(
                                  Text(order['status'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: _getStatusColor(order['status']),
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                                DataCell(
                                  Text(order['paymentStatus'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: _getStatusColor(order['paymentStatus']),
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                                DataCell(Text('\$${order['totalAmount']}',
                                    style: const TextStyle(
                                        fontSize: 15, fontFamily: 'Poppins'))),
                                DataCell(
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) {
                                            return adminOrderDetailScreen(
                                              orderId: order['orderId'],
                                            );
                                          },
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(opacity: animation, child: child);
                                          },
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: Colors.blue,
                                        decoration: TextDecoration.none, // ❌ No underline
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
                      'Page $_currentPage of ${(_orderList.length / _ordersPerPage).ceil()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: _nextPage,
                      color: _currentPage * _ordersPerPage < _orderList.length
                          ? const Color(0xFFFF4A49)
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}