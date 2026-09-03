// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_form_widget.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/string_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ---------------------------------------------------------------------------
// Types privés
// ---------------------------------------------------------------------------

enum _SelectMode { list, create }

// ---------------------------------------------------------------------------
// Helper hex → Color (données métier uniquement, pas de hardcode DESIGN)
// ---------------------------------------------------------------------------

/// Convertit un string hexadécimal `'#RRGGBB'` en [Color] opaque.
///
/// Utilisé exclusivement pour les couleurs de catégories (`cat.couleur`),
/// qui sont des données utilisateur (domaine métier), pas des tokens design.
Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.parse(cleaned, radix: 16);
  return Color(value | 0xFF000000);
}

// ---------------------------------------------------------------------------
// Widget public
// ---------------------------------------------------------------------------

/// Sélecteur de catégorie inline avec recherche et création embedded.
///
/// Opère en deux modes internes :
/// - **`list`** : champ recherche + listbox + bouton `+ Créer « terme »`
///   quand aucune catégorie ne correspond exactement.
/// - **`create`** : header `[← Retour] [✓ Créer]` + embed
///   [CategoryFormWidget] pré-rempli avec le terme de recherche.
///
/// Le changement de mode est notifié au parent via [onCreatingChanged],
/// permettant à un bottom sheet parent de désactiver son footer pendant
/// la création.
///
/// Exemple d'usage :
/// ```dart
/// CategorySelectExpand(
///   categories: categories,
///   selectedId: _selectedCategoryId,
///   onSelected: (id) => setState(() => _selectedCategoryId = id),
///   onCreated: (cat) { /* catégorie nouvellement créée */ },
///   onCreatingChanged: (isCreating) { /* désactiver le footer */ },
/// );
/// ```
class CategorySelectExpand extends StatefulWidget {
  /// Liste des catégories disponibles (préchargée par le parent).
  final List<Category> categories;

  /// ID (`String`) de la catégorie actuellement sélectionnée, ou `null`.
  final String? selectedId;

  /// Callback au tap sur une catégorie. Reçoit l'[id] (`String`).
  final ValueChanged<String> onSelected;

  /// Callback après création réussie via l'embed [CategoryFormWidget].
  /// Reçoit la [Category] complète retournée par le notifier.
  final ValueChanged<Category>? onCreated;

  /// Callback notifiant le parent du changement de mode.
  /// `true` = mode `'create'`, `false` = mode `'list'`.
  final ValueChanged<bool>? onCreatingChanged;

  /// Placeholder du champ recherche.
  /// Défaut : `'Rechercher une catégorie...'`.
  final String? searchPlaceholder;

  const CategorySelectExpand({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onSelected,
    this.onCreated,
    this.onCreatingChanged,
    this.searchPlaceholder,
  });

  @override
  State<CategorySelectExpand> createState() => _CategorySelectExpandState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _CategorySelectExpandState extends State<CategorySelectExpand> {
  final _searchController = TextEditingController();

  /// GlobalKey nécessaire pour invoquer [CategoryFormWidgetState.submit]
  /// depuis le bouton header parent — pattern Flutter idiomatique pour ce cas
  /// (cf. plan.md CX-001 / RES-003). Le widget enfant est créé/détruit avec
  /// le mode `'create'` et ne change jamais de position dans l'arbre, ce qui
  /// évite l'inconvénient classique de GlobalKey.
  final _formKey = GlobalKey<CategoryFormWidgetState>();

  _SelectMode _mode = _SelectMode.list;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    // Reset mode list au dispose (équivalent ngOnDestroy Angular)
    _mode = _SelectMode.list;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Computed
  // ---------------------------------------------------------------------------

  List<Category> get _filteredCategories {
    final query = normalizeForSearch(_searchController.text);
    if (query.isEmpty) return widget.categories;
    return widget.categories
        .where((c) => normalizeForSearch(c.nom).contains(query))
        .toList();
  }

  bool get _hasExactMatch {
    final query = normalizeForSearch(_searchController.text);
    if (query.isEmpty) return true;
    return widget.categories
        .any((c) => normalizeForSearch(c.nom) == query);
  }

  bool get _showCreateButton =>
      _searchController.text.isNotEmpty && !_hasExactMatch;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _pushToCreate() {
    setState(() => _mode = _SelectMode.create);
    widget.onCreatingChanged?.call(true);
  }

  void _backToList() {
    setState(() => _mode = _SelectMode.list);
    widget.onCreatingChanged?.call(false);
    // searchTerm conservé au retour (FR-006 / cohérence Angular)
  }

  void _onCategoryCreated(Category cat) {
    widget.onCreated?.call(cat);
    widget.onSelected(cat.id);
    setState(() {
      _mode = _SelectMode.list;
      _searchController.clear();
      _isSubmitting = false;
    });
    widget.onCreatingChanged?.call(false);
  }

  Future<void> _submitForm() async {
    setState(() => _isSubmitting = true);
    await _formKey.currentState?.submit();
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _SelectMode.list => _buildListMode(context),
      _SelectMode.create => _buildCreateMode(context),
    };
  }

  // ---------------------------------------------------------------------------
  // Mode list
  // ---------------------------------------------------------------------------

  Widget _buildListMode(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filteredCategories;
    final isEmpty =
        widget.categories.isEmpty && _searchController.text.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Champ de recherche
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space2,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.searchPlaceholder ??
                  'Rechercher une catégorie...',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide:
                    BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              isDense: true,
            ),
            style: textTheme.bodyMedium,
          ),
        ),

        // Liste ou état vide
        if (isEmpty)
          _buildEmptyState(context)
        else ...[
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.6,
            ),
            child: filtered.isEmpty
                ? _buildNoResults(context)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryItem(context, filtered[index]),
                  ),
          ),

          // Bouton + Créer «terme»
          if (_showCreateButton)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              child: TextButton(
                onPressed: _pushToCreate,
                child: Text(
                  '+ Créer « ${_searchController.text} »',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category cat) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;
    final isSelected = widget.selectedId == cat.id;

    return InkWell(
      onTap: () => widget.onSelected(cat.id),
      child: Container(
        color: isSelected ? themeExt.primarySubtle : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          children: [
            // Icône avec cercle coloré
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hexToColor(cat.couleur).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  cat.icone,
                  style: const TextStyle(fontSize: AppTypography.sizeMd),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                cat.nom,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Aucune catégorie — créez-en une',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton(
            onPressed: _pushToCreate,
            child: Text(
              '+ Créer',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Text(
        'Aucune catégorie trouvée',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mode create
  // ---------------------------------------------------------------------------

  Widget _buildCreateMode(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header [← Retour] ............. [✓ Créer]
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space2,
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _backToList,
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.arrowLeft,
                  size: 16,
                ),
                label: const Text('Retour'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const PhosphorIcon(
                        PhosphorIconsRegular.check,
                        size: 14,
                      ),
                label: const Text('Créer'),
              ),
            ],
          ),
        ),

        // Formulaire embedded (sans header interne)
        CategoryFormWidget(
          key: _formKey,
          initialName: _searchController.text,
          onSaved: _onCategoryCreated,
        ),
      ],
    );
  }
}
