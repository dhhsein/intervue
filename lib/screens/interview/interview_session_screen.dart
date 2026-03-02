import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/technical_round.dart';
import '../../providers/candidates_provider.dart';
import '../../providers/interview_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/auto_save_text_field.dart';
import '../../widgets/score_selector.dart';

class InterviewSessionScreen extends ConsumerStatefulWidget {
  final String candidateId;

  const InterviewSessionScreen({super.key, required this.candidateId});

  @override
  ConsumerState<InterviewSessionScreen> createState() =>
      _InterviewSessionScreenState();
}

class _InterviewSessionScreenState
    extends ConsumerState<InterviewSessionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _showFraudProbe = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = ref.read(interviewProvider);
      if (session != null) {
        setState(() {
          _elapsed = session.elapsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(interviewProvider);
    final candidateAsync = ref.watch(
      candidateDetailProvider(widget.candidateId),
    );

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 48, color: AppColors.warning),
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

    final candidateName =
        candidateAsync.whenOrNull(data: (detail) => detail.candidate.name) ??
        'Candidate';

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(candidateName, session),
            Expanded(child: _buildQuestionArea(session)),
            _buildBottomBar(session),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final session = ref.read(interviewProvider);
    if (session == null) return;

    // Number keys 1-5 for scoring
    if (event.logicalKey == LogicalKeyboardKey.digit1) {
      ref.read(interviewProvider.notifier).updateCurrentScore(score: 1);
    } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
      ref.read(interviewProvider.notifier).updateCurrentScore(score: 2);
    } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
      ref.read(interviewProvider.notifier).updateCurrentScore(score: 3);
    } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
      ref.read(interviewProvider.notifier).updateCurrentScore(score: 4);
    } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
      ref.read(interviewProvider.notifier).updateCurrentScore(score: 5);
    }
    // Arrow keys for navigation
    else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (!session.isLastQuestion) {
        setState(() => _showFraudProbe = false);
        ref.read(interviewProvider.notifier).nextQuestion();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (!session.isFirstQuestion) {
        setState(() => _showFraudProbe = false);
        ref.read(interviewProvider.notifier).previousQuestion();
      }
    }
  }

  Widget _buildHeader(String candidateName, InterviewSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$candidateName — Technical Round',
              style: AppTypography.titleMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_elapsed),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.accent,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ElevatedButton(
            onPressed: _finishRound,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Finish Round'),
          ),
          const SizedBox(width: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Q ${session.currentQuestionIndex + 1} of ${session.selectedQuestions.length}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(InterviewSession session) {
    final question = session.currentQuestion;
    final score = session.currentScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  question.category,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Question text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(question.question, style: AppTypography.bodyLarge),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Fraud probe
              if (question.fraudProbe != null) ...[
                _buildFraudProbe(question.fraudProbe!),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Score selector
              _buildScoreSection(score),
              const SizedBox(height: AppSpacing.lg),

              // Fraud flag
              _buildFraudFlagSection(score),
              const SizedBox(height: AppSpacing.lg),

              // Response quality
              _buildResponseQualitySection(score),
              const SizedBox(height: AppSpacing.lg),

              // Notes
              _buildNotesSection(score),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFraudProbe(String probeText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showFraudProbe = !_showFraudProbe),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showFraudProbe ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  _showFraudProbe ? 'Hide Fraud Probe' : 'Show Fraud Probe',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              probeText,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          crossFadeState: _showFraudProbe
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildScoreSection(QuestionScore score) {
    return Row(
      children: [
        Text(
          'Score',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        ScoreSelector(
          value: score.score,
          onChanged: (value) {
            ref
                .read(interviewProvider.notifier)
                .updateCurrentScore(score: value);
          },
        ),
      ],
    );
  }

  Widget _buildFraudFlagSection(QuestionScore score) {
    return Row(
      children: [
        Text(
          'Fraud',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        _buildFraudDot(
          FraudFlag.none,
          score.fraudFlag,
          'None',
          AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildFraudDot(
          FraudFlag.concern,
          score.fraudFlag,
          'Concern',
          AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildFraudDot(
          FraudFlag.suspect,
          score.fraudFlag,
          'Suspect',
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildFraudDot(
    FraudFlag flag,
    FraudFlag current,
    String label,
    Color color,
  ) {
    final isSelected = flag == current;
    return GestureDetector(
      onTap: () {
        ref
            .read(interviewProvider.notifier)
            .updateCurrentScore(fraudFlag: flag);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseQualitySection(QuestionScore score) {
    final qualities = ['Detailed', 'Textbook', 'Vague', 'Wrong', 'No answer'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Response',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: qualities.map((quality) {
            final isSelected = score.responseQuality == quality;
            return GestureDetector(
              onTap: () {
                ref
                    .read(interviewProvider.notifier)
                    .updateCurrentScore(
                      responseQuality: isSelected ? null : quality,
                    );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Text(
                  quality,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection(QuestionScore score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AutoSaveTextField(
          key: ValueKey('notes_${score.questionId}'),
          initialValue: score.notes ?? '',
          hint: 'Add notes about the response...',
          maxLines: 4,
          onSave: (value) async {
            ref
                .read(interviewProvider.notifier)
                .updateCurrentScore(notes: value.isEmpty ? null : value);
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(InterviewSession session) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: session.isFirstQuestion
                ? null
                : () {
                    setState(() => _showFraudProbe = false);
                    ref.read(interviewProvider.notifier).previousQuestion();
                  },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _showFraudProbe = false);
              ref.read(interviewProvider.notifier).skipCurrentQuestion();
            },
            child: Text(
              'Skip',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          OutlinedButton.icon(
            onPressed: session.isLastQuestion
                ? null
                : () {
                    setState(() => _showFraudProbe = false);
                    ref.read(interviewProvider.notifier).nextQuestion();
                  },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
        ],
      ),
    );
  }

  void _finishRound() {
    context.push('/candidate/${widget.candidateId}/interview/summary');
  }
}
