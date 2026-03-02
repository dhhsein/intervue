import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Configuration for a grade option.
class GradeOption {
  final String value;
  final String label;
  final String icon;
  final Color color;

  const GradeOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Three large tappable cards for screening grades or recommendations.
class GradeSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<GradeOption> options;

  const GradeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  /// Pre-built screening grade options.
  static const screeningGradeOptions = [
    GradeOption(
      value: 'strong',
      label: 'STRONG',
      icon: '★',
      color: AppColors.success,
    ),
    GradeOption(
      value: 'maybe',
      label: 'MAYBE',
      icon: '○',
      color: AppColors.warning,
    ),
    GradeOption(
      value: 'no',
      label: 'NO',
      icon: '✕',
      color: AppColors.error,
    ),
  ];

  /// Pre-built recommendation options.
  static const recommendationOptions = [
    GradeOption(
      value: 'advance',
      label: 'ADVANCE',
      icon: '▶',
      color: AppColors.success,
    ),
    GradeOption(
      value: 'hold',
      label: 'HOLD',
      icon: '⏸',
      color: AppColors.warning,
    ),
    GradeOption(
      value: 'reject',
      label: 'REJECT',
      icon: '✕',
      color: AppColors.error,
    ),
  ];

  /// Pre-built hire options.
  static const hireOptions = [
    GradeOption(
      value: 'hire',
      label: 'HIRE',
      icon: '✓',
      color: AppColors.success,
    ),
    GradeOption(
      value: 'hold',
      label: 'HOLD',
      icon: '⏸',
      color: AppColors.warning,
    ),
    GradeOption(
      value: 'reject',
      label: 'REJECT',
      icon: '✕',
      color: AppColors.error,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = value == option.value;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: _GradeCard(
            option: option,
            isSelected: isSelected,
            onTap: () {
              if (isSelected) {
                onChanged(null);
              } else {
                onChanged(option.value);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

class _GradeCard extends StatefulWidget {
  final GradeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GradeCard> createState() => _GradeCardState();
}

class _GradeCardState extends State<_GradeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.option.color.withValues(alpha: 0.2)
                : (_isHovered ? AppColors.surfaceLight : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.option.color
                  : AppColors.surfaceBorder,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.option.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: widget.isSelected
                      ? widget.option.color
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.option.label,
                style: AppTypography.label.copyWith(
                  color: widget.isSelected
                      ? widget.option.color
                      : AppColors.textSecondary,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
