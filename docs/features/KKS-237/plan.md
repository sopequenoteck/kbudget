# Plan — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
> Spec : [spec.md](./spec.md)
> Research : [research.md](./research.md)

---

## Constitution Check

> Vérification des 7 principes de la constitution v3.0.0 (`/Users/kellysossoe/Code/Apps/budget/.specify/memory/constitution.md`).

| Principe | Statut | Commentaire |
|----------|--------|-------------|
| **I. API-First / Local-First** | ✅ PASS | Refonte 100% locale (`flutter/lib/src/constants/`, `flutter/lib/src/theme/`). Aucune dépendance réseau introduite. NFR-004 garantit pubspec.yaml inchangé. Mode Flutter standalone (Trajectoire B). |
| **II. Sécurité par défaut** | ✅ N/A | Pas de routes API, pas de mots de passe, pas de JWT, pas d'inputs utilisateur dans le périmètre. |
| **III. Simplicité & YAGNI** | ✅ PASS | Aucune abstraction prématurée. Patterns existants conservés (`class _()` + `static const`, `ThemeExtension<T>`, `Color.lerp` natif). RES-001/003 explicitent le refus du refactoring opportuniste. RES-002 introduit 1 helper et 2 constantes — pas de complexité non justifiée. |
| **IV. Mobile-First UX** | ✅ PASS | Tokens optimisés mobile (`sizeHero = 36`, `size2Xs = 10`). Aucun impact direct sur les interactions. La PWA Angular est hors scope. |
| **V. Testabilité** | ✅ PASS | NFR-002 exige `flutter test` à 100%. SC-003/SC-004 mesurent `flutter analyze` et `flutter test`. Tests unitaires à compléter pour `AppThemeExtension.lerp()` étendu (RES-004). |
| **VI. Observabilité** | ✅ N/A | Refonte de tokens — pas de logique applicative. Aucun log à produire. |
| **VII. Two Distribution Trajectories** | ✅ PASS | Trajectoire B (Flutter standalone) explicite dans NFR-005. La refonte alignement avec Angular v5 est cohérente avec la coexistence des deux trajectoires. |

### Dérogations

Aucune dérogation. Tous les principes sont respectés.

| Article | Dérogation | Justification |
|---------|------------|---------------|
| — | — | — |

### Complexity Tracking

| # | Complexité | Justification | Alternative envisagée |
|---|-----------|---------------|----------------------|
| CX-001 | Helper `AppShadows.coloredPrimary(Brightness)` introduit en plus des 2 constantes statiques `coloredPrimaryDark/Light` | Combinaison `const`-friendly + dynamic-friendly. Sans helper, chaque caller dynamique duplique la logique de sélection. | Option C (constantes seules, sans helper) — rejetée car chaque caller doit re-écrire le `switch (brightness)`. Cf. RES-002. |

---

## Résumé de l'approche

Refonte ciblée des fichiers de tokens Flutter (`flutter/lib/src/constants/app_*.dart`) et du thème (`flutter/lib/src/theme/app_theme*.dart`) pour aligner sur la palette propriétaire Angular v5 (couche primitive `_primitives.scss` + couche semantique `_dark.scss` / `_light.scss`). Architecture en 2 couches reproduite côté Flutter : `AppColors` = primitives, `AppTheme` + `AppThemeExtension` = semantique. Les patterns existants sont conservés (constructeur privé + statiques, `ThemeExtension<T>` Material 3, `Color.lerp` natif). Une seule classe widget (`PatrimoineCard`) reçoit une annotation `@Deprecated` pour signaler la suppression du gradient anti-pattern dans KKS-240.

---

## Contexte technique

- **Stack** : Flutter ≥ 3.27, Dart ≥ 3.6, Material 3 (`useMaterial3: true`)
- **Dépendances nouvelles** : aucune (NFR-004 conforme)
- **Dépendances existantes impactées** :
  - `phosphor_flutter` v2.1.0 : non touché (icônes)
  - Aucune autre lib externe impactée
- **Source de vérité Angular** : `app/src/styles/tokens/_primitives.scss`, `app/src/styles/themes/_dark.scss`, `app/src/styles/themes/_light.scss`

---

## Architecture

### Structure des fichiers impactés

```
flutter/lib/src/
├── constants/
│   ├── app_colors.dart           [M] Refonte palette gris (10 nuances) + valeurs sémantiques mises à jour + ~22 nouvelles constantes sémantiques
│   ├── app_typography.dart       [M] Ajout size2Xs, sizeHero, labelLetterSpacingFactor, labelLetterSpacingForSize10/12/14
│   ├── app_shadows.dart          [M] Refonte md/lg double-layer + ajout coloredPrimaryDark/Light + helper coloredPrimary(Brightness) + @Deprecated colored()
│   ├── app_radius.dart           [—] Inchangé (déjà aligné)
│   ├── app_spacing.dart          [—] Inchangé (déjà aligné)
│   └── app_durations.dart        [—] Inchangé (déjà aligné)
├── theme/
│   ├── app_theme.dart            [M] Refonte AppTheme.dark (primary → primaryAmberDark) + AppTheme.light (primary → amber600) + extensions étendues
│   └── app_theme_extension.dart  [M] Extension avec ~10 nouveaux tokens + lerp() + copyWith() étendus + tests unitaires
└── features/dashboard/presentation/widgets/
    └── patrimoine_card.dart      [M] Annotation @Deprecated('...KKS-240...') sur la classe

docs/
└── design-tokens.md              [M] Insertion avertissement obsolète en entête + redirection vers SCSS + DESIGN.md

flutter/test/
└── theme/
    └── app_theme_extension_test.dart  [M ou C] Tests unitaires pour les nouveaux tokens et le lerp() étendu
```

**Total** :
- 6 fichiers Flutter modifiés (5 dans `lib/`, 1 test)
- 1 fichier doc modifié
- 0 fichier créé (sauf possible nouveau fichier de tests)

### Diagramme de flux

```
┌─────────────────────────────────────────────────────────────────┐
│ Couche primitive (AppColors)                                     │
│  - Palette gris propriétaire (#fafafa → #0a0a0a)                 │
│  - Palettes amber/violet/feedback Tailwind-compatibles           │
│  - Constantes sémantiques dark (primaryAmberDark = #e0a820, etc.)│
│  - Constantes sémantiques light (primarySubtleLight, etc.)       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                ┌──────────┴──────────┐
                ▼                      ▼
┌────────────────────────┐  ┌─────────────────────────────────┐
│ AppTheme.dark/.light   │  │ AppThemeExtension.dark/.light   │
│ (ThemeData Material 3) │  │ (16 propriétés Color)           │
│  - colorScheme.*       │  │  - 6 business existantes        │
│  - elevatedButton, FAB │  │  - +10 sémantiques nouvelles    │
└────────────────────────┘  └─────────────────────────────────┘
                │                      │
                └──────────┬───────────┘
                           ▼
              ┌────────────────────────────┐
              │ Widgets consommateurs (14+)│
              │ - Theme.of(context)         │
              │ - Theme.of(context).extension<AppThemeExtension>()│
              └────────────────────────────┘
```

---

## Approche par composant

### Composant 1 — `AppColors` (couche primitive + sémantique)

- **Responsabilité** : exposer toutes les couleurs primitives (palettes amber, violet, feedback Tailwind-compatibles + palette gris propriétaire) et les valeurs sémantiques par thème (dark/light).
- **Fichiers** : `flutter/lib/src/constants/app_colors.dart`
- **Requirements couverts** : FR-001, FR-002, FR-003, FR-004, FR-005, FR-009 (constantes utilisées par AppThemeExtension), FR-010 (constantes feedback dark/light), FR-011 (constantes interactives dark), FR-012b/c/d (constantes light)
- **Approche** :
  1. **Refonte palette gris** : remplacer `gray50 → gray900` par les 10 valeurs propriétaires (`#fafafa, #f5f5f5, #e5e5e5, #d4d4d4, #a3a3a3, #737373, #525252, #1e1e1e, #141414, #0a0a0a`).
  2. **Conservation primitives amber/violet/feedback** : aucune modification (RES-001 + FR-002/003/004).
  3. **Mise à jour valeurs sémantiques dark existantes** : `incomeDark = #6dc990`, `expenseDark = #d97777`, `subscriptionDark = #9580d9`, `debtOweDark = #d97777`, `debtOwedDark = #6dc990` (5 modifications).
  4. **Ajout section "Semantic dark values"** avec docstrings explicites (RES-003) :
     - Primary : `primaryAmberDark = #e0a820`, `primaryAmberHoverDark = #c9952a`
     - Feedback : `textWarningDark = #d4ad3c`, `textInfoDark = #7aacdb` (textSuccess/textError reprennent income/expense)
     - Interactifs : `primarySubtleDark`, `primaryMutedDark`, `primaryBorderDark`, `hoverBgDark`, `hoverSubtleDark`, `highlightSubtleDark`, `overlayLightDark`, `focusRingDark`, `iconCircleBgDark`
  5. **Ajout section "Semantic light values"** :
     - `textWarningLight = #ca8a04`, `textInfoLight = #2563eb`
     - `primarySubtleLight`, `primaryMutedLight`, `primaryBorderLight`, `hoverBgLight`, `hoverSubtleLight`, `highlightSubtleLight`, `overlayLightLight`, `focusRingLight`, `iconCircleBgLight`

### Composant 2 — `AppTypography`

- **Responsabilité** : exposer les tailles, poids et conventions typographiques.
- **Fichiers** : `flutter/lib/src/constants/app_typography.dart`
- **Requirements couverts** : FR-013, FR-014, FR-015
- **Approche** :
  1. Ajouter `size2Xs = 10.0` et `sizeHero = 36.0` avec docstrings.
  2. Ajouter convention letter-spacing hybride :
     - `labelLetterSpacingFactor = 0.05` (facteur dynamique)
     - `labelLetterSpacingForSize10 = 0.5`
     - `labelLetterSpacingForSize12 = 0.6`
     - `labelLetterSpacingForSize14 = 0.7`

### Composant 3 — `AppShadows`

- **Responsabilité** : exposer les ombres `BoxShadow` const + helper brightness-aware.
- **Fichiers** : `flutter/lib/src/constants/app_shadows.dart`
- **Requirements couverts** : FR-016, FR-017, FR-018, FR-019
- **Approche** :
  1. **Refonte `md`** : passer de single-layer à double-layer.
     ```dart
     static const List<BoxShadow> md = [
       BoxShadow(color: Color(0x1A000000), blurRadius: 6, spreadRadius: -1, offset: Offset(0, 4)),
       BoxShadow(color: Color(0x1A000000), blurRadius: 4, spreadRadius: -2, offset: Offset(0, 2)),
     ];
     ```
  2. **Refonte `lg`** : double-layer avec valeurs `_primitives.scss`.
  3. **Conservation `sm`** (déjà aligné).
  4. **Ajout `coloredPrimaryDark`** : `BoxShadow(color: Color(0x66000000), blurRadius: 24, spreadRadius: -4, offset: Offset(0, 8))` (alpha 0x66 = 0.4).
  5. **Ajout `coloredPrimaryLight`** : idem mais `Color(0x66F59E0B)` (amber primitive avec alpha 0.4).
  6. **Ajout helper** :
     ```dart
     static List<BoxShadow> coloredPrimary(Brightness brightness) =>
         brightness == Brightness.dark ? coloredPrimaryDark : coloredPrimaryLight;
     ```
  7. **Marquage `@Deprecated`** sur `colored(Color, {alpha})` :
     ```dart
     @Deprecated('Utiliser AppShadows.coloredPrimary(brightness) ou les constantes coloredPrimaryDark/Light')
     static List<BoxShadow> colored(Color color, {int alpha = 102}) => ...;
     ```

### Composant 4 — `AppThemeExtension`

- **Responsabilité** : exposer les tokens semantiques manquants au `ColorScheme` Material standard.
- **Fichiers** : `flutter/lib/src/theme/app_theme_extension.dart`
- **Requirements couverts** : FR-009, FR-010, FR-011, FR-012b/c/d, FR-022
- **Approche** :
  1. **Conservation des 6 propriétés existantes** (`incomeColor`, `expenseColor`, `debtOweColor`, `debtOwedColor`, `subscriptionColor`, `secondaryColor`) — aucune rupture API pour les 14+ widgets consommateurs (RES-001).
  2. **Ajout de 10 nouvelles propriétés** :
     - Feedback : `textWarning`, `textInfo`
     - Interactifs : `primarySubtle`, `primaryMuted`, `primaryBorder`, `hoverSubtle`, `highlightSubtle`, `overlayLight`, `focusRing`, `iconCircleBg`
     - Note : `hoverBg` est exposé via `ColorScheme.surface` ou directement, à arbitrer pendant l'implémentation.
  3. **Mise à jour des instances `light` et `dark`** :
     - `dark` consomme les nouvelles constantes `AppColors.{name}Dark`.
     - `light` consomme les nouvelles constantes `AppColors.{name}Light`.
  4. **Extension de `lerp()` et `copyWith()`** : ajout des 10 nouvelles propriétés mécaniquement (RES-004).
  5. **Tests unitaires** : compléter `app_theme_extension_test.dart` (créer si absent) avec tests `lerp(t=0)` et `lerp(t=1)` pour chaque propriété.

### Composant 5 — `AppTheme`

- **Responsabilité** : produire `ThemeData.dark` et `ThemeData.light` cohérents avec la palette v5.
- **Fichiers** : `flutter/lib/src/theme/app_theme.dart`
- **Requirements couverts** : FR-006, FR-007, FR-008, FR-012a, FR-020
- **Approche** :
  1. **Audit ligne par ligne** des ~14 occurrences `AppColors.amber*` dans `AppTheme.dark` et `AppTheme.light` (RES-005).
  2. **Refonte `AppTheme.dark`** :
     - `colorScheme.primary` : `AppColors.amber400` → `AppColors.primaryAmberDark`
     - `colorScheme.surface` : `gray800` (`#141414`)
     - `colorScheme.surfaceContainerHighest` : `gray700` (`#1e1e1e`)
     - `colorScheme.background` : `gray900` (`#0a0a0a`)
     - `colorScheme.onPrimary` : `gray900`
     - `selectedItemColor`, `FAB.backgroundColor`, `border focused` : `primaryAmberDark`
     - Conservation des `amber800`/`amber100`/`amber900` pour `primaryContainer`/`onPrimaryContainer` Material si pertinent — sinon migration vers les nouveaux tokens.
  3. **Refonte `AppTheme.light`** :
     - `colorScheme.primary` : `amber600` (`#d97706`, déjà OK conformément à `_light.scss`)
     - `colorScheme.surface` : blanc
     - `colorScheme.surfaceContainerHighest` : `gray100` (`#f5f5f5`)
  4. **Vérification `useMaterial3: true`** : confirmer dans `ThemeData(...)` (à valider au moment de l'implémentation).

### Composant 6 — `PatrimoineCard` (annotation `@Deprecated`)

- **Responsabilité** : signaler le widget gradient anti-pattern.
- **Fichiers** : `flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart`
- **Requirements couverts** : FR-021
- **Approche** :
  1. Ajouter `@Deprecated('Gradient décoratif interdit en dark v5 — refonte hero flat dans KKS-240. Token Angular équivalent neutralisé : --hero-gradient: none.')` sur la classe `PatrimoineCard`.
  2. **Audit grep** complémentaire : `grep -rn "LinearGradient" flutter/lib/src/features/` pour détecter d'autres widgets à marquer.

### Composant 7 — `docs/design-tokens.md` (avertissement obsolète)

- **Responsabilité** : rediriger les contributeurs vers les sources de vérité actuelles.
- **Fichiers** : `docs/design-tokens.md`
- **Requirements couverts** : FR-023
- **Approche** :
  1. Insérer en entête (juste après le titre `# Design Tokens Reference`) :
     ```markdown
     > ⚠️ **OBSOLÈTE** — Ce document n'est plus maintenu.
     >
     > **Sources de vérité actuelles** :
     > 1. **Primitives (couche 1)** : [`app/src/styles/tokens/_primitives.scss`](../app/src/styles/tokens/_primitives.scss)
     > 2. **Tokens semantiques par thème (couche 2)** : [`app/src/styles/themes/_dark.scss`](../app/src/styles/themes/_dark.scss) et [`_light.scss`](../app/src/styles/themes/_light.scss)
     > 3. **Principes design** : [`DESIGN.md`](../DESIGN.md)
     > 4. **Flutter** : [`flutter/lib/src/constants/`](../flutter/lib/src/constants/) et [`flutter/lib/src/theme/`](../flutter/lib/src/theme/)
     >
     > Ce fichier sera supprimé en v3.0.x. Toute modification du contenu ci-dessous est à proscrire.
     ```
  2. Aucune modification du contenu existant (le fichier devient un pointeur).

---

## Risques et mitigations

| # | Risque | Impact | Probabilité | Mitigation |
|---|--------|--------|-------------|------------|
| R-01 | Tests unitaires existants validant des hex précis (e.g. `#4ADE80` pour `incomeDark`) cassent après refonte | Moyen | Haut | Adaptation des tests pour référencer les tokens (`AppColors.incomeDark`) au lieu des valeurs hex (Edge Case déjà documenté + NFR-002). À traiter dans la même PR que la refonte de `AppColors`. |
| R-02 | Régression visuelle sur les écrans entre KKS-237 et KKS-240 (refonte écrans) | Bas | Haut (attendu) | Acceptable et documenté dans la spec (Edge Case "Les écrans Flutter peuvent paraître désalignés visuellement après cette étape"). Communication explicite dans la PR. |
| R-03 | `AppTheme.dark` qui consomme encore `AppColors.amber400` après refonte AppColors mais avant refonte AppTheme → primary visuellement incohérent | Bas | Moyen | Ordre d'implémentation strict (cf. research.md étape 1-9). Refonte `AppTheme` immédiatement après `AppColors`. Tests visuels manuels après chaque étape. |
| R-04 | Hardcodes `AppColors.amber100` dans `list_item.dart` et `recent_transactions_section.dart` font apparaître des fonds d'icône incohérents | Bas | Bas | Différé KKS-240 (RES-006). Audit informatif consigné dans la PR (SC-011). Le visuel reste fonctionnel — inutile de bloquer KKS-237. |
| R-05 | Material 3 `useMaterial3: true` non activé dans `AppTheme` → certains tokens ColorScheme ne se propagent pas | Moyen | Bas | Vérifier au début de l'implémentation. Activer si manquant. Test visuel sur 1 écran. |
| R-06 | Conflit avec `flutter/lib/src/domain/models/app_config.dart` modifié hors scope (vu dans `git status`) | Bas | Bas | Le fichier est hors scope KKS-237. Travailler sur branche dédiée `feature/flutter-tokens-refonte-v5` pour isoler. |

---

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | [research.md](./research.md) | Oui | 8 inconnues techniques résolues (RES-001 à RES-008) |
| Data Model | [data-model.md](./data-model.md) | Oui | 5 entités logiques (classes Dart de tokens) à documenter pour clarifier la structure cible |
| Quickstart | [quickstart.md](./quickstart.md) | Oui | Guide d'implémentation pas à pas pour le développeur |
| Contracts | [contracts.md](./contracts.md) | À générer en `/devflow.contracts` | Pas d'API REST — contracts limités aux signatures Dart publiques |

---

## Hors scope

- Refonte des composants shared (KKS-238 — `SectionHeaderSticky`, `ListGroup`, `EmptyStateWidget`, etc.)
- Refonte des écrans (KKS-240 à KKS-243)
- Suppression effective des `LinearGradient` anti-patterns dans les widgets (annotation `@Deprecated` seulement, suppression réelle dans KKS-240)
- Correction des hardcodes `AppColors.amber100` dans `list_item.dart` et `recent_transactions_section.dart` (différé KKS-238/240)
- Refonte des tokens dashboard spécifiques `--hero-gradient`, `--glass-bg`, `--glass-blur`, `--page-gradient-color`, `--shadow-hero-text` (valeurs nulles en dark v5 — pas de Flutter equivalent à créer)
- Mise à jour de `AppRadius`, `AppSpacing`, `AppDurations` (déjà alignés sur Angular v5)
- Onboarding commercial (KKS-244)
