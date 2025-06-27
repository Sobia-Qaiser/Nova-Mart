import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../innerscreens/ProductInfo.dart';
import 'home_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final DatabaseReference _favoritesRef = FirebaseDatabase.instance.ref('favourites');
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');
  List<Map<String, dynamic>> favorites = [];
  final bool isDarkMode = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  void _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => isLoading = true);
    // Add listener for real-time updates
    _favoritesRef.child(user.uid).onValue.listen((event) {
      if (event.snapshot.exists) {
        _fetchProductDetails(event.snapshot.value as Map<dynamic, dynamic>);
      } else {
        setState(() {
          favorites = [];
          isLoading = false; // Update loading state
        });
      }
    });
  }

  void _fetchProductDetails(Map<dynamic, dynamic> favoritesData) async {
    List<Map<String, dynamic>> favoriteItems = [];

    for (var productId in favoritesData.keys) {
      final productSnapshot = await _productsRef.child(productId).get();
      if (productSnapshot.exists) {
        final productData = productSnapshot.value as Map<dynamic, dynamic>;
        favoriteItems.add({
          'id': productId,
          'name': productData['productName'] ?? 'Unnamed Product',
          'imageUrls': (productData['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
          'price': (productData['price'] ?? 0).toDouble(),
          'discountPrice': (productData['discountPrice'] ?? 0).toDouble(),
        });
      }
    }
    setState(() {
      favorites = favoriteItems;
      isLoading = false; // Update loading state when done
    });
  }

  void _removeFromFavorites(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Remove from Firebase
      await _favoritesRef.child(user.uid).child(productId).remove();

      // 2. Update UI immediately for better responsiveness
      setState(() {
        favorites.removeWhere((item) => item['id'] == productId);
      });


      // 4. Optional: Refresh data from server
      // await _fetchFavorites();

    } catch (e) {
      // 5. Handle errors and revert UI
      setState(() => favorites = [...favorites]); // Revert changes
      Get.snackbar(
          "Error",
          "Failed to remove: $e",
          backgroundColor: Colors.red
      );
    }
  }

  Widget _buildProductImage(List<String> imageUrls) {
    if (imageUrls.isEmpty) return _buildPlaceholder();

    return Image.network(
      imageUrls.first,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(Icons.image, color: Colors.grey[700]),
    );
  }

  Widget _buildDiscountBadge(double original, double discounted) {
    if (original <= discounted) return SizedBox();
    final percentage = ((original - discounted) / original * 100).round();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('-$percentage%',
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600,)),
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
        title: const Text(
          'My Wishlist',
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
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4A49)),
        ),
      )
          : favorites.isEmpty
          ? Center(child: Text('No products in wishlist',
          style: TextStyle(color: Colors.grey[600])))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final product = favorites[index];
          // Add these 3 lines at the start of the builder
          final originalPrice = product['price'];
          final discountPrice = product['discountPrice'];
          final hasDiscount = discountPrice > 0 && discountPrice < originalPrice;

          return GestureDetector( // <-- ये नया GestureDetector जोड़ें
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => ProductInfo(productId: product['id']),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },

          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildProductImage(product['imageUrls']),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'], /*...*/),
                      SizedBox(height: 1),
                      Row(
                        children: [
                          // Change this Text widget
                          Text(
                            '\$${(hasDiscount ? discountPrice : originalPrice).toStringAsFixed(0)}',
                            style: TextStyle(
                                color: Color(0xFFFF4A49),
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          // Add conditional rendering
                          if (hasDiscount) ...[
                            SizedBox(width: 4),
                            Text(
                              '\$${originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 4),
                            _buildDiscountBadge(originalPrice, discountPrice),
                          ],
                        ],
                      ),
                      // Add conditional saving text
                      if (hasDiscount) ...[
                        SizedBox(height: 1),
                        Text(
                          'Save \$${(originalPrice - discountPrice).toStringAsFixed(0)}',
                          style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.favorite, color: Color(0xFFFF4A49)),
                  onPressed: () => _removeFromFavorites(product['id']),
                ),
              ],
            ),
          )
          );
        },
      ),
    );
  }
}