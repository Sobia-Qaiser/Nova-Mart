import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/innerscreens/ProductInfo.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<String> popularKeywords = [];
  bool showKeywords = true;
  bool isLoading = false;
  bool hasSearched = false;
  final DatabaseReference _favoritesRef = FirebaseDatabase.instance.ref('favourites');
  Set<String> favoriteProductIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPopularKeywords();
    _loadFavorites();
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

  void _fetchPopularKeywords() async {
    final ref = FirebaseDatabase.instance.ref('categories');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        popularKeywords = data.values
            .map((category) => category['category name'].toString())
            .toList();
      });
    }
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        showKeywords = true;
        searchResults = [];
        hasSearched = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      showKeywords = false;
      hasSearched = true;
    });

    final ref = FirebaseDatabase.instance.ref('products');
    final snapshot = await ref.get();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    if (snapshot.exists) {
      final productsData = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> results = [];

      productsData.forEach((key, value) {
        final productName = value['productName']?.toString().toLowerCase() ?? '';
        final category = value['category']?.toString().toLowerCase() ?? '';
        final queryLower = query.toLowerCase();

        if (productName.contains(queryLower) || category.contains(queryLower)) {
          results.add({
            'key': key.toString(),
            'name': value['productName'],
            'price': value['price']?.toString() ?? '0',
            'discountPrice': value['discountPrice']?.toString(),
            'description': value['description'] ?? '',
            'image': (value['imageUrls'] != null && value['imageUrls'].isNotEmpty)
                ? value['imageUrls'][0]
                : null,
            'category': value['category'] ?? 'Uncategorized',
          });
        }
      });

      if (mounted) {
        setState(() {
          searchResults = results;
        });
      }
    }
  }

  String calculateDiscountPercentage(dynamic actualPrice, dynamic discountPrice) {
    double actual = double.tryParse(actualPrice.toString()) ?? 0;
    double discount = double.tryParse(discountPrice.toString()) ?? 0;
    if (actual <= discount || actual == 0) return "0%";
    return "${((actual - discount) / actual * 100).round()}%";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF4A49)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
          Expanded(
                child: TextField(
                  cursorColor: isDarkMode ? Colors.black : Colors.black,
                  controller: _searchController,
                  style: TextStyle(  // Add this
                    color: isDarkMode ? Colors.black : Colors.black,  // Text color when typing
                  ),
                  decoration: InputDecoration(
                    hintText: 'Searching....',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: InputBorder.none,
                  ),
                  onChanged: _performSearch,
                ),
              ),
              Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4A49),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    _performSearch(_searchController.text);
                  },
                  child: const Text(
                    "Search",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (showKeywords && _searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Popular Categories",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 0.2,
                    children: popularKeywords.map((keyword) {
                      return GestureDetector(
                        onTap: () {
                          _searchController.text = keyword;
                          _performSearch(keyword);
                        },
                        child: Chip(
                          label: Text(
                            keyword,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF4A49),
              ),
            )
                : hasSearched && searchResults.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No products found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Try different keywords",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final product = searchResults[index];
                final hasDiscount = product['discountPrice'] != null &&
                    product['discountPrice'].isNotEmpty &&
                    double.tryParse(product['price']) != null &&
                    double.tryParse(product['discountPrice']) != null &&
                    double.parse(product['discountPrice']) < double.parse(product['price']);
                final discount = hasDiscount
                    ? calculateDiscountPercentage(
                    product['price'], product['discountPrice'])
                    : '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductInfo(productId: product['key']),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  )
                                      : const Icon(Icons.image_not_supported),
                                ),
                              ),
                              if (hasDiscount)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '-$discount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _toggleFavorite(product['key']),
                                  child: _buildActionButton(
                                    favoriteProductIds.contains(product['key'])
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (hasDiscount) ...[
                                    Text(
                                      '\$${product['discountPrice']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF4A49),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\$${product['price']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      '\$${product['price']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF4A49),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}