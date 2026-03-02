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
    // Match colors with StatusBadge
    switch (status) {
      case CandidateStatus.newCandidate:
        return const Color(0xFFF1C40F); // Yellow
      case CandidateStatus.screeningSent:
        return const Color(0xFF5DADE2); // Light blue
      case CandidateStatus.screeningDone:
        return const Color(0xFF3498DB); // Blue
      case CandidateStatus.phoneScreen:
        return const Color(0xFF2471A3); // Dark blue
      case CandidateStatus.technical:
        return const Color(0xFFE67E22); // Orange
      case CandidateStatus.assignment:
        return const Color(0xFF9B59B6); // Magenta
      case CandidateStatus.finalReview:
        return const Color(0xFF00BCD4); // Cyan
      case CandidateStatus.offer:
        return const Color(0xFF2ECC71); // Green
      case CandidateStatus.hired:
        return const Color(0xFFE8E8E8); // White
      case CandidateStatus.rejected:
        return const Color(0xFFE74C3C); // Red
    }
  }
}
