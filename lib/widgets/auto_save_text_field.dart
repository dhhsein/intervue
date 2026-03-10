import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/save_status_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Text field that automatically saves after a debounce period.
class AutoSaveTextField extends ConsumerStatefulWidget {
  final String? initialValue;
  final Future<void> Function(String) onSave;
  final int debounceMs;
  final String? hint;
  final int? maxLines;
  final String? label;
  final bool readOnly;

  const AutoSaveTextField({
    super.key,
    this.initialValue,
    required this.onSave,
    this.debounceMs = 500,
    this.hint,
    this.maxLines = 3,
    this.label,
    this.readOnly = false,
  });

  @override
  ConsumerState<AutoSaveTextField> createState() => _AutoSaveTextFieldState();
}

class _AutoSaveTextFieldState extends ConsumerState<AutoSaveTextField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  String _lastSavedValue = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastSavedValue = widget.initialValue ?? '';
  }

  @override
  void didUpdateWidget(AutoSaveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
      _lastSavedValue = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();

    if (value == _lastSavedValue) return;

    ref.read(saveStatusProvider.notifier).setSaving();

    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceMs),
      () async {
        if (value != _lastSavedValue) {
          try {
            await widget.onSave(value);
            _lastSavedValue = value;
            if (mounted) {
              ref.read(saveStatusProvider.notifier).setSaved();
            }
          } catch (e) {
            if (mounted) {
              ref.read(saveStatusProvider.notifier).setError();
            }
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: _controller,
          style: AppTypography.bodyMedium,
          maxLines: widget.maxLines,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(12),
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
          onChanged: _onChanged,
        ),
      ],
    );
  }
}
