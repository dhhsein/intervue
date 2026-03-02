import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Multi-select chips where multiple can be selected.
/// Includes optional "Other" text field.
class MultiSelectChips extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final bool showOtherTextField;
  final String? otherValue;
  final ValueChanged<String>? onOtherChanged;

  const MultiSelectChips({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.showOtherTextField = false,
    this.otherValue,
    this.onOtherChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((option) {
            final isSelected = values.contains(option);
            return _MultiChipButton(
              label: option,
              isSelected: isSelected,
              onTap: () {
                final newValues = List<String>.from(values);
                if (isSelected) {
                  newValues.remove(option);
                } else {
                  newValues.add(option);
                }
                onChanged(newValues);
              },
            );
          }).toList(),
        ),
        if (showOtherTextField && values.contains('Other')) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 300,
            child: TextField(
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Please specify...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
              controller: TextEditingController(text: otherValue),
              onChanged: onOtherChanged,
            ),
          ),
        ],
      ],
    );
  }
}

class _MultiChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MultiChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MultiChipButton> createState() => _MultiChipButtonState();
}

class _MultiChipButtonState extends State<_MultiChipButton> {
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
                ? AppColors.accentSoft
                : (_isHovered ? AppColors.surfaceLight : AppColors.surface),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accent
                  : AppColors.surfaceBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSelected) ...[
                const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: AppTypography.bodySmall.copyWith(
                  color: widget.isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
