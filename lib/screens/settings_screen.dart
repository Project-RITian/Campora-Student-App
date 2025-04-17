import 'package:flutter/material.dart';
import '../widgets/custom_navigation_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const CustomNavigationDrawer(),
      body: const Center(child: Text('Settings Screen')),
    );
  }
}
