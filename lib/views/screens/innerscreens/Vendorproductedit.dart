import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/provider/product_provider.dart';
import 'package:provider/provider.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final ProductProvider _provider;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  List<Map<String, dynamic>> _variations = [];
  List<TextEditingController> _variationStockControllers = [];

  // Design constants matching UploadScreen
  final Color _primaryColor = const Color(0xFFFF4A49);
  final Color _secondaryColor = Colors.grey.shade800;
  final Color _borderColor = Colors.grey.shade300;
  final double _borderRadius = 12.0;
  final double _inputPadding = 16.0;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ProductProvider>();
    _initializeData();
  }

  void _initializeData() {
    _priceController.text = widget.product['price']?.toString() ?? '';
    _discountController.text = widget.product['discountPrice']?.toString() ?? '';

    if (widget.product['productType'] == 'Simple Product') {
      _stockController.text = widget.product['quantity']?.toString() ?? '';
    } else if (widget.product['productType'] == 'Product Variants' &&
        widget.product['variations'] != null) {
      final variations = widget.product['variations'] as List<dynamic>;
      _variations = variations.map((v) {
        final variation = v as Map<dynamic, dynamic>;
        return {
          if (variation['size'] != null) 'size': variation['size'].toString(),
          if (variation['color'] != null) 'color': variation['color'].toString(),
          'quantity': variation['quantity']?.toString(),
        };
      }).toList();

      _variationStockControllers = _variations.map((v) {
        return TextEditingController(text: v['quantity']?.toString() ?? '');
      }).toList();
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.product['productType'] == 'Simple Product') {
        await FirebaseDatabase.instance
            .ref('products/${widget.product['productId']}')
            .update({
          'price': double.tryParse(_priceController.text),
          'discountPrice': _discountController.text.isNotEmpty
              ? double.tryParse(_discountController.text)
              : null,
          'quantity': int.tryParse(_stockController.text),
        });
      } else if (widget.product['productType'] == 'Product Variants') {
        final updatedVariations = _variations.asMap().entries.map((entry) {
          final index = entry.key;
          final variation = entry.value;
          return {
            if (variation['size'] != null) 'size': variation['size'],
            if (variation['color'] != null) 'color': variation['color'],
            'quantity': int.tryParse(_variationStockControllers[index].text) ?? 0,
          };
        }).toList();

        await FirebaseDatabase.instance
            .ref('products/${widget.product['productId']}')
            .update({
          'price': double.tryParse(_priceController.text),
          'discountPrice': _discountController.text.isNotEmpty
              ? double.tryParse(_discountController.text)
              : null,
          'variations': updatedVariations,
        });
      }

      await _provider.loadVendorProducts();

      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          "Success",
          "Product updated successfully!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Error",
          "Failed to update product: ${e.toString()}",
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: Icon(Icons.cancel, color: Colors.red, size: 30),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 3),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        String? Function(String?)? validator,
        TextInputType? keyboardType,
      }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black, // Text color changes based on mode
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : _secondaryColor.withOpacity(0.7),
        ),
        filled: isDarkMode,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: _primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _inputPadding,
          vertical: _inputPadding * 0.75,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: _inputPadding / 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isVariantProduct = widget.product['productType'] == 'Product Variants';

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(_inputPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Section
              _buildSectionHeader('Price Information'),
              SizedBox(height: _inputPadding),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Price (PKR)',
                      _priceController,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) return 'Invalid price';
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: _inputPadding),
                  Expanded(
                    child: _buildTextField(
                      'Discount Price (PKR)',
                      _discountController,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final discount = double.tryParse(value);
                          final price = double.tryParse(_priceController.text);
                          if (discount == null || discount < 0) return 'Invalid';
                          if (price != null && discount >= price) {
                            return ' less tha price';
                          }
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _inputPadding * 1.5),

              // Stock Section
              _buildSectionHeader('Stock Information'),
              SizedBox(height: _inputPadding),

              if (!isVariantProduct) ...[
                // Simple Product Stock
                _buildTextField(
                  'Stock Quantity',
                  _stockController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final qty = int.tryParse(value);
                    if (qty == null || qty < 0) return 'Invalid quantity';
                    return null;
                  },
                  keyboardType: TextInputType.number,
                ),
              ] else ...[
                // Variant Product Stock - Table Layout
                if (_variations.isEmpty)
                  const Text('No variations available'),

                if (_variations.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(_borderRadius),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(_borderRadius),
                              topRight: Radius.circular(_borderRadius),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: _inputPadding),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 40), // left se 10 pixels shift
                                    child: Text(
                                      'Size',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 40),
                                  child: Text(
                                    'Color',
                                    textAlign: TextAlign.center, // Align text horizontally
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              )),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    'Stock',
                                    textAlign: TextAlign.center, // Align text horizontally
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
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
                          itemCount: _variations.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          ),
                          itemBuilder: (context, index) {
                            return Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[850] : Colors.white,
                                borderRadius: index == _variations.length - 1
                                    ? BorderRadius.only(
                                  bottomLeft: Radius.circular(_borderRadius),
                                  bottomRight: Radius.circular(_borderRadius),
                                )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Size (non-editable)
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        _variations[index]['size']?.toString() ?? '---',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Color (non-editable)
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        _variations[index]['color']?.toString() ?? '---',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Stock (editable)
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          controller: _variationStockControllers[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center, // Align text horizontally
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return 'Required';
                                            final qty = int.tryParse(value);
                                            if (qty == null || qty < 0) return 'Invalid';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                    ),
                  ),
              ],

              SizedBox(height: _inputPadding * 2),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4A49),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFFF4A49),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'Update Product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  void dispose() {
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    for (var controller in _variationStockControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}