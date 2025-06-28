import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VendorPaymentHistoryScreen extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final String businessName;

  const VendorPaymentHistoryScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment History',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // History List
            Expanded(
              child: StreamBuilder(
                // Replace with your actual Firebase stream for payment history
                stream: FirebaseDatabase.instance
                    .ref('vendorPayments/$vendorId/paymentHistory')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Text(
                        'No payment history found',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  final historyData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final historyList = historyData.entries.map((entry) {
                    return {
                      'amount': entry.value['amount'] ?? 0,
                      'timestamp': entry.value['timestamp'] ?? 0,
                      'status': entry.value['status'] ?? 'completed',
                      'formattedDate': _formatTimestamp(entry.value['timestamp'] as int),
                    };
                  }).toList()
                    ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

                  return ListView.builder(
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final payment = historyList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0), // spacing between cards
                        child: _buildTransactionCard(payment, isDarkMode),
                      );
                    },
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        // Removed the leading icon
        title: Text(
          "\$${transaction['amount'].toInt()}",
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.green[900] : Colors.green[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            transaction['status'].toString().toUpperCase(),
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

}