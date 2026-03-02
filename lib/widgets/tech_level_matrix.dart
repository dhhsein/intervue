import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Grid of radio buttons for tech experience assessment.
class TechLevelMatrix extends StatelessWidget {
  final List<String> technologies;
  final List<String> levels;
  final Map<String, String> values;
  final ValueChanged<Map<String, String>> onChanged;

  const TechLevelMatrix({
    super.key,
    required this.technologies,
    required this.levels,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '',
                style: AppTypography.label.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            ...levels.map((level) => SizedBox(
                  width: 100,
                  child: Text(
                    level,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Technology rows
        ...List.generate(technologies.length, (index) {
          final tech = technologies[index];
          final selectedLevel = values[tech];
          final isEven = index % 2 == 0;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isEven ? AppColors.surface : AppColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Text(
                    tech,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                ...levels.map((level) => SizedBox(
                      width: 100,
                      child: Center(
                        child: _RadioDot(
                          isSelected: selectedLevel == level,
                          onTap: () {
                            final newValues = Map<String, String>.from(values);
                            newValues[tech] = level;
                            onChanged(newValues);
                          },
                        ),
                      ),
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RadioDot extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioDot({
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RadioDot> createState() => _RadioDotState();
}

class _RadioDotState extends State<_RadioDot> {
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
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isSelected
                ? AppColors.accent
                : (_isHovered ? AppColors.surfaceLight : AppColors.surface),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accent
                  : AppColors.surfaceBorder,
              width: 2,
            ),
          ),
          child: widget.isSelected
              ? const Center(
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
