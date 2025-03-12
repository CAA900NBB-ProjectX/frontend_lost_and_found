import 'package:flutter/material.dart';
import 'navigation_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: bottom,
      ),
      drawer: AppNavigationDrawer(currentRoute: currentRoute),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}