import 'package:hive/hive.dart';

class HiveDatabaseHelper {
  static final HiveDatabaseHelper _instance = HiveDatabaseHelper._internal();

  factory HiveDatabaseHelper() => _instance;

  HiveDatabaseHelper._internal();

  static const String _customersBoxName = 'customers';
  static const String _cashHistoryBoxName = 'cashHistory';
  static const String _userCredentialsBoxName = 'userCredentials';

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
        (record['date'] as String).startsWith(formattedDate))
        .cast<Map<String, dynamic>>()
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
        .where((record) =>
    record['subtype'] == subtype && record[type] > 0)
        .cast<Map<String, dynamic>>()
        .toList();
  }

}
