import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class InterviewSummaryScreen extends StatelessWidget {
  final String candidateId;

  const InterviewSummaryScreen({
    super.key,
    required this.candidateId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Interview Summary for: $candidateId - Coming in Phase 4',
          style: AppTypography.titleMedium,
        ),
      ),
    );
  }
}
