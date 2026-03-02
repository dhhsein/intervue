import 'package:flutter/material.dart';

import '../models/screening_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class GradeIndicator extends StatelessWidget {
  final ScreeningGrade? grade;
  final bool compact;

  const GradeIndicator({
    super.key,
    required this.grade,
    this.compact = false,
  });

  Color get _color {
    switch (grade) {
      case ScreeningGrade.strong:
        return AppColors.success;
      case ScreeningGrade.maybe:
        return AppColors.warning;
      case ScreeningGrade.no:
        return AppColors.error;
      case null:
        return AppColors.textTertiary;
    }
  }

  String get _icon {
    switch (grade) {
      case ScreeningGrade.strong:
        return '★';
      case ScreeningGrade.maybe:
        return '○';
      case ScreeningGrade.no:
        return '✕';
      case null:
        return '—';
    }
  }

  String get _label {
    switch (grade) {
      case ScreeningGrade.strong:
        return 'Strong';
      case ScreeningGrade.maybe:
        return 'Maybe';
      case ScreeningGrade.no:
        return 'No';
      case null:
        return 'Not graded';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_icon, style: TextStyle(color: _color, fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTypography.bodySmall.copyWith(color: _color),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_icon, style: TextStyle(color: _color, fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTypography.label.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}
