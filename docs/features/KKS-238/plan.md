# Plan — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter (8 widgets)

> Date : 2026-05-07
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Spec : [spec.md](./spec.md) — Research : [research.md](./research.md) — Clarify : [clarify-log.md](./clarify-log.md)

---

## Constitution Check

Vérification des gates de la Constitution v3.0.0 (Trajectoire B Flutter standalone commercial).

| Gate | Article | Statut | Commentaire |
|------|---------|--------|-------------|
| **API-First / Local-First** | I | ✅ PASS | Composants UI purs sans dépendance réseau (sauf `CategoryFormWidget` qui appelle `categoryNotifierProvider`, lequel respecte déjà la stratégie data mode local/remote du projet). Trajectoire B respectée |
| **Sécurité par défaut** | II | N/A | Composants UI sans gestion d'auth ni d'inputs serveur — non applicable |
| **Simplicité & YAGNI** | III | ✅ PASS | Aucune nouvelle dépendance. Aucune abstraction prématurée (`GlobalKey` justifié pour le pattern parent → état enfant, pas de pattern controller custom). Voir Complexity Tracking |
| **Mobile-First UX** | IV | ✅ PASS | Alignement DESIGN.md v5 strict. `InlineDatePicker` remplace `showDatePicker()` Material (anti-pattern « second sheet empilé »). `CategorySelectExpand` supprime le `Navigator.push` du `category_picker.dart` actuel. Pattern Mobile ≤ 30s respecté |
| **Testabilité** | V | ✅ PASS | NFR-001 impose un widget test par composant × dark + light. Helper `forEachTheme` (RES-012) évite la duplication. Nommage `should_[résultat]_when_[condition]` |
| **Observabilité** | VI | ✅ PASS | NFR-008 ajouté ci-après : aucun `print()`, utilisation de `developer.log` si logging nécessaire. Convention globale `pre-commit-review` |
| **Two Distribution Trajectories** | VII | ✅ PASS | Trajectoire B Flutter — composants destinés au store. Pas de versioning couplé Spring + Angular. Aucune dépendance serveur |

### Dérogations

Aucune dérogation. Toutes les gates passent.

### Complexity Tracking

| # | Complexité ajoutée | Justification | Alternative envisagée |
|---|-------------------|---------------|----------------------|
| CX-001 | `GlobalKey<CategoryFormWidgetState>` dans `CategorySelectExpand` pour invoquer `submit()` du sous-widget | Pattern Flutter idiomatique pour atteindre l'état d'un sous-widget depuis le parent. Le widget `CategoryFormWidget` est créé/détruit avec le mode `'create'`, pas déplacé dans l'arbre — l'inconvénient classique de `GlobalKey` ne s'applique pas (RES-003) | `ValueNotifier<bool> triggerSubmit` rejeté (verbeux) ; controller custom rejeté (sur-ingénierie pour 1 méthode) |
| CX-002 | Extraction `CategoryFormWidget` depuis `CategoryFormScreen` existant (FR-019) | Prérequis à l'embed Option A de `CategorySelectExpand` (CL-003 révisé). Refactor in-place préservant le comportement actuel (RES-004) | Réécriture from scratch rejetée (duplication temporaire, risque divergence) |
| CX-003 | Sub-widgets privés (`_CalendarHeader`, `_CalendarGrid`, `_DayCell`) dans `inline_date_picker.dart` | Reproduction fidèle de la structure Angular (`idp__header`, `idp__grid`, `idp__day`). Permet tests isolés du `_DayCell` (état sélectionné / aujourd'hui / original / disabled) (RES-002) | Code monolithique rejeté (testabilité difficile) |

---

## Résumé de l'approche

Création de **8 composants shared Flutter** + **1 cleanup transversal** (suppression `SegmentedFilter`) + **1 refactor préparatoire** (extraction `CategoryFormWidget` depuis `CategoryFormScreen`). Tous les composants sont 100% UI sans dépendance réseau (Trajectoire B), basés sur les tokens KKS-237 (`AppThemeExtension` 16 props, `AppColors`, `AppTypography`, `AppShadows`). Implémentation custom Flutter pour `InlineDatePicker` (CL-002) et composite stateful pour `CategorySelectExpand` avec embed `CategoryFormWidget` (CL-003). Suivi strict de DESIGN.md v5 et alignement cross-stack avec les composants Angular sources audités le 2026-05-07.

---

## Contexte technique

- **Stack** : Flutter ≥ 3.6, Dart ≥ 3.6, Material 3, Riverpod (`flutter_riverpod`), `phosphor_flutter`, `intl`, `diacritic`
- **Dépendances nouvelles** : **aucune** (conforme NFR-005 — RES validation)
- **Dépendances existantes impactées** :
  - `flutter/lib/src/theme/app_theme_extension.dart` (lecture seule — consommée par les composants)
  - `flutter/lib/src/theme/app_theme.dart` (lecture seule — consommée)
  - `flutter/lib/src/constants/app_*.dart` (lecture seule — consommés)
  - `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` (modification — refactor extraction CategoryFormWidget)
  - `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` (modification — retrait SegmentedFilter)
  - `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` (modification — retrait SegmentedFilter)
  - `flutter/lib/src/common_widgets/segmented_filter.dart` (suppression — FR-015)

### Mapping tokens cross-stack (référence — RES-013)

| Angular token | Flutter equivalent | Niveau |
|---------------|-------------------|--------|
| `--bg-primary` | `colorScheme.surface` | Fond page |
| `--surface-default` | `colorScheme.surfaceContainer` | Cards, conteneurs (`ListGroup`, dialogs) |
| `--surface-raised` | `colorScheme.surfaceContainerHighest` | Header, sticky, FAB (`SectionHeaderSticky.stuck`) |
| `--border-default` | `colorScheme.outlineVariant` | Dividers, borders subtiles |
| `--text-primary` | `colorScheme.onSurface` | Texte principal |
| `--text-secondary` | `colorScheme.onSurfaceVariant` | Texte secondaire |
| `--text-tertiary` | `AppThemeExtension` (à confirmer en implémentation, ou `colorScheme.outline`) | Labels, hints |
| `--icon-circle-bg` | `AppThemeExtension.iconCircleBg` | Wrapper icônes circulaires |
| `--hover-subtle` | `AppThemeExtension.hoverSubtle` | Original cell `InlineDatePicker` mode édition |
| `--color-primary` | `colorScheme.primary` (amber) | CTA, sélection InlineDatePicker, EmptyState CTA, Confirm default |

---

## Architecture

### Structure des fichiers impactés

```
flutter/
├── lib/
│   └── src/
│       ├── common_widgets/                       # Composants shared
│       │   ├── section_header_sticky.dart        # C — US-003 / FR-007
│       │   ├── list_group.dart                   # C — US-004 / FR-008/FR-009
│       │   ├── empty_state_widget.dart           # C — US-006 / FR-011
│       │   ├── variation_badge.dart              # C — US-008 / FR-014
│       │   ├── page_header.dart                  # C — US-005 / FR-010
│       │   ├── confirm_dialog_custom.dart        # C — US-007 / FR-012/FR-013
│       │   ├── inline_date_picker.dart           # C — US-001 / FR-001/FR-002/FR-003
│       │   ├── category_select_expand.dart       # C — US-002 / FR-004/FR-005/FR-006
│       │   └── segmented_filter.dart             # D — supprimé / FR-015
│       ├── features/categories/presentation/
│       │   ├── widgets/
│       │   │   └── category_form_widget.dart     # C — FR-019 (extrait du screen)
│       │   └── screens/
│       │       └── category_form_screen.dart     # M — wrapper Scaffold autour de CategoryFormWidget
│       ├── features/debts/presentation/
│       │   └── debt_list_screen.dart             # M — retrait SegmentedFilter, ajout ChoiceChip / FR-016
│       ├── features/subscriptions/presentation/
│       │   └── subscription_list_screen.dart     # M — retrait SegmentedFilter, ajout ChoiceChip / FR-016
│       └── utils/
│           └── string_utils.dart                 # C — helper normalizeForSearch / RES-010
└── test/
    ├── helpers/
    │   └── theme_test_helpers.dart               # C — forEachTheme / RES-012
    └── src/
        ├── common_widgets/
        │   ├── section_header_sticky_test.dart   # C
        │   ├── list_group_test.dart              # C
        │   ├── empty_state_widget_test.dart      # C
        │   ├── variation_badge_test.dart         # C
        │   ├── page_header_test.dart             # C
        │   ├── confirm_dialog_custom_test.dart   # C
        │   ├── inline_date_picker_test.dart      # C
        │   └── category_select_expand_test.dart  # C
        └── features/categories/presentation/
            ├── widgets/
            │   └── category_form_widget_test.dart # C — tests extraits de category_form_screen_test
            └── screens/
                └── category_form_screen_test.dart # M — adapté au nouveau wrapper Scaffold

Légende : C = créé, M = modifié, D = supprimé
```

### Diagramme de flux principal

```
[Utilisateur tape sur pill date dans bottom sheet transaction]
         ↓
[bsheet__expand activé pour 'date']
         ↓
[InlineDatePicker rendu inline avec value: '2026-05-07']
         ↓
[Tap sur cellule jour 15]
         ↓
[InlineDatePicker.onChanged('2026-05-15')]
         ↓
[Bottom sheet ferme l'expand, met à jour la pill date]


[Utilisateur tape sur pill catégorie dans bottom sheet transaction]
         ↓
[bsheet__expand activé pour 'category']
         ↓
[CategorySelectExpand rendu en mode 'list']
         ↓
[Utilisateur tape "cou" dans recherche]
         ↓
[Filtre liste — pas de match]
         ↓
[Tap sur "+ Créer « cou »"]
         ↓
[Bascule mode 'create' — embed CategoryFormWidget(initialName: 'cou')]
         ↓
[Header [← Retour] [✓ Créer] affiché]
         ↓
[Tap [✓ Créer] → _formKey.currentState!.submit()]
         ↓
[CategoryFormWidget valide → categoryNotifierProvider.create()]
         ↓
[onSaved(Category) → CategorySelectExpand.onCreated(Category)]
         ↓
[Mode 'list' restauré, recherche réinitialisée, nouvelle catégorie sélectionnée]
```

---

## Approche par composant

### Composant 1 : `SectionHeaderSticky`

- **Responsabilité** : Header sticky d'une section dans une liste scrollable, fond dynamique au scroll.
- **Fichiers** : `flutter/lib/src/common_widgets/section_header_sticky.dart` (C)
- **Requirements couverts** : FR-007, FR-017, FR-018
- **Approche** :
  - Public widget `SectionHeaderSticky({String title, int? count, List<Widget>? actions})` qui retourne un `SliverPersistentHeader(pinned: true, delegate: _SectionHeaderDelegate(...))` (RES-001).
  - Private `_SectionHeaderDelegate extends SliverPersistentHeaderDelegate` :
    - `minExtent == maxExtent == 48.0`
    - `build(context, shrinkOffset, overlapsContent)` retourne un `AnimatedContainer(duration: AppDurations.medium, color: shrinkOffset > 0 ? colorScheme.surfaceContainerHighest : Colors.transparent, ...)`
    - `shouldRebuild` compare `title` / `count` / `actions`
  - Pas de Riverpod, `StatelessWidget`.
  - Le widget doit être inséré dans un `CustomScrollView`.

### Composant 2 : `ListGroup`

- **Responsabilité** : Conteneur arrondi `surface-default` avec dividers internes entre enfants.
- **Fichiers** : `flutter/lib/src/common_widgets/list_group.dart` (C)
- **Requirements couverts** : FR-008, FR-009, FR-017, FR-018
- **Approche** :
  - `StatelessWidget` `ListGroup({List<Widget> children})`.
  - Container avec `clipBehavior: Clip.antiAlias`, `borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl))`, `color: colorScheme.surfaceContainer`.
  - Helper privé `_intersperse<Widget>(List<Widget> items, Widget separator)` insère un `Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant)` entre chaque paire (RES-009).
  - Pas de divider après le dernier enfant.

### Composant 3 : `EmptyStateWidget`

- **Responsabilité** : État vide unifié avec icône, message, hint optionnel, CTA text-link optionnel.
- **Fichiers** : `flutter/lib/src/common_widgets/empty_state_widget.dart` (C)
- **Requirements couverts** : FR-011, FR-017, FR-018
- **Approche** :
  - `StatelessWidget` `EmptyStateWidget({IconData? icon, required String message, String? hint, String? ctaLabel, VoidCallback? onCtaTap})`.
  - `Center` → `Column(mainAxisSize: MainAxisSize.min)` avec `padding: EdgeInsets.symmetric(vertical: AppSpacing.s10, horizontal: AppSpacing.s4)`, `gap` via `SizedBox(height: AppSpacing.s2)` entre éléments.
  - Icône (si fournie) : `Icon(icon, size: 48, color: themeExt.textTertiary).withOpacity(0.5)` (à valider sur le token textTertiary, sinon `colorScheme.outline`).
  - Message : `Text(message, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: center)`.
  - Hint (si fourni) : `Text(hint, style: textTheme.bodySmall?.copyWith(color: themeExt.textTertiary), textAlign: center)`.
  - CTA (si fourni) : `TextButton(onPressed: onCtaTap, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, foregroundColor: colorScheme.primary), child: Text(ctaLabel, style: TextStyle(decoration: TextDecoration.underline)))` (RES-007).

### Composant 4 : `VariationBadge`

- **Responsabilité** : Texte coloré delta vs mois précédent avec format `+150,00 € ce mois (+12,5%)` ; masqué si zéro et pas de pourcentage.
- **Fichiers** : `flutter/lib/src/common_widgets/variation_badge.dart` (C)
- **Requirements couverts** : FR-014, FR-017, FR-018
- **Approche** :
  - `StatelessWidget` `VariationBadge({required num delta, String? currency, num? percentage, String suffix = 'ce mois'})`.
  - Si `delta == 0 && percentage == null` → `SizedBox.shrink()` (CL-005).
  - Helper privé `_formatVariation(...)` utilisant `intl.NumberFormat.currency(locale: 'fr_FR', symbol: currency ?? '€', decimalDigits: 2)` pour le montant (RES-006).
  - Pourcentage formaté manuellement : `'${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%'`.
  - Couleur via Switch :
    - `delta > 0` → `colorScheme.tertiary` (à mapper sur `textSuccess` Angular — utiliser `AppThemeExtension.incomeColor` à la place pour cohérence avec les autres usages).
    - `delta < 0` → `AppThemeExtension.expenseColor`.
    - `delta == 0` → `colorScheme.onSurfaceVariant` (text-secondary, pas tertiary).
  - Rendu : `Row(mainAxisSize: MainAxisSize.min, children: [Text(formatted, style: textTheme.bodySmall?.copyWith(color: color, fontWeight: medium))])`.

### Composant 5 : `PageHeader`

- **Responsabilité** : Header de sous-pages avec back button + icône métier optionnelle + titre flex-end.
- **Fichiers** : `flutter/lib/src/common_widgets/page_header.dart` (C)
- **Requirements couverts** : FR-010, FR-017, FR-018
- **Approche** :
  - `StatelessWidget` `PageHeader({required String title, VoidCallback? onBack, Widget? icon})`.
  - `Padding(padding: EdgeInsets.only(bottom: AppSpacing.s4))` → `Row` :
    - Bouton retour : `IconButton(onPressed: onBack, icon: Icon(PhosphorIcons.arrowLeft(), size: 20), style: IconButton.styleFrom(shape: CircleBorder(), fixedSize: Size(36, 36), foregroundColor: colorScheme.onSurface))`.
    - `Spacer()` (équivalent du `flex: 1` Angular pour pousser le titre à droite).
    - Si `icon != null` : `Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: themeExt.iconCircleBg), child: Center(child: icon))` (RES-008).
    - `SizedBox(width: AppSpacing.s2)` entre icône et titre.
    - `Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: AppTypography.bold), textAlign: TextAlign.right)`.
  - **Pas de `trailing` actions** (FR-010, suit strictement Angular).

### Composant 6 : `ConfirmDialogCustom`

- **Responsabilité** : Dialog confirmation avec icône métier, variantes default / danger.
- **Fichiers** : `flutter/lib/src/common_widgets/confirm_dialog_custom.dart` (C)
- **Requirements couverts** : FR-012, FR-013, FR-017, FR-018, NFR-007
- **Approche** :
  - Enum public `ConfirmVariant { primary, danger }` (note : `default` réservé Dart → `primary`).
  - Méthode statique `static Future<bool?> show({required BuildContext context, IconData? icon, required String title, String? message, String confirmLabel = 'Confirmer', String cancelLabel = 'Annuler', ConfirmVariant variant = ConfirmVariant.primary})` (RES-005).
  - Implémentation : `showDialog<bool>(context: context, barrierDismissible: true, builder: (ctx) => Dialog(child: _ConfirmDialogContent(...)))`.
  - `_ConfirmDialogContent` privé : `Padding` → `Column(mainAxisSize: min)` :
    - Header : `Row` avec `Icon(icon, size: 20, color: colorScheme.onSurface)` + `SizedBox(width: AppSpacing.s2)` + `Text(title, style: titleMedium bold)`.
    - Message (si fourni) : `Text(message, style: bodyMedium)`.
    - Actions : `Row(mainAxisAlignment: spaceBetween)` :
      - Cancel : `OutlinedButton.icon(icon: Icon(PhosphorIcons.x(), size: 14), label: Text(cancelLabel), onPressed: () => Navigator.of(ctx).pop(false))`.
      - Confirm : `FilledButton.icon(icon: Icon(variant == danger ? PhosphorIcons.trash() : PhosphorIcons.check(), size: 14), label: Text(confirmLabel), onPressed: () => Navigator.of(ctx).pop(true), style: FilledButton.styleFrom(backgroundColor: variant == danger ? colorScheme.error : colorScheme.primary))`.
  - NFR-007 (back button Android) : géré nativement par `showDialog` (Navigator pop = false).

### Composant 7 : `InlineDatePicker`

- **Responsabilité** : Calendrier inline custom Flutter, format ISO, support `originalValue` mode édition.
- **Fichiers** : `flutter/lib/src/common_widgets/inline_date_picker.dart` (C, ~250 lignes)
- **Requirements couverts** : FR-001, FR-002, FR-003, FR-017, FR-018
- **Approche** :
  - `StatefulWidget` `InlineDatePicker({required String value, required ValueChanged<String> onChanged, String? originalValue, String? minDate, String? maxDate})`.
  - State `_InlineDatePickerState` :
    - `late int _currentMonth, _currentYear` initialisés depuis `value` ou `DateTime.now()`.
    - `_calendarDays` calculé via `_computeDays()` à chaque rebuild.
    - Méthodes `_prevMonth()`, `_nextMonth()`, `_goToToday()`, `_selectDay(_CalendarDay day)`.
  - Sub-widgets privés (RES-002) :
    - `_CalendarHeader({String monthLabel, VoidCallback onPrev, VoidCallback onNext, VoidCallback onLabelTap})` : `Row` avec 2 boutons nav circulaires 28×28 + label cliquable centré.
    - `_CalendarGrid({List<_CalendarDay> days, ValueChanged<_CalendarDay> onSelectDay})` : `GridView.count(crossAxisCount: 7)` ou plutôt `Column` de 7 colonnes via `Wrap` pour contrôle exact.
    - `_DayCell({_CalendarDay day, VoidCallback onTap})` : `InkWell` 36×36 cercle avec couleur fond / texte selon état.
  - Helpers `_toIsoDate(DateTime)`, `_isoToDate(String)`, `_computeDays()`, `_normalizeStartOffset()`.
  - Lundi-first hardcodé : `firstDay.weekday - 1` (Dart `weekday` est 1=lundi).

### Composant 8 : `CategorySelectExpand`

- **Responsabilité** : Sélecteur de catégorie inline, 2 modes (`'list'` / `'create'`), embed `CategoryFormWidget` en mode création.
- **Fichiers** : `flutter/lib/src/common_widgets/category_select_expand.dart` (C, ~200 lignes)
- **Requirements couverts** : FR-004, FR-005, FR-006, FR-017, FR-018, dépend de FR-019
- **Approche** :
  - `StatefulWidget` `CategorySelectExpand({required List<Category> categories, String? selectedId, required ValueChanged<String> onSelected, ValueChanged<Category>? onCreated, ValueChanged<bool>? onCreatingChanged, String? searchPlaceholder})`.
  - State `_CategorySelectExpandState` :
    - `_mode: _SelectMode` (enum `list` / `create`)
    - `_searchController: TextEditingController`
    - `_formKey: GlobalKey<CategoryFormWidgetState>` (RES-003)
  - Mode `'list'` :
    - Champ recherche `TextField` (lié à `_searchController`)
    - `_filteredCategories` computed via `normalizeForSearch` (RES-010)
    - `ListView.builder` ou `Column` de tiles `Category` (icon + nom)
    - Bouton `+ Créer « terme »` apparent quand `_searchController.text.isNotEmpty && !hasExactMatch`
  - Mode `'create'` :
    - Header `[← Retour] [✓ Créer]` — `[✓ Créer]` invoque `_formKey.currentState?.submit()`
    - `CategoryFormWidget(key: _formKey, initialName: _searchController.text, onSaved: _onCreated, onCancelled: _backToList, showHeader: false)`
  - `_setMode(_SelectMode mode)` notifie via `onCreatingChanged(mode == _SelectMode.create)`.
  - `dispose()` : reset `_mode = list` (équivalent `ngOnDestroy` Angular).

### Composant 9 : Extraction `CategoryFormWidget` (FR-019)

- **Responsabilité** : Formulaire de catégorie réutilisable, embeddable sans Scaffold.
- **Fichiers** :
  - `flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart` (C, ~150 lignes)
  - `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` (M — devient un wrapper Scaffold de ~30 lignes)
- **Requirements couverts** : FR-019
- **Approche** (RES-004) :
  - `ConsumerStatefulWidget` `CategoryFormWidget({Category? category, String? initialName, ValueChanged<Category>? onSaved, VoidCallback? onCancelled, bool showHeader = true})`.
  - State **publique** `class CategoryFormWidgetState extends ConsumerState<CategoryFormWidget>` (pas private — pour exposer `submit()` via `GlobalKey`).
  - Méthode publique `Future<void> submit()` : valide nom + emoji, affiche erreurs inline via `_showErrors = true`, appelle `categoryNotifierProvider.notifier.create()` ou `.update()`, émet `onSaved(category)` au succès.
  - Erreurs serveur : `SnackBar` (cohérent comportement actuel — pas de propagation au parent).
  - `CategoryFormScreen` devient :
    ```dart
    class CategoryFormScreen extends StatefulWidget {
      final Category? category;
      const CategoryFormScreen({super.key, this.category});
      @override
      State<CategoryFormScreen> createState() => _CategoryFormScreenState();
    }
    class _CategoryFormScreenState extends State<CategoryFormScreen> {
      final _formKey = GlobalKey<CategoryFormWidgetState>();
      bool _isSubmitting = false;
      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: ..., actions: [submit button → _formKey.currentState?.submit()]),
          body: CategoryFormWidget(category: widget.category, key: _formKey, onSaved: (_) => context.pop(), showHeader: false),
        );
      }
    }
    ```

### Cleanup transversal : Suppression `SegmentedFilter`

- **Responsabilité** : Retirer le composant `SegmentedFilter` (DESIGN.md anti-pattern) et adapter les 2 sites consommateurs.
- **Fichiers** :
  - `flutter/lib/src/common_widgets/segmented_filter.dart` (D — supprimé)
  - `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` (M)
  - `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` (M)
  - `flutter/test/.../segmented_filter_test.dart` (D — si existe)
- **Requirements couverts** : FR-015, FR-016
- **Approche** (RES-011) :
  - Supprimer `segmented_filter.dart` et son test.
  - Dans chaque écran consommateur :
    - Retirer `import 'package:k_budget/src/common_widgets/segmented_filter.dart';`
    - Remplacer le widget `SegmentedFilter<DebtStatusFilter>(items: [...], selectedValue: ..., onChanged: ...)` par :
      ```dart
      // TODO KKS-240 : remplacer par groupement + sections (DESIGN.md anti-pattern segmented control)
      Wrap(
        spacing: AppSpacing.s2,
        children: items.map((item) => ChoiceChip(
          label: Text(item.label),
          selected: selectedValue == item.value,
          onSelected: (_) => onChanged(item.value),
        )).toList(),
      )
      ```
  - Adapter / supprimer les tests qui dépendent du `SegmentedFilter` dans `debt_list_screen_test.dart` et `subscription_list_screen_test.dart`.

### Helper : `normalizeForSearch`

- **Fichier** : `flutter/lib/src/utils/string_utils.dart` (C)
- **Approche** (RES-010) :
  ```dart
  import 'package:diacritic/diacritic.dart';
  String normalizeForSearch(String input) => removeDiacritics(input.toLowerCase()).trim();
  ```
- **Refactor optionnel** (différable au plan) : migrer `transaction_repository_local.dart:71` pour utiliser ce helper public au lieu du `_normalize` privé.

### Helper de tests : `forEachTheme`

- **Fichier** : `flutter/test/helpers/theme_test_helpers.dart` (C)
- **Approche** (RES-012) :
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:k_budget/src/theme/app_theme.dart';

  void forEachTheme(void Function(ThemeData theme, String themeName) body) {
    body(AppTheme.dark, 'dark');
    body(AppTheme.light, 'light');
  }

  Widget wrapWithTheme(ThemeData theme, Widget child) {
    return MaterialApp(theme: theme, home: Scaffold(body: child));
  }
  ```

---

## Couverture FR ↔ Composant

| FR | Composant | Statut |
|----|-----------|--------|
| FR-001 / FR-002 / FR-003 | `InlineDatePicker` | Plan défini |
| FR-004 / FR-005 / FR-006 | `CategorySelectExpand` | Plan défini |
| FR-007 | `SectionHeaderSticky` | Plan défini |
| FR-008 / FR-009 | `ListGroup` | Plan défini |
| FR-010 | `PageHeader` | Plan défini |
| FR-011 | `EmptyStateWidget` | Plan défini |
| FR-012 / FR-013 | `ConfirmDialogCustom` | Plan défini |
| FR-014 | `VariationBadge` | Plan défini |
| FR-015 / FR-016 | Cleanup `SegmentedFilter` | Plan défini |
| FR-017 / FR-018 | Transversal (tous composants) | Garanti par tokens + helper `forEachTheme` |
| FR-019 | Extraction `CategoryFormWidget` | Plan défini |

**Couverture** : 19/19 FR (100%).

---

## NFR ajoutés au plan

| NFR | Description | Méthode de vérification |
|-----|-------------|------------------------|
| NFR-008 (nouveau, INFO-05 review-spec) | Aucun `print()` dans les composants livrés — `developer.log` ou logging contrôlé uniquement (Constitution Principe VI) | Couvert par `pre-commit-review` global ; vérification manuelle au review-impl |
| NFR-007 (correction INFO-03) | NFR-007 (back button Android) ne concerne **que `ConfirmDialogCustom`** — `InlineDatePicker` est inline et le back button est géré par le parent (bottom sheet) | Widget test `ConfirmDialogCustom` : simuler back button, vérifier `Future<bool?>` retourne `null` |

---

## Risques et mitigations

| # | Risque | Impact | Probabilité | Mitigation |
|---|--------|--------|-------------|------------|
| R-1 | Extraction `CategoryFormWidget` casse le comportement actuel de `CategoryFormScreen` (création depuis liste catégories) | Haut | Moyen | Tests manuels du parcours `Liste catégories → + → CategoryFormScreen` au review-impl ; conserver les tests existants `category_form_screen_test.dart` adaptés au wrapper |
| R-2 | Pattern `GlobalKey<CategoryFormWidgetState>` mal compris par les futurs développeurs (anti-pattern apparent) | Moyen | Bas | Documentation `///` explicite sur le `_formKey` privé : « GlobalKey nécessaire pour invoquer `submit()` du sous-widget — pattern Flutter idiomatique pour ce cas (cf. RES-003) » |
| R-3 | `SliverPersistentHeader` rendu partiel ou non sticky dans certains layouts (ex : `NestedScrollView`) | Moyen | Moyen | Test d'intégration sur un `CustomScrollView` simple ; documentation indique que le composant est pensé pour `CustomScrollView`, pas `NestedScrollView` |
| R-4 | `InlineDatePicker` calcul `startOffset` (lundi-first) bug à la frontière des mois (1er jour = dimanche) | Moyen | Moyen | Widget tests sur les 12 premiers mois de 2026 + tests sur février bissextile 2024 ; helper `_normalizeStartOffset` testé unitairement |
| R-5 | Suppression `SegmentedFilter` casse les tests `debt_list_screen` et `subscription_list_screen` | Bas | Haut | Adapter les tests dans la même PR ; faire passer `flutter test` avant commit |
| R-6 | Performance dégradée sur `ListGroup` avec 100+ enfants (rebuild liste complète) | Bas | Bas | Pas un cas d'usage — `ListGroup` est conçu pour 5-30 items max ; documenter dans `///` |
| R-7 | Mapping token `--text-tertiary` Flutter incertain (RES-013 indique « à confirmer ») | Bas | Moyen | Audit en début d'implémentation : vérifier si `AppThemeExtension` expose `textTertiary` ; sinon utiliser `colorScheme.outline` ou ajouter une propriété à `AppThemeExtension` |

---

## Hors scope

- **Refonte des écrans** (Étape 4-7).
- **Migration des 12 sites `showDialog` Material vers `ConfirmDialogCustom`** : sera fait progressivement en Étape 4-5, pas dans cette feature.
- **BottomSheet à 4 lignes** (Étape 3 — KKS-239 séparée).
- **Onboarding standalone** (Étape 8).
- **Tests perf automatisés** (NFR-003) : vérification manuelle au review-impl uniquement, automatisation différée à une feature dédiée si la perf devient critique post-launch.
- **Migration `transaction_repository_local._normalize` vers `normalizeForSearch` public** : refactor cohérence optionnel, peut être fait dans cette feature si rapide ou différé.
- **Tests goldens** (RES-012) : non utilisés pour cette feature.

---

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | [research.md](./research.md) | Oui | 14 décisions techniques (RES-001 à RES-014), aucune nouvelle dépendance, audit codebase complet |
| Data Model | [data-model.md](./data-model.md) | Oui (minimal) | Spec mentionne 4 entités mais aucune nouvelle entité de domaine — uniquement réutilisation de `Category` (existante) + nouveaux types UI (`ConfirmVariant` enum local, `CategoryFormWidget` widget) |
| Quickstart | [quickstart.md](./quickstart.md) | Oui | Guide d'usage des 8 composants pour les développeurs Flutter qui les consommeront en Étape 4-7 |
| Clarify Log | [clarify-log.md](./clarify-log.md) | Oui (déjà existant) | 7 points résolus (1 interactif Option A, 6 auto), audit comparatif Angular du 2026-05-07 |
