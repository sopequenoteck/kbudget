import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';

class BSheetTypeToggle extends StatelessWidget {
  const BSheetTypeToggle({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(labels.length, (i) {
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.horizontal(
                left: i == 0 ? const Radius.circular(20) : Radius.zero,
                right: i == labels.length - 1 ? const Radius.circular(20) : Radius.zero,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }),
    );
  }
}
