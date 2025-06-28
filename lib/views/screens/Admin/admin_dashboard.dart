import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:multi_vendor_ecommerce_app/draweradminside.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool isLoading = true;
  String selectedPeriod = "Weekly";

  int totalOrders = 0;
  int totalProducts = 0;
  int totalCustomers = 0;
  int totalVendors = 0;
  int totalCategories = 0;
  double totalRevenue = 0.0;

  // Data for the chart
  List<FlSpot> weeklySpots = [];
  List<FlSpot> monthlySpots = [];
  List<String> weeklyLabels = [];
  List<String> monthlyLabels = [];



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
    });
  }

  Future<void> _loadAdminData() async {
    try {
      await Future.wait([
        _fetchTotalOrders(),
        _fetchTotalProducts(),
        _fetchTotalCustomers(),
        _fetchTotalVendors(),
        _fetchTotalCategories(),
        _fetchTotalRevenue(),
        _fetchChartData(),
      ]);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint("Error loading admin data: $e");
    }
  }

  Future<void> _fetchTotalOrders() async {
    final snapshot = await _dbRef.child('orders').once();
    if (snapshot.snapshot.value == null) return;

    final ordersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;

    if (mounted) {
      setState(() {
        totalOrders = ordersMap.length;
      });
    }
  }

  Future<void> _fetchTotalProducts() async {
    final snapshot = await _dbRef.child('products').once();
    if (snapshot.snapshot.value == null) return;

    final productsMap = snapshot.snapshot.value as Map<dynamic, dynamic>;

    if (mounted) {
      setState(() {
        totalProducts = productsMap.length;
      });
    }
  }

  Future<void> _fetchTotalCustomers() async {
    final snapshot = await _dbRef.child('users').once();
    if (snapshot.snapshot.value == null) return;

    final usersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
    int customerCount = 0;

    usersMap.forEach((key, value) {
      if (value['role'] == 'Customer') {
        customerCount++;
      }
    });

    if (mounted) {
      setState(() {
        totalCustomers = customerCount;
      });
    }
  }

  Future<void> _fetchTotalVendors() async {
    final snapshot = await _dbRef.child('users').once();
    if (snapshot.snapshot.value == null) return;

    final usersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
    int vendorCount = 0;

    usersMap.forEach((key, value) {
      if (value['role'] == 'Vendor' && value['status'] == 'approved') {
        vendorCount++;
      }
    });

    if (mounted) {
      setState(() {
        totalVendors = vendorCount;
      });
    }
  }

  Future<void> _fetchTotalCategories() async {
    final snapshot = await _dbRef.child('categories').once();
    if (snapshot.snapshot.value == null) return;

    final categoriesMap = snapshot.snapshot.value as Map<dynamic, dynamic>;

    if (mounted) {
      setState(() {
        totalCategories = categoriesMap.length;
      });
    }
  }

  Future<void> _fetchTotalRevenue() async {
    final snapshot = await _dbRef.child('orders').once();
    if (snapshot.snapshot.value == null) return;

    final ordersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
    double revenue = 0;

    ordersMap.forEach((orderId, orderData) {
      if (orderData['items'] != null) {
        final items = orderData['items'] as Map<dynamic, dynamic>;
        double orderTotal = 0.0;

        items.forEach((itemId, itemData) {
          if (itemData['vendorStatus'] == 'delivered') {
            orderTotal += (itemData['price'] ?? 0.0) * (itemData['quantity'] ?? 1);
          }
        });

        revenue += orderTotal * 0.05; // 5% commission
      }
    });

    if (mounted) {
      setState(() {
        totalRevenue = revenue.floorToDouble(); // remove decimal points
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required String title,
    required int count,
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
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(bool isDarkMode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[800] : Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.attach_money, size: 30, color: Colors.purple),
            const SizedBox(height: 12),
            Text(
              "Total Revenue",
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "\$${totalRevenue.toInt()}",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
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

    // ✅ Custom maxY based on period
    double maxYValue;
    if (selectedPeriod == "Monthly") {
      maxYValue = 20;
    } else {
      maxYValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      maxYValue = (maxYValue * 1.2).ceilToDouble();
      if (maxYValue < 14) maxYValue = 14;
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
                        if (value % 5 == 0) {
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
                      interval: 5,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                maxY: maxYValue, // ✅ set dynamic maxY
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      drawer: DrawerContent(),
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
            // First row with 2 cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.shopping_cart,
                    iconColor: Colors.blue,
                    cardColor: Colors.blue[50]!,
                    title: "Total Orders",
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
                    count: totalProducts,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row with 2 cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    iconColor: Colors.orange,
                    cardColor: Colors.orange[50]!,
                    title: "Customers",
                    count: totalCustomers,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.store,
                    iconColor: Colors.red,
                    cardColor: Colors.red[50]!,
                    title: "Vendors",
                    count: totalVendors,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Third row with 2 cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.category,
                    iconColor: Colors.teal,
                    cardColor: Colors.teal[50]!,
                    title: "Categories",
                    count: totalCategories,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRevenueCard(isDarkMode),
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