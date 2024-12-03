
import 'package:customer_manager/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox<Map>('customers');
  await Hive.openBox<Map>('cashHistory');
  final userCredentialsBox = await Hive.openBox<Map>('userCredentials');

  if (!userCredentialsBox.containsKey('3810301109757')) {
    await userCredentialsBox.put('3810301109757', {
      'password': 'Saleem@123',
    });
  }
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'Customer Manager',
      home: const LockScreen(),
    );
  }
}
