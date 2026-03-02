import 'package:flutter/material.dart';

import '../models/candidate.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final CandidateStatus status;

  const StatusBadge({super.key, required this.status});

  // Status colors per user specs:
  // New (yellow), Screening I (light blue), Screening II (blue),
  // Screening III (dark blue), Technical (orange), Assignment (magenta),
  // In Review (cyan), Offered (green), Rejected (red), Hired (white)
  Color get _color {
    switch (status) {
      case CandidateStatus.newCandidate:
        return const Color(0xFFF1C40F); // Yellow
      case CandidateStatus.screeningSent:
        return const Color(0xFF5DADE2); // Light blue (Screening I)
      case CandidateStatus.screeningDone:
        return const Color(0xFF3498DB); // Blue (Screening II)
      case CandidateStatus.phoneScreen:
        return const Color(0xFF2471A3); // Dark blue (Screening III)
      case CandidateStatus.technical:
        return const Color(0xFFE67E22); // Orange
      case CandidateStatus.assignment:
        return const Color(0xFF9B59B6); // Magenta
      case CandidateStatus.finalReview:
        return const Color(0xFF00BCD4); // Cyan (In Review)
      case CandidateStatus.offer:
        return const Color(0xFF2ECC71); // Green (Offered)
      case CandidateStatus.hired:
        return const Color(0xFFE8E8E8); // White
      case CandidateStatus.rejected:
        return const Color(0xFFE74C3C); // Red
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
