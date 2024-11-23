import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../consts/app_colors.dart';

class AddCustomerScreen extends StatelessWidget {
  const AddCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController numberController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.mainColor,
        title: const Text("Add Customer"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Add Customer",
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "Enter customer name",
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
              TextField(
                controller: numberController,
                cursorColor: Colors.white,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Enter customer number",
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
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  "Add Customer",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () async {
                  final String name = nameController.text;
                  final String number = numberController.text;

                  if (name.isEmpty || number.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  final customersBox = Hive.isBoxOpen('customers')
                      ? Hive.box<Map>('customers')
                      : await Hive.openBox<Map>('customers');

                  await customersBox.add({
                    'name': name,
                    'number': number,
                    'cash_in': 0,
                    'cash_out': 0,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Customer $name added!")),
                  );

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
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
