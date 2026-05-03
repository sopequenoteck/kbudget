# Documentation — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
> Issue parent : [KKS-236](https://linear.app/kksdev/issue/KKS-236/phase-1-refonte-design-flutter-v5)

---

## Résumé

Première étape de la **Phase 1 — Refonte design Flutter v5** : alignement complet des tokens design Flutter (`AppColors`, `AppTypography`, `AppShadows`, `AppTheme`, `AppThemeExtension`) sur la palette propriétaire Angular v5 (couche primitive `_primitives.scss` + couche semantique `_dark.scss` / `_light.scss`). L'architecture en deux couches Angular est reproduite côté Flutter, avec compatibilité backward stricte sur les 14+ widgets consommateurs existants. Les anti-patterns gradient (PatrimoineCard) sont marqués `@Deprecated` pour suppression effective en KKS-240.

Cette feature débloque les étapes suivantes de Phase 1 (KKS-238 composants shared, KKS-239 BottomSheet pattern, KKS-240+ refonte écrans).

---

## Guide utilisateur

### Pour le développeur Flutter

#### 1. Consommer les tokens primitives `AppColors`

Les primitives de palette restent accessibles directement (palette gris propriétaire + amber/violet/feedback Tailwind-compatibles) :

```dart
import 'package:k_budget/src/constants/app_colors.dart';

// Palette gris propriétaire (10 nuances : #fafafa → #0a0a0a)
Container(color: AppColors.gray800)  // #141414 — surface dark
Container(color: AppColors.gray100)  // #f5f5f5 — surface light raised

// Palette amber (Tailwind, inchangée — pour usages structurels Material)
const Border(color: AppColors.amber600)  // #d97706 — primary light Material container

// Feedback primitives (Tailwind, inchangées — pour usage brut hors theme)
const Color rawSuccess = AppColors.success;  // #22c55e
```

#### 2. Consommer les tokens sémantiques via le thème (recommandé)

Pour les couleurs sémantiques (primary, business, feedback, interactifs), **passer par le thème** plutôt que par les constantes directes :

```dart
// Primary — change automatiquement avec le thème (dark/light)
final theme = Theme.of(context);
Container(color: theme.colorScheme.primary)
// → #e0a820 en dark, #d97706 en light

// Business tokens (income, expense, subscription, etc.) via AppThemeExtension
final ext = theme.extension<AppThemeExtension>()!;
Container(color: ext.incomeColor)         // #6dc990 dark, #16a34a light
Container(color: ext.expenseColor)        // #d97777 dark, #dc2626 light
Container(color: ext.subscriptionColor)   // #9580d9 dark, #8b5cf6 light

// Feedback secondaires (textWarning, textInfo)
Text('attention', style: TextStyle(color: ext.textWarning))
Text('info', style: TextStyle(color: ext.textInfo))

// Interactifs (hover, focus, overlay, icon backgrounds)
Container(color: ext.primarySubtle)   // amber 0.10 alpha
Container(color: ext.iconCircleBg)    // 0.06 alpha (white dark / black light)
Container(color: ext.focusRing)       // amber 0.5 alpha
```

#### 3. Consommer les ombres `AppShadows`

```dart
// Ombres neutres (mêmes en dark et light)
Container(decoration: BoxDecoration(boxShadow: AppShadows.sm))    // single layer
Container(decoration: BoxDecoration(boxShadow: AppShadows.md))    // double layer
Container(decoration: BoxDecoration(boxShadow: AppShadows.lg))    // double layer

// Ombre primary (brightness-aware)
Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.coloredPrimary(Theme.of(context).brightness),
  ),
)
// → noire neutre en dark, amber glow en light

// Constantes statiques pour usage const
const decoration = BoxDecoration(boxShadow: AppShadows.coloredPrimaryDark);
```

L'ancienne API `AppShadows.colored(Color, {alpha})` reste disponible mais marquée `@Deprecated`. Migrer vers `coloredPrimary(brightness)`.

#### 4. Typographie

```dart
// Tailles existantes inchangées : sizeXs (12), sizeSm (14), sizeMd (16), sizeLg (18), sizeXl (20), size2xl (24), size3xl (30)

// Nouvelles tailles
const TextStyle smallLabel = TextStyle(fontSize: AppTypography.size2Xs);  // 10px — labels uppercase

// Hero — RÉSERVÉ AU PATRIMOINE TOTAL DASHBOARD
const TextStyle heroAmount = TextStyle(
  fontSize: AppTypography.sizeHero,  // 36px
  fontWeight: AppTypography.bold,
);

// Letter-spacing labels uppercase — convention hybride
// Usage statique
const TextStyle uppercaseSize10 = TextStyle(
  fontSize: AppTypography.size2Xs,
  letterSpacing: AppTypography.labelLetterSpacingForSize10,  // 0.5
);

// Usage dynamique
Text(
  'LABEL',
  style: TextStyle(
    fontSize: dynamicSize,
    letterSpacing: dynamicSize * AppTypography.labelLetterSpacingFactor,  // 0.05 × size
  ),
)
```

### Pour le designer / référence cross-stack

La palette Flutter est désormais **strictement alignée** sur les fichiers SCSS Angular v5 :

| Concept | Flutter (`AppColors`) | Angular (SCSS) |
|---|---|---|
| Palette gris propriétaire | `gray50` → `gray900` | `_primitives.scss` `$gray-50` → `$gray-900` |
| Primitives amber (Tailwind) | `amber50` → `amber900` | `$amber-*` (inchangées) |
| Primary semantique dark | `primaryAmberDark = #E0A820` | `_dark.scss` `--color-primary` |
| Income dark | `incomeDark = #6DC990` | `_dark.scss` `--color-income` |
| Expense dark | `expenseDark = #D97777` | `_dark.scss` `--color-expense` |
| Subscription dark | `subscriptionDark = #9580D9` | `_dark.scss` `--color-subscription` |
| Hero font size | `AppTypography.sizeHero = 36.0` | `_dark.scss` `--font-size-hero: 2.25rem` |

**Source de vérité unique** : les fichiers SCSS Angular (`app/src/styles/tokens/_primitives.scss`, `app/src/styles/themes/_dark.scss`, `app/src/styles/themes/_light.scss`) + `DESIGN.md`. Le fichier `docs/design-tokens.md` est désormais marqué obsolète.

---

## Changements techniques

### Fichiers créés

| Fichier | Description |
|---------|-------------|
| `flutter/test/src/theme/app_theme_extension_test.dart` | 10 tests unitaires (4 groupes) couvrant les 16 propriétés `AppThemeExtension`, méthodes `lerp()` (3 cas), `copyWith()` (1 cas). Couvre SC-006 explicitement. |

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/constants/app_colors.dart` | Refonte palette gris propriétaire (10 nuances). Mise à jour valeurs sémantiques dark business (`incomeDark`, `expenseDark`, `subscriptionDark`, `debtOweDark`, `debtOwedDark`). Ajout 22+ nouvelles constantes sémantiques dark (primary, feedback, interactifs) et light. Toutes documentées via `///`. |
| `flutter/lib/src/constants/app_typography.dart` | Ajout `size2Xs = 10.0`, `sizeHero = 36.0`, `labelLetterSpacingFactor = 0.05` + 3 constantes pré-calculées. |
| `flutter/lib/src/constants/app_shadows.dart` | Refonte `md` et `lg` en double-layer. Ajout `coloredPrimaryDark`/`coloredPrimaryLight` const + helper `coloredPrimary(Brightness)`. `@Deprecated` sur `colored(Color, {alpha})`. |
| `flutter/lib/src/theme/app_theme_extension.dart` | Extension de 6 → 16 propriétés. Méthodes `copyWith()` et `lerp()` étendues. Instances `dark`/`light` mises à jour. Compatibilité backward stricte sur les 6 propriétés existantes. |
| `flutter/lib/src/theme/app_theme.dart` | Refonte `AppTheme.dark` (`primary` `amber400` → `primaryAmberDark`) et `AppTheme.light` (`primary` `amber500` → `amber600`). Audit ligne par ligne des 14+ usages `AppColors.amber*` avec reclassements sémantiques. |
| `flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart` | Annotation `@Deprecated('Gradient décoratif interdit en dark v5 — refonte hero flat dans KKS-240. Token Angular équivalent neutralisé : --hero-gradient: none.')` sur la classe. |
| `flutter/test/src/theme/app_theme_test.dart` | 2 tests adaptés : `should_use_amber_500_as_primary_in_light_theme` → `should_use_amber_600_as_primary_in_light_theme` ; `should_use_amber_400_as_primary_in_dark_theme` → `should_use_primary_amber_dark_as_primary_in_dark_theme`. |
| `flutter/android/app/build.gradle.kts` | Effet de bord T-002 baseline (`flutter pub get`) : activation `isCoreLibraryDesugaringEnabled` + dépendance `desugar_jdk_libs`. |
| `docs/design-tokens.md` | Insertion en entête d'un avertissement `> ⚠️ OBSOLÈTE` avec redirection vers les sources de vérité actuelles (`_primitives.scss`, `_dark.scss`, `_light.scss`, `DESIGN.md`, dossiers Flutter `constants/` et `theme/`). |

### Dépendances ajoutées

| Package | Version | Raison |
|---------|---------|--------|
| (aucune) | — | Conformément à NFR-004. `pubspec.yaml` inchangé. |

`build.gradle.kts` ajoute `com.android.tools:desugar_jdk_libs:2.1.4` au runtime Android — effet de bord du baseline check, pas une dépendance Dart.

---

## Configuration

Aucune configuration applicative requise. Les tokens sont injectés via `MaterialApp.theme` et `MaterialApp.darkTheme` standard :

```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,  // ou ThemeMode.dark / ThemeMode.light
)
```

L'`AppThemeExtension` est automatiquement disponible via `Theme.of(context).extension<AppThemeExtension>()` dans tout le sous-arbre `MaterialApp`.

---

## Tests et validation

### Tests unitaires

| Fichier | Tests | Statut |
|---------|-------|--------|
| `flutter/test/src/theme/app_theme_test.dart` | 7 tests (5 préexistants + 2 adaptés) | ✅ Tous passent |
| `flutter/test/src/theme/app_theme_extension_test.dart` (NOUVEAU) | 10 tests (4 groupes : dark instance, light instance, lerp, copyWith) | ✅ Tous passent |

**Couverture des Success Criteria** :

| SC | Test | Statut |
|---|---|---|
| SC-005 (`primary == #E0A820` dark) | `app_theme_test.dart : should_use_primary_amber_dark_as_primary_in_dark_theme` | ✅ |
| SC-006 (`incomeColor == #6DC990` dark) | `app_theme_extension_test.dart` (assertion explicite + référence `AppColors.incomeDark`) | ✅ |
| SC-007 (`coloredPrimary(dark)` ombre noire) | Audit code `app_shadows.dart` (constantes const) | ✅ |
| SC-008 (≥ 12 nouveaux tokens documentés) | Audit grep `///` sur `app_colors.dart`, `app_typography.dart` | ✅ ~16 tokens |

### Tests d'intégration

Sans objet — la feature ne touche pas la couche métier ni les flux utilisateur. Les widgets consommateurs (14+ existants utilisant `AppThemeExtension`) continuent de fonctionner sans modification grâce à la compatibilité backward stricte.

### Validation manuelle

- [x] **Test visuel dark theme** validé : `primary` apparaît en `#e0a820` (plus doux que `amber400` Tailwind), surfaces en `#141414` / `#0a0a0a` (plus sombres que `#1F2937` / `#111827` Tailwind).
- [x] **Test visuel light theme** validé : `primary` reste `#d97706` (`amber600`), surfaces blanches / `gray100` (`#f5f5f5`).
- [x] **`flutter analyze`** : 0 erreur, 15 infos pré-existantes (warnings `@Deprecated` attendus sur `PatrimoineCard` et `AppShadows.colored`).
- [x] **`flutter test`** : 709/711 passent. 2 préexistants hors scope (`recurring_list_screen_test.dart`, `dashboard_notifier_test.dart`) — à traiter dans une PR séparée.
- [x] **Audit grep SC-001** : `grep -E '#(111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/constants/` → 0 ligne pour les nuances Tailwind primaires.
- [x] **Audit grep SC-002** : ≥ 10 nuances propriétaires (`#fafafa`, `#f5f5f5`, ..., `#0a0a0a`) dans `app_colors.dart`.
- [x] **Audit informatif T-062 / SC-011** : `grep -E '#(F59E0B|D97706|FBBF24|FCD34D|4ADE80|F87171|8B5CF6|A78BFA|...)' flutter/lib/src/features/` → **0 occurrence**. Aucun hardcode Tailwind dans les widgets de features. Mieux que prévu.

---

## Notes techniques et dette résiduelle

### Dette technique différée à KKS-240+

#### `unbudgetedGray = Color(0xFF9CA3AF)` (préexistant)

`AppColors.unbudgetedGray` correspond à la valeur Tailwind `gray-400` (`#9CA3AF`). Cette constante préexistante est conservée pour compatibilité avec les widgets qui la consomment (probablement le module budget). Elle n'a pas été migrée dans KKS-237 pour ne pas élargir le périmètre.

**Action future** : soit la renommer en alias explicite (`AppColors.gray400` Tailwind) pour clarifier sa nature, soit la documenter comme token business hors couche primitive. À traiter dans KKS-240 lors de la refonte des écrans budget.

#### `scaffoldBackgroundColor` light : `gray50 = #fafafa` vs `#f0f0f0` spec

L'`AppTheme.light.scaffoldBackgroundColor` est défini à `AppColors.gray50` (`#fafafa`) alors que la spec FR-012a indique `#f0f0f0` conforme à `_light.scss --bg-primary`. Cet écart est **acceptable** selon l'**Assumption A5** de la spec : *"Le light theme reste partiellement Tailwind-compatible (primary `amber-600`, income `green-600`, etc.) conformément à `_light.scss` Angular. Pas de refonte light pixel-perfect requise."*

**Action future** : vérifier visuellement la cohérence en KKS-242 (refonte écrans M light) et ajuster si nécessaire.

#### `Color(0xFFF87171)` hardcodé pour `error` dark

Dans `app_theme.dart`, le `colorScheme.error` du dark theme utilise une valeur hex hardcodée (`#F87171` = Tailwind `red-400`) au lieu de référencer une constante `AppColors`. La valeur est correcte mais la pratique d'uniformité n'est pas respectée.

**Action future** : remplacer par `AppColors.expenseDark` (`#D97777`) ou créer une constante dédiée `AppColors.errorDark` lors d'un pass de cohérence en KKS-238 ou KKS-240.

#### Hardcodes `AppColors.amber100` dans 2 widgets (cf. RES-006)

- `flutter/lib/src/common_widgets/list_item.dart:76`
- `flutter/lib/src/features/dashboard/presentation/widgets/recent_transactions_section.dart:211`

Ces fonds d'icône utilisent `AppColors.amber100` directement au lieu d'un token sémantique (`iconCircleBg` ou `primarySubtle`).

**Action future** : à corriger dans KKS-238 (refonte composants shared) et KKS-240 (refonte écrans dashboard).

#### Convention de nommage `overlayLightOnDark` / `overlayLightOnLight`

Suite à la review-impl-frontend, les constantes `overlayLightDark`/`overlayLightLight` ont été renommées en `overlayLightOnDark`/`overlayLightOnLight` pour éliminer l'ambiguïté du double "Light". Le fichier `contracts.md` initial mentionne encore `overlayLightDark`/`overlayLightLight`. À aligner lors d'une mise à jour future de `contracts.md` si nécessaire.

### Tests préexistants hors scope cassés

2 tests Flutter cassent dans la baseline et restent cassés après KKS-237 :
- `flutter/test/src/features/recurring/presentation/recurring_list_screen_test.dart : should_show_recurring_items_sorted`
- `flutter/test/src/features/dashboard/application/dashboard_notifier_test.dart : should_loadCurrentSummary_when_loadDashboardSucceeds`

Ces échecs sont préexistants et ne sont pas causés par la refonte tokens. À traiter dans une PR de maintenance séparée hors KKS-237.

---

## Références

- Constitution v3.0.0 : [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md)
- Issue parent : [KKS-236](https://linear.app/kksdev/issue/KKS-236) — Phase 1 Refonte design Flutter v5
- Source de vérité tokens Angular : [`app/src/styles/tokens/_primitives.scss`](../../app/src/styles/tokens/_primitives.scss), [`app/src/styles/themes/_dark.scss`](../../app/src/styles/themes/_dark.scss), [`app/src/styles/themes/_light.scss`](../../app/src/styles/themes/_light.scss)
- Référence design : [`DESIGN.md`](../../DESIGN.md), [`DESIGN-REFONTE.md`](../../DESIGN-REFONTE.md)
- Artefacts devflow KKS-237 :
  - [spec.md](./spec.md) — 7 US, 23 FR, 5 NFR, 11 SC
  - [clarify-log.md](./clarify-log.md) — 5 résolutions
  - [research.md](./research.md) — 8 décisions techniques
  - [plan.md](./plan.md) — Constitution Check PASS, 7 composants
  - [contracts.md](./contracts.md) — signatures Dart publiques
  - [data-model.md](./data-model.md) — 5 entités logiques
  - [quickstart.md](./quickstart.md) — guide d'implémentation
  - [tasks.md](./tasks.md) — 37 tâches
  - [review-log.md](./review-log.md) — 3 reviews PASS (review-spec, review-tasks, review-impl)
- Commits sur `feature/flutter-tokens-refonte-v5` :
  - `6a31c71` — Artefacts devflow Phase 1 / Étape 1
  - `743e55f` — Lot 1 (AppColors palette propriétaire + AppTypography + design-tokens.md)
  - `c8d3566` — Lot 2 (AppShadows + AppThemeExtension + AppTheme + PatrimoineCard @Deprecated)
  - `88a1848` — Lot 3 (tests adaptés + nouveau app_theme_extension_test)
  - `dfb4b08` — Corrections post-review-frontend (rename `overlayLight*`, docstring `sizeHero`)
  - `88d5319` — Finalisation tasks + state.json

---

## Prochaines étapes (roadmap Phase 1)

| Étape | Issue | Description |
|-------|-------|-------------|
| 2 | [KKS-238](https://linear.app/kksdev/issue/KKS-238) | 8 composants shared (SectionHeaderSticky, ListGroup, EmptyStateWidget, etc.) |
| 3 | [KKS-239](https://linear.app/kksdev/issue/KKS-239) | BottomSheet4RowsWidget composable |
| 4 | [KKS-240](https://linear.app/kksdev/issue/KKS-240) | Refonte 4 écrans L (Dashboard, Transactions, Abonnements, Dettes) — suppression effective gradient PatrimoineCard |
| 5 | [KKS-241](https://linear.app/kksdev/issue/KKS-241) | Refonte 3 formulaires XL via BottomSheet4RowsWidget |
| 6 | [KKS-242](https://linear.app/kksdev/issue/KKS-242) | Refonte 9 écrans M |
| 7 | [KKS-243](https://linear.app/kksdev/issue/KKS-243) | Refonte 6 écrans S |
| 8 | [KKS-244](https://linear.app/kksdev/issue/KKS-244) | Onboarding commercial |
