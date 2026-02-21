import 'package:flutter/material.dart';

class StubSettingsScreen extends StatelessWidget {
  final String title;

  const StubSettingsScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('À venir'),
      ),
    );
  }
}
