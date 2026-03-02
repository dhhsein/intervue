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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CandidateStatus>(
          value: value,
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.expand_more, color: AppColors.textSecondary),
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
    switch (status.pipelineStage) {
      case PipelineStage.screening:
        return AppColors.info;
      case PipelineStage.technical:
        return AppColors.accent;
      case PipelineStage.assignment:
        return AppColors.warning;
      case PipelineStage.finalReview:
        return AppColors.accent;
      case PipelineStage.hired:
        return AppColors.success;
      case PipelineStage.rejected:
        return AppColors.error;
    }
  }
}
