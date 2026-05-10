import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

/// Variantes visuelles du bouton Valider du footer.
enum BSheetSubmitVariant {
  /// Bouton Valider en couleur primary (amber) — comportement par défaut.
  primary,

  /// Bouton Valider en couleur error/expense — confirmation dangereuse.
  /// Texte et bordure : [AppThemeExtension.expenseColor].
  danger,
}

/// Variantes privées de la pill d'action (file-scoped — non exporté).
enum _BSheetActionPillVariant {
  /// Bordure + texte [ColorScheme.primary].
  primary,

  /// Bordure [ColorScheme.outline] + texte [ColorScheme.onSurfaceVariant].
  cancel,

  /// Bordure + texte [AppThemeExtension.expenseColor].
  danger,

  /// Bordure [ColorScheme.outline] + texte [ColorScheme.onSurfaceVariant] — état booléen.
  status,

  /// Spinner 16×16 + opacité 0.4 + tap ignoré.
  loading,
}

class _BSheetHandle extends StatelessWidget {
  const _BSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
      ),
    );
  }
}

class _BSheetActionPill extends StatelessWidget {
  const _BSheetActionPill({
    required this.variant,
    required this.label,
    // ignore: unused_element_parameter
    this.icon,
    this.onTap,
    super.key,
  });

  final _BSheetActionPillVariant variant;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isLoading = variant == _BSheetActionPillVariant.loading;

    Color textColor;
    Color borderColor;
    Color highlightColor;
    Color splashColor;

    switch (variant) {
      case _BSheetActionPillVariant.primary:
        textColor = cs.primary;
        borderColor = cs.primary;
        highlightColor = ext.primarySubtle;
        splashColor = ext.primaryMuted;
      case _BSheetActionPillVariant.cancel:
        textColor = cs.onSurfaceVariant;
        borderColor = cs.outline;
        highlightColor = ext.hoverSubtle;
        splashColor = ext.hoverSubtle;
      case _BSheetActionPillVariant.danger:
        textColor = ext.expenseColor;
        borderColor = ext.expenseColor;
        highlightColor = cs.errorContainer.withValues(alpha: 0.6);
        splashColor = cs.errorContainer.withValues(alpha: 0.3);
      case _BSheetActionPillVariant.status:
        textColor = cs.onSurfaceVariant;
        borderColor = cs.outline;
        highlightColor = ext.hoverSubtle;
        splashColor = ext.hoverSubtle;
      case _BSheetActionPillVariant.loading:
        textColor = cs.primary;
        borderColor = cs.primary;
        highlightColor = Colors.transparent;
        splashColor = Colors.transparent;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: AppSpacing.space1),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: textColor,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeSm,
          fontWeight: AppTypography.medium,
          color: textColor,
        ),
      );
    }

    final pill = Opacity(
      opacity: isLoading ? 0.4 : 1.0,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.round),
        highlightColor: highlightColor,
        splashColor: splashColor,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppRadius.round),
          ),
          child: content,
        ),
      ),
    );

    return pill;
  }
}

class _BSheetErrorBanner extends StatelessWidget {
  const _BSheetErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const Key('bsheet_error_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space2,
        horizontal: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: AppTypography.sizeSm,
          color: cs.error,
        ),
      ),
    );
  }
}

/// Squelette composable 4-rows des bottom sheets formulaires.
///
/// Aligné sur le pattern Angular `_bottom-sheet.scss` (.bsheet), ce widget
/// fournit le chrome visuel commun (handle, titre, rows, footer, expand) sans
/// imposer de logique métier. Chaque formulaire (Transaction, Subscription,
/// Debt) injecte ses propres champs via les slots.
///
/// ## Responsabilité clavier
///
/// Pour que [Row 4] reste visible sur le clavier ouvert, l'appelant doit
/// utiliser :
/// ```dart
/// showModalBottomSheet(
///   isScrollControlled: true,
///   builder: (ctx) => Padding(
///     padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
///     child: BottomSheet4RowsWidget(...),
///   ),
/// );
/// ```
///
/// ## Bouton retour Android et zone expand
///
/// Brancher [onExpandClose] sur un `PopScope` parent pour intercepter le
/// bouton retour Android quand la zone expand est ouverte :
/// ```dart
/// PopScope(
///   canPop: expandedSection == null,
///   onPopInvokedWithResult: (didPop, _) {
///     if (!didPop) onExpandClose?.call();
///   },
///   child: BottomSheet4RowsWidget(
///     onExpandClose: () => setState(() => expandedSection = null),
///     ...
///   ),
/// )
/// ```
///
/// ## Exemple d'usage Transaction-like
///
/// ```dart
/// // Dans le parent — gérer l'état expand via ValueNotifier
/// final expandNotifier = ValueNotifier<String?>(null);
///
/// ValueListenableBuilder<String?>(
///   valueListenable: expandNotifier,
///   builder: (context, expandedSection, _) {
///     return BottomSheet4RowsWidget(
///       title: 'Nouvelle transaction',
///       titleIcon: PhosphorIconsRegular.arrowsLeftRight,
///       topTrailing: MyTypeToggle(onChanged: ...),
///       amountField: MyAmountInput(controller: amountCtrl),
///       libelleField: MyLibelleInput(controller: libelleCtrl),
///       metaPills: [
///         MyPill(label: 'Aujourd\'hui', onTap: () => expandNotifier.value = 'date'),
///         MyPill(label: 'Alimentation', onTap: () => expandNotifier.value = 'category'),
///       ],
///       expandedContent: switch (expandedSection) {
///         'date' => InlineDatePicker(...),
///         'category' => CategorySelectExpand(
///             onCreatingChanged: (creating) => setState(() => footerEnabled = !creating),
///           ),
///         _ => null,
///       },
///       onExpandClose: () => expandNotifier.value = null,
///       onCancel: () => Navigator.pop(context),
///       onSubmit: () { /* soumettre */ },
///     );
///   },
/// )
/// ```
class BottomSheet4RowsWidget extends StatelessWidget {
  /// Crée un squelette 4-rows de bottom sheet.
  const BottomSheet4RowsWidget({
    super.key,

    // Row 1 — bsheet_top
    /// Titre affiché en Row 1 (gras, taille secondaire).
    required this.title,

    /// Icône optionnelle à gauche du titre.
    this.titleIcon,

    /// Slot universel Row 1 trailing : type-toggle Tx/Sub/Debt ou widget
    /// arbitraire.
    this.topTrailing,

    // Row 2 — bsheet_main_row
    /// Slot montant hero (obligatoire) — aligné `bsheet__amount`.
    required this.amountField,

    /// Slot libellé optionnel (input direct ou wrapper contenant un input).
    this.libelleField,

    // Slot inter-Row 2/3
    /// Preview note italique 2 lignes — rendu entre Row 2 et Row 3.
    /// Null → absent de l'arbre.
    this.notePreview,

    // Row 3 — bsheet_meta_row (rendu uniquement si non vide)
    /// Icônes gauche Row 3 (note, récurrence, actif, reminder…).
    this.iconButtons,

    /// Pills scrollables droite Row 3 (date, catégorie, compte…).
    /// Row 3 est absente si `metaPills.isEmpty && iconButtons == null`.
    required this.metaPills,

    // Zone expand — entre Row 3 et Row 4
    /// Contenu déployé (InlineDatePicker, CategorySelectExpand…).
    /// Peut être affiché sans pill correspondante dans Row 3 (expand orpheline).
    /// Null → zone expand absente.
    this.expandedContent,

    // Row 4 — bsheet_bottom_row (pinned)
    /// Liste de pills gauche Row 4.
    /// Null → bouton Annuler rendu par défaut via [onCancel].
    /// Non null → Annuler non rendu ; le parent gère toute la zone gauche.
    this.footerLeading,

    /// Callback bouton Annuler — ignoré si [footerLeading] != null.
    this.onCancel,

    /// Callback bouton Valider (obligatoire).
    required this.onSubmit,

    /// Label du bouton Annuler. Défaut : `'Annuler'`.
    this.cancelLabel = 'Annuler',

    /// Label du bouton Valider. Défaut : `'Valider'`.
    this.submitLabel = 'Valider',

    // États
    /// `true` → spinner sur Valider + tap ignoré + opacité 0.4 sur bouton.
    this.loading = false,

    /// Message d'erreur — bandeau au-dessus de Row 1 si non null.
    this.errorMessage,

    /// Variante visuelle du bouton Valider.
    this.submitVariant = BSheetSubmitVariant.primary,

    /// `false` → Row 4 entière désactivée (Opacity 0.4 + IgnorePointer).
    this.footerEnabled = true,

    // Navigation
    /// Callback à brancher sur `PopScope` côté parent pour intercepter le
    /// bouton retour Android quand la zone expand est ouverte.
    this.onExpandClose,
  });

  final String title;
  final IconData? titleIcon;
  final Widget? topTrailing;
  final Widget amountField;
  final Widget? libelleField;
  final Widget? notePreview;
  final List<Widget>? iconButtons;
  final List<Widget> metaPills;
  final Widget? expandedContent;
  final List<Widget>? footerLeading;
  final VoidCallback? onCancel;
  final VoidCallback onSubmit;
  final String cancelLabel;
  final String submitLabel;
  final bool loading;
  final String? errorMessage;
  final BSheetSubmitVariant submitVariant;
  final bool footerEnabled;
  final VoidCallback? onExpandClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space2,
              AppSpacing.space4,
              0,
            ),
            child: _BSheetErrorBanner(message: errorMessage!),
          ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1 — bsheet_top
                Container(
                  key: const Key('bsheet_top'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                  ),
                  child: Column(
                    children: [
                      const _BSheetHandle(),
                      Row(
                        children: [
                          if (titleIcon != null) ...[
                            Icon(
                              titleIcon,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.space2),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: AppTypography.sizeMd,
                                fontWeight: AppTypography.semiBold,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          ?topTrailing,
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space3),
                    ],
                  ),
                ),

                // Row 2 — bsheet_main_row
                Container(
                  key: const Key('bsheet_main_row'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      amountField,
                      if (libelleField != null) ...[
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(child: libelleField!),
                      ],
                    ],
                  ),
                ),

                // Note preview — entre Row 2 et Row 3
                if (notePreview != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space2,
                    ),
                    child: KeyedSubtree(
                      key: const Key('bsheet_note_preview'),
                      child: notePreview!,
                    ),
                  ),

                // Row 3 — bsheet_meta_row (absente si vide — CL-001)
                if (iconButtons != null || metaPills.isNotEmpty)
                  Container(
                    key: const Key('bsheet_meta_row'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space3,
                    ),
                    child: Row(
                      children: [
                        if (iconButtons != null) ...iconButtons!,
                        if (iconButtons != null && metaPills.isNotEmpty)
                          const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (int i = 0; i < metaPills.length; i++) ...[
                                  metaPills[i],
                                  if (i < metaPills.length - 1)
                                    const SizedBox(width: AppSpacing.space2),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Zone expand — AnimatedSize (FR-003)
                AnimatedSize(
                  duration: AppDurations.normal,
                  curve: AppDurations.easeOut,
                  alignment: Alignment.topCenter,
                  child: expandedContent != null
                      ? KeyedSubtree(
                          key: const Key('bsheet_expand'),
                          child: expandedContent!,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // Row 4 — bsheet_bottom_row (pinned)
        _buildFooter(context, cs),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme cs) {
    final submitPillVariant = loading
        ? _BSheetActionPillVariant.loading
        : submitVariant == BSheetSubmitVariant.danger
            ? _BSheetActionPillVariant.danger
            : _BSheetActionPillVariant.primary;

    final footer = Container(
      key: const Key('bsheet_bottom_row'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Zone gauche
          if (footerLeading != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < footerLeading!.length; i++) ...[
                  footerLeading![i],
                  if (i < footerLeading!.length - 1)
                    const SizedBox(width: AppSpacing.space2),
                ],
              ],
            )
          else
            _BSheetActionPill(
              key: const Key('bsheet_cancel'),
              variant: _BSheetActionPillVariant.cancel,
              label: cancelLabel,
              onTap: onCancel,
            ),

          const Spacer(),

          // Bouton Valider
          _BSheetActionPill(
            key: const Key('bsheet_submit'),
            variant: submitPillVariant,
            label: submitLabel,
            onTap: loading ? null : onSubmit,
          ),
        ],
      ),
    );

    if (!footerEnabled) {
      return Opacity(
        opacity: 0.4,
        child: IgnorePointer(child: footer),
      );
    }
    return footer;
  }
}
