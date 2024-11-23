import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../consts/app_colors.dart';

class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final TextEditingController customerSearchController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<Map> customers = [];
  List<Map> filteredCustomers = [];
  String? selectedCustomer;
  int balance = 0;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    // Ensure the box is open
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

    // Update balance
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        title: const Text("Cash Out"),
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Cash Out",
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: customerSearchController,
                onChanged: _filterCustomers,
                cursorColor: Colors.white,
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
              selectedCustomer != null
                  ? Column(
                children: [
                  Text(
                    "Selected: $selectedCustomer",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Balance: $balance",
                    style: TextStyle(
                      color: balance >= 0 ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
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
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "Enter cash-out amount",
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
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_money, color: Colors.white),
                label: const Text(
                  "Process Cash-Out",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () async {
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

                  final historyBox = Hive.box<Map>('cashHistory');
                  await historyBox.add({
                    'name': selectedCustomer,
                    'cash_in': 0,
                    'cash_out': amount,
                    'date': DateTime.now().toIso8601String(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Cash-Out of $amount added for $selectedCustomer!",
                        ),
                    ),
                  );

                  Navigator.pop(context, true);
                },
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
