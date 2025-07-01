import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'checkout.dart';
import 'home_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref('carts');
  late User? _currentUser;
  double _totalAmount = 0.0;

  double _calculateShipping(Map<dynamic, dynamic> cartData) {
    final vendorShippingMap = <String, double>{};

    cartData.forEach((key, value) {
      final vendorId = value['vendorId']?.toString() ?? '';
      final shipping = double.tryParse(value['shippingCharges']?.toString() ?? '0') ?? 0.0;

      if (vendorShippingMap.containsKey(vendorId)) {
        if (shipping > vendorShippingMap[vendorId]!) {
          vendorShippingMap[vendorId] = shipping;
        }
      } else {
        vendorShippingMap[vendorId] = shipping;
      }
    });

    return vendorShippingMap.values.fold(0.0, (sum, value) => sum + value);
  }
// Existing methods के नीचे ये method add करें
  double _calculateTax(Map<dynamic, dynamic> cartData) {
    return cartData.entries.fold(0.0, (totalTax, entry) {
      final item = entry.value;
      final tax = _parsePrice(item['taxAmount'] ?? 0.0);
      final quantity = _parseQuantity(item['quantity']);
      return totalTax + (tax * quantity);
    });
  }

  double _parsePrice(dynamic price) {
    if (price is String) return double.tryParse(price) ?? 0.0;
    if (price is num) return price.toDouble();
    return 0.0;
  }

  int _parseQuantity(dynamic quantity) {
    if (quantity is String) return int.tryParse(quantity) ?? 1;
    if (quantity is num) return quantity.toInt();
    return 1;
  }

  String _buildVariantInfo(dynamic item) {
    final color = item['color']?.toString();
    final size = item['size']?.toString();
    final hasColor = color != null && color.isNotEmpty;
    final hasSize = size != null && size.isNotEmpty;

    if (!hasColor && !hasSize) return '';
    if (hasColor && hasSize) return 'Color: $color | Size: $size';
    if (hasColor) return 'Color: $color';
    return 'Size: $size';
  }

  double _getEffectivePrice(dynamic item) {
    final originalPrice = _parsePrice(item['price']);
    final discountPrice = _parsePrice(item['discountPrice']);
    return discountPrice > 0 && discountPrice < originalPrice
        ? discountPrice
        : originalPrice;
  }

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  void _updateQuantity(String itemKey, int newQuantity) {
    if (newQuantity > 0) {
      _cartRef
          .child(_currentUser!.uid)
          .child(itemKey)
          .update({'quantity': newQuantity})
          .then((_) {
        // یہاں کچھ نہیں کرنا، HomeScreen خود بخود update ہو جائے گا
      });
    }
  }

  void _removeItem(String itemKey) {
    if (_currentUser != null) {
      _cartRef.child(_currentUser!.uid).child(itemKey).remove().then((_) {
      });
    }
  }
  double _calculateTotal(Map<dynamic, dynamic> cartData) {
    return cartData.entries.fold(0.0, (total, entry) {
      final item = entry.value;
      final effectivePrice = _getEffectivePrice(item);
      final quantity = _parseQuantity(item['quantity']);
      return total + (effectivePrice * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, _, __) => const HomeScreen(initialIndex: 0),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _cartRef.child(_currentUser?.uid ?? '').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          final cartData = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map);
          final subtotal = _calculateTotal(cartData);
          final shippingCharges = _calculateShipping(cartData);
          final totalTax = _calculateTax(cartData);
          _totalAmount = subtotal + shippingCharges + totalTax;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Padding updated
                  itemCount: cartData.length,
                  itemBuilder: (context, index) {
                    final itemKey = cartData.keys.elementAt(index);
                    final item = cartData[itemKey];
                    return _buildCartItem(
                      context,
                      itemKey: itemKey.toString(),
                      item: item,
                      isDarkMode: isDarkMode,
                    );
                  },
                ),
              ),
              _buildTotalSection(
                context,
                subtotal: subtotal,
                shippingCharges: shippingCharges,
                totalAmount: _totalAmount,
                cartData: cartData,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context, {
        required String itemKey,
        required dynamic item,
        required bool isDarkMode,
      }) {
    final stockStatus = item['stockStatus']?.toString() ?? 'In Stock';
    final variantText = _buildVariantInfo(item);
    final originalPrice = _parsePrice(item['price']);
    final discountPrice = _parsePrice(item['discountPrice']);
    final hasDiscount = discountPrice > 0 && discountPrice < originalPrice;
    final effectivePrice = _getEffectivePrice(item);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['imageUrl'] ?? 'https://via.placeholder.com/80',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12), // Reduced space between image and product details

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name & Delete Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align text and delete icon
                    children: [
                      // Product Name
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            item['productName'] ?? 'No Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Delete Icon
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeItem(itemKey),
                      ),
                    ],
                  ),

                  // Variant Info
                  if (variantText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        variantText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                  // Price and Quantity in Same Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${effectivePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4CAF50),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      _buildQuantitySelector(
                        itemKey: itemKey,
                        currentQuantity: _parseQuantity(item['quantity']),
                        stockStatus: stockStatus,
                      ),
                    ],
                  ),

                  // Original Price (if discounted)
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        '\$${originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                          fontFamily: 'Poppins',
                        ),
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


  /*Widget _buildQuantitySelector({
    required String itemKey,
    required int currentQuantity,
  }) {
    final bool canDecrease = currentQuantity > 1;
    final bool canIncrease = true; // You can add max check if needed

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus Button
        _styledButton(
          icon: Icons.remove,
          onPressed: canDecrease
              ? () => _updateQuantity(itemKey, currentQuantity - 1)
              : null,
          isMinus: true,
          isEnabled: canDecrease,
        ),
        const SizedBox(width: 10),
        // Quantity Display
        Text(
          '$currentQuantity',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 10),
        // Plus Button
        _styledButton(
          icon: Icons.add,
          onPressed: canIncrease
              ? () => _updateQuantity(itemKey, currentQuantity + 1)
              : null,
          isMinus: false,
          isEnabled: canIncrease,
        ),
      ],
    );
  }*/

  /*Widget _buildQuantitySelector({
    required String itemKey,
    required int currentQuantity,
    required String stockStatus, // Add this parameter
  }) {
    final bool canDecrease = currentQuantity > 1;
    // Modified to check stock status
    final bool canIncrease = stockStatus != "Limited Stock";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus Button
        _styledButton(
          icon: Icons.remove,
          onPressed: canDecrease
              ? () => _updateQuantity(itemKey, currentQuantity - 1)
              : null,
          isMinus: true,
          isEnabled: canDecrease,
        ),
        const SizedBox(width: 10),
        // Quantity Display
        Text(
          '$currentQuantity',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 10),
        // Plus Button
        _styledButton(
          icon: Icons.add,
          onPressed: canIncrease
              ? () => _updateQuantity(itemKey, currentQuantity + 1)
              : null,
          isMinus: false,
          isEnabled: canIncrease,
        ),
      ],
    );
  }*/

  Widget _buildQuantitySelector({
    required String itemKey,
    required int currentQuantity,
    required String stockStatus,
  }) {
    final bool canDecrease = currentQuantity > 1;

    // ✅ Modified: If stockStatus is "In Stock", limit to 10 items max
    final bool canIncrease = stockStatus == "In Stock"
        ? currentQuantity < 10
        : stockStatus != "Limited Stock";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus Button
        _styledButton(
          icon: Icons.remove,
          onPressed: canDecrease
              ? () => _updateQuantity(itemKey, currentQuantity - 1)
              : null,
          isMinus: true,
          isEnabled: canDecrease,
        ),
        const SizedBox(width: 10),

        // Quantity Display
        Text(
          '$currentQuantity',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 10),

        // Plus Button
        _styledButton(
          icon: Icons.add,
          onPressed: canIncrease
              ? () => _updateQuantity(itemKey, currentQuantity + 1)
              : null,
          isMinus: false,
          isEnabled: canIncrease,
        ),
      ],
    );
  }


  /*Widget _styledButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isMinus,
    required bool isEnabled,
  }) {
    final Color backgroundColor = isMinus
        ? (isEnabled ? const Color(0xFFF1F1F1) : const Color(0xFFF1F1F1))
        : (isEnabled ? const Color(0xFFFF4A49) : const Color(0xFFF1F1F1));

    final Color iconColor = isMinus
        ? (isEnabled ? const Color(0xFFFF4A49) : Colors.grey)
        : (isEnabled ? Colors.white : Colors.grey);

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }*/


  Widget _styledButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isMinus,
    required bool isEnabled,
  }) {
    final Color backgroundColor = isMinus
        ? (isEnabled ? const Color(0xFFF1F1F1) : const Color(0xFFF1F1F1))
        : (isEnabled ? const Color(0xFFFF4A49) : const Color(0xFFF1F1F1));

    final Color iconColor = isMinus
        ? (isEnabled ? const Color(0xFFFF4A49) : Colors.grey)
        : (isEnabled ? Colors.white : Colors.grey);

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildTotalSection(
      BuildContext context, {
        required double subtotal,
        required double shippingCharges,
        required double totalAmount,
        required Map<dynamic, dynamic> cartData,
      }) {
    final totalTax = _calculateTax(cartData);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', subtotal),
          _buildTotalRow('Shipping Charges', shippingCharges),
          _buildTotalRow('Tax', totalTax),
          const Divider(height: 24),
          _buildTotalRow('Total', totalAmount, isTotal: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const CheckoutScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child); // Example transition
                  },
                  transitionDuration: const Duration(milliseconds: 300), // Optional: You can adjust the transition duration
                ),
              );
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4A49),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              color: isTotal
                  ? const Color(0xFF4CAF50)
                  : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,

              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}