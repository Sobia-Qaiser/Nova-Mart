import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class AdminsalesreportOrderReportScreen extends StatefulWidget {
  const AdminsalesreportOrderReportScreen({Key? key}) : super(key: key);

  @override
  _AdminsalesreportOrderReportScreen createState() => _AdminsalesreportOrderReportScreen();
}

class _AdminsalesreportOrderReportScreen extends State<AdminsalesreportOrderReportScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  DateTimeRange? _selectedDateRange;
  final List<String> statusFilters = ['All', 'Pending', 'Processing', 'Delivered'];
  String selectedStatusFilter = 'All';
  int _currentPage = 1;
  final int _ordersPerPage = 10;
  String businessName = "Store";

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final snapshot = await _dbRef.child('orders').once();
      if (snapshot.snapshot.value == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final ordersMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> loadedOrders = [];

      ordersMap.forEach((orderId, orderData) {
        if (orderData['items'] != null) {
          final items = orderData['items'] as Map<dynamic, dynamic>;
          double orderTotal = 0.0;
          int itemCount = 0;
          List<Map<String, dynamic>> orderItems = [];

          items.forEach((itemId, itemData) {
            final price = (itemData['price'] ?? 0.0) as num;
            final quantity = (itemData['quantity'] ?? 1) as num;
            orderTotal += price * quantity;
            itemCount += quantity as int;

            orderItems.add({
              'name': itemData['name'] ?? 'Unknown Item',
              'price': price.toDouble(),
              'quantity': quantity.toInt(),
              'image': itemData['imageUrl'] ?? '',
            });
          });

          final orderStatus = orderData['status'] ?? 'Pending';
          final paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
          final orderNumber = orderData['orderNumber'] ?? '#00000';
          final createdAt = orderData['createdAt'] ?? 'Unknown Date';
          final deliveredAt = orderData['deliveredAt'] ?? 'Not Delivered';

          loadedOrders.add({
            'orderId': orderId,
            'orderNumber': orderNumber,
            'createdAt': createdAt,
            'formattedDate': _formatDate(createdAt),
            'status': orderStatus,
            'deliveredAt': deliveredAt,
            'paymentMethod': paymentMethod,
            'totalAmount': orderTotal,
            'earning': orderTotal * 0.95, // Keeping these calculations
            'commission': orderTotal * 0.05, // Keeping these calculations
            'items': orderItems,
            'itemCount': itemCount,
          });
        }
      });

      loadedOrders.sort((a, b) {
        final dateA = _parseDate(a['createdAt']);
        final dateB = _parseDate(b['createdAt']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading orders: $e");
      setState(() {
        isLoading = false;
      });
    }
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

  DateTime _parseDate(String dateString) {
    try {
      if (dateString.startsWith('Delivered on ')) {
        dateString = dateString.replaceFirst('Delivered on ', '');
      }
      return DateFormat('MMMM d, yyyy \'at\' h:mm a').parse(dateString);
    } catch (e) {
      try {
        return DateFormat('d MMMM yyyy, h:mm a').parse(dateString);
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final matchesStatus = selectedStatusFilter == 'All' ||
          order['status'].toString().toLowerCase() == selectedStatusFilter.toLowerCase();

      if (_selectedDateRange == null) return matchesStatus;

      final orderDate = _parseDate(order['createdAt']);
      return matchesStatus &&
          (orderDate.isAfter(_selectedDateRange!.start) ||
              orderDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
          (orderDate.isBefore(_selectedDateRange!.end) ||
              orderDate.isAtSameMomentAs(_selectedDateRange!.end));
    }).toList();
  }

  List<Map<String, dynamic>> get _displayedOrders {
    final startIndex = (_currentPage - 1) * _ordersPerPage;
    final endIndex = startIndex + _ordersPerPage;

    if (startIndex < filteredOrders.length) {
      return filteredOrders.sublist(
        startIndex,
        endIndex < filteredOrders.length ? endIndex : filteredOrders.length,
      );
    }
    return [];
  }

  void _nextPage() {
    if (_currentPage * _ordersPerPage < filteredOrders.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFFF4A49),
              onPrimary: Colors.white,
              surface: isDark ? Colors.grey[850]! : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: isDark ? Colors.grey[900] : Colors.white,
            textTheme: Theme.of(context).textTheme.copyWith(
              titleSmall: const TextStyle(fontSize: 14),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _currentPage = 1;
      });
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pw.ImageProvider? logoImage;
    try {
      final logo = await rootBundle.load('assets/images/logo3.png');
      logoImage = pw.MemoryImage(logo.buffer.asUint8List());
    } catch (e) {
      debugPrint("Could not load logo: $e");
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(logoImage),
                  ),
                if (logoImage != null) pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Sales Report', style: pw.TextStyle(fontSize: 18)),
                      if (_selectedDateRange != null)
                        pw.Text(
                          'Date Range: ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      if (selectedStatusFilter != 'All')
                        pw.Text(
                          'Status: $selectedStatusFilter',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      pw.Text('Generated on ${DateFormat.yMMMMd().format(DateTime.now())}'),
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Order #', 'Date', 'Status', 'Items', 'Total', 'Amount to Pay', 'Commission'],
              data: filteredOrders.map((order) => [
                order['orderNumber'],
                DateFormat('MMM d, yyyy').format(_parseDate(order['createdAt'])),
                order['status'],
                order['itemCount'].toString(),
                '\$${(order['totalAmount'] as num).toInt()}',
                '\$${(order['earning'] as num).toInt()}',
                '\$${(order['commission'] as num).toInt()}',
              ]).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFF4A49),
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Orders: ${filteredOrders.length}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Delivered Orders: ${filteredOrders.where((order) => order['status'].toString().toLowerCase() == 'delivered').length}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Total Amount to Pay: \$${_calculateTotalEarnings().toInt()}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Total Commission: \$${_calculateTotalCommission().toInt()}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  double _calculateTotalEarnings() {
    return filteredOrders.where((order) => order['status'].toString().toLowerCase() == 'delivered')
        .fold(0.0, (sum, order) => sum + order['earning']);
  }

  double _calculateTotalCommission() {
    return filteredOrders.where((order) => order['status'].toString().toLowerCase() == 'delivered')
        .fold(0.0, (sum, order) => sum + order['commission']);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final scaffoldBgColor = isDark ? Colors.grey[900] : Colors.white;
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF4A49),
        centerTitle: true,
        title: const Text(
          'Sales Report',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generatePdf,
          ),
        ],
      ),
      backgroundColor: scaffoldBgColor,
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF4A49)),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatusFilter,
                    decoration: InputDecoration(
                      labelText: 'Filter by Status',
                      labelStyle: TextStyle(color: const Color(0xFFFF4A49)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: Color(0xFFFF4A49)),
                      ),
                    ),
                    dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                    style: TextStyle(color: textColor),
                    items: statusFilters.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatusFilter = newValue!;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  color: const Color(0xFFFF4A49),
                  onPressed: () => _selectDateRange(context),
                ),
              ],
            ),
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                    style: TextStyle(color: textColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: textColor),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                        _currentPage = 1;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (filteredOrders.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No orders found',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
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
                        color: cardBgColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.resolveWith<Color>(
                                (states) => const Color(0xFFFF4A49).withOpacity(0.1)),
                        columnSpacing: 30,
                        horizontalMargin: 20,
                        dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                            if (isDark) {
                              return states.contains(MaterialState.hovered)
                                  ? Colors.grey[800]
                                  : Colors.grey[900];
                            }
                            return null;
                          },
                        ),
                        columns: [
                          DataColumn(
                              label: Center(
                                  child: Text('Order #',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                              label: Center(
                                  child: Text('Date',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                              label: Center(
                                  child: Text('Items',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                              label: Center(
                                  child: Text('Status',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                              label: Center(
                                  child: Text('Payment',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                              label: Center(
                                  child: Text('Total',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                              label: Center(
                                  child: Text('Amount to Pay',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                              label: Center(
                                  child: Text('Commission',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                        ],
                        rows: _displayedOrders.map((order) {
                          return DataRow(
                            cells: [
                              DataCell(Center(
                                child: Text(order['orderNumber'],
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text(order['formattedDate'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text(order['itemCount'].toString(),
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text(order['status'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                      color: _getStatusColor(order['status']),
                                      fontWeight: FontWeight.bold,
                                    )),
                              )),
                              DataCell(Center(
                                child: Text(order['paymentMethod'],
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text('\$${(order['totalAmount'] as num).toInt()}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text('\$${(order['earning'] as num).toInt()}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text('\$${(order['commission'] as num).toInt()}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (filteredOrders.isNotEmpty) ...[
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
                    'Page $_currentPage of ${(filteredOrders.length / _ordersPerPage).ceil()}',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _nextPage,
                    color: _currentPage * _ordersPerPage < filteredOrders.length
                        ? const Color(0xFFFF4A49)
                        : Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}