# Contrats techniques — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter

> Date : 2026-05-07
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Plan : [plan.md](./plan.md) — Spec : [spec.md](./spec.md) — Research : [research.md](./research.md) — Data Model : [data-model.md](./data-model.md)

---

## Note

Cette feature est **100% UI Flutter**. Aucun endpoint REST, aucun nouveau service Riverpod, aucun nouveau modèle de domaine.

Les contrats formalisés ici sont :
- **9 contrats de composants Flutter** (8 composants shared + 1 widget extrait `CategoryFormWidget`)
- **2 helpers publics** (`normalizeForSearch`, `forEachTheme`)
- **1 enum public** (`ConfirmVariant`)

Notation : signatures Dart, conformément à la stack du projet (CLAUDE.md).

---

## Interfaces & Types

### `ConfirmVariant`

> Réf: FR-012, FR-013

```dart
enum ConfirmVariant {
  /// Variante par défaut — bouton confirmer en `colorScheme.primary` (amber),
  /// icône `PhosphorIcons.check()`.
  primary,

  /// Variante danger — bouton confirmer en `colorScheme.error` (rouge),
  /// icône `PhosphorIcons.trash()`.
  danger,
}
```

**Invariants** :
- `primary` est la valeur par défaut du paramètre `variant` de `ConfirmDialogCustom.show()`.
- L'enum n'est exporté publiquement que par le fichier `confirm_dialog_custom.dart`.
- Le nom `default` est réservé en Dart, donc la valeur principale s'appelle `primary` (et non `default`).

---

## API Endpoints

**Aucun endpoint REST.** Cette feature ne touche pas le backend Spring.

Les composants `CategoryFormWidget` (FR-019) interagissent indirectement avec l'API via le `categoryNotifierProvider` Riverpod existant, qui à son tour utilise le `CategoryRepository` (local Drift ou remote Dio selon `dataModeProvider`). Cette interaction est **inchangée** par cette feature.

---

## Contrats composants

### `SectionHeaderSticky`

> Réf: FR-007, FR-017, FR-018 / US-003

| Aspect | Détail |
|--------|--------|
| Responsabilité | Header sticky d'une section dans une liste scrollable, fond dynamique au scroll |
| Fichier | `flutter/lib/src/common_widgets/section_header_sticky.dart` |
| Type Flutter | `StatelessWidget` retournant un `SliverPersistentHeader` |
| Riverpod | Aucun |

**Constructeur** :

```dart
const SectionHeaderSticky({
  super.key,
  required this.title,
  this.count,
  this.actions,
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `title` | `String` | Oui | Titre de la section (ex : « Transactions ») |
| `count` | `int?` | Non | Compteur affiché à droite du titre (ex : 24) |
| `actions` | `List<Widget>?` | Non | Boutons d'action à droite (ex : filtre, recherche) |

**Outputs / Events** : aucun (composant de présentation pure).

**Contrat d'usage** :
- Doit être inséré comme un `Sliver` dans un `CustomScrollView`.
- N'est pas compatible avec `NestedScrollView` (cf. R-3 du plan).
- Hauteur fixe 48px (`minExtent == maxExtent`).

---

### `ListGroup`

> Réf: FR-008, FR-009, FR-017, FR-018 / US-004

| Aspect | Détail |
|--------|--------|
| Responsabilité | Conteneur arrondi `surfaceContainer` avec dividers internes entre enfants |
| Fichier | `flutter/lib/src/common_widgets/list_group.dart` |
| Type Flutter | `StatelessWidget` |
| Riverpod | Aucun |

**Constructeur** :

```dart
const ListGroup({
  super.key,
  required this.children,
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `children` | `List<Widget>` | Oui | Items à grouper. `n - 1` dividers seront insérés entre eux |

**Outputs / Events** : aucun.

**Contrat d'usage** :
- `BorderRadius.all(Radius.circular(AppRadius.xl))`.
- `color: Theme.of(context).colorScheme.surfaceContainer`.
- Divider interne : `Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant)`.
- Pas de divider après le dernier enfant.
- Optimisé pour 5-30 items max (cf. R-6 du plan).

---

### `EmptyStateWidget`

> Réf: FR-011, FR-017, FR-018 / US-006

| Aspect | Détail |
|--------|--------|
| Responsabilité | État vide unifié avec icône, message, hint optionnel, CTA text-link optionnel |
| Fichier | `flutter/lib/src/common_widgets/empty_state_widget.dart` |
| Type Flutter | `StatelessWidget` |
| Riverpod | Aucun |

**Constructeur** :

```dart
const EmptyStateWidget({
  super.key,
  this.icon,
  required this.message,
  this.hint,
  this.ctaLabel,
  this.onCtaTap,
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `icon` | `IconData?` | Non | Icône Phosphor 48px à 50% opacité |
| `message` | `String` | Oui | Message principal (ex : « Aucune transaction ») |
| `hint` | `String?` | Non | Hint secondaire xs `text-tertiary` (ex : « Tapez + pour ajouter ») |
| `ctaLabel` | `String?` | Non | Label du CTA text-link (ex : « + Créer ») |
| `onCtaTap` | `VoidCallback?` | Non | Callback déclenché au tap du CTA |

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| `onCtaTap` | `void` | Tap sur le CTA text-link (souligné permanent au lieu du hover-only Angular) |

**Contrat d'usage** :
- `ctaLabel` et `onCtaTap` doivent être passés ensemble (les deux ou aucun).
- Le CTA est rendu via `TextButton` stylé, pas un bouton plein.

---

### `VariationBadge`

> Réf: FR-014, FR-017, FR-018 / US-008

| Aspect | Détail |
|--------|--------|
| Responsabilité | Texte coloré delta vs mois précédent — masqué si zéro et pas de pourcentage |
| Fichier | `flutter/lib/src/common_widgets/variation_badge.dart` |
| Type Flutter | `StatelessWidget` |
| Riverpod | Aucun |

**Constructeur** :

```dart
const VariationBadge({
  super.key,
  required this.delta,
  this.currency,
  this.percentage,
  this.suffix = 'ce mois',
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `delta` | `num` | Oui | Variation absolue (ex : `+150.5` ou `-8.0`) |
| `currency` | `String?` | Non | Symbole monétaire (défaut : `'€'`) |
| `percentage` | `num?` | Non | Pourcentage de variation (ex : `12.5`). Si fourni, affiché entre parenthèses |
| `suffix` | `String` | Non (défaut `'ce mois'`) | Suffixe textuel après le montant |

**Outputs / Events** : aucun.

**Contrat de rendu** :
- **Masqué** (`SizedBox.shrink()`) si `delta == 0 && percentage == null`.
- Format : `'{signe}{montant formaté} {suffix} ({signePct}{pct,1 décimale}%)'`.
  - Exemple : `'+150,50 € ce mois (+12,5%)'`
  - Exemple : `'-8,00 € ce mois (-3,2%)'`
- Couleur :
  - `delta > 0` → `AppThemeExtension.incomeColor` (vert)
  - `delta < 0` → `AppThemeExtension.expenseColor` (rouge)
  - `delta == 0` (avec percentage) → `colorScheme.onSurfaceVariant` (text-secondary)
- Locale `fr_FR` (séparateur décimal virgule).

---

### `PageHeader`

> Réf: FR-010, FR-017, FR-018 / US-005

| Aspect | Détail |
|--------|--------|
| Responsabilité | Header sous-pages : back button rond 36px à gauche, titre flex-end (à droite), icône métier optionnelle |
| Fichier | `flutter/lib/src/common_widgets/page_header.dart` |
| Type Flutter | `StatelessWidget` |
| Riverpod | Aucun |

**Constructeur** :

```dart
const PageHeader({
  super.key,
  required this.title,
  this.onBack,
  this.icon,
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `title` | `String` | Oui | Titre de la page (aligné à droite, `titleLarge` bold) |
| `onBack` | `VoidCallback?` | Non | Callback du back button. Si `null`, le bouton est rendu désactivé |
| `icon` | `Widget?` | Non | Icône métier optionnelle, rendue dans un cercle 32×32 `iconCircleBg` juste avant le titre |

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| `onBack` | `void` | Tap sur le back button rond |

**Contrat d'usage** :
- **Pas de `trailing` actions** (suit strictement Angular).
- Le `Widget` `icon` est wrappé automatiquement dans un cercle 32×32 — le caller passe juste le child (`Icon(...)`, `Text('💰')`, image, etc.).
- Layout : `[← back rond 36×36] [Spacer] [icon optionnel rond 32×32] [titre flex-end bold]`.

---

### `ConfirmDialogCustom`

> Réf: FR-012, FR-013, FR-017, FR-018, NFR-007 / US-007

| Aspect | Détail |
|--------|--------|
| Responsabilité | Dialog de confirmation modal centré avec icône, variantes default / danger |
| Fichier | `flutter/lib/src/common_widgets/confirm_dialog_custom.dart` |
| Type Flutter | Classe avec méthode statique (pas un widget instanciable) + widget privé `_ConfirmDialogContent` |
| Riverpod | Aucun |

**API publique — méthode statique** :

```dart
class ConfirmDialogCustom {
  ConfirmDialogCustom._();  // pas instanciable

  /// Affiche un dialog modal de confirmation.
  ///
  /// Retourne :
  /// - `true` si l'utilisateur tap sur le bouton confirmer
  /// - `false` si l'utilisateur tap sur le bouton annuler
  /// - `null` si l'utilisateur tap hors du dialog (`barrierDismissible`)
  ///   ou utilise le back button Android
  static Future<bool?> show({
    required BuildContext context,
    IconData? icon,
    required String title,
    String? message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    ConfirmVariant variant = ConfirmVariant.primary,
  });
}
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `context` | `BuildContext` | Oui | Contexte parent pour `showDialog` |
| `icon` | `IconData?` | Non | Icône métier 20px en header (ex : `PhosphorIcons.trash()`) |
| `title` | `String` | Oui | Titre concret (ex : `'Supprimer Courses 42 €'`) |
| `message` | `String?` | Non | Description (ex : `'Cette action est irréversible.'`) |
| `confirmLabel` | `String` | Non (défaut `'Confirmer'`) | Label du bouton de confirmation |
| `cancelLabel` | `String` | Non (défaut `'Annuler'`) | Label du bouton d'annulation |
| `variant` | `ConfirmVariant` | Non (défaut `primary`) | Style du bouton confirmer (couleur + icône) |

**Outputs** :

| Retour `Future<bool?>` | Source |
|-----------------------|--------|
| `true` | Tap sur le bouton confirmer |
| `false` | Tap sur le bouton annuler |
| `null` | Tap sur le scrim (barrier dismiss) ou back button Android |

**Contrat d'usage** :
- Utilise `showDialog<bool>` Material avec `barrierDismissible: true`.
- Bouton Annuler : `OutlinedButton.icon(icon: PhosphorIcons.x() 14px, label: ...)`.
- Bouton Confirmer : `FilledButton.icon` avec :
  - `variant == primary` → `backgroundColor: colorScheme.primary`, icône `PhosphorIcons.check()` 14px
  - `variant == danger` → `backgroundColor: colorScheme.error`, icône `PhosphorIcons.trash()` 14px
- Sites d'appel : `final result = await ConfirmDialogCustom.show(...) ?? false;` (convention recommandée).

---

### `InlineDatePicker`

> Réf: FR-001, FR-002, FR-003, FR-017, FR-018 / US-001

| Aspect | Détail |
|--------|--------|
| Responsabilité | Calendrier inline custom Flutter, format ISO `String`, support `originalValue` mode édition |
| Fichier | `flutter/lib/src/common_widgets/inline_date_picker.dart` |
| Type Flutter | `StatefulWidget` (état local : mois/année courants) |
| Riverpod | Aucun |

**Constructeur** :

```dart
const InlineDatePicker({
  super.key,
  required this.value,
  required this.onChanged,
  this.originalValue,
  this.minDate,
  this.maxDate,
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `value` | `String` | Oui | Date sélectionnée au format ISO `'YYYY-MM-DD'` (ex : `'2026-05-07'`) |
| `onChanged` | `ValueChanged<String>` | Oui | Callback déclenché quand l'utilisateur sélectionne un jour. Reçoit la nouvelle ISO |
| `originalValue` | `String?` | Non | Date initiale en mode édition (ISO). Cellule mise en valeur discrète (`hoverSubtle`) tant que `value != originalValue` |
| `minDate` | `String?` | Non | Borne inférieure ISO. Les jours antérieurs sont disabled |
| `maxDate` | `String?` | Non | Borne supérieure ISO. Les jours postérieurs sont disabled |

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| `onChanged` | `String` | ISO du jour sélectionné (ex : `'2026-05-15'`) |

**Contrat d'usage** :
- Format ISO `'YYYY-MM-DD'` strict. La conversion vers `DateTime` Dart est à la charge du consommateur.
- **Lundi-first** hardcodé (headers `L M M J V S D`).
- Tap sur le label du mois → `goToToday()` (revient au mois courant).
- Pas de mode année / décennie (différent de `CalendarDatePicker` Material).
- Doit être placé dans un widget capable de recevoir un calendrier inline (typiquement zone `bsheet__expand` du bottom sheet).

---

### `CategorySelectExpand`

> Réf: FR-004, FR-005, FR-006, FR-017, FR-018 / US-002, dépend de FR-019

| Aspect | Détail |
|--------|--------|
| Responsabilité | Sélecteur de catégorie inline avec recherche et création — embed `CategoryFormWidget` en mode `'create'` |
| Fichier | `flutter/lib/src/common_widgets/category_select_expand.dart` |
| Type Flutter | `StatefulWidget` (état local : mode, recherche, GlobalKey form) |
| Riverpod | Aucun (parent gère via `categoriesProvider`) |

**Constructeur** :

```dart
const CategorySelectExpand({
  super.key,
  required this.categories,
  this.selectedId,
  required this.onSelected,
  this.onCreated,
  this.onCreatingChanged,
  this.searchPlaceholder,
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `categories` | `List<Category>` | Oui | Liste des catégories disponibles (préchargée par le parent) |
| `selectedId` | `String?` | Non | ID de la catégorie actuellement sélectionnée |
| `onSelected` | `ValueChanged<String>` | Oui | Callback au tap sur une catégorie. Reçoit l'`id` (`String`) |
| `onCreated` | `ValueChanged<Category>?` | Non | Callback après création réussie via embed `CategoryFormWidget`. Reçoit la `Category` complète retournée par le notifier |
| `onCreatingChanged` | `ValueChanged<bool>?` | Non | Callback notifiant le parent du changement de mode (`true` = mode `'create'`, `false` = mode `'list'`). Permet au parent de désactiver son footer pendant la création |
| `searchPlaceholder` | `String?` | Non | Placeholder du champ recherche (défaut : `'Rechercher une catégorie...'`) |

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| `onSelected` | `String` | ID de la catégorie tappée par l'utilisateur |
| `onCreated` | `Category` | Objet `Category` complet créé via le sous-formulaire `CategoryFormWidget` |
| `onCreatingChanged` | `bool` | `true` quand le mode passe à `'create'`, `false` quand il revient à `'list'` |

**Comportement** :
- 2 modes internes : `_SelectMode.list` / `_SelectMode.create`.
- Mode `list` : champ recherche + listbox + bouton `+ Créer « terme »` apparaît si recherche non vide ET pas de match exact.
- Mode `create` : header `[← Retour] [✓ Créer]` + embed `CategoryFormWidget(initialName: searchTerm, showHeader: false)` via `GlobalKey<CategoryFormWidgetState>`.
- Tap `[✓ Créer]` du header → `_formKey.currentState?.submit()`.
- Recherche conservée au retour `create → list` (cohérence Angular).
- Reset au `dispose()` (forçage `_mode = list`).
- Filtrage via `normalizeForSearch` (case + diacritics insensible).

---

### `CategoryFormWidget` (extrait depuis `CategoryFormScreen`)

> Réf: FR-019 (dépendance directe de US-002)

| Aspect | Détail |
|--------|--------|
| Responsabilité | Formulaire de catégorie réutilisable et embeddable (sans Scaffold) |
| Fichier | `flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart` |
| Type Flutter | `ConsumerStatefulWidget` avec **state class publique** |
| Riverpod | Lit `categoryNotifierProvider` pour `create()` / `update()` |

**Constructeur** :

```dart
const CategoryFormWidget({
  super.key,
  this.category,
  this.initialName,
  this.onSaved,
});
```

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `category` | `Category?` | Non | `null` = mode création ; non-null = mode édition |
| `initialName` | `String?` | Non | Pré-remplissage du champ nom (utilisé par `CategorySelectExpand` qui passe le `searchTerm`) |
| `onSaved` | `ValueChanged<Category>?` | Non | Callback après save réussi (POST/PUT). Reçoit la `Category` finale |

> **Note livraison** : les paramètres `onCancelled: VoidCallback?` et `showHeader: bool = true` initialement spécifiés ont été **retirés en Phase 2** sur indication du `pre-commit-review` (code mort YAGNI) :
> - `onCancelled` n'est jamais appelé : le retour mode `'list'` dans `CategorySelectExpand` est géré par le bouton externe `[← Retour]` du parent qui appelle son propre `_backToList`, pas par un callback du sous-widget.
> - `showHeader` ne contrôlait rien (les deux branches `if/!if` rendaient la même chose). Suppression du flag, la preview card est rendue inconditionnellement.
> Si un futur consommateur (KKS-239+) a un besoin réel d'annuler depuis le sous-widget ou de masquer la preview, ces paramètres pourront être réintroduits avec un usage concret.

**State class publique** :

```dart
class CategoryFormWidgetState extends ConsumerState<CategoryFormWidget> {
  /// Valide les champs du formulaire et soumet la création/édition.
  ///
  /// - Si validation échoue : affiche les erreurs inline (`_showErrors = true`),
  ///   ne lève pas d'exception, n'émet pas `onSaved`.
  /// - Si validation OK : appelle `categoryNotifierProvider.notifier.create()`
  ///   ou `update()` selon le mode, puis émet `onSaved(category)` au succès.
  /// - Si erreur réseau / serveur : reste sur le widget, affiche un `SnackBar`
  ///   d'erreur, n'émet pas `onSaved`.
  Future<void> submit();
}
```

**Outputs / Events** :

| Nom | Payload | Description |
|-----|---------|-------------|
| `onSaved` | `Category` | Émis **uniquement** en cas de succès complet (validation OK + persist OK) |
| `onCancelled` | `void` | Émis si l'utilisateur abandonne (back / cancel) |

**Invariants** :
- `submit()` est silencieuse en cas d'erreur de validation (gère ses propres erreurs inline).
- `onSaved` n'est jamais appelé si `submit()` n'a pas été invoquée.
- Le state `CategoryFormWidgetState` est **publique** pour permettre l'accès via `GlobalKey<CategoryFormWidgetState>` depuis le parent (CX-001).

---

## Helpers publics

### `normalizeForSearch(String input)`

> Réf: FR-005 (CategorySelectExpand) / RES-010

| Aspect | Détail |
|--------|--------|
| Responsabilité | Normaliser une chaîne pour comparaison de recherche : lowercase + suppression diacritiques + trim |
| Fichier | `flutter/lib/src/utils/string_utils.dart` |
| Type Dart | Fonction top-level |

**Signature** :

```dart
import 'package:diacritic/diacritic.dart';

/// Normalise une chaîne pour la recherche : lowercase + suppression des
/// diacritiques (accents) + trim.
///
/// Exemple : `normalizeForSearch('Café  ')` → `'cafe'`.
///
/// Utilisé par les composants de recherche (ex: [CategorySelectExpand])
/// pour permettre des matches insensibles à la casse et aux accents.
String normalizeForSearch(String input);
```

**Comportement** :
- `'Café'` → `'cafe'`
- `'  COURSES  '` → `'courses'`
- `'Épicerie & Boissons'` → `'epicerie & boissons'`

**Contrat** : pas d'exception levée. Retourne toujours une `String`.

---

### `forEachTheme` (helper de tests)

> Réf: NFR-001, FR-018 / RES-012

| Aspect | Détail |
|--------|--------|
| Responsabilité | Itérer un test sur les thèmes dark + light pour les widget tests |
| Fichier | `flutter/test/helpers/theme_test_helpers.dart` |
| Type Dart | Fonction top-level (test only) |

**Signature** :

```dart
import 'package:flutter/material.dart';
import 'package:k_budget/src/theme/app_theme.dart';

/// Itère [body] sur les thèmes [AppTheme.dark] et [AppTheme.light].
///
/// Usage typique :
/// ```dart
/// forEachTheme((theme, themeName) {
///   testWidgets('should_render_correctly_when_$themeName', (tester) async {
///     // pumpWidget avec un MaterialApp(theme: theme, ...)
///   });
/// });
/// ```
void forEachTheme(void Function(ThemeData theme, String themeName) body);
```

**Contrat** :
- `forEachTheme` invoque `body` exactement 2 fois : `(AppTheme.dark, 'dark')` puis `(AppTheme.light, 'light')`.

> **Note livraison** : `Widget wrapWithTheme(ThemeData theme, Widget child)` initialement spécifié a été **retiré en Phase 2** sur indication du `pre-commit-review` (code mort YAGNI). Chaque fichier de test livré utilise un helper local `pumpXxx(tester, theme, ...)` adapté à ses besoins spécifiques (`CustomScrollView` pour `SectionHeaderSticky`, `ProviderScope` pour `CategorySelectExpand`, `localizationsDelegates` pour `CategoryFormWidget`). Ces helpers locaux sont plus flexibles qu'un `wrapWithTheme` générique pour des widgets avec contexte Riverpod, Sliver ou localisation. Si KKS-239+ identifie un consommateur réel d'un wrapper minimal, `wrapWithTheme` pourra être ajouté à ce moment.

---

## Contrats services

**Aucun nouveau service Riverpod ni Provider.** Cette feature consomme des providers existants :

| Provider existant | Consommateur | Méthode utilisée |
|-------------------|--------------|------------------|
| `categoryNotifierProvider` | `CategoryFormWidget` | `notifier.create(Category)`, `notifier.update(Category)` |

---

## Conventions cross-composants

| # | Règle | Composants concernés |
|---|-------|---------------------|
| C-001 | Tous les composants exposent une documentation `///` triple-slash sur la classe publique + chaque paramètre (NFR-006) | Tous (8 + CategoryFormWidget) |
| C-002 | Aucun `Color(0xFF...)` direct dans les fichiers de composants — uniquement `colorScheme.*` ou `AppThemeExtension` (FR-017, DC-001) | Tous |
| C-003 | Aucun `print()` — `developer.log` ou logging contrôlé uniquement (NFR-008, DC-006) | Tous |
| C-004 | Tests dark + light via `forEachTheme` (NFR-001, FR-018) | Tous |
| C-005 | `Category.id` typé `String` partout (DC-003) | `CategorySelectExpand`, `CategoryFormWidget` |
| C-006 | Format date `String` ISO `'YYYY-MM-DD'` en E/S de `InlineDatePicker` (DC-004) | `InlineDatePicker` |
| C-007 | `ConfirmDialogCustom.show()` retourne `Future<bool?>` (pas `Future<bool>`) (DC-005) | `ConfirmDialogCustom` |

---

## Résumé

| Type | Nombre |
|------|--------|
| Interfaces & Types | 1 (`ConfirmVariant`) |
| API Endpoints | 0 (feature 100% UI) |
| Contrats composants | 9 (8 shared + `CategoryFormWidget` extrait) |
| Contrats services | 0 (réutilisation de `categoryNotifierProvider` existant) |
| Helpers publics | 2 (`normalizeForSearch`, `forEachTheme`) |
| FR couverts | **19/19** (100% — FR-001 à FR-019) |
