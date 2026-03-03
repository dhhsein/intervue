import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/candidate.dart';
import '../providers/candidates_provider.dart';
import '../providers/save_status_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'reject_dialog.dart';

enum _GradeAction { advance, keep, reject }

/// A CTA button that updates the candidate's pipeline status based on
/// the selected grade. Consistent across all grading tabs.
///
/// - +1 grade → "Save & Advance" (green) → moves to [nextStatus]
/// - 0 grade  → "Save" (accent)          → no status change
/// - -1 grade → "Save & Reject" (red)    → shows RejectDialog
class GradeActionButton extends ConsumerStatefulWidget {
  final String? gradeValue;
  final Set<String> positiveGrades;
  final Set<String> negativeGrades;
  final String candidateId;
  final String candidateName;
  final CandidateStatus nextStatus;
  final Future<void> Function()? onBeforeStatusUpdate;
  final VoidCallback? onComplete;

  const GradeActionButton({
    super.key,
    required this.gradeValue,
    required this.positiveGrades,
    required this.negativeGrades,
    required this.candidateId,
    required this.candidateName,
    required this.nextStatus,
    this.onBeforeStatusUpdate,
    this.onComplete,
  });

  @override
  ConsumerState<GradeActionButton> createState() => _GradeActionButtonState();
}

class _GradeActionButtonState extends ConsumerState<GradeActionButton> {
  bool _isProcessing = false;

  _GradeAction get _action {
    final v = widget.gradeValue;
    if (v == null) return _GradeAction.keep;
    if (widget.positiveGrades.contains(v)) return _GradeAction.advance;
    if (widget.negativeGrades.contains(v)) return _GradeAction.reject;
    return _GradeAction.keep;
  }

  String get _label {
    switch (_action) {
      case _GradeAction.advance:
        return 'Save & Advance';
      case _GradeAction.keep:
        return 'Save';
      case _GradeAction.reject:
        return 'Save & Reject';
    }
  }

  Color get _color {
    switch (_action) {
      case _GradeAction.advance:
        return AppColors.success;
      case _GradeAction.keep:
        return AppColors.accent;
      case _GradeAction.reject:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (_action) {
      case _GradeAction.advance:
        return Icons.arrow_forward;
      case _GradeAction.keep:
        return Icons.save;
      case _GradeAction.reject:
        return Icons.close;
    }
  }

  Future<void> _handlePress() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      ref.read(saveStatusProvider.notifier).setSaving();

      // Run any domain-specific save first
      if (widget.onBeforeStatusUpdate != null) {
        await widget.onBeforeStatusUpdate!();
      }

      switch (_action) {
        case _GradeAction.advance:
          await ref.read(candidatesProvider.notifier).updateCandidate(
            widget.candidateId,
            {'status': widget.nextStatus.value},
          );
          break;
        case _GradeAction.keep:
          // No status change
          break;
        case _GradeAction.reject:
          if (!mounted) return;
          // Show reject dialog and wait for result
          await _showRejectDialog();
          ref.read(saveStatusProvider.notifier).setSaved();
          widget.onComplete?.call();
          return; // reject dialog handles its own status update
      }

      ref.invalidate(candidateDetailProvider(widget.candidateId));
      ref.read(saveStatusProvider.notifier).setSaved();
      widget.onComplete?.call();
    } catch (e) {
      ref.read(saveStatusProvider.notifier).setError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showRejectDialog() async {
    await showDialog(
      context: context,
      builder: (context) => RejectDialog(
        candidateName: widget.candidateName,
        onReject: (reason) => _rejectCandidate(reason),
      ),
    );
  }

  Future<void> _rejectCandidate(String reason) async {
    await ref.read(candidatesProvider.notifier).updateCandidate(
      widget.candidateId,
      {
        'status': CandidateStatus.rejected.value,
        'rejectionReason': reason,
      },
    );
    ref.invalidate(candidateDetailProvider(widget.candidateId));
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.gradeValue == null || _isProcessing;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : _handlePress,
        icon: _isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(_icon, size: 18),
        label: Text(
          _isProcessing ? 'Saving...' : _label,
          style: AppTypography.buttonText,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? AppColors.surfaceLight : _color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
