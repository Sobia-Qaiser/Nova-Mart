
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:get/get.dart';import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/main_vendor_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/innerscreens/vendororderdetailscreen.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<dynamic, dynamic> orders = {};
  bool isLoading = true;

  int newCount = 0;
  int processingCount = 0;
  int deliveredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    FirebaseDatabase.instance.ref('orders').onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        int tempNew = 0;
        int tempProcessing = 0;
        int tempDelivered = 0;

        data.forEach((orderId, order) {
          if (order['items'] != null) {
            final items = Map<dynamic, dynamic>.from(order['items']);
            bool hasVendorProduct = false;
            String orderStatus = 'pending'; // Default status

            items.forEach((productId, item) {
              if (item['vendorId'] == user?.uid) {
                hasVendorProduct = true;
                final itemStatus = (item['vendorStatus']?.toString() ?? 'pending').toLowerCase();

                // If any item is delivered, the whole order is delivered
                if (itemStatus == 'delivered') {
                  orderStatus = 'delivered';
                }
                // If any item is processing and none are delivered, the order is processing
                else if (itemStatus == 'processing' && orderStatus != 'delivered') {
                  orderStatus = 'processing';
                }
              }
            });

            if (hasVendorProduct) {
              // Count the order based on its overall status
              if (orderStatus == 'pending') {
                tempNew++;
              } else if (orderStatus == 'processing') {
                tempProcessing++;
              } else if (orderStatus == 'delivered') {
                tempDelivered++;
              }
            }
          }
        });

        setState(() {
          orders = data;
          newCount = tempNew;
          processingCount = tempProcessing;
          deliveredCount = tempDelivered;
          isLoading = false;
        });
      } else {
        setState(() {
          orders = {};
          newCount = 0;
          processingCount = 0;
          deliveredCount = 0;
          isLoading = false;
        });
      }
    });
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
            onPressed: () => Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const MainVendorScreen(initialIndex: 0);
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300), // optional
              ),
            ),



          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: _buildTabBar(newCount, processingCount, deliveredCount, isDarkMode),
          ),
        ),
        body: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: isDarkMode ? Colors.white : const Color(0xFFFF4A49),
          ),
        )
            : TabBarView(
          children: [
            _buildOrderList('pending', isDarkMode),
            _buildOrderList('processing', isDarkMode),
            _buildOrderList('delivered', isDarkMode),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildTabBar(int newCount, int processingCount, int deliveredCount, bool isDarkMode) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        color: const Color(0xFFFF4A49),
        child: TabBar(
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            Tab(text: 'New ($newCount)'),
            Tab(text: 'Processing ($processingCount)'),
            Tab(text: 'Delivered ($deliveredCount)'),
          ],
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 3.0,
              color: const Color(0xFFFFD180),
            ),
            insets: const EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 8.0),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            fontSize: 14,
            shadows: [
              Shadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(1, 1)),
            ],
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          labelColor: const Color(0xFFFFE0B2),
          unselectedLabelColor: const Color(0xFFFFAB91),
          splashBorderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildOrderList(String statusFilter, bool isDarkMode) {
    final user = FirebaseAuth.instance.currentUser;

    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No orders found!',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    final ordersList = orders.entries.toList().reversed.toList();

    // Filter vendor-specific orders
    final filteredOrders = [];
    for (final entry in ordersList) {
      final order = entry.value;

      // Check if order has products from this vendor
      bool hasVendorProduct = false;
      int vendorItemCount = 0;
      double vendorTotalAmount = 0.0;
      List<Map<String, dynamic>> vendorItems = [];
      String vendorOrderStatus = 'pending';

      if (order['items'] != null) {
        final items = Map<dynamic, dynamic>.from(order['items']);
        items.forEach((productId, item) {
          if (item['vendorId'] == user?.uid) {
            hasVendorProduct = true;
            vendorItemCount++;

            // Use discounted price if available, otherwise use regular price
            double price = _parseDouble(item['discountedPrice'] ?? item['price']);
            int quantity = _parseDouble(item['quantity']).toInt();
            double itemTotal = price * quantity;

            vendorTotalAmount += itemTotal;

            vendorItems.add({
              'productId': productId,
              'name': item['productName'],
              'price': price,
              'quantity': quantity,
              'image': item['imageUrl'],
              'total': itemTotal,
              'vendorStatus': item['vendorStatus'] ?? 'pending',
            });

            // Determine the overall status for this vendor's products
            final itemStatus = (item['vendorStatus']?.toString() ?? 'pending').toLowerCase();
            if (itemStatus == 'delivered') {
              vendorOrderStatus = 'delivered';
            } else if (itemStatus == 'processing' && vendorOrderStatus != 'delivered') {
              vendorOrderStatus = 'processing';
            }
          }
        });
      }

      if (!hasVendorProduct) continue;

      // Check status filter
      if (statusFilter == vendorOrderStatus) {
        filteredOrders.add({
          'entry': entry,
          'itemCount': vendorItemCount,
          'totalAmount': vendorTotalAmount,
          'items': vendorItems,
          'vendorStatus': vendorOrderStatus,
        });
      }
    }

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          'No ${_capitalize(statusFilter)} orders found!',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final data = filteredOrders[index];
        final entry = data['entry'];
        final orderId = entry.key.toString();
        final order = entry.value;
        final vendorItemCount = data['itemCount'];
        final vendorTotalAmount = data['totalAmount'];
        final vendorItems = data['items'] as List<Map<String, dynamic>>;
        final vendorStatus = data['vendorStatus'];

        return _VendorOrderItem(
          orderId: orderId,
          orderNumber: order['orderNumber']?.toString() ?? 'N/A',
          status: _capitalize(vendorStatus),
          createdAt: order['createdAt'],
          totalAmount: vendorTotalAmount,
          itemCount: vendorItemCount,
          isDarkMode: isDarkMode,
          paymentMethod: order['paymentMethod']?.toString() ?? 'cod',
          paymentStatus: _capitalize(order['paymentStatus']?.toString() ??
              (order['paymentMethod'] == 'cod' ? 'Unpaid' : 'Paid')),
          items: vendorItems,
          allowStatusChange: statusFilter == 'pending' || statusFilter == 'processing',
          vendorId: user?.uid ?? '',
        );
      },
    );
  }
}

class _VendorOrderItem extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String status;
  final dynamic createdAt;
  final double totalAmount;
  final int itemCount;
  final bool isDarkMode;
  final String paymentMethod;
  final String paymentStatus;
  final List<Map<String, dynamic>> items;
  final bool allowStatusChange;
  final String vendorId;

  const _VendorOrderItem({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    required this.itemCount,
    required this.isDarkMode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.allowStatusChange,
    required this.vendorId,
  });

  @override
  State<_VendorOrderItem> createState() => _VendorOrderItemState();
}

class _VendorOrderItemState extends State<_VendorOrderItem> {
  bool _showStatusDropdown = false;
  String? _selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.status;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF5E35B1);
      case 'processing':
        return const Color(0xFFFFA726);
      case 'delivered':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFFB0BEC5);
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'unpaid':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFB0BEC5);
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  void _navigateToOrderDetail(BuildContext context) {
    if (widget.vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor ID is missing')),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VendorOrderDetailScreen(orderId: widget.orderId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );

  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (widget.vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor ID is missing')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final updates = <String, dynamic>{};

      // Update vendorStatus for each product belonging to this vendor
      for (final item in widget.items) {
        final productId = item['productId'];
        if (productId != null && productId.isNotEmpty) {
          updates['items/$productId/vendorStatus'] = newStatus.toLowerCase();
        }
      }

      // If all items are delivered and payment is COD, mark as paid
      if (newStatus.toLowerCase() == 'delivered' &&
          widget.paymentMethod == 'cod' &&
          widget.paymentStatus.toLowerCase() != 'paid') {
        updates['paymentStatus'] = 'paid';
      }

      if (updates.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref('orders')
            .child(widget.orderId)
            .update(updates)
            .then((_) {

          Get.snackbar(
            "Success",
            "Status updated to $newStatus",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: Colors.black,
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
            shouldIconPulse: false,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
            margin: const EdgeInsets.all(10),
          );



        });
      }

      setState(() {
        _selectedStatus = _capitalize(newStatus);
        _showStatusDropdown = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToOrderDetail(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ${widget.orderNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(widget.paymentStatus.toLowerCase()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.paymentStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  widget.allowStatusChange
                      ? GestureDetector(
                    onTap: _isUpdating
                        ? null
                        : () {
                      setState(() {
                        _showStatusDropdown = !_showStatusDropdown;
                      });
                    },
                    child: Row(
                      children: [
                        if (_isUpdating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Text(
                            _selectedStatus ?? widget.status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(
                                  (_selectedStatus ?? widget.status).toLowerCase()),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(
                          _showStatusDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ],
                    ),
                  )
                      : Text(
                    _selectedStatus ?? widget.status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(
                          (_selectedStatus ?? widget.status).toLowerCase()),
                    ),
                  ),
                ],
              ),
              if (_showStatusDropdown && widget.allowStatusChange)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    if (widget.status.toLowerCase() == 'pending')
                      _buildStatusOption('Processing'),
                    if (widget.status.toLowerCase() == 'pending' ||
                        widget.status.toLowerCase() == 'processing')
                      _buildStatusOption('Delivered'),
                    const SizedBox(height: 8),
                  ],
                ),
              const SizedBox(height: 12),
              _buildDetailRow('Items:', '${widget.itemCount}'),
              _buildDetailRow('Order Date:', _formatTimestamp(widget.createdAt)),
              _buildDetailRow('Payment:', widget.paymentMethod == 'cod' ? 'COD' : 'Card'),
              _buildDetailRow('Total Amount:', 'PKR ${widget.totalAmount.toStringAsFixed(0)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(String status) {
    final isSelected = (_selectedStatus ?? '').toLowerCase() == status.toLowerCase();

    return GestureDetector(
      onTap: _isUpdating ? null : () => _updateOrderStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? _getStatusColor(status.toLowerCase()).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(status.toLowerCase()),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                color: _getStatusColor(status.toLowerCase()),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
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
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
