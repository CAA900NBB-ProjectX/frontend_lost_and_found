// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Found It'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.search, color: Colors.white),
              ),
              title: Text('Lost Item ${index + 1}'),
              subtitle: const Text('Location: Campus Library'),
              trailing: const Text('2h ago'),
              onTap: () {
                // Navigate to detail page
              },
            ),
          );
        },
      ),
    );
  }
}
