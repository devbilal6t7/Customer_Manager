import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../consts/app_colors.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController customerSearchController = TextEditingController();

  String? selectedCustomer;
  List<Map> customers = [];
  List<Map> filteredCustomers = [];
  List<Map> historyList = [];

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

  Future<void> _fetchHistory(String customerName) async {
    final historyBox = Hive.isBoxOpen('cashHistory')
        ? Hive.box<Map>('cashHistory')
        : await Hive.openBox<Map>('cashHistory');

    setState(() {
      historyList = historyBox.values
          .where((entry) => entry['name'] == customerName)
          .toList();
    });
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

  Future<void> _exportData() async {
    if (selectedCustomer == null || historyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data available to export!")),
      );
      return;
    }

    final pdf = pw.Document();

    // Calculate running balance for each transaction
    int runningBalance = 0;
    final transactionsWithBalance = historyList.map((record) {
      final cashIn = record['cash_in'] ?? 0;
      final cashOut = record['cash_out'] ?? 0;
      runningBalance = cashIn - cashOut;
      return {
        'date': record['date'],
        'cash_in': cashIn,
        'cash_out': cashOut,
        'subtype': record['subtype'] ?? 'Cash',
        'balance': runningBalance,
      };
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Customer Transaction Report",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Text("Customer Name: $selectedCustomer"),
              pw.SizedBox(height: 16),
              pw.Text("Transaction Details:"),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Date', 'CashIn', 'CashOut', 'Subtype', 'Balance'],
                data: transactionsWithBalance.map((record) {
                  return [
                    _formatDate(record['date']),
                    record['cash_in'].toString(),
                    record['cash_out'].toString(),
                    record['subtype'],
                    record['balance'].toString(),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
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

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
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
                  TextField(
                    controller: customerSearchController,
                    onChanged: _filterCustomers,
                    cursorColor: Colors.white,
                    autofocus: true, // Enable autofocus
                    decoration: InputDecoration(
                      hintText: "Search Customer",
                      hintStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: AppColors.secondaryColor.withOpacity(0.2),
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
                        return ListTile(
                          title: Text(
                            customer['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          // tileColor: AppColors.secondaryColor.withOpacity(0.2),
                          onTap: () {
                            setState(() {
                              selectedCustomer = customer['name'];
                            });
                            _fetchHistory(customer['name']);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selectedCustomer != null)
                    Text(
                      "History for $selectedCustomer",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: historyList.isEmpty
                        ? const Center(
                      child: Text(
                        "No transactions found.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                        : ListView.builder(
                      itemCount: historyList.length,
                      itemBuilder: (context, index) {
                        final record = historyList[index];
                        final isCashIn =
                        (record['cash_in'] != null && record['cash_in'] > 0);
                        final subtitleText = isCashIn
                            ? "وصول : ${record['cash_in']}"
                            : "مال/بل : ${record['cash_out']}";
                        final subtypeText = record['subtype'] ?? 'Cash';
                        int balance = 0;
                        for (int i = 0; i <= index; i++) {
                          final currentRecord = historyList[i];
                          balance += (currentRecord['cash_in'] as int? ?? 0);
                          balance -= (currentRecord['cash_out'] as int? ?? 0);
                        }

                        return Card(
                          color: AppColors.secondaryColor.withOpacity(0.1),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(
                              "Date: ${_formatDate(record['date'])}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  "$subtitleText ",
                                  style: TextStyle(
                                    color: isCashIn ? Colors.red : Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                Text(
                                  " || بقایا : $balance ",
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              subtypeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
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
}
