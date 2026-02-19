import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_spacing.dart';

/// Indicateur de chargement réutilisable.
///
/// Affiche un [CircularProgressIndicator] centré avec un [message]
/// optionnel en dessous. Utilise les tokens du design system.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});

  /// Message optionnel affiché sous l'indicateur (ex: "Chargement des transactions...").
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              message!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
