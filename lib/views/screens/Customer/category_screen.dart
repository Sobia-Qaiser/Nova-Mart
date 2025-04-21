import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../innerscreens/category_product.dart';
import 'home_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final DatabaseReference _categoriesRef =
  FirebaseDatabase.instance.ref().child('categories');
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void _fetchCategories() {
    _categoriesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((key, value) {
          tempList.add({
            'key': key.toString(),
            'name': value['category name'].toString(),
            'image': value['image'].toString(),
          });
        });
        setState(() {
          categories = tempList;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
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
          onPressed: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return const HomeScreen(initialIndex: 0);
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85, // Optimized aspect ratio
      ),
      itemCount: _isLoading ? 4 : categories.length,
      itemBuilder: (context, index) {
        return _isLoading
            ? _buildSkeletonCard()
            : _buildCategoryCard(categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return CategoryProductScreen(
                categoryKey: category['key'],
                categoryName: category['name'],
              );
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );

      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              Image.network(
                category['image'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[100],
                  child: const Center(child: Icon(Icons.photo, color: Colors.grey)),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5)
                      ],
                    ),
                  ),
                ),
              ),

              // Category Name Text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    category['name'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      shadows: [
                        Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(1, 1))
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16)),
    );
  }
}