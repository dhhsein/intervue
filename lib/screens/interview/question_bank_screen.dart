import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class QuestionBankScreen extends StatelessWidget {
  final String candidateId;

  const QuestionBankScreen({
    super.key,
    required this.candidateId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Question Bank for: $candidateId - Coming in Phase 4',
          style: AppTypography.titleMedium,
        ),
      ),
    );
  }
}
