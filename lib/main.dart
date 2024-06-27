import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:namer_app/components/base_page.dart';
import 'package:namer_app/screens/bills.dart';
import 'package:namer_app/screens/customers.dart';
import 'package:namer_app/screens/login.dart';
import 'package:namer_app/theme/theme.dart';
import './screens/item_management.dart';

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Inventory',
      theme: AppTheme.themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/items': (context) => BasePage(child: ItemsPage()),
        '/bills': (context) => BasePage(child: BillsPage()),
        '/customers': (context) => BasePage(child: CustomerPage()),
      },
    );
  }
}

void main() async {
  await dotenv.load(fileName: ".env");

  runApp(MyApp());
}
