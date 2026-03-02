import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/technical_round.dart';
import '../../../providers/candidates_provider.dart';
import '../../../providers/questions_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class TechnicalTab extends ConsumerWidget {
  final String candidateId;

  const TechnicalTab({super.key, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(candidateDetailProvider(candidateId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (detail) {
        final technical = detail.technical;
        if (technical == null || !technical.completed) {
          return _buildNoInterviewState(context);
        }
        return _buildInterviewResults(context, ref, technical);
      },
    );
  }

  Widget _buildNoInterviewState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No technical interview yet',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select questions and start an interview session',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => context.push('/candidate/$candidateId/questions'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Technical Interview'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewResults(
    BuildContext context,
    WidgetRef ref,
    TechnicalRound technical,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final duration = Duration(seconds: technical.durationSeconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technical Interview',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(technical.date)} • Duration: $hours:$minutes:$seconds',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildRecommendationBadge(technical.recommendation),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Average score
              _buildScoreSummary(technical),
              const SizedBox(height: AppSpacing.xl),

              // Question scores
              _buildQuestionsSection(ref, technical),
              const SizedBox(height: AppSpacing.xl),

              // Overall impressions
              if (technical.impressions != null)
                _buildImpressionsSection(technical.impressions!),

              // Fraud assessment
              if (technical.fraudAssessment != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _buildFraudSection(technical.fraudAssessment!),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Start new interview button
              Center(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/candidate/$candidateId/questions'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Run Another Interview'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationBadge(String? recommendation) {
    if (recommendation == null) {
      return const SizedBox.shrink();
    }

    Color color;
    String label;
    switch (recommendation.toLowerCase()) {
      case 'advance':
        color = AppColors.success;
        label = 'ADVANCE';
        break;
      case 'hold':
        color = AppColors.warning;
        label = 'HOLD';
        break;
      case 'reject':
        color = AppColors.error;
        label = 'REJECT';
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

  Widget _buildScoreSummary(TechnicalRound technical) {
    final average = technical.averageScore;
    final fraudFlags = technical.questions.where((q) => q.fraudFlag != FraudFlag.none).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Average Score',
            '${average.toStringAsFixed(1)} / 5',
            AppColors.accent,
          ),
          _buildStatItem(
            'Questions',
            '${technical.questions.length}',
            AppColors.info,
          ),
          _buildStatItem(
            'Fraud Flags',
            '$fraudFlags',
            fraudFlags > 0 ? AppColors.warning : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection(WidgetRef ref, TechnicalRound technical) {
    final questionsAsync = ref.watch(allInterviewQuestionsProvider);
    final questionMap = questionsAsync.whenOrNull(
      data: (questions) => {for (var q in questions) q.id: q},
    ) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Question Scores'),
        const SizedBox(height: AppSpacing.md),
        ...technical.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final score = entry.value;
          final question = questionMap[score.questionId];
          final title = question?.question ?? 'Question ${index + 1}';

          return _buildQuestionScoreCard(index, title, score);
        }),
      ],
    );
  }

  Widget _buildQuestionScoreCard(int index, String title, QuestionScore score) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${index + 1}.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _buildScoreBadge(score.score),
              const SizedBox(width: AppSpacing.sm),
              _buildFraudFlagIcon(score.fraudFlag),
            ],
          ),
          if (score.responseQuality != null || score.notes != null) ...[
            const SizedBox(height: AppSpacing.sm),
            if (score.responseQuality != null)
              Container(
                margin: const EdgeInsets.only(left: 30),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  score.responseQuality!,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (score.notes != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  score.notes!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int? score) {
    if (score == null || score == 0) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '-',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final color = AppColors.getScoreColor(score);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '$score',
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFraudFlagIcon(FraudFlag flag) {
    Color color;
    switch (flag) {
      case FraudFlag.none:
        color = AppColors.success;
        break;
      case FraudFlag.concern:
        color = AppColors.warning;
        break;
      case FraudFlag.suspect:
        color = AppColors.error;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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

  Widget _buildImpressionsSection(OverallImpressions impressions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Overall Impressions'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildImpressionRow('Communication', impressions.communication),
              const SizedBox(height: AppSpacing.sm),
              _buildImpressionRow('Depth of Knowledge', impressions.depthOfKnowledge),
              const SizedBox(height: AppSpacing.sm),
              _buildImpressionRow('Problem-Solving', impressions.problemSolving),
              const SizedBox(height: AppSpacing.sm),
              _buildImpressionRow('Culture Fit', impressions.cultureFit),
            ],
          ),
        ),
        if (impressions.redFlags != null || impressions.greenFlags != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (impressions.redFlags != null)
                Expanded(
                  child: _buildFlagCard(
                    'Red Flags',
                    impressions.redFlags!,
                    AppColors.error,
                  ),
                ),
              if (impressions.redFlags != null && impressions.greenFlags != null)
                const SizedBox(width: AppSpacing.md),
              if (impressions.greenFlags != null)
                Expanded(
                  child: _buildFlagCard(
                    'Green Flags',
                    impressions.greenFlags!,
                    AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImpressionRow(String label, int? value) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        ...List.generate(5, (index) {
          final scoreValue = index + 1;
          final isSelected = value == scoreValue;
          final color = AppColors.getScoreColor(scoreValue);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.surfaceBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$scoreValue',
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected ? color : AppColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFlagCard(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudSection(FraudAssessment assessment) {
    Color color;
    String label;
    switch (assessment.level) {
      case 'genuine':
        color = AppColors.success;
        label = 'All genuine';
        break;
      case 'some_doubt':
        color = AppColors.warning;
        label = 'Some doubt';
        break;
      case 'high_suspicion':
        color = AppColors.error;
        label = 'High suspicion';
        break;
      default:
        color = AppColors.textTertiary;
        label = assessment.level;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Fraud Assessment'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(color: color),
                  ),
                ],
              ),
              if (assessment.notes != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  assessment.notes!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
