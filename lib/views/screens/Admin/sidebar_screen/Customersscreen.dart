import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('users');
  final List<Map<String, dynamic>> _customerList = [];
  final List<Map<String, dynamic>> _displayedCustomers = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _customersPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  void _fetchCustomers() {
    setState(() => _isLoading = true);
    _database.orderByChild('role').equalTo('Customer').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      _customerList.clear();
      if (data != null) {
        data.forEach((key, value) {
          _customerList.add({
            "userId": key,
            "fullName": value["fullName"] ?? "No Name",
            "email": value["email"] ?? "No Email",
            "phoneNumber": value["phoneNumber"]?.toString() ?? "---",
            "address": value["address"] ?? "---",
          });
        });
      }
      _updateDisplayedCustomers();
      setState(() => _isLoading = false);
    }).onError((error) {
      setState(() => _isLoading = false);
      Get.snackbar(
        "Error",
        "Failed to load customers: ${error.toString()}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
    });
  }

  void _updateDisplayedCustomers() {
    final startIndex = (_currentPage - 1) * _customersPerPage;
    final endIndex = startIndex + _customersPerPage;

    setState(() {
      _displayedCustomers.clear();
      if (startIndex < _customerList.length) {
        _displayedCustomers.addAll(
          _customerList.sublist(
            startIndex,
            endIndex < _customerList.length ? endIndex : _customerList.length,
          ),
        );
      }
    });
  }

  void _nextPage() {
    if (_currentPage * _customersPerPage < _customerList.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedCustomers();
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateDisplayedCustomers();
      });
    }
  }

  Future<void> _removeCustomer(String userId) async {
    try {
      await _database.child(userId).remove();
      setState(() {
        _customerList.removeWhere((customer) => customer['userId'] == userId);
        _updateDisplayedCustomers();
      });
      Get.snackbar(
        "Success",
        "Customer removed successfully",
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
      Get.snackbar(
        "Error",
        "Failed to remove customer",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customers',
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
            : _customerList.isEmpty
      ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No Customers Found',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Poppins',
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    )
        : Column(
    children: [
    Expanded(
    child: Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.grey.shade100, Colors.grey.shade50],
    ),
    ),
    child: Padding(
    padding: const EdgeInsets.all(16.0),
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
    offset: const Offset(0, 2),
    )
    ],
    ),
    child: DataTable(
    headingRowColor:
    MaterialStateProperty.resolveWith<Color>(
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
    label: Text('Full Name',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Email',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Phone Number',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Address',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('Action',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    ],
    rows: _displayedCustomers.asMap().entries.map((entry) {
    final index = entry.key + 1 + ((_currentPage - 1) * _customersPerPage);
    final customer = entry.value;
    return DataRow(
    cells: [
    DataCell(Text(index.toString(),
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(customer['fullName'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(customer['email'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(customer['phoneNumber'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(Text(customer['address'],
    style: const TextStyle(
    fontSize: 15, fontFamily: 'Poppins'))),
    DataCell(
    TextButton(
    onPressed: () {
    _removeCustomer(customer['userId']);
    },
    child: const Text(
    'Remove',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    color: Colors.red,
    ),
    ),
    ),
    ),
    ],
    );
    }).toList(),
    ),
    ),
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
    'Page $_currentPage of ${(_customerList.length / _customersPerPage).ceil()}',
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    ),
    ),
    IconButton(
    icon: const Icon(Icons.arrow_forward_ios, size: 16),
    onPressed: _nextPage,
    color: _currentPage * _customersPerPage < _customerList.length
    ? const Color(0xFFFF4A49)
        : Colors.grey,
    ),
    ],
    ),
    ),
    const SizedBox(height: 16),
    ],
    ),
    );
  }
}