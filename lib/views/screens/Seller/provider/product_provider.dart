import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ProductProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('categories');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Product Data Fields
  String? _productName;
  String? _category;
  String? _description;
  String? _brandName;
  String? _vendorId;
  String? _businessName;
  String? _vendorAddress;
  double? _price;
  double? _discountPrice;
  int? _quantity;
  double? _shippingCharges;
  double? _taxPercent;
  double? _taxAmount;
  String? _dateTime;
  String? _productType;
  List<String> _images = [];
  List<String> _categories = [];
  List<Map<String, dynamic>> _variations = [];
  List<Map<String, dynamic>> _uploadedProducts = [];
  bool _isLoadingProducts = false;

  // Getters
  List<String> get categories => _categories;
  List<Map<String, dynamic>> get variations => List.unmodifiable(_variations);
  List<String> get images => List.unmodifiable(_images);
  double? get taxPercent => _taxPercent;
  double? get taxAmount => _taxAmount;
  String? get dateTime => _dateTime;
  String? get productType => _productType;
  List<Map<String, dynamic>> get uploadedProducts => List.unmodifiable(_uploadedProducts);
  bool get isLoadingProducts => _isLoadingProducts;
  int get uploadedProductsCount => _uploadedProducts.length;

  Map<String, dynamic> get productData => {
    'productName': _productName,
    'category': _category,
    'description': _description,
    'brandName': _brandName,
    'vendorId': _vendorId,
    'businessName': _businessName,
    'vendorAddress': _vendorAddress,
    'price': _price,
    'discountPrice': _discountPrice,
    'quantity': _quantity,
    'shippingCharges': _shippingCharges,
    'taxPercent': _taxPercent,
    'taxAmount': _taxAmount,
    'images': _images,
    'dateTime': _dateTime,
    'productType': _productType,
  };

  void clearForm() {
    _productName = null;
    _category = null;
    _description = null;
    _brandName = null;
    _price = null;
    _discountPrice = null;
    _quantity = null;
    _shippingCharges = null;
    _taxPercent = null;
    _taxAmount = null;
    _vendorId = null;
    _businessName = null;
    _vendorAddress = null;
    _variations.clear();
    _images.clear();
    _productType = null;
    notifyListeners();
  }

  Future<void> loadVendorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}')
            .get();

        if (snapshot.exists) {
          _vendorId = user.uid;
          _businessName = snapshot.child('businessName').value.toString();
          _vendorAddress = snapshot.child('address').value.toString();
          notifyListeners();
        } else {
          print('Vendor data not found');
        }
      } catch (e) {
        print('Error loading vendor data: $e');
      }
    } else {
      print('No user is logged in');
    }
  }

  void loadCategories() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        _categories = data.values
            .map((category) => category['category name'].toString())
            .toList();
        notifyListeners();
      }
    });
  }

  Future<void> loadVendorProducts() async {
    _isLoadingProducts = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseDatabase.instance
          .ref('products')
          .orderByChild('vendorId')
          .equalTo(user.uid)
          .once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as dynamic);
        _uploadedProducts = data.entries.map((entry) {
          return {
            'productId': entry.key,
            ...Map<String, dynamic>.from(entry.value),
          };
        }).toList();
      } else {
        _uploadedProducts = [];
      }
    } catch (e) {
      print('Error loading products: $e');
      _uploadedProducts = [];
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      // Delete from database
      await FirebaseDatabase.instance.ref('products/$productId').remove();

      // Delete images from storage
      final storageRef = _storage.ref('products/$productId');
      await storageRef.listAll().then((result) {
        for (var item in result.items) {
          item.delete();
        }
      });

      // Update local list
      _uploadedProducts.removeWhere((product) => product['productId'] == productId);
      notifyListeners();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  void setTaxPercent(double? percent) {
    _taxPercent = percent;

    if (_discountPrice != null && _discountPrice! > 0) {
      _taxAmount = _discountPrice! * (percent! / 100);
    } else if (_price != null) {
      _taxAmount = _price! * (percent! / 100);
    } else {
      _taxAmount = null;
    }

    notifyListeners();
  }

  void handleProductTypeChange(String? type) {
    _productType = type;
    if (type == 'Simple Product') {
      _variations.clear();
    } else if (type == 'Product Variants') {
      _quantity = null;
    }
    notifyListeners();
  }

  void addVariation(String size, String color, String quantity) {
    _variations.add({
      'size': size.isNotEmpty ? size : null,
      'color': color.isNotEmpty ? color : null,
      'quantity': int.tryParse(quantity) ?? 0
    });
    notifyListeners();
  }

  void removeVariation(int index) {
    _variations.removeAt(index);
    notifyListeners();
  }

  void getFormData({
    String? productName,
    String? category,
    String? description,
    String? brandName,
    double? price,
    double? discountPrice,
    int? quantity,
    double? shippingCharges,
    double? taxPercent,
    List<String>? images,
  }) {
    _productName = productName ?? _productName;
    _category = category ?? _category;
    _description = description ?? _description;
    _brandName = brandName ?? _brandName;
    _price = price ?? _price;
    _discountPrice = discountPrice ?? _discountPrice;
    _quantity = quantity ?? _quantity;
    _shippingCharges = shippingCharges ?? _shippingCharges;
    _images = images ?? _images;
    _dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (taxPercent != null) {
      setTaxPercent(taxPercent);
    } else if (price != null && _taxPercent != null) {
      setTaxPercent(_taxPercent);
    }

    notifyListeners();
  }
}