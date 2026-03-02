import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/assignment_review.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/candidates_provider.dart';
import '../../../providers/config_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/auto_save_text_field.dart';
import '../../../widgets/grade_selector.dart';
import '../../../widgets/score_selector.dart';
import '../../../widgets/toggle_chips.dart';

class AssignmentTab extends ConsumerWidget {
  final String candidateId;

  const AssignmentTab({super.key, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync =
        ref.watch(assignmentReviewNotifierProvider(candidateId));

    return assignmentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (assignment) => _buildContent(context, ref, assignment),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
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

              // Dates section
              _buildDatesSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // Submission details
              _buildSubmissionSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // Scoring areas
              _buildScoringSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // Git history check
              _buildGitHistorySection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // Review call notes
              _buildReviewCallSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // Fraud assessment
              _buildFraudAssessmentSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),

              // Recommendation
              _buildRecommendationSection(context, ref, assignment),
              const SizedBox(height: AppSpacing.xl),
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
              child: Text(
                'Assignment Review',
                style: AppTypography.titleLarge,
              ),
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
          style: AppTypography.titleSmall.copyWith(color: AppColors.textTertiary),
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
    final candidateDetail = ref.read(candidateDetailProvider(candidateId)).valueOrNull;

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
    final firstName = candidateDetail?.candidate.name.split(' ').first ?? 'there';

    // Generate email
    final email = _defaultAssignmentEmailTemplate
        .replaceAll('{name}', firstName)
        .replaceAll('{assignment}', config.assignmentBrief!)
        .replaceAll('{interviewer}', config.interviewerName)
        .replaceAll('{company}', config.companyName);

    await Clipboard.setData(ClipboardData(text: email));

    // Update sent date if not already set
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);
    final assignment = ref.read(assignmentReviewNotifierProvider(candidateId)).valueOrNull;
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

  Widget _buildDatesSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  label: 'Sent',
                  date: assignment.sentAt,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: assignment.sentAt ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      await notifier.updateSentDate(picked);
                    }
                  },
                  dateFormat: dateFormat,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDateField(
                  context,
                  label: 'Due',
                  date: assignment.dueAt,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: assignment.dueAt ?? DateTime.now().add(const Duration(days: 3)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      await notifier.updateDueDate(picked);
                    }
                  },
                  dateFormat: dateFormat,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDateField(
                  context,
                  label: 'Submitted',
                  date: assignment.submittedAt,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: assignment.submittedAt ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      await notifier.updateSubmittedDate(picked);
                    }
                  },
                  dateFormat: dateFormat,
                  suffix: assignment.submittedAt != null
                      ? (assignment.onTime ? ' ✓' : ' (late)')
                      : null,
                  suffixColor:
                      assignment.onTime ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          if (assignment.submittedAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Submitted on time:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ToggleChips(
                  options: const ['Yes', 'No'],
                  value: assignment.onTime ? 'Yes' : 'No',
                  onChanged: (value) {
                    notifier.updateOnTime(value == 'Yes');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
    String? suffix,
    Color? suffixColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  date != null ? dateFormat.format(date) : 'Not set',
                  style: AppTypography.bodyMedium.copyWith(
                    color: date != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                if (suffix != null)
                  Text(
                    suffix,
                    style: AppTypography.bodyMedium.copyWith(
                      color: suffixColor ?? AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionSection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission',
            style: AppTypography.titleSmall,
          ),
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
                        ClipboardData(text: assignment.repoLink!));
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
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);
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
        ...sortedAreas.map((area) => _buildAreaScoreCard(
              context,
              ref,
              area,
              notifier,
            )),
      ],
    );
  }

  Widget _buildWeightedScoreCard(AssignmentReview assignment) {
    final weightedScore = assignment.weightedScore;
    final scoredCount =
        assignment.areaScores.values.where((a) => a.score != null).length;
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      area.displayName,
                      style: AppTypography.titleSmall,
                    ),
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
                  notifier.updateAreaScore(area.areaId, score);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AutoSaveTextField(
            initialValue: area.notes,
            hint: 'Notes for ${area.displayName.toLowerCase()}...',
            maxLines: 2,
            onSave: (value) async {
              await notifier.updateAreaNotes(
                  area.areaId, value.isEmpty ? null : value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGitHistorySection(
    BuildContext context,
    WidgetRef ref,
    AssignmentReview assignment,
  ) {
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);
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
                maxLines: 2,
                onSave: (value) async {
                  await notifier.updateGitCheck(
                      notes: value.isEmpty ? null : value);
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
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);

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
            hint:
                'Notes from the code review call with the candidate...',
            maxLines: 4,
            onSave: (value) async {
              await notifier
                  .updateReviewCallNotes(value.isEmpty ? null : value);
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
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);
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
                maxLines: 2,
                onSave: (value) async {
                  await notifier.updateFraudAssessment(
                      notes: value.isEmpty ? null : value);
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
  ) {
    final notifier = ref.read(assignmentReviewNotifierProvider(candidateId).notifier);

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
                onChanged: (value) async {
                  notifier.updateRecommendation(value);

                  // Update candidate status based on grade
                  // Only Pass changes status to Final Review
                  // Hold and Reject do not change status
                  if (value == 'pass') {
                    await ref.read(candidatesProvider.notifier).updateCandidate(
                      candidateId,
                      {'status': 'final_review'},
                    );
                    // Refresh the candidate detail to show updated status
                    ref.invalidate(candidateDetailProvider(candidateId));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
              child: Container(height: 1, color: AppColors.surfaceBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
              child: Container(height: 1, color: AppColors.surfaceBorder)),
        ],
      ),
    );
  }
}
