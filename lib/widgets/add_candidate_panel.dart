import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isExtracting = false;
  String? _createdCandidateId;
  Map<String, String?>? _extractedInfo;

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

  Future<void> _extractFromResume() async {
    if (_selectedFileBytes == null) return;

    // Only require name for extraction
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name first')),
      );
      return;
    }

    setState(() => _isExtracting = true);

    try {
      final dataService = ref.read(dataServiceProvider);

      // Create candidate first if not already created
      if (_createdCandidateId == null) {
        final candidate = await ref.read(candidatesProvider.notifier).createCandidate(
              name: name,
              email: 'pending@extract.local',
              phone: null,
            );
        _createdCandidateId = candidate.id;

        // Upload the resume
        await dataService.uploadResume(candidate.id, _selectedFileBytes!);
      }

      // Extract contact info
      final info = await dataService.extractResumeInfo(_createdCandidateId!);

      if (mounted) {
        setState(() => _extractedInfo = info);

        final extractedCount = info.values.where((v) => v != null).length;
        if (extractedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not extract contact info from resume')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extract: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    ref.read(saveStatusProvider.notifier).setSaving();

    try {
      String candidateId;

      if (_createdCandidateId != null) {
        // Candidate was already created during extraction, just update it
        candidateId = _createdCandidateId!;
        await ref.read(candidatesProvider.notifier).updateCandidate(
              candidateId,
              {
                'name': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim().isEmpty
                    ? null
                    : _phoneController.text.trim(),
              },
            );
        await ref.read(candidatesProvider.notifier).refresh();
      } else {
        // Create new candidate
        final candidate = await ref.read(candidatesProvider.notifier).createCandidate(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            );
        candidateId = candidate.id;

        if (_selectedFileBytes != null) {
          final dataService = ref.read(dataServiceProvider);
          await dataService.uploadResume(candidate.id, _selectedFileBytes!);
          await ref.read(candidatesProvider.notifier).refresh();
        }
      }

      ref.read(saveStatusProvider.notifier).setSaved();
      widget.onCreated?.call(candidateId);
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
      decoration: const BoxDecoration(
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
            required: true,
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
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
          ),
        ),
        if (_selectedFileName != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _isExtracting ? null : _extractFromResume,
            icon: _isExtracting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high, size: 18),
            label: const Text('Extract from Resume'),
          ),
          if (_extractedInfo != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildExtractedFields(),
          ],
        ],
      ],
    );
  }

  Widget _buildExtractedFields() {
    final items = <Widget>[];

    if (_extractedInfo!['email'] != null) {
      items.add(_buildExtractedChip('Email', _extractedInfo!['email']!));
    }
    if (_extractedInfo!['phone'] != null) {
      items.add(_buildExtractedChip('Phone', _extractedInfo!['phone']!));
    }

    if (items.isEmpty) {
      return Text(
        'No contact info found in resume',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items,
    );
  }

  Widget _buildExtractedChip(String label, String value) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $label: $value'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.info.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'Email' ? Icons.email_outlined : Icons.phone_outlined,
              size: 16,
              color: AppColors.info,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(color: AppColors.info),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.copy,
              size: 14,
              color: AppColors.info.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
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
