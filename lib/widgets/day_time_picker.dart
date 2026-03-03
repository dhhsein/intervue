import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A combined day selector (5 tiles) + time range picker for scheduling.
class DayTimePicker extends StatefulWidget {
  final String? selectedDay;
  final String? timeRange;
  final void Function(String? day, String? timeRange) onChanged;

  const DayTimePicker({
    super.key,
    this.selectedDay,
    this.timeRange,
    required this.onChanged,
  });

  @override
  State<DayTimePicker> createState() => _DayTimePickerState();
}

class _DayTimePickerState extends State<DayTimePicker> {
  late TextEditingController _startHourController;
  late TextEditingController _endHourController;
  String _startPeriod = 'AM';
  String _endPeriod = 'PM';

  @override
  void initState() {
    super.initState();
    _parseTimeRange(widget.timeRange);
  }

  void _parseTimeRange(String? timeRange) {
    if (timeRange != null) {
      final parts = timeRange.split(' - ');
      if (parts.length == 2) {
        final startParts = parts[0].split(' ');
        final endParts = parts[1].split(' ');
        _startHourController = TextEditingController(text: startParts[0]);
        _startPeriod = startParts.length > 1 ? startParts[1] : 'AM';
        _endHourController = TextEditingController(text: endParts[0]);
        _endPeriod = endParts.length > 1 ? endParts[1] : 'PM';
        return;
      }
    }
    _startHourController = TextEditingController();
    _endHourController = TextEditingController();
  }

  @override
  void dispose() {
    _startHourController.dispose();
    _endHourController.dispose();
    super.dispose();
  }

  List<DateTime> _generateDays() {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(5, (i) => today.add(Duration(days: i)));
  }

  void _onDayTap(DateTime day) {
    final iso = DateFormat('yyyy-MM-dd').format(day);
    final newDay = widget.selectedDay == iso ? null : iso;
    widget.onChanged(newDay, _buildTimeRange());
  }

  String? _buildTimeRange() {
    final startHour = _startHourController.text.trim();
    final endHour = _endHourController.text.trim();
    if (startHour.isEmpty && endHour.isEmpty) return null;
    return '$startHour $_startPeriod - $endHour $_endPeriod';
  }

  void _onTimeChanged() {
    widget.onChanged(widget.selectedDay, _buildTimeRange());
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateDays();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Day',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: days.map((day) {
            final iso = DateFormat('yyyy-MM-dd').format(day);
            final isSelected = widget.selectedDay == iso;
            final dayName = DateFormat('E').format(day);
            final dateStr = DateFormat('d MMM').format(day);

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _DayTile(
                dayName: dayName,
                date: dateStr,
                isSelected: isSelected,
                onTap: () => _onDayTap(day),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Preferred Time',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildHourInput(_startHourController),
            const SizedBox(width: AppSpacing.sm),
            _buildPeriodToggle(_startPeriod, (p) {
              setState(() => _startPeriod = p);
              _onTimeChanged();
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                '–',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _buildHourInput(_endHourController),
            const SizedBox(width: AppSpacing.sm),
            _buildPeriodToggle(_endPeriod, (p) {
              setState(() => _endPeriod = p);
              _onTimeChanged();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildHourInput(TextEditingController controller) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: AppTypography.bodyMedium,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
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
            borderSide: const BorderSide(
              color: AppColors.accent,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (_) => _onTimeChanged(),
      ),
    );
  }

  Widget _buildPeriodToggle(String value, ValueChanged<String> onChanged) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['AM', 'PM'].map((period) {
          final isSelected = value == period;
          return GestureDetector(
            onTap: () => onChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.horizontal(
                  left: period == 'AM'
                      ? const Radius.circular(7)
                      : Radius.zero,
                  right: period == 'PM'
                      ? const Radius.circular(7)
                      : Radius.zero,
                ),
              ),
              child: Text(
                period,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayTile extends StatefulWidget {
  final String dayName;
  final String date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayTile({
    required this.dayName,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DayTile> createState() => _DayTileState();
}

class _DayTileState extends State<_DayTile> {
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
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent
                : (_isHovered ? AppColors.surfaceLight : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accent
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.dayName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.date,
                style: AppTypography.bodySmall.copyWith(
                  color: widget.isSelected
                      ? Colors.white70
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
