import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:multi_vendor_ecommerce_app/paymentfiles/payment.dart';
import 'package:multi_vendor_ecommerce_app/paymentfiles/paymentresponse.dart';
import 'package:multi_vendor_ecommerce_app/paymentfiles/textfields.dart';

class firstpage extends StatefulWidget {
  final double totalBalance;
  final Future<void> Function() placeOrder;
  final Map<String, dynamic> billingDetails;

  firstpage(
      this.totalBalance, {
        required this.placeOrder,
        required this.billingDetails,
      });

  @override
  State<firstpage> createState() => _firstpageState();
}

class _firstpageState extends State<firstpage> {
  // Remove all the TextEditingControllers for address details
  TextEditingController amountController = TextEditingController();
  final formkey = GlobalKey<FormState>();
  List<String> currencyList = <String>[
    'PKR',
    'USD',
    'INR',
    'EUR',
    'JPY',
    'GBP',
    'AED'
  ];
  String selectedCurrency = 'PKR';

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(text: widget.totalBalance.toStringAsFixed(0) ?? '');
  }

  Future<String?> _fetchOrderId() async {
    try {
      final orderSnapshot = await FirebaseDatabase.instance.ref('orders').orderByKey().limitToLast(1).once();
      final orderData = orderSnapshot.snapshot.value as Map?;
      return orderData?.keys.last;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch order ID: $e')),
      );
      return null;
    }
  }

  Future<void> initPaymentSheet() async {
    try {
      // Use the billing details from widget.billingDetails
      final data = await cretaePaymentIntent(
        amount: (int.parse(amountController.text)*100).toString(),
        currency: selectedCurrency,
        name: widget.billingDetails['name'],
        address: widget.billingDetails['address']['line1'],
        pin: widget.billingDetails['address']['postal_code'],
        city: widget.billingDetails['address']['city'],
        state: widget.billingDetails['address']['state'],
        country: widget.billingDetails['address']['country'], phone: '', email: '',
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'Your Merchant Name',
          paymentIntentClientSecret: data['client_secret'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['id'],
          style: ThemeMode.dark,
          billingDetails: BillingDetails(
            name: widget.billingDetails['name'],
            email: widget.billingDetails['email'],
            phone: widget.billingDetails['phone'],
            address: Address(
              city: widget.billingDetails['address']['city'],
              country: widget.billingDetails['address']['country'],
              line1: widget.billingDetails['address']['line1'],
              line2: '',
              postalCode: widget.billingDetails['address']['postal_code'],
              state: widget.billingDetails['address']['state'],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      rethrow;
    }
  }

  Future<void> _savePaymentDetails(String orderId) async {
    try {
      final orderRef = FirebaseDatabase.instance.ref('orders').child(orderId);
      final _paymentRef = orderRef.child('payment_details');
      await _paymentRef.update({
        'orderId': orderId,
        'amount': amountController.text,
        'currency': selectedCurrency,
        'timestamp': DateTime.now().toIso8601String(),
        // No need to save address details again as they're already in the order
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save payment details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Complete Your Payment",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Billing Information:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildBillingInfoRow("Name", widget.billingDetails['name']),
                  _buildBillingInfoRow("Email", widget.billingDetails['email']),
                  _buildBillingInfoRow("Phone", widget.billingDetails['phone']),
                  _buildBillingInfoRow("Address", widget.billingDetails['address']['line1']),
                  _buildBillingInfoRow("City", widget.billingDetails['address']['city']),
                  _buildBillingInfoRow("Postal Code", widget.billingDetails['address']['postal_code']),
                  _buildBillingInfoRow("Country", widget.billingDetails['address']['country']),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: ReusableTextField(
                          formkey: formkey,
                          controller: amountController,
                          isNumber: true,
                          title: "Total Order Amount",
                          hint: "Order Amount",
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 10),
                      DropdownMenu<String>(
                        inputDecorationTheme: InputDecorationTheme(
                          contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 0),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade600),
                          ),
                        ),
                        initialSelection: currencyList.first,
                        onSelected: (String? value) {
                          setState(() {
                            selectedCurrency = value!;
                          });
                        },
                        dropdownMenuEntries: currencyList
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.shade400),
                      child: Text(
                        "Proceed to Pay",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: () async {
                        if (formkey.currentState!.validate()) {
                          try {
                            await initPaymentSheet();
                            await Stripe.instance.presentPaymentSheet();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Payment Successful", style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.green,
                              ),
                            );

                            await widget.placeOrder();
                            final orderId = await _fetchOrderId();
                            if (orderId != null) {
                              await _savePaymentDetails(orderId);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResponsePage(orderId),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Payment Failed: $e", style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}