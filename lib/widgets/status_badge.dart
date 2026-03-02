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
        return AppColors.statusNew;
      case CandidateStatus.screeningSent:
        return AppColors.statusScreeningSent;
      case CandidateStatus.screeningDone:
        return AppColors.statusScreeningDone;
      case CandidateStatus.phoneScreen:
        return AppColors.statusPhoneScreen;
      case CandidateStatus.pendingScheduling:
        return AppColors.statusPendingScheduling;
      case CandidateStatus.technical:
        return AppColors.statusTechnical;
      case CandidateStatus.assignment:
        return AppColors.statusAssignment;
      case CandidateStatus.finalReview:
        return AppColors.statusFinalReview;
      case CandidateStatus.offer:
        return AppColors.statusOffer;
      case CandidateStatus.hired:
        return AppColors.statusHired;
      case CandidateStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.label.copyWith(color: _color),
      ),
    );
  }
}
