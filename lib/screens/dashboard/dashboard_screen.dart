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
import '../../widgets/settings_dialog.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

enum DashboardSort { name, dateAdded }

final dashboardSortProvider =
    StateProvider<DashboardSort>((ref) => DashboardSort.dateAdded);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showAddPanel = false;

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final candidatesAsync = ref.watch(filteredCandidatesProvider(searchQuery));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          candidatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error),
            data: (candidates) => Column(
              children: [
                _buildTopBar(candidates),
                Expanded(child: _buildPipelineView(candidates)),
              ],
            ),
          ),
          if (_showAddPanel)
            AddCandidatePanel(
              onClose: () => setState(() => _showAddPanel = false),
              onCreated: (_) {},
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(List<Candidate> candidates) {
    final rejected = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.rejected)
        .toList();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Text('Overview', style: AppTypography.titleMedium),
          const Spacer(),
          AppSearchBar(
            onChanged: (query) {
              ref.read(searchQueryProvider.notifier).state = query;
            },
          ),
          const SizedBox(width: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showAddPanel = true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Candidate'),
          ),
          const SizedBox(width: AppSpacing.lg),
          if (candidates.any((c) => c.status == CandidateStatus.finalReview))
            IconButton(
              onPressed: () => context.push('/compare'),
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Compare Finalists',
              color: AppColors.textSecondary,
            ),
          const SizedBox(width: AppSpacing.sm),
          _buildRejectedBadge(rejected.length),
          const SizedBox(width: AppSpacing.lg),
          const SaveIndicator(),
          const SizedBox(width: AppSpacing.sm),
          _buildSortButton(),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () => ref.invalidate(candidatesProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  Widget _buildSortButton() {
    final sort = ref.watch(dashboardSortProvider);
    final isByName = sort == DashboardSort.name;
    return IconButton(
      onPressed: () {
        ref.read(dashboardSortProvider.notifier).state =
            isByName ? DashboardSort.dateAdded : DashboardSort.name;
      },
      icon: Icon(isByName ? Icons.sort_by_alpha : Icons.schedule),
      tooltip: isByName ? 'Sorted by name' : 'Sorted by date added',
      color: AppColors.textSecondary,
    );
  }

  Widget _buildRejectedBadge(int count) {
    return Tooltip(
      message: 'Rejected',
      child: InkWell(
        onTap: count == 0 ? null : () => context.push('/rejected'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: AppTypography.label.copyWith(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
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

  List<Candidate> _sortedCandidates(List<Candidate> list) {
    final sort = ref.read(dashboardSortProvider);
    if (sort == DashboardSort.name) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return list;
  }

  Widget _buildPipelineView(List<Candidate> candidates) {
    final sort = ref.watch(dashboardSortProvider);
    final screening = candidates
        .where((c) => c.effectivePipelineStage == PipelineStage.screening)
        .toList();
    final scheduled = candidates
        .where((c) => c.effectivePipelineStage == PipelineStage.scheduled)
        .toList();
    final technical = candidates
        .where((c) => c.effectivePipelineStage == PipelineStage.technical)
        .toList();
    final assignment = candidates
        .where((c) => c.effectivePipelineStage == PipelineStage.assignment)
        .toList();
    final finalReview = candidates
        .where((c) => c.effectivePipelineStage == PipelineStage.finalReview)
        .toList();

    // Apply sort to all columns (scheduled keeps meeting-time order when sorting by date)
    if (sort == DashboardSort.name) {
      for (final list in [screening, scheduled, technical, assignment, finalReview]) {
        _sortedCandidates(list);
      }
    } else {
      _sortedCandidates(screening);
      scheduled.sort((a, b) => (a.scheduledMeetingTime ?? DateTime.now())
          .compareTo(b.scheduledMeetingTime ?? DateTime.now()));
      _sortedCandidates(technical);
      _sortedCandidates(assignment);
      _sortedCandidates(finalReview);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PipelineColumn(
              title: 'Screening',
              candidates: screening,
              onCandidateTap: _navigateToCandidate,
              accentColor: AppColors.stageScreening,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PipelineColumn(
              title: 'Scheduled',
              candidates: scheduled,
              onCandidateTap: _navigateToCandidate,
              accentColor: AppColors.stageScheduled,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PipelineColumn(
              title: 'Technical',
              candidates: technical,
              onCandidateTap: _navigateToCandidate,
              accentColor: AppColors.stageTechnical,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PipelineColumn(
              title: 'Assignment',
              candidates: assignment,
              onCandidateTap: _navigateToCandidate,
              accentColor: AppColors.stageAssignment,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PipelineColumn(
              title: 'Final Review',
              candidates: finalReview,
              onCandidateTap: _navigateToCandidate,
              accentColor: AppColors.stageFinalReview,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCandidate(Candidate candidate) {
    context.push('/candidate/${candidate.id}');
  }

}
