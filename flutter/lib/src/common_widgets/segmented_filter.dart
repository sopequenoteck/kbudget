import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_shadows.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';

class SegmentedFilterItem<T> {
  final T value;
  final String label;

  const SegmentedFilterItem({
    required this.value,
    required this.label,
  }) : assert(label != '', 'SegmentedFilterItem label must not be empty');
}

class SegmentedFilter<T> extends StatelessWidget {
  final List<SegmentedFilterItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  const SegmentedFilter({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  })  : assert(items.length >= 2, 'SegmentedFilter requires at least 2 items'),
        assert(items.length <= 5, 'SegmentedFilter requires at most 5 items');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveSelectedValue =
        items.any((item) => item.value == selectedValue)
            ? selectedValue
            : items.first.value;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(AppSpacing.space1),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        spacing: AppSpacing.space1,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = item.value == effectiveSelectedValue;

          return Expanded(
            child: Semantics(
              toggled: isSelected,
              label: item.label,
              child: GestureDetector(
                onTap: () {
                  if (!isSelected) onChanged(item.value);
                },
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: Curves.easeInOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.surface : null,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: isSelected ? AppShadows.sm : null,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: AppDurations.fast,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppTypography.sizeSm,
                      fontWeight: isSelected
                          ? AppTypography.semiBold
                          : AppTypography.medium,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
