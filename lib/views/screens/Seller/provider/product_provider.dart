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
  double? _taxPercent; // New field for tax percentage
  double? _taxAmount;// New field for calculated tax amount
  String? _dateTime;
  String? _productType;

  List<String> _images = [];
  List<String> _categories = [];



  // Getters
  List<String> get categories => _categories;


  List<Map<String, dynamic>> _variations = [];
  List<Map<String, dynamic>> get variations => List.unmodifiable(_variations);

  List<String> get images => List.unmodifiable(_images);

  double? get taxPercent => _taxPercent;

  double? get taxAmount => _taxAmount;
  String? get dateTime => _dateTime;
  String? get productType => _productType;



  Map<String, dynamic> get productData =>
      {
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
    final user = FirebaseAuth.instance.currentUser;  // Get current logged-in user
    if (user != null) {
      try {
        // Fetch the vendor data from Firebase Realtime Database using the current user's UID
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}')
            .get();

        if (snapshot.exists) {
          // Assign the fetched data to local variables
          _vendorId = user.uid;
          _businessName = snapshot.child('businessName').value.toString();
          _vendorAddress = snapshot.child('address').value.toString();

          // Notify listeners to update UI if necessary
          notifyListeners();
        } else {
          // Handle case when no data is found for the vendor
          print('Vendor data not found');
        }
      } catch (e) {
        // Handle errors (e.g., network issues)
        print('Error loading vendor data: $e');
      }
    } else {
      // Handle case when user is not logged in
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


  // Calculate tax amount when tax percentage is set
  // Calculate tax amount when tax percentage is set
  void setTaxPercent(double? percent) {
    _taxPercent = percent;

    // If discount price is available and greater than 0, apply tax on discount price
    if (_discountPrice != null && _discountPrice! > 0) {
      // Apply tax on discount price
      _taxAmount = _discountPrice! * (percent! / 100);
    } else if (_price != null) {
      // If discount price is not available, apply tax on base price
      _taxAmount = _price! * (percent! / 100);
    } else {
      _taxAmount = null; // If no price is set, tax amount will be null
    }

    // Debugging Output to Check Discount and Base Price
    print('Discount Price: $_discountPrice');
    print('Base Price: $_price');
    print('Tax Amount: $_taxAmount');

    notifyListeners();
  }

  void handleProductTypeChange(String? type) {
    _productType = type;
    if (type == 'Simple Product') {
      _variations.clear(); // Clear all variants
    } else if (type == 'Product Variants') {
      _quantity = null; // Reset simple quantity
    }
    notifyListeners();
  }

  void addVariation(String size, String color, String quantity) {
    _variations.add({
      'size': size,
      'color': color,
      'quantity': quantity
    });
    notifyListeners();
  }

  void removeVariation(int index) {
    _variations.removeAt(index);
    notifyListeners();
  }






  // Image Management
  void addImage(String imagePath) {
    _images = [..._images, imagePath];
    notifyListeners();
  }

  void removeImage(int index) {
    _images = List.from(_images)
      ..removeAt(index);
    notifyListeners();
  }

  // Main Form Data Handler
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
    _dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime.now());


    // Handle tax percentage and calculation
    if (taxPercent != null) {
      setTaxPercent(
          taxPercent); // This will update _taxPercent and calculate _taxAmount
    } else if (price != null && _taxPercent != null) {
      // Recalculate tax if price changed but tax percent didn't
      setTaxPercent(
          _taxPercent); // This ensures tax amount is recalculated if price changes
    }

    // If price is set but taxPercent is null, you might want to recalculate tax as well
    if (price != null && _taxPercent != null) {
      setTaxPercent(_taxPercent);
    }

    notifyListeners();
  }
}