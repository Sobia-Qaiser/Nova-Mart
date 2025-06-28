import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class RecommendationReportScreen extends StatefulWidget {
  final String vendorId;

  const RecommendationReportScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _RecommendationReportScreenState createState() => _RecommendationReportScreenState();
}

class _RecommendationReportScreenState extends State<RecommendationReportScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> recommendations = [];
  bool isLoading = true;
  final List<String> statusFilters = ['All', 'Low', 'Medium', 'High'];
  String selectedStatusFilter = 'All';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String businessName = "Store";

  @override
  void initState() {
    super.initState();
    _loadVendorData();
    _loadRecommendations();
  }

  Future<void> _loadVendorData() async {
    try {
      final vendorSnapshot = await _dbRef.child('users').child(widget.vendorId).once();
      if (vendorSnapshot.snapshot.value != null) {
        final vendorData = vendorSnapshot.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          businessName = vendorData['businessName']?.toString() ?? "Store";
        });
      }
    } catch (e) {
      debugPrint("Error loading vendor data: $e");
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final snapshot = await _dbRef.child('recommendedPackages').child(widget.vendorId).once();

      if (snapshot.snapshot.value == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> loadedRecommendations = [];

      data.forEach((packageId, packageData) {
        if (packageData is Map<dynamic, dynamic>) {
          loadedRecommendations.add({
            'srNo': loadedRecommendations.length + 1,
            'baseProduct': _formatProducts(packageData['baseProduct'], vertical: true),
            'recommendedProduct': _formatProducts(packageData['recommendedProduct'], vertical: true),
            'confidence': packageData['confidencePercent']?.toString() ?? '0%',
            'status': packageData['status']?.toString() ?? 'Unknown',
          });
        }
      });

      setState(() {
        recommendations = loadedRecommendations;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading recommendations: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatProducts(dynamic products, {bool vertical = false}) {
    List<String> items = [];

    if (products is List) {
      items = List<String>.from(products.map((e) => e.toString()));
    } else if (products is Map) {
      items = List<String>.from(products.values.map((e) => e.toString()));
    } else if (products is String) {
      items = [products];
    }

    if (vertical) {
      if (items.length == 1) {
        return items.first; // Just return without comma
      }
      return items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        return isLast ? entry.value : '${entry.value},';
      }).join('\n');
    } else {
      return items.join(', ');
    }
  }





  List<Map<String, dynamic>> get filteredRecommendations {
    return recommendations.where((rec) {
      return selectedStatusFilter == 'All' ||
          rec['status'].toString().toLowerCase() == selectedStatusFilter.toLowerCase();
    }).toList();
  }

  List<Map<String, dynamic>> get _displayedRecommendations {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex < filteredRecommendations.length) {
      return filteredRecommendations.sublist(
        startIndex,
        endIndex < filteredRecommendations.length ? endIndex : filteredRecommendations.length,
      );
    }
    return [];
  }

  void _nextPage() {
    if (_currentPage * _itemsPerPage < filteredRecommendations.length) {
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
                      pw.Text('Recommended Packages Report', style: pw.TextStyle(fontSize: 18)),
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

            /// 👇 Table with Correct Serial Numbers
            pw.Table.fromTextArray(
              headers: ['Sr#', 'Base Product', 'Recommended Product', 'Chance to Buy', 'Status'],
              data: List.generate(filteredRecommendations.length, (i) {
                final rec = filteredRecommendations[i];
                return [
                  (i + 1).toString(),
                  rec['baseProduct'],
                  rec['recommendedProduct'],
                  rec['confidence'],
                  rec['status'],
                ];
              }),
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
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
            ),

          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
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
          'Recommended Packages',
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
          if (filteredRecommendations.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No recommendations found',
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
                        headingRowColor:
                        MaterialStateProperty.resolveWith<Color>(
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
                                  child: Text('Sr#',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: textColor)))),
                          DataColumn(
                            label: Padding(
                              padding: const EdgeInsets.only(left: 40), // Adjust value as needed
                              child: Text(
                                'Base Product',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),


                          DataColumn(
                            label: Center(
                              child: Text(
                                'Recommended Product',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),

                          DataColumn(
                              label: Center(
                                  child: Text('Chance to Buy',
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
                        ],
                        rows: _displayedRecommendations.map((rec) {
                          return DataRow(
                            cells: [
                              DataCell(Center(
                                child: Text(rec['srNo'].toString(),
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text(rec['baseProduct'],
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text(rec['recommendedProduct'],
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text(rec['confidence'],
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        color: textColor)),
                              )),
                              DataCell(Center(
                                child: Text(rec['status'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                      color: _getStatusColor(rec['status']),
                                      fontWeight: FontWeight.bold,
                                    )),
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
          if (filteredRecommendations.isNotEmpty) ...[
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
                    'Page $_currentPage of ${(filteredRecommendations.length / _itemsPerPage).ceil()}',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _nextPage,
                    color: _currentPage * _itemsPerPage < filteredRecommendations.length
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