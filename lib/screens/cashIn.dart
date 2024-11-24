import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../consts/app_colors.dart';

class CashInScreen extends StatefulWidget {
  const CashInScreen({super.key});

  @override
  State<CashInScreen> createState() => _CashInScreenState();
}

class _CashInScreenState extends State<CashInScreen> {
  final TextEditingController customerSearchController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<Map> customers = [];
  List<Map> filteredCustomers = [];
  String? selectedCustomer;
  String selectedSubtype = 'Cash'; // Default subtype is "Cash"

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
      context: context,
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text("Concession"),
              onTap: () => _selectSubtype("Concession"),
            ),
            ListTile(
              title: const Text("JazzCash/EasyPaisa"),
              onTap: () => _selectSubtype("JazzCash/EasyPaisa"),
            ),
            ListTile(
              title: const Text("Check"),
              onTap: () => _selectSubtype("Check"),
            ),
            ListTile(
              title: const Text("Amanat"),
              onTap: () => _selectSubtype("Amanat"),
            ),
            ListTile(
              title: const Text("By Other Bank"),
              onTap: () => _selectSubtype("By Other Bank"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        title: const Text("Cash In"),
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
                "Cash In",
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
              if (selectedCustomer != null)
                Text(
                  "Selected: $selectedCustomer",
                  style: const TextStyle(color: Colors.white),
                ),
              const SizedBox(height: 20),
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
                          : AppColors.secondaryColor.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          selectedCustomer = customer['name'];
                        });
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
                  hintText: "Enter cash-in amount",
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
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      backgroundColor: selectedSubtype != "Cash"
                          ? Colors.green
                          : AppColors.secondaryColor,
                    ),
                    child:  Text(
                      selectedSubtype != "Cash"
                        ? selectedSubtype
                        : "Other",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_money, color: Colors.white),
                label: const Text(
                  "Process Cash-In",
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
                    'cash_in': amount,
                    'cash_out': 0,
                    'subtype': selectedSubtype,
                    'date': DateTime.now().toIso8601String(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Cash-In of $amount added for $selectedCustomer (Subtype: $selectedSubtype)!"),
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
