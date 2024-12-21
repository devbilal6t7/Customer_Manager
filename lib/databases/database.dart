import 'package:hive/hive.dart';

class HiveDatabaseHelper {
  static final HiveDatabaseHelper _instance = HiveDatabaseHelper._internal();

  factory HiveDatabaseHelper() => _instance;

  HiveDatabaseHelper._internal();

  static const String _customersBoxName = 'customers';
  static const String _cashHistoryBoxName = 'cashHistory';
  static const String _userCredentialsBoxName = 'userCredentials';

  String get cashHistoryBoxName => _cashHistoryBoxName;
  String get customersBoxName => _customersBoxName;
  String get userCredentialsBoxName => _userCredentialsBoxName;

  static Future<void> initialize() async {
    await Hive.openBox<Map>(_customersBoxName);
    await Hive.openBox<Map>(_cashHistoryBoxName);
    await Hive.openBox<Map>(_userCredentialsBoxName);
  }

  Future<void> addCustomer(String name, String number) async {
    final customersBox = Hive.box<Map>(_customersBoxName);
    await customersBox.add({'name': name, 'number': number, 'cash_in': 0, 'cash_out': 0});
  }

  Future<void> addUserCredentials(String username, String password) async {
    final userCredentialsBox = Hive.box<Map>(_userCredentialsBoxName);
    await userCredentialsBox.put(username, {'password': password});
  }

  Future<bool> validateUserCredentials(String username, String password) async {
    final userCredentialsBox = Hive.box<Map>(_userCredentialsBoxName);
    final credentials = userCredentialsBox.get(username);
    if (credentials != null && credentials['password'] == password) {
      return true;
    }
    return false;
  }

  Future<void> updateCashIn(String name, int amount) async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    await historyBox.add({
      'name': name,
      'cash_in': amount,
      'cash_out': 0,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateCashOut(String name, int amount) async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    await historyBox.add({
      'name': name,
      'cash_in': 0,
      'cash_out': amount,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getTotalCashIn() async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    int totalCashIn = 0;

    for (var record in historyBox.values) {
      totalCashIn += record['cash_in'] as int? ?? 0;
    }

    return totalCashIn;
  }

  Future<int> getTotalCashOut() async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    int totalCashOut = 0;

    for (var record in historyBox.values) {
      totalCashOut += record['cash_out'] as int? ?? 0;
    }

    return totalCashOut;
  }

  Future<List<Map<String, dynamic>>> getHistoryByDate(DateTime selectedDate) async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    final formattedDate = selectedDate.toIso8601String().substring(0, 10);

    return historyBox.values
        .where((record) =>
        (record['date'] as String).startsWith(formattedDate)) // Check if date matches today
        .map((record) => Map<String, dynamic>.from(record)) // Explicitly cast to Map<String, dynamic>
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final customersBox = Hive.box<Map>(_customersBoxName);
    return customersBox.values.cast<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> getHistoryByCustomer(String customerName) async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);

    return historyBox.values
        .where((record) => record['name'] == customerName)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> clearCashHistory() async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    await historyBox.clear();
  }

  Future<void> updateCustomerName(String oldName, String newName) async {
    final customersBox = Hive.box<Map>(_customersBoxName);
    final customerKey = customersBox.keys.firstWhere(
          (key) => customersBox.get(key)?['name'] == oldName,
      orElse: () => null,
    );

    if (customerKey != null) {
      final updatedCustomer = customersBox.get(customerKey);
      updatedCustomer?['name'] = newName;
      await customersBox.put(customerKey, updatedCustomer!);
    }

    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    for (var key in historyBox.keys) {
      final record = historyBox.get(key);
      if (record?['name'] == oldName) {
        record?['name'] = newName;
        await historyBox.put(key, record!);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryBySubtype(String type, String subtype) async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);

    return historyBox.values
        .where((record) => record['subtype'] == subtype && record[type] > 0)
        .cast<Map<String, dynamic>>()
        .toList();
  }
  Future<void> saveCustomSubtype(String subtype) async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);

    // Check if the custom subtype already exists
    final existingSubtypes = historyBox.values
        .map((record) => record['subtype'])
        .whereType<String>()
        .toSet();

    if (!existingSubtypes.contains(subtype)) {
      // Save the subtype to the database by adding a placeholder entry
      await historyBox.add({
        'name': 'Custom Subtype Placeholder',
        'cash_in': 0,
        'cash_out': 0,
        'subtype': subtype,
        'date': DateTime.now().toIso8601String(),
      });
    }
  }


  Future<void> updateCustomerDetails({
    required String oldName,
    required String newName,
    required String newNumber,
  }) async {
    final customersBox = Hive.box<Map>(_customersBoxName);

    final customerKey = customersBox.keys.firstWhere(
          (key) => customersBox.get(key)?['name'] == oldName,
      orElse: () => null,
    );

    if (customerKey != null) {
      final updatedCustomer = customersBox.get(customerKey);
      updatedCustomer?['name'] = newName;
      updatedCustomer?['number'] = newNumber;
      await customersBox.put(customerKey, updatedCustomer!);
    }

    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    for (var key in historyBox.keys) {
      final record = historyBox.get(key);
      if (record?['name'] == oldName) {
        record?['name'] = newName;
        await historyBox.put(key, record!);
      }
    }
  }
  Future<int> getCustomerBalance(String customerName) async {
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);
    int totalCashIn = 0;
    int totalCashOut = 0;

    for (var record in historyBox.values.whereType<Map>()) {
      final recordMap = Map<String, dynamic>.from(record);
      if (recordMap['name'] == customerName) {
        totalCashIn += recordMap['cash_in'] as int? ?? 0;
        totalCashOut += recordMap['cash_out'] as int? ?? 0;
      }
    }

    return totalCashIn - totalCashOut;
  }


  Future<List<Map<String, dynamic>>> getDefaulters() async {
    final customersBox = Hive.box<Map>(_customersBoxName);
    final historyBox = Hive.box<Map>(_cashHistoryBoxName);

    final DateTime thresholdDate = DateTime.now().subtract(Duration(days: 30));

    // Retrieve all customers and convert to the desired type safely
    final allCustomers = customersBox.values
        .whereType<Map>() // Ensure only maps are processed
        .map((e) => Map<String, dynamic>.from(e)) // Safely convert each entry
        .toList();

    List<Map<String, dynamic>> defaulters = [];

    for (var customer in allCustomers) {
      final customerName = customer['name'];

      final hasRecentActivity = historyBox.values
          .whereType<Map>() // Ensure only maps are processed
          .any((record) {
        final recordMap = Map<String, dynamic>.from(record);
        final transactionDate = DateTime.tryParse(recordMap['date'] ?? '');
        return recordMap['name'] == customerName &&
            transactionDate != null &&
            transactionDate.isAfter(thresholdDate);
      });

      if (!hasRecentActivity) {
        defaulters.add(customer);
      }
    }

    return defaulters;
  }

}
