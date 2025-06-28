import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:multi_vendor_ecommerce_app/controllers/auth_controller.dart';
import 'main_vendor_screen.dart';

class Earning extends StatefulWidget {
  const Earning({super.key});

  @override
  State<Earning> createState() => _EarningState();
}

class _EarningState extends State<Earning> {
  final AuthController _authController = AuthController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String vendorId = "";
  bool isLoading = true;
  bool hasShownError = false;

  double amountToPay = 0.0;
  double paidAmount = 0.0;
  String businessName = "";
  String vendorName = "";
  int? lastPaymentTimestamp;
  List<Map<String, dynamic>> paymentHistory = [];

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
      await _fetchVendorInfo();
      await _fetchPaymentData();

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
      debugPrint("Error loading vendor data: $e");
    }
  }

  Future<void> _fetchVendorInfo() async {
    final vendorSnap = await _dbRef.child('users').child(vendorId).once();
    if (vendorSnap.snapshot.value != null) {
      final data = vendorSnap.snapshot.value as Map;
      setState(() {
        businessName = data['businessName'] ?? 'Unknown Business';
        vendorName = data['fullName'] ?? 'Unknown Vendor';
      });
    }
  }

  Future<void> _fetchPaymentData() async {
    try {
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final vendorPaymentSnap = await _dbRef.child('vendorPayments').child(vendorId).once();
      if (vendorPaymentSnap.snapshot.value != null) {
        final data = vendorPaymentSnap.snapshot.value as Map;
        lastPaymentTimestamp = data['lastPaymentDate'] as int?;
      }

      final ordersSnap = await _dbRef.child('orders').once();
      if (ordersSnap.snapshot.value == null) return;

      final ordersMap = ordersSnap.snapshot.value as Map<dynamic, dynamic>;
      double newEarnings = 0.0;

      for (var entry in ordersMap.entries) {
        final orderData = entry.value;
        if (orderData['items'] == null) continue;

        final deliveredDate = _parseDeliveredAt(orderData['deliveredAt']);
        if (deliveredDate == null) continue;

        final isInCurrentWeek = !deliveredDate.isBefore(startOfWeek) &&
            !deliveredDate.isAfter(endOfWeek);

        final isAfterLastPayment = lastPaymentTimestamp == null ? true :
        deliveredDate.isAfter(DateTime.fromMillisecondsSinceEpoch(lastPaymentTimestamp!));

        if (isInCurrentWeek && isAfterLastPayment) {
          double vendorOrderTotal = 0.0;
          final items = orderData['items'] as Map<dynamic, dynamic>;

          for (var itemEntry in items.entries) {
            final itemData = itemEntry.value;
            if (itemData['vendorId'] == vendorId && itemData['vendorStatus'] == 'delivered') {
              final price = (itemData['price'] ?? 0.0) as num;
              final quantity = (itemData['quantity'] ?? 1) as num;
              vendorOrderTotal += price * quantity;
            }
          }

          newEarnings += vendorOrderTotal * 0.95;
        }
      }

      double totalPaid = 0.0;
      final paymentHistorySnap = await _dbRef.child('vendorPayments').child(vendorId).child('paymentHistory').once();
      if (paymentHistorySnap.snapshot.value != null) {
        final historyData = paymentHistorySnap.snapshot.value as Map<dynamic, dynamic>;

        // Extract and format payment history
        paymentHistory = [];
        historyData.forEach((key, value) {
          if (value['amount'] != null) {
            final amount = (value['amount'] as num).toDouble();
            totalPaid += amount;

            paymentHistory.add({
              'amount': amount,
              'status': value['status'] ?? 'completed',
              'timestamp': value['timestamp'] as int,
              'formattedDate': _formatTimestamp(value['timestamp'] as int),
            });
          }
        });

        // Sort by timestamp (newest first)
        paymentHistory.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      }

      setState(() {
        paidAmount = totalPaid;
        amountToPay = newEarnings;
      });

      await _updateVendorEarnings(
        updatedEarnings: newEarnings,
        isPaid: false,
      );
    } catch (e) {
      debugPrint("Error fetching payment data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  DateTime? _parseDeliveredAt(dynamic deliveredAtRaw) {
    if (deliveredAtRaw == null) return null;

    try {
      String deliveredStr = deliveredAtRaw.toString();
      if (deliveredStr.startsWith('Delivered on ')) {
        deliveredStr = deliveredStr.replaceFirst('Delivered on ', '');
      }
      deliveredStr = deliveredStr.trim();
      return DateFormat('MMMM d, yyyy \'at\' h:mm a').parse(deliveredStr);
    } catch (e) {
      debugPrint("Error parsing deliveredAt: $e");
      return null;
    }
  }

  Future<void> _updateVendorEarnings({
    required double updatedEarnings,
    required bool isPaid,
  }) async {
    final updateData = {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'businessName': businessName,
      'earned': double.parse(updatedEarnings.toStringAsFixed(2)),
      'paid': isPaid,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };

    if (isPaid) {
      updateData['lastPaymentDate'] = DateTime.now().millisecondsSinceEpoch;
    }

    await _dbRef.child('vendorPayments').child(vendorId).update(updateData);
  }

  Widget _buildPaymentCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey[800] : cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "\$${amount.toInt()}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        // leading removed
        title: Text(
          "\$${transaction['amount'].toStringAsFixed(transaction['amount'].truncateToDouble() == transaction['amount'] ? 0 : 2)}",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          transaction['formattedDate'],
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.green[900] : Colors.green[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Completed',
            style: TextStyle(
              color: isDarkMode ? Colors.green[100] : Colors.green[800],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }


  @override
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDarkMode ? Colors.grey[900]! : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text(
          'My Earnings',
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return const MainVendorScreen(initialIndex: 0);
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4A49)),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Cards
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 150,
                    child: _buildPaymentCard(
                      title: "Amount to Pay",
                      amount: amountToPay,
                      icon: Icons.payment,
                      iconColor: Colors.blue,
                      cardColor: Colors.blue[50]!,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 150,
                    child: _buildPaymentCard(
                      title: "Paid Amount",
                      amount: paidAmount,
                      icon: Icons.paid,
                      iconColor: Colors.green,
                      cardColor: Colors.green[50]!,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 17),

            // Payment History Section with Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0), // <-- left/right padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payment History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),

                  if (paymentHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No transactions yet",
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ...paymentHistory.map((txn) =>
                        _buildTransactionCard(txn, isDarkMode)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}