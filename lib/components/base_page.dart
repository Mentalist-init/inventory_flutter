import 'package:flutter/material.dart';
import 'package:namer_app/services/auth.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/screens/item_management.dart';
import 'package:namer_app/screens/login.dart';

class BasePage extends StatelessWidget {
  final Widget child;

  const BasePage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
      ),
      drawer: NavigationDrawer(),
      body: SafeArea(
        child: child,
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Items'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/items');
            },
          ),
          ListTile(
            leading: Icon(Icons.pages),
            title: Text('Bills'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/bills');
            }
          ),
          ListTile(
              leading: Icon(Icons.person),
              title: Text('Customers'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/customers');
              }
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              AuthService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
