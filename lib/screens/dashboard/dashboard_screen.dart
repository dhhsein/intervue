import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Dashboard - Coming in Phase 2',
          style: AppTypography.titleMedium,
        ),
      ),
    );
  }
}
