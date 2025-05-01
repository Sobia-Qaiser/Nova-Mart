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

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Product Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            _buildImageGallery(imageUrls),
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
            Text(
              product['category'] ?? 'No Category',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Price Information
            _buildPriceSection(product, isDarkMode),
            const SizedBox(height: 20),

            // Description
            _buildDescriptionSection(product, isDarkMode),
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),

            // Vendor Info
            _buildVendorInfoSection(product, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    return SizedBox(
      height: 300,
      child: imageUrls.isEmpty
          ? Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 60, color: Colors.grey),
        ),
      )
          : PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[200]),
              ),
            ),
          );
        },
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
        Text(
          'Price',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        if (hasDiscount) ...[
          Text(
            'PKR ${product['discountPrice']?.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF4A49),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PKR ${product['price']?.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
        ] else
          Text(
            'PKR ${product['price']?.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF4A49),
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
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
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
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
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
                Icon(icon, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: variations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final variation = variations[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (variation['size'] != null && variation['size'].toString().isNotEmpty)
                        Text(
                          'Size: ${variation['size']}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      if (variation['color'] != null && variation['color'].toString().isNotEmpty)
                        Text(
                          'Color: ${variation['color']}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Qty: ${variation['quantity']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          },
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
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
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
            ),
            const SizedBox(width: 12),
            _buildInfoCard(
              title: 'Tax',
              value: '${product['taxPercent']?.toStringAsFixed(1) ?? '0'}%',
              icon: Icons.receipt,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorInfoSection(Map<String, dynamic> product, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendor Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF4A49).withOpacity(0.2),
                  child: const Icon(Icons.store, color: Color(0xFFFF4A49)),
                ),
                title: Text(
                  product['businessName'] ?? 'No Business Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  product['vendorAddress'] ?? 'No Address',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}