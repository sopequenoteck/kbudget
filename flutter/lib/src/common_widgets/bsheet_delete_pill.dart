import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Pill Supprimer pour le footer leading en mode édition.
/// Utilisée dans les bottom-sheet forms (transaction, abonnement, dette).
class BSheetDeletePill extends StatelessWidget {
  const BSheetDeletePill({
    super.key,
    required this.isLoading,
    required this.onTap,
    required this.label,
  });

  final bool isLoading;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.round),
      child: Opacity(
        opacity: isLoading ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: cs.error),
            borderRadius: BorderRadius.circular(AppRadius.round),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.trash,
                size: 14,
                color: cs.error,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.medium,
                  color: cs.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
