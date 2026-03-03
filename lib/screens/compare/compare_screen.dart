import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/candidate.dart';
import '../../providers/candidates_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Provider for candidates eligible for comparison (Final Review only).
final comparableCandidatesProvider =
    Provider<AsyncValue<List<Candidate>>>((ref) {
  final candidatesAsync = ref.watch(candidatesProvider);
  return candidatesAsync.whenData((candidates) {
    return candidates.where((c) {
      return c.status == CandidateStatus.finalReview;
    }).toList();
  });
});

/// Provider for selected candidate IDs to compare.
final selectedCandidateIdsProvider =
    StateProvider<Set<String>>((ref) => {});

/// Provider for tracking whether we're viewing the comparison table.
final isComparingProvider = StateProvider<bool>((ref) => false);

/// Provider for fetching details of selected candidates.
final selectedCandidateDetailsProvider =
    FutureProvider<List<CandidateDetail>>((ref) async {
  final selectedIds = ref.watch(selectedCandidateIdsProvider);
  if (selectedIds.isEmpty) return [];

  final details = <CandidateDetail>[];
  for (final id in selectedIds) {
    final detail = await ref.watch(candidateDetailProvider(id).future);
    details.add(detail);
  }
  return details;
});

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(selectedCandidateIdsProvider);
    final isComparing = ref.watch(isComparingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isComparing) {
              ref.read(isComparingProvider.notifier).state = false;
            } else {
              ref.read(selectedCandidateIdsProvider.notifier).state = {};
              context.pop();
            }
          },
        ),
        title: Text(
          'Compare Candidates',
          style: AppTypography.titleMedium,
        ),
        actions: [
          if (isComparing && selectedIds.length >= 2)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: ElevatedButton.icon(
                onPressed: () => _exportComparison(context, ref),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export Summary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: isComparing
          ? _buildComparisonView(context, ref)
          : _buildSelectionView(context, ref),
    );
  }

  Widget _buildSelectionView(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(comparableCandidatesProvider);
    final selectedIds = ref.watch(selectedCandidateIdsProvider);

    return candidatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (candidates) {
        if (candidates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.compare_arrows,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No candidates to compare',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Candidates in Assignment or Final Review stage will appear here',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Select 2-4 candidates to compare',
                    style: AppTypography.titleSmall,
                  ),
                  const Spacer(),
                  if (selectedIds.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(selectedCandidateIdsProvider.notifier).state =
                            {};
                      },
                      child: const Text('Clear Selection'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${selectedIds.length} of 4 selected',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.builder(
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    final isSelected = selectedIds.contains(candidate.id);
                    final canSelect = selectedIds.length < 4 || isSelected;

                    return _buildCandidateSelectionCard(
                      context,
                      ref,
                      candidate,
                      isSelected,
                      canSelect,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedIds.length >= 2
                      ? () {
                          ref.read(isComparingProvider.notifier).state = true;
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: AppColors.surfaceLight,
                    disabledForegroundColor: AppColors.textTertiary,
                  ),
                  child: Text(
                    selectedIds.length >= 2
                        ? 'Compare ${selectedIds.length} Candidates'
                        : 'Select at least 2 candidates',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCandidateSelectionCard(
    BuildContext context,
    WidgetRef ref,
    Candidate candidate,
    bool isSelected,
    bool canSelect,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: canSelect
              ? () {
                  final notifier =
                      ref.read(selectedCandidateIdsProvider.notifier);
                  final current = Set<String>.from(notifier.state);
                  if (isSelected) {
                    current.remove(candidate.id);
                  } else {
                    current.add(candidate.id);
                  }
                  notifier.state = current;
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.surfaceBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.surfaceBorder,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.name,
                        style: AppTypography.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        candidate.email,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(candidate.status),
                const SizedBox(width: AppSpacing.sm),
                if (candidate.technicalScore != null)
                  _buildScoreChip(
                    'Tech',
                    candidate.technicalScore!,
                    AppColors.info,
                  ),
                if (candidate.assignmentScore != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _buildScoreChip(
                    'Assign',
                    candidate.assignmentScore!,
                    AppColors.accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(CandidateStatus status) {
    Color color;
    switch (status) {
      case CandidateStatus.assignment:
        color = const Color(0xFF9B59B6); // Magenta
        break;
      case CandidateStatus.finalReview:
        color = const Color(0xFF00BCD4); // Cyan
        break;
      case CandidateStatus.offer:
        color = const Color(0xFF2ECC71); // Green
        break;
      default:
        color = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.label.copyWith(color: color),
      ),
    );
  }

  Widget _buildScoreChip(String label, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(selectedCandidateDetailsProvider);

    return detailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (details) {
        if (details.isEmpty) {
          return const Center(child: Text('No candidates selected'));
        }
        return _buildComparisonTable(context, ref, details);
      },
    );
  }

  Widget _buildComparisonTable(
    BuildContext context,
    WidgetRef ref,
    List<CandidateDetail> details,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to selection
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(isComparingProvider.notifier).state = false;
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Change Selection'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Comparison table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(context, ref, details),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    List<CandidateDetail> details,
  ) {
    final metrics = _extractMetrics(details);
    const columnWidth = 180.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Header row with candidate names
          _buildTableRow(
            label: '',
            values: details.map((d) => d.candidate.name).toList(),
            isHeader: true,
            columnWidth: columnWidth,
            onViewDetail: (index) {
              context.push('/candidate/${details[index].candidate.id}');
            },
          ),

          // Status
          _buildTableRow(
            label: 'Status',
            values: details.map((d) => d.candidate.status.displayName).toList(),
            columnWidth: columnWidth,
          ),

          // Technical Score
          _buildTableRow(
            label: 'Technical Score',
            values: metrics.map((m) => m['technicalScore'] as String).toList(),
            highlightMax: true,
            numericValues: metrics
                .map((m) => m['technicalScoreNum'] as double?)
                .toList(),
            columnWidth: columnWidth,
          ),

          // Assignment Score
          _buildTableRow(
            label: 'Assignment Score',
            values: metrics.map((m) => m['assignmentScore'] as String).toList(),
            highlightMax: true,
            numericValues: metrics
                .map((m) => m['assignmentScoreNum'] as double?)
                .toList(),
            columnWidth: columnWidth,
          ),

          // Communication
          _buildTableRow(
            label: 'Communication',
            values: metrics.map((m) => m['communication'] as String).toList(),
            highlightMax: true,
            numericValues:
                metrics.map((m) => m['communicationNum'] as double?).toList(),
            columnWidth: columnWidth,
          ),

          // Depth of Knowledge
          _buildTableRow(
            label: 'Depth of Knowledge',
            values:
                metrics.map((m) => m['depthOfKnowledge'] as String).toList(),
            highlightMax: true,
            numericValues: metrics
                .map((m) => m['depthOfKnowledgeNum'] as double?)
                .toList(),
            columnWidth: columnWidth,
          ),

          // Problem Solving
          _buildTableRow(
            label: 'Problem Solving',
            values: metrics.map((m) => m['problemSolving'] as String).toList(),
            highlightMax: true,
            numericValues:
                metrics.map((m) => m['problemSolvingNum'] as double?).toList(),
            columnWidth: columnWidth,
          ),

          // Culture Fit
          _buildTableRow(
            label: 'Culture Fit',
            values: metrics.map((m) => m['cultureFit'] as String).toList(),
            highlightMax: true,
            numericValues:
                metrics.map((m) => m['cultureFitNum'] as double?).toList(),
            columnWidth: columnWidth,
          ),

          // Fraud Flags
          _buildTableRow(
            label: 'Fraud Flags',
            values: metrics.map((m) => m['fraudFlags'] as String).toList(),
            highlightMin: true,
            numericValues:
                metrics.map((m) => m['fraudFlagsNum'] as double?).toList(),
            columnWidth: columnWidth,
          ),

          // Expected CTC
          _buildTableRow(
            label: 'Expected CTC',
            values: metrics.map((m) => m['expectedCtc'] as String).toList(),
            columnWidth: columnWidth,
          ),

          // Notice Period
          _buildTableRow(
            label: 'Notice Period',
            values: metrics.map((m) => m['noticePeriod'] as String).toList(),
            columnWidth: columnWidth,
          ),

          // Technical Recommendation
          _buildTableRow(
            label: 'Tech Recommendation',
            values:
                metrics.map((m) => m['techRecommendation'] as String).toList(),
            columnWidth: columnWidth,
            colorValues:
                metrics.map((m) => _getRecommendationColor(m['techRecommendation'] as String)).toList(),
          ),

          // Assignment Recommendation
          _buildTableRow(
            label: 'Assignment Rec.',
            values: metrics
                .map((m) => m['assignmentRecommendation'] as String)
                .toList(),
            columnWidth: columnWidth,
            colorValues:
                metrics.map((m) => _getRecommendationColor(m['assignmentRecommendation'] as String)).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractMetrics(List<CandidateDetail> details) {
    return details.map((detail) {
      final technical = detail.technical;
      final assignment = detail.assignment;
      final screening = detail.screening;

      // Get CTC from screening (Q3)
      String expectedCtc = '--';
      if (screening?.responses['q3'] != null) {
        final ctc = screening!.responses['q3']!.numericValue2;
        if (ctc != null && ctc.isNotEmpty) {
          expectedCtc = '₹$ctc LPA';
        }
      }

      // Get notice period from screening (Q8)
      String noticePeriod = '--';
      if (screening?.responses['q8'] != null) {
        final notice = screening!.responses['q8']!.numericValue;
        if (notice != null && notice.isNotEmpty) {
          noticePeriod = '$notice days';
        }
      }

      // Technical scores
      final techScore = technical?.averageScore;
      final impressions = technical?.impressions;

      // Fraud flags count
      int fraudFlags = 0;
      if (technical != null) {
        for (final q in technical.questions) {
          if (q.fraudFlag.index > 0) fraudFlags++;
        }
      }

      return {
        'technicalScore':
            techScore != null ? '${techScore.toStringAsFixed(1)} / 5' : '--',
        'technicalScoreNum': techScore,
        'assignmentScore': assignment?.weightedScore != null &&
                assignment!.weightedScore > 0
            ? '${assignment.weightedScore.toStringAsFixed(2)} / 5'
            : '--',
        'assignmentScoreNum': assignment?.weightedScore,
        'communication': impressions?.communication != null
            ? '${impressions!.communication} / 5'
            : '--',
        'communicationNum': impressions?.communication?.toDouble(),
        'depthOfKnowledge': impressions?.depthOfKnowledge != null
            ? '${impressions!.depthOfKnowledge} / 5'
            : '--',
        'depthOfKnowledgeNum': impressions?.depthOfKnowledge?.toDouble(),
        'problemSolving': impressions?.problemSolving != null
            ? '${impressions!.problemSolving} / 5'
            : '--',
        'problemSolvingNum': impressions?.problemSolving?.toDouble(),
        'cultureFit': impressions?.cultureFit != null
            ? '${impressions!.cultureFit} / 5'
            : '--',
        'cultureFitNum': impressions?.cultureFit?.toDouble(),
        'fraudFlags': '$fraudFlags',
        'fraudFlagsNum': fraudFlags.toDouble(),
        'expectedCtc': expectedCtc,
        'noticePeriod': noticePeriod,
        'techRecommendation': technical?.recommendation?.toUpperCase() ?? '--',
        'assignmentRecommendation':
            assignment?.recommendation?.toUpperCase() ?? '--',
      };
    }).toList();
  }

  Color? _getRecommendationColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'advance':
      case 'hire':
        return AppColors.success;
      case 'hold':
        return AppColors.warning;
      case 'reject':
        return AppColors.error;
      default:
        return null;
    }
  }

  Widget _buildTableRow({
    required String label,
    required List<String> values,
    bool isHeader = false,
    bool highlightMax = false,
    bool highlightMin = false,
    List<double?>? numericValues,
    required double columnWidth,
    List<Color?>? colorValues,
    void Function(int)? onViewDetail,
  }) {
    // Find max/min for highlighting
    int? highlightIndex;
    if ((highlightMax || highlightMin) && numericValues != null) {
      double? bestValue;
      for (int i = 0; i < numericValues.length; i++) {
        final val = numericValues[i];
        if (val != null) {
          if (bestValue == null ||
              (highlightMax && val > bestValue) ||
              (highlightMin && val < bestValue)) {
            bestValue = val;
            highlightIndex = i;
          }
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          // Label column
          Container(
            width: 160,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isHeader ? AppColors.surfaceLight : null,
            child: Text(
              label,
              style: isHeader
                  ? AppTypography.titleSmall
                  : AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
          // Value columns
          ...List.generate(values.length, (index) {
            final isHighlighted = index == highlightIndex;
            final textColor = colorValues != null ? colorValues[index] : null;

            return Container(
              width: columnWidth,
              padding: const EdgeInsets.all(AppSpacing.md),
              color: isHeader
                  ? AppColors.surfaceLight
                  : (isHighlighted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : null),
              child: isHeader
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          values[index],
                          style: AppTypography.titleSmall,
                        ),
                        if (onViewDetail != null) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => onViewDetail(index),
                            child: Text(
                              'View Details →',
                              style: AppTypography.label.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      values[index],
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor ?? AppColors.textPrimary,
                        fontWeight:
                            isHighlighted ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _exportComparison(BuildContext context, WidgetRef ref) async {
    final details = await ref.read(selectedCandidateDetailsProvider.future);
    if (details.isEmpty) return;

    final metrics = _extractMetrics(details);
    final exportData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'candidates': List.generate(details.length, (i) {
        final detail = details[i];
        final metric = metrics[i];
        return {
          'id': detail.candidate.id,
          'name': detail.candidate.name,
          'email': detail.candidate.email,
          'status': detail.candidate.status.displayName,
          'metrics': metric,
          'screening': detail.screening?.toJson(),
          'technical': detail.technical?.toJson(),
          'assignment': detail.assignment?.toJson(),
        };
      }),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement()
      ..href = url
      ..download = 'candidate_comparison_${DateTime.now().millisecondsSinceEpoch}.json';

    anchor.click();

    html.Url.revokeObjectUrl(url);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comparison exported successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
