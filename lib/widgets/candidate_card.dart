import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/candidate.dart';
import '../models/screening_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'grade_indicator.dart';

class CandidateCard extends StatefulWidget {
  final Candidate candidate;
  final VoidCallback onTap;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onTap,
  });

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final candidate = widget.candidate;
    final stage = candidate.effectivePipelineStage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          candidate.name,
          style: AppTypography.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildStageSpecificContent(stage, candidate),
      ],
    );
  }

  Widget _buildStageSpecificContent(PipelineStage stage, Candidate candidate) {
    switch (stage) {
      case PipelineStage.screening:
        return _buildScreeningContent(candidate);
      case PipelineStage.scheduled:
        return _buildScheduledContent(candidate);
      case PipelineStage.technical:
        return _buildTechnicalContent(candidate);
      case PipelineStage.assignment:
        return _buildAssignmentContent(candidate);
      case PipelineStage.finalReview:
        return _buildFinalReviewContent(candidate);
      case PipelineStage.hired:
        return _buildHiredContent(candidate);
      case PipelineStage.rejected:
        return _buildRejectedContent(candidate);
    }
  }

  Widget _buildScheduledContent(Candidate candidate) {
    final grade = candidate.screeningGrade != null
        ? ScreeningGrade.values.firstWhere(
            (g) => g.value == candidate.screeningGrade,
            orElse: () => ScreeningGrade.maybe,
          )
        : null;
    final meetingTime = candidate.scheduledMeetingTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradeIndicator(grade: grade, compact: true),
        const SizedBox(height: AppSpacing.xs),
        if (meetingTime != null)
          Row(
            children: [
              const Icon(
                Icons.videocam,
                size: 14,
                color: AppColors.stageScheduled,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('d MMM, h:mm a').format(meetingTime),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.stageScheduled,
                ),
              ),
            ],
          )
        else
          Text('No meeting scheduled', style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildScreeningContent(Candidate candidate) {
    final grade = candidate.screeningGrade != null
        ? ScreeningGrade.values.firstWhere(
            (g) => g.value == candidate.screeningGrade,
            orElse: () => ScreeningGrade.maybe,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradeIndicator(grade: grade, compact: true),
        const SizedBox(height: AppSpacing.xs),
        Text(candidate.status.displayName, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildTechnicalContent(Candidate candidate) {
    final recommendation = candidate.technicalRecommendation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recommendation != null)
          _buildRecommendationBadge(recommendation)
        else
          Text('Not interviewed', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        _buildTimeAgo(candidate.updatedAt),
      ],
    );
  }

  Widget _buildRecommendationBadge(String recommendation) {
    Color color;
    String label;
    switch (recommendation.toLowerCase()) {
      case 'advance':
        color = AppColors.success;
        label = 'Advance';
        break;
      case 'hold':
        color = AppColors.warning;
        label = 'Hold';
        break;
      case 'reject':
        color = AppColors.error;
        label = 'Reject';
        break;
      default:
        color = AppColors.textTertiary;
        label = recommendation;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: AppTypography.label.copyWith(color: color)),
    );
  }

  Widget _buildAssignmentContent(Candidate candidate) {
    final score = candidate.assignmentScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (score != null)
          Row(
            children: [
              Text('Score: ', style: AppTypography.bodySmall),
              Text(
                score.toStringAsFixed(1),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.getScoreColor(score.round()),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.check, size: 14, color: AppColors.success),
            ],
          )
        else
          Text(
            'Pending',
            style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
          ),
      ],
    );
  }

  Widget _buildFinalReviewContent(Candidate candidate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (candidate.technicalScore != null)
          Text(
            'Technical: ${candidate.technicalScore!.toStringAsFixed(1)}',
            style: AppTypography.bodySmall,
          ),
        if (candidate.assignmentScore != null)
          Text(
            'Assignment: ${candidate.assignmentScore!.toStringAsFixed(1)}',
            style: AppTypography.bodySmall,
          ),
      ],
    );
  }

  Widget _buildHiredContent(Candidate candidate) {
    return Row(
      children: [
        const Icon(Icons.celebration, size: 14, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          'Hired',
          style: AppTypography.bodySmall.copyWith(color: AppColors.success),
        ),
      ],
    );
  }

  Widget _buildRejectedContent(Candidate candidate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rejected',
          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
        if (candidate.rejectionReason != null)
          Text(
            candidate.rejectionReason!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    String text;
    if (diff.inDays > 0) {
      text = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      text = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      text = '${diff.inMinutes}m ago';
    } else {
      text = 'Just now';
    }

    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
    );
  }
}
