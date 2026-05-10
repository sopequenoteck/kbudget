# Research — KKS-239 : BottomSheet4RowsWidget composable

> Date : 2026-05-10
> Issue : KKS-239
> Spec : [spec.md](./spec.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Layout Flutter | Comment structurer Column + footer pinned dans `showModalBottomSheet(isScrollControlled: true)` avec clavier visible ? | Haute |
| RES-002 | Animation | `AnimatedSize` : un seul `duration` ou enter/leave asymétrique (200ms/150ms Angular) ? | Moyenne |
| RES-003 | Tokens | Valeurs exactes de `errorContainer` à ajouter dans `app_theme.dart` (prérequis FR-009) | Haute |
| RES-004 | Composant | `_BSheetActionPill` : `InkWell + Container` ou `OutlinedButton` ou `TextButton` ? | Moyenne |
| RES-005 | UX pressed | État pressed de `BSheetSubmitVariant.danger` — résolution de W-002 | Basse |

---

## Décisions techniques

### RES-001 — Layout Column avec footer pinned + gestion clavier

- **Contexte** : Le widget doit exposer 4 rows dont la Row 4 (footer) est **toujours visible**, même quand les rows 1-3 et la zone expand débordent la hauteur de l'écran. `AppModal` actuel utilise `ConstrainedBox(maxHeight: 90vh) + Column(mainAxisSize.min) + Flexible(SingleChildScrollView)` — ce pattern ne supporte **pas** un footer pinned car le `Flexible` absorbe tout le contenu.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `Column { Expanded(SingleChildScrollView), footer }` | Footer toujours visible, idiomatique Flutter, `Expanded` absorbe le scroll | Nécessite `isScrollControlled: true` côté appelant (déjà documenté dans spec NFR-007) | ★★★ |
| B — `DraggableScrollableSheet` avec footer en overlay positionné | Plus proche d'un "vrai" bottom sheet draggable | Complexité élevée, gestion du scroll compliquée pour l'expand, hors périmètre | ★ |
| C — `Column(mainAxisSize.min)` sans Expanded | Simple, pas de footer pinned forcé | Footer scroll avec le contenu, Row 4 peut disparaître sur sheet long (Subscription + expand) | ★ |

- **Décision** : Option A — `Column { Expanded(child: SingleChildScrollView(child: Column { Row1, Row2, notePreview?, Row3, AnimatedSize(expand) })), Row4 }`.

- **Rationale** : L'option A est le pattern Flutter canonique pour un layout avec header/body scrollable/footer fixe. Elle est cohérente avec le pattern de `ConstrainedBox(maxHeight: 0.9)` de `AppModal` (même appelant, même `isScrollControlled: true`). La gestion du clavier est déléguée à l'appelant via `Padding(EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))` — documenté dans la `///` du widget (alignement NFR-007 et NFR-006 dans la spec).

- **Alternatives rejetées** : B — complexité non justifiée par la spec (YAGNI). C — non conforme au cas Subscription+expand (sheet long).

- **Impact sur le plan** : La tâche d'implémentation du widget doit inclure : (1) la structure `Expanded + SingleChildScrollView`, (2) `SafeArea(bottom: false)` pour éviter le padding iOS bas sur le contenu scrollable (le footer gère son propre padding), (3) documenter l'appel `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)` dans la `///` du widget.

---

### RES-002 — AnimatedSize : duration symétrique vs asymétrique

- **Contexte** : La spec (FR-003) spécifie `AppDurations.normal` (200 ms) comme durée, aligné sur l'animation Angular `expandCollapse` (200ms easeOut à l'ouverture / 150ms easeIn à la fermeture). `AnimatedSize` Flutter n'expose qu'un seul `duration` — pas de durée séparée enter/leave. Le constat I-007 (review) avait identifié cette contrainte comme un point à arbitrer.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `AnimatedSize(duration: normal)` symétrique 200ms | Simple, pattern déjà utilisé dans `app_form_field.dart`, `select_picker.dart`, `emoji_input.dart` (3 occurrences) — parfaitement aligné sur les patterns existants | Légère différence visuelle vs Angular (150ms leave vs 200ms) — imperceptible | ★★★ |
| B — `AnimationController` custom + `SizeTransition` | Durées asymétriques exactes (200ms/150ms) | Complexité élevée, `StatefulWidget` requis pour le squelette, brise FR-001 (`StatelessWidget`) | ✗ |
| C — `AnimatedSwitcher` | Utile pour cross-fade de contenu | N'anime pas la hauteur — l'ancienne section doit disparaître avant que la nouvelle apparaisse (layout saccadé) | ★ |

- **Décision** : Option A — `AnimatedSize(duration: AppDurations.normal, curve: AppDurations.easeOut, alignment: Alignment.topCenter)`.

- **Rationale** : `AnimatedSize` avec `AppDurations.normal` (200ms) est le pattern homologué dans 3 composants existants. FR-001 impose `StatelessWidget` — l'option B est architecturalement incompatible. La différence 200ms↔150ms est imperceptible. `alignment: Alignment.topCenter` assure que le contenu s'ouvre vers le bas (cohérent avec l'animation Angular `translateY(-8px)`).

- **Alternatives rejetées** : B (brise StatelessWidget), C (pas d'animation de hauteur).

- **Impact sur le plan** : Aucune constante à ajouter. I-007 résolu : 150ms leave non porté, 200ms utilisé pour les deux sens. `AppDurations.easeOut` est la curve retenue (alignment avec Angular `cubic-bezier(0, 0, 0.2, 1)` = easeOut).

---

### RES-003 — Token errorContainer : valeurs light et dark

- **Contexte** : FR-009 impose `colorScheme.errorContainer` comme fond du bandeau d'erreur. `app_theme.dart` ne déclare pas ce token (absent de `ColorScheme.light` et `ColorScheme.dark`). La valeur Material 3 auto-générée n'est pas utilisable (non alignée sur `--bg-error` Angular). Prérequis FR-009 à livrer.

- **Analyse des tokens source Angular** :
  - `--bg-error` light (`_light.scss` ligne 36) : `#fee2e2` → `AppColors.errorLight` = `Color(0xFFFEE2E2)` ✓ (constant existante)
  - `--bg-error` dark (`_dark.scss` ligne 35) : `rgb(239 68 68 / 0.10)` → `AppColors.error.withValues(alpha: 0.10)` = `Color(0x1AEF4444)`

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Ajouter `errorContainer` dans `ColorScheme` de `app_theme.dart` | Token Material 3 natif, consommable via `colorScheme.errorContainer` | Modification d'un fichier existant (1 ligne light, 1 ligne dark) | ★★★ |
| B — Nouveau token `AppThemeExtension.errorBg` | Extension sémantique du projet | Crée une 17ème prop dans `AppThemeExtension`, ajouter `copyWith`/`lerp` — overhead pour un seul consommateur | ★ |
| C — Valeur Material 3 par défaut | Zéro modification | Couleur incorrecte, SC-005 invalide visuellement | ✗ |

- **Décision** : Option A — ajouter dans `app_theme.dart` :
  - Light : `errorContainer: AppColors.errorLight,` (= `#fee2e2`)
  - Dark : `errorContainer: const Color(0x1AEF4444),` (= `--bg-error` dark = `rgb(239 68 68 / 10%)`)

- **Rationale** : `colorScheme.errorContainer` est le token Material 3 sémantiquement correct pour un fond de surface d'erreur. L'option A ajoute 2 lignes à un fichier existant. L'option B alourdirait `AppThemeExtension` pour un seul usage. `AppColors.errorLight` existe déjà — pas de nouvelle constante de couleur nécessaire pour le light. La valeur dark `0x1AEF4444` est une constante inline documentée (pattern déjà présent dans `app_theme.dart` dark : `error: Color(0xFFF87171)`).

- **Alternatives rejetées** : B (overhead `AppThemeExtension`), C (valeur incorrecte).

- **Impact sur le plan** : Tâche prérequis : modifier `flutter/lib/src/theme/app_theme.dart` — ajouter `errorContainer` dans les deux `ColorScheme` (light + dark). Cette tâche doit être listée **avant** l'implémentation de `_BSheetErrorBanner` dans le widget.

---

### RES-004 — Implémentation de _BSheetActionPill

- **Contexte** : `_BSheetActionPill` est un sous-widget privé qui rend les pills du footer (cancel, primary, danger, status). Le SCSS Angular spécifie : `border: 1px solid --border-default`, `border-radius: --radius-round`, `background: transparent`, `padding: 5px 8-12px`, `font-size: sm`, `font-weight: medium`. Ce n'est pas un bouton Material standard.

- **Analyse du codebase** : `category_select_expand.dart` (ligne 283) utilise `InkWell + Container(BoxDecoration(border, borderRadius))` pour ses items sélectionnables — pattern existant pour les "pill-like" interactives. `AppFormField` et `EmojiInput` utilisent `TextButton` pour leurs actions inline.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `InkWell + Container(BoxDecoration)` | Contrôle total du padding, border, shape, couleur ; pattern déjà dans le projet ; ripple Material | Verbeux (~8 lignes par pill) | ★★★ |
| B — `OutlinedButton` styalisé | Moins de boilerplate | Hauteur minimum Material (48px) difficile à overrider ; `BorderSide` dans `ButtonStyle` moins lisible | ★ |
| C — `TextButton` avec `OutlinedBorder` | Compact | Pas de bordure native dans `TextButton` — hack via `shape` | ★ |

- **Décision** : Option A — `InkWell(borderRadius: AppRadius.round, onTap: onTap, child: Container(padding, decoration: BoxDecoration(border: Border.all(...), borderRadius: AppRadius.round), child: Row(icon?, Text)))`.

- **Rationale** : Contrôle exact du rendu (padding, border, couleur) aligné pixel-perfect sur le SCSS Angular. Pattern cohérent avec `category_select_expand.dart`. Le ripple `InkWell` fournit un feedback tactile Material natif. Les variantes (primary, danger, cancel, status) se différencient uniquement par les couleurs de texte/bordure — un seul constructeur avec paramètre `variant` suffit.

- **Alternatives rejetées** : B et C — trop de contraintes Material difficiles à surcharger pour une pill custom.

- **Impact sur le plan** : `_BSheetActionPill` est un widget privé au fichier avec un constructeur `const` et paramètre `variant: _BSheetActionPillVariant { primary, cancel, danger, status, loading }`. Pas de sous-classe par variante.

---

### RES-005 — État pressed de BSheetSubmitVariant.danger (résolution W-002)

- **Contexte** : CL-005 avait résolu l'état au repos (texte `ext.expenseColor`, bordure `ext.expenseColor`, fond transparent). W-002 identifiait que l'état hover Angular (`background: --bg-error`) n'avait pas d'équivalent Flutter spécifié.

- **Analyse** : `--bg-error` light = `#fee2e2` = `AppColors.errorLight`. En Flutter mobile, l'état d'interaction est `pressed` (InkWell `splashColor`/`highlightColor`). Avec l'option A de RES-004 (InkWell), l'état pressed est contrôlé via `splashColor` et `highlightColor` de l'`InkWell`.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `InkWell(splashColor: colorScheme.errorContainer)` | Aligné Angular hover → pressed, utilise le token RES-003 | Splash circulaire visible (ripple), pas un fond uniforme | ★★ |
| B — `InkWell(highlightColor: colorScheme.errorContainer, splashColor: Colors.transparent)` | Fond uniforme au pressed, plus proche du hover CSS | Pas de ripple (feedback moins visible sur tactile) | ★★ |
| C — `GestureDetector + onTapDown/onTapUp + setState` | Contrôle total | Exige `StatefulWidget` pour le sous-widget — brise la simplicité | ★ |

- **Décision** : Option B — `InkWell(highlightColor: colorScheme.errorContainer.withValues(alpha: 0.6), splashColor: colorScheme.errorContainer.withValues(alpha: 0.3))`. Fond clair au pressed, ripple discret.

- **Rationale** : `highlightColor` produit un fond uniforme (équivalent "background change" CSS hover), `splashColor` semi-transparent pour le feedback ripple. Pas d'état stateful nécessaire. Aligné sur le token `errorContainer` résolu dans RES-003. Le même pattern s'applique à la variante `primary` (splash `colorScheme.primary`) et `cancel` (splash `colorScheme.onSurface`).

- **Alternatives rejetées** : C (StatefulWidget inutile).

- **Impact sur le plan** : Paramètre `splashColor` et `highlightColor` définis par variante dans `_BSheetActionPill`. W-002 résolu.

---

## Analyse du codebase

### Patterns existants identifiés

- **`AnimatedSize(duration: AppDurations.normal, curve: AppDurations.easeInOut)`** — utilisé dans `app_form_field.dart`, `select_picker.dart`, `emoji_input.dart`. Pattern homologué pour expand/collapse. → RES-002 aligné sur `easeOut` (légèrement différent de `easeInOut` existant — justifié par l'alignement Angular exact).
- **`InkWell + Container(BoxDecoration(border, borderRadius))`** — utilisé dans `category_select_expand.dart` pour les items sélectionnables. → Pattern retenu pour `_BSheetActionPill` (RES-004).
- **`Column { Expanded(SingleChildScrollView), footer }`** — non présent dans `AppModal` actuel (utilise `Flexible` sans footer pinned). Pattern à introduire pour `BottomSheet4RowsWidget`. → Layout fondamentalement différent de `AppModal`.
- **`showModalBottomSheet(isScrollControlled: true, useSafeArea: true)`** — utilisé dans `AppModal._showBottomSheet`. L'appelant du `BottomSheet4RowsWidget` utilisera le même appel. Documentation `///` à fournir (NFR-007).
- **`ConstrainedBox(maxHeight: 0.9 * screenHeight)`** — utilisé dans `AppModal`. Le `BottomSheet4RowsWidget` ne s'impose pas cette contrainte — c'est l'appelant qui la gère via `showModalBottomSheet` (constitution YAGNI).

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `phosphor_flutter` | existant | Icône handle, pills footer | Aucun — déjà dans le projet |
| `AppDurations` | existant | `AppDurations.normal` + `AppDurations.easeOut` pour `AnimatedSize` | Aucun |
| `AppThemeExtension` | existant (16 props) | `expenseColor` (danger pill), `iconCircleBg` (icon buttons Row 3) | Aucun |
| `ColorScheme.errorContainer` | **à ajouter** dans `app_theme.dart` | Fond bandeau erreur (`_BSheetErrorBanner`) + état pressed danger pill | Faible — 2 lignes dans un fichier existant |
| `AppColors.errorLight` | existant | Valeur light de `errorContainer` | Aucun |
| `InlineDatePicker` (KKS-238) | existant dans `common_widgets/` | Passé via slot `expandedContent` | Aucun — pas d'import direct dans le widget |
| `CategorySelectExpand` (KKS-238) | existant dans `common_widgets/` | Passé via slot `expandedContent` | Aucun — pas d'import direct dans le widget |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 5 |
| Décisions prises | 5 |
| Nouvelles dépendances | 0 |
| Fichiers existants à modifier (prérequis) | 1 (`app_theme.dart` — ajout `errorContainer` light + dark) |
| Patterns réutilisés | 3 (`AnimatedSize`, `InkWell+BoxDecoration`, `showModalBottomSheet`) |
| Points de review résiduels résolus | 2 (I-007 durée 150ms, W-002 état pressed danger) |
