# Feature Specification : Refonte tokens design Flutter (palette propriétaire v5)

**Issue Linear** : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
**Issue parent** : [KKS-236](https://linear.app/kksdev/issue/KKS-236/phase-1-refonte-design-flutter-v5)
**Feature Branch** : `feature/flutter-tokens-refonte-v5`
**Créée** : 2026-05-03
**Mise à jour** : 2026-05-03 (correction valeurs après lecture directe SCSS Angular ; clarify CL-001 à CL-005 résolus ; review-spec WARNING W-01/W-02/W-04 corrigés)
**Statut** : Draft
**Priorité** : High (P2 Linear) — bloquant pour KKS-238 et KKS-240+
**Labels** : Feature
**Input** : Issue Linear KKS-237

---

## Contexte

L'application Flutter k-budget utilise actuellement une palette de tokens design construite à partir des **valeurs Tailwind CSS embarquées** (`gray-900 = #111827`, `gray-800 = #1F2937`, `green-400 = #4ADE80`, `red-400 = #F87171`, `amber-500 = #F59E0B`, etc.).

L'application Angular k-budget a migré en v5 vers une **architecture en deux couches** :

1. **Couche primitive** (`app/src/styles/tokens/_primitives.scss`) — palette de base partiellement réécrite en propriétaire :
   - **Gris** : palette propriétaire neutre (`gray-50 = #fafafa`, `gray-100 = #f5f5f5`, `gray-200 = #e5e5e5`, `gray-300 = #d4d4d4`, `gray-400 = #a3a3a3`, `gray-500 = #737373`, `gray-600 = #525252`, `gray-700 = #1e1e1e`, `gray-800 = #141414`, `gray-900 = #0a0a0a`).
   - **Amber, Indigo, Violet, feedback (success / warning / error / info)** : valeurs Tailwind **conservées** (`amber-500 = #f59e0b`, `violet-500 = #8b5cf6`, etc.).
2. **Couche semantique par thème** (`app/src/styles/themes/_dark.scss` et `_light.scss`) — applique des **valeurs custom** par-dessus les primitives, notamment en dark où la primary devient `#e0a820`, l'income `#6dc990`, l'expense `#d97777`, le subscription `#9580d9` (couleurs custom non dérivées des primitives).

Cette architecture en deux couches DOIT être reproduite côté Flutter :
- `AppColors` = couche primitive (palette gris propriétaire + amber / violet / feedback Tailwind-compatibles)
- `AppTheme.dark` / `AppTheme.light` = couche semantique avec couleurs custom dark
- L'`AppThemeExtension` existant (`flutter/lib/src/theme/app_theme_extension.dart`, déjà consommé par 14+ widgets avec 6 propriétés business) DOIT être étendu — pas remplacé — pour exposer également les tokens semantiques manquants au `ColorScheme` Material standard.

**`docs/design-tokens.md` est obsolète** (valeurs Tailwind partout — ne reflète ni `_primitives.scss` propriétaire ni `_dark.scss`). Décision actée en clarify : marquage obsolète + redirection vers les SCSS comme source de vérité (option B).

Décisions structurantes validées en phase sparring (Phase 0, 2026-05-03) :

- **Périmètre limité aux tokens** : seuls `flutter/lib/src/constants/app_*.dart` et `AppTheme` sont touchés. La propagation visuelle dans les écrans suit dans les étapes ultérieures de Phase 1.
- **Pas de suppression des ombres colorées** : reproduction du pattern Angular = neutralisation par thème (override en dark vers ombre neutre noire).
- **Marquage `@Deprecated`** des gradient anti-patterns Flutter (`PatrimoineCard` notamment) sans suppression effective ici. Côté Angular, le pattern est neutralisé par token thème (`--hero-gradient: none`) ; côté Flutter, il faut un mécanisme équivalent (`ThemeExtension` ou suppression effective dans KKS-240).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Aligner les primitives Flutter sur la palette gris propriétaire (Priorité : P1)

En tant que développeur Flutter, je veux que la palette gris primitive `AppColors.gray*` reflète la palette propriétaire Angular v5, afin que toute couche semantique construite par-dessus soit cohérente cross-stack.

**Why this priority** : Bloquant pour toutes les étapes suivantes de Phase 1. Sans cette refonte, chaque composant shared (KKS-238) et chaque écran refondu (KKS-240+) se construirait sur des valeurs gris Tailwind obsolètes. Le coût de correction post-hoc est exponentiel.

**Independent Test** : Recherche grep sur `flutter/lib/src/constants/` pour vérifier qu'aucune valeur hex Tailwind gray résiduelle n'existe (`#111827`, `#1F2937`, `#374151`, `#4B5563`, `#6B7280`, `#9CA3AF`, `#D1D5DB`, `#E5E7EB`, `#F3F4F6`, `#F9FAFB`).

**Acceptance Scenarios** :

1. **Étant donné** la palette `AppColors.gray*` actuelle utilisant Tailwind, **quand** la refonte est appliquée, **alors** les valeurs correspondent exactement à la palette propriétaire Angular v5 :
   - `gray50 = #fafafa`
   - `gray100 = #f5f5f5`
   - `gray200 = #e5e5e5`
   - `gray300 = #d4d4d4`
   - `gray400 = #a3a3a3`
   - `gray500 = #737373`
   - `gray600 = #525252`
   - `gray700 = #1e1e1e`
   - `gray800 = #141414`
   - `gray900 = #0a0a0a`
2. **Étant donné** un développeur consultant `app_colors.dart`, **quand** il cherche une valeur Tailwind gray résiduelle, **alors** aucune occurrence n'est trouvée.

---

### User Story 2 — Conserver les primitives amber / violet / feedback Tailwind (Priorité : P1)

En tant que mainteneur du design system Flutter, je veux que les primitives `amber-*`, `violet-*` et les couleurs feedback (`success`, `warning`, `error`, `info`) restent alignées sur Tailwind dans `AppColors`, conformément à la décision Angular v5 qui les a conservées dans `_primitives.scss`.

**Why this priority** : Erreur récurrente : croire qu'Angular v5 a migré toutes les couleurs en propriétaire. Faux. Seule la palette gris a été refaite. Aligner Flutter sur Tailwind sur ces palettes est la décision correcte. **Sans cette US, on risque de modifier des valeurs qui sont déjà bonnes** (et casser le light theme qui dépend de ces primitives).

**Independent Test** : Vérifier que les valeurs primitives suivantes restent identiques après la refonte : `amber500 = #f59e0b`, `amber400 = #fbbf24`, `amber600 = #d97706`, `violet500 = #8b5cf6`, `violet400 = #a78bfa`, `success = #22c55e`, `error = #ef4444`, `warning = #eab308`, `info = #3b82f6`.

**Acceptance Scenarios** :

1. **Étant donné** la primitive `AppColors.amber500 = #f59e0b` actuelle, **quand** la refonte est appliquée, **alors** sa valeur reste `#f59e0b` (Tailwind amber-500).
2. **Étant donné** la primitive `AppColors.violet500 = #8b5cf6`, **quand** la refonte est appliquée, **alors** sa valeur reste `#8b5cf6` (Tailwind violet-500).
3. **Étant donné** les feedback dark actuels `incomeDark = #4ADE80`, `expenseDark = #F87171`, **quand** la refonte est appliquée, **alors** ils peuvent être renommés ou conservés en primitive Tailwind (`#4ade80`, `#f87171`) — la valeur custom dark (`#6dc990`, `#d97777`) est portée par la couche semantique, pas par les primitives (cf. US3).

---

### User Story 3 — Définir la couche semantique dark avec couleurs custom (Priorité : P1)

En tant que développeur Flutter, je veux qu'`AppTheme.dark` produise les couleurs semantiques custom Angular v5 (primary `#e0a820`, income `#6dc990`, expense `#d97777`, subscription `#9580d9`, etc.) afin que tout widget consommant `Theme.of(context).colorScheme.primary` ou un `AppThemeExtension` reçoive la couleur correcte.

**Why this priority** : C'est ici que se joue la cohérence visuelle réelle avec Angular dark. Sans cette US, même avec une palette primitive correcte, les écrans Flutter affichent toujours `amber-500 = #f59e0b` en primary au lieu du custom `#e0a820` plus doux.

**Independent Test** : Sur un écran arbitraire en dark, vérifier que `Theme.of(context).colorScheme.primary` retourne `Color(0xFFE0A820)`. Vérifier qu'un widget consommant le `AppThemeExtension.incomeColor` reçoit `Color(0xFF6DC990)`.

**Acceptance Scenarios** :

1. **Étant donné** `AppTheme.dark` actuel, **quand** la refonte est appliquée, **alors** `colorScheme.primary` vaut `#e0a820`, `colorScheme.onPrimary` (primary-contrast) vaut `gray900` (`#0a0a0a`), `colorScheme.surface` vaut `gray800` (`#141414`), `colorScheme.background` vaut `gray900` (`#0a0a0a`).
2. **Étant donné** l'`AppThemeExtension` existant étendu avec les nouveaux tokens, **quand** il est consommé en dark, **alors** `incomeColor = #6dc990`, `expenseColor = #d97777`, `subscriptionColor = #9580d9`, `debtOweColor = #d97777`, `debtOwedColor = #6dc990` (les 6 propriétés existantes conservent leurs noms ; les valeurs sont mises à jour si nécessaire).
3. **Étant donné** les feedback semantiques dark, **quand** la refonte est appliquée, **alors** `textSuccess = #6dc990`, `textError = #d97777`, `textWarning = #d4ad3c`, `textInfo = #7aacdb` sont exposés (via theme ou ThemeExtension).
4. **Étant donné** le light theme, **quand** la refonte est appliquée, **alors** `colorScheme.primary` vaut `amber-600 = #d97706`, les business tokens valent `incomeColor = #16a34a`, `expenseColor = #dc2626`, `subscriptionColor = #8b5cf6`, les feedback valent `textWarning = #ca8a04` et `textInfo = #2563eb`, les interactifs valent `hoverBg = gray-100 = #f5f5f5` et `iconCircleBg = rgba(0, 0, 0, 0.04)`. Le light reste partiellement Tailwind-compatible, conforme à `_light.scss`.

---

### User Story 4 — Ajouter les tokens manquants (interactifs, états, dashboard, hero) (Priorité : P2)

En tant que développeur Flutter, je veux disposer des tokens manquants identifiés dans `_dark.scss` (`primary-subtle`, `primary-muted`, `primary-border`, `hover-bg`, `hover-subtle`, `highlight-subtle`, `overlay-light`, `focus-ring`, `icon-circle-bg`, `font-size-hero`, `font-size-2xs`, etc.) afin de pouvoir construire les composants shared (KKS-238) et écrans (KKS-240+) sans réinventer ces valeurs.

**Why this priority** : Sans ces tokens, les composants shared (Étape 2) ne peuvent pas être construits proprement et risqueraient de hardcoder des valeurs `withValues(alpha: 0.06)` ou des `Color.fromRGBO(...)` répétés.

**Independent Test** : Vérifier la présence dans le code source d'au minimum les tokens listés ci-dessous, documentés via `///`.

**Acceptance Scenarios** :

1. **Étant donné** `AppTypography` ne disposant pas de taille `2xs`, **quand** la refonte est appliquée, **alors** `AppTypography.size2Xs = 10.0` et `AppTypography.sizeHero = 36.0` sont définis avec un commentaire `///`.
2. **Étant donné** les états interactifs non tokenisés, **quand** la refonte est appliquée, **alors** les tokens semantiques suivants sont définis (via extension de l'`AppThemeExtension` existant ou via `AppTheme.dark` / `AppTheme.light` selon nature du token) :
   - `primarySubtle` (rgba primary 0.10)
   - `primaryMuted` (rgba primary 0.15)
   - `primaryBorder` (rgba primary 0.25)
   - `hoverBg` (= surface-raised en dark, gray-100 en light)
   - `hoverSubtle` (rgba blanc 0.04 en dark, rgba noir 0.04 en light)
   - `highlightSubtle` (rgba blanc 0.10 en dark, rgba noir 0.06 en light)
   - `overlayLight` (rgba blanc 0.15 en dark, rgba noir 0.10 en light)
   - `focusRing` (rgba amber-400 0.5 en dark, rgba amber-500 0.5 en light)
   - `iconCircleBg` (rgba blanc 0.06 en dark, rgba noir 0.04 en light)
3. **Étant donné** le pattern hero (PatrimoineCard, dashboard), **quand** la refonte est appliquée, **alors** un token `AppTypography.sizeHero = 36.0` est exposé pour le montant patrimoine.
4. **Étant donné** les labels uppercase utilisés dans le hero (letter-spacing CSS `0.05em`), **quand** la refonte est appliquée, **alors** une convention de letter-spacing pour labels uppercase est définie côté Flutter (cf. NC-3).

---

### User Story 5 — Aligner AppShadows en neutralisant les ombres colorées par thème (Priorité : P2)

En tant que mainteneur du design system Flutter, je veux que les ombres `md` / `lg` adoptent le pattern double-layer Angular v5, et que l'ombre `colored-primary` soit **neutralisée en dark** (ombre noire) tout en restant fonctionnelle en light, conformément à `_dark.scss` qui override `--shadow-colored-primary` à `rgb(0 0 0 / 0.4)`.

**Why this priority** : DESIGN.md v5 dark interdit les ombres colorées, mais en light théoriquement OK. Le pattern Angular = neutralisation par thème. Le pattern Flutter doit reproduire ça (helper qui retourne une ombre différente selon le brightness du thème), pas suppression brute.

**Independent Test** : `AppShadows.coloredPrimary(brightness: dark)` retourne une `BoxShadow` noire (alpha 102). `AppShadows.md` retourne une `BoxShadow[]` à deux entrées.

**Acceptance Scenarios** :

1. **Étant donné** `AppShadows.md` actuel produisant une `BoxShadow` simple, **quand** la refonte est appliquée, **alors** il produit `[BoxShadow(blur=6, offset=(0,4), spread=-1, alpha 0x1A) + BoxShadow(blur=4, offset=(0,2), spread=-2, alpha 0x1A)]`.
2. **Étant donné** `AppShadows.lg` actuel, **quand** la refonte est appliquée, **alors** il produit `[BoxShadow(blur=15, offset=(0,10), spread=-3, alpha 0x1A) + BoxShadow(blur=6, offset=(0,4), spread=-4, alpha 0x1A)]`.
3. **Étant donné** `AppShadows.sm`, **quand** la refonte est appliquée, **alors** il reste inchangé (déjà aligné).
4. **Étant donné** `AppShadows.colored(Color, alpha)` actuel, **quand** la refonte est appliquée, **alors** un helper `AppShadows.coloredPrimary(BuildContext)` est introduit qui retourne une ombre **noire** en dark (`alpha 0x66`, `Color(0xFF000000)`) et une ombre **colorée amber** en light (`Color(0xFFF59E0B)` avec `alpha 0x66`). L'ancienne API `AppShadows.colored(Color, alpha)` peut rester pour compatibilité courte mais est marquée `@Deprecated` avec recommandation de migrer vers `coloredPrimary`.

---

### User Story 6 — Adapter AppTheme et marquer les anti-patterns (Priorité : P2)

En tant que mainteneur de l'app Flutter, je veux que `AppTheme.dark` et `AppTheme.light` consomment la nouvelle palette primitive `AppColors` + le `AppThemeExtension` business, et que les widgets utilisant des gradient décoratifs anti-patterns soient marqués `@Deprecated` afin de signaler la prochaine étape de refonte (KKS-240).

**Why this priority** : Sans adaptation `AppTheme`, les `Theme.of(context).colorScheme.surface` continuent de retourner les valeurs Tailwind. Côté Angular, le gradient PatrimoineCard est neutralisé via `--hero-gradient: none`. Côté Flutter, ce mécanisme indirect n'existe pas — il faut soit ajouter le gradient dans le theme (ThemeExtension), soit marquer `@Deprecated` les widgets concernés pour signaler la refonte ultérieure.

**Independent Test** : Sur un écran arbitraire, vérifier que `Theme.of(context).colorScheme.surface` retourne `#141414` en dark. Vérifier que `PatrimoineCard` (`LinearGradient(amber900→indigo900)`) affiche un avertissement `@Deprecated` dans l'IDE.

**Acceptance Scenarios** :

1. **Étant donné** `AppTheme.dark` actuel utilisant `gray-900` Tailwind, **quand** la refonte est appliquée, **alors** son `colorScheme.background` vaut `#0a0a0a`, `colorScheme.surface` vaut `#141414`, `colorScheme.surfaceContainerHighest` vaut `#1e1e1e` (gray-700 propriétaire).
2. **Étant donné** un widget construisant un `LinearGradient(amber900→indigo900)`, **quand** la refonte est appliquée, **alors** ce widget est marqué `@Deprecated('Gradient décoratif interdit en dark v5 — voir KKS-240 pour la refonte hero flat. Token Angular équivalent : --hero-gradient: none.')`.
3. **Étant donné** `AppTheme.light` actuel, **quand** la refonte est appliquée, **alors** sa palette est mise à jour de manière cohérente avec `_light.scss` Angular (primary `amber-600`, income `green-600`, expense `red-600`, etc.).
4. **Étant donné** un développeur souhaitant accéder aux tokens business depuis un widget, **quand** il appelle `Theme.of(context).extension<AppThemeExtension>()`, **alors** il reçoit l'instance avec les valeurs correctes selon le brightness courant.

---

### User Story 7 — Mettre à jour ou déprécier `docs/design-tokens.md` (Priorité : P3)

En tant que contributeur (humain ou agent IA), je veux que `docs/design-tokens.md` soit soit à jour avec la palette propriétaire actuelle, soit explicitement marqué obsolète avec redirection vers la vraie source de vérité (`app/src/styles/tokens/_primitives.scss` + `app/src/styles/themes/_dark.scss` / `_light.scss`).

**Why this priority** : Faible immédiat (le fichier ne casse rien) mais bloquant pour la maintenabilité long-terme. Sans cette US, le prochain contributeur lit `docs/design-tokens.md` (qui se proclame "Source de vérité unique") et fait les mauvais choix — comme moi à la première rédaction de cette spec.

**Independent Test** : Lire `docs/design-tokens.md` ; soit ses valeurs gris correspondent à la palette propriétaire (`#0a0a0a` etc.), soit un avertissement clair en entête redirige vers les fichiers SCSS / DESIGN.md.

**Acceptance Scenarios** :

1. **Étant donné** `docs/design-tokens.md` actuel avec valeurs Tailwind, **quand** la refonte est appliquée, **alors** soit (A) les valeurs sont mises à jour pour refléter `_primitives.scss` + tokens semantiques dark/light, soit (B) un avertissement `> ⚠️ OBSOLÈTE — voir app/src/styles/tokens/ et app/src/styles/themes/ pour la source de vérité actuelle. Ce fichier sera supprimé en v3.0.x.` est ajouté en entête.
2. **Étant donné** la décision A ou B prise, **quand** un nouveau contributeur consulte la doc, **alors** il est correctement orienté vers les valeurs réelles.

---

### Edge Cases

- **Widgets hardcodant des valeurs Tailwind hors `AppColors`** : identifier les usages via grep mais **ne pas corriger ici**. Documenter dans la PR pour suite dans KKS-240+.
- **Tests existants validant des couleurs précises** : adapter pour référencer les nouveaux tokens, pas les valeurs hex.
- **Light theme** : la cohérence light est conservée mais l'effort visuel se concentre sur le dark. Light reste partiellement Tailwind-compatible (cf. `_light.scss`).
- **Avertissements `@Deprecated` dans tests** : ignorer ou supprimer les warnings dans les tests des widgets concernés (sinon les tests cassent).
- **Theme switching dynamique** : vérifier que le passage light↔dark continue de fonctionner après la refonte, en particulier pour les `AppThemeExtension` et `AppShadows.coloredPrimary` qui dépendent du brightness.
- **Disponibilité de `BuildContext`** : certains helpers Flutter (`AppShadows.coloredPrimary(context)`) nécessitent un context. Veiller à fournir aussi des constantes statiques quand le brightness peut être déduit (e.g. `AppShadows.coloredPrimaryDark`).

---

## Requirements *(mandatory)*

### Functional Requirements

#### Couche primitive (AppColors)

- **FR-001** : `AppColors.gray*` DOIT adopter la palette propriétaire Angular v5 :
  - `gray50 = #fafafa`, `gray100 = #f5f5f5`, `gray200 = #e5e5e5`, `gray300 = #d4d4d4`, `gray400 = #a3a3a3`, `gray500 = #737373`, `gray600 = #525252`, `gray700 = #1e1e1e`, `gray800 = #141414`, `gray900 = #0a0a0a`.
- **FR-002** : Les primitives `AppColors.amber*` (50→900) DOIVENT rester sur les valeurs Tailwind (`amber-500 = #f59e0b`, `amber-400 = #fbbf24`, `amber-600 = #d97706`, etc.), conformément à `_primitives.scss`.
- **FR-003** : Les primitives `AppColors.violet*` DOIVENT rester sur les valeurs Tailwind (`violet-400 = #a78bfa`, `violet-500 = #8b5cf6`).
- **FR-004** : Les primitives feedback (`success = #22c55e`, `warning = #eab308`, `error = #ef4444`, `info = #3b82f6`) DOIVENT rester Tailwind.
- **FR-005** : Aucun fichier dans `flutter/lib/src/constants/` NE DOIT contenir de valeur hex de l'ancienne palette gris Tailwind (`#111827`, `#1F2937`, `#374151`, `#4B5563`, `#6B7280`, `#9CA3AF`, `#D1D5DB`, `#E5E7EB`, `#F3F4F6`, `#F9FAFB`).

#### Couche semantique dark (AppTheme.dark + AppThemeExtension)

- **FR-006** : `AppTheme.dark.colorScheme.primary` DOIT valoir `#e0a820` (couleur custom dark, **non** dérivée de la primitive amber).
- **FR-007** : `AppTheme.dark.colorScheme.onPrimary` DOIT valoir `#0a0a0a` (gray-900 propriétaire).
- **FR-008** : `AppTheme.dark.colorScheme.surface` DOIT valoir `#141414` (gray-800), `surfaceContainerHighest` DOIT valoir `#1e1e1e` (gray-700), `background` DOIT valoir `#0a0a0a` (gray-900).
- **FR-009** : L'`AppThemeExtension` existant (`flutter/lib/src/theme/app_theme_extension.dart`) DOIT être étendu — pas remplacé — pour conserver les 6 propriétés business actuelles (`incomeColor`, `expenseColor`, `debtOweColor`, `debtOwedColor`, `subscriptionColor`, `secondaryColor`) avec les valeurs custom dark mises à jour si nécessaire :
  - `incomeColor = #6dc990` (dark) / `#16a34a` (light)
  - `expenseColor = #d97777` (dark) / `#dc2626` (light)
  - `debtOweColor = #d97777` (dark) / `#dc2626` (light)
  - `debtOwedColor = #6dc990` (dark) / `#16a34a` (light)
  - `subscriptionColor = #9580d9` (dark) / `#8b5cf6` (light)
  - `secondaryColor` : valeur conservée selon convention actuelle
- **FR-010** : L'`AppThemeExtension` existant DOIT être étendu pour exposer les tokens feedback semantiques manquants au `ColorScheme` Material avec les valeurs dark :
  - `textSuccess = #6dc990`
  - `textError = #d97777`
  - `textWarning = #d4ad3c`
  - `textInfo = #7aacdb`
- **FR-011** : L'`AppThemeExtension` existant DOIT être étendu pour exposer les tokens interactifs avec les valeurs dark :
  - `primarySubtle = rgba(224, 168, 32, 0.10)`
  - `primaryMuted = rgba(224, 168, 32, 0.15)`
  - `primaryBorder = rgba(224, 168, 32, 0.25)`
  - `hoverBg = gray-700`
  - `hoverSubtle = rgba(255, 255, 255, 0.04)`
  - `highlightSubtle = rgba(255, 255, 255, 0.10)`
  - `overlayLight = rgba(255, 255, 255, 0.15)`
  - `focusRing = rgba(amber-400, 0.5)` (= `rgba(251, 191, 36, 0.5)`)
  - `iconCircleBg = rgba(255, 255, 255, 0.06)`

#### Couche semantique light (AppTheme.light + AppThemeExtension)

- **FR-012a** : `AppTheme.light.colorScheme.primary` DOIT valoir `#d97706` (amber-600), `colorScheme.onPrimary` DOIT valoir `#ffffff`, `colorScheme.surface` DOIT valoir `#ffffff` (blanc), `colorScheme.surfaceContainerHighest` DOIT valoir `#f5f5f5` (gray-100 propriétaire), `colorScheme.background` DOIT valoir `#f0f0f0` (conforme `_light.scss` `--bg-primary`). Light reste partiellement Tailwind-compatible.
- **FR-012b** : Les tokens business light de l'`AppThemeExtension` étendu DOIVENT valoir :
  - `incomeColor = #16a34a` (green-600)
  - `expenseColor = #dc2626` (red-600)
  - `debtOweColor = #dc2626` (red-600)
  - `debtOwedColor = #16a34a` (green-600)
  - `subscriptionColor = #8b5cf6` (violet-500)
- **FR-012c** : Les tokens feedback light DOIVENT valoir :
  - `textSuccess = #16a34a` (green-600)
  - `textError = #dc2626` (red-600)
  - `textWarning = #ca8a04` (yellow-700 Tailwind, conforme `_light.scss`)
  - `textInfo = #2563eb` (blue-600)
- **FR-012d** : Les tokens interactifs light DOIVENT valoir :
  - `primarySubtle = rgba(217, 119, 6, 0.10)` (amber-600 derived)
  - `primaryMuted = rgba(217, 119, 6, 0.15)`
  - `primaryBorder = rgba(217, 119, 6, 0.25)`
  - `hoverBg = #f5f5f5` (gray-100 propriétaire)
  - `hoverSubtle = rgba(0, 0, 0, 0.04)`
  - `highlightSubtle = rgba(0, 0, 0, 0.06)`
  - `overlayLight = rgba(0, 0, 0, 0.10)`
  - `focusRing = rgba(245, 158, 11, 0.5)` (amber-500 derived)
  - `iconCircleBg = rgba(0, 0, 0, 0.04)`

#### Typographie

- **FR-013** : `AppTypography.size2Xs` DOIT être ajouté avec valeur `10.0`.
- **FR-014** : `AppTypography.sizeHero` DOIT être ajouté avec valeur `36.0` (équivalent `--font-size-hero: 2.25rem`).
- **FR-015** : Une convention hybride de letter-spacing pour labels uppercase DOIT être définie dans `AppTypography` :
  - **Facteur dynamique** : `AppTypography.labelLetterSpacingFactor = 0.05` (équivalent CSS `0.05em`, à appliquer dynamiquement = `fontSize * factor`)
  - **Constantes pré-calculées** pour usages statiques en `TextStyle` constants : `labelLetterSpacingForSize10 = 0.5`, `labelLetterSpacingForSize12 = 0.6`, `labelLetterSpacingForSize14 = 0.7`

#### Ombres (AppShadows)

- **FR-016** : `AppShadows.md` DOIT produire un double-layer (`BoxShadow(blur=6, offset=(0,4), spread=-1, color=0x1A000000)` + `BoxShadow(blur=4, offset=(0,2), spread=-2, color=0x1A000000)`).
- **FR-017** : `AppShadows.lg` DOIT produire un double-layer (`BoxShadow(blur=15, offset=(0,10), spread=-3, color=0x1A000000)` + `BoxShadow(blur=6, offset=(0,4), spread=-4, color=0x1A000000)`).
- **FR-018** : `AppShadows.coloredPrimary(context)` ou helper équivalent DOIT être introduit, retournant une ombre **neutre noire** (`Color(0xFF000000)`, alpha `0x66` = `0.4`) en dark et une ombre **colorée amber** (`Color(0xFFF59E0B)`, alpha `0x66` = `0.4`) en light. Conforme exact à `_primitives.scss` (`$shadow-colored-primary: 0 8px 24px -4px rgb(245 158 11 / 0.4)`) et `_dark.scss` (override `--shadow-colored-primary: 0 8px 24px -4px rgb(0 0 0 / 0.4)`).
- **FR-019** : L'ancienne API `AppShadows.colored(Color, {alpha})` peut être conservée mais marquée `@Deprecated` avec recommandation de migrer vers `coloredPrimary`.

#### AppTheme et anti-patterns

- **FR-020** : `AppTheme.dark` et `AppTheme.light` DOIVENT consommer les `AppColors` mis à jour ainsi que le `AppThemeExtension` business.
- **FR-021** : Tout widget utilisant un `LinearGradient` décoratif anti-pattern (notamment `PatrimoineCard` avec `amber900→indigo900`) DOIT être marqué `@Deprecated` pour signaler la suppression ultérieure dans KKS-240.
- **FR-022** : Chaque nouveau token introduit DOIT être documenté inline via commentaire Dart `///`.

#### Documentation

- **FR-023** : `docs/design-tokens.md` DOIT être marqué obsolète en entête avec un avertissement explicite redirigeant vers les sources de vérité actuelles (`app/src/styles/tokens/_primitives.scss`, `app/src/styles/themes/_dark.scss`, `app/src/styles/themes/_light.scss`, `DESIGN.md`). Le contenu détaillé du fichier n'a pas vocation à être maintenu — il devient un pointeur. Format suggéré de l'avertissement : `> ⚠️ OBSOLÈTE — Ce document n'est plus maintenu. Sources de vérité actuelles : (1) primitives → app/src/styles/tokens/_primitives.scss, (2) tokens semantiques par thème → app/src/styles/themes/_dark.scss et _light.scss, (3) principes design → DESIGN.md, (4) Flutter → flutter/lib/src/constants/ et flutter/lib/src/theme/.`

### Non-Functional Requirements

- **NFR-001** : L'app Flutter DOIT continuer à compiler sans erreur après la refonte (`flutter analyze` propre, warnings `@Deprecated` autorisés).
- **NFR-002** : Tous les tests Flutter existants (`flutter test`) DOIVENT passer après la refonte. Les tests qui validaient des valeurs hex précises DOIVENT être adaptés pour référencer les tokens.
- **NFR-003** : Les performances de rendu NE DOIVENT PAS se dégrader (pas de surcoût de calcul de couleurs ni de double-rebuild des thèmes).
- **NFR-004** : La refonte NE DOIT PAS introduire de dépendance externe nouvelle (`pubspec.yaml` inchangé).
- **NFR-005** : La refonte DOIT respecter la Constitution v3.0.0 (Local-First, Mobile-First, Testabilité, Trajectoire B).

### Key Entities

- **AppColors** (`flutter/lib/src/constants/app_colors.dart`) — **couche primitive**. Palette gris propriétaire + amber/violet/indigo/feedback Tailwind-compatibles. Ne contient PAS de couleurs custom dark (qui appartiennent à la couche semantique).
- **AppTypography** (`flutter/lib/src/constants/app_typography.dart`) — tailles `2xs` → `3xl` + `hero`, poids, letter-spacing labels.
- **AppShadows** (`flutter/lib/src/constants/app_shadows.dart`) — `sm`, `md` (double-layer), `lg` (double-layer), `coloredPrimary(context)` brightness-aware.
- **AppTheme** (`flutter/lib/src/theme/app_theme.dart`) — `ThemeData.light` et `ThemeData.dark` consolidés sur `AppColors` + `AppThemeExtension` business.
- **AppThemeExtension** (nouveau ou existant) — `ThemeExtension<T>` Flutter qui expose les tokens business (income/expense/subscription/debt-owe/debt-owed) + tokens semantiques manquants au `ColorScheme` Material standard (textWarning, textInfo, primarySubtle, primaryMuted, primaryBorder, hoverSubtle, highlightSubtle, overlayLight, iconCircleBg).
- **AppRadius**, **AppSpacing**, **AppDurations** — déjà alignés, **non modifiés** par cette feature.

---

## Constraints & Dependencies

### Contraintes

- **Constitution v3.0.0** : Principe I (Local-First — aucune dépendance réseau), Principe IV (Mobile-First UX — interactions ≤ 30s), Principe V (Testabilité), Trajectoire B (Flutter standalone commercial).
- **Source de vérité tokens Angular** : `app/src/styles/tokens/_primitives.scss` (couche 1) + `app/src/styles/themes/_dark.scss` et `_light.scss` (couche 2). DESIGN.md pour les principes de design. **`docs/design-tokens.md` est obsolète et ne doit PAS être consulté comme référence**.
- **Périmètre fermé** : refonte limitée aux fichiers de tokens et au theme. La propagation visuelle dans les écrans est explicitement hors périmètre.

### Dépendances

- **Bloque** : KKS-238, KKS-239, KKS-240, KKS-241, KKS-242, KKS-243, KKS-244.
- **Bloqué par** : aucune dépendance préalable. Cette étape peut démarrer immédiatement.

### Hors périmètre

- Refonte des composants shared (Étape 2 / KKS-238).
- Refonte des écrans (Étapes 4-7 / KKS-240 à KKS-243).
- Suppression effective des gradient anti-patterns dans les widgets (Étape 4 / KKS-240).
- Onboarding commercial (Étape 8 / KKS-244).
- Ajustements `AppRadius`, `AppSpacing`, `AppDurations` (déjà alignés).
- Refonte des tokens dashboard spécifiques `--hero-gradient`, `--glass-bg`, `--glass-blur`, `--page-gradient-color`, `--shadow-hero-text`, `--nav-border-top` qui ont **valeur `none` / `transparent` / `0px` en dark v5** : leur Flutter equivalent est implicite (pas de gradient, pas de glass, pas de blur). Pas de token Flutter spécifique à créer pour ces valeurs nulles.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : Audit grep sur `flutter/lib/src/constants/` ne renvoie aucune valeur hex Tailwind gray résiduelle. Vérification : `grep -E '#(111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/constants/` retourne 0 ligne.
- **SC-002** : Audit grep confirme la présence des nouvelles valeurs gris propriétaires : `grep -E '#(0a0a0a|141414|1e1e1e|525252|737373|a3a3a3|d4d4d4|e5e5e5|f5f5f5|fafafa)' flutter/lib/src/constants/app_colors.dart` retourne au minimum 10 lignes (une par nuance).
- **SC-003** : `flutter analyze` retourne 0 erreur (warnings `@Deprecated` autorisés sur les widgets gradient et sur `AppShadows.colored`).
- **SC-004** : `flutter test` passe à 100% sur l'ensemble des tests existants après adaptation.
- **SC-005** : `AppTheme.dark.colorScheme.primary` retourne `Color(0xFFE0A820)` en dark et `Color(0xFFD97706)` en light.
- **SC-006** : `Theme.of(context).extension<AppThemeExtension>()!.incomeColor` retourne `Color(0xFF6DC990)` en dark et `Color(0xFF16A34A)` en light.
- **SC-007** : `AppShadows.coloredPrimary(context)` retourne une ombre noire (`Color(0xFF000000)`) en dark et une ombre amber (`Color(0xFFF59E0B)`) en light.
- **SC-008** : Au minimum 12 nouveaux tokens documentés via `///` sont introduits : `AppTypography.size2Xs`, `AppTypography.sizeHero`, `primarySubtle`, `primaryMuted`, `primaryBorder`, `hoverSubtle`, `highlightSubtle`, `overlayLight`, `focusRing`, `iconCircleBg`, `textWarning`, `textInfo`.
- **SC-009** : Au moins 1 widget gradient anti-pattern (`PatrimoineCard`) est marqué `@Deprecated` avec message explicite.
- **SC-010** : `docs/design-tokens.md` porte un avertissement `OBSOLÈTE` clair en entête redirigeant vers les fichiers SCSS et DESIGN.md.
- **SC-011** : Audit informatif des hardcodes Tailwind hors `AppColors` exécuté pendant l'implémentation : `grep -E '#(F59E0B|D97706|FBBF24|FCD34D|4ADE80|F87171|8B5CF6|A78BFA|111827|1F2937|374151|4B5563|6B7280|9CA3AF|D1D5DB|E5E7EB|F3F4F6|F9FAFB)' flutter/lib/src/features/` retourne un comptage qui est consigné dans la PR. Les corrections relèvent de KKS-240+, pas bloquant pour KKS-237.

---

## Assumptions

- **A1** : Les écrans Flutter peuvent paraître désalignés visuellement après cette étape — c'est attendu. L'alignement écran par écran suit dans KKS-240 à KKS-243.
- **A2** : Les fichiers `AppRadius`, `AppSpacing`, `AppDurations` sont alignés sur Angular v5 et ne nécessitent aucune modification. Vérifié par lecture directe `_primitives.scss` du 2026-05-03.
- **A3** : Aucun widget ne consomme directement les valeurs hex Tailwind hors des tokens — toutes les couleurs passent par `AppColors`. Si fausse, un grep sur `flutter/lib/src/` révélera des hardcodes à corriger dans KKS-240+.
- **A4** : Le tooling Flutter (`flutter analyze`, `flutter test`) est fonctionnel. Si non, ajouter une étape de validation manuelle.
- **A5** : Le light theme reste partiellement Tailwind-compatible (primary `amber-600`, income `green-600`, etc.) conformément à `_light.scss` Angular. **Pas de refonte light pixel-perfect requise.**
- **A6** : `app/src/styles/tokens/_primitives.scss` + `app/src/styles/themes/_dark.scss` + `_light.scss` sont la source de vérité tokens Angular au 2026-05-03. Lecture directe effectuée.
- **A7** : Flutter peut implémenter les tokens business via `ThemeExtension<T>` (mécanisme natif Flutter Material 3). **Validé** via lecture directe de `flutter/lib/src/theme/app_theme_extension.dart` au 2026-05-03 — l'extension est en production avec 6 propriétés et consommée dans 14+ widgets. Mécanisme stable depuis Flutter 3.10+, projet utilise Flutter ≥ 3.27.

---

## Open Questions

> Toutes les questions ouvertes ont été résolues lors de la session `/devflow.clarify` du 2026-05-03. Voir [`clarify-log.md`](./clarify-log.md) pour le détail des décisions et leur justification.
