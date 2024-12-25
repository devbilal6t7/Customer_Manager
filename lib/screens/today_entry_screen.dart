import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../consts/app_colors.dart';
import '../databases/database.dart';

class TodayEntriesScreen extends StatefulWidget {
  const TodayEntriesScreen({super.key});

  @override
  _TodayEntriesScreenState createState() => _TodayEntriesScreenState();
}

class _TodayEntriesScreenState extends State<TodayEntriesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _cashInEntries = [];
  List<Map<String, dynamic>> _cashOutEntries = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTodayEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load today's entries and filter them into Cash In and Cash Out
  Future<void> _loadTodayEntries() async {
    DateTime today = DateTime.now();
    List<Map<String, dynamic>> entries =
        await HiveDatabaseHelper().getHistoryByDate(today);

    setState(() {
      _cashInEntries = entries.where((e) => e['cash_in'] > 0).toList();
      _cashOutEntries = entries.where((e) => e['cash_out'] > 0).toList();
    });
  }

  // Update entry in Hive database
  Future<void> _updateEntry(
      Map<String, dynamic> entry, String type, int amount) async {
    final historyBox = Hive.box<Map>(HiveDatabaseHelper().cashHistoryBoxName);
    final entryKey = historyBox.keys.firstWhere(
      (key) =>
          historyBox.get(key)?['date'] == entry['date'] &&
          historyBox.get(key)?['name'] == entry['name'],
      orElse: () => null,
    );

    if (entryKey != null) {
      final updatedEntry = historyBox.get(entryKey);
      if (updatedEntry != null) {
        updatedEntry[type] = amount;
        await historyBox.put(entryKey, updatedEntry);
        _loadTodayEntries();
      }
    }
  }

  // Show dialog for editing the entry
  Future<void> _showEditDialog(Map<String, dynamic> entry) async {
    final TextEditingController cashInController =
        TextEditingController(text: entry['cash_in'].toString());
    final TextEditingController cashOutController =
        TextEditingController(text: entry['cash_out'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show only cash_in TextField if editing cash_in
              if (_tabController.index == 0)
                TextField(
                  controller: cashInController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'وصول'),
                ),
              // Show only cash_out TextField if editing cash_out
              if (_tabController.index == 1)
                TextField(
                  controller: cashOutController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'مال/بل'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                int cashIn = int.tryParse(cashInController.text) ?? 0;
                int cashOut = int.tryParse(cashOutController.text) ?? 0;

                // Update the entry based on the tab selected (Cash In or Cash Out)
                if (_tabController.index == 0) {
                  await _updateEntry(entry, 'cash_in', cashIn);
                } else if (_tabController.index == 1) {
                  await _updateEntry(entry, 'cash_out', cashOut);
                }

                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Build a list of entries (Cash In or Cash Out)
  Widget _buildEntryList(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          "No Entries",
          style: TextStyle(color: AppColors.secondaryColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['date']));
        String formattedString = 'Date: $formattedDate\n${_tabController.index == 0 ? "وصول : ${entry['cash_in']}" : "مال/بل : ${entry['cash_out']}" }';



        return Card(
          color: AppColors.mainColor,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(
              entry['name'],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
                formattedString,
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: AppColors.secondaryColor),
              onPressed: () async {
                await _showEditDialog(entry);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
              });
            },
            icon: Icon(Icons.arrow_back_ios_rounded)),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text('آج کی نقد اندراجات', style: TextStyle(fontFamily: 'JameelNooriNastaleeqKasheeda',letterSpacing: 2),),
        backgroundColor: AppColors.mainColor,
        bottom: TabBar(
          indicator: BoxDecoration(color: Colors.white.withOpacity(0.3)),
          unselectedLabelColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          controller: _tabController,
          indicatorColor: AppColors.secondaryColor,
          labelStyle: TextStyle(color: Colors.white,fontSize: 18,fontFamily: 'JameelNooriNastaleeqKasheeda',letterSpacing: 2),
          tabs: [
            Tab(text: 'وصول',),
            Tab(text: ' مال/بل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Show Cash In entries when Cash In tab is selected
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildEntryList(_cashInEntries),
          ),
          // Show Cash Out entries when Cash Out tab is selected
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildEntryList(_cashOutEntries),
          ),
        ],
      ),
    );
  }
}
