import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Admin/sidebar_screen/widget/banner_widget_home.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/innerscreens/searchscreen.dart';
import '../../../controllers/auth_controller.dart';
import '../Seller/customerchatlist.dart';
import '../innerscreens/ProductInfo.dart';
import '../innerscreens/category_product.dart';
import 'cart_screen.dart';

class ShopHome extends StatefulWidget {
  const ShopHome({super.key});

  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  String userName = "Guest";
  final AuthController _authController = AuthController();
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _categoriesRef = FirebaseDatabase.instance.ref('categories');
  final DatabaseReference _favoritesRef = FirebaseDatabase.instance.ref('favourites');
  final String customerId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> latestProducts = [];
  List<Map<String, dynamic>> allProducts = [];//new
  Set<String> favoriteProductIds = {};
  Set<String> cartProductIds = {};
  int cartItemCount = 0;
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref('carts');
  late User? _currentUser;
  bool isSearching = false;
  int totalUnreadCount = 0;



  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadCartCount();
    getUserName();
    _fetchCategories();
    _fetchLatestProducts();
    _loadFavorites(); // Add this line
    _setupChatListener();
  }

  void getUserName() async {
    String? name = await _authController.getCurrentCustomerName();
    if (name != null) {
      setState(() {
        userName = name;
      });
    }
  }

  void _loadCartCount() {
    _cartRef.child(_currentUser?.uid ?? '').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final totalItems = data.values.fold<int>(0, (sum, item) {
          return sum + (item['quantity'] as int? ?? 1);
        });
        setState(() => cartItemCount = totalItems);
      } else {
        setState(() => cartItemCount = 0);
      }
    });
  }

  void _setupChatListener() {
    FirebaseDatabase.instance.ref('chats').onValue.listen((event) {
      if (event.snapshot.exists) {
        int total = 0;
        final chats = event.snapshot.value as Map<dynamic, dynamic>;

        chats.forEach((chatId, messages) {
          if (messages is Map) {
            messages.forEach((messageId, message) {
              if (message is Map &&
                  message['receiverId'] == customerId &&
                  (message['isSeen'] == null || message['isSeen'] == false)) {
                total++;
              }
            });
          }
        });

        if (mounted) {
          setState(() {
            totalUnreadCount = total;
          });
        }
      }
    });
  }

  void _fetchLatestProducts() async {
    final ref = FirebaseDatabase.instance.ref('products');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final productsData = snapshot.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> tempList = productsData.entries.map((entry) {
        final data = entry.value as Map;
        return {
          'key': entry.key.toString(),
          'name': data['productName'] ?? 'Unnamed Product',
          'price': data['price']?.toString() ?? '0',
          'discountPrice': data['discountPrice']?.toString(),
          'description': data['description'] ?? '',
          'image': (data['imageUrls'] != null && data['imageUrls'].isNotEmpty)
              ? data['imageUrls'][0]
              : null,
          'dateTime': data['dateTime'] ?? DateTime.now().toString(),
          'category': data['category'] ?? 'Uncategorized',
        };
      }).toList();

      // Sort by dateTime descending
      tempList.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['dateTime']);
          final dateB = DateTime.parse(b['dateTime']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        allProducts = tempList;
        latestProducts = tempList.take(6).toList(); // Always keep only 6 latest products
      });
    }
  }

  String calculateDiscountPercentage(dynamic actualPrice, dynamic discountPrice) {
    double actual = double.tryParse(actualPrice.toString()) ?? 0;
    double discount = double.tryParse(discountPrice.toString()) ?? 0;
    if (actual <= discount || actual == 0) return "0%";
    return "${((actual - discount) / actual * 100).round()}%";
  }
//s
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

  void _fetchCategories() async {
    Map<String, int> categoryCounts = {};
    final productsSnapshot = await FirebaseDatabase.instance.ref('products').get();

    if (productsSnapshot.exists) {
      final productsData = productsSnapshot.value as Map<dynamic, dynamic>;
      productsData.forEach((productKey, productValue) {
        String category = productValue['category']?.toString() ?? 'Unknown';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      });

      final categoriesSnapshot = await _categoriesRef.get();
      if (categoriesSnapshot.exists) {
        final categoriesData = categoriesSnapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempList = [];

        categoriesData.forEach((key, categoryValue) {
          final categoryName = categoryValue['category name']?.toString() ?? 'Unknown';
          final image = categoryValue['image']?.toString() ?? '';
          int productCount = categoryCounts[categoryName] ?? 0;

          if (productCount > 0) {
            tempList.add({
              'key': key.toString(),
              'name': categoryName,
              'image': image,
              'count': productCount,
            });
          }
        });

        tempList.sort((a, b) => b['count'].compareTo(a['count']));
        setState(() {
          categories = tempList.take(6).toList();
        });
      }
    }
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
      resizeToAvoidBottomInset: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Color(0xFFFF4A49) : Color(0xFFFF4A49),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hi, $userName! 👋",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            Row(
              children: [
                // Chat Icon with unread count
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      splashColor: Colors.transparent, // Removes ripple
                      highlightColor: Colors.transparent, // Removes tap highlight
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                CustomerChatListScreen(customerId: customerId),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                        setState(() {
                          totalUnreadCount = result ?? totalUnreadCount;
                        });
                      },
                      icon: Transform.translate(
                        offset: Offset(20, 0),
                        child: Icon(Icons.chat, color: Colors.white, size: 20),
                      ),
                    ),


                    if (totalUnreadCount > 0)
                      Positioned(
                        top: 2,
                        right: -16, // Changed from 28 to 4 to position it above the icon
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            totalUnreadCount > 9 ? '9+' : totalUnreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),

                // Existing Cart Icon with counter
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const CartScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 300),
                          ),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    if (cartItemCount > 0)
                      Positioned(
                        top: 5,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartItemCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const SearchScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child); // Example transition
                        },
                        transitionDuration: const Duration(milliseconds: 300), // Optional: You can adjust the transition duration
                      ),
                    );


                  },
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          Icons.search,
                          size: 22,
                          color: isDarkMode ? Colors.white70 : const Color(0xFFFF4A49),
                        ),
                      ),
                      Text(
                        "Search for products",
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              const BannerWidget(),

              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Text(
                  'Top Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),

              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return CategoryProductScreen(
                                categoryKey: categories[index]['key'],
                                categoryName: categories[index]['name'],
                              );
                            },
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.pink.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(categories[index]['image']),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  if (!isDarkMode)
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              categories[index]['name'],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 13, bottom: 8),
                child: Text(
                  'Latest Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 6,
                  left: 4,
                  right: 4,
                  bottom: 6,
                ),

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: latestProducts.length,
                itemBuilder: (context, index) {
                  final product = latestProducts[index];
                  final hasDiscount = product['discountPrice'] != null &&
                      product['discountPrice'].isNotEmpty &&
                      double.tryParse(product['price']) != null &&
                      double.tryParse(product['discountPrice']) != null &&
                      double.parse(product['discountPrice']) < double.parse(product['price']);
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
                          return ProductInfo(productId: product['key']);
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
                                        color: Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '-$discount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
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
                                        onTap: () => _toggleFavorite(product['key']),
                                        child: _buildActionButton(
                                          favoriteProductIds.contains(product['key'])
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
                                if ((product['description'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    product['description'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'Poppins',
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (hasDiscount) ...[
                                      Text(
                                        'PKR ${product['discountPrice']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF4A49),
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'PKR ${product['price']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          decoration: TextDecoration.lineThrough,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'PKR ${product['price']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF4A49),
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
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
          if (!isSearching) ...[
    Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
    'Explore All Products',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    color: Theme.of(context).textTheme.titleLarge?.color,
    ),
    ),
    ),
    GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.only(
    top: 6,
    left: 4,
    right: 4,
    bottom: 16, // Extra padding at bottom
    ),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    ),
    itemCount: allProducts.length,
    itemBuilder: (context, index) {
    final product = allProducts[index];
    final hasDiscount = product['discountPrice'] != null &&
    product['discountPrice'].isNotEmpty &&
    double.tryParse(product['price']) != null &&
    double.tryParse(product['discountPrice']) != null &&
    double.parse(product['discountPrice']) < double.parse(product['price']);
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
    return ProductInfo(productId: product['key']);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
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
    color: Color(0xFF2E7D32),
    borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
    '-$discount',
    style: const TextStyle(
    color: Colors.white,
    fontSize: 12,
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
    onTap: () => _toggleFavorite(product['key']),
    child: _buildActionButton(
    favoriteProductIds.contains(product['key'])
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
    if ((product['description'] ?? '').isNotEmpty) ...[
    const SizedBox(height: 2),
    Text(
    product['description'],
    style: TextStyle(
    fontSize: 13,
    color: Colors.grey.shade600,
    fontFamily: 'Poppins',
    height: 1.1,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    ),
    ],
    const SizedBox(height: 4),
    Row(
    children: [
    if (hasDiscount) ...[
    Text(
    'PKR ${product['discountPrice']}',
    style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFFFF4A49),
    fontFamily: 'Poppins',
    ),
    ),
    const SizedBox(width: 8),
    Text(
    'PKR ${product['price']}',
    style: TextStyle(
    fontSize: 12,
    color: Colors.grey.shade600,
    decoration: TextDecoration.lineThrough,
    fontFamily: 'Poppins',
    ),
    ),
    ] else ...[
    Text(
    'PKR ${product['price']}',
    style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFFFF4A49),
    fontFamily: 'Poppins',
    ),
    ),
    ],
    ],
    )
    ],
    ),
    ),
    ],
    ),
    ),
    ),
    );
    },
    ),
    ],
            ],
          ),
        ),
      ),
    );
  }
}