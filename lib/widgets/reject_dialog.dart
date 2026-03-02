import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class RejectDialog extends StatefulWidget {
  final String candidateName;
  final void Function(String reason) onReject;

  const RejectDialog({
    super.key,
    required this.candidateName,
    required this.onReject,
  });

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<RejectDialog> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();
  bool _showCustomField = false;

  static const _presetReasons = [
    'Not a culture fit',
    'Technical skills insufficient',
    'Compensation mismatch',
    'Failed assignment',
    'Fraud/authenticity concerns',
    'Withdrew from process',
    'No response',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'Reject ${widget.candidateName}?',
        style: AppTypography.titleMedium,
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a reason for rejection:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _presetReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return ChoiceChip(
                  label: Text(reason),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedReason = selected ? reason : null;
                      _showCustomField = reason == 'Other' && selected;
                    });
                  },
                  selectedColor: AppColors.error.withAlpha(51),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isSelected ? AppColors.error : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.error : AppColors.surfaceBorder,
                  ),
                );
              }).toList(),
            ),
            if (_showCustomField) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _customReasonController,
                style: AppTypography.bodyMedium,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter custom reason...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  final reason = _selectedReason == 'Other'
                      ? _customReasonController.text.trim().isEmpty
                          ? 'Other'
                          : _customReasonController.text.trim()
                      : _selectedReason!;
                  widget.onReject(reason);
                  Navigator.of(context).pop();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
