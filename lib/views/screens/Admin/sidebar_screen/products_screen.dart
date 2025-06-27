import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('products');
  final List<Map<String, dynamic>> _productList = [];
  final List<Map<String, dynamic>> _displayedProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _productsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is int) {
      return DateFormat('dd MMM yyyy').format(
          DateTime.fromMillisecondsSinceEpoch(timestamp));
    }
    if (timestamp is String) {
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(timestamp));
      } catch (e) {
        return timestamp;
      }
    }
    return "N/A";
  }

  int _calculateTotalQuantity(dynamic variations) {
    if (variations == null) return 0;

    // Handle flat variation structure
    if (variations is Map && variations.containsKey('quantity')) {
      dynamic quantity = variations['quantity'];
      if (quantity is int) return quantity;
      if (quantity is String) return int.tryParse(quantity) ?? 0;
      return 0;
    }

    // Handle list of variations
    if (variations is List) {
      return variations.fold(0, (sum, item) {
        dynamic quantity = item['quantity'];
        if (quantity is int) return sum + quantity;
        if (quantity is String) return sum + (int.tryParse(quantity) ?? 0);
        return sum;
      });
    }
    // Handle map of variations
    else if (variations is Map) {
      return variations.values.fold(0, (sum, item) {
        if (item is Map) {
          dynamic quantity = item['quantity'];
          if (quantity is int) return sum + quantity;
          if (quantity is String) return sum + (int.tryParse(quantity) ?? 0);
        }
        return sum;
      });
    }
    return 0;
  }

  String? _getFirstImageUrl(dynamic imageUrls) {
    if (imageUrls == null) return null;

    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls[0].toString();
    } else if (imageUrls is Map && imageUrls.isNotEmpty) {
      return imageUrls.values.first.toString();
    }
    return null;
  }

  String _parsePriceDisplay(dynamic price) {
    if (price == null) return "---";

    double? parsed;

    if (price is num) {
      parsed = price.toDouble();
    } else if (price is String) {
      parsed = double.tryParse(price);
    }

    if (parsed == null || parsed == 0) return "---";

    // Check if number is whole (no decimal value)
    if (parsed == parsed.roundToDouble()) {
      return parsed.toInt().toString(); // Return without .00
    }

    return parsed.toStringAsFixed(2); // Keep .xx if needed
  }


  void _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final databaseEvent = await _database.once();
      final data = databaseEvent.snapshot.value;

      _productList.clear();
      if (data != null && data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            String? imageUrl = _getFirstImageUrl(value["imageUrls"]);
            String productType = value["productType"] ?? "Simple Product";

            // Handle stock based on product type
            String stock;
            if (productType == "Simple Product") {
              dynamic quantity = value["quantity"];
              if (quantity is int) {
                stock = quantity.toString();
              } else if (quantity is String) {
                stock = (int.tryParse(quantity) ?? 0).toString();
              } else {
                stock = "0";
              }
            } else {
              dynamic variations = value["variations"];
              int totalQuantity = _calculateTotalQuantity(variations);
              stock = totalQuantity.toString();
            }

            final productData = {
              "productId": key,
              "imageUrl": imageUrl,
              "productName": value["productName"]?.toString() ?? "No Name",
              "category": value["category"]?.toString() ?? "---",
              "price": _parsePriceDisplay(value["price"]),
              "discountPrice": _parsePriceDisplay(value["discountPrice"]),
              "businessName": value["businessName"]?.toString() ?? "---",
              "productType": productType,
              "stock": stock,
              "createdAt": _formatDate(value["dateTime"] ?? value["createdAt"]),
            };

            _productList.add(productData);
          }
        });

        _productList.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
        _updateDisplayedProducts();
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Failed to load products: ${error.toString()}";
      });
      Get.snackbar(
        "Error",
        _errorMessage!,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateDisplayedProducts() {
    final startIndex = (_currentPage - 1) * _productsPerPage;
    final endIndex = startIndex + _productsPerPage;

    setState(() {
      _displayedProducts.clear();
      if (startIndex < _productList.length) {
        _displayedProducts.addAll(
          _productList.sublist(
            startIndex,
            endIndex < _productList.length ? endIndex : _productList.length,
          ),
        );
      }
    });
  }

  void _nextPage() {
    if (_currentPage * _productsPerPage < _productList.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedProducts();
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateDisplayedProducts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF4A49),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF4A49)),
        ))
            : _errorMessage != null
      ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProducts,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4A49)),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    )
        : _productList.isEmpty
    ? Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    const Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey),
    const SizedBox(height: 16),
    Text(
    'No Products Found',
    style: TextStyle(
    fontSize: 18,
    fontFamily: 'Poppins',
    color: Colors.grey.shade600,
    ),
    ),
    const SizedBox(height: 16),
    ElevatedButton(
    onPressed: _fetchProducts,
    style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFF4A49)),
    child: const Text(
    'Refresh',
    style: TextStyle(color: Colors.white),
    ),
    ),
    ],
    ),
    )
        : Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.grey.shade100, Colors.grey.shade50],
    ),
    ),
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    children: [
    Expanded(
    child: Scrollbar(
    thumbVisibility: true,
    thickness: 8,
    radius: const Radius.circular(4),
    child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(
    decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(0.1),
    spreadRadius: 2,
    blurRadius: 8,
    offset: const Offset(0, 2)),
    ],
    ),
    child: DataTable(
    headingRowColor: MaterialStateProperty.resolveWith<Color>(
    (states) => Colors.pink.shade50),
    columnSpacing: 30,
    horizontalMargin: 20,
    columns: const [
    DataColumn(
    label: Text('Sr#',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Image',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Name',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Category',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Price',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Discount Price',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Stock',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Business',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Type',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    ],
    rows: _displayedProducts.asMap().entries.map((entry) {
    final index = entry.key;
    final product = entry.value;
    return DataRow(
    cells: [
    DataCell(Text('${index + 1 + ((_currentPage - 1) * _productsPerPage)}',
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(
    product['imageUrl'] != null
    ? Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(4),
    ),
    child: Image.network(
    product['imageUrl'],
    fit: BoxFit.cover,
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
    errorBuilder: (context, error, stackTrace) =>
    const Icon(Icons.error, size: 30),
    ),
    )
        : const Icon(Icons.image_not_supported, size: 30),
    ),
    DataCell(Text(product['productName'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(product['category'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(
    product['price'] == "---" ? "---" : '\$${product['price']}',
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(
    product['discountPrice'] == "---" ? "---" : '\$${product['discountPrice']}',
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(product['stock'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(product['businessName'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(product['productType'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    ],
    );
    }).toList(),
    ),
    ),
    ),
    ),
    ),
    ),
    const SizedBox(height: 16),
    Align(
    alignment: Alignment.centerRight,
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    IconButton(
    icon: const Icon(Icons.arrow_back_ios, size: 16),
    onPressed: _prevPage,
    color: _currentPage > 1 ? const Color(0xFFFF4A49) : Colors.grey,
    ),
    Text(
    'Page $_currentPage of ${(_productList.length / _productsPerPage).ceil()}',
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    ),
    ),
    IconButton(
    icon: const Icon(Icons.arrow_forward_ios, size: 16),
    onPressed: _nextPage,
    color: _currentPage * _productsPerPage < _productList.length
    ? const Color(0xFFFF4A49)
        : Colors.grey,
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }
}