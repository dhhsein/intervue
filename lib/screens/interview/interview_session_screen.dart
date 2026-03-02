import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class InterviewSessionScreen extends StatelessWidget {
  final String candidateId;

  const InterviewSessionScreen({
    super.key,
    required this.candidateId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Interview Session for: $candidateId - Coming in Phase 4',
          style: AppTypography.titleMedium,
        ),
      ),
    );
  }
}
