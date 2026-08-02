import 'package:flutter/material.dart';
import 'package:aahar_app/screens/dashboard_screen.dart';

class MainShell extends StatelessWidget {
  final String farmerName;
  final String fieldName;

  const MainShell({
    super.key,
    required this.farmerName,
    required this.fieldName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashboardScreen(
        farmerName: farmerName,
        fieldName: fieldName,
      ),
    );
  }
}
