import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/interview_question.dart';
import '../../providers/candidates_provider.dart';
import '../../providers/interview_provider.dart';
import '../../providers/questions_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/collapsible_section.dart';

class QuestionBankScreen extends ConsumerStatefulWidget {
  final String candidateId;

  const QuestionBankScreen({
    super.key,
    required this.candidateId,
  });

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  String _depthFilter = 'all'; // 'all', 'core', 'nice_to_have', 'general'

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsByCategoryProvider);
    final candidateAsync = ref.watch(candidateDetailProvider(widget.candidateId));
    final selectedIds = ref.watch(selectedQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(candidateAsync, selectedIds.length),
          Expanded(
            child: questionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (grouped) => _buildQuestionList(grouped, selectedIds),
            ),
          ),
          _buildBottomBar(selectedIds.length),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue candidateAsync, int selectedCount) {
    final candidateName = candidateAsync.whenOrNull(
      data: (detail) => detail.candidate.name,
    ) ?? 'Candidate';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/candidate/${widget.candidateId}');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question Bank', style: AppTypography.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Selecting for: $candidateName',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selectedCount > 0
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Selected: $selectedCount questions',
                  style: AppTypography.bodyMedium.copyWith(
                    color: selectedCount > 0
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Text(
          'Filter:',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _buildFilterChip('All', 'all'),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterChip('Core', 'core'),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterChip('Nice-to-have', 'nice_to_have'),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterChip('General', 'general'),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _depthFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _depthFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionList(
    Map<String, List<InterviewQuestion>> grouped,
    Set<String> selectedIds,
  ) {
    // Filter questions based on depth filter
    final filteredGrouped = <String, List<InterviewQuestion>>{};
    for (final entry in grouped.entries) {
      final filteredQuestions = entry.value.where((q) {
        if (_depthFilter == 'all') return true;
        return q.depth == _depthFilter;
      }).toList();
      if (filteredQuestions.isNotEmpty) {
        filteredGrouped[entry.key] = filteredQuestions;
      }
    }

    if (filteredGrouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No questions match the filter',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filteredGrouped.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: CollapsibleSection(
                  title: entry.key,
                  count: entry.value.length,
                  child: Column(
                    children: entry.value.map((question) {
                      return _buildQuestionCard(
                        question,
                        selectedIds.contains(question.id),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(InterviewQuestion question, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleQuestion(question.id),
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _buildTag('Assesses: ${question.assesses}', false),
                      _buildDepthBadge(question.depth),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.accent.withValues(alpha: 0.2)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          color: isHighlighted ? AppColors.accent : AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDepthBadge(String depth) {
    Color color;
    String label;
    switch (depth) {
      case 'core':
        color = AppColors.accent;
        label = 'Core';
        break;
      case 'nice_to_have':
        color = AppColors.info;
        label = 'Nice-to-have';
        break;
      case 'general':
        color = AppColors.warning;
        label = 'General';
        break;
      default:
        color = AppColors.textTertiary;
        label = depth;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _toggleQuestion(String questionId) {
    final current = ref.read(selectedQuestionsProvider);
    if (current.contains(questionId)) {
      ref.read(selectedQuestionsProvider.notifier).state =
          {...current}..remove(questionId);
    } else {
      ref.read(selectedQuestionsProvider.notifier).state = {...current, questionId};
    }
  }

  Widget _buildBottomBar(int selectedCount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selectedCount > 0)
            TextButton(
              onPressed: () {
                ref.read(selectedQuestionsProvider.notifier).state = {};
              },
              child: Text(
                'Clear Selection',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 300,
            child: ElevatedButton(
              onPressed: selectedCount > 0 ? _startInterview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                selectedCount > 0
                    ? 'Start Interview with $selectedCount Questions'
                    : 'Select questions to start',
                style: AppTypography.buttonText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startInterview() {
    final selectedIds = ref.read(selectedQuestionsProvider);
    final questionsAsync = ref.read(allInterviewQuestionsProvider);

    questionsAsync.whenData((allQuestions) {
      final selectedQuestions = allQuestions
          .where((q) => selectedIds.contains(q.id))
          .toList();

      if (selectedQuestions.isNotEmpty) {
        ref.read(interviewProvider.notifier).startInterview(
          widget.candidateId,
          selectedQuestions,
        );
        context.push('/candidate/${widget.candidateId}/interview');
      }
    });
  }
}
