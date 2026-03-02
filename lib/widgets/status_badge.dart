import 'package:flutter/material.dart';

import '../models/candidate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final CandidateStatus status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case CandidateStatus.newCandidate:
      case CandidateStatus.screeningSent:
      case CandidateStatus.screeningDone:
      case CandidateStatus.phoneScreen:
        return AppColors.info;
      case CandidateStatus.technical:
        return AppColors.accent;
      case CandidateStatus.assignment:
        return AppColors.warning;
      case CandidateStatus.finalReview:
      case CandidateStatus.offer:
        return AppColors.accent;
      case CandidateStatus.hired:
        return AppColors.success;
      case CandidateStatus.rejected:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.label.copyWith(color: _color),
      ),
    );
  }
}
