import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late DatabaseReference _orderRef;
  late User? _currentUser;
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _orderRef = FirebaseDatabase.instance.ref('orders').child(widget.orderId);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Color(0xFF5E35B1); // Deep Purple
      case 'processing':
        return Color(0xFFFFA726); // Warm Amber
    // Teal Blue
      case 'delivered':
        return Color(0xFF2E7D32); // Deep Green
      case 'cancelled':
        return Color(0xFFE53935); // Soft Red
      default:
        return Color(0xFFB0BEC5); // Neutral Gray
    }
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
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: statusColor ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItems(dynamic itemsData, bool isDarkMode) {
    if (itemsData == null) return [const SizedBox()];
    Map<dynamic, dynamic> items = itemsData as Map;

    return items.entries.map<Widget>((entry) {
      var item = entry.value;
      final String name = item['name'] ?? 'Product';
      final int quantity = item['quantity'] ?? 1;
      final double price = (item['price']?.toDouble() ?? 0.0);
      final String? size = item['size'];
      final String? color = item['color'];

      // Combine size and color if at least one is available
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
                  if (variation != null) // Show only if size or color is present
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
              'PKR ${price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
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
          : StreamBuilder(
        stream: _orderRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text(
                'Order not found',
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            );
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final orderData = Map<String, dynamic>.from(data);

          final orderNumber = orderData['orderNumber'] ?? '';
          final status = orderData['status'] ?? 'Pending';
          final createdAt = orderData['createdAt'] ?? '';
          final deliveryTime = orderData['deliveryTime'] ?? '';
          final total = (orderData['totalAmount'] ?? 0.0).toDouble();
          final shipping = (orderData['shippingCharges'] ?? 0.0).toDouble();
          final tax = (orderData['taxAmount'] ?? 0.0).toDouble();
          final paymentMethod = orderData['paymentMethod'] == 'cod'
              ? 'Cash on Delivery'
              : 'Credit Card';
          final name = orderData['name'] ?? '';
          final email = orderData['email'] ?? '';
          final address = orderData['address'] ?? '';
          final city = orderData['city'] ?? '';
          final country = orderData['country'] ?? '';
          final zipCode = orderData['zipCode'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildSection('Order Summary', [
                  _buildDetailRow('Order Number', orderNumber, isDarkMode: isDarkMode),
                  _buildDetailRow('Order Date', createdAt, isDarkMode: isDarkMode),
                  _buildDetailRow(
                    'Status',
                    status,
                    statusColor: _getStatusColor(status),
                    isTotal: true,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDetailRow('Delivery Estimate', deliveryTime, isDarkMode: isDarkMode),
                ], isDarkMode),

                _buildSection('Shipping Address', [
                  _buildDetailRow('Name', name, isDarkMode: isDarkMode),
                  _buildDetailRow('Email', email, isDarkMode: isDarkMode),
                  _buildDetailRow('Address', address, isDarkMode: isDarkMode),
                  _buildDetailRow('City', city, isDarkMode: isDarkMode),
                  _buildDetailRow('Country', country, isDarkMode: isDarkMode),
                  _buildDetailRow('ZIP Code', zipCode, isDarkMode: isDarkMode),
                ], isDarkMode),

                _buildSection('Payment Method', [
                  _buildDetailRow('Method', paymentMethod, isDarkMode: isDarkMode),
                ], isDarkMode),

                _buildSection('Order Items', [
                  ..._buildOrderItems(orderData['items'], isDarkMode),
                ], isDarkMode),

                _buildSection('Total Breakdown', [
                  _buildDetailRow('Subtotal', 'PKR ${(total - shipping - tax).toStringAsFixed(0)}',
                      isDarkMode: isDarkMode),
                  _buildDetailRow('Shipping', 'PKR ${shipping.toStringAsFixed(0)}',
                      isDarkMode: isDarkMode),
                  _buildDetailRow('Tax', 'PKR ${tax.toStringAsFixed(0)}',
                      isDarkMode: isDarkMode),
                  const Divider(),
                  _buildDetailRow('Total Amount', 'PKR ${total.toStringAsFixed(0)}',
                      isTotal: true, isDarkMode: isDarkMode),
                ], isDarkMode),
              ],
            ),
          );
        },
      ),
    );
  }
}