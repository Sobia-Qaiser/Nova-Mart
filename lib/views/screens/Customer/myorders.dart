import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/innerscreens/OrderDetail.dart';

class MyOrders extends StatelessWidget {
  String capitalize(String s) {
    return s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : s;
  }

  const MyOrders({super.key});

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _determineOrderStatus(Map<dynamic, dynamic>? itemsData) {
    if (itemsData == null) return 'Pending';

    bool allProcessing = true;
    bool allDelivered = true;
    bool hasItems = false;

    itemsData.forEach((key, value) {
      hasItems = true;
      final status = value['vendorStatus']?.toString().toLowerCase() ?? 'pending';

      if (status != 'processing' && status != 'delivered') {
        allProcessing = false;
      }
      if (status != 'delivered') {
        allDelivered = false;
      }
    });

    if (!hasItems) return 'Pending';
    if (allDelivered) return 'Delivered';
    if (allProcessing) return 'Processing';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final ordersRef = FirebaseDatabase.instance
        .ref('orders')
        .orderByChild('userId')
        .equalTo(user?.uid);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Orders',
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
      body: StreamBuilder(
        stream: ordersRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text(
                'No orders found!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          final orders = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map);
          final ordersList = orders.entries.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordersList.length,
            itemBuilder: (context, index) {
              final entry = ordersList[index];
              final orderId = entry.key.toString();
              final order = entry.value;

              // Get the order items to determine status
              final orderItems = order['items'] as Map<dynamic, dynamic>?;
              final status = _determineOrderStatus(orderItems);

              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            OrderDetailScreen(orderId: orderId),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: _OrderItem(
                    orderId: orderId,
                    orderNumber: order['orderNumber']?.toString() ?? 'N/A',
                    status: capitalize(status), // Use the determined status
                    createdAt: order['createdAt'],
                    totalAmount: _parseDouble(order['totalAmount']),
                    deliveryTime: order['deliveryTime']?.toString() ?? '5-6 business days',
                    isDarkMode: isDarkMode,
                  )
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final String status;
  final dynamic createdAt;
  final double totalAmount;
  final String deliveryTime;
  final bool isDarkMode;

  const _OrderItem({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    required this.deliveryTime,
    required this.isDarkMode,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Color(0xFF5E35B1);
      case 'processing':
        return Color(0xFFFFA726);
      case 'delivered':
        return Color(0xFF2E7D32);
      case 'cancelled':
        return Color(0xFFE53935);
      default:
        return Color(0xFFB0BEC5);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is int) {
        return DateFormat('dd MMMM y, h:mm a')
            .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
      } else if (timestamp is String) {
        if (timestamp.contains(',')) return timestamp;
        return DateFormat('dd MMMM y, h:mm a')
            .format(DateTime.parse(timestamp));
      }
      return DateFormat('dd MMMM y, h:mm a').format(DateTime.now());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Number $orderNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Order Date:', _formatTimestamp(createdAt)),
            _buildDetailRow('Total Amount:', 'PKR ${totalAmount.toStringAsFixed(0)}'),
            if (status.toLowerCase() != 'delivered') // Only show delivery estimate if status is not delivered
              _buildDetailRow('Estimated Delivery:', deliveryTime),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}