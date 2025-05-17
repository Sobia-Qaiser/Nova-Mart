import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:multi_vendor_ecommerce_app/controllers/auth_controller.dart';
import 'package:intl/intl.dart';

class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key});

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  final AuthController _authController = AuthController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String userName = "Vendor";
  String vendorId = "";
  bool isLoading = true;

  int totalOrders = 0;
  int totalProducts = 0;
  double totalRevenue = 0.0;
  double totalRevenueAfterCommission = 0.0;
  double thisMonthEarning = 0.0;
  double thisMonthEarningAfterCommission = 0.0;
  DateTime? vendorJoinDate;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      vendorId = user.uid;
      final name = await _authController.getCurrentVendorName();

      await _fetchVendorJoinDate();
      await Future.wait([
        _fetchTotalOrders(),
        _fetchTotalProducts(),
        _fetchTotalRevenue(),
        _fetchThisMonthEarning(),
      ]);

      if (mounted) {
        setState(() {
          userName = name ?? "Vendor";
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint("Error loading vendor data: $e");
    }
  }

  Future<void> _fetchVendorJoinDate() async {
    final snapshot = await _dbRef.child('users').child(vendorId).child(
        'createdAt').once();
    if (snapshot.snapshot.value != null) {
      try {
        if (snapshot.snapshot.value is int) {
          setState(() {
            vendorJoinDate = DateTime.fromMillisecondsSinceEpoch(
                snapshot.snapshot.value as int);
          });
        } else if (snapshot.snapshot.value is String) {
          final dateString = snapshot.snapshot.value as String;
          try {
            setState(() {
              vendorJoinDate =
                  DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateString);
            });
          } catch (e) {
            try {
              setState(() {
                vendorJoinDate = DateTime.parse(dateString);
              });
            } catch (e) {
              debugPrint("Failed to parse join date: $e");
            }
          }
        }
      } catch (e) {
        debugPrint("Error parsing join date: $e");
      }
    }
  }

  Future<void> _fetchTotalOrders() async {
    final snapshot = await _dbRef.child('orders').once();
    if (snapshot.snapshot.value == null) return;

    final ordersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
    Set<String> uniqueOrderIds = Set();

    ordersMap.forEach((orderId, orderData) {
      if (orderData['items'] != null) {
        final items = orderData['items'] as Map<dynamic, dynamic>;
        bool hasVendorItem = false;

        items.forEach((itemId, itemData) {
          if (itemData['vendorId'] == vendorId &&
              itemData['vendorStatus'] == 'delivered') {
            hasVendorItem = true;
          }
        });

        if (hasVendorItem) {
          uniqueOrderIds.add(orderId);
        }
      }
    });

    if (mounted) {
      setState(() {
        totalOrders = uniqueOrderIds.length;
      });
    }
  }

  Future<void> _fetchTotalProducts() async {
    final snapshot = await _dbRef.child('products')
        .orderByChild('vendorId')
        .equalTo(vendorId)
        .once();
    if (snapshot.snapshot.value == null) return;

    final productsMap = snapshot.snapshot.value as Map<dynamic, dynamic>;

    if (mounted) {
      setState(() {
        totalProducts = productsMap.length;
      });
    }
  }

  Future<void> _fetchTotalRevenue() async {
    final snapshot = await _dbRef.child('orders').once();
    if (snapshot.snapshot.value == null) return;

    final ordersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
    double revenue = 0.0;
    double revenueAfterCommission = 0.0;

    ordersMap.forEach((orderId, orderData) {
      if (orderData['items'] != null && _isOrderValid(orderData)) {
        final items = orderData['items'] as Map<dynamic, dynamic>;
        double vendorOrderTotal = 0.0;

        // Calculate total for this vendor in this order
        items.forEach((itemId, itemData) {
          if (itemData['vendorId'] == vendorId &&
              itemData['vendorStatus'] == 'delivered') {
            vendorOrderTotal +=
                (itemData['price'] ?? 0.0) * (itemData['quantity'] ?? 1);
          }
        });

        // Add to totals (with commission calculated per order)
        revenue += vendorOrderTotal;
        revenueAfterCommission +=
            vendorOrderTotal * 0.95; // Deduct 5% per order
      }
    });

    if (mounted) {
      setState(() {
        totalRevenue = revenue;
        totalRevenueAfterCommission = revenueAfterCommission;
      });
    }
  }

  Future<void> _fetchThisMonthEarning() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _dbRef.child('orders').once();
    if (snapshot.snapshot.value == null) return;

    final ordersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
    double earnings = 0.0;
    double earningsAfterCommission = 0.0;

    ordersMap.forEach((orderId, orderData) {
      if (orderData['items'] == null) return;

      DateTime? orderDate;

      if (orderData['createdAt'] != null) {
        try {
          orderDate =
              DateFormat('d MMMM yyyy, h:mm a').parse(orderData['createdAt']);
        } catch (e) {
          debugPrint("Error parsing createdAt: $e");
        }
      }

      if (orderDate == null && orderData['orderDate'] != null) {
        try {
          orderDate = DateFormat('yyyy-MM-dd').parse(orderData['orderDate']);
        } catch (e) {
          debugPrint("Error parsing orderDate: $e");
        }
      }

      if (orderDate == null && orderData['timestamp'] != null) {
        orderDate =
            DateTime.fromMillisecondsSinceEpoch(orderData['timestamp'] as int);
      }

      if (orderDate == null || orderDate.isBefore(firstDayOfMonth)) return;

      double vendorOrderTotal = 0.0;
      final items = orderData['items'] as Map<dynamic, dynamic>;
      items.forEach((itemId, itemData) {
        if (itemData['vendorId'] == vendorId &&
            itemData['vendorStatus'] == 'delivered') {
          vendorOrderTotal +=
              (itemData['price'] ?? 0.0) * (itemData['quantity'] ?? 1);
        }
      });

      // Add to totals (with commission calculated per order)
      earnings += vendorOrderTotal;
      earningsAfterCommission += vendorOrderTotal * 0.95; // Deduct 5% per order
    });

    if (mounted) {
      setState(() {
        thisMonthEarning = earnings;
        thisMonthEarningAfterCommission = earningsAfterCommission;
      });
    }
  }

  bool _isOrderValid(Map<dynamic, dynamic> orderData) {
    if (vendorJoinDate == null) return true;

    DateTime? orderDate;

    if (orderData['createdAt'] != null) {
      try {
        orderDate =
            DateFormat('d MMMM yyyy, h:mm a').parse(orderData['createdAt']);
      } catch (e) {
        debugPrint("Error parsing createdAt: $e");
      }
    }

    if (orderDate == null && orderData['orderDate'] != null) {
      try {
        orderDate = DateFormat('yyyy-MM-dd').parse(orderData['orderDate']);
      } catch (e) {
        debugPrint("Error parsing orderDate: $e");
      }
    }

    if (orderDate == null && orderData['timestamp'] != null) {
      orderDate =
          DateTime.fromMillisecondsSinceEpoch(orderData['timestamp'] as int);
    }

    return orderDate == null || orderDate.isAfter(vendorJoinDate!) ||
        orderDate.isAtSameMomentAs(vendorJoinDate!);
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required String title,
    required bool isRevenueCard,
    double? grossAmount,
    double? netAmount,
    int? count, // For simple count cards
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (isRevenueCard) ...[
              Text(
                "PKR ${netAmount?.toStringAsFixed(2) ?? '0.00'}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "-5%",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else
              ...[
                Text(
                  count?.toString() ?? '0',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hi, $userName! 👋",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(9),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.shopping_cart,
                    iconColor: Colors.blue,
                    cardColor: Colors.blue[50]!,
                    title: "Total Orders",
                    isRevenueCard: false,
                    count: totalOrders,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.inventory,
                    iconColor: Colors.green,
                    cardColor: Colors.green[50]!,
                    title: "Total Products",
                    isRevenueCard: false,
                    count: totalProducts,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money,
                    iconColor: Colors.purple,
                    cardColor: Colors.purple[50]!,
                    title: "Total Revenue",
                    isRevenueCard: true,
                    grossAmount: totalRevenue,
                    netAmount: totalRevenueAfterCommission,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    iconColor: Colors.orange,
                    cardColor: Colors.orange[50]!,
                    title: "This Month",
                    isRevenueCard: true,
                    grossAmount: thisMonthEarning,
                    netAmount: thisMonthEarningAfterCommission,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}