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
              onCreated: (id) {
                context.push('/candidate/$id');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(List<Candidate> candidates) {
    final rejected = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.rejected)
        .toList();
    final hired = candidates
        .where((c) => c.status.pipelineStage == PipelineStage.hired)
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
          IconButton(
            onPressed: () => context.push('/compare'),
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Compare Finalists',
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildCountBadge(rejected.length, AppColors.error, 'Rejected', rejected),
          const SizedBox(width: AppSpacing.sm),
          _buildCountBadge(hired.length, AppColors.success, 'Hired', hired),
          const SizedBox(width: AppSpacing.lg),
          const SaveIndicator(),
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

  Widget _buildCountBadge(int count, Color color, String tooltip, List<Candidate> candidates) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: candidates.isEmpty ? null : () => _showCandidateList(tooltip, candidates),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: AppTypography.label.copyWith(
                color: color,
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
