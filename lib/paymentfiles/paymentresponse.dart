import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../views/screens/Customer/home_screen.dart';


class ResponsePage extends StatefulWidget {
  final String orderId;

  ResponsePage(this.orderId); // Add orderId as a parameter


  @override
  _ResponsePageState createState() => _ResponsePageState();
}

class _ResponsePageState extends State<ResponsePage> {
  late final DatabaseReference _orderRef;

  @override
  void initState() {
    super.initState();
    _orderRef = FirebaseDatabase.instance.ref("orders").child(widget.orderId);
  }

  Future<Map<String, dynamic>> fetchPaymentDetails() async {
    try {
      // Fetch the snapshot from the specific order reference
      DatabaseEvent event = await _orderRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        DataSnapshot paymentDetailsSnapshot = snapshot.child("payment_details");

        if (paymentDetailsSnapshot.exists) {
          // Convert the snapshot value to a Map
          return Map<String, dynamic>.from(paymentDetailsSnapshot.value as Map<dynamic, dynamic>);
        }
      }
      return {};
    } catch (e) {
      // Handle errors
      print('Error fetching payment details: $e');
      return {};
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Payment Successful'),
          backgroundColor: Colors.green,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: fetchPaymentDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data found'));
            } else {
              final data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Thank you for your purchase!",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "You have successfully paid ${data['amount'] ?? 'N/A'} ${data['currency'] ?? 'N/A'}.",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Payment Details:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                      },
                      border: TableBorder.all(color: Colors.grey),
                      children: [
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(data['name'] ?? 'N/A'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(data['address'] ?? 'N/A'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('City', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(data['city'] ?? 'N/A'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('State', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(data['state'] ?? 'N/A'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Country', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(data['country'] ?? 'N/A'),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Pincode', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(data['pincode'] ?? 'N/A'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.shade400),
                      child: const Text("Shop More"),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

