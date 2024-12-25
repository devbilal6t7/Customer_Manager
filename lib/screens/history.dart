import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../consts/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController customerSearchController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  String? selectedCustomer;
  DateTime? fromDate;
  DateTime? toDate;
  List<Map> customers = [];
  List<Map> filteredCustomers = [];
  List<Map> historyList = [];
  List<Map> transactionsWithBalance = [];
  int totalCashIn = 0;
  int totalCashOut = 0;
  int runningBalance = 0;
 int? selectedCustomerIndex;
  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final customersBox = Hive.isBoxOpen('customers')
        ? Hive.box<Map>('customers')
        : await Hive.openBox<Map>('customers');

    setState(() {
      customers = customersBox.values.toList();
      filteredCustomers = customers;
    });
  }

  Future<void> _fetchHistory(String customerName, {DateTime? from, DateTime? to}) async {
    final historyBox = Hive.isBoxOpen('cashHistory')
        ? Hive.box<Map>('cashHistory')
        : await Hive.openBox<Map>('cashHistory');

    setState(() {
      historyList = historyBox.values
          .where((entry) {
        final entryDate = DateTime.tryParse(entry['date']);
        if (entryDate == null) return false; // Skip invalid dates

        // If dates are not provided, fetch all history
        if (from == null && to == null) {
          return entry['name'] == customerName;
        }

        // Otherwise, filter based on date range
        final withinFrom = from == null || entryDate.isAfter(from.subtract(const Duration(days: 1)));
        final withinTo = to == null || entryDate.isBefore(to.add(const Duration(days: 1)));
        return entry['name'] == customerName && withinFrom && withinTo;
      }).toList();

      _calculateTransactionsWithBalance();
    });
  }


  void _calculateTransactionsWithBalance() {
    totalCashIn = 0;
    totalCashOut = 0;
    runningBalance = 0;

    transactionsWithBalance = historyList.map((record) {
      final cashIn = record['cash_in'] ?? 0;
      final cashOut = record['cash_out'] ?? 0;

      // Update totals
      totalCashIn += cashIn as int;
      totalCashOut += cashOut as int;

      // Calculate running balance
      runningBalance += cashOut - cashIn;

      return {
        ...record,
        'balance': runningBalance,
      };
    }).toList();
  }

  void _showDatePicker(TextEditingController controller, ValueChanged<DateTime?> onDateSelected) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      controller.text = "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";
      onDateSelected(selectedDate);
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers
            .where((customer) =>
            customer['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'JameelNooriNastaleeqKasheeda',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: textColor ?? Colors.white,

        ),
      ),
    );
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
  }
  Future<void> _exportData() async {
    if (selectedCustomer == null || historyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data available to export!")),
      );
      return;
    }

    final urduFont = pw.Font.ttf(await rootBundle.load("assets/fonts/JameelNooriNastaleeqKasheeda.ttf"));
    final pdf = pw.Document();

    int runningBalance = 0;
    int totalCashIn = 0;
    int totalCashOut = 0;
    int totalBalance = 0; // NEW: To calculate sum of all balances

    // Calculate transaction data and totals
    final transactionsWithBalance = historyList.map((record) {
      final cashIn = record['cash_in'] ?? 0;
      final cashOut = record['cash_out'] ?? 0;

      // Update running balance for this transaction
      runningBalance += (cashOut - cashIn as num).toInt();

      // Add to totals
      totalCashIn += (cashIn as num).toInt();
      totalCashOut += (cashOut as num).toInt();
      totalBalance += runningBalance; // Sum of all balance values

      return {
        'date': record['date'],
        'cash_in': cashIn,
        'cash_out': cashOut,
        'subtype': record['subtype'] ?? 'نقد',
        'balance': runningBalance,
      };
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Title
                pw.Text(
                  "Customer's Detailed History Report",
                  style: pw.TextStyle(font: urduFont, fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                // Customer Name
                pw.Text("Name: $selectedCustomer", style: pw.TextStyle(font: urduFont, fontSize: 16)),
                pw.SizedBox(height: 16),
                // Table
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(100),
                    1: const pw.FixedColumnWidth(70),
                    2: const pw.FixedColumnWidth(70),
                    3: const pw.FixedColumnWidth(100),
                    4: const pw.FixedColumnWidth(100),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCellPDF('Baqaya', urduFont),
                        _buildTableCellPDF('Tafseel', urduFont),
                        _buildTableCellPDF('Wasool', urduFont),
                        _buildTableCellPDF('Bill', urduFont),
                        _buildTableCellPDF('Date', urduFont),

                      ],
                    ),
                    // Table Rows for Transactions
                    ...transactionsWithBalance.map((record) {
                      return pw.TableRow(
                        children: [
                          _buildTableCellPDF((record['balance'].toString()), urduFont),
                          _buildTableCellPDF(record['subtype'].toString(), urduFont),
                          _buildTableCellPDF(record['cash_in'].toString(), urduFont),
                          _buildTableCellPDF(record['cash_out'].toString(), urduFont),
                          _buildTableCellPDF(_formatDate(record['date']), urduFont),
                        ],
                      );
                    }).toList(),
                    // Final Row for Totals
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableCellPDF(totalBalance.toString(), urduFont),
                        _buildTableCellPDF("-", urduFont),// Total Label // Total Cash Out
                        _buildTableCellPDF(totalCashIn.toString(), urduFont), // Total Cash In
                        _buildTableCellPDF(totalCashOut.toString(), urduFont),
                        _buildTableCellPDF("Total", urduFont),// Empty for Subtype
                         // Sum of all balances
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

// Helper Function to Build Table Cell
  pw.Widget _buildTableCellPDF(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Row(
        children: [
          _buildSidebar(),
          Container(width: 2, color: Colors.white),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Center(
                        child: Text(
                          "Transaction History",
                          style: TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fromDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefix: const Text("From :   ", style: TextStyle(color: Colors.white)),
                            suffixIcon: Icon(Icons.calendar_month, color: AppColors.white),
                            hintText: "Select From Date",
                            hintStyle: TextStyle(color: AppColors.secondaryColor),
                            filled: true,
                            fillColor: AppColors.mainColor.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: AppColors.secondaryColor),
                          onTap: () => _showDatePicker(fromDateController, (date) {
                            setState(() => fromDate = date);
                            if (selectedCustomer != null && toDate != null) {
                              _fetchHistory(selectedCustomer!, from: fromDate, to: toDate);
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: toDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefix: const Text("To :   ", style: TextStyle(color: Colors.white)),
                            suffixIcon: Icon(Icons.date_range, color: AppColors.white),
                            hintText: "To Date",
                            hintStyle: TextStyle(color: AppColors.secondaryColor),
                            filled: true,
                            fillColor: AppColors.mainColor.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: AppColors.secondaryColor),
                          onTap: () => _showDatePicker(toDateController, (date) {
                            setState(() => toDate = date);
                            if (selectedCustomer != null && fromDate != null) {
                              _fetchHistory(selectedCustomer!, from: fromDate, to: toDate);
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: customerSearchController,
                    onChanged: _filterCustomers,
                    decoration: InputDecoration(
                      hintText: "Search Customer",
                      hintStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isSelected = selectedCustomerIndex == index;

                        return ListTile(
                          leading: Text(
                            '${index + 1}.',
                            style: TextStyle(color: isSelected ? Colors.yellow : Colors.white),
                          ),
                          title: Text(
                            customer['name'],
                            style: TextStyle(color: isSelected ? Colors.yellow : Colors.white),
                          ),
                          tileColor: isSelected ? Colors.blueGrey[700] : Colors.transparent,
                          onTap: () {
                            setState(() {
                              selectedCustomerIndex = index;
                              selectedCustomer = customer['name'];
                              fromDateController.clear();
                              toDateController.clear();
                              fromDate = null;
                              toDate = null;
                            });
                            _fetchHistory(customer['name']);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selectedCustomer != null)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(color: Colors.white, width: 1),
                            columnWidths: const {
                              0: FixedColumnWidth(100),
                              1: FixedColumnWidth(80),
                              2: FixedColumnWidth(80),
                              3: FixedColumnWidth(100),
                              4: FixedColumnWidth(80),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey[800]),
                                children: [
                                  _buildTableHeader("بقایا"),
                                  _buildTableHeader("تفصیل"),
                                  _buildTableHeader("وصول"),
                                  _buildTableHeader("بل"),
                                  _buildTableHeader("تاریخ"),
                                ],
                              ),
                              ...transactionsWithBalance.map((record) {
                                return TableRow(
                                  children: [
                                    _buildTableCell(record['balance'].toString()), // Convert balance to String
                                    _buildTableCell(record['subtype'] ?? 'نقد'),
                                    _buildTableCell(record['cash_in'].toString()), // Convert cash_in to String
                                    _buildTableCell(record['cash_out'].toString()), // Convert cash_out to String
                                    _buildTableCell(_formatDate(record['date'])),
                                  ],
                                );
                              }).toList(),
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey[800]),
                                children: [
                                  _buildTableCell(runningBalance.toString()),
                                  _buildTableCell("-"),
                                  _buildTableCell(totalCashIn.toString()),

                                  _buildTableCell(totalCashOut.toString()),
                                  _buildTableCell("ٹوٹل"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppColors.secondaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            color: AppColors.secondaryColor,
            alignment: Alignment.center,
            child: Text(
              "Customer Manager",
              style: TextStyle(
                color: AppColors.mainColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
            title: const Text(
              "Export Data",
              style: TextStyle(color: Colors.white),
            ),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.white),
            title: const Text(
              "Export Database",
              style: TextStyle(color: Colors.white),
            ),
            onTap: _exportDatabase,
          ),
          ListTile(
            leading: const Icon(Icons.file_upload, color: Colors.white),
            title: const Text(
              "Import Database",
              style: TextStyle(color: Colors.white),
            ),
            onTap: _importDatabase,
          ),
        ],
      ),
    );
  }
  Future<void> _exportDatabase() async {
    try {
      final file = await FilePicker.platform.saveFile(
        dialogTitle: "Save Database Export",
        fileName: "database_export.json",
      );

      if (file == null) return;

      final List<String> boxNames = ['customers', 'cashHistory', 'userCredentials'];

      final Map<String, dynamic> data = {};
      for (var boxName in boxNames) {
        var box = Hive.box<Map>(boxName);

        data[boxName] = box.toMap().map((key, value) {
          return MapEntry(
            key.toString(),
            _makeJsonEncodable(value),
          );
        });
      }

      final jsonString = jsonEncode(data);
      await File(file).writeAsString(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Database exported successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to export database: $e")),
      );
    }
  }

  dynamic _makeJsonEncodable(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _makeJsonEncodable(val)));
    } else if (value is List) {
      return value.map((item) => _makeJsonEncodable(item)).toList();
    } else if (value is DateTime) {
      return value.toIso8601String();
    } else if (value is num || value is String || value is bool || value == null) {
      return value;
    } else {
      return value.toString();
    }
  }

  Future<void> _importDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      for (var boxName in data.keys) {
        var box = Hive.isBoxOpen(boxName)
            ? Hive.box<Map>(boxName)
            : await Hive.openBox<Map>(boxName);

        await box.clear();

        final formattedData = (data[boxName] as Map<String, dynamic>).map((key, value) {
          return MapEntry(key, Map<dynamic, dynamic>.from(value));
        });

        await box.putAll(formattedData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Database imported successfully!")),
      );

      await _fetchCustomers();
      setState(() {
        selectedCustomer = null;
        historyList = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to import database: $e")),
      );
    }
  }


}
