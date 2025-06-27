import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/provider/product_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';


class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final ProductProvider _provider;
  String? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _sizeFormKey = GlobalKey<FormState>();
  final _colorFormKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _shippingController = TextEditingController();
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();
  final _quantityController = TextEditingController();
  final TextEditingController _varSizeController = TextEditingController();
  final TextEditingController _varColorController = TextEditingController();
  final TextEditingController _varQtyController = TextEditingController();
  final _variationFormKey = GlobalKey<FormState>();
  String? _selectedSize;
  bool _isLoading = false;
  String? _selectedProductType;
  final _productTypeFormKey = GlobalKey<FormState>();

  // Design constants
  final Color _primaryColor = const Color(0xFFFF4A49);
  final Color _secondaryColor = Colors.grey.shade800;
  final Color _borderColor = Colors.grey.shade300;
  final Color _chipBackground = const Color(0xFFF5F5F5);
  final double _borderRadius = 12.0;
  final double _inputPadding = 16.0;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ProductProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.clearForm();
      _initializeFormData();
      _provider.loadCategories();
    });
  }


  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _shippingController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _varSizeController.dispose();
    _varColorController.dispose();
    _varQtyController.dispose();
    super.dispose();
  }

  // In your EditProductScreen, modify the initialization to handle type conversion:

  // In your _initializeFormData method, modify it to properly initialize all fields:

  void _initializeFormData() {
    // Clear any existing data first
    _provider.clearForm();

    // Safely convert the product data to Map<String, dynamic>
    final productData = Map<String, dynamic>.from(widget.product);

    // Set dropdown values FIRST
    _selectedCategory = productData['category']?.toString();
    _selectedProductType = productData['productType']?.toString() ?? 'Simple Product';

    // Inform provider about product type change (this clears variations or quantity)
    _provider.handleProductTypeChange(_selectedProductType);

    // Now initialize the rest of the form data
    _provider.getFormData(
      productName: productData['productName']?.toString(),
      category: _selectedCategory,
      description: productData['description']?.toString(),
      price: _convertToDouble(productData['price']),
      discountPrice: _convertToDouble(productData['discountPrice']),
      quantity: _convertToInt(productData['quantity']),
      shippingCharges: _convertToDouble(productData['shippingCharges']),
      taxPercent: _convertToDouble(productData['taxPercent']),
      images: List<String>.from(productData['imageUrls'] ?? []),
    );

    // Initialize text controllers
    _productNameController.text = productData['productName']?.toString() ?? '';
    _priceController.text = productData['price']?.toString() ?? '';
    _shippingController.text = productData['shippingCharges']?.toString() ?? '';
    _discountController.text = productData['discountPrice']?.toString() ?? '';
    _taxController.text = productData['taxPercent']?.toString() ?? '';
    _quantityController.text = productData['quantity']?.toString() ?? '';
    _descriptionController.text = productData['description']?.toString() ?? '';

    // Initialize variations if it's a variant product
    if (productData['variations'] != null && _selectedProductType == 'Product Variants') {
      final variations = List<Map<String, dynamic>>.from(
        productData['variations'].map((v) => Map<String, dynamic>.from(v)),
      );
      for (var variation in variations) {
        _provider.addVariation(
          variation['size']?.toString() ?? '',
          variation['color']?.toString() ?? '',
          variation['quantity']?.toString() ?? '0',
        );
      }
    }

    // Force UI update
    setState(() {});
  }



// Helper methods for type conversion
  double? _convertToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _convertToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (_provider.images.length < 7) {
          _provider.getFormData(images: [..._provider.images, image.path]);
        }
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_provider.productType == 'Product Variants') {
      if (_provider.variations.isEmpty) {
        Get.snackbar(
          "Error",
          "You must add at least one variation",
          backgroundColor: Colors.blueGrey[800],
          colorText: Colors.white,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final List<String> imageUrls = [];
      final List<String> newImages = [];
      final List<String> existingUrls = List<String>.from(widget.product['imageUrls'] ?? []);

      // Separate existing URLs from new local paths
      for (String image in _provider.images) {
        if (image.startsWith('http')) {
          imageUrls.add(image);
        } else {
          newImages.add(image);
        }
      }

      // Upload new images to Firebase Storage
      for (String localPath in newImages) {
        final File imageFile = File(localPath);
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance
            .ref('products/${widget.product['productId']}/$fileName');
        await storageRef.putFile(imageFile);
        final String downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Prepare updated product data
      final productData = {
        'productName': _provider.productData['productName'],
        'category': _provider.productData['category'],
        'description': _provider.productData['description'],
        'price': _provider.productData['price'],
        'discountPrice': _provider.productData['discountPrice'],
        'shippingCharges': _provider.productData['shippingCharges'],
        'taxPercent': _provider.productData['taxPercent'],
        'taxAmount': _provider.productData['taxAmount'],
        'imageUrls': imageUrls,
        'productType': _provider.productType,
        'dateTime': DateTime.now().toString(),

        if (_provider.productType == 'Simple Product')
          'quantity': _provider.productData['quantity'],

        if (_provider.productType == 'Product Variants')
          'variations': _provider.variations.map((v) => {
            if (v['size']?.toString().isNotEmpty ?? false) 'size': v['size'],
            if (v['color']?.toString().isNotEmpty ?? false) 'color': v['color'],
            'quantity': v['quantity']
          }).toList(),
      };

      // Update in Firebase Realtime Database
      await FirebaseDatabase.instance
          .ref('products/${widget.product['productId']}')
          .update(productData);

      // Refresh products list
      await _provider.loadVendorProducts();

      if (mounted) {
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

        Navigator.of(context).pop();
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

  void _addVariation() {
    if (_variationFormKey.currentState!.validate()) {
      final size = _varSizeController.text.trim();
      final color = _varColorController.text.trim();
      final qty = _varQtyController.text.trim();

      if (size.isEmpty && color.isEmpty) {
        Get.snackbar(
          "Error",
          "Please provide either size or color",
          backgroundColor: Colors.blueGrey[800],
          colorText: Colors.white,
        );
        return;
      }

      _provider.addVariation(size, color, qty);
      _varSizeController.clear();
      _varColorController.clear();
      _varQtyController.clear();
    }
  }

  // Validation methods (same as in UploadScreen)
  String? _validateProductName(String? value) {
    if (value == null || value.isEmpty) return 'Product name is required';
    if (RegExp(r'^[0-9]+$').hasMatch(value)) return 'Cannot be only digits';
    if (value.trim().isNotEmpty && !RegExp(r'[a-zA-Z0-9]').hasMatch(value)) {
      return 'Only special characters are not allowed';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Quantity is required';
    final quantity = int.tryParse(value);
    if (quantity == null) return 'Enter valid quantity';
    if (quantity <= 0) return 'Must be greater than 0';
    if (value.length > 4) return 'Maximum 4 digits allowed';
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final price = double.tryParse(value);
    if (price == null || price <= 0) return 'Must be greater than 0';
    if (int.tryParse(value) == null) return 'Enter valid price';
    return null;
  }

  String? _validateDiscountPrice(String? value) {
    if (value!.isNotEmpty) {
      final discount = double.tryParse(value);
      final price = _provider.productData['price'] ?? double.tryParse(value);
      if (discount == null || discount < 0) return 'Invalid discount';
      if (price != null && discount >= price) return 'lower than price';
      if (int.tryParse(value) == null) return 'Enter valid price';
    }
    return null;
  }

  String? _validateShipping(String? value) {
    if (value == null || value.isEmpty) return 'Shipping charges are required';
    final shipping = double.tryParse(value);
    if (shipping == null || shipping < 0) return 'Cannot be negative';
    if (int.tryParse(value) == null) return 'Enter valid price';
    return null;
  }

  String? _validateTax(String? value) {
    if (value!.isNotEmpty) {
      final tax = double.tryParse(value);
      if (tax == null || tax < 0 || tax > 100) return 'Must be 0-100';
    }
    return null;
  }

  String? _validateSize(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'[a-zA-Z0-9]').hasMatch(value)) return 'Invalid';
    return null;
  }

  String? _validateColor(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) return 'Invalid';
      if (RegExp(r'^[0-9 ]+$').hasMatch(value)) return 'Invalid';
    }
    return null;
  }

  String? _validateProductType(String? value) {
    return value == null ? 'Please select product type' : null;
  }

  // Helper widgets (same as in UploadScreen)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: _inputPadding / 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : _secondaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      Function(String) onChanged, {
        TextEditingController? controller,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
        EdgeInsets? contentPadding,
      }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
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
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: _primaryColor),
        ),
        contentPadding: contentPadding ?? EdgeInsets.symmetric(
          horizontal: _inputPadding,
          vertical: _inputPadding * 0.75,
        ),
      ),
      keyboardType: keyboardType,
    );
  }


  Widget _buildCategoryDropdown() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: "Category",
            labelStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : _secondaryColor.withOpacity(0.7),
            ),
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
          validator: (value) => value == null ? 'Please select a category' : null,
          items: provider.categories
              .map((category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value);
            provider.getFormData(category: value);
          },
        );
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      onChanged: (value) => _provider.getFormData(description: value),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Description is required';
        if (value.length > 200) return 'Description cannot exceed 200 characters';
        return null;
      },
      decoration: InputDecoration(
        labelText: "Description",
        labelStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[300]
              : _secondaryColor.withOpacity(0.7),
        ),
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

  Widget _buildProductTypeDropdown() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: _selectedProductType,
      decoration: InputDecoration(
        labelText: "Product Type",
        labelStyle: TextStyle(
          color: isDarkMode
              ? Colors.grey[300]
              : _secondaryColor.withOpacity(0.7),
        ),
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
      validator: _validateProductType,
      items: ['Simple Product', 'Product Variants']
          .map((type) => DropdownMenuItem(
        value: type,
        child: Text(type),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedProductType = value;
          _provider.handleProductTypeChange(value);
          // Clear quantity when switching to variants
          if (value == 'Product Variants') {
            _quantityController.clear();
          }
        });
      },
    );
  }


  Widget _buildSaveButton() {
    return Center(
      child: SizedBox(
        width: 180,
        height: 45,
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
    );
  }


  @override
  Widget build(BuildContext context) {
    final images = context.watch<ProductProvider>().images;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Product',
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_inputPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              _buildSectionHeader('Product Images'),
              SizedBox(height: _inputPadding),

              // Main Image Preview
              if (images.isNotEmpty)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        border: Border.all(color: Colors.black54, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        child: images[0].startsWith('http')
                            ? Image.network(
                          images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey.shade200),
                        )
                            : Image.file(
                          File(images[0]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _provider.getFormData(images: images.sublist(1));
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(_borderRadius),
                      border: Border.all(color: _borderColor, width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: _primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Click to upload",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "PNG or JPG",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Thumbnail Grid
              SizedBox(height: _inputPadding),
              if (images.length > 1)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length - 1,
                    itemBuilder: (context, index) {
                      final imgIndex = index + 1;
                      return Padding(
                        padding: EdgeInsets.only(right: _inputPadding),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              final newImages = List<String>.from(images);
                              final selected = newImages.removeAt(imgIndex);
                              newImages.insert(0, selected);
                              _provider.getFormData(images: newImages);
                            });
                          },
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_borderRadius),
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(_borderRadius),
                                  child: images[imgIndex].startsWith('http')
                                      ? Image.network(
                                    images[imgIndex],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: Colors.grey.shade200),
                                  )
                                      : Image.file(
                                    File(images[imgIndex]),
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: Colors.grey.shade200),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        final newImages = List<String>.from(images);
                                        newImages.removeAt(imgIndex);
                                        _provider.getFormData(images: newImages);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Add More Images Button
              if (images.length < 7)
                Padding(
                  padding: EdgeInsets.only(top: _inputPadding),
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: _inputPadding,
                      ),
                    ),
                    icon: Icon(Icons.add, size: 20),
                    label: Text(
                      "Add More Images",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              SizedBox(height: _inputPadding * 1.5),

              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              _buildTextField(
                "Product Name",
                    (value) => _provider.getFormData(productName: value),
                controller: _productNameController,
                validator: _validateProductName,
              ),
              SizedBox(height: _inputPadding),
              _buildCategoryDropdown(),
              SizedBox(height: _inputPadding),
              _buildProductTypeDropdown(),
              Visibility(
                visible: _provider.productType != 'Product Variants',
                child: Column(
                  children: [
                    SizedBox(height: _inputPadding),
                    _buildTextField(
                      "Stock",
                          (value) => _provider.getFormData(quantity: int.tryParse(value)),
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      validator: _validateQuantity,
                    ),
                  ],
                ),
              ),
              SizedBox(height: _inputPadding),
              _buildDescriptionField(),

              // Pricing Section
              SizedBox(height: _inputPadding * 1.5),
              _buildSectionHeader('Pricing'),
              Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '* ',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        TextSpan(
                          text: 'Enter price in dollar only',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Price",
                          (value) => _provider.getFormData(price: double.tryParse(value)),
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      validator: _validatePrice,
                    ),
                  ),
                  SizedBox(width: _inputPadding),
                  Expanded(
                    child: _buildTextField(
                      "Shipping Price",
                          (value) => _provider.getFormData(shippingCharges: double.tryParse(value)),
                      controller:_shippingController,
                      keyboardType: TextInputType.number,
                      validator: _validateShipping,
                    ),
                  ),

                ],
              ),

              // Discount and Tax Section
              SizedBox(height: _inputPadding),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Discount Price",
                          (value) => _provider.getFormData(discountPrice: double.tryParse(value)),
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      validator: _validateDiscountPrice,

                    ),
                  ),


                  SizedBox(width: _inputPadding),
                  Expanded(
                    child: _buildTextField(
                      "Tax %",
                          (value) => _provider.getFormData(taxPercent: double.tryParse(value)),
                      controller:_taxController,
                      keyboardType: TextInputType.number,
                      validator: _validateTax,
                    ),
                  ),


                ],
              ),

              // Variations Section
              Visibility(
                visible: _provider.productType == 'Product Variants',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: _inputPadding * 1.5),
                    _buildSectionHeader('Product Variations'),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(_inputPadding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[50],
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Form(
                            key: _variationFormKey,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        "Size",
                                            (value) {},
                                        controller: _varSizeController,
                                        validator: _validateSize,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      ),
                                    ),
                                    SizedBox(width: _inputPadding),
                                    Expanded(
                                      child: _buildTextField(
                                        "Color",
                                            (value) {},
                                        controller: _varColorController,
                                        validator: _validateColor,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      ),
                                    ),
                                    SizedBox(width: _inputPadding),
                                    Expanded(
                                      child: _buildTextField(
                                        "Stock",
                                            (value) {},
                                        controller: _varQtyController,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required';
                                          final quantity = int.tryParse(value);
                                          if (quantity == null) return 'Invalid';
                                          if (quantity <= 0) return 'Must be > 0';
                                          if (value.length > 4) return 'Max 4 digits';
                                          return null;
                                        },
                                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: _inputPadding),
                                GestureDetector(
                                  onTap: _addVariation,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.add, size: 20, color: _primaryColor),
                                        SizedBox(width: 4),
                                        Text(
                                          "Add Variation",
                                          style: TextStyle(
                                            color: _primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_provider.variations.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: _inputPadding),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _provider.variations.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final variation = entry.value;

                                  List<String> parts = [];
                                  if (variation['size'] != null && variation['size'].toString().trim().isNotEmpty) {
                                    parts.add('Size: ${variation['size']}');
                                  }
                                  if (variation['color'] != null && variation['color'].toString().trim().isNotEmpty) {
                                    parts.add('Color: ${variation['color']}');
                                  }
                                  if (variation['quantity'] != null && variation['quantity'].toString().trim().isNotEmpty) {
                                    parts.add('Quantity: ${variation['quantity']}');
                                  }

                                  return Chip(
                                    label: Text(
                                      parts.join(' | '),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    deleteIcon: Icon(Icons.close, size: 16),
                                    onDeleted: () => _provider.removeVariation(index),
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[700]
                                        : _chipBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: BorderSide(color: _borderColor.withOpacity(0.3)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Center(child: _buildSaveButton()),
            ],
          ),
        ),
      ),
    );
  }
}