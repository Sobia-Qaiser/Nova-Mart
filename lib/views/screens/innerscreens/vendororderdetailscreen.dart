import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class VendorOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const VendorOrderDetailScreen({super.key, required this.orderId});

  @override
  State<VendorOrderDetailScreen> createState() => _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  late DatabaseReference _orderRef;
  late User? _currentUser;
  bool isLoading = true;
  double vendorTotal = 0.0;
  List<Map<String, dynamic>> vendorItems = [];
  Map<String, dynamic> orderData = {};
  StreamSubscription<DatabaseEvent>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _orderRef = FirebaseDatabase.instance.ref('orders').child(widget.orderId);
    _setupOrderListener();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _setupOrderListener() {
    _orderSubscription = _orderRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        setState(() {
          orderData = Map<String, dynamic>.from(snapshot.value as Map);
        });

        // Filter items belonging to this vendor
        if (orderData['items'] != null) {
          final items = Map<dynamic, dynamic>.from(orderData['items']);
          vendorItems.clear();
          vendorTotal = 0.0;

          for (var entry in items.entries) {
            var item = entry.value;
            if (item['vendorId'] == _currentUser?.uid) {
              double price = (item['price']?.toDouble() ?? 0.0);
              int quantity = (item['quantity']?.toInt() ?? 1);
              vendorTotal += price * quantity;

              String productName = item['productName'] ?? item['name'] ?? 'Product';
              String? imageUrl = item['imageUrl'] ?? item['image'];
              String vendorStatus = item['vendorStatus']?.toString() ?? 'pending';

              vendorItems.add({
                'productId': entry.key.toString(),
                'name': productName,
                'price': price,
                'quantity': quantity,
                'size': item['size'],
                'color': item['color'],
                'image': imageUrl,
                'vendorStatus': vendorStatus,
              });
            }
          }
        }

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order: ${error.message}')),
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF5E35B1);
      case 'processing':
        return const Color(0xFFFFA726);
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFB0BEC5);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Widget _buildSection(String title, List<Widget> children, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? statusColor, bool isTotal = false, bool isDarkMode = false}) {
    bool isStatusRow = label.toLowerCase().contains('status');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isStatusRow || isTotal ? FontWeight.bold : FontWeight.normal,
              color: statusColor ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVendorOrderItems(bool isDarkMode) {
    return vendorItems.map<Widget>((item) {
      final String name = item['name'] ?? 'Product';
      final int quantity = item['quantity'] ?? 1;
      final double price = (item['price']?.toDouble() ?? 0.0);
      final String? size = item['size'];
      final String? color = item['color'];
      final String? imageUrl = item['image'];

      // Combine size and color if available
      String? variation;
      if (size != null && size.isNotEmpty && color != null && color.isNotEmpty) {
        variation = 'Size: $size, Color: $color';
      } else if (size != null && size.isNotEmpty) {
        variation = 'Size: $size';
      } else if (color != null && color.isNotEmpty) {
        variation = 'Color: $color';
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image if available
            if (imageUrl != null && imageUrl.isNotEmpty)
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  if (variation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        variation,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Qty: $quantity',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '\$${price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final status = orderData['status']?.toString()?.toLowerCase() ?? 'pending';
    final isDelivered = status == 'delivered';
    final capitalizedStatus = _capitalize(orderData['status']?.toString() ?? 'Pending');

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Order Details',
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (orderData.isNotEmpty) ...[
              _buildSection('Order Summary', [
                _buildDetailRow('Order Number', orderData['orderNumber']?.toString() ?? 'N/A', isDarkMode: isDarkMode),
                _buildDetailRow('Order Date', orderData['createdAt']?.toString() ?? '', isDarkMode: isDarkMode),
                _buildDetailRow(
                  'Status',
                  vendorItems.isNotEmpty
                      ? _capitalize(vendorItems.first['vendorStatus']?.toString() ?? 'processing')
                      : 'N/A',
                  statusColor: vendorItems.isNotEmpty
                      ? _getStatusColor(vendorItems.first['vendorStatus']?.toString() ?? 'processing')
                      : Colors.grey,
                  isDarkMode: isDarkMode,
                ),
                _buildDetailRow(
                  'Payment Status',
                  isDelivered ? 'Paid' : _capitalize(orderData['paymentStatus']?.toString() ??
                      (orderData['paymentMethod'] == 'cod' ? 'Unpaid' : 'Paid')),
                  statusColor: isDelivered ? Colors.green :
                  ((orderData['paymentStatus']?.toString() ??
                      (orderData['paymentMethod'] == 'cod' ? 'Unpaid' : 'Paid')).toLowerCase() == 'paid'
                      ? Colors.green
                      : Colors.red),
                  isDarkMode: isDarkMode,
                ),
              ], isDarkMode),

              _buildSection('Customer Information', [
                _buildDetailRow('Name', orderData['name']?.toString() ?? '', isDarkMode: isDarkMode),
                _buildDetailRow('Address', orderData['address']?.toString() ?? '', isDarkMode: isDarkMode),
                _buildDetailRow('City', orderData['city']?.toString() ?? '', isDarkMode: isDarkMode),
                _buildDetailRow('Payment Method',
                    orderData['paymentMethod'] == 'cod' ? 'Cash on Delivery' : 'Credit Card',
                    isDarkMode: isDarkMode),
              ], isDarkMode),

              _buildSection('Your Products', [
                ..._buildVendorOrderItems(isDarkMode),
              ], isDarkMode),

              _buildSection('Payment Summary', [
                _buildDetailRow('Subtotal', '\$${vendorTotal.toStringAsFixed(0)}',
                    isDarkMode: isDarkMode),
                const Divider(),
                _buildDetailRow('Total Amount', '\$${vendorTotal.toStringAsFixed(0)}',
                    isTotal: true, isDarkMode: isDarkMode),
              ], isDarkMode),
            ] else
              Center(
                child: Text(
                  'Order not found',
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}