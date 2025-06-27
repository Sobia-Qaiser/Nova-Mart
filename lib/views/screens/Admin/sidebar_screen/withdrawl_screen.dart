import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final DatabaseReference _revenueRef = FirebaseDatabase.instance.ref('revenue');
  List<Map<String, dynamic>> _vendorRevenues = [];
  List<Map<String, dynamic>> _displayedVendors = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _vendorsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchRevenueData();
  }

  void _fetchRevenueData() {
    setState(() => _isLoading = true);
    _revenueRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      _vendorRevenues.clear();
      if (data != null) {
        // Convert to list first to maintain order
        final vendors = data.entries.toList();

        // Sort by this month's revenue (descending)
        vendors.sort((a, b) {
          final aRevenue = (b.value["thisMonthEarningAfterCommission"] ?? 0).toInt();
          final bRevenue = (a.value["thisMonthEarningAfterCommission"] ?? 0).toInt();
          return aRevenue.compareTo(bRevenue);
        });

        // Now assign serial numbers based on sorted order
        for (int i = 0; i < vendors.length; i++) {
          final vendorData = Map<String, dynamic>.from(vendors[i].value as Map);
          _vendorRevenues.add({
            "vendorId": vendors[i].key,
            "srNo": i + 1,  // This will give sequential numbers 1, 2, 3...
            "vendorName": vendorData["vendorName"] ?? "Unknown",
            "businessName": vendorData["businessName"] ?? "Unknown",
            "totalRevenue": (vendorData["totalRevenueAfterCommission"] ?? 0).toInt(),
            "thisMonth": (vendorData["thisMonthEarningAfterCommission"] ?? 0).toInt(),
          });
        }
      }

      _updateDisplayedVendors();
      setState(() => _isLoading = false);
    }).onError((error) {
      setState(() => _isLoading = false);
      debugPrint('Error loading revenue data: $error');
    });
  }

  void _updateDisplayedVendors() {
    final startIndex = (_currentPage - 1) * _vendorsPerPage;
    final endIndex = startIndex + _vendorsPerPage;

    setState(() {
      _displayedVendors.clear();
      if (startIndex < _vendorRevenues.length) {
        _displayedVendors.addAll(
          _vendorRevenues.sublist(
            startIndex,
            endIndex < _vendorRevenues.length ? endIndex : _vendorRevenues.length,
          ),
        );
      }
    });
  }

  void _nextPage() {
    if (_currentPage * _vendorsPerPage < _vendorRevenues.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedVendors();
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateDisplayedVendors();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vendor Revenue',
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
            : _vendorRevenues.isEmpty
      ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No Revenue Data Available',
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
    label: Text('Vendor Name',
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
    label: Text('Total Revenue',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    DataColumn(
    label: Text('This Month',
    style: TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold))),
    ],
    rows: _displayedVendors.map((vendor) {
    return DataRow(
    cells: [
    DataCell(Text(vendor['srNo'].toString(),
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins'))),
    DataCell(Text(vendor['vendorName'],
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins'))),
    DataCell(Text(vendor['businessName'],
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins'))),
    DataCell(
    Text(
    '\$${NumberFormat('#,##0').format(vendor['totalRevenue'])}',
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins'))),
    DataCell(
    Text(
    '\$${NumberFormat('#,##0').format(vendor['thisMonth'])}',
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins'))),
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
    color: _currentPage > 1
    ? const Color(0xFFFF4A49)
        : Colors.grey,
    ),
    Text(
    'Page $_currentPage of ${(_vendorRevenues.length / _vendorsPerPage).ceil()}',
    style: const TextStyle(
    fontSize: 15,
    fontFamily: 'Poppins',
    ),
    ),
    IconButton(
    icon: const Icon(Icons.arrow_forward_ios, size: 16),
    onPressed: _nextPage,
    color: _currentPage * _vendorsPerPage <
    _vendorRevenues.length
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