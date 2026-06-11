# Documentation — KKS-239 : BottomSheet4RowsWidget composable

> Date : 2026-05-10
> Issue : KKS-239
> Branche : `feature/bottom-sheet-4-rows-widget`
> Statut : Done

---

## Résumé

`BottomSheet4RowsWidget` est le squelette composable commun aux trois formulaires bottom sheet de l'application (Transaction, Subscription, Debt). Il fournit la structure visuelle 4-rows alignée sur le pattern Angular `_bottom-sheet.scss`, expose une API par slots typés, et centralise les comportements d'état (loading, erreur, footer désactivé). Les formulaires métier (Étape 5 / KKS-241+) consomment ce squelette sans avoir à réimplémenter le chrome visuel.

---

## Guide développeur

### Usage minimal

```dart
import 'package:k_budget/src/common_widgets/bottom_sheet_4_rows_widget.dart';

showModalBottomSheet(
  context: context,
  isScrollControlled: true,           // obligatoire pour footer pinned
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: BottomSheet4RowsWidget(
      title: 'Nouvelle transaction',
      amountField: MonAmountInput(),
      metaPills: [pillDate, pillCategorie],
      onCancel: () => Navigator.pop(ctx),
      onSubmit: () { /* soumettre */ },
    ),
  ),
);
```

### Usage complet — Transaction-like

```dart
final expandNotifier = ValueNotifier<String?>(null);

ValueListenableBuilder<String?>(
  valueListenable: expandNotifier,
  builder: (context, expandedSection, _) {
    return PopScope(
      canPop: expandedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) expandNotifier.value = null;
      },
      child: BottomSheet4RowsWidget(
        title: 'Nouvelle transaction',
        titleIcon: PhosphorIconsRegular.arrowsLeftRight,
        topTrailing: MyTypeToggle(onChanged: (type) { /* Dépense/Recette */ }),
        amountField: MyAmountInput(controller: amountCtrl),
        libelleField: MyLibelleInput(controller: libelleCtrl),
        notePreview: noteText.isNotEmpty
            ? MyNotePreview(text: noteText)
            : null,
        iconButtons: [noteIconBtn, recurringIconBtn],
        metaPills: [
          MyPill(
            label: dateLabel,
            onTap: () => expandNotifier.value = 'date',
          ),
          MyPill(
            label: categoryLabel,
            onTap: () => expandNotifier.value = 'category',
          ),
        ],
        expandedContent: switch (expandedSection) {
          'date'     => InlineDatePicker(selectedDate: date, onChanged: (d) { /* ... */ }),
          'category' => CategorySelectExpand(
              categories: categories,
              selectedId: selectedCategoryId,
              onSelected: (id) { /* ... */ },
              onCreatingChanged: (creating) => setState(() => footerEnabled = !creating),
            ),
          _          => null,
        },
        onExpandClose: () => expandNotifier.value = null,
        onCancel: () => Navigator.pop(context),
        onSubmit: _handleSubmit,
        loading: isSubmitting,
        errorMessage: submitError,
        footerEnabled: footerEnabled,
      ),
    );
  },
)
```

### Cas édition Debt (footer avec 2 pills)

```dart
BottomSheet4RowsWidget(
  // ...slots métier...
  footerLeading: [
    _BSheetActionPillWrapper(
      label: 'Supprimer',
      variant: _Variant.danger,
      icon: PhosphorIconsRegular.trash,
      onTap: _handleDelete,
    ),
    _BSheetActionPillWrapper(
      label: isRepaid ? 'Remboursé' : 'Non remboursé',
      variant: _Variant.status,
      onTap: _toggleRepaid,
    ),
  ],
  onSubmit: _handleSave,
)
// Note : quand footerLeading != null, le bouton Annuler par défaut n'est PAS rendu.
// Le parent est responsable de la zone gauche du footer dans son intégralité.
```

---

## API de référence

### BottomSheet4RowsWidget

| Paramètre | Type | Requis | Défaut | Description |
|-----------|------|--------|--------|-------------|
| `title` | `String` | ✓ | — | Titre Row 1 |
| `titleIcon` | `IconData?` | | null | Icône à gauche du titre |
| `topTrailing` | `Widget?` | | null | Slot trailing Row 1 (type-toggle Tx/Sub/Debt) |
| `amountField` | `Widget` | ✓ | — | Montant hero Row 2 |
| `libelleField` | `Widget?` | | null | Libellé optionnel Row 2 |
| `notePreview` | `Widget?` | | null | Preview note entre Row 2 et Row 3 |
| `iconButtons` | `List<Widget>?` | | null | Icônes gauche Row 3 |
| `metaPills` | `List<Widget>` | ✓ | — | Pills scrollables Row 3 (peut être vide) |
| `expandedContent` | `Widget?` | | null | Contenu zone expand (InlineDatePicker, CategorySelectExpand…) |
| `footerLeading` | `List<Widget>?` | | null | Pills gauche Row 4 (null → bouton Annuler par défaut) |
| `onCancel` | `VoidCallback?` | | null | Callback Annuler (ignoré si `footerLeading != null`) |
| `onSubmit` | `VoidCallback` | ✓ | — | Callback Valider |
| `cancelLabel` | `String` | | `'Annuler'` | Label bouton Annuler |
| `submitLabel` | `String` | | `'Valider'` | Label bouton Valider |
| `loading` | `bool` | | `false` | Spinner sur Valider + tap ignoré |
| `errorMessage` | `String?` | | null | Bandeau erreur au-dessus de Row 1 |
| `submitVariant` | `BSheetSubmitVariant` | | `primary` | Couleur bouton Valider (`primary` ou `danger`) |
| `footerEnabled` | `bool` | | `true` | `false` → Row 4 entière désactivée (Opacity 0.4 + IgnorePointer) |
| `onExpandClose` | `VoidCallback?` | | null | Callback retour Android quand expand ouverte |

### BSheetSubmitVariant

| Valeur | Description |
|--------|-------------|
| `primary` | Bouton Valider en amber (défaut) |
| `danger` | Bouton Valider en rouge expense — confirmation dangereuse |

### Keys structurelles (utilisables en tests)

| Key | Zone |
|-----|------|
| `Key('bsheet_top')` | Row 1 — handle + titre |
| `Key('bsheet_main_row')` | Row 2 — montant + libellé |
| `Key('bsheet_note_preview')` | Note preview (présent si `notePreview != null`) |
| `Key('bsheet_meta_row')` | Row 3 — icônes + pills (présent si non vide) |
| `Key('bsheet_expand')` | Zone expand (présent si `expandedContent != null`) |
| `Key('bsheet_bottom_row')` | Row 4 — footer |
| `Key('bsheet_submit')` | Bouton Valider |
| `Key('bsheet_cancel')` | Bouton Annuler (présent si `footerLeading == null`) |
| `Key('bsheet_error_banner')` | Bandeau erreur (présent si `errorMessage != null`) |

---

## Comportements clés

| Condition | Comportement |
|-----------|-------------|
| `metaPills.isEmpty && iconButtons == null` | Row 3 absente (`SizedBox.shrink()`) |
| `footerLeading != null` | Annuler non rendu, `onCancel` ignoré |
| `loading: true` | Spinner 16×16 sur Valider, opacité 0.4, tap ignoré |
| `footerEnabled: false` | Row 4 entière : `Opacity(0.4) + IgnorePointer` |
| `errorMessage != null` | Bandeau fond `colorScheme.errorContainer`, texte `colorScheme.error` |
| `loading && errorMessage != null` | Les deux états coexistent (pas de masquage mutuel) |
| `expandedContent != null` | Zone expand animée (`AnimatedSize`, 200 ms easeOut) |
| `submitVariant: danger` | Bouton Valider : texte + bordure `expenseColor` |

### Responsabilité clavier (importante)

Le widget ne gère **pas** le padding clavier. L'appelant doit l'assurer :

```dart
showModalBottomSheet(
  isScrollControlled: true,   // OBLIGATOIRE
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: BottomSheet4RowsWidget(...),
  ),
);
```

### Bouton retour Android et zone expand

```dart
PopScope(
  canPop: expandedSection == null,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) expandNotifier.value = null;
  },
  child: BottomSheet4RowsWidget(
    onExpandClose: () => expandNotifier.value = null,
    ...
  ),
)
```

---

## Changements techniques

### Fichiers créés

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart` | Widget principal + sous-widgets privés (`_BSheetHandle`, `_BSheetActionPill`, `_BSheetErrorBanner`) + enums (`BSheetSubmitVariant`, `_BSheetActionPillVariant`) |
| `flutter/test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart` | 33 widget tests (SC-001→SC-014, × 2 thèmes) |

### Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `flutter/lib/src/theme/app_theme.dart` | Ajout `errorContainer: AppColors.errorLight` (light) et `errorContainer: Color(0x1AEF4444)` (dark) dans les deux `ColorScheme` — prérequis `_BSheetErrorBanner` |

### Aucune nouvelle dépendance

Le widget réutilise exclusivement les packages déjà présents (`flutter/material`, `phosphor_flutter` pour les icônes passées en slots).

---

## Tests et validation

### Suite de tests

```bash
cd flutter && flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart --reporter=expanded
# 33/33 tests passés — ~1 seconde
```

### Couverture SC

| SC | Description | Statut |
|----|-------------|--------|
| SC-001 | 4 rows keys présentes | ✓ × 2 thèmes |
| SC-002 | Slots injectés présents inchangés | ✓ × 2 thèmes |
| SC-003 | AnimatedSize déclenché expand null→non-null | ✓ × 2 thèmes |
| SC-004 | `loading: true` — spinner + onSubmit bloqué | ✓ × 2 thèmes |
| SC-005 | `errorMessage` — bandeau `bsheet_error_banner` | ✓ × 2 thèmes |
| SC-006 | `loading + errorMessage` coexistent | ✓ × 2 thèmes |
| SC-007 | `footerLeading` à gauche, spaceBetween | ✓ × 2 thèmes |
| SC-008 | `footerEnabled: false` — callbacks bloqués | ✓ × 2 thèmes |
| SC-009 | Grep no-hex : 0 résultat | ✓ (script) |
| SC-010 | Dark + light via `forEachTheme` | ✓ × 2 thèmes |
| SC-011 | Documentation `///` avec exemple Transaction-like | ✓ (lecture humaine) |
| SC-012 | 3 hauteurs sans overflow (320/600/900 px) | ✓ |
| SC-013 | `notePreview` null vs non-null | ✓ × 2 thèmes |
| SC-014 | `footerLeading` 3 cas (null / [1] / [2]) | ✓ × 2 thèmes |

### Qualité

```bash
# Analyse statique
cd flutter && flutter analyze lib/src/common_widgets/bottom_sheet_4_rows_widget.dart
# → No issues found!

# Aucun hex hardcodé (SC-009)
grep -nE "Color\(0x|#[0-9a-fA-F]{6,8}" flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart
# → 0 résultats
```

---

## Dépendances et impacts

### Bloquant pour Étape 5

`BottomSheet4RowsWidget` est le prérequis direct de KKS-241+ (refonte des 3 formulaires). Les formulaires `TransactionForm`, `SubscriptionForm`, `DebtForm` migreront vers ce squelette en Étape 5.

### Prérequis satisfaits

| Issue | Statut | Apport utilisé |
|-------|--------|----------------|
| KKS-237 | ✓ Done | Tokens design (`AppColors`, `AppThemeExtension`, `AppSpacing`, `AppRadius`, `AppDurations`) |
| KKS-238 | ✓ Done | `InlineDatePicker`, `CategorySelectExpand` (passés via slot `expandedContent`) |

### Points différés (Étape 5)

| Ref | Description |
|-----|-------------|
| CL-008 | Validation performance `AnimatedSize` sur Android low-end (Pixel 3a) — à valider en Étape 5 lors de l'intégration réelle |
| NFR-003 | 60 fps sur device réel — validé par POC en Étape 5 |

---

## Reviews et pipeline

| Phase | Résultat | Itérations |
|-------|----------|-----------|
| review-spec | PASS | 2 (BLOQUANT → PASS) |
| review-tasks | PASS | 1 |
| review-impl | PASS | 1 |

**Pipeline complet** : spec → clarify → review-spec × 2 → research → plan → contracts → tasks → review-tasks → implement → review-impl → docs

---

## Checklist finale

- [x] `app_theme.dart` : `errorContainer` ajouté light + dark
- [x] `bottom_sheet_4_rows_widget.dart` : `dart analyze` exit 0
- [x] Grep no-hex : 0 résultats
- [x] 33 tests flutter : exit 0 (≥ 10 requis par NFR-001)
- [x] 9 keys structurelles présentes
- [x] Documentation `///` avec exemple Transaction-like
- [x] Pas de `print()` ni `debugPrint()`
- [x] Pre-commit review : CLEAR
- [x] Commit : `8b26ed4`
