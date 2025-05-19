import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:multi_vendor_ecommerce_app/controllers/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'Vendorschatlistscreen.dart';

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
  String selectedPeriod = "Weekly";
  int _unreadChatCount = 0;

  int totalOrders = 0;
  int totalProducts = 0;
  double totalRevenue = 0.0;
  double totalRevenueAfterCommission = 0.0;
  double thisMonthEarning = 0.0;
  double thisMonthEarningAfterCommission = 0.0;
  DateTime? vendorJoinDate;

  // Data for the chart
  List<FlSpot> weeklySpots = [];
  List<FlSpot> monthlySpots = [];
  List<String> weeklyLabels = [];
  List<String> monthlyLabels = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVendorData();
    });
    _fetchUnreadCount();
    FirebaseDatabase.instance.ref('chats').onChildChanged.listen((_) {
      _fetchUnreadCount();
    });
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
        _fetchChartData(),
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
    final snapshot = await _dbRef.child('users').child(vendorId).child('createdAt').once();
    if (snapshot.snapshot.value != null) {
      try {
        if (snapshot.snapshot.value is int) {
          setState(() {
            vendorJoinDate = DateTime.fromMillisecondsSinceEpoch(snapshot.snapshot.value as int);
          });
        } else if (snapshot.snapshot.value is String) {
          final dateString = snapshot.snapshot.value as String;
          try {
            setState(() {
              vendorJoinDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateString);
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

  Future<void> _fetchUnreadCount() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('chats').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
      int totalUnread = 0;

      if (data != null) {
        for (var chat in data.values) {
          final messages = chat as Map<dynamic, dynamic>;
          for (var message in messages.values) {
            final msg = message as Map<dynamic, dynamic>;
            if (msg['receiverId'] == vendorId && (msg['isSeen'] ?? false) == false) {
              totalUnread++;
            }
          }
        }
      }

      setState(() {
        _unreadChatCount = totalUnread;
      });
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
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
          if (itemData['vendorId'] == vendorId && itemData['vendorStatus'] == 'delivered') {
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

        items.forEach((itemId, itemData) {
          if (itemData['vendorId'] == vendorId && itemData['vendorStatus'] == 'delivered') {
            vendorOrderTotal += (itemData['price'] ?? 0.0) * (itemData['quantity'] ?? 1);
          }
        });

        revenue += vendorOrderTotal;
        revenueAfterCommission += vendorOrderTotal * 0.95;
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
          orderDate = DateFormat('d MMMM yyyy, h:mm a').parse(orderData['createdAt']);
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
        orderDate = DateTime.fromMillisecondsSinceEpoch(orderData['timestamp'] as int);
      }

      if (orderDate == null || orderDate.isBefore(firstDayOfMonth)) return;

      double vendorOrderTotal = 0.0;
      final items = orderData['items'] as Map<dynamic, dynamic>;
      items.forEach((itemId, itemData) {
        if (itemData['vendorId'] == vendorId && itemData['vendorStatus'] == 'delivered') {
          vendorOrderTotal += (itemData['price'] ?? 0.0) * (itemData['quantity'] ?? 1);
        }
      });

      earnings += vendorOrderTotal;
      earningsAfterCommission += vendorOrderTotal * 0.95;
    });

    if (mounted) {
      setState(() {
        thisMonthEarning = earnings;
        thisMonthEarningAfterCommission = earningsAfterCommission;
      });
    }
  }

  Future<void> _fetchChartData() async {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    final snapshot = await _dbRef.child('orders').once();
    if (snapshot.snapshot.value == null) return;

    final ordersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;

    Map<DateTime, int> weeklyData = {};
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: 6 - i));
      weeklyData[DateTime(date.year, date.month, date.day)] = 0;
    }

    Map<DateTime, int> monthlyData = {};
    for (int i = 0; i < 30; i++) {
      DateTime date = now.subtract(Duration(days: 29 - i));
      monthlyData[DateTime(date.year, date.month, date.day)] = 0;
    }

    ordersMap.forEach((orderId, orderData) {
      if (orderData['items'] == null) return;

      DateTime? orderDate;

      if (orderData['createdAt'] != null) {
        try {
          orderDate = DateFormat('d MMMM yyyy, h:mm a').parse(orderData['createdAt']);
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
        orderDate = DateTime.fromMillisecondsSinceEpoch(orderData['timestamp'] as int);
      }

      if (orderDate == null) return;

      bool hasVendorItems = false;
      final items = orderData['items'] as Map<dynamic, dynamic>;
      items.forEach((itemId, itemData) {
        if (itemData['vendorId'] == vendorId && itemData['vendorStatus'] == 'delivered') {
          hasVendorItems = true;
        }
      });

      if (!hasVendorItems) return;

      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
      if (orderDate.isAfter(oneWeekAgo)) {
        if (weeklyData.containsKey(orderDay)) {
          weeklyData[orderDay] = weeklyData[orderDay]! + 1;
        }
      }

      if (orderDate.isAfter(oneMonthAgo)) {
        if (monthlyData.containsKey(orderDay)) {
          monthlyData[orderDay] = monthlyData[orderDay]! + 1;
        }
      }
    });

    weeklySpots = [];
    weeklyLabels = [];
    int dayIndex = 0;
    weeklyData.forEach((date, count) {
      weeklySpots.add(FlSpot(dayIndex.toDouble(), count.toDouble()));
      weeklyLabels.add(DateFormat('EEE').format(date));
      dayIndex++;
    });

    monthlySpots = [];
    monthlyLabels = [];
    int weekIndex = 0;
    List<DateTime> monthlyDates = monthlyData.keys.toList()..sort();
    for (int i = 0; i < monthlyDates.length; i += 7) {
      int endIndex = i + 7 < monthlyDates.length ? i + 7 : monthlyDates.length;
      int weeklyCount = 0;
      for (int j = i; j < endIndex; j++) {
        weeklyCount += monthlyData[monthlyDates[j]]!;
      }
      monthlySpots.add(FlSpot(weekIndex.toDouble(), weeklyCount.toDouble()));
      monthlyLabels.add('Week ${weekIndex + 1}');
      weekIndex++;
    }

    if (mounted) setState(() {});
  }

  bool _isOrderValid(Map<dynamic, dynamic> orderData) {
    if (vendorJoinDate == null) return true;

    DateTime? orderDate;

    if (orderData['createdAt'] != null) {
      try {
        orderDate = DateFormat('d MMMM yyyy, h:mm a').parse(orderData['createdAt']);
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
      orderDate = DateTime.fromMillisecondsSinceEpoch(orderData['timestamp'] as int);
    }

    return orderDate == null || orderDate.isAfter(vendorJoinDate!) || orderDate.isAtSameMomentAs(vendorJoinDate!);
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required String title,
    required bool isRevenueCard,
    double? grossAmount,
    double? netAmount,
    int? count,
    required bool isDarkMode,
  }) {
    return Card(

      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[800] : cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (isRevenueCard) ...[
              Text(
                "PKR ${netAmount?.toStringAsFixed(2) ?? '0.00'}",
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.black,
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
            ] else ...[
              Text(
                count?.toString() ?? '0',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart(bool isDarkMode) {
    final spots = selectedPeriod == "Weekly" ? weeklySpots : monthlySpots;
    final labels = selectedPeriod == "Weekly" ? weeklyLabels : monthlyLabels;

    if (spots.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Text(
            "No sales data available",
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 1),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDarkMode ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: isDarkMode ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 22,
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 50 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 32,
                      interval: 50,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: isDarkMode ? Colors.grey.withOpacity(0.3) : Colors.black26, width: 1),
                    left: BorderSide(color: isDarkMode ? Colors.grey.withOpacity(0.3) : Colors.black26, width: 1),
                    right: BorderSide(color: Colors.transparent),
                    top: BorderSide(color: Colors.transparent),
                  ),
                ),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: 300,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: const Color(0xFFFF4A49),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: const Color(0xFFFF4A49),
                          strokeWidth: 2,
                          strokeColor: isDarkMode ? Colors.grey[900]! : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF4A49).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDarkMode ? Colors.grey[900]! : const Color(0xFFF8F9FA);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: primaryColor,

// Update your app bar like this:
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
          Stack(
            children: [
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          VendorChatListScreen(vendorId: vendorId),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                  // Update the count when returning from chat screen
                  if (result != null) {
                    setState(() {
                      _unreadChatCount = result;
                    });
                  }
                },
                icon: const Icon(
                  Icons.chat,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (_unreadChatCount > 0)
                Positioned(
                  right: 8,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadChatCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF4A49)),
        ),
      )
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
                    isDarkMode: isDarkMode,
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
                    isDarkMode: isDarkMode,
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
                    isDarkMode: isDarkMode,
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
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sales Report",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Period : ",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      DropdownButton<String>(
                        value: selectedPeriod,
                        underline: Container(),
                        icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.black54),
                        items: <String>['Weekly', 'Monthly']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPeriod = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildChart(isDarkMode),
          ],
        ),
      ),
    );
  }
}