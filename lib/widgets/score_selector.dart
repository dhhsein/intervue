import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tappable row of 5 circles for 1-5 scoring.
class ScoreSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final double size;

  const ScoreSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final score = index + 1;
        final isSelected = value == score;
        return Padding(
          padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
          child: _ScoreCircle(
            score: score,
            isSelected: isSelected,
            size: size,
            onTap: () {
              if (isSelected) {
                onChanged(null);
              } else {
                onChanged(score);
              }
            },
          ),
        );
      }),
    );
  }
}

class _ScoreCircle extends StatefulWidget {
  final int score;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;

  const _ScoreCircle({
    required this.score,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  @override
  State<_ScoreCircle> createState() => _ScoreCircleState();
}

class _ScoreCircleState extends State<_ScoreCircle>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_ScoreCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getScoreColor(widget.score);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isSelected
                  ? color
                  : (_isHovered ? AppColors.surfaceLight : AppColors.surface),
              border: Border.all(
                color: widget.isSelected ? color : AppColors.surfaceBorder,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                widget.score.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.textTertiary,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
