import 'package:flutter/material.dart';
import 'package:customer_manager/databases/database.dart';
import '../consts/app_colors.dart';

class DefaulterListScreen extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> defaultersFuture;

  const DefaulterListScreen({super.key, required this.defaultersFuture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.secondaryColor,
        title: const Text(
          'Defaulter List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: defaultersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.secondaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No defaulters found.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final defaulters = snapshot.data!;
          return ListView.builder(
            itemCount: defaulters.length,
            itemBuilder: (context, index) {
              final customer = defaulters[index];
              final customerName = customer['name'];
              final customerNumber = customer['number'];

              return FutureBuilder<int>(
                future: HiveDatabaseHelper().getCustomerBalance(customerName),
                builder: (context, balanceSnapshot) {
                  if (balanceSnapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        tileColor: AppColors.secondaryColor.withOpacity(0.2),
                        title: Text(
                          customerName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          customerNumber,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: CircularProgressIndicator(color: AppColors.secondaryColor),
                      ),
                    );
                  }

                  final balance = balanceSnapshot.data ?? 0;
                  final balanceColor = balance >= 0 ? Colors.green : Colors.red;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      tileColor: AppColors.secondaryColor.withOpacity(0.2),
                      title: Text(
                        customerName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            'Contact: $customerNumber ',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Balance: ${balance.toString()} ',
                              style: TextStyle(
                                color: balanceColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),

                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
