# Contrats techniques — KKS-239 : BottomSheet4RowsWidget composable

> Date : 2026-05-10
> Issue : KKS-239
> Plan : [plan.md](./plan.md)

---

## Interfaces & Types

### BSheetSubmitVariant (enum public)

> Réf : FR-006

```dart
/// Variantes visuelles du bouton Valider du footer.
enum BSheetSubmitVariant {
  /// Bouton Valider en couleur primary (amber) — comportement par défaut.
  primary,

  /// Bouton Valider en couleur error/expense — confirmation dangereuse.
  /// Texte et bordure : [AppThemeExtension.expenseColor].
  danger,
}
```

**Invariants** :
- La valeur par défaut du paramètre `submitVariant` dans `BottomSheet4RowsWidget` est `BSheetSubmitVariant.primary`.
- `danger` n'affecte que la couleur du bouton Valider — pas le comportement du callback `onSubmit`.

---

### _BSheetActionPillVariant (enum privé, file-scoped)

> Réf : FR-013

```dart
/// Variantes privées de la pill d'action (file-scoped — non exporté).
enum _BSheetActionPillVariant {
  /// Bordure + texte [colorScheme.primary].
  primary,

  /// Bordure + texte [colorScheme.outline] / [colorScheme.onSurfaceVariant].
  cancel,

  /// Bordure + texte [AppThemeExtension.expenseColor].
  danger,

  /// Bordure + texte [colorScheme.onSurfaceVariant] — bouton d'état booléen
  /// (ex : Remboursé/Non remboursé, Actif/Inactif).
  status,

  /// État de chargement : spinner 16×16 + opacité 0.4 + tap ignoré.
  loading,
}
```

**Invariants** :
- `loading` remplace le `Text` par `CircularProgressIndicator(strokeWidth: 2, value: null)` 16×16.
- Un `_BSheetActionPill` en variante `loading` n'invoque jamais son `onTap`.

---

## API Endpoints

*N/A — KKS-239 est un widget 100% UI / présentation. Aucun endpoint réseau.*

---

## Contrats composants

### BottomSheet4RowsWidget

> Réf : FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-014, FR-015, FR-016

| Aspect | Détail |
|--------|--------|
| Responsabilité | Squelette composable 4-rows des bottom sheets formulaires (Transaction, Subscription, Debt) |
| Type | `StatelessWidget` |
| Fichier | `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart` |

**Constructeur** :

```dart
const BottomSheet4RowsWidget({
  super.key,

  // Row 1 — bsheet_top
  required String title,
  IconData? titleIcon,
  Widget? topTrailing,        // slot universel : type-toggle Tx/Sub/Debt ou widget arbitraire

  // Row 2 — bsheet_main_row
  required Widget amountField,   // montant hero (obligatoire)
  Widget? libelleField,          // libellé optionnel (input direct ou wrapper)

  // Slot inter-Row 2/3
  Widget? notePreview,           // preview note italique 2 lignes (Tx uniquement)

  // Row 3 — bsheet_meta_row (rendu uniquement si non vide)
  List<Widget>? iconButtons,     // icônes gauche (note, récurrence, actif, reminder…)
  required List<Widget> metaPills, // pills scrollables droite (date, catégorie, compte…)

  // Zone expand (inline, entre Row 3 et Row 4)
  Widget? expandedContent,       // contenu déployé — expand orpheline acceptée

  // Row 4 — bsheet_bottom_row (pinned)
  List<Widget>? footerLeading,   // liste pills gauche (null → bouton Annuler par défaut)
  VoidCallback? onCancel,        // ignoré si footerLeading != null
  required VoidCallback onSubmit,
  String cancelLabel = 'Annuler',
  String submitLabel = 'Valider',

  // États
  bool loading = false,
  String? errorMessage,
  BSheetSubmitVariant submitVariant = BSheetSubmitVariant.primary,
  bool footerEnabled = true,

  // Navigation
  VoidCallback? onExpandClose,   // brancher sur PopScope côté parent (bouton retour Android)
})
```

**Keys publiques** (utilisables en tests) :

| Key | Zone |
|-----|------|
| `Key('bsheet_top')` | Row 1 — handle + titre |
| `Key('bsheet_main_row')` | Row 2 — montant + libellé |
| `Key('bsheet_note_preview')` | Slot note preview (présent si `notePreview != null`) |
| `Key('bsheet_meta_row')` | Row 3 — icônes + pills (présent si non vide) |
| `Key('bsheet_expand')` | Zone expand (présent si `expandedContent != null`) |
| `Key('bsheet_bottom_row')` | Row 4 — footer |
| `Key('bsheet_submit')` | Bouton Valider |
| `Key('bsheet_cancel')` | Bouton Annuler (quand rendu par défaut) |
| `Key('bsheet_error_banner')` | Bandeau erreur (présent si `errorMessage != null`) |

**Règles comportementales** :

| Condition | Comportement |
|-----------|-------------|
| `metaPills.isEmpty && iconButtons == null` | Row 3 absente (`SizedBox.shrink()`) — CL-001 |
| `footerLeading != null` | Bouton Annuler non rendu, `onCancel` ignoré — CL-002, SC-014 |
| `footerLeading == null` | Bouton Annuler rendu via `onCancel` dans la zone gauche du footer |
| `loading: true` | Bouton Valider désactivé (opacité 0.4), spinner 16×16, tap ignoré — FR-008 |
| `footerEnabled: false` | Zone footer entière `Opacity(0.4) + IgnorePointer` — FR-007 |
| `expandedContent != null` | Zone expand présente, `AnimatedSize(AppDurations.normal, easeOut)` — FR-003 |
| `expandedContent == null` | Zone expand absente (`SizedBox.shrink()`) — FR-003 |
| `errorMessage != null` | `_BSheetErrorBanner` rendu au-dessus de Row 1 — FR-009 |
| `loading && errorMessage != null` | Les deux états coexistent — FR-010 |

---

### _BSheetHandle (sous-widget privé)

> Réf : FR-002, FR-013

| Aspect | Détail |
|--------|--------|
| Responsabilité | Handle 36×4 px centré, conforme `.bsheet__handle` Angular |
| Type | `StatelessWidget` (file-scoped) |

```dart
// Signature privée — non exportée
const _BSheetHandle();
```

**Rendu** : `Container(width: 36, height: 4, color: onSurfaceVariant×0.4, borderRadius: round)` centré avec `margin: vertical s2`.

---

### _BSheetActionPill (sous-widget privé)

> Réf : FR-005, FR-006, FR-007, FR-008, FR-013

| Aspect | Détail |
|--------|--------|
| Responsabilité | Pill d'action configurable — tous les boutons du footer |
| Type | `StatelessWidget` (file-scoped) |

```dart
// Signature privée — non exportée
const _BSheetActionPill({
  required _BSheetActionPillVariant variant,
  required String label,
  IconData? icon,
  VoidCallback? onTap,        // null ou ignoré si loading
  Key? key,
});
```

**Rendu** : `InkWell(borderRadius: round) + Container(padding 5-8px, BoxDecoration(border, borderRadius: round))` — RES-004.

**États pressed par variante** :

| Variante | highlightColor | splashColor |
|----------|---------------|-------------|
| `primary` | `primarySubtle` | `primaryMuted` |
| `cancel` | `hoverSubtle` | `hoverSubtle` |
| `danger` | `errorContainer×0.6` | `errorContainer×0.3` |
| `status` | `hoverSubtle` | `hoverSubtle` |
| `loading` | `Colors.transparent` | `Colors.transparent` |

---

### _BSheetErrorBanner (sous-widget privé)

> Réf : FR-009, FR-013

| Aspect | Détail |
|--------|--------|
| Responsabilité | Bandeau d'erreur au-dessus de Row 1 |
| Type | `StatelessWidget` (file-scoped) |

```dart
// Signature privée — non exportée
const _BSheetErrorBanner({required String message});
```

**Rendu** :
- Fond : `colorScheme.errorContainer` (token ajouté dans `app_theme.dart` — prérequis T-0)
- Texte : `AppTypography.bodySmall`, couleur `colorScheme.error`
- Padding : `vertical: AppSpacing.s2 / horizontal: AppSpacing.s3`
- Border radius : `AppRadius.lg`
- Key : `Key('bsheet_error_banner')`

---

## Contrats services

*N/A — KKS-239 est un widget 100% UI / présentation. Aucun service métier.*

---

## Contrat de modification : app_theme.dart

> Réf : FR-009, SC-005, RES-003

| Aspect | Détail |
|--------|--------|
| Responsabilité | Prérequis T-0 — exposition du token `errorContainer` dans les deux `ColorScheme` |
| Fichier | `flutter/lib/src/theme/app_theme.dart` |

**Modifications** :

```dart
// ColorScheme.light — après onError: Colors.white
errorContainer: AppColors.errorLight, // #fee2e2 — aligné --bg-error Angular light

// ColorScheme.dark — après onError: Colors.white
errorContainer: const Color(0x1AEF4444), // rgb(239 68 68 / 10%) — aligné --bg-error Angular dark
```

**Invariants** :
- `AppColors.errorLight` = `Color(0xFFFEE2E2)` — constante existante, aucune création requise.
- `Color(0x1AEF4444)` : valeur inline documentée (alignement avec `error: Color(0xFFF87171)` déjà inline dans le dark ColorScheme).
- Cette modification est un prérequis strict de `_BSheetErrorBanner` — doit être implémentée avant T-4.

---

## Résumé

| Type | Nombre |
|------|--------|
| Interfaces & Types | 2 (BSheetSubmitVariant, _BSheetActionPillVariant) |
| API Endpoints | 0 (widget 100% UI) |
| Contrats composants | 4 (BottomSheet4RowsWidget + 3 sous-widgets privés) |
| Contrats services | 0 |
| Contrat de modification | 1 (app_theme.dart) |
| FR couverts | 16 (FR-001 à FR-016) |
