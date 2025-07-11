import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/main_vendor_screen.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/innerscreens/Vendor%20product%20detail%20screen.dart';
import 'package:provider/provider.dart';
import 'package:multi_vendor_ecommerce_app/views/screens/Seller/provider/product_provider.dart';

import '../innerscreens/Vendorproductedit.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;


    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Products',
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
                  return const MainVendorScreen(initialIndex: 0);
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300), // optional
              ),
            ),



          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Container(
              color: const Color(0xFFFF4A49),
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  return TabBar(
                    labelPadding: EdgeInsets.symmetric(horizontal: 4),
                    tabs: [
                      Tab(text: 'Add Products'),
                      Tab(text: 'Uploaded Products(${provider.uploadedProductsCount})'),
                    ],
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 3.0,
                        color: Color(0xFFFFD180),
                      ),
                      insets: EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 8.0),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      shadows: [
                        Shadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 1)),
                      ],
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                    labelColor: Color(0xFFFFE0B2),
                    unselectedLabelColor: Color(0xFFFFAB91),
                  );
                },
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            GeneralScreen(),
            UploadedProductsScreen(),
          ],
        ),
      ),
    );
  }
}

class GeneralScreen extends StatefulWidget {
  const GeneralScreen({super.key});

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {
  late final ProductProvider _provider;
  String? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _sizeFormKey = GlobalKey<FormState>();
  final _colorFormKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
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
    _provider.loadCategories();
    _initializeData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _varSizeController.dispose();
    _varColorController.dispose();
    _varQtyController.dispose();
    super.dispose();
  }


  Future<void> _initializeData() async {
    await _provider.loadVendorInfo();
    await _provider.loadVendorProducts();
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

  Future<void> _uploadProduct() async {
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
      final productId = FirebaseDatabase.instance.ref('products').push().key!;
      final List<String> imageUrls = [];

      // Upload images to Firebase Storage
      for (String localPath in _provider.images) {
        final File imageFile = File(localPath);
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance
            .ref('products/$productId/$fileName');
        await storageRef.putFile(imageFile);
        final String downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Prepare product data
      final productData = {
        'productId': productId,
        'productName': _provider.productData['productName'],
        'category': _provider.productData['category'],
        'description': _provider.productData['description'],
        'price': _provider.productData['price'],
        'discountPrice': _provider.productData['discountPrice'],
        'shippingCharges': _provider.productData['shippingCharges'],
        'taxPercent': _provider.productData['taxPercent'],
        'taxAmount': _provider.productData['taxAmount'],
        'imageUrls': imageUrls,
        'vendorId': _provider.productData['vendorId'],
        'businessName': _provider.productData['businessName'],
        'vendorAddress': _provider.productData['vendorAddress'],
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

      // Save to Firebase Realtime Database
      await FirebaseDatabase.instance
          .ref('products/$productId')
          .set(productData);

      setState(() {
        _selectedCategory = null;
        _selectedProductType = null;
        _descriptionController.clear();
      });
      _provider.clearForm();


      _clearAllFormData();
      // Clear form and refresh products
      // _provider.clearForm();
      await _provider.loadVendorProducts();

      if (mounted) {
        Get.snackbar(
          "Success",
          "Product uploaded successfully!",
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
          "Something went wrong. Please try again.",
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


  void _clearAllFormData() async {
    // Clear provider first
    _provider.clearForm();

    // Clear controllers
    _descriptionController.clear();
    _sizeController.clear();
    _colorController.clear();
    _varSizeController.clear();
    _varColorController.clear();
    _varQtyController.clear();

    // Reset dropdowns
    _selectedCategory = null;
    _selectedProductType = null;

    // Reset form keys
    _formKey.currentState?.reset();
    _variationFormKey.currentState?.reset();
    _productTypeFormKey.currentState?.reset();

    // Now wait a little
    await Future.delayed(Duration(milliseconds: 20));

    // Force UI rebuild after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _descriptionController.text = '';
        _selectedCategory = null;
        _selectedProductType = null;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final images = context.watch<ProductProvider>().images;

    return Form(
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
                      child: Image.file(
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
                                child: Image.file(
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
                    keyboardType: TextInputType.number,
                    validator: _validatePrice,
                  ),
                ),
                SizedBox(width: _inputPadding),
                Expanded(
                  child: _buildTextField(
                    "Shipping Price",
                        (value) => _provider.getFormData(shippingCharges: double.tryParse(value)),
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
                    keyboardType: TextInputType.number,
                    validator: _validateDiscountPrice,
                  ),
                ),
                SizedBox(width: _inputPadding),
                Expanded(
                  child: _buildTextField(
                    "Tax %",
                        (value) => _provider.getFormData(taxPercent: double.tryParse(value)),
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
            SizedBox(height: _inputPadding * 2),
            Center(child: _buildSaveButton()),
          ],
        ),
      ),
    );
  }

  // Validation methods
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
    if (price == null || price <= 0) return ' greater than 0';
    if (int.tryParse(value) == null) return 'Enter valid price';
    return null;
  }

  String? _validateDiscountPrice(String? value) {
    if (value!.isNotEmpty) {
      final discount = double.tryParse(value);
      final price = _provider.productData['price'] ?? double.tryParse(value);
      if (discount == null || discount < 0) return 'Invalid discount';
      if (discount == 0) return 'Enter valid price';
      if (price != null && discount >= price) return 'lower than price';
      if (int.tryParse(value) == null) return 'Enter valid price';
    }
    return null;
  }

  String? _validateShipping(String? value) {
    if (value == null || value.isEmpty) return  'Charges are required';
    final shipping = double.tryParse(value);
    if (shipping == null || shipping < 0) return 'Cannot be negative';
    if (int.tryParse(value) == null) return 'Enter valid price';
    return null;
  }

  String? _validateTax(String? value) {
    if (value!.isNotEmpty) {
      final tax = double.tryParse(value);
      if (tax == null || tax < 1 || tax > 100) return 'Must be 1%-100%';
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

  // Helper widgets
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
        color: isDarkMode ? Colors.white : Colors.black, // Text color
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
    return DropdownButtonFormField<String>(

      value: _selectedProductType,
      decoration: InputDecoration(
        labelText: "Product Type",
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
      validator: _validateProductType,
      items: ['Simple Product', 'Product Variants']
          .map((type) => DropdownMenuItem(
        value: type,
        child: Text(type),
      ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedProductType = value);
        _provider.handleProductTypeChange(value);
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: 160,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF4A49),
          borderRadius: BorderRadius.circular(30),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _uploadProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
            "Save Product",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  void _addVariation() {
    if (_variationFormKey.currentState!.validate()) {
      final size = _varSizeController.text.trim();
      final color = _varColorController.text.trim();
      final qty = _varQtyController.text.trim();

      if (size.isEmpty && color.isEmpty) {
        Get.snackbar(
          "Error",
          "Please provide either size or color.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          icon: const Icon(Icons.info, color: Colors.orange, size: 30),
          shouldIconPulse: false,
          snackStyle: SnackStyle.FLOATING,
          isDismissible: true,
          margin: const EdgeInsets.all(10),
        );
        return;
      }

      _provider.addVariation(size, color, qty);
      _varSizeController.clear();
      _varColorController.clear();
      _varQtyController.clear();
    }
  }
}


class UploadedProductsScreen extends StatefulWidget {
  const UploadedProductsScreen({super.key});

  @override
  State<UploadedProductsScreen> createState() => _UploadedProductsScreenState();
}

class _UploadedProductsScreenState extends State<UploadedProductsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get all unique categories
    final categories = ['All'] +
        provider.uploadedProducts
            .map((p) => p['category']?.toString() ?? 'Uncategorized')
            .toSet()
            .toList();

    // Filter products based on selected category
    final filteredProducts = _selectedCategory == 'All'
        ? provider.uploadedProducts
        : provider.uploadedProducts.where((product) =>
    (product['category']?.toString() ?? 'Uncategorized') == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Visibility(
              visible: provider.uploadedProducts.isNotEmpty,
              // Category Filter Chips
              child:Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == category
                                ? const Color(0xFFFF4A49)
                                : isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : isDarkMode ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )),
          // Product List
          Expanded(
            child: provider.isLoadingProducts
                ? Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? Center(
              child: Text(
                _selectedCategory == 'All'
                    ? 'No products uploaded yet'
                    : 'No products in this category',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 3, left: 16, right: 16),

              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductCard(context, product, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, Map<String, dynamic> product, ProductProvider provider) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = product['imageUrls'] != null && product['imageUrls'].isNotEmpty
        ? product['imageUrls'][0]
        : null;

    return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ProductDetailScreen(product: product),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      ),
                      child: imageUrl != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                          : Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['productName'] ?? 'No Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${product['category'] ?? 'No Category'}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (product['discountPrice'] != null && product['discountPrice'] > 0)
                                Text(
                                  '\$${product['discountPrice']?.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF4A49),
                                  ),
                                ),
                              if (product['discountPrice'] != null && product['discountPrice'] > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: isDarkMode ? Colors.grey[500] : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF4A49),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Three Dot Menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.grey[400] : Colors.black87),
                      onSelected: (value) => _handleMenuSelection(value, product['productId'], context, provider),
                      itemBuilder: (BuildContext context) {
                        return {'View', 'Edit', 'Delete'}.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),

                // Stock Information
                const SizedBox(height: 12),
                Divider(height: 1, color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStockText(product),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor(product),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStockStatus(product),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
        ));
  }

  String _getStockText(Map<String, dynamic> product) {
    try {
      if (product['productType'] == 'Product Variants' && product['variations'] != null) {
        final variations = product['variations'] as List;
        int totalStock = 0;

        for (final variation in variations) {
          final qty = variation['quantity'] is int
              ? variation['quantity'] as int
              : (int.tryParse(variation['quantity']?.toString() ?? '0'))?? 0;
          totalStock += qty;
        }

        return '$totalStock';
      }

      final simpleQty = product['quantity'] is int
          ? product['quantity'] as int
          : (int.tryParse(product['quantity']?.toString() ?? '0')) ?? 0;

      return '$simpleQty';
    } catch (e) {
      debugPrint('Error in _getStockText: $e');
      return '0';
    }
  }

  String _getStockStatus(Map<String, dynamic> product) {
    try {
      int quantity = 0;

      if (product['productType'] == 'Product Variants' && product['variations'] != null) {
        final variations = product['variations'] as List;
        for (final variation in variations) {
          final qty = variation['quantity'] is int
              ? variation['quantity'] as int
              : (int.tryParse(variation['quantity']?.toString() ?? '0')) ?? 0;
          quantity += qty;
        }
      } else {
        quantity = product['quantity'] is int
            ? product['quantity'] as int
            : (int.tryParse(product['quantity']?.toString() ?? '0')) ?? 0;
      }

      if (quantity == 0) return 'Out of Stock';
      if (quantity < 10) return 'Limited Stock';
      return 'In Stock';
    } catch (e) {
      debugPrint('Error in _getStockStatus: $e');
      return 'Status unknown';
    }
  }

  Color _getStockStatusColor(Map<String, dynamic> product) {
    try {
      int quantity = 0;

      if (product['productType'] == 'Product Variants' && product['variations'] != null) {
        final variations = product['variations'] as List;
        for (final variation in variations) {
          final qty = variation['quantity'] is int
              ? variation['quantity'] as int
              : (int.tryParse(variation['quantity']?.toString() ?? '0')) ?? 0;
          quantity += qty;
        }
      } else {
        quantity = product['quantity'] is int
            ? product['quantity'] as int
            : (int.tryParse(product['quantity']?.toString() ?? '0')) ?? 0;
      }

      if (quantity == 0) return Colors.red;
      if (quantity < 10) return Colors.orange;
      return Colors.green;
    } catch (e) {
      debugPrint('Error in _getStockStatusColor: $e');
      return Colors.grey;
    }
  }

  void _handleMenuSelection(
      String value,
      String productId,
      BuildContext context,
      ProductProvider provider,
      )
  {
    switch (value) {
      case 'View':
        final product = provider.uploadedProducts.firstWhere(
              (p) => p['productId'] == productId,
          orElse: () => {},
        );

        if (product.isNotEmpty) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProductDetailScreen(product: product),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
        break;

      case 'Edit':
        final product = provider.uploadedProducts.firstWhere(
              (p) => p['productId'] == productId,
          orElse: () => {},
        );

        if (product.isNotEmpty) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  EditProductScreen(product: product),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ).then((_) {
            // This will be called when coming back from EditProductScreen
            provider.clearForm();
          });
        }

        break;

      case 'Delete':
        _showDeleteDialog(context, productId, provider);
        break;
    }
  }

  void _showDeleteDialog(
      BuildContext context, String productId, ProductProvider provider)
  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Product',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, ),
          ),

          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),


            ),
            TextButton(
              onPressed: () async {
                try {
                  await provider.deleteProduct(productId);
                  Navigator.of(context).pop();
                  Get.snackbar(
                    "Success",
                    "Product deleted successfully!",
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
                  Navigator.of(context).pop();
                  Get.snackbar(
                    "Error",
                    "Failed to delete product",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.white,
                    colorText: Colors.black,
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                    shouldIconPulse: false,
                    snackStyle: SnackStyle.FLOATING,
                    isDismissible: true,
                    margin: const EdgeInsets.all(10),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}