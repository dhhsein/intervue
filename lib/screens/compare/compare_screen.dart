import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Compare Candidates - Coming in Phase 5',
          style: AppTypography.titleMedium,
        ),
      ),
    );
  }
}
