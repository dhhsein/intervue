import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/candidates_provider.dart';
import '../providers/data_service_provider.dart';
import '../providers/save_status_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AddCandidatePanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(String candidateId)? onCreated;

  const AddCandidatePanel({
    super.key,
    required this.onClose,
    this.onCreated,
  });

  @override
  ConsumerState<AddCandidatePanel> createState() => _AddCandidatePanelState();
}

class _AddCandidatePanelState extends ConsumerState<AddCandidatePanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.first.name;
        _selectedFileBytes = result.files.first.bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    ref.read(saveStatusProvider.notifier).setSaving();

    try {
      final candidate = await ref.read(candidatesProvider.notifier).createCandidate(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      if (_selectedFileBytes != null) {
        final dataService = ref.read(dataServiceProvider);
        await dataService.uploadResume(candidate.id, _selectedFileBytes!);
        await ref.read(candidatesProvider.notifier).refresh();
      }

      ref.read(saveStatusProvider.notifier).setSaved();
      widget.onCreated?.call(candidate.id);
      widget.onClose();
    } catch (e) {
      ref.read(saveStatusProvider.notifier).setError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create candidate: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withAlpha(128),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(64),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _buildForm(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Add Candidate', style: AppTypography.titleMedium),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Name',
            controller: _nameController,
            required: true,
            hint: 'Full name',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            required: true,
            hint: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            label: 'Phone',
            controller: _phoneController,
            hint: '+91-98765-43210',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildResumeUpload(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.label),
            if (required)
              Text(' *', style: AppTypography.label.copyWith(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          style: AppTypography.bodyMedium,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          validator: validator ??
              (required
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return '$label is required';
                      }
                      return null;
                    }
                  : null),
        ),
      ],
    );
  }

  Widget _buildResumeUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resume', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: _pickResume,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFileName != null ? Icons.description : Icons.upload_file,
                  color: _selectedFileName != null
                      ? AppColors.success
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _selectedFileName ?? 'Upload PDF',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _selectedFileName != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedFileName != null)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Candidate'),
        ),
      ),
    );
  }
}
