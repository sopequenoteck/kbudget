# Data Model — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

> **Note** : cette feature ne touche pas la base de données. Le "data model" décrit ici est le **modèle d'objets Dart** des tokens design (classes statiques + ThemeExtension Material 3). Les sections "Migrations" et "Index" sont sans objet.

---

## Entités

### `AppColors` (couche primitive + sémantique)

Classe Dart `final` avec constructeur privé `AppColors._()` exposant exclusivement des `static const`.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| **Primitives — palette gris propriétaire** | | | |
| `gray50` | `Color` | const, `0xFFFAFAFA` | Gris très clair (light bg-tertiary) |
| `gray100` | `Color` | const, `0xFFF5F5F5` | Gris clair (light hover-bg, surface-raised light) |
| `gray200` | `Color` | const, `0xFFE5E5E5` | Border default light |
| `gray300` | `Color` | const, `0xFFD4D4D4` | Border strong light |
| `gray400` | `Color` | const, `0xFFA3A3A3` | Text tertiary light, text secondary dark |
| `gray500` | `Color` | const, `0xFF737373` | Text tertiary dark |
| `gray600` | `Color` | const, `0xFF525252` | Text secondary light |
| `gray700` | `Color` | const, `0xFF1E1E1E` | Surface raised dark, hover-bg dark |
| `gray800` | `Color` | const, `0xFF141414` | Surface default dark |
| `gray900` | `Color` | const, `0xFF0A0A0A` | Background dark, text primary light |
| **Primitives — palette amber Tailwind** | | | |
| `amber50, amber100, ..., amber900` | `Color` | const | Tailwind inchangées (e.g. `amber500 = 0xFFF59E0B`) |
| **Primitives — palette violet Tailwind** | | | |
| `violet400` | `Color` | const, `0xFFA78BFA` | Tailwind |
| `violet500` | `Color` | const, `0xFF8B5CF6` | Tailwind |
| **Primitives — palette indigo Tailwind** | | | |
| `indigo50, ..., indigo900` | `Color` | const | Tailwind (utilisée par secondaryColor) |
| **Primitives — feedback Tailwind** | | | |
| `success, error, warning, info` | `Color` | const | Tailwind brut (`#22c55e`, `#ef4444`, `#eab308`, `#3b82f6`) |
| **Sémantique dark — business (mises à jour)** | | | |
| `incomeDark` | `Color` | const, `0xFF6DC990` | Custom — était `#4ADE80` Tailwind |
| `expenseDark` | `Color` | const, `0xFFD97777` | Custom — était `#F87171` |
| `subscriptionDark` | `Color` | const, `0xFF9580D9` | Custom — était `#A78BFA` |
| `debtOweDark` | `Color` | const, `0xFFD97777` | Custom — alias expenseDark |
| `debtOwedDark` | `Color` | const, `0xFF6DC990` | Custom — alias incomeDark |
| **Sémantique dark — primary** | | | |
| `primaryAmberDark` | `Color` | const, `0xFFE0A820` | Primary custom dark — non dérivé de amber-* palette |
| `primaryAmberHoverDark` | `Color` | const, `0xFFC9952A` | Primary hover dark |
| **Sémantique dark — feedback** | | | |
| `textWarningDark` | `Color` | const, `0xFFD4AD3C` | Custom |
| `textInfoDark` | `Color` | const, `0xFF7AACDB` | Custom |
| **Sémantique dark — interactifs** | | | |
| `primarySubtleDark` | `Color` | const, `0x1AE0A820` (rgba 0.10) | |
| `primaryMutedDark` | `Color` | const, `0x26E0A820` (rgba 0.15) | |
| `primaryBorderDark` | `Color` | const, `0x40E0A820` (rgba 0.25) | |
| `hoverBgDark` | `Color` | const, `gray700` | |
| `hoverSubtleDark` | `Color` | const, `0x0AFFFFFF` (rgba 0.04) | |
| `highlightSubtleDark` | `Color` | const, `0x1AFFFFFF` (rgba 0.10) | |
| `overlayLightDark` | `Color` | const, `0x26FFFFFF` (rgba 0.15) | |
| `focusRingDark` | `Color` | const, `0x80FBBF24` (amber400 alpha 0.5) | |
| `iconCircleBgDark` | `Color` | const, `0x0FFFFFFF` (rgba 0.06) | |
| **Sémantique light — business (existantes)** | | | |
| `incomeLight, expenseLight, subscriptionLight, debtOweLight, debtOwedLight` | `Color` | const | Inchangées — Tailwind green-600/red-600/violet-500 |
| **Sémantique light — feedback** | | | |
| `textWarningLight` | `Color` | const, `0xFFCA8A04` | Yellow-700 Tailwind |
| `textInfoLight` | `Color` | const, `0xFF2563EB` | Blue-600 Tailwind |
| **Sémantique light — interactifs** | | | |
| `primarySubtleLight` | `Color` | const, `0x1AD97706` (rgba 0.10) | amber-600 derived |
| `primaryMutedLight, primaryBorderLight, hoverBgLight, hoverSubtleLight, highlightSubtleLight, overlayLightLight, focusRingLight, iconCircleBgLight` | `Color` | const | Selon `_light.scss` |

**Invariants** :
- Toutes les valeurs sont `static const` immutables.
- Le constructeur est privé (`AppColors._()`) — instanciation interdite.
- Les valeurs hex correspondent exactement aux SCSS Angular v5 (cf. tableau de mapping dans `plan.md`).
- Aucune valeur Tailwind gray résiduelle (FR-005).

---

### `AppTypography`

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| **Tailles existantes** | | | |
| `sizeXs` | `double` | const, `12.0` | |
| `sizeSm` | `double` | const, `14.0` | |
| `sizeMd` | `double` | const, `16.0` | base |
| `sizeLg` | `double` | const, `18.0` | |
| `sizeXl` | `double` | const, `20.0` | |
| `size2xl` | `double` | const, `24.0` | |
| `size3xl` | `double` | const, `30.0` | |
| **Nouvelles tailles** | | | |
| `size2Xs` | `double` | const, `10.0` | NEW — pour labels uppercase |
| `sizeHero` | `double` | const, `36.0` | NEW — montant patrimoine, équivalent `--font-size-hero` |
| **Poids** | | | |
| `regular, medium, semiBold, bold` | `FontWeight` | const | Inchangés |
| **Letter-spacing labels uppercase** | | | |
| `labelLetterSpacingFactor` | `double` | const, `0.05` | NEW — facteur dynamique CSS-equivalent |
| `labelLetterSpacingForSize10` | `double` | const, `0.5` | NEW — pré-calculé pour `size2Xs` |
| `labelLetterSpacingForSize12` | `double` | const, `0.6` | NEW — pré-calculé pour `sizeXs` |
| `labelLetterSpacingForSize14` | `double` | const, `0.7` | NEW — pré-calculé pour `sizeSm` |

**Invariants** :
- `static const` partout, pas de méthodes runtime.
- Le facteur dynamique (`labelLetterSpacingFactor`) est multiplié par la taille de police au moment de l'usage.

---

### `AppShadows`

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `sm` | `List<BoxShadow>` | const | Inchangé — single-layer `(blur=2, offset=(0,1), 0x0D000000)` |
| `md` | `List<BoxShadow>` | const | **REFONTE** — double-layer `[blur=6 spread=-1 offset=(0,4) + blur=4 spread=-2 offset=(0,2)]` |
| `lg` | `List<BoxShadow>` | const | **REFONTE** — double-layer `[blur=15 spread=-3 offset=(0,10) + blur=6 spread=-4 offset=(0,4)]` |
| `coloredPrimaryDark` | `List<BoxShadow>` | const, NEW | Ombre noire `(blur=24, spread=-4, offset=(0,8), color=0x66000000)` |
| `coloredPrimaryLight` | `List<BoxShadow>` | const, NEW | Ombre amber `(blur=24, spread=-4, offset=(0,8), color=0x66F59E0B)` |
| `coloredPrimary(Brightness)` | `List<BoxShadow>` | static, NEW | Helper retournant la constante selon brightness |
| `colored(Color, {alpha})` | `List<BoxShadow>` | static, **DEPRECATED** | Ancienne API conservée mais `@Deprecated` |

**Invariants** :
- Les 5 entrées const exposent des `BoxShadow` immuables.
- Le helper `coloredPrimary` retourne une référence partagée (pas de nouvelle allocation).
- L'ancienne API `colored()` reste fonctionnelle pour compatibilité courte.

---

### `AppThemeExtension` (Material 3 ThemeExtension)

Étend `ThemeExtension<AppThemeExtension>`. 16 propriétés au total après refonte (6 existantes + 10 nouvelles).

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| **Existantes (conservées)** | | | |
| `incomeColor` | `Color` | required | |
| `expenseColor` | `Color` | required | |
| `debtOweColor` | `Color` | required | |
| `debtOwedColor` | `Color` | required | |
| `subscriptionColor` | `Color` | required | |
| `secondaryColor` | `Color` | required | |
| **Nouvelles — feedback** | | | |
| `textWarning` | `Color` | required, NEW | |
| `textInfo` | `Color` | required, NEW | |
| **Nouvelles — interactifs** | | | |
| `primarySubtle` | `Color` | required, NEW | |
| `primaryMuted` | `Color` | required, NEW | |
| `primaryBorder` | `Color` | required, NEW | |
| `hoverSubtle` | `Color` | required, NEW | |
| `highlightSubtle` | `Color` | required, NEW | |
| `overlayLight` | `Color` | required, NEW | |
| `focusRing` | `Color` | required, NEW | |
| `iconCircleBg` | `Color` | required, NEW | |

**Méthodes** :
- `copyWith({...})` — étendu pour les 10 nouvelles propriétés (mécanique).
- `lerp(other, t)` — étendu via `Color.lerp()` natif pour chaque propriété (RES-004).

**Instances statiques** :
- `AppThemeExtension.dark` : utilise les constantes `AppColors.{name}Dark`.
- `AppThemeExtension.light` : utilise les constantes `AppColors.{name}Light`.

**Invariants** :
- Tous les champs sont `final` et `required` (immuabilité).
- `lerp()` ne renvoie jamais `null` pour les propriétés (utilise `!` après `Color.lerp()`).

---

### `AppTheme`

Classe utilitaire exposant deux `static final ThemeData`.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `light` | `ThemeData` | static final | `useMaterial3: true`. `colorScheme.primary = AppColors.amber600`. Surfaces sur palette gris propriétaire light. Inclut `AppThemeExtension.light` dans `extensions:`. |
| `dark` | `ThemeData` | static final | `useMaterial3: true`. `colorScheme.primary = AppColors.primaryAmberDark`. Surfaces sur palette gris propriétaire dark (`gray800` surface, `gray900` background). Inclut `AppThemeExtension.dark` dans `extensions:`. |

**Invariants** :
- Toutes les références `AppColors.amber*` dans `AppTheme.dark` sont remplacées par les constantes sémantiques (`primaryAmberDark`) ou conservées explicitement si pertinent (e.g. `primaryContainer = amber800` Material).
- Le passage light↔dark dynamique fonctionne (test manuel obligatoire).

---

## Relations

```
AppColors (primitives + sémantiques)
    │
    ├──> AppTheme.dark (ThemeData)
    │       └──> consomme primaryAmberDark, gray*, etc. dans colorScheme
    │
    ├──> AppTheme.light (ThemeData)
    │       └──> consomme amber600, gray*, etc. dans colorScheme
    │
    └──> AppThemeExtension.dark/.light (ThemeExtension)
            └──> consomme {name}Dark / {name}Light pour 16 propriétés
                    │
                    └──> Injectée dans AppTheme.dark/.light via extensions:

AppShadows
    │
    └──> Consommé directement par les widgets (pas via theme)

AppTypography
    │
    └──> Consommé directement par les widgets dans TextStyle
```

| Relation | Type | Cardinalité | Contrainte |
|----------|------|-------------|------------|
| `AppColors` → `AppTheme.dark` | dépendance compile-time | 1:N (toutes les couleurs sémantiques dark) | Aucune référence circulaire |
| `AppColors` → `AppTheme.light` | dépendance compile-time | 1:N | Aucune référence circulaire |
| `AppColors` → `AppThemeExtension.dark` | dépendance compile-time | 1:16 | Toutes les propriétés sont des `Color` const |
| `AppColors` → `AppThemeExtension.light` | dépendance compile-time | 1:16 | Idem |
| `AppTheme.{dark,light}` → `AppThemeExtension.{dark,light}` | injection via `extensions:` | 1:1 | L'extension est const, l'injection aussi |
| Widgets (14+) → `AppThemeExtension` | runtime via `Theme.of(context).extension<...>()` | N:1 | Compatible API existante (6 propriétés conservées) |

---

## Contraintes globales

| # | Contrainte | Type | Entités concernées |
|---|-----------|------|-------------------|
| DC-001 | Aucune valeur hex Tailwind gray (`#111827`, `#1F2937`, etc.) résiduelle | Vérification | `AppColors`, `AppTheme` |
| DC-002 | Toutes les valeurs hex correspondent exactement aux SCSS Angular v5 (`_primitives.scss`, `_dark.scss`, `_light.scss`) | Conformité | `AppColors`, `AppTheme`, `AppThemeExtension` |
| DC-003 | `AppThemeExtension` reste compatible API avec les 14+ widgets existants | Backward compat | `AppThemeExtension` |
| DC-004 | `AppShadows` constantes sont `const`-friendly (utilisables dans `BoxDecoration` const) | Compile-time | `AppShadows.coloredPrimaryDark/Light` |
| DC-005 | Aucune nouvelle dépendance externe (`pubspec.yaml` inchangé) | NFR-004 | Toutes |

---

## Migrations

> Pas de migration BDD. Section sans objet pour cette feature.

Les modifications Flutter sont des **modifications de code source** (refonte de constantes statiques + extension de `AppThemeExtension`). Pas de migration de schéma de données.

---

## Index

> Pas d'index BDD. Section sans objet.
