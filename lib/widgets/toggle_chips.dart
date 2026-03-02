import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A row of chip buttons where only one can be selected.
/// Tap to select, tap again to deselect.
class ToggleChips extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const ToggleChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final isSelected = option == value;
        return _ChipButton(
          label: option,
          isSelected: isSelected,
          onTap: () {
            if (isSelected) {
              onChanged(null);
            } else {
              onChanged(option);
            }
          },
        );
      }).toList(),
    );
  }
}

class _ChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<_ChipButton> {
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
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent
                : (_isHovered ? AppColors.surfaceLight : AppColors.surface),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accent
                  : AppColors.surfaceBorder,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.bodySmall.copyWith(
                color: widget.isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
