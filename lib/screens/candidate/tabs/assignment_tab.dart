import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/debrief_questions.dart';
import '../../../models/assignment_review.dart';
import '../../../models/candidate.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/candidates_provider.dart';
import '../../../providers/config_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/auto_save_text_field.dart';
import '../../../widgets/grade_action_button.dart';
import '../../../widgets/grade_selector.dart';
import '../../../widgets/score_selector.dart';
import '../../../widgets/toggle_chips.dart';

class AssignmentTab extends ConsumerWidget {
  final String candidateId;

  const AssignmentTab({super.key, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(
      assignmentReviewNotifierProvider(candidateId),
    );
    final candidateAsync = ref.watch(candidateDetailProvider(candidateId));

    return assignmentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (assignment) => candidateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (detail) =>
            _buildContent(context, ref, assignment, detail.candidate.name),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
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
              // Header with status
              _buildHeader(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // Submission details
              _buildSubmissionSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // AI Evaluation
              _buildAiEvaluationSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xxl),

              // Scoring areas
              _buildScoringSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xxl),

              // Git history check
              _buildGitHistorySection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xxl),

              // Review call notes
              _buildReviewCallSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xxl),

              // Fraud assessment
              _buildFraudAssessmentSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xxl),

              // Recommendation
              _buildRecommendationSection(
                context,
                ref,
                assignment,
                candidateName,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with recommendation badge
        Row(
          children: [
            Expanded(
              child: Text('Assignment Review', style: AppTypography.titleLarge),
            ),
            _buildRecommendationBadge(assignment.recommendation),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Email prompt section
        _buildEmailPrompt(context, ref, assignment),
      ],
    );
  }

  Widget _buildRecommendationBadge(String? recommendation) {
    if (recommendation == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textTertiary),
        ),
        child: Text(
          'NOT REVIEWED',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    Color color;
    String label;
    switch (recommendation) {
      case 'strong_yes':
        color = AppColors.success;
        label = 'STRONG YES';
        break;
      case 'yes':
        color = AppColors.success;
        label = 'YES';
        break;
      case 'maybe':
        color = AppColors.warning;
        label = 'MAYBE';
        break;
      case 'no':
        color = AppColors.error;
        label = 'NO';
        break;
      case 'strong_no':
        color = AppColors.error;
        label = 'STRONG NO';
        break;
      default:
        color = AppColors.textTertiary;
        label = recommendation.toUpperCase();
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

  Widget _buildEmailPrompt(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final dateFormat = DateFormat('MMM d');
    final isSent = assignment.sentAt != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(
            isSent ? Icons.check_circle_outline : Icons.mail_outline,
            color: isSent ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isSent
                  ? 'Assignment sent on ${dateFormat.format(assignment.sentAt!)}'
                  : 'Assignment has not been sent yet',
              style: AppTypography.bodyMedium.copyWith(
                color: isSent ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _copyAssignmentEmail(context, ref),
            icon: const Icon(Icons.copy, size: 16),
            label: Text(isSent ? 'Copy Again' : 'Copy Email'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyAssignmentEmail(BuildContext context, WidgetRef ref) async {
    final config = await ref.read(configProvider.future);
    if (!context.mounted) return;
    final candidateDetail = ref
        .read(candidateDetailProvider(candidateId))
        .valueOrNull;

    if (config.assignmentBrief == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment brief not configured'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get first name
    final firstName =
        candidateDetail?.candidate.name.split(' ').first ?? 'there';

    // Generate email
    final email = _defaultAssignmentEmailTemplate
        .replaceAll('{name}', firstName)
        .replaceAll('{assignment}', config.assignmentBrief!)
        .replaceAll('{interviewer}', config.interviewerName)
        .replaceAll('{company}', config.companyName);

    await Clipboard.setData(ClipboardData(text: email));

    // Update sent date if not already set
    final notifier = ref.read(
      assignmentReviewNotifierProvider(candidateId).notifier,
    );
    final assignment = ref
        .read(assignmentReviewNotifierProvider(candidateId))
        .valueOrNull;
    if (assignment?.sentAt == null) {
      await notifier.updateSentDate(DateTime.now());
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment email copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static const _defaultAssignmentEmailTemplate = '''Hi {name},

Congratulations on moving to the next stage! Please complete the following take-home assignment:

---

{assignment}

---

Please share your solution as a GitHub repository link once completed.

Best,
{interviewer}
{company}''';

  Widget _buildSubmissionSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final notifier = ref.read(
      assignmentReviewNotifierProvider(candidateId).notifier,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submission', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AutoSaveTextField(
                  initialValue: assignment.repoLink,
                  label: 'Repository Link',
                  hint: 'https://github.com/...',
                  maxLines: 1,
                  onSave: (value) async {
                    await notifier.updateRepoLink(value.isEmpty ? null : value);
                  },
                ),
              ),
              if (assignment.repoLink != null &&
                  assignment.repoLink!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: () {
                    final url = assignment.repoLink!;
                    launchUrl(Uri.parse(url));
                  },
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Open repository',
                  color: AppColors.accent,
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: assignment.repoLink!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Repository link copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy link',
                  color: AppColors.textSecondary,
                ),
                IconButton(
                  onPressed: () {
                    final prompt = _evaluationPromptTemplate.replaceAll(
                      '{{REPO_URL}}',
                      assignment.repoLink!,
                    );
                    Clipboard.setData(ClipboardData(text: prompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI evaluation prompt copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Copy AI evaluation prompt',
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoringSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final notifier = ref.read(
      assignmentReviewNotifierProvider(candidateId).notifier,
    );
    final sortedAreas = assignment.areaScores.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Code Review Scores'),
        const SizedBox(height: AppSpacing.md),

        // Weighted score display
        _buildWeightedScoreCard(assignment),
        const SizedBox(height: AppSpacing.md),

        // Individual area scores
        ...sortedAreas.map(
          (area) => _buildAreaScoreCard(context, ref, area, notifier),
        ),
      ],
    );
  }

  Widget _buildWeightedScoreCard(AssignmentReview assignment) {
    final weightedScore = assignment.weightedScore;
    final scoredCount = assignment.areaScores.values
        .where((a) => a.score != null)
        .length;
    final totalCount = assignment.areaScores.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                'Weighted Score',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                scoredCount > 0
                    ? '${weightedScore.toStringAsFixed(2)} / 5.00'
                    : '-- / 5.00',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.accent,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$scoredCount of $totalCount areas scored',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaScoreCard(
    BuildContext context,
    WidgetRef ref,
    AreaScore area,
    AssignmentReviewNotifier notifier,
  ) {
    return _AreaScoreCard(area: area, notifier: notifier);
  }

  Widget _buildGitHistorySection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final notifier = ref.read(
      assignmentReviewNotifierProvider(candidateId).notifier,
    );
    final gitCheck = assignment.gitCheck ?? GitHistoryCheck();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Git History Check'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commit Pattern',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ToggleChips(
                options: const ['Incremental', 'Bulk (1-2)', 'Single commit'],
                value: _getCommitPatternLabel(gitCheck.commitPattern),
                onChanged: (value) {
                  final pattern = _getCommitPatternValue(value);
                  notifier.updateGitCheck(commitPattern: pattern);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    'Suspicious activity:',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ToggleChips(
                    options: const ['No', 'Yes'],
                    value: gitCheck.suspicious ? 'Yes' : 'No',
                    onChanged: (value) {
                      notifier.updateGitCheck(suspicious: value == 'Yes');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AutoSaveTextField(
                initialValue: gitCheck.notes,
                label: 'Git History Notes',
                hint: 'Any observations about commit patterns...',
                maxLines: null,
                readOnly: true,
                onSave: (value) async {
                  await notifier.updateGitCheck(
                    notes: value.isEmpty ? null : value,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCommitPatternLabel(String pattern) {
    switch (pattern) {
      case 'incremental':
        return 'Incremental';
      case 'bulk':
        return 'Bulk (1-2)';
      case 'single':
        return 'Single commit';
      default:
        return 'Incremental';
    }
  }

  String _getCommitPatternValue(String? label) {
    switch (label) {
      case 'Incremental':
        return 'incremental';
      case 'Bulk (1-2)':
        return 'bulk';
      case 'Single commit':
        return 'single';
      default:
        return 'incremental';
    }
  }

  Widget _buildReviewCallSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final notifier = ref.read(
      assignmentReviewNotifierProvider(candidateId).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Review Call'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AutoSaveTextField(
            initialValue: assignment.reviewCallNotes,
            label: 'Review Call Notes',
            hint: 'Notes from the code review call with the candidate...',
            maxLines: 4,
            onSave: (value) async {
              await notifier.updateReviewCallNotes(
                value.isEmpty ? null : value,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFraudAssessmentSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final notifier = ref.read(
      assignmentReviewNotifierProvider(candidateId).notifier,
    );
    final assessment = assignment.fraudAssessment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Fraud Assessment'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assessment Level',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _buildFraudLevelButton(
                    'Genuine',
                    'genuine',
                    AppColors.success,
                    assessment?.level,
                    notifier,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFraudLevelButton(
                    'Some doubt',
                    'some_doubt',
                    AppColors.warning,
                    assessment?.level,
                    notifier,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFraudLevelButton(
                    'High suspicion',
                    'high_suspicion',
                    AppColors.error,
                    assessment?.level,
                    notifier,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AutoSaveTextField(
                initialValue: assessment?.notes,
                label: 'Fraud Assessment Notes',
                hint: 'Any concerns about authenticity...',
                maxLines: null,
                readOnly: true,
                onSave: (value) async {
                  await notifier.updateFraudAssessment(
                    notes: value.isEmpty ? null : value,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFraudLevelButton(
    String label,
    String value,
    Color color,
    String? currentLevel,
    AssignmentReviewNotifier notifier,
  ) {
    final isSelected = currentLevel == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          notifier.updateFraudAssessment(level: isSelected ? null : value);
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
    String candidateName,
  ) {
    final notifier = ref.read(
      assignmentReviewNotifierProvider(candidateId).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Assessment Grade'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Final Decision',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GradeSelector(
                value: assignment.recommendation,
                options: GradeSelector.assessmentGradeOptions,
                onChanged: (value) {
                  notifier.updateRecommendation(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GradeActionButton(
          gradeValue: assignment.recommendation,
          positiveGrades: const {'pass'},
          negativeGrades: const {'reject'},
          candidateId: candidateId,
          candidateName: candidateName,
          nextStatus: CandidateStatus.finalReview,
        ),
      ],
    );
  }

  Widget _buildAiEvaluationSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final eval = assignment.aiEvaluation;
    final hasEval = eval != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('AI Evaluation'),
        const SizedBox(height: AppSpacing.md),

        if (!hasEval)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.surfaceBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 32,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No AI evaluation yet',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Copy the evaluation prompt using the sparkle icon next to the repo link, paste it into an AI tool, then import the JSON result here.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _showImportDialog(context, ref),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Import AI Evaluation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          _buildAiEvaluationDisplay(context, ref, eval),
      ],
    );
  }

  Widget _buildAiEvaluationDisplay(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> eval,
  ) {
    final supplementary =
        eval['supplementaryAnalysis'] as Map<String, dynamic>?;
    final debriefQuestions = eval['debriefQuestions'] as List<dynamic>?;
    final reasoning = eval['recommendationReasoning'] as String?;
    final aiScore = eval['weightedScore'] as num?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card with AI score and actions
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'AI-Generated Evaluation',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  if (aiScore != null) ...[
                    Text(
                      '${aiScore.toStringAsFixed(2)} / 5.00',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.accent,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  TextButton.icon(
                    onPressed: () => _showImportDialog(context, ref),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Re-import'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              if (reasoning != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reasoning,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Supplementary analysis
        if (supplementary != null && supplementary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildSupplementaryAnalysis(supplementary),
        ],

        // Debrief questions
        if (debriefQuestions != null && debriefQuestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildDebriefQuestions(debriefQuestions),
        ],

        // Static interviewer debrief guide
        const SizedBox(height: AppSpacing.md),
        _buildInterviewerDebriefGuide(),
      ],
    );
  }

  Widget _buildSupplementaryAnalysis(Map<String, dynamic> supplementary) {
    const labels = {
      'errorHandling': 'Error Handling & Resilience',
      'security': 'Security Practices',
      'documentation': 'Documentation & Readability',
      'projectStructure': 'Project Structure',
    };

    const icons = {
      'errorHandling': Icons.shield_outlined,
      'security': Icons.lock_outline,
      'documentation': Icons.description_outlined,
      'projectStructure': Icons.folder_outlined,
    };

    final entries = supplementary.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Supplementary Analysis',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          ...entries.map(
            (entry) => _SupplementaryTile(
              label: labels[entry.key] ?? entry.key,
              icon: icons[entry.key] ?? Icons.info_outline,
              content: entry.value.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebriefQuestions(List<dynamic> questions) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'AI-Generated Debrief Questions',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
                Text(
                  '${questions.length} questions',
                  style: AppTypography.label.copyWith(
                    color: AppColors.warning.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          ...questions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final q = entry.value as Map<String, dynamic>;
            return _AiDebriefQuestionTile(idx: idx, question: q);
          }),
        ],
      ),
    );
  }

  Widget _buildInterviewerDebriefGuide() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 22,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Interviewer Debrief Guide',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
                Text(
                  '${kDebriefQuestions.length} questions',
                  style: AppTypography.label.copyWith(
                    color: AppColors.info.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          ...kDebriefQuestions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final q = entry.value;
            return _DebriefQuestionTile(idx: idx, question: q);
          }),
          Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    kDebriefTip,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.info,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.warning, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text('Import AI Evaluation'),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste the JSON output from the AI evaluation below:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        '{\n  "areaScores": { ... },\n  "gitCheck": { ... },\n  ...\n}',
                    hintStyle: AppTypography.bodySmall.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.surfaceBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.surfaceBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              try {
                final text = controller.text.trim();
                // Support pasting JSON wrapped in markdown code blocks
                final cleanJson = text
                    .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
                    .replaceAll(RegExp(r'^```\s*$', multiLine: true), '')
                    .trim();
                final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
                final notifier = ref.read(
                  assignmentReviewNotifierProvider(candidateId).notifier,
                );
                notifier.applyAiEvaluation(parsed);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'AI evaluation imported — scores, git check, fraud assessment, and recommendation updated',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid JSON: $e'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Import & Apply'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.surfaceBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.surfaceBorder)),
        ],
      ),
    );
  }

  static const _evaluationPromptTemplate =
      '''You are a senior backend engineer conducting a code review of a take-home assignment.

## Assignment Brief

The candidate was asked to build a **FastAPI webhook ingestion service** that:
- Accepts incoming webhook payloads via a POST endpoint
- Validates payloads using Pydantic models
- Stores session data in a relational database (SQLite or PostgreSQL)
- Handles duplicate/idempotent webhook deliveries
- Provides a GET endpoint with pagination to retrieve stored sessions
- Includes a Dockerfile for containerized deployment
- Includes tests

## Repository to Review

{{REPO_URL}}

Fetch and analyze ALL files in this public GitHub repository. Examine:
- All Python source files
- Tests
- Dockerfile and docker-compose.yml (if present)
- README and any documentation
- requirements.txt / pyproject.toml / setup.cfg
- Git commit history (commit messages, frequency, patterns)

## Evaluation Instructions

Evaluate the submission across the following areas. For each **scored area**, provide:
- A score from 1 to 5 (1 = poor, 2 = below average, 3 = adequate, 4 = good, 5 = excellent)
- Specific observations with file/line references where possible

For **supplementary areas**, provide detailed qualitative notes only (no numeric score).

---

### SCORED AREAS (these carry weight in final assessment)

#### 1. Code Quality (weight: 25%)
- Clean, idiomatic Python — follows PEP 8 and project conventions
- Meaningful variable/function/class naming
- DRY principle — no unnecessary repetition
- Appropriate use of type hints
- Logical function/method decomposition

#### 2. Correctness (weight: 25%)
- Does the POST endpoint correctly ingest and store webhook payloads?
- Does idempotency handling actually work (unique constraints, pre-check, or both)?
- Does the GET endpoint return paginated results correctly?
- Are edge cases handled (empty payloads, missing fields, malformed JSON)?
- Does the application start and run without errors?

#### 3. Testing (weight: 20%)
- Are there meaningful tests (not just smoke tests)?
- Do tests cover happy path AND edge cases (duplicates, bad payloads, pagination boundaries)?
- Is test setup clean (fixtures, test database, teardown)?
- Test isolation — do tests depend on each other or on external state?
- Are there integration tests for the API endpoints?

#### 4. API Design (weight: 15%)
- Correct HTTP methods and status codes (201 for creation, 409 or 200 for duplicates, 422 for validation errors)
- RESTful URL structure
- Consistent response format (envelope, error schema)
- Pagination implementation (offset vs cursor, consistency under inserts)
- Input validation error messages are clear and actionable

#### 5. DevOps (weight: 15%)
- Dockerfile present and functional
- Efficient layer ordering (requirements before code copy)
- Non-root user in container
- docker-compose.yml for local development (if applicable)
- Environment variable configuration (not hardcoded secrets)
- .dockerignore present

---

### SUPPLEMENTARY AREAS (qualitative notes, no score)

#### 6. Error Handling & Resilience
- How does the app behave when the database is unavailable?
- Are exceptions caught and returned as appropriate HTTP errors (not 500s)?
- Is there any retry logic or graceful degradation?
- Are errors logged with useful context?

#### 7. Security Practices
- Is user input validated before database operations?
- Are SQL queries parameterized (or ORM-managed)?
- Are secrets/credentials hardcoded anywhere?
- Are dependencies pinned and free of known vulnerabilities?
- Is there any authentication/authorization (even if simple)?

#### 8. Documentation & Readability
- README explains how to run the project, run tests, and make API calls
- Code is self-documenting with clear naming
- Docstrings on non-obvious functions
- API documentation (OpenAPI/Swagger auto-generated is fine)

#### 9. Project Structure & Organization
- Logical folder layout (routes, models, services, tests separated)
- Separation of concerns (business logic not in route handlers)
- Configuration management (settings file, env vars)
- Clean dependency management (requirements.txt or pyproject.toml)

---

### GIT HISTORY ANALYSIS

Analyze the repository's commit history and report:
- **commitPattern**: One of "incremental" (many small, logical commits over time), "bulk" (a few large commits), or "single" (one or two commits with all code)
- **suspicious**: true/false — Flag as suspicious if:
  - All commits within a very short window (< 1 hour) despite significant code
  - Commit messages are generic ("update", "fix", "changes") throughout
  - Large blocks of code appear fully formed with no iteration
  - Code style/quality varies dramatically between files (suggesting multiple authors)
- **notes**: Specific observations about commit patterns, timing, and quality

---

### FRAUD ASSESSMENT

Evaluate the likelihood that the candidate genuinely wrote this code:
- **level**: One of "genuine", "some_doubt", or "high_suspicion"
- **notes**: Explain your reasoning. Look for:
  - Inconsistent coding style across files (mix of experienced and novice patterns)
  - Unusually perfect or boilerplate-heavy code with no personal style
  - Comments that look AI-generated (overly formal, explaining obvious things)
  - Test code quality dramatically different from application code quality
  - README quality mismatched with code quality
  - Copy-paste artifacts (leftover template comments, unrelated code)

---

### CANDIDATE-SPECIFIC DEBRIEF QUESTIONS

Based on the actual code in this repository, generate 5 targeted questions for a live debrief call. Each question should:
- Reference specific files, functions, or design decisions in their code
- Test whether the candidate truly understands what they wrote
- Include "what to look for" in a good answer and "red flags" for a bad answer
- Cover different aspects (architecture decisions, error handling, trade-offs, scaling)

Format each question with:
- The question text
- **What to look for**: What a genuine author would say
- **Red flags**: Signs they didn't write or understand the code

---

## OUTPUT FORMAT

Return your evaluation as a single JSON object with this exact structure:

```json
{
  "areaScores": {
    "code_quality": {
      "areaId": "code_quality",
      "displayName": "Code Quality",
      "weight": 25,
      "score": <1-5>,
      "notes": "<detailed observations with file references>"
    },
    "correctness": {
      "areaId": "correctness",
      "displayName": "Correctness",
      "weight": 25,
      "score": <1-5>,
      "notes": "<detailed observations>"
    },
    "testing": {
      "areaId": "testing",
      "displayName": "Testing",
      "weight": 20,
      "score": <1-5>,
      "notes": "<detailed observations>"
    },
    "api_design": {
      "areaId": "api_design",
      "displayName": "API Design",
      "weight": 15,
      "score": <1-5>,
      "notes": "<detailed observations>"
    },
    "devops": {
      "areaId": "devops",
      "displayName": "DevOps",
      "weight": 15,
      "score": <1-5>,
      "notes": "<detailed observations>"
    }
  },
  "supplementaryAnalysis": {
    "errorHandling": "<qualitative notes on error handling & resilience>",
    "security": "<qualitative notes on security practices>",
    "documentation": "<qualitative notes on documentation & readability>",
    "projectStructure": "<qualitative notes on project structure & organization>"
  },
  "gitCheck": {
    "commitPattern": "<incremental|bulk|single>",
    "suspicious": <true|false>,
    "notes": "<specific observations about commit history>"
  },
  "fraudAssessment": {
    "level": "<genuine|some_doubt|high_suspicion>",
    "notes": "<reasoning with specific evidence>"
  },
  "debriefQuestions": [
    {
      "question": "<question referencing their specific code>",
      "whatToLookFor": "<what a genuine author would say>",
      "redFlags": "<signs they didn't write it>"
    }
  ],
  "recommendation": "<strong_yes|yes|maybe|no|strong_no>",
  "recommendationReasoning": "<2-3 sentence justification>",
  "weightedScore": <calculated weighted average as float>
}
```

IMPORTANT:
- Be rigorous but fair. A "3" is a passing score — average, meets requirements.
- Only give a 5 for genuinely impressive work that goes beyond expectations.
- Only give a 1 for fundamentally broken or missing functionality.
- Reference specific files and code patterns in your notes.
- The supplementary analysis notes should be detailed enough to inform a debrief conversation.
- Debrief questions MUST reference actual code from the repository, not generic questions.''';
}

class _AreaScoreCard extends StatefulWidget {
  final AreaScore area;
  final AssignmentReviewNotifier notifier;

  const _AreaScoreCard({required this.area, required this.notifier});

  @override
  State<_AreaScoreCard> createState() => _AreaScoreCardState();
}

class _AreaScoreCardState extends State<_AreaScoreCard> {
  bool _notesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final hasNotes = area.notes != null && area.notes!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(area.displayName, style: AppTypography.titleSmall),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${area.weight}%',
                          style: AppTypography.label.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ScoreSelector(
                  value: area.score,
                  onChanged: (score) {
                    widget.notifier.updateAreaScore(area.areaId, score);
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          InkWell(
            onTap: () => setState(() => _notesExpanded = !_notesExpanded),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notes,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    hasNotes ? 'Notes' : 'Add notes',
                    style: AppTypography.label.copyWith(
                      color: hasNotes
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (hasNotes) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _notesExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_notesExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: AutoSaveTextField(
                initialValue: area.notes,
                hint: 'Notes for ${area.displayName.toLowerCase()}...',
                maxLines: null,
                readOnly: false,
                onSave: (value) async {
                  await widget.notifier.updateAreaNotes(
                    area.areaId,
                    value.isEmpty ? null : value,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SupplementaryTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final String content;

  const _SupplementaryTile({
    required this.label,
    required this.icon,
    required this.content,
  });

  @override
  State<_SupplementaryTile> createState() => _SupplementaryTileState();
}

class _SupplementaryTileState extends State<_SupplementaryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.content,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const Divider(color: AppColors.surfaceBorder, height: 1),
      ],
    );
  }
}

class _AiDebriefQuestionTile extends StatefulWidget {
  final int idx;
  final Map<String, dynamic> question;

  const _AiDebriefQuestionTile({required this.idx, required this.question});

  @override
  State<_AiDebriefQuestionTile> createState() => _AiDebriefQuestionTileState();
}

class _AiDebriefQuestionTileState extends State<_AiDebriefQuestionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final whatToLookFor = q['whatToLookFor'] as String?;
    final redFlags = q['redFlags'] as String?;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.idx}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    q['question'] as String? ?? '',
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (whatToLookFor != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          whatToLookFor,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (redFlags != null) ...[
                  if (whatToLookFor != null)
                    const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          redFlags,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        const Divider(color: AppColors.surfaceBorder, height: 1),
      ],
    );
  }
}

class _DebriefQuestionTile extends StatefulWidget {
  final int idx;
  final Map<String, String> question;

  const _DebriefQuestionTile({required this.idx, required this.question});

  @override
  State<_DebriefQuestionTile> createState() => _DebriefQuestionTileState();
}

class _DebriefQuestionTileState extends State<_DebriefQuestionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final whatToLookFor = q['whatToLookFor'];
    final redFlags = q['redFlags'];

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.idx}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    q['question'] ?? '',
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (whatToLookFor != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          whatToLookFor,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (redFlags != null) ...[
                  if (whatToLookFor != null)
                    const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          redFlags,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        const Divider(color: AppColors.surfaceBorder, height: 1),
      ],
    );
  }
}
