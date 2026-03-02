import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/save_status_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SaveIndicator extends ConsumerWidget {
  const SaveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(saveStatusProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _buildContent(status),
    );
  }

  Widget _buildContent(SaveStatus status) {
    switch (status) {
      case SaveStatus.idle:
        return const SizedBox.shrink();
      case SaveStatus.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          key: const ValueKey('saving'),
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Saving...',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case SaveStatus.saved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          key: const ValueKey('saved'),
          children: [
            Icon(Icons.check, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              'Saved',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        );
      case SaveStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          key: const ValueKey('error'),
          children: [
            Icon(Icons.error_outline, size: 14, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'Save failed',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        );
      case SaveStatus.offline:
        return Row(
          mainAxisSize: MainAxisSize.min,
          key: const ValueKey('offline'),
          children: [
            Icon(Icons.cloud_off, size: 14, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'Server offline',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        );
    }
  }
}
