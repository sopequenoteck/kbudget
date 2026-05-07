import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/color_palette_picker.dart';
import 'package:k_budget/src/common_widgets/emoji_input.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_preview_card.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

/// Formulaire de catégorie réutilisable et embeddable sans Scaffold.
///
/// Peut être utilisé en mode standalone (wrappé par [CategoryFormScreen])
/// ou en mode embedded (ex: dans [CategorySelectExpand] en mode création).
///
/// Exemple d'usage en mode création inline :
/// ```dart
/// final _formKey = GlobalKey<CategoryFormWidgetState>();
///
/// CategoryFormWidget(
///   key: _formKey,
///   initialName: 'Courses',
///   onSaved: (category) { /* ... */ },
/// );
///
/// // Déclencher le submit depuis le parent :
/// await _formKey.currentState?.submit();
/// ```
class CategoryFormWidget extends ConsumerStatefulWidget {
  /// Catégorie existante à modifier. Si `null`, le formulaire est en mode création.
  final Category? category;

  /// Valeur initiale du champ nom. Utilisé par [CategorySelectExpand] pour
  /// pré-remplir le nom avec le terme de recherche de l'utilisateur.
  final String? initialName;

  /// Callback appelé après un save réussi (POST ou PUT). Reçoit la [Category]
  /// finale (la catégorie soumise, cohérente avec ce qui a été persist).
  final ValueChanged<Category>? onSaved;

  const CategoryFormWidget({
    super.key,
    this.category,
    this.initialName,
    this.onSaved,
  });

  @override
  CategoryFormWidgetState createState() => CategoryFormWidgetState();
}

/// State publique de [CategoryFormWidget] pour permettre l'accès via
/// [GlobalKey<CategoryFormWidgetState>] depuis un widget parent.
///
/// Le fait que cette classe soit publique (et non privée `_`) est intentionnel :
/// c'est le pattern Flutter idiomatique pour exposer des méthodes comme
/// [submit] à un parent via [GlobalKey] (cf. plan.md CX-001, RES-003).
class CategoryFormWidgetState extends ConsumerState<CategoryFormWidget> {
  bool get _isEditMode => widget.category != null;

  late String _selectedEmoji;
  late String _selectedColor;

  final _nameController = TextEditingController();

  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final c = widget.category!;
      _selectedEmoji = c.icone;
      _selectedColor = c.couleur;
      _nameController.text = c.nom;
    } else {
      _selectedEmoji = '';
      _selectedColor = ColorPalettePicker.paletteColors[
          Random().nextInt(ColorPalettePicker.paletteColors.length)];
      // Pré-remplissage depuis un terme de recherche parent (ex: CategorySelectExpand)
      if (widget.initialName != null && widget.initialName!.isNotEmpty) {
        _nameController.text = widget.initialName!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateNom(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value.trim().isEmpty) return l10n.categoryNameRequired;
    if (value.length > 30) return l10n.categoryNameMaxLength;
    return null;
  }

  String? _validateEmoji() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedEmoji.isEmpty) return l10n.categoryEmojiRequired;
    return null;
  }

  /// Valide les champs du formulaire et soumet la création ou la modification.
  ///
  /// - Si la validation échoue : affiche les erreurs inline via [_showErrors],
  ///   ne lève pas d'exception, n'émet pas [CategoryFormWidget.onSaved].
  /// - Si la validation réussit : appelle [categoryNotifierProvider] `create()`
  ///   ou `update()` selon le mode, puis émet [CategoryFormWidget.onSaved] au succès.
  /// - En cas d'erreur réseau ou serveur : affiche un [SnackBar], reste sur le
  ///   formulaire sans propager l'erreur au parent.
  Future<void> submit() async {
    setState(() => _showErrors = true);

    final nomError = _validateNom(_nameController.text);
    final emojiError = _validateEmoji();

    if (nomError != null || emojiError != null) return;

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(categoryNotifierProvider.notifier);

    if (_isEditMode) {
      final updated = widget.category!.copyWith(
        nom: _nameController.text.trim(),
        icone: _selectedEmoji,
        couleur: _selectedColor,
      );
      await notifier.update(updated);
      if (!mounted) return;
      final errorAfterUpdate = ref.read(categoryNotifierProvider).error;
      if (errorAfterUpdate != null) {
        final isDuplicate = errorAfterUpdate.contains('409') ||
            errorAfterUpdate.toLowerCase().contains('duplicate') ||
            errorAfterUpdate.toLowerCase().contains('existe');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicate
                  ? l10n.categoryNameDuplicate
                  : l10n.categoryErrorUpdate,
            ),
          ),
        );
        return;
      }
      widget.onSaved?.call(updated);
    } else {
      final category = Category(
        id: '',
        nom: _nameController.text.trim(),
        icone: _selectedEmoji,
        couleur: _selectedColor,
      );
      await notifier.create(category);
      if (!mounted) return;
      final errorAfterCreate = ref.read(categoryNotifierProvider).error;
      if (errorAfterCreate != null) {
        final isDuplicate = errorAfterCreate.contains('409') ||
            errorAfterCreate.toLowerCase().contains('duplicate') ||
            errorAfterCreate.toLowerCase().contains('existe');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicate
                  ? l10n.categoryNameDuplicate
                  : l10n.categoryErrorCreate,
            ),
          ),
        );
        return;
      }
      // La category créée est disponible dans le state du notifier.
      // On reconstitue un objet cohérent avec les données soumises.
      final created = Category(
        id: '',
        nom: _nameController.text.trim(),
        icone: _selectedEmoji,
        couleur: _selectedColor,
      );
      widget.onSaved?.call(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final nomError = _showErrors ? _validateNom(_nameController.text) : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        CategoryPreviewCard(
          emoji: _selectedEmoji,
          name: _nameController.text,
          colorHex: _selectedColor,
        ),
        const SizedBox(height: AppSpacing.space6),

        // Emoji + Color row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmojiInput(
              label: l10n.categoryFormIconField,
              initialValue: _selectedEmoji.isNotEmpty ? _selectedEmoji : null,
              onChanged: (emoji) => setState(() => _selectedEmoji = emoji),
              validator: (_) => _showErrors ? _validateEmoji() : null,
              autovalidateMode: _showErrors
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: ColorPalettePicker(
                label: l10n.categoryFormColorField,
                selectedColor: _selectedColor,
                onChanged: (color) => setState(() => _selectedColor = color),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),

        // Name field
        AppFormField(
          label: l10n.categoryFormNameField,
          showError: nomError != null,
          errorMessage: nomError ?? '',
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration.collapsed(hintText: ''),
            style: TextStyle(
              fontSize: AppTypography.sizeMd,
              color: colorScheme.onSurface,
            ),
            maxLength: 30,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.space6),

        const SizedBox(height: AppSpacing.space12),
      ],
    );
  }
}
