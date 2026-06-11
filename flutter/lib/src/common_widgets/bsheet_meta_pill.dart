import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';

/// Pill méta scrollable de Row 3 (date, catégorie, compte, devise).
/// Utilisée dans les bottom-sheet forms (transaction, abonnement, dette).
class BSheetMetaPill extends StatelessWidget {
  const BSheetMetaPill({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.colorScheme,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isActive ? colorScheme.primary : colorScheme.outlineVariant;
    final textColor =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 5,
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.sizeSm,
            fontWeight: AppTypography.medium,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
