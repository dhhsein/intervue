import 'package:flutter/material.dart';

import '../models/candidate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'candidate_card.dart';

class PipelineColumn extends StatelessWidget {
  final String title;
  final List<Candidate> candidates;
  final void Function(Candidate) onCandidateTap;
  final Color? accentColor;

  const PipelineColumn({
    super.key,
    required this.title,
    required this.candidates,
    required this.onCandidateTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: candidates.isEmpty
                ? _buildEmptyState()
                : _buildCandidateList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (accentColor != null) ...[
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${candidates.length}',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No candidates',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: candidates.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        return CandidateCard(
          candidate: candidate,
          onTap: () => onCandidateTap(candidate),
        );
      },
    );
  }
}
