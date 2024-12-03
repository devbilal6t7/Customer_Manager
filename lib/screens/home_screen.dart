import 'package:customer_manager/consts/app_colors.dart';
import 'package:customer_manager/screens/lock_screen.dart';
import 'package:customer_manager/screens/today_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../main.dart';
import 'add_customer.dart';
import 'all_customers.dart';
import 'cashIn.dart';
import 'cashOut.dart';
import 'history.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int totalCashIn = 0;
  int totalCashOut = 0;
  int balance = 0;
  DateTime? selectedDate;

  final _cashHistoryBox = Hive.box<Map>('cashHistory');

  @override
  void initState() {
    super.initState();
    _fetchTotalsForDate(selectedDate ?? DateTime.now());
  }

  Future<void> _fetchTotalsForDate(DateTime date) async {
    int cashIn = 0;
    int cashOut = 0;

    for (var record in _cashHistoryBox.values) {
      // Ensure record contains valid data
      if (record.containsKey('date')) {
        try {
          DateTime recordDate = DateTime.parse(record['date'] as String);

          if (recordDate.year == date.year &&
              recordDate.month == date.month &&
              recordDate.day == date.day) {
            cashIn += (record['cash_in'] as int?) ?? 0;
            cashOut += (record['cash_out'] as int?) ?? 0;
          }
        } catch (e) {
          debugPrint("Invalid date in record: $e");
        }
      }
    }

    setState(() {
      totalCashIn = cashIn;
      totalCashOut = cashOut;
      balance = cashOut - cashIn;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondaryColor,
              onPrimary: AppColors.mainColor,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryColor,
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await _fetchTotalsForDate(picked);
    }
  }

  void didPopNext() {
    // This method will be triggered when returning to this screen.
    _fetchTotalsForDate(selectedDate ?? DateTime.now());
    super.didPopNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the RouteObserver
    MyApp.routeObserver
        .subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    // Unsubscribe from the RouteObserver
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = selectedDate ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: Row(
        children: [
          _buildSidebar(),
          Container(
            width: 2,
            color: Colors.white,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Overview",
                        style: TextStyle(
                          color: AppColors.secondaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LockScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.date_range, color: Colors.white),
                        label: Text(
                          "Selected Date: ${currentDate.toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _fetchTotalsForDate(selectedDate ?? DateTime.now());
                        },
                        icon: const Icon(Icons.refresh,color: Colors.white,),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryCard(
                          " وصول", "$totalCashIn", AppColors.secondaryColor),
                      _buildSummaryCard(
                        " بقایا",
                        "$balance",
                        balance >= 0 ? Colors.green : Colors.yellow,
                      ),
                      _buildSummaryCard(
                          " مال/بل", "$totalCashOut", Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        " وصول",
                        const CashInScreen(),
                        AppColors.secondaryColor,
                        Colors.white,
                      ),
                      _buildActionButton(
                        context,
                        " مال/بل",
                        const CashOutScreen(),
                        Colors.redAccent,
                        Colors.white,
                      ),
                    ],
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
      color: AppColors.mainColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            color: AppColors.secondaryColor,
            alignment: Alignment.center,
            child: Text(
              "Customer Manager   کسٹمر مینیجر",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mainColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.white),
                  title: const Text(
                    "History    تاریخ  ",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.white),
                  title: const Text(
                    "Add Customer",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCustomerScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.man, color: Colors.white),
                  title: const Text(
                    "All Customers  گاہک",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllCustomers(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text(
                    "Today Entries",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TodayEntriesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainColor,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, Widget screen,
      Color color, Color foreground) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
        if (result == true) {
          await _fetchTotalsForDate(selectedDate ?? DateTime.now());
        }
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: color,
      ),
      child: Text(
        title,
        style: TextStyle(color: AppColors.mainColor, fontSize: 16),
      ),
    );
  }
}
