import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/interview_question.dart';
import '../../../models/screening_data.dart';
import '../../../providers/candidates_provider.dart';
import '../../../providers/questions_provider.dart';
import '../../../providers/screening_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/auto_save_text_field.dart';
import '../../../widgets/grade_selector.dart';
import '../../../widgets/multi_select_chips.dart';
import '../../../widgets/number_input.dart';
import '../../../widgets/reject_dialog.dart';
import '../../../widgets/tech_level_matrix.dart';
import '../../../widgets/toggle_chips.dart';

class ScreeningTab extends ConsumerStatefulWidget {
  final String candidateId;

  const ScreeningTab({super.key, required this.candidateId});

  @override
  ConsumerState<ScreeningTab> createState() => _ScreeningTabState();
}

class _ScreeningTabState extends ConsumerState<ScreeningTab> {
  @override
  Widget build(BuildContext context) {
    final screeningAsync = ref.watch(screeningNotifierProvider(widget.candidateId));
    final questionsAsync = ref.watch(screeningQuestionsProvider);
    final candidateAsync = ref.watch(candidateDetailProvider(widget.candidateId));

    return screeningAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (screening) => questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (questions) => candidateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (detail) => _buildContent(screening, questions, detail.candidate.name),
        ),
      ),
    );
  }

  Widget _buildContent(
    ScreeningData screening,
    List<InterviewQuestion> questions,
    String candidateName,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(screening, candidateName),
              const SizedBox(height: AppSpacing.xl),
              ...questions.asMap().entries.map(
                    (entry) => _buildQuestionCard(entry.key, entry.value, screening),
                  ),
              const SizedBox(height: AppSpacing.xl),
              _buildGradeSection(screening),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ScreeningData screening, String candidateName) {
    return Row(
      children: [
        Expanded(
          child: Text('Screening', style: AppTypography.titleLarge),
        ),
        _buildGradeBadge(screening.grade),
      ],
    );
  }

  Widget _buildGradeBadge(ScreeningGrade? grade) {
    if (grade == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textTertiary),
        ),
        child: Text(
          'NOT GRADED',
          style: AppTypography.titleSmall.copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    Color color;
    String label;
    switch (grade) {
      case ScreeningGrade.strong:
        color = AppColors.success;
        label = 'STRONG';
        break;
      case ScreeningGrade.maybe:
        color = AppColors.warning;
        label = 'MAYBE';
        break;
      case ScreeningGrade.no:
        color = AppColors.error;
        label = 'NO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTypography.titleSmall.copyWith(color: color),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuestionCard(
    int index,
    InterviewQuestion question,
    ScreeningData screening,
  ) {
    final response = screening.responses[question.id] ??
        ScreeningResponse(questionId: question.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}. ${question.question}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildQuestionInput(question, response),
          const SizedBox(height: AppSpacing.md),
          AutoSaveTextField(
            initialValue: response.notes,
            hint: 'Notes...',
            maxLines: 2,
            onSave: (value) async {
              final updated = ScreeningResponse(
                questionId: question.id,
                selectedOption: response.selectedOption,
                selectedOptions: response.selectedOptions,
                textValue: response.textValue,
                numericValue: response.numericValue,
                numericValue2: response.numericValue2,
                techLevels: response.techLevels,
                notes: value.isEmpty ? null : value,
              );
              await ref
                  .read(screeningNotifierProvider(widget.candidateId).notifier)
                  .updateResponse(question.id, updated);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(InterviewQuestion question, ScreeningResponse response) {
    switch (question.inputType) {
      case 'single_select':
        return ToggleChips(
          options: question.options ?? [],
          value: response.selectedOption,
          onChanged: (value) => _updateResponse(
            question.id,
            response.copyWith(selectedOption: value),
          ),
        );

      case 'multi_select':
        return MultiSelectChips(
          options: question.options ?? [],
          values: response.selectedOptions ?? [],
          showOtherTextField: true,
          otherValue: response.textValue,
          onChanged: (values) => _updateResponse(
            question.id,
            response.copyWith(selectedOptions: values),
          ),
          onOtherChanged: (value) => _updateResponse(
            question.id,
            response.copyWith(textValue: value),
          ),
        );

      case 'number_pair':
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current CTC',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                NumberInput(
                  value: response.numericValue,
                  prefix: '₹',
                  suffix: 'LPA',
                  hint: '0',
                  onChanged: (value) => _updateResponse(
                    question.id,
                    response.copyWith(numericValue: value),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected CTC',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                NumberInput(
                  value: response.numericValue2,
                  prefix: '₹',
                  suffix: 'LPA',
                  hint: '0',
                  onChanged: (value) => _updateResponse(
                    question.id,
                    response.copyWith(numericValue2: value),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'number':
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notice Period',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                NumberInput(
                  value: response.numericValue,
                  suffix: 'days',
                  hint: '30',
                  onChanged: (value) => _updateResponse(
                    question.id,
                    response.copyWith(numericValue: value),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Negotiable?',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                ToggleChips(
                  options: const ['Yes', 'No'],
                  value: response.selectedOption,
                  onChanged: (value) => _updateResponse(
                    question.id,
                    response.copyWith(selectedOption: value),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'tech_matrix':
        final matrixOptions = question.matrixOptions ?? {};
        final technologies = (matrixOptions['technologies'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        final levels = (matrixOptions['levels'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        return TechLevelMatrix(
          technologies: technologies,
          levels: levels,
          values: response.techLevels ?? {},
          onChanged: (values) => _updateResponse(
            question.id,
            response.copyWith(techLevels: values),
          ),
        );

      case 'text':
      default:
        return AutoSaveTextField(
          initialValue: response.textValue,
          hint: 'Enter response...',
          maxLines: 4,
          onSave: (value) async {
            await _updateResponse(
              question.id,
              response.copyWith(textValue: value.isEmpty ? null : value),
            );
          },
        );
    }
  }

  Future<void> _updateResponse(String questionId, ScreeningResponse response) async {
    await ref
        .read(screeningNotifierProvider(widget.candidateId).notifier)
        .updateResponse(questionId, response);
  }

  Future<void> _handleGradeChange(String? value) async {
    final grade = value == null
        ? null
        : ScreeningGrade.values.firstWhere((g) => g.value == value);

    // Update the grade
    ref.read(screeningNotifierProvider(widget.candidateId).notifier).updateGrade(grade);

    // Handle status changes based on grade
    if (grade == ScreeningGrade.strong) {
      // Strong → move to pending scheduling
      await ref.read(candidatesProvider.notifier).updateCandidate(
        widget.candidateId,
        {'status': 'pending_scheduling'},
      );
      _showToast('Candidate moved to Pending Scheduling');
    } else if (grade == ScreeningGrade.no) {
      // No → show reject dialog
      final candidateAsync = ref.read(candidateDetailProvider(widget.candidateId));
      final candidateName = candidateAsync.valueOrNull?.candidate.name ?? 'Candidate';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => RejectDialog(
            candidateName: candidateName,
            onReject: (reason) async {
              await ref.read(candidatesProvider.notifier).updateCandidate(
                widget.candidateId,
                {
                  'status': 'rejected',
                  'rejectionReason': reason,
                },
              );
              if (mounted) {
                _showToast('Candidate rejected');
              }
            },
          ),
        );
      }
    }
    // Maybe → stay in screening, no status change needed
  }

  Widget _buildGradeSection(ScreeningData screening) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: AppColors.surfaceBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Screening Grade',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: AppColors.surfaceBorder)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GradeSelector(
          value: screening.grade?.value,
          options: GradeSelector.screeningGradeOptions,
          onChanged: (value) => _handleGradeChange(value),
        ),
      ],
    );
  }

}

// Extension for copyWith on ScreeningResponse
extension ScreeningResponseCopyWith on ScreeningResponse {
  ScreeningResponse copyWith({
    String? selectedOption,
    List<String>? selectedOptions,
    String? textValue,
    String? numericValue,
    String? numericValue2,
    Map<String, String>? techLevels,
    String? notes,
  }) {
    return ScreeningResponse(
      questionId: questionId,
      selectedOption: selectedOption ?? this.selectedOption,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      textValue: textValue ?? this.textValue,
      numericValue: numericValue ?? this.numericValue,
      numericValue2: numericValue2 ?? this.numericValue2,
      techLevels: techLevels ?? this.techLevels,
      notes: notes ?? this.notes,
    );
  }
}
