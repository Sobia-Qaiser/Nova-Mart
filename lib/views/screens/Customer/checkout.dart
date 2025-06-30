// import 'dart:math';
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:intl/intl.dart';
//
// import '../../../paymentfiles/firstpage.dart';
// import '../../../paymentfiles/payment.dart';
// import '../innerscreens/orderconfirmation.dart';
//
// class CheckoutScreen extends StatefulWidget {
//   const CheckoutScreen({super.key});
//
//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }
//
// class _CheckoutScreenState extends State<CheckoutScreen> {
//   final DatabaseReference _cartRef = FirebaseDatabase.instance.ref('carts');
//   late User? _currentUser;
//   final _formKey = GlobalKey<FormState>();
//   String _paymentMethod = 'cod';
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _countryController = TextEditingController();
//   final TextEditingController _cityController = TextEditingController();
//   final TextEditingController _zipController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
//
//   bool _isLoading = false;
//
//   String _getFormattedTimestamp() {
//     return DateFormat('dd MMMM y, h:mm a').format(DateTime.now());
//   }
//
//   double _parsePrice(dynamic price) {
//     if (price is String) return double.tryParse(price) ?? 0.0;
//     if (price is num) return price.toDouble();
//     return 0.0;
//   }
//
//   String _buildVariantInfo(dynamic item) {
//     final color = item['color']?.toString();
//     final size = item['size']?.toString();
//     if (color == null && size == null) return '';
//     return '${color != null ? 'Color: $color' : ''}${size != null ? ' | Size: $size' : ''}';
//   }
//
//   double _getEffectivePrice(dynamic item) {
//     final discount = _parsePrice(item['discountPrice']);
//     final price = _parsePrice(item['price']);
//     return (discount > 0 && discount < price) ? discount : price;
//   }
//
//   void _fetchUserDetails() async {
//     if (_currentUser == null) return;
//
//     final snapshot = await _usersRef.child(_currentUser!.uid).get();
//
//     if (snapshot.exists) {
//       final data = snapshot.value as Map<dynamic, dynamic>;
//
//       _fullNameController.text = data['fullName'] ?? '';
//       _emailController.text = data['email'] ?? '';
//     }
//   }
//
//   Widget _buildCartItem(dynamic item, bool isDarkMode) {
//     final variantText = _buildVariantInfo(item);
//     final effectivePrice = _getEffectivePrice(item);
//
//     return Container(
//       margin: const EdgeInsets.only(top: 0, bottom: 8),
//       decoration: BoxDecoration(
//         color: isDarkMode ? Colors.grey[800] : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12.withOpacity(0.1),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Image.network(
//                 item['imageUrl'] ?? 'https://via.placeholder.com/80',
//                 width: 60,
//                 height: 60,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     item['productName'] ?? 'No Name',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: isDarkMode ? Colors.white : Colors.black,
//                     ),
//                   ),
//                   if (variantText.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Text(
//                         variantText,
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 13,
//                         ),
//                       ),
//                     ),
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           '\$${effectivePrice.toStringAsFixed(0)}',
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF4CAF50),
//                           ),
//                         ),
//                         Text(
//                           'Qty: ${item['quantity']}',
//                           style: TextStyle(
//                             color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   void _placeOrder(double total, double shipping, double tax) async {
//     if (_formKey.currentState!.validate()) {
//       if (_paymentMethod == 'stripe') {
//         // Directly process Stripe payment without showing firstpage
//         try {
//           setState(() {
//             _isLoading = true;
//           });
//
//           // Initialize payment sheet with customer details
//           final data = await cretaePaymentIntent(
//             amount: (total * 100).toInt().toString(),
//             currency: 'USD', // or your preferred currency
//             name: _fullNameController.text,
//             email: _emailController.text,
//             phone: _phoneController.text,
//             address: _addressController.text,
//             city: _cityController.text,
//             state: '', // Add if you have state field
//             country: _countryController.text,
//             pin: _zipController.text,
//           );
//
//           await Stripe.instance.initPaymentSheet(
//             paymentSheetParameters: SetupPaymentSheetParameters(
//               customFlow: false,
//               merchantDisplayName: 'Your Store Name',
//               paymentIntentClientSecret: data['client_secret'],
//               customerEphemeralKeySecret: data['ephemeralKey'],
//               customerId: data['id'],
//               style: ThemeMode.dark,
//               billingDetails: BillingDetails(
//                 name: _fullNameController.text,
//                 email: _emailController.text,
//                 phone: _phoneController.text,
//                 address: Address(
//                   city: _cityController.text,
//                   country: _countryController.text,
//                   line1: _addressController.text,
//                   postalCode: _zipController.text,
//                   line2: '',
//                   state: '',
//                 ),
//               ),
//             ),
//           );
//
//           // Present the payment sheet
//           await Stripe.instance.presentPaymentSheet();
//
//           // Payment successful - process the order
//           await _processOrder(total, shipping, tax);
//
//           // Show success message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Payment successful!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Payment failed: $e'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         } finally {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       } else {
//         // Process COD order directly
//         _processOrder(total, shipping, tax);
//       }
//     }
//   }
//   // Separate method to process the actual order
//   Future<void> _processOrder(double total, double shipping, double tax) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final user = FirebaseAuth.instance.currentUser!;
//       final orderRef = FirebaseDatabase.instance.ref('orders').push();
//       final orderId = orderRef.key!;
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final orderNumber = '#${timestamp % 100000}'; // Human-readable order #
//
//       final orderData = {
//         'orderId': orderId,
//         'orderNumber': orderNumber,
//         'userId': user.uid,
//         'name': _fullNameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'country': _countryController.text,
//         'city': _cityController.text,
//         'zipCode': _zipController.text,
//         'address': _addressController.text,
//         'totalAmount': total,
//         'paymentMethod': _paymentMethod,
//         'status': 'Pending',
//         'createdAt': _getFormattedTimestamp(),
//         'shippingCharges': shipping,
//         'taxAmount': tax,
//         'deliveryTime': "5 to 6 business Days",
//       };
//
//       await orderRef.set(orderData);
//       final cartSnapshot = await _cartRef.child(user.uid).get();
//
//       if (cartSnapshot.exists) {
//         final cartItems = Map<String, dynamic>.from(cartSnapshot.value as Map);
//         final itemsRef = orderRef.child('items');
//
//         int itemCount = 1;
//         for (var entry in cartItems.entries) {
//           // Create base item data including imageUrl
//           final itemData = {
//             'productId': entry.value['productId'],
//             'name': entry.value['productName'],
//             'price': _getEffectivePrice(entry.value),
//             'quantity': entry.value['quantity'],
//             'vendorId': entry.value['vendorId'],
//             'imageUrl': entry.value['imageUrl'], // Add image URL to order items
//           };
//
//           if (entry.value['size'] != null && entry.value['size'].toString().isNotEmpty) {
//             itemData['size'] = entry.value['size'];
//           }
//           if (entry.value['color'] != null && entry.value['color'].toString().isNotEmpty) {
//             itemData['color'] = entry.value['color'];
//           }
//           await itemsRef.child('item$itemCount').set(itemData);
//           itemCount++;
//
//           // Stock management logic
//           final productRef = FirebaseDatabase.instance.ref('products/${entry.value['productId']}');
//           final orderedQty = entry.value['quantity'] as int;
//
//           try {
//             await productRef.runTransaction((Object? currentData) {
//               if (currentData == null) {
//                 print('⚠️ Product ${entry.value['productId']} not found in database!');
//                 return Transaction.abort();
//               }
//
//               Map<String, dynamic> product = Map<String, dynamic>.from(currentData as Map);
//               final productType = product['productType']?.toString() ?? 'Simple Product';
//
//               if (productType == 'Simple Product') {
//                 int currentQty = (product['quantity'] is String)
//                     ? int.tryParse(product['quantity']) ?? 0
//                     : (product['quantity'] as int? ?? 0);
//
//                 product['quantity'] = max(currentQty - orderedQty, 0);
//                 print('✅ Simple product stock updated: $currentQty → ${product['quantity']}');
//               }
//
//               else if (productType == 'Product Variants') {
//                 List<dynamic> variations = List.from(product['variations'] ?? []);
//                 bool variationFound = false;
//
//                 final orderSize = entry.value['size']?.toString()?.toLowerCase();
//                 final orderColor = entry.value['color']?.toString()?.toLowerCase();
//
//                 for (int i = 0; i < variations.length; i++) {
//                   final variation = Map<String, dynamic>.from(variations[i]);
//
//                   final varColor = variation['color']?.toString()?.toLowerCase();
//                   final varSize = variation['size']?.toString()?.toLowerCase();
//
//                   bool colorMatch = (orderColor != null && orderColor.isNotEmpty)
//                       ? varColor == orderColor
//                       : true;
//
//                   bool sizeMatch = (orderSize != null && orderSize.isNotEmpty)
//                       ? varSize == orderSize
//                       : true;
//
//                   if (colorMatch && sizeMatch) {
//                     int currentVarQty = (variation['quantity'] is String)
//                         ? int.tryParse(variation['quantity']) ?? 0
//                         : (variation['quantity'] as int? ?? 0);
//
//                     final newQty = max(currentVarQty - orderedQty, 0);
//                     print("✅ Variant matched [Color: $varColor, Size: $varSize], Qty: $currentVarQty → $newQty");
//
//                     variation['quantity'] = newQty;
//                     variations[i] = variation;
//                     variationFound = true;
//                     break;
//                   }
//                 }
//
//                 if (!variationFound) {
//                   print("❌ No matching variant found for Color: $orderColor, Size: $orderSize");
//                   return Transaction.abort();
//                 }
//
//                 product['variations'] = variations;
//               }
//
//               else {
//                 return Transaction.abort();
//               }
//
//               return Transaction.success(product);
//             });
//           } catch (e) {
//             print('🔥 Transaction error for product ${entry.value['productId']}: $e');
//             throw Exception('Failed to update product stock: ${e.toString()}');
//           }
//         }
//       }
//
//       await _cartRef.child(user.uid).remove();
//
//       // Navigate to Order Confirmation Screen
//       Navigator.pushReplacement(
//         context,
//         PageRouteBuilder(
//           pageBuilder: (context, animation, secondaryAnimation) {
//             return OrderConfirmationScreen(
//               orderId: orderId,
//               totalAmount: total,
//               paymentMethod: _paymentMethod == 'cod' ? 'Cash on Delivery' : 'Credit Card',
//               deliveryTime: "5 to 6 business Days",
//               address: _addressController.text,
//               orderNumber: orderNumber,
//             );
//           },
//           transitionsBuilder: (context, animation, secondaryAnimation, child) {
//             return FadeTransition(opacity: animation, child: child);
//           },
//           transitionDuration: const Duration(milliseconds: 300),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error placing order: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _currentUser = FirebaseAuth.instance.currentUser;
//     _fetchUserDetails();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text(
//           'Checkout',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             fontSize: 18,
//             color: Colors.white,
//             fontFamily: 'Poppins',
//             letterSpacing: 0.5,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: const Color(0xFFFF4A49),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded,
//               size: 18, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: StreamBuilder(
//         stream: _cartRef.child(_currentUser?.uid ?? '').onValue,
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//
//           final cartData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
//           if (cartData == null) return const Center(child: Text('Cart is empty'));
//
//           final subtotal = cartData.values.fold(0.0, (sum, item) =>
//           sum + (_getEffectivePrice(item) * item['quantity']));
//
//           final shipping = _calculateShipping(Map.from(cartData));
//           final tax = _calculateTax(Map.from(cartData));
//           final total = subtotal + shipping + tax;
//
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Cart Summary',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: isDarkMode ? Colors.white : Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ...cartData.entries.map((entry) =>
//                     _buildCartItem(entry.value, isDarkMode)).toList(),
//
//                 const SizedBox(height: 20),
//                 Text(
//                   'Billing Details',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: isDarkMode ? Colors.white : Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       _buildTextField('Full Name', _fullNameController),
//                       _buildTextField('Email Address', _emailController),
//                       _buildTextField('Phone Number', _phoneController),
//                       _buildTextField('Country', _countryController),
//                       Row(
//                         children: [
//                           Expanded(child: _buildTextField('City', _cityController)),
//                           const SizedBox(width: 16),
//                           Expanded(child: _buildTextField('ZIP Code', _zipController)),
//                         ],
//                       ),
//                       _buildTextField('Address', _addressController, lines: 3),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//                 Text(
//                   'Payment Method',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: isDarkMode ? Colors.white : Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 1),
//                 _buildPaymentMethod('Cash on Delivery', 'cod'),
//                 _buildPaymentMethod('Credit Card (Stripe)', 'stripe'),
//
//                 const SizedBox(height: 20),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: isDarkMode ? Colors.grey[800] : Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     children: [
//                       _buildTotalRow('Subtotal', subtotal),
//                       _buildTotalRow('Shipping', shipping),
//                       _buildTotalRow('Tax', tax),
//                       const Divider(),
//                       _buildTotalRow('Total', total, isTotal: true),
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFFFF4A49),
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                           ),
//                           onPressed: () => _placeOrder(total, shipping, tax),
//                           child: _isLoading
//                               ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 4,
//                             ),
//                           )
//                               : const Text(
//                             'Place Order',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                               fontFamily: 'Poppins',
//                             ),
//                           ),
//                         ),
//                       ),
//
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller, {int lines = 1}) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         style: TextStyle(
//           fontSize: 14,
//           color: isDarkMode ? Colors.white : Colors.black,
//         ),
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: TextStyle(
//             color: Colors.grey[600],
//             fontSize: 13,
//           ),
//           filled: true,
//           fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(
//               color: Colors.grey.withOpacity(0.4),
//               width: 1.2,
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: const BorderSide(
//               color: Color(0xFFFF4A49),
//               width: 1.5,
//             ),
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Required field';
//           }
//
//           if (label == 'Full Name') {
//             if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
//               return 'Only alphabets and spaces allowed';
//             }
//           }
//
//           if (label == 'Email Address') {
//             if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//               return 'Invalid email format';
//             }
//           }
//
//           if (label == 'Phone Number') {
//             if (!RegExp(r'^[0-9+]+$').hasMatch(value)) {
//               return 'Only numbers allowed';
//             }
//             if (value.length < 8 || value.length > 15) {
//               return 'Invalid length (8-15 digits)';
//             }
//           }
//
//           if (label == 'Country') {
//             if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
//               return 'Only alphabets allowed';
//             }
//           }
//
//           if (label == 'City') {
//             if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
//               return 'Only alphabets allowed';
//             }
//           }
//
//           if (label == 'ZIP Code') {
//             if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
//               return 'numbers allowed';
//             }
//             if (value.length < 4 || value.length > 6) {
//               return 'Invalid ZIP';
//             }
//           }
//
//           return null;
//         },
//         maxLines: lines,
//       ),
//     );
//   }
//
//   Widget _buildPaymentMethod(String title, String value) {
//     return Theme(
//       data: Theme.of(context).copyWith(
//         splashColor: Colors.transparent,
//         highlightColor: Colors.transparent,
//         hoverColor: Colors.transparent,
//       ),
//       child: RadioListTile<String>(
//         title: Text(title),
//         value: value,
//         groupValue: _paymentMethod,
//         onChanged: (v) => setState(() => _paymentMethod = v!),
//         tileColor: Colors.transparent,
//         contentPadding: EdgeInsets.zero,
//         visualDensity: VisualDensity.compact,
//         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       ),
//     );
//   }
//
//   Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//           Text(
//             '\$${amount.toStringAsFixed(0)}',
//             style: TextStyle(
//               fontSize: isTotal ? 18 : 16,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//               color: const Color(0xFF4CAF50),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   double _calculateShipping(Map<dynamic, dynamic> cartData) {
//     final vendorShippingMap = <String, double>{};
//     cartData.forEach((key, value) {
//       final vendorId = value['vendorId'].toString();
//       final shipping = _parsePrice(value['shippingCharges']);
//       if (!vendorShippingMap.containsKey(vendorId)) {
//         vendorShippingMap[vendorId] = shipping;
//       } else if (shipping > vendorShippingMap[vendorId]!) {
//         vendorShippingMap[vendorId] = shipping;
//       }
//     });
//     return vendorShippingMap.values.fold(0.0, (sum, value) => sum + value);
//   }
//
//   double _calculateTax(Map<dynamic, dynamic> cartData) {
//     return cartData.values.fold(0.0, (sum, item) =>
//     sum + _parsePrice(item['taxAmount']) * item['quantity']);
//   }
// }


import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';

import '../../../paymentfiles/firstpage.dart';
import '../../../paymentfiles/payment.dart';
import '../innerscreens/orderconfirmation.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>  {
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref('carts');
  late User? _currentUser;
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'cod';
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  bool _isLoading = false;

  String _getFormattedTimestamp() {
    return DateFormat('dd MMMM y, h:mm a').format(DateTime.now());
  }

  double _parsePrice(dynamic price) {
    if (price is String) return double.tryParse(price) ?? 0.0;
    if (price is num) return price.toDouble();
    return 0.0;
  }

  String _buildVariantInfo(dynamic item) {
    final color = item['color']?.toString();
    final size = item['size']?.toString();
    if (color == null && size == null) return '';
    return '${color != null ? 'Color: $color' : ''}${size != null ? ' | Size: $size' : ''}';
  }

  double _getEffectivePrice(dynamic item) {
    final discount = _parsePrice(item['discountPrice']);
    final price = _parsePrice(item['price']);
    return (discount > 0 && discount < price) ? discount : price;
  }

  void _fetchUserDetails() async {
    if (_currentUser == null) return;

    final snapshot = await _usersRef.child(_currentUser!.uid).get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      _fullNameController.text = data['fullName'] ?? '';
      _emailController.text = data['email'] ?? '';
    }
  }

  Widget _buildCartItem(dynamic item, bool isDarkMode) {
    final variantText = _buildVariantInfo(item);
    final effectivePrice = _getEffectivePrice(item);

    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 8),
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['imageUrl'] ?? 'https://via.placeholder.com/80',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'] ?? 'No Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  if (variantText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        variantText,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${effectivePrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        Text(
                          'Qty: ${item['quantity']}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(double total, double shipping, double tax) async {
    if (_formKey.currentState!.validate()) {
      if (_paymentMethod == 'stripe') {
        // Process Stripe payment and save payment details
        try {
          setState(() {
            _isLoading = true;
          });

          // Initialize payment sheet with customer details
          final data = await cretaePaymentIntent(
            amount: (total * 100).toInt().toString(),
            currency: 'USD',
            name: _fullNameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            city: _cityController.text,
            state: '',
            country: _countryController.text,
            pin: _zipController.text,
          );

          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              customFlow: false,
              merchantDisplayName: 'Your Store Name',
              paymentIntentClientSecret: data['client_secret'],
              customerEphemeralKeySecret: data['ephemeralKey'],
              customerId: data['id'],
              style: ThemeMode.dark,
              billingDetails: BillingDetails(
                name: _fullNameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                address: Address(
                  city: _cityController.text,
                  country: _countryController.text,
                  line1: _addressController.text,
                  postalCode: _zipController.text,
                  line2: '',
                  state: '',
                ),
              ),
            ),
          );

          // Present the payment sheet
          await Stripe.instance.presentPaymentSheet();

          // Payment successful - process the order with Stripe payment details
          await _processOrder(
            total,
            shipping,
            tax,
            paymentDetails: {
              'paymentIntentId': data['payment_intent_id'],
              'customerId': data['id'],
              'clientSecret': data['client_secret'],
              'paymentStatus': 'completed',
              'paymentGateway': 'stripe',
              'transactionId': data['payment_intent_id'], // Stripe uses payment intent ID as transaction ID
              'paymentDate': _getFormattedTimestamp(),
              'cardDetails': {
                'last4': '****', // This would need to be retrieved from the payment method
                'brand': 'unknown', // This would need to be retrieved from the payment method
                'expMonth': null,
                'expYear': null,
              },
              'billingAddress': {
                'name': _fullNameController.text,
                'email': _emailController.text,
                'phone': _phoneController.text,
                'address': _addressController.text,
                'city': _cityController.text,
                'country': _countryController.text,
                'zipCode': _zipController.text,
              },
            },
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Process COD order directly
        _processOrder(total, shipping, tax);
      }
    }
  }

  // Enhanced method to process the actual order with payment details
  Future<void> _processOrder(
      double total,
      double shipping,
      double tax,
      {Map<String, dynamic>? paymentDetails}
      ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final orderRef = FirebaseDatabase.instance.ref('orders').push();
      final orderId = orderRef.key!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderNumber = '#${timestamp % 100000}';

      final orderData = {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'userId': user.uid,
        'name': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'country': _countryController.text,
        'city': _cityController.text,
        'zipCode': _zipController.text,
        'address': _addressController.text,
        'totalAmount': total,
        'paymentMethod': _paymentMethod,
        'status': 'Pending',
        'createdAt': _getFormattedTimestamp(),
        'shippingCharges': shipping,
        'taxAmount': tax,
        'deliveryTime': "5 to 6 business Days",
      };

      // Add payment details for credit card payments
      if (paymentDetails != null && _paymentMethod == 'stripe') {
        orderData['paymentDetails'] = paymentDetails;

        // Also save payment details separately for easier querying
        final paymentRef = FirebaseDatabase.instance.ref('payments').push();
        final paymentData = {
          'paymentId': paymentRef.key,
          'orderId': orderId,
          'orderNumber': orderNumber,
          'userId': user.uid,
          'amount': total,
          'currency': 'USD',
          'createdAt': _getFormattedTimestamp(),
          'timestamp': timestamp,
          ...paymentDetails,
        };

        await paymentRef.set(paymentData);

        // Update order with payment reference (only if key exists)
        if (paymentRef.key != null) {
          orderData['paymentId'] = paymentRef.key!;
        }
      }

      await orderRef.set(orderData);

      // Process cart items and stock management (existing code)
      final cartSnapshot = await _cartRef.child(user.uid).get();

      if (cartSnapshot.exists) {
        final cartItems = Map<String, dynamic>.from(cartSnapshot.value as Map);
        final itemsRef = orderRef.child('items');

        int itemCount = 1;
        for (var entry in cartItems.entries) {
          final itemData = {
            'productId': entry.value['productId'],
            'name': entry.value['productName'],
            'price': _getEffectivePrice(entry.value),
            'quantity': entry.value['quantity'],
            'vendorId': entry.value['vendorId'],
            'imageUrl': entry.value['imageUrl'],
          };

          if (entry.value['size'] != null && entry.value['size'].toString().isNotEmpty) {
            itemData['size'] = entry.value['size'];
          }
          if (entry.value['color'] != null && entry.value['color'].toString().isNotEmpty) {
            itemData['color'] = entry.value['color'];
          }

          await itemsRef.child('item$itemCount').set(itemData);
          itemCount++;

          // Stock management logic (existing code remains the same)
          final productRef = FirebaseDatabase.instance.ref('products/${entry.value['productId']}');
          final orderedQty = entry.value['quantity'] as int;

          try {
            await productRef.runTransaction((Object? currentData) {
              if (currentData == null) {
                print('⚠️ Product ${entry.value['productId']} not found in database!');
                return Transaction.abort();
              }

              Map<String, dynamic> product = Map<String, dynamic>.from(currentData as Map);
              final productType = product['productType']?.toString() ?? 'Simple Product';

              if (productType == 'Simple Product') {
                int currentQty = (product['quantity'] is String)
                    ? int.tryParse(product['quantity']) ?? 0
                    : (product['quantity'] as int? ?? 0);

                product['quantity'] = max(currentQty - orderedQty, 0);
                print('✅ Simple product stock updated: $currentQty → ${product['quantity']}');
              }
              else if (productType == 'Product Variants') {
                List<dynamic> variations = List.from(product['variations'] ?? []);
                bool variationFound = false;

                final orderSize = entry.value['size']?.toString()?.toLowerCase();
                final orderColor = entry.value['color']?.toString()?.toLowerCase();

                for (int i = 0; i < variations.length; i++) {
                  final variation = Map<String, dynamic>.from(variations[i]);

                  final varColor = variation['color']?.toString()?.toLowerCase();
                  final varSize = variation['size']?.toString()?.toLowerCase();

                  bool colorMatch = (orderColor != null && orderColor.isNotEmpty)
                      ? varColor == orderColor
                      : true;

                  bool sizeMatch = (orderSize != null && orderSize.isNotEmpty)
                      ? varSize == orderSize
                      : true;

                  if (colorMatch && sizeMatch) {
                    int currentVarQty = (variation['quantity'] is String)
                        ? int.tryParse(variation['quantity']) ?? 0
                        : (variation['quantity'] as int? ?? 0);

                    final newQty = max(currentVarQty - orderedQty, 0);
                    print("✅ Variant matched [Color: $varColor, Size: $varSize], Qty: $currentVarQty → $newQty");

                    variation['quantity'] = newQty;
                    variations[i] = variation;
                    variationFound = true;
                    break;
                  }
                }

                if (!variationFound) {
                  print("❌ No matching variant found for Color: $orderColor, Size: $orderSize");
                  return Transaction.abort();
                }

                product['variations'] = variations;
              }
              else {
                return Transaction.abort();
              }

              return Transaction.success(product);
            });
          } catch (e) {
            print('🔥 Transaction error for product ${entry.value['productId']}: $e');
            throw Exception('Failed to update product stock: ${e.toString()}');
          }
        }
      }

      await _cartRef.child(user.uid).remove();

      // Navigate to Order Confirmation Screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return OrderConfirmationScreen(
              orderId: orderId,
              totalAmount: total,
              paymentMethod: _paymentMethod == 'cod' ? 'Cash on Delivery' : 'Credit Card',
              deliveryTime: "5 to 6 business Days",
              address: _addressController.text,
              orderNumber: orderNumber,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Checkout',
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
        stream: _cartRef.child(_currentUser?.uid ?? '').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final cartData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
          if (cartData == null) return const Center(child: Text('Cart is empty'));

          final subtotal = cartData.values.fold(0.0, (sum, item) =>
          sum + (_getEffectivePrice(item) * item['quantity']));

          final shipping = _calculateShipping(Map.from(cartData));
          final tax = _calculateTax(Map.from(cartData));
          final total = subtotal + shipping + tax;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cart Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ...cartData.entries.map((entry) =>
                    _buildCartItem(entry.value, isDarkMode)).toList(),

                const SizedBox(height: 20),
                Text(
                  'Billing Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField('Full Name', _fullNameController),
                      _buildTextField('Email Address', _emailController),
                      _buildTextField('Phone Number', _phoneController),
                      _buildTextField('Country', _countryController),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('City', _cityController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('ZIP Code', _zipController)),
                        ],
                      ),
                      _buildTextField('Address', _addressController, lines: 3),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                _buildPaymentMethod('Cash on Delivery', 'cod'),
                _buildPaymentMethod('Credit Card (Stripe)', 'stripe'),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow('Subtotal', subtotal),
                      _buildTotalRow('Shipping', shipping),
                      _buildTotalRow('Tax', tax),
                      const Divider(),
                      _buildTotalRow('Total', total, isTotal: true),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4A49),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _placeOrder(total, shipping, tax),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          )
                              : const Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int lines = 1}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFFF4A49),
              width: 1.5,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required field';
          }

          if (label == 'Full Name') {
            if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
              return 'Only alphabets and spaces allowed';
            }
          }

          if (label == 'Email Address') {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Invalid email format';
            }
          }

          if (label == 'Phone Number') {
            if (!RegExp(r'^[0-9+]+$').hasMatch(value)) {
              return 'Only numbers allowed';
            }
            if (value.length < 8 || value.length > 15) {
              return 'Invalid length (8-15 digits)';
            }
          }

          if (label == 'Country') {
            if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
              return 'Only alphabets allowed';
            }
          }

          if (label == 'City') {
            if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
              return 'Only alphabets allowed';
            }
          }

          if (label == 'ZIP Code') {
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'numbers allowed';
            }
            if (value.length < 4 || value.length > 6) {
              return 'Invalid ZIP';
            }
          }

          return null;
        },
        maxLines: lines,
      ),
    );
  }

  Widget _buildPaymentMethod(String title, String value) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: RadioListTile<String>(
        title: Text(title),
        value: value,
        groupValue: _paymentMethod,
        onChanged: (v) => setState(() => _paymentMethod = v!),
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateShipping(Map<dynamic, dynamic> cartData) {
    final vendorShippingMap = <String, double>{};
    cartData.forEach((key, value) {
      final vendorId = value['vendorId'].toString();
      final shipping = _parsePrice(value['shippingCharges']);
      if (!vendorShippingMap.containsKey(vendorId)) {
        vendorShippingMap[vendorId] = shipping;
      } else if (shipping > vendorShippingMap[vendorId]!) {
        vendorShippingMap[vendorId] = shipping;
      }
    });
    return vendorShippingMap.values.fold(0.0, (sum, value) => sum + value);
  }

  double _calculateTax(Map<dynamic, dynamic> cartData) {
    return cartData.values.fold(0.0, (sum, item) =>
    sum + _parsePrice(item['taxAmount']) * item['quantity']);
  }
}

