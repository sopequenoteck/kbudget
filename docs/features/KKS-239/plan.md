# Plan — KKS-239 : Phase 1 / Étape 3 — BottomSheet4RowsWidget composable

> Date : 2026-05-10
> Issue : KKS-239
> Spec : [spec.md](./spec.md)
> Research : [research.md](./research.md)

---

## Constitution Check

> Vérification des gates définies dans `docs/constitution.md` v3.0.0.

| Gate | Statut | Commentaire |
|------|--------|-------------|
| I — API-First / Local-First | ✅ PASS | Trajectoire B — widget 100% UI, aucun appel réseau, aucune dépendance Drift/Dio |
| II — Sécurité par défaut | ✅ N/A | Widget de présentation — aucune donnée sensible, aucune route, aucun secret |
| III — Simplicité & YAGNI | ✅ PASS | `StatelessWidget`, sous-widgets privés file-scoped, aucune abstraction prématurée, aucun pattern CQRS/DDD |
| IV — Mobile-First UX | ✅ PASS | Footer pinned (RES-001), `isScrollControlled: true` documenté, gestion clavier via `viewInsets` côté appelant |
| V — Testabilité | ✅ PASS | 14 SC couverts par widget tests × 2 thèmes = ≥ 10 tests (NFR-001), `forEachTheme` helper existant |
| VI — Observabilité | ✅ N/A | Widget de présentation — pas de logs nécessaires |
| VII — Trajectoire B (Flutter) | ✅ PASS | Widget standalone, aucune dépendance serveur, conforme `common_widgets/` |

### Dérogations

Aucune dérogation — tous les gates sont conformes.

### Complexity Tracking

| # | Complexité | Justification | Alternative envisagée |
|---|-----------|---------------|----------------------|
| CX-001 | `AnimatedSize` pour la zone expand (au lieu d'affichage conditionnel simple) | DESIGN.md v5 impose une animation d'ouverture/fermeture fluide. Pattern identique dans `app_form_field.dart`, `select_picker.dart`, `emoji_input.dart` — pas de complexité nouvelle. | `Visibility` / `if` conditionnel sans animation (rejeté : contredit DESIGN.md) |
| CX-002 | Footer pinned via `Column { Expanded(ScrollView), Row4 }` au lieu de `Column(mainAxisSize.min)` | Row 4 doit rester visible même sur un sheet long (Subscription + expand). Pattern standard Flutter pour layout pinned-footer. | `mainAxisSize.min` (rejeté : Row 4 disparaît sur sheet long) |

---

## Résumé de l'approche

Créer `BottomSheet4RowsWidget` comme `StatelessWidget` dans `common_widgets/`, exposant une API par slots typés (`Widget?`, `List<Widget>?`) pour les 4 rows + zone expand. Le layout utilise `Column { Expanded(SingleChildScrollView { rows 1-3 + expand }), Row 4 pinned }` (RES-001). Trois sous-widgets privés file-scoped gèrent le handle, les pills d'action, et le bandeau d'erreur. Un prérequis préalable ajoute `errorContainer` dans `app_theme.dart` (RES-003).

---

## Contexte technique

- **Stack** : Flutter ≥ 3.27, Dart ≥ 3.6, Material 3, `phosphor_flutter`
- **Dépendances nouvelles** : aucune
- **Dépendances existantes impactées** :
  - `flutter/lib/src/theme/app_theme.dart` — ajout `errorContainer` (2 lignes, prérequis FR-009)
  - `flutter/lib/src/constants/app_durations.dart` — lecture seule (`AppDurations.normal`, `AppDurations.easeOut`)
  - `flutter/lib/src/constants/app_colors.dart` — lecture seule (`AppColors.errorLight`)
  - `flutter/lib/src/theme/app_theme_extension.dart` — lecture seule (`expenseColor`, `iconCircleBg`)

---

## Architecture

### Structure des fichiers impactés

```
flutter/
├── lib/src/
│   ├── theme/
│   │   └── app_theme.dart                                (M) Ajouter errorContainer light + dark
│   └── common_widgets/
│       └── bottom_sheet_4_rows_widget.dart               (C) Widget principal + sous-widgets privés
└── test/src/
    └── common_widgets/
        └── bottom_sheet_4_rows_widget_test.dart          (C) 14 SC × 2 thèmes ≥ 10 tests
```

### Diagramme de flux

```
showModalBottomSheet(isScrollControlled: true)
  └─ Padding(viewInsets.bottom)              ← responsabilité appelant (NFR-007)
       └─ BottomSheet4RowsWidget
            ├─ [bsheet_error_banner] _BSheetErrorBanner?   ← si errorMessage != null
            └─ Column
                 ├─ Expanded
                 │    └─ SingleChildScrollView
                 │         └─ Column
                 │              ├─ [bsheet_top]      Row 1: _BSheetHandle + titre + topTrailing?
                 │              ├─ [bsheet_main_row] Row 2: amountField + libelleField?
                 │              ├─ [bsheet_note_preview] notePreview?
                 │              ├─ [bsheet_meta_row] Row 3: iconButtons? + metaPills (si non vides)
                 │              └─ AnimatedSize      Zone expand (RES-002)
                 │                   └─ [bsheet_expand] expandedContent?
                 └─ [bsheet_bottom_row] Row 4 pinned: footerLeading? / onCancel + onSubmit
```

---

## Approche par composant

### T-0 — Prérequis : app_theme.dart (colorScheme.errorContainer)

- **Responsabilité** : Ajouter `errorContainer` dans les deux `ColorScheme` pour que `_BSheetErrorBanner` consomme un token projet (pas la valeur Material 3 auto-générée).
- **Fichier** : `flutter/lib/src/theme/app_theme.dart`
- **Requirements couverts** : FR-009, SC-005
- **Approche** :
  - Light : ajouter `errorContainer: AppColors.errorLight,` (= `#fee2e2`, aligné `--bg-error` light Angular — RES-003)
  - Dark : ajouter `errorContainer: const Color(0x1AEF4444),` (= `rgb(239 68 68 / 10%)`, aligné `--bg-error` dark Angular — RES-003)
  - Les deux lignes s'insèrent après `onError: Colors.white` / `onError: Colors.white` respectifs.

---

### T-1 — Enum et types publics

- **Responsabilité** : Déclarer `BSheetSubmitVariant` en tête du fichier widget.
- **Fichier** : `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart`
- **Requirements couverts** : FR-006, NFR-005
- **Approche** :
  ```dart
  /// Variantes visuelles du bouton Valider.
  enum BSheetSubmitVariant {
    /// Bouton Valider en couleur primary (amber) — défaut.
    primary,
    /// Bouton Valider en couleur error (expense) — confirmation dangereuse.
    danger,
  }
  ```

---

### T-2 — Sous-widget privé : _BSheetHandle

- **Responsabilité** : Handle 36×4 px centré, conforme `.bsheet__handle` Angular.
- **Fichier** : `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart`
- **Requirements couverts** : FR-002, FR-013
- **Approche** :
  ```dart
  class _BSheetHandle extends StatelessWidget {
    const _BSheetHandle();
    @override
    Widget build(BuildContext context) {
      return Center(
        child: Container(
          width: 36, height: 4,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.round),
          ),
        ),
      );
    }
  }
  ```

---

### T-3 — Sous-widget privé : _BSheetActionPill

- **Responsabilité** : Pill d'action configurable (primary, cancel, danger, status, loading) — file-scoped. Conforme `.bsheet__action-pill--*` Angular (RES-004).
- **Fichier** : `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart`
- **Requirements couverts** : FR-005, FR-006, FR-007, FR-008, FR-013, SC-004, SC-007, SC-014
- **Approche** : `InkWell(borderRadius: AppRadius.round) + Container(padding: 5-8px, BoxDecoration(border: Border.all(color), borderRadius: AppRadius.round))`. Variantes via enum privé `_BSheetActionPillVariant { primary, cancel, danger, status, loading }`.

  | Variante | Couleur texte | Couleur bordure | Fond | Splash |
  |----------|--------------|-----------------|------|--------|
  | `primary` | `colorScheme.primary` | `colorScheme.primary` | transparent | `primarySubtle` |
  | `cancel` | `colorScheme.onSurfaceVariant` | `colorScheme.outline` | transparent | `hoverSubtle` |
  | `danger` | `ext.expenseColor` | `ext.expenseColor` | transparent | `errorContainer` 60% |
  | `status` | `colorScheme.onSurfaceVariant` | `colorScheme.outline` | transparent | `hoverSubtle` |
  | `loading` | désactivé, `opacity: 0.4` | idem primary | transparent | Colors.transparent |

  État `loading` : remplace le `Text` par `CircularProgressIndicator(value: null, strokeWidth: 2)` 16×16 (FR-008). Tap ignoré si `loading` (callback non invoqué — FR-008, SC-004).

---

### T-4 — Sous-widget privé : _BSheetErrorBanner

- **Responsabilité** : Bandeau d'erreur au-dessus de Row 1, clé `Key('bsheet_error_banner')`.
- **Fichier** : `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart`
- **Requirements couverts** : FR-009, FR-010, FR-013, SC-005, SC-006
- **Approche** :
  ```dart
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
          style: AppTypography.bodySmall.copyWith(color: cs.error),
        ),
      );
    }
  }
  ```

---

### T-5 — Widget principal : BottomSheet4RowsWidget

- **Responsabilité** : Assembler les 4 rows + zone expand + footer dans le layout Column { Expanded(ScrollView), Row4 }. Exposer l'API publique par slots (FR-005). Gérer les états loading/error/footerEnabled.
- **Fichier** : `flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart`
- **Requirements couverts** : FR-001, FR-002, FR-003, FR-004, FR-005, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-014, FR-015, FR-016, tous SC, tous NFR
- **Approche** :

  **Paramètres** (voir FR-005 complet) :
  ```dart
  class BottomSheet4RowsWidget extends StatelessWidget {
    const BottomSheet4RowsWidget({
      super.key,
      required this.title,
      this.titleIcon,
      this.topTrailing,
      required this.amountField,
      this.libelleField,
      this.notePreview,
      this.iconButtons,
      required this.metaPills,
      this.expandedContent,
      this.footerLeading,
      this.onCancel,
      required this.onSubmit,
      this.cancelLabel = 'Annuler',
      this.submitLabel = 'Valider',
      this.loading = false,
      this.errorMessage,
      this.submitVariant = BSheetSubmitVariant.primary,
      this.footerEnabled = true,
      this.onExpandClose,
    });
    // ... champs
  }
  ```

  **Structure build** :
  ```
  Column(
    children: [
      if (errorMessage != null) _BSheetErrorBanner(message: errorMessage!),
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Row 1 — Key('bsheet_top')
              _BSheetHandle(),
              Row(children: [titleIcon?, Text(title), Spacer(), topTrailing?]),

              // Row 2 — Key('bsheet_main_row')
              Row(children: [amountField, libelleField ?? SizedBox.shrink()]),

              // Note preview — Key('bsheet_note_preview') si notePreview != null
              if (notePreview != null) notePreview!,

              // Row 3 — Key('bsheet_meta_row') si non vide (CL-001)
              if (iconButtons != null || metaPills.isNotEmpty)
                Row(children: [iconButtons?, ...metaPills]),

              // Zone expand — Key('bsheet_expand')
              AnimatedSize(
                duration: AppDurations.normal,
                curve: AppDurations.easeOut,
                alignment: Alignment.topCenter,
                child: expandedContent != null
                    ? KeyedSubtree(key: const Key('bsheet_expand'), child: expandedContent!)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      // Row 4 — Key('bsheet_bottom_row') — pinned
      _buildFooter(context),
    ],
  )
  ```

  **Footer `_buildFooter`** :
  - `footerLeading != null` → Row(children: footerLeading!) — Annuler non rendu (CL-002)
  - `footerLeading == null` → Row(children: [_BSheetActionPill(cancel), Spacer()])
  - `footerEnabled: false` → `Opacity(opacity: 0.4, child: IgnorePointer(child: footer))` (FR-007, SC-008)
  - Bouton Valider : `_BSheetActionPill(loading ? loading : submitVariant)`, key `Key('bsheet_submit')` (FR-008, SC-004)
  - Bouton Annuler : key `Key('bsheet_cancel')` (SC-004)

---

### T-6 — Tests : bottom_sheet_4_rows_widget_test.dart

- **Responsabilité** : Couvrir les 14 SC × 2 thèmes = ≥ 10 tests.
- **Fichier** : `flutter/test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart`
- **Requirements couverts** : SC-001 à SC-014, NFR-001
- **Approche** : Utiliser `forEachTheme` helper existant (`test/helpers/theme_test_helpers.dart`). Pump dans `MaterialApp(theme: theme, home: Scaffold(body: widget))`.

  | Test | SC | Thèmes |
  |------|----|--------|
  | Rendu 4 rows minimal (keys structurelles) | SC-001 | × 2 |
  | Slots injectés présents inchangés (3 variantes) | SC-002 | × 2 |
  | Expand null → non-null : AnimatedSize déclenché | SC-003 | × 2 |
  | `loading: true` : spinner visible, onSubmit non invoqué | SC-004 | × 2 |
  | `errorMessage: 'X'` : bandeau key + couleurs | SC-005 | × 2 |
  | `loading + errorMessage` : coexistence | SC-006 | × 2 |
  | `footerLeading` à gauche, spaceBetween | SC-007 | × 2 |
  | `footerEnabled: false` : bloque callbacks | SC-008 | × 2 |
  | Grep no-hex (SC-009) | SC-009 | — (grep script, pas widget test) |
  | Tests dark + light (via forEachTheme) | SC-010 | × 2 |
  | 3 hauteurs sans overflow | SC-012 | × 2 |
  | notePreview null vs non-null (key) | SC-013 | × 2 |
  | footerLeading 3 cas (null / [1] / [2]) | SC-014 | × 2 |

  Note SC-011 (documentation) : vérification lecture humaine + `dart doc` — pas un widget test automatisé.
  Note SC-009 (grep no-hex) : vérifiable par `grep -nE "Color\(0x|#[0-9a-fA-F]{6,8}" flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart`.

---

## Risques et mitigations

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| Appelant n'utilise pas `isScrollControlled: true` → Row 4 masquée par le clavier | Haut | Moyenne | Documentation `///` du widget sur la responsabilité appelant (NFR-007). Exemple complet dans doc de classe (FR-012). |
| `AnimatedSize` dans `SingleChildScrollView` : saccade si `InlineDatePicker` 6 semaines (hauteur ~300px) | Moyen | Basse | Validé sur device réel en Étape 5 (CL-008 différé). `AnimatedSize` est éprouvé sur 3 composants existants — risque faible. |
| Ajout `errorContainer` dans `app_theme.dart` : rupture de tests existants vérifiant les couleurs Material par défaut | Bas | Très basse | Aucun test existant ne vérifie `errorContainer` (grep confirmé). L'ajout est additif. |
| `onExpandClose` non connecté par l'appelant → bouton retour Android ferme le sheet (pas juste l'expand) | Bas | Moyenne | NFR-006 documenté dans `///`. Le widget ne peut pas forcer le parent à connecter le callback. |

---

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | [research.md](./research.md) | Oui | 5 décisions techniques (RES-001 à RES-005) |
| Data Model | — | Non | Widget 100% UI / présentation — aucune entité métier |
| Quickstart | [quickstart.md](./quickstart.md) | Oui | Guide de démarrage pour l'implémenteur |

---

## Hors scope

- Refonte des 3 formulaires consommateurs (Transaction, Subscription, Debt) — Étape 5 / KKS-241+
- Extraction des sous-widgets (`_BSheetHandle`, `_BSheetActionPill`) en composants publics `common_widgets/` — aucun second site d'appel à ce stade (Constitution YAGNI)
- Animations sophistiquées au-delà d'`AnimatedSize` (slide, cross-fade, spring)
- `InlineDatePicker` et `CategorySelectExpand` ne sont pas importés ni instanciés dans le widget
- Gestion du clavier par le widget lui-même (`viewInsets`) — responsabilité de l'appelant
- Migration des sites d'appel actuels (`TransactionForm`, etc.) — Étape 5
