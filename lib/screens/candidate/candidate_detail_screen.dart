import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/candidate.dart';
import '../../providers/candidates_provider.dart';
import '../../providers/data_service_provider.dart';
import '../../providers/save_status_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/save_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_dropdown.dart';
import '../../widgets/reject_dialog.dart';
import 'tabs/profile_tab.dart';
import 'tabs/screening_tab.dart';
import 'tabs/technical_tab.dart';
import 'tabs/assignment_tab.dart';

class CandidateDetailScreen extends ConsumerStatefulWidget {
  final String candidateId;

  const CandidateDetailScreen({
    super.key,
    required this.candidateId,
  });

  @override
  ConsumerState<CandidateDetailScreen> createState() =>
      _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends ConsumerState<CandidateDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(candidateDetailProvider(widget.candidateId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
        data: (detail) => _buildContent(detail),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load candidate',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error.toString(),
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () =>
                ref.invalidate(candidateDetailProvider(widget.candidateId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CandidateDetail detail) {
    final candidate = detail.candidate;

    return Column(
      children: [
        _buildHeader(candidate),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ProfileTab(detail: detail),
              ScreeningTab(candidateId: widget.candidateId),
              TechnicalTab(candidateId: widget.candidateId),
              AssignmentTab(candidateId: widget.candidateId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Candidate candidate) {
    final dataService = ref.read(dataServiceProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Dashboard',
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(candidate.name, style: AppTypography.titleLarge),
                    const SizedBox(width: AppSpacing.md),
                    StatusBadge(status: candidate.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _buildCopyableInfo(
                      context,
                      icon: Icons.email_outlined,
                      value: candidate.email,
                      label: 'Email',
                    ),
                    if (candidate.phone != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      _buildCopyableInfo(
                        context,
                        icon: Icons.phone_outlined,
                        value: candidate.phone!,
                        label: 'Phone',
                      ),
                    ],
                    if (candidate.resumePath != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      TextButton.icon(
                        onPressed: () {
                          final url = dataService.getResumeUrl(
                            candidate.id,
                            candidate.resumePath!.split('/').last,
                          );
                          launchUrl(Uri.parse(url));
                        },
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('Resume'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SaveIndicator(),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  StatusDropdown(
                    value: candidate.status,
                    onChanged: (newStatus) => _updateStatus(candidate, newStatus),
                  ),
                ],
              ),
              if (candidate.meetingLink != null && candidate.scheduledMeetingTime != null)
                _buildMeetingInfo(candidate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingInfo(Candidate candidate) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
          Text(
            '${dateFormat.format(candidate.scheduledMeetingTime!)} at ${timeFormat.format(candidate.scheduledMeetingTime!)}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: candidate.meetingLink!));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meeting link copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Copy Link',
                    style: AppTypography.label.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.copy,
                    size: 12,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableInfo(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label copied to clipboard'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.copy, size: 12, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Screening'),
          Tab(text: 'Technical'),
          Tab(text: 'Assignment'),
        ],
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accent,
        labelStyle: AppTypography.buttonText,
      ),
    );
  }

  Future<void> _updateStatus(Candidate candidate, CandidateStatus newStatus) async {
    if (newStatus == CandidateStatus.rejected) {
      _showRejectDialog(candidate);
      return;
    }

    ref.read(saveStatusProvider.notifier).setSaving();
    try {
      await ref.read(candidatesProvider.notifier).updateCandidate(
        candidate.id,
        {'status': newStatus.value},
      );
      ref.invalidate(candidateDetailProvider(widget.candidateId));
      ref.read(saveStatusProvider.notifier).setSaved();
    } catch (e) {
      ref.read(saveStatusProvider.notifier).setError();
    }
  }

  void _showRejectDialog(Candidate candidate) {
    showDialog(
      context: context,
      builder: (context) => RejectDialog(
        candidateName: candidate.name,
        onReject: (reason) => _rejectCandidate(candidate, reason),
      ),
    );
  }

  Future<void> _rejectCandidate(Candidate candidate, String reason) async {
    ref.read(saveStatusProvider.notifier).setSaving();
    try {
      await ref.read(candidatesProvider.notifier).updateCandidate(
        candidate.id,
        {
          'status': CandidateStatus.rejected.value,
          'rejectionReason': reason,
        },
      );
      ref.invalidate(candidateDetailProvider(widget.candidateId));
      ref.read(saveStatusProvider.notifier).setSaved();
    } catch (e) {
      ref.read(saveStatusProvider.notifier).setError();
    }
  }
}
