import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../consts/app_colors.dart';
import '../databases/database.dart';

class AllCustomers extends StatefulWidget {
  const AllCustomers({super.key});

  @override
  State<AllCustomers> createState() => _AllCustomersState();
}

class _AllCustomersState extends State<AllCustomers> {
  final TextEditingController searchController = TextEditingController();
  List<Map> customers = [];
  List<Map> filteredCustomers = [];
  final cashHistoryBox =
  Hive.isBoxOpen('cashHistory') ? Hive.box<Map>('cashHistory') : null;

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

  int _calculateBalance(String customerName) {
    int totalCashIn = 0;
    int totalCashOut = 0;

    final cashHistoryBox = this.cashHistoryBox;
    if (cashHistoryBox != null) {
      for (var record in cashHistoryBox.values) {
        if (record['name'] == customerName) {
          totalCashIn += (record['cash_in'] as int?) ?? 0;
          totalCashOut += (record['cash_out'] as int?) ?? 0;
        }
      }
    }

    return totalCashOut - totalCashIn;
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

  void _showEditDialog(Map customer) {
    final TextEditingController nameController =
    TextEditingController(text: customer['name']);
    final TextEditingController numberController =
    TextEditingController(text: customer['number']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.mainColor.withOpacity(0.9),
          title: Text(
            "Edit Customer Details",
            style: TextStyle(
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: AppColors.secondaryColor),
                cursorColor: AppColors.secondaryColor,
                decoration: InputDecoration(
                  labelText: "Customer Name",
                  labelStyle: TextStyle(color: AppColors.secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: numberController,
                style: TextStyle(color: AppColors.secondaryColor),
                cursorColor: AppColors.secondaryColor,
                decoration: InputDecoration(
                  labelText: "Customer Number",
                  labelStyle: TextStyle(color: AppColors.secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: AppColors.secondaryColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newNumber = numberController.text.trim();

                if (newName.isNotEmpty && newNumber.isNotEmpty) {
                  await HiveDatabaseHelper().updateCustomerDetails(
                    oldName: customer['name'],
                    newName: newName,
                    newNumber: newNumber,
                  );
                  await _fetchCustomers();
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                "Update",
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        title: const Text("All Customers"),
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Customer List",
              style: TextStyle(
                color: AppColors.secondaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
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
            const SizedBox(height: 20),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? const Center(
                child: Text(
                  "No customers found.",
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : ListView.builder(
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  final balance = _calculateBalance(customer['name']);

                  return Card(
                    color: AppColors.secondaryColor.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(
                        customer['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Number: ${customer['number']}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: SizedBox(
                        width: 105,
                        child: Row(

                          children: [
                            IconButton(
                              onPressed: () => _showEditDialog(customer),
                              icon: const Icon(Icons.edit, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              balance.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                balance < 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
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
    );
  }
}
