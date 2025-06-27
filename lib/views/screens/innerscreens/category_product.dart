import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'ProductInfo.dart';

class CategoryProductScreen extends StatefulWidget {
  final String categoryKey;
  final String categoryName;


  const CategoryProductScreen({
    super.key,
    required this.categoryKey,
    required this.categoryName,
  });

  @override
  State<CategoryProductScreen> createState() => _CategoryProductScreenState();
}

class _CategoryProductScreenState extends State<CategoryProductScreen> {
  final DatabaseReference _productsRef =
  FirebaseDatabase.instance.ref().child('products');
  final DatabaseReference _favoritesRef = FirebaseDatabase.instance.ref('favourites');

  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  Set<String> favoriteProductIds = {};
  Set<String> cartProductIds = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _loadFavorites();
  }

  void fetchProducts() async {
    _productsRef.once().then((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        List<Map<String, dynamic>> temp = [];
        Map<dynamic, dynamic> productsMap = snapshot.value as Map<dynamic, dynamic>;
        productsMap.forEach((key, value) {
          if (value['category'] == widget.categoryName) {
            temp.add({
              'id': key,
              'name': value['productName'],
              'price': value['price'],
              'discountPrice': value['discountPrice'],
              'description': value['description'],
              'image': (value['imageUrls'] != null && value['imageUrls'][0] != null)
                  ? value['imageUrls'][0]
                  : null,
            });
          }
        });
        setState(() {
          filteredProducts = temp;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    });
  }


  String calculateDiscountPercentage(dynamic actualPrice, dynamic discountPrice) {
    double actual = actualPrice is int ? actualPrice.toDouble() : actualPrice;
    double discount = discountPrice is int ? discountPrice.toDouble() : discountPrice;
    if (actual == 0) return "0%";
    return "${((actual - discount) / actual * 100).round()}";
  }

  Widget _buildActionButton(IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: const Color(0xFFFF4A49),
      ),
    );
  }

  void _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _favoritesRef.child(user.uid).get();
    if (snapshot.exists) {
      final favorites = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        favoriteProductIds = favorites.keys.toSet();
      });
    }
  }

  void _toggleFavorite(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar("Error", "Please login to add favorites");
      return;
    }

    try {
      if (favoriteProductIds.contains(productId)) {
        await _favoritesRef.child(user.uid).child(productId).remove();
      } else {
        await _favoritesRef.child(user.uid).child(productId).set(true);
      }

      setState(() {
        favoriteProductIds.contains(productId)
            ? favoriteProductIds.remove(productId)
            : favoriteProductIds.add(productId);
      });

    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
      final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4A49)))
          : filteredProducts.isEmpty
          ? Center(
        child: Text(
          "No products found",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];

          final hasDiscount = product['discountPrice'] != null &&
              product['discountPrice'] != product['price'];
          final discount = hasDiscount
              ? calculateDiscountPercentage(
              product['price'], product['discountPrice'])
              : '';

          return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return ProductInfo(productId: product['id']);
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300), // optional
                  ),
                );
          },
          child: AnimatedContainer(

          duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(

                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: product['image'] != null
                                ? Image.network(
                              product['image'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFFFF4A49),
                                )),
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade300,
                                  size: 40,
                                ),
                              )
                                  : Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade300,
                              size: 40,
                            ),
                          ),
                        ),
                        if (hasDiscount)
                          Positioned(
                            top: 12,
                            left: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(20), // Oval shape
                              ),
                              child: Text(
                                '-$discount%', // Added minus sign and percentage
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12, // Smaller font
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleFavorite(product['id']),
                                child: _buildActionButton(
                                  favoriteProductIds.contains(product['id'])
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          product['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product['description'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontFamily: 'Poppins',
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Price Section
                        Row(
                          children: [
                            if (product['discountPrice'] != null &&
                                product['discountPrice'] != product['price']) ...[
                              Text(
                                '\$${product['discountPrice']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF4A49),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${product['price']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  decoration: TextDecoration.lineThrough,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ] else
                              Text(
                                '\$${product['price']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF4A49),
                                  fontFamily: 'Poppins',
                                ),
                              ),

                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          );
        },
      ),
    );
  }
}