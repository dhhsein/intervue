import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/technical_round.dart';
import '../../providers/candidates_provider.dart';
import '../../providers/data_service_provider.dart';
import '../../providers/interview_provider.dart';
import '../../providers/questions_provider.dart';
import '../../providers/save_status_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/auto_save_text_field.dart';
import '../../widgets/grade_selector.dart';
import '../../widgets/score_selector.dart';

class InterviewSummaryScreen extends ConsumerStatefulWidget {
  final String candidateId;

  const InterviewSummaryScreen({
    super.key,
    required this.candidateId,
  });

  @override
  ConsumerState<InterviewSummaryScreen> createState() =>
      _InterviewSummaryScreenState();
}

class _InterviewSummaryScreenState
    extends ConsumerState<InterviewSummaryScreen> {
  OverallImpressions _impressions = OverallImpressions();
  FraudAssessment _fraudAssessment = FraudAssessment(level: 'genuine');
  String? _recommendation;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(interviewProvider);

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 48, color: AppColors.warning),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No active interview session',
                style: AppTypography.titleSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go('/candidate/${widget.candidateId}'),
                child: const Text('Return to Candidate'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(session),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionsOverview(session),
                      const SizedBox(height: AppSpacing.xl),
                      _buildOverallImpressions(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildFlagsSection(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildFraudAssessment(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildRecommendation(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSaveButton(session),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(InterviewSession session) {
    final duration = session.elapsed;
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Interview Summary',
              style: AppTypography.titleLarge,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Duration: $hours:$minutes:$seconds',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsOverview(InterviewSession session) {
    final questionsAsync = ref.watch(allInterviewQuestionsProvider);
    final questionMap = questionsAsync.whenOrNull(
      data: (questions) => {for (var q in questions) q.id: q},
    ) ?? {};

    // Calculate average
    final scoredQuestions = session.scores.where((s) => s.score != null && s.score! > 0);
    final average = scoredQuestions.isEmpty
        ? 0.0
        : scoredQuestions.map((s) => s.score!).reduce((a, b) => a + b) /
            scoredQuestions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Questions'),
        const SizedBox(height: AppSpacing.md),
        ...session.scores.asMap().entries.map((entry) {
          final index = entry.key;
          final score = entry.value;
          final question = questionMap[score.questionId];
          final title = question?.question ?? 'Question ${index + 1}';
          // Truncate if too long
          final displayTitle = title.length > 60
              ? '${title.substring(0, 57)}...'
              : title;

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
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
                    displayTitle,
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildScoreBadge(score.score),
                const SizedBox(width: AppSpacing.sm),
                _buildFraudFlagIcon(score.fraudFlag),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Average: ',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${average.toStringAsFixed(1)} / 5',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildOverallImpressions() {
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
              _buildImpressionRow('Communication', _impressions.communication, (v) {
                setState(() {
                  _impressions = OverallImpressions(
                    communication: v,
                    depthOfKnowledge: _impressions.depthOfKnowledge,
                    problemSolving: _impressions.problemSolving,
                    cultureFit: _impressions.cultureFit,
                    redFlags: _impressions.redFlags,
                    greenFlags: _impressions.greenFlags,
                  );
                });
              }),
              const SizedBox(height: AppSpacing.md),
              _buildImpressionRow('Depth of Knowledge', _impressions.depthOfKnowledge, (v) {
                setState(() {
                  _impressions = OverallImpressions(
                    communication: _impressions.communication,
                    depthOfKnowledge: v,
                    problemSolving: _impressions.problemSolving,
                    cultureFit: _impressions.cultureFit,
                    redFlags: _impressions.redFlags,
                    greenFlags: _impressions.greenFlags,
                  );
                });
              }),
              const SizedBox(height: AppSpacing.md),
              _buildImpressionRow('Problem-Solving', _impressions.problemSolving, (v) {
                setState(() {
                  _impressions = OverallImpressions(
                    communication: _impressions.communication,
                    depthOfKnowledge: _impressions.depthOfKnowledge,
                    problemSolving: v,
                    cultureFit: _impressions.cultureFit,
                    redFlags: _impressions.redFlags,
                    greenFlags: _impressions.greenFlags,
                  );
                });
              }),
              const SizedBox(height: AppSpacing.md),
              _buildImpressionRow('Culture Fit', _impressions.cultureFit, (v) {
                setState(() {
                  _impressions = OverallImpressions(
                    communication: _impressions.communication,
                    depthOfKnowledge: _impressions.depthOfKnowledge,
                    problemSolving: _impressions.problemSolving,
                    cultureFit: v,
                    redFlags: _impressions.redFlags,
                    greenFlags: _impressions.greenFlags,
                  );
                });
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpressionRow(String label, int? value, ValueChanged<int?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        ScoreSelector(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFlagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Red Flags',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AutoSaveTextField(
                    initialValue: _impressions.redFlags ?? '',
                    hint: 'Any concerns or warning signs...',
                    maxLines: 2,
                    onSave: (value) async {
                      setState(() {
                        _impressions = OverallImpressions(
                          communication: _impressions.communication,
                          depthOfKnowledge: _impressions.depthOfKnowledge,
                          problemSolving: _impressions.problemSolving,
                          cultureFit: _impressions.cultureFit,
                          redFlags: value.isEmpty ? null : value,
                          greenFlags: _impressions.greenFlags,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Green Flags',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AutoSaveTextField(
                    initialValue: _impressions.greenFlags ?? '',
                    hint: 'Strengths and positive signals...',
                    maxLines: 2,
                    onSave: (value) async {
                      setState(() {
                        _impressions = OverallImpressions(
                          communication: _impressions.communication,
                          depthOfKnowledge: _impressions.depthOfKnowledge,
                          problemSolving: _impressions.problemSolving,
                          cultureFit: _impressions.cultureFit,
                          redFlags: _impressions.redFlags,
                          greenFlags: value.isEmpty ? null : value,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFraudAssessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Fraud Assessment'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _buildFraudOption('genuine', 'All genuine', AppColors.success),
            const SizedBox(width: AppSpacing.md),
            _buildFraudOption('some_doubt', 'Some doubt', AppColors.warning),
            const SizedBox(width: AppSpacing.md),
            _buildFraudOption('high_suspicion', 'High suspicion', AppColors.error),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AutoSaveTextField(
          initialValue: _fraudAssessment.notes ?? '',
          hint: 'Notes about fraud assessment...',
          maxLines: 2,
          onSave: (value) async {
            setState(() {
              _fraudAssessment = FraudAssessment(
                level: _fraudAssessment.level,
                notes: value.isEmpty ? null : value,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildFraudOption(String value, String label, Color color) {
    final isSelected = _fraudAssessment.level == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _fraudAssessment = FraudAssessment(
              level: value,
              notes: _fraudAssessment.notes,
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Technical Grade'),
        const SizedBox(height: AppSpacing.md),
        GradeSelector(
          value: _recommendation,
          options: GradeSelector.technicalGradeOptions,
          onChanged: (value) => setState(() => _recommendation = value),
        ),
      ],
    );
  }

  Widget _buildSaveButton(InterviewSession session) {
    return Center(
      child: SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: () => _saveAndReturn(session),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Save & Return to Candidate',
            style: AppTypography.buttonText,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndReturn(InterviewSession session) async {
    ref.read(saveStatusProvider.notifier).setSaving();

    try {
      // Build the technical round data
      final technicalRound = TechnicalRound(
        candidateId: widget.candidateId,
        date: session.startTime,
        durationSeconds: session.elapsed.inSeconds,
        questions: session.scores,
        impressions: _impressions,
        fraudAssessment: _fraudAssessment,
        recommendation: _recommendation,
        completed: true,
      );

      // Save to server
      final dataService = ref.read(dataServiceProvider);
      await dataService.saveTechnicalRound(widget.candidateId, technicalRound);

      // Clear the interview session
      ref.read(interviewProvider.notifier).endInterview();
      ref.read(selectedQuestionsProvider.notifier).state = {};

      // Status changes are manual — show guidance toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview saved. Update the candidate status manually.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Invalidate candidate detail to refresh
      ref.invalidate(candidateDetailProvider(widget.candidateId));

      ref.read(saveStatusProvider.notifier).setSaved();

      // Navigate back to candidate
      if (mounted) {
        context.go('/candidate/${widget.candidateId}');
      }
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
    }
  }
}
