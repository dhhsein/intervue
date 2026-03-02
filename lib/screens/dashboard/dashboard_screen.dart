import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/candidate.dart';
import '../../providers/candidates_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/add_candidate_panel.dart';
import '../../widgets/pipeline_column.dart';
import '../../widgets/save_indicator.dart';
import '../../widgets/search_bar.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showAddPanel = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildContent()),
            ],
          ),
          if (_showAddPanel)
            AddCandidatePanel(
              onClose: () => setState(() => _showAddPanel = false),
              onCreated: (id) {
                context.push('/candidate/$id');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Text('InterVue', style: AppTypography.titleMedium),
          const Spacer(),
          AppSearchBar(
            onChanged: (query) {
              ref.read(searchQueryProvider.notifier).state = query;
            },
          ),
          const SizedBox(width: AppSpacing.lg),
          const SaveIndicator(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final searchQuery = ref.watch(searchQueryProvider);
    final candidatesAsync = ref.watch(filteredCandidatesProvider(searchQuery));

    return candidatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
      data: (candidates) => _buildPipelineView(candidates),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Could not connect to server',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Make sure the server is running on localhost:3001',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(candidatesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineView(List<Candidate> candidates) {
    final screening = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.screening)
        .toList();
    final technical = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.technical)
        .toList();
    final assignment = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.assignment)
        .toList();
    final finalReview = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.finalReview)
        .toList();
    final rejected = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.rejected)
        .toList();
    final hired = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.hired)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PipelineColumn(
                    title: 'Screening',
                    candidates: screening,
                    onCandidateTap: _navigateToCandidate,
                    accentColor: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PipelineColumn(
                    title: 'Technical',
                    candidates: technical,
                    onCandidateTap: _navigateToCandidate,
                    accentColor: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PipelineColumn(
                    title: 'Assignment',
                    candidates: assignment,
                    onCandidateTap: _navigateToCandidate,
                    accentColor: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PipelineColumn(
                    title: 'Final Review',
                    candidates: finalReview,
                    onCandidateTap: _navigateToCandidate,
                    accentColor: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBottomSummary(rejected, hired),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Pipeline Overview', style: AppTypography.titleLarge),
        ElevatedButton.icon(
          onPressed: () => setState(() => _showAddPanel = true),
          icon: const Icon(Icons.add),
          label: const Text('Add Candidate'),
        ),
      ],
    );
  }

  Widget _buildBottomSummary(List<Candidate> rejected, List<Candidate> hired) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            'Rejected',
            rejected.length,
            AppColors.error,
            onTap: rejected.isEmpty ? null : () => _showCandidateList('Rejected', rejected),
          ),
          const SizedBox(width: AppSpacing.xl),
          _buildSummaryItem(
            'Hired',
            hired.length,
            AppColors.success,
            onTap: hired.isEmpty ? null : () => _showCandidateList('Hired', hired),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.push('/compare'),
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare Finalists'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    int count,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$count',
              style: AppTypography.titleSmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCandidate(Candidate candidate) {
    context.push('/candidate/${candidate.id}');
  }

  void _showCandidateList(String title, List<Candidate> candidates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTypography.titleMedium),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              return ListTile(
                title: Text(candidate.name, style: AppTypography.bodyMedium),
                subtitle: Text(
                  candidate.email,
                  style: AppTypography.bodySmall,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToCandidate(candidate);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
