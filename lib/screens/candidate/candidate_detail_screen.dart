import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class CandidateDetailScreen extends StatelessWidget {
  final String candidateId;

  const CandidateDetailScreen({
    super.key,
    required this.candidateId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Candidate Detail: $candidateId - Coming in Phase 2',
          style: AppTypography.titleMedium,
        ),
      ),
    );
  }
}
