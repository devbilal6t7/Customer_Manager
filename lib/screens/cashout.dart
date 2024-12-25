import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../consts/app_colors.dart';

class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final TextEditingController customerSearchController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final FocusNode searchFocusNode = FocusNode();
  final FocusNode amountFocusNode = FocusNode();

  List<Map> customers = [];
  List<Map> filteredCustomers = [];
  String? selectedCustomer;
  int balance = 0;
  String selectedSubtype = 'Cash'; // Default subtype is "Cash"

  @override
  void initState() {
    super.initState();
    _fetchCustomers();

    // Set initial focus to the search field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocusNode);
    });
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

  Future<void> _fetchBalance(String customerName) async {
    final cashHistoryBox = Hive.isBoxOpen('cashHistory')
        ? Hive.box<Map>('cashHistory')
        : await Hive.openBox<Map>('cashHistory');

    int totalCashIn = 0;
    int totalCashOut = 0;

    for (var record in cashHistoryBox.values) {
      if (record['name'] == customerName) {
        totalCashIn += record['cash_in'] as int? ?? 0;
        totalCashOut += record['cash_out'] as int? ?? 0;
      }
    }

    setState(() {
      balance = totalCashOut - totalCashIn;
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

  void _showSubtypeOptions() {
    showModalBottomSheet(
      backgroundColor: AppColors.mainColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      context: context,
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            // Predefined subtypes
            ListTile(
              title: const Text("Concession",
                  style: TextStyle(color: Colors.white)),
              tileColor: AppColors.mainColor.withOpacity(0.5),
              onTap: () => _selectSubtype("Concession"),
            ),
            ListTile(
              title: const Text("JazzCash/EasyPaisa",
                  style: TextStyle(color: Colors.white)),
              tileColor: AppColors.mainColor.withOpacity(0.5),
              onTap: () => _selectSubtype("JazzCash/EasyPaisa"),
            ),
            ListTile(
              title: const Text("Check", style: TextStyle(color: Colors.white)),
              tileColor: AppColors.mainColor.withOpacity(0.5),
              onTap: () => _selectSubtype("Check"),
            ),
            ListTile(
              title:
                  const Text("Amanat", style: TextStyle(color: Colors.white)),
              tileColor: AppColors.mainColor.withOpacity(0.5),
              onTap: () => _selectSubtype("Amanat"),
            ),
            ListTile(
              title: const Text("By Other Bank",
                  style: TextStyle(color: Colors.white)),
              tileColor: AppColors.mainColor.withOpacity(0.5),
              onTap: () => _selectSubtype("By Other Bank"),
            ),
            // "Other" subtype tile
            ListTile(
              title: const Text(
                "Other",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              leading: Icon(Icons.add, color: AppColors.secondaryColor),
              tileColor: AppColors.secondaryColor.withOpacity(0.2),
              onTap: () {
                Navigator.pop(context); // Close the modal
                _showCustomSubtypeDialog(); // Open dialog for custom subtype
              },
            ),
          ],
        );
      },
    );
  }

  void _showCustomSubtypeDialog() {
    final TextEditingController customSubtypeController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.mainColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Center(
            child: Text(
              "تفصیل درج کریں",
              style: TextStyle(
                color: AppColors.secondaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'JameelNooriNastaleeqKasheeda',
                letterSpacing: 2,
              ),
            ),
          ),
          content: TextField(
            controller: customSubtypeController,
            cursorColor: AppColors.secondaryColor,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "اپنی تفصیل ٹائپ کریں۔",
              hintStyle: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'JameelNooriNastaleeqKasheeda',
                  letterSpacing: 2),
              filled: true,
              fillColor: AppColors.mainColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.secondaryColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.secondaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final customSubtype = customSubtypeController.text.trim();
                if (customSubtype.isNotEmpty) {
                  setState(() {
                    selectedSubtype = customSubtype; // Update selected subtype
                  });
                  Navigator.pop(context); // Close dialog
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _selectSubtype(String subtype) {
    setState(() {
      selectedSubtype = subtype;
    });
    Navigator.pop(context);
  }

  Future<void> _processCashOut() async {
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer")),
      );
      return;
    }
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount")),
      );
      return;
    }
    final amount = int.tryParse(amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    // Check if the last digit is zero
    if (amount % 10 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "براہ کرم رقم چیک کریں۔ آخری ہندسہ صفر ہونا ضروری ہے۔",
            style: TextStyle(
                fontSize: 16,
                fontFamily: 'JameelNooriNastaleeqKasheeda',
                letterSpacing: 2),
          ),
        ),
      );
      return;
    }

    final historyBox = Hive.box<Map>('cashHistory');
    await historyBox.add({
      'name': selectedCustomer,
      'cash_in': 0,
      'cash_out': amount,
      'subtype': selectedSubtype,
      'date': DateTime.now().toIso8601String(),
    });
    _fetchBalance(selectedCustomer!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Cash-Out of $amount added for $selectedCustomer (Subtype: $selectedSubtype)!"),
      ),
    );

    // Clear the input, reload balance, and shift focus back to search field
    setState(() {
      amountController.clear();
      customerSearchController.clear();
      FocusScope.of(context).requestFocus(searchFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        title: const Text(
          " مال/بل",
          style: TextStyle(
            fontFamily: 'JameelNooriNastaleeqKasheeda',
          ),
        ),
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: customerSearchController,
                focusNode: searchFocusNode,
                onChanged: _filterCustomers,
                autofocus: true,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "کسٹمر تلاش کریں۔",
                  hintStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'JameelNooriNastaleeqKasheeda',
                      letterSpacing: 2),
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
              selectedCustomer != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Selected: $selectedCustomer",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "   بقایا :     $balance",
                            style: TextStyle(
                                letterSpacing: 2,
                                fontFamily: 'JameelNooriNastaleeqKasheeda',
                                color: balance >= 0 ? Colors.green : Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    final isSelected = customer['name'] == selectedCustomer;
                    return ListTile(
                      title: Text(
                        customer['name'],
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.secondaryColor
                              : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      tileColor: isSelected
                          ? AppColors.secondaryColor.withOpacity(0.3)
                          : Colors.transparent,
                      onTap: () {
                        setState(() {
                          selectedCustomer = customer['name'];
                        });
                        _fetchBalance(customer['name']);
                        FocusScope.of(context).requestFocus(amountFocusNode);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                focusNode: amountFocusNode,
                keyboardType: TextInputType.number,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "  مال/بل کی رقم درج کریں۔ ",
                  hintStyle: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontFamily: 'JameelNooriNastaleeqKasheeda',
                  ),
                  filled: true,
                  fillColor: AppColors.secondaryColor.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedSubtype = "Cash";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      foregroundColor: Colors.white,
                      backgroundColor: selectedSubtype == "Cash"
                          ? Colors.green
                          : AppColors.secondaryColor,
                    ),
                    child: const Text("Cash"),
                  ),
                  ElevatedButton(
                    onPressed: _showSubtypeOptions,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      foregroundColor: Colors.white,
                      backgroundColor: selectedSubtype != "Cash"
                          ? Colors.green
                          : AppColors.secondaryColor,
                    ),
                    child: Text(
                        selectedSubtype != "Cash" ? selectedSubtype : "Other"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_money, color: Colors.white),
                label: const Text(
                  "Process مال/بل",
                  style: TextStyle(
                    letterSpacing: 2,
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'JameelNooriNastaleeqKasheeda',
                  ),
                ),
                onPressed: _processCashOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
