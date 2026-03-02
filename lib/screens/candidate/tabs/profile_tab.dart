import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/candidate.dart';
import '../../../models/screening_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ProfileTab extends ConsumerWidget {
  final CandidateDetail detail;

  const ProfileTab({super.key, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidate = detail.candidate;
    final screening = detail.screening;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _buildSectionCard(
                title: 'Contact',
                child: _buildContactInfo(candidate),
              ),
              _buildSectionCard(
                title: 'Compensation',
                child: _buildCompensationInfo(screening),
              ),
              _buildSectionCard(
                title: 'Availability',
                child: _buildAvailabilityInfo(screening),
              ),
              _buildSectionCard(
                title: 'Timeline',
                child: _buildTimeline(candidate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return SizedBox(
      width: 420,
      child: _buildSection(title: title, child: child),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildContactInfo(Candidate candidate) {
    return Column(
      children: [
        _buildInfoRow(Icons.email_outlined, 'Email', candidate.email),
        if (candidate.phone != null)
          _buildInfoRow(Icons.phone_outlined, 'Phone', candidate.phone!),
      ],
    );
  }

  Widget _buildCompensationInfo(ScreeningData? screening) {
    if (screening == null) {
      return Text(
        'No compensation data yet',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }

    final responses = screening.responses;
    final ctcResponse = responses['screening_03'];

    if (ctcResponse == null) {
      return Text(
        'No compensation data yet',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }

    final currentCtc = ctcResponse.numericValue ?? '—';
    final expectedCtc = ctcResponse.numericValue2 ?? '—';

    return Row(
      children: [
        Expanded(
          child: _buildCompensationCard('Current CTC', '₹$currentCtc LPA'),
        ),
        const SizedBox(width: AppSpacing.md),
        const Icon(Icons.arrow_forward, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildCompensationCard('Expected CTC', '₹$expectedCtc LPA'),
        ),
      ],
    );
  }

  Widget _buildCompensationCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.titleSmall),
        ],
      ),
    );
  }

  Widget _buildAvailabilityInfo(ScreeningData? screening) {
    if (screening == null) {
      return Text(
        'No availability data yet',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }

    final responses = screening.responses;
    final noticeResponse = responses['screening_08'];
    final locationResponse = responses['screening_02'];
    final offersResponse = responses['screening_04'];

    return Column(
      children: [
        if (noticeResponse != null) ...[
          _buildInfoRow(
            Icons.schedule_outlined,
            'Notice Period',
            '${noticeResponse.numericValue ?? '—'} days',
          ),
        ],
        if (locationResponse != null) ...[
          _buildInfoRow(
            Icons.location_on_outlined,
            'Location',
            locationResponse.selectedOption ?? '—',
          ),
        ],
        if (offersResponse != null) ...[
          _buildInfoRow(
            Icons.work_outline,
            'Standing Offers',
            offersResponse.selectedOption ?? '—',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Candidate candidate) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeline = <_TimelineEntry>[
      _TimelineEntry(
        date: candidate.createdAt,
        label: 'Added',
        icon: Icons.person_add_outlined,
      ),
    ];

    for (final change in candidate.timeline) {
      timeline.add(_TimelineEntry(
        date: change.at,
        label: _getStatusChangeLabel(change),
        icon: _getStatusIcon(change.to),
      ));
    }

    timeline.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: timeline.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.icon,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(entry.label, style: AppTypography.bodyMedium),
              ),
              Text(
                dateFormat.format(entry.date),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getStatusChangeLabel(StatusChange change) {
    final toStatus = CandidateStatus.values.firstWhere(
      (s) => s.value == change.to,
      orElse: () => CandidateStatus.newCandidate,
    );
    return toStatus.displayName;
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'screening_sent':
        return Icons.mail_outline;
      case 'screening_done':
        return Icons.check_circle_outline;
      case 'phone_screen':
        return Icons.phone_outlined;
      case 'technical':
        return Icons.code;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'final_review':
        return Icons.star_outline;
      case 'offer':
        return Icons.handshake_outlined;
      case 'hired':
        return Icons.celebration;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

class _TimelineEntry {
  final DateTime date;
  final String label;
  final IconData icon;

  _TimelineEntry({
    required this.date,
    required this.label,
    required this.icon,
  });
}
