import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../Admin/sidebar_screen/widget/quntity.dart';
import '../chatscreen.dart';

class ProductInfo extends StatefulWidget {
  final String productId;
  const ProductInfo({super.key, required this.productId});


  @override
  State<ProductInfo> createState() => _ProductInfoState();
}

class _ProductInfoState extends State<ProductInfo> {
  List<String> imageUrls = [];
  int selectedImageIndex = 0;
  bool isLoading = true;
  String category = '';
  String productName = '';
  String price = '';
  String discountPrice = '';
  String productDescription = '';
  List<String> sizes = [];
  String? selectedSize;
  List<String> colors = [];
  String? selectedColor;
  String _businessName = 'Loading...';
  String _address = 'Loading...';
  String? productType;
  List<dynamic> variations = [];
  List<String> availableColorsForSize = [];
  String quantity = '0'; // For simple products
  String stockStatus = 'In Stock';
  Color stockStatusColor = Colors.green;
  Set<String> favoriteProductIds = {};
  final DatabaseReference _favoritesRef = FirebaseDatabase.instance.ref('favourites');
  String vendorId = '';
  int selectedQuantity = 1;
  int currentStock = 0;
  String shippingCharges = '0';
  String taxAmount = '0';


  @override
  void initState() {
    super.initState();
    _loadProductImages();
    _loadProductCategory();
    _checkProductType();
    _loadFavorites();
  }
  // Update _filterColors method
  void _filterColors(String selectedSize) {
    Set<String> colorSet = variations
        .where((v) {
      // Handle products without sizes
      if (sizes.isEmpty) return v['color'] != null;

      // Handle products with sizes
      return v['size']?.toString().toLowerCase() == selectedSize.toLowerCase() &&
          v['color'] != null;
    })
        .map((v) => v['color'].toString())
        .toSet();



    setState(() {
      colors = colorSet.toList();
      selectedColor = colors.isNotEmpty ? colors.first : null;
    });
  }

  void _updateStockStatus() {
    int currentQty = _calculateCurrentQuantity();
    setState(() {
      currentStock = currentQty;

      if (selectedQuantity > currentStock) {
        selectedQuantity = currentStock > 0 ? 1 : 0;
      }

      if (currentQty == 0) {
        stockStatus = 'Out of Stock';
        stockStatusColor = Colors.red;
      } else if (currentQty <= 10) {
        stockStatus = 'Limited Stock';
        stockStatusColor = Colors.orange;
      } else {
        stockStatus = 'In Stock';
        stockStatusColor = Colors.green;
      }

      if (selectedQuantity > currentStock) {
        selectedQuantity = currentStock > 0 ? 1 : 0;
      }
    });
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar("Error", "Please login to add to cart");
      return;
    }

    if (vendorId.isEmpty) {
      Get.snackbar("Error", "Vendor information missing");
      return;
    }

    if (selectedQuantity > currentStock) {
      Get.snackbar("Error", "Insufficient stock");
      return;
    }

    // 🔴 Change 1: Cart Item को Lowercase में Save करें
    final cartItem = {
      'productId': widget.productId,
      'vendorId': vendorId,
      'productName': productName,
      'price': price,
      'discountPrice': discountPrice,
      'quantity': selectedQuantity,
      'productType': productType,
      'size': selectedSize?.toString().toLowerCase(), // Lowercase
      'color': selectedColor?.toString().toLowerCase(), // Lowercase
      'imageUrl': imageUrls.isNotEmpty ? imageUrls[0] : '',
      'addedAt': ServerValue.timestamp,
      'shippingCharges': shippingCharges,
      'taxAmount': taxAmount,
    };

    try {
      final cartRef = FirebaseDatabase.instance.ref('carts').child(user.uid);
      final snapshot = await cartRef.get();

      String? existingKey;
      if (snapshot.exists) {
        final cartItems = Map<String, dynamic>.from(snapshot.value as Map);
        cartItems.forEach((key, value) {
          final item = Map<String, dynamic>.from(value);
          // 🔴 Change 2: Case-Insensitive Comparison
          final itemSize = item['size']?.toString().toLowerCase();
          final selectedSizeLower = selectedSize?.toString().toLowerCase();
          final itemColor = item['color']?.toString().toLowerCase();
          final selectedColorLower = selectedColor?.toString().toLowerCase();

          if (item['productId'] == widget.productId &&
              itemSize == selectedSizeLower &&
              itemColor == selectedColorLower) {
            existingKey = key;
          }
        });
      }

      if (existingKey != null) {
        await cartRef.child(existingKey!).update({
          'quantity': ServerValue.increment(selectedQuantity),
        });
      } else {
        await cartRef.push().set(cartItem);
      }

      Get.snackbar(
        "Success",
        "Added to cart!",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
        shouldIconPulse: false,
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
        margin: const EdgeInsets.all(10),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to add to cart: ${e.toString()}");
    }
  }

// ✅ _calculateCurrentQuantity में कोई बदलाव नहीं (पहले से Lowercase है)
  int _calculateCurrentQuantity() {
    if (productType != 'Product Variants') {
      return int.tryParse(quantity) ?? 0;
    }

    int total = 0;
    for (var variant in variations) {
      bool sizeMatch = selectedSize == null ||
          (variant['size']?.toString().toLowerCase() == selectedSize!.toLowerCase());

      bool colorMatch = selectedColor == null ||
          (variant['color']?.toString().toLowerCase() == selectedColor!.toLowerCase());

      if (sizeMatch && colorMatch) {
        total += int.tryParse(variant['quantity']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }


  Future<void> _checkProductType() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child('products')
        .child(widget.productId);
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      setState(() {
        productType = snapshot.child('productType').value.toString();
        _updateStockStatus();
      });
    }
  }

  Future<void> _loadProductCategory() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('products')
          .child(widget.productId);
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          setState(() {
            category = data['category'] ?? 'Uncategorized';
          });
        }
      }
    } catch (error) {
      print('Error loading category: $error');
    }
  }


  Future<void> _loadProductImages() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('products')
          .child(widget.productId);
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          setState(() {
            vendorId = data['vendorId'] ?? '';
            _businessName = data['businessName'] ?? 'Business Name N/A';
            _address = data['vendorAddress'] ?? 'Address N/A';
            // Load all product data
            shippingCharges = data['shippingCharges']?.toString() ?? '0'; // Add this line
            taxAmount = data['taxAmount']?.toString() ?? '0'; // Add this line
            productName = data['productName'] ?? 'Unnamed Product';
            price = data['price']?.toString() ?? '0';
            discountPrice = data['discountPrice']?.toString() ?? '';
            productDescription =
                data['description'] ?? 'No description available';
            variations = (data['variations'] as List<dynamic>?)?.whereType<Map<dynamic, dynamic>>().toList() ?? [];

            // Extract unique sizes
            Set<String> sizeSet = variations
                .where((v) => v['size'] != null)
                .map((v) => v['size'].toString().toLowerCase())
                .toSet();

            sizes = sizeSet.toList();
            if (sizes.isEmpty) {
              // Get all unique colors from variations
              Set<String> colorSet = variations
                  .where((v) => v['color'] != null)
                  .map((v) => v['color'].toString())
                  .toSet();

              colors = colorSet.toList();
              selectedColor = colors.isNotEmpty ? colors.first : null;
            } else {
              // Existing logic for sizes
              selectedSize = sizes.first;
              _filterColors(sizes.first);
            }

            // Quantiy check
            productType = data['productType']?.toString() ?? '';
            if (productType != 'Product Variants') {
              quantity = data['quantity']?.toString() ?? '0';
            }

            // Existing image loading logic
            if (data.containsKey('imageUrls')) {
              dynamic imageUrlsData = data['imageUrls'];
              List<String> imagesList = [];

              if (imageUrlsData is Map) {
                List<String> sortedKeys = imageUrlsData.keys.cast<String>()
                    .toList()
                  ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                imagesList =
                    sortedKeys.map((key) => imageUrlsData[key] as String)
                        .toList();

              } else if (imageUrlsData is List) {
                imagesList = imageUrlsData.cast<String>().toList();
              }
              imageUrls = imagesList;
            }
            isLoading = false;
            // Set initial selections
            if (sizes.isNotEmpty) {
              selectedSize = sizes.first;
              _filterColors(sizes.first);
            }
            _updateStockStatus();
          });
        }
      }
    } catch (error) {
      print('Error loading product data: $error');
      setState(() => isLoading = false);
    }
  }

  void _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _favoritesRef.child(user.uid).get();
    setState(() {
      if (snapshot.exists) {
        final favoritesMap = Map<String, dynamic>.from(snapshot.value as Map);
        favoriteProductIds = Set<String>.from(favoritesMap.keys);
      } else {
        favoriteProductIds = Set<String>();
      }
    });
  }

  void _toggleFavorite(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar("Error", "Please login to add favorites");
      return;
    }

    try {
      setState(() {
        if (favoriteProductIds.contains(productId)) {
          favoriteProductIds.remove(productId);
        } else {
          favoriteProductIds.add(productId);
        }
      });

      await _favoritesRef.child(user.uid).child(productId)
          .set(favoriteProductIds.contains(productId) ? true : null);

    } catch (e) {
      Get.snackbar("Error", e.toString());
      // Revert on error
      setState(() {
        favoriteProductIds.contains(productId)
            ? favoriteProductIds.remove(productId)
            : favoriteProductIds.add(productId);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          category.isNotEmpty ? category : 'Product Detail',
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainImage(isDarkMode),
              _buildProductDetails(textColor),
              _buildPriceWithQuantity(textColor),
              _buildProductDescription(textColor),
              if (productType == 'Product Variants') ...[
                if (sizes.isNotEmpty) _buildSizeSelector(textColor, isDarkMode),
                if (colors.isNotEmpty && (sizes.isEmpty || selectedSize != null)) // Updated condition
                  _buildColorSelector(textColor, isDarkMode),
              ],
              _buildVendorInfo(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Color(0xFF1E1E1E)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Wishlist Icon
            Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
        child: IconButton(
          icon: Icon(
            favoriteProductIds.contains(widget.productId) ? Icons.favorite : Icons.favorite_border, // Corrected condition
            size: 28,
            color: Color(0xFFFF4A49),
          ),
          onPressed: () => _toggleFavorite(widget.productId), // Call correct method
        ),
      ),

            // Add to Cart Button
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: Material(
                    color: stockStatus == "Out of Stock"
                        ? Colors.grey[300]
                        : Color(0xFFFF4A49),
                    borderRadius: BorderRadius.circular(8),
                    child: MaterialButton(
                      height: 45,
                      highlightElevation: 4, // Pressed state elevation (shadow)
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.transparent,
                        ),
                      ),
                      onPressed: (stockStatus == "Out of Stock") ? null : _addToCart,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: stockStatus == "Out of Stock"
                                ? Colors.black87
                                : Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Add to Cart",
                            style: TextStyle(
                              color: stockStatus == "Out of Stock"
                                  ? Colors.black87
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),



          ],
        ),
      ),
    );

  }

  Widget _buildMainImage(bool isDarkMode) {
    return Hero(
      tag: 'product-image-${widget.productId}',
      child: Container(
        width: double.infinity,
        height: 320,
        margin: EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
          child: Stack(
            children: [
              // Main Image
              if (imageUrls.isNotEmpty)
                Image.network(
                  imageUrls[selectedImageIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                )
              else
                Center(child: Icon(Icons.image_not_supported, size: 100)),

              // Thumbnails Positioned at bottom
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: _buildThumbnailList(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildThumbnailList() {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          height: 50, // Thora chhota size
          margin: EdgeInsets.symmetric(vertical: 1),
          child: Center(
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedImageIndex = index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedImageIndex == index
                            ? Color(0xFFFF4A49)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrls[index],
                        width: 50,
                        // Smaller thumbnail
                        height: 50,
                        // Smaller thumbnail
                        fit: BoxFit.cover,
                        cacheWidth: 100,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                    null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetails(Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 9, right: 9, top: 20, bottom: 0),
      child: Row(
        children: [
          // Product Title (left)
          Expanded(
            child: Text(
              productName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPriceWithQuantity(Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price Display (existing code)
              Row(
                children: [
                  if (discountPrice.isNotEmpty)
                    Text(
                      'PKR $discountPrice',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  if (discountPrice.isNotEmpty) const SizedBox(width: 6),
                  Text(
                    'PKR $price',
                    style: TextStyle(
                      fontSize: discountPrice.isNotEmpty ? 12 : 16,
                      color: discountPrice.isNotEmpty
                          ? textColor.withOpacity(0.5)
                          : const Color(0xFF1976D2),
                      decoration: discountPrice.isNotEmpty
                          ? TextDecoration.lineThrough
                          : null,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Updated QuantitySelector
              QuantitySelector(
                quantity: selectedQuantity,
                maxQuantity: currentStock,
                onIncrease: () {
                  if (selectedQuantity < currentStock) {
                    setState(() => selectedQuantity++);
                  }
                },
                onDecrease: () {
                  if (selectedQuantity > 1) {
                    setState(() => selectedQuantity--);
                  }
                },
              ),
            ],
          ),
          // Stock Status (existing code)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              stockStatus,
              style: TextStyle(
                color: stockStatusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDescription(Color textColor) {
    final bool isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.8),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            productDescription,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? Colors.grey[400] // Light gray for dark mode
                  : Colors.grey[600], // Dark gray for light mode
              fontFamily: 'Poppins',
              height: 1.4, // Line height
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 17, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sizes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.8),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              final isSelected = size == selectedSize;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: () {
                    setState(() => selectedSize = size);
                    _filterColors(size);
                    _updateStockStatus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // Always transparent background
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(
                            0xFFFF4A49) // Red border when selected
                            : Colors.grey.shade300,
                        // Grey border when unselected
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      size,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        // Same color for selected/unselected
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 17, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Colors',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.8),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((colorName) {
              final isSelected = colorName == selectedColor;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                    onTap: () {
                      setState(() => selectedColor = colorName);
                      _updateStockStatus(); // Add this
                    },

                    child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // Always transparent background
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(
                            0xFFFF4A49) // Red border when selected
                            : Colors.grey.shade300,
                        // Grey border when unselected
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      colorName,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        // Same color for selected/unselected
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo(BuildContext context) {
    final bool isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    final Color primaryColor = Color(0xFFFF4A49);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 25, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 "Sold by" heading on top
          Text(
            'Sold by',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.8),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 🏪 Store Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store,
                  size: 30,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              // 📝 Vendor name and address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _businessName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _address,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // 💬 Chat Icon
              IconButton(
                icon: Icon(
                  Icons.message,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 28,
                ),
                onPressed: () {
                  print('Message button pressed');

                  final currentUser = FirebaseAuth.instance.currentUser;
                  final customerId = currentUser?.uid;
                  final vendorId = this.vendorId; // Use state's vendorId

                  print('Customer ID: $customerId');
                  print('Vendor ID: $vendorId');

                  if (customerId != null && vendorId.isNotEmpty && customerId != vendorId) {
                    final chatId = customerId.hashCode <= vendorId.hashCode
                        ? '${customerId}_$vendorId'
                        : '${vendorId}_$customerId';

                    print('Chat ID: $chatId');

                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
                          chatId: chatId,
                          senderId: customerId,
                          receiverId: vendorId,
                        ), // Replace with your chat screen
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );

                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to start chat.')),
                    );
                  }
                },
              )
            ],
          ),
        ],
      ),
    );


  }

}

