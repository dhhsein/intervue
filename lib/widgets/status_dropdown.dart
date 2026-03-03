import 'package:flutter/material.dart';

import '../models/candidate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusDropdown extends StatelessWidget {
  final CandidateStatus value;
  final ValueChanged<CandidateStatus> onChanged;

  const StatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CandidateStatus>(
          isDense: true,
          value: value,
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
          style: AppTypography.bodyMedium,
          items: CandidateStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(status.displayName),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(CandidateStatus status) {
    switch (status) {
      case CandidateStatus.newCandidate:
        return AppColors.statusNew;
      case CandidateStatus.screeningDone:
        return AppColors.statusScreeningDone;
      case CandidateStatus.callUnattended:
        return AppColors.statusCallUnattended;
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
}
