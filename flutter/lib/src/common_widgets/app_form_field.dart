import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';

/// Widget réutilisable pour envelopper un champ de formulaire avec un label,
/// un conteneur stylé iOS (fond gris, radius xl, pas de bordure) et un
/// message d'erreur conditionnel.
///
/// Le widget est purement visuel — il ne gère ni validation ni état métier.
/// Les TextField enfants doivent utiliser [InputDecoration.collapsed] pour
/// éviter les doubles styles.
class AppFormField extends StatefulWidget {
  const AppFormField({
    required this.label,
    required this.child,
    this.showError = false,
    this.errorMessage = '',
    super.key,
  });

  final String label;
  final Widget child;
  final bool showError;
  final String errorMessage;

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final showErrorMessage =
        widget.showError && widget.errorMessage.isNotEmpty;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            widget.label,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space2),
          // Conteneur avec focus
          Semantics(
            label: widget.label,
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() => _hasFocus = hasFocus);
              },
              child: AnimatedContainer(
                duration: AppDurations.normal,
                curve: AppDurations.easeInOut,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: _hasFocus
                      ? Border.all(color: colorScheme.primary, width: 1.5)
                      : Border.all(color: Colors.transparent, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space3,
                  horizontal: AppSpacing.space4,
                ),
                child: widget.child,
              ),
            ),
          ),
          // Message d'erreur avec transition et live region
          AnimatedSize(
            duration: AppDurations.normal,
            curve: AppDurations.easeInOut,
            alignment: Alignment.topLeft,
            child: showErrorMessage
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space1),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.errorMessage,
                        style: TextStyle(
                          fontSize: AppTypography.sizeXs,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
