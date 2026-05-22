import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:shimmer/shimmer.dart';

class ProfileSettingsSkeleton extends StatelessWidget {
  const ProfileSettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionSkeleton(rowCount: 2),
            const SizedBox(height: AppSpacing.space4),
            _sectionSkeleton(rowCount: 1),
            const SizedBox(height: AppSpacing.space4),
            _sectionSkeleton(rowCount: 2),
            const SizedBox(height: AppSpacing.space4),
            _sectionSkeleton(rowCount: 2),
          ],
        ),
      ),
    );
  }

  Widget _sectionSkeleton({required int rowCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label placeholder
        Container(
          width: 80,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // Container section arrondi
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rowCount; i++) _rowPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
