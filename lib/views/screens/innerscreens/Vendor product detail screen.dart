import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool hasVariations = product['productType'] == 'Product Variants';
    final List<dynamic> variations = hasVariations ? product['variations'] ?? [] : [];
    final List<String> imageUrls = List<String>.from(product['imageUrls'] ?? []);
    String category = '';

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
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
    body: Container(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            _buildImageGallery(imageUrls, isDarkMode),
            const SizedBox(height: 20),

            // Basic Info
            Text(
              product['productName'] ?? 'No Name',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Category: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: product['category'] ?? 'No Category',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 1),

            // Price Information - Kept in original position below category
            _buildPriceSection(product, isDarkMode),
            const SizedBox(height: 10),

            // Description
            _buildDescriptionSection(product, isDarkMode),
            const SizedBox(height: 10),

            // Stock Information
            _buildStockInfoSection(product, isDarkMode),
            const SizedBox(height: 20),

            // Variations (if applicable)
            if (hasVariations) ...[
              _buildVariationsSection(variations, isDarkMode),
              const SizedBox(height: 20),
            ],

            // Shipping & Tax
            _buildShippingTaxSection(product, isDarkMode),
          ],
        ),
      ),
    ));
  }

  Widget _buildImageGallery(List<String> imageUrls, bool isDarkMode) {
    int selectedImageIndex = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            // Main Image
            Hero(
              tag: 'product-image-${product['productId']}',
              child: Container(
                width: double.infinity,
                height: 320,
                margin: EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20), // All corners rounded
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Same radius as container
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
                        child: _buildThumbnailList(
                            imageUrls,
                            selectedImageIndex,
                                (index) => setState(() => selectedImageIndex = index)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThumbnailList(List<String> imageUrls, int selectedIndex, Function(int) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          height: 50,
          margin: EdgeInsets.symmetric(vertical: 1),
          child: Center(
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onSelect(index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedIndex == index
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
                        height: 50,
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
                                value: loadingProgress.expectedTotalBytes != null
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

  Widget _buildPriceSection(Map<String, dynamic> product, bool isDarkMode) {
    final hasDiscount = product['discountPrice'] != null &&
        product['discountPrice'] > 0 &&
        product['discountPrice'] < product['price'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (hasDiscount) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Price: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.grey[800],
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: 'PKR ${product['discountPrice']?.toStringAsFixed(2)}  ',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFF4A49),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'PKR ${product['price']?.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        ] else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Price: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.grey[800],
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: 'PKR ${product['price']?.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFF4A49),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> product, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          product['description'] ?? 'No description available',
          style: TextStyle(
            fontSize: 15,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfoSection(Map<String, dynamic> product, bool isDarkMode) {
    final bool hasVariations = product['productType'] == 'Product Variants';
    final totalStock = hasVariations
        ? (product['variations'] as List).fold<int>(
        0, (sum, variation) => sum + (variation['quantity'] as int))
        : product['quantity'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoCard(
              title: 'Total Stock',
              value: totalStock.toString(),
              icon: Icons.inventory,
              isDarkMode: isDarkMode,
              iconColor: Color(0xFFFF4A49),
            ),
            const SizedBox(width: 12),
            _buildInfoCard(
              title: 'Status',
              value: totalStock == 0
                  ? 'Out of Stock'
                  : totalStock < 10
                  ? 'Low Stock'
                  : 'In Stock',
              icon: totalStock == 0
                  ? Icons.cancel
                  : totalStock < 10
                  ? Icons.warning
                  : Icons.check_circle,
              isDarkMode: isDarkMode,
              valueColor: totalStock == 0
                  ? Colors.red
                  : totalStock < 10
                  ? Colors.orange
                  : Colors.green,
              iconColor: Color(0xFFFF4A49),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDarkMode,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor ?? Color(0xFFFF4A49)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationsSection(List<dynamic> variations, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Variations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : const Color(0xFFF0F0F0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Size',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF333333),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Color',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF333333),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Stock',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Rows
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: variations.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  itemBuilder: (context, index) {
                    final variation = variations[index];
                    return Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                        child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                    children: [
                    Expanded(
                    flex: 2,
                    child: Text(
                    variation['size']?.toString() ?? '---',
                    style: TextStyle(
                    color: isDarkMode ? Colors.white70 : const Color(0xFF555555),
                    ),
                    )),
                    Expanded(
                    flex: 2,
                    child: Text(
                    variation['color']?.toString() ?? '---',
                    style: TextStyle(
                    color: isDarkMode ? Colors.white70 : const Color(0xFF555555),
                    ),
                    )),
                    Expanded(
                    flex: 1,
                    child: Text(
                    variation['quantity']?.toString() ?? '0',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : const Color(0xFF555555),
                    ),
                    ),
                    ),
                    ],
                    ),
                    ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildShippingTaxSection(Map<String, dynamic> product, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping & Tax',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoCard(
              title: 'Shipping',
              value: 'PKR ${product['shippingCharges']?.toStringAsFixed(2) ?? '0.00'}',
              icon: Icons.local_shipping,
              isDarkMode: isDarkMode,
              iconColor: Color(0xFFFF4A49),
            ),
            const SizedBox(width: 12),
            _buildInfoCard(
              title: 'Tax',
              value: '${product['taxPercent']?.toStringAsFixed(1) ?? '0'}%',
              icon: Icons.receipt,
              isDarkMode: isDarkMode,
              iconColor: Color(0xFFFF4A49),
            ),
          ],
        ),
      ],
    );
  }
}