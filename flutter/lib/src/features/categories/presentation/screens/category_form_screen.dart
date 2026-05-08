import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_form_widget.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Écran navigable de création / modification d'une catégorie.
///
/// Ce widget est un wrapper Scaffold autour de [CategoryFormWidget].
/// Il gère l'AppBar (titre, bouton submit, bouton delete en mode édition)
/// et la navigation (retour liste via [GoRouter]).
///
/// Le formulaire lui-même est délégué à [CategoryFormWidget], accessible
/// via [GlobalKey<CategoryFormWidgetState>] pour déclencher [CategoryFormWidgetState.submit].
class CategoryFormScreen extends ConsumerStatefulWidget {
  /// Catégorie à modifier. Si `null`, l'écran est en mode création.
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  // GlobalKey nécessaire pour invoquer submit() du sous-widget CategoryFormWidget
  // depuis le bouton de l'AppBar — pattern Flutter idiomatique pour ce cas (cf. RES-003).
  final _formKey = GlobalKey<CategoryFormWidgetState>();
  bool _isSubmitting = false;

  bool get _isEditMode => widget.category != null;

  void _onDelete() {
    final l10n = AppLocalizations.of(context)!;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.categoryDeleteConfirmTitle),
        content: Text(l10n.categoryDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      try {
        await ref
            .read(categoryNotifierProvider.notifier)
            .delete(widget.category!.id);
        if (mounted) context.pop();
      } on Exception {
        if (mounted) {
          final l10nInner = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10nInner.categoryErrorDelete)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? l10n.categoryFormTitleEdit
              : l10n.categoryFormTitleCreate,
        ),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.space4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsBold.check, size: 24),
              onPressed: () async {
                setState(() => _isSubmitting = true);
                await _formKey.currentState?.submit();
                if (mounted) setState(() => _isSubmitting = false);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CategoryFormWidget(
              key: _formKey,
              category: widget.category,
              onSaved: (_) => context.pop(),
            ),
            if (_isEditMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space2,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _onDelete,
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.trash,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    label: Text(
                      l10n.delete,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
