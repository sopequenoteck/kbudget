# Research — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
> Spec : [spec.md](./spec.md)
> Clarify : [clarify-log.md](./clarify-log.md)
> Review-spec : [review-log.md](./review-log.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Migration | Stratégie de migration des constantes sémantiques dark dans `AppColors` (`incomeDark`, `expenseDark`, etc.) — supprimer / renommer / conserver avec valeurs mises à jour ? | Haute |
| RES-002 | API design | Pattern `AppShadows.coloredPrimary` brightness-aware tout en préservant le pattern `const` de `AppShadows` | Haute |
| RES-003 | Architecture | Placement des couleurs custom dark non-primitives (`#e0a820`, `#9580d9`, `#6dc990`, `#d97777`, `#d4ad3c`, `#7aacdb`) | Moyenne |
| RES-004 | Material 3 | Extension `lerp()` et `copyWith()` du `AppThemeExtension` avec ~10 nouveaux tokens — risque d'interpolation des tokens alpha ? | Basse |
| RES-005 | Migration | Refonte `AppTheme.dark` et `AppTheme.light` qui consomment actuellement les primitives `AppColors.amber*` directement | Haute |
| RES-006 | Audit | Hardcodes amber100 dans `list_item.dart` et `recent_transactions_section.dart` pour fonds d'icône — gérer dans KKS-237 ou différer ? | Moyenne |
| RES-007 | Marquage | Stratégie `@Deprecated` sur `PatrimoineCard` (et autres widgets gradient) — annotation classe entière ou propriété spécifique ? | Basse |
| RES-008 | Documentation | Format précis de l'avertissement obsolète dans `docs/design-tokens.md` | Basse |

---

## Décisions techniques

### RES-001 — Stratégie de migration des constantes sémantiques dark dans `AppColors`

- **Contexte** : `AppColors` contient actuellement `incomeDark = Color(0xFF4ADE80)`, `expenseDark = Color(0xFFF87171)`, `subscriptionDark = Color(0xFFA78BFA)`, `debtOweDark`, `debtOwedDark` — couleurs sémantiques mélangées avec primitives. La spec demande de mettre à jour les valeurs vers `#6dc990`, `#d97777`, `#9580d9`. Question : conserver les noms et changer les valeurs, renommer pour signaler le caractère sémantique, ou supprimer et inliner dans `AppThemeExtension` ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Conserver noms, changer valeurs (`AppColors.incomeDark = #6dc990`) | Migration en place. Aucun renommage. Compatibilité avec consommateurs. | Mélange primitives + sémantiques persiste dans `AppColors`. | **Élevé** |
| B — Renommer en `AppColors.incomeDarkValue` ou `semanticIncomeDark` | Signale le caractère sémantique. Découpage plus propre. | Breaking change sur 1 fichier (`app_theme_extension.dart`). Refactoring sans valeur ajoutée fonctionnelle. | Moyen |
| C — Supprimer de `AppColors`, inliner valeurs dans `AppThemeExtension.dark`/`.light` | Pure couche primitive. | Hardcode des hex dans `AppThemeExtension`. Multiplication des hex à maintenir. | Bas |

- **Décision** : **Option A**. Conserver `incomeDark`, `expenseDark`, `subscriptionDark`, `debtOweDark`, `debtOwedDark` avec valeurs mises à jour. Ajouter en parallèle les nouvelles constantes sémantiques (`primaryAmberDark = #e0a820`, `textWarningDark = #d4ad3c`, `textInfoDark = #7aacdb`) et les tokens interactifs (`primarySubtleDark`, `hoverBgDark`, etc.).

- **Rationale** :
  1. **Audit consommateurs** : `grep -rn "AppColors\.\(income\|expense\|subscription\|debtOwe\|debtOwed\)" flutter/lib --include="*.dart"` retourne **uniquement** `app_theme_extension.dart` (10 occurrences). Aucun widget direct. Migration en place sans casse.
  2. **Compatibilité Constitution Principe III (Simplicité & YAGNI)** : pas de refactoring opportuniste. La distinction primitive/sémantique pure est un idéal architectural, mais la rupture API n'apporte aucune valeur fonctionnelle.
  3. **Cohérence avec l'existant** : le pattern actuel (`AppColors.incomeDark` consommé par `AppThemeExtension.dark.incomeColor`) fonctionne. On garde.

- **Alternatives rejetées** :
  - B : refactoring cosmétique non justifié.
  - C : multiplication des hex hardcodés viole le principe DRY.

- **Impact sur le plan** : tâche unique de mise à jour des valeurs dans `AppColors` (5 modifications de `Color(0x...)`).

---

### RES-002 — Pattern `AppShadows.coloredPrimary` brightness-aware

- **Contexte** : `AppShadows` actuel est une classe `static const` (constructeur privé `_()`). Pattern `const` partout. La spec FR-018 demande un helper qui retourne une ombre **noire** en dark et **amber** en light. Trois patterns Flutter possibles : prendre `BuildContext` (couplage widgets), prendre `Brightness` (paramètre simple), ou exposer 2 constantes dark/light.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Helper `coloredPrimary(BuildContext context)` qui lit `Theme.of(context).brightness` | Utilisation simple `AppShadows.coloredPrimary(context)`. | Couplage à `BuildContext`. Difficile à tester unitairement. Ne peut pas être `const`. | Bas |
| B — Helper `coloredPrimary(Brightness brightness)` paramètre direct | Découplé de `BuildContext`. Testable unitairement. Fonctionne hors widget tree. | Le caller doit récupérer le brightness lui-même (`Theme.of(context).brightness`). | Moyen |
| C — Deux constantes `static const coloredPrimaryDark` et `coloredPrimaryLight` | `const` préservé. Usage le plus simple. | Le caller doit choisir manuellement selon le brightness. | Élevé |
| D — Combiner B + C : 2 constantes + helper Brightness | Le meilleur des deux mondes : `const` pour usages statiques + helper pour usages dynamiques. | Léger doublon API. | **Élevé** |

- **Décision** : **Option D**. Exposer :
  - `static const List<BoxShadow> coloredPrimaryDark = [...]` (ombre noire `#000000` alpha `0x66`)
  - `static const List<BoxShadow> coloredPrimaryLight = [...]` (ombre amber `#F59E0B` alpha `0x66`)
  - `static List<BoxShadow> coloredPrimary(Brightness brightness)` qui retourne l'une ou l'autre

  L'ancienne API `static List<BoxShadow> colored(Color color, {int alpha = 102})` est marquée `@Deprecated('Utiliser AppShadows.coloredPrimary(brightness) ou les constantes coloredPrimaryDark/Light')` pour compatibilité courte.

- **Rationale** :
  1. **Découplage `BuildContext`** : Brightness est un paramètre primitif (`enum`). Le caller (typiquement un widget) appelle `Theme.of(context).brightness` une fois et passe le brightness. Découpage propre.
  2. **`const` préservé** : les 2 constantes statiques restent utilisables dans `const` widgets ou `const TextStyle`.
  3. **Migration douce** : `colored()` deprecated mais conservé. Les widgets actuels (`PatrimoineCard` ?) qui l'utilisent ne cassent pas immédiatement — ils seront migrés lors de KKS-240.

- **Alternatives rejetées** :
  - A : couplage `BuildContext` complique les tests + interdit `const`.
  - B seul (sans constantes) : perd la possibilité d'usage `const` dans les `BoxDecoration` const.
  - C seul (sans helper) : duplique le code de sélection chez chaque caller.

- **Impact sur le plan** : refonte de `app_shadows.dart` avec 2 nouvelles constantes + 1 helper + annotation `@Deprecated` sur l'ancienne API.

---

### RES-003 — Placement des couleurs custom dark non-primitives

- **Contexte** : Les couleurs `#e0a820` (primary dark), `#9580d9` (subscription dark), `#6dc990` (income dark), `#d97777` (expense dark), `#d4ad3c` (textWarning dark), `#7aacdb` (textInfo dark) ne sont pas dans une palette `amber-*` ou `green-*` standard. Elles sont sémantiques par essence. Question : où les définir ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Inliner les hex directement dans `AppTheme.dark` et `AppThemeExtension.dark` | Pas de fichier intermédiaire. | Hardcode hex dans 2 endroits. Duplication. | Bas |
| B — Constantes dans `AppColors` avec section "Semantic dark values" + nommage explicite | Convention déjà partiellement adoptée (`incomeDark` existe). Centralisation. | `AppColors` reste mixte primitives + sémantiques. | **Élevé** |
| C — Fichier dédié `app_semantic_colors.dart` séparé | Découpage pur primitives / sémantiques. | Fichier supplémentaire à maintenir. Refactoring `AppColors` actuel nécessaire. | Bas |

- **Décision** : **Option B**. Conserver dans `AppColors` avec section commentée :
  ```dart
  // ===== Semantic dark values (custom, not derived from primitive palettes) =====
  /// Primary amber semantic value for dark theme. Not derived from amber-* palette.
  /// Source: app/src/styles/themes/_dark.scss `--color-primary: #e0a820`.
  static const Color primaryAmberDark = Color(0xFFE0A820);

  /// Text warning semantic value for dark theme.
  static const Color textWarningDark = Color(0xFFD4AD3C);
  // ...
  ```

- **Rationale** :
  1. **Cohérence avec l'existant** : `incomeDark`, `expenseDark`, etc. sont déjà dans `AppColors` malgré leur nature sémantique. Continuer cette convention au lieu de fragmenter.
  2. **Découplage de la décomposition pure** : la spec (et le rapport flutter-dev) acceptent la mixité primitives/sémantiques dans `AppColors`. La pureté architecturale (option C) n'est pas un objectif déclaré.
  3. **Lisibilité** : section commentée signale clairement la nature sémantique aux contributeurs futurs.

- **Alternatives rejetées** :
  - A : hardcodes hex dispersés violent DRY.
  - C : fichier supplémentaire sans gain fonctionnel. Refactoring trop large pour le scope KKS-237.

- **Impact sur le plan** : tâche d'ajout de ~10-15 constantes dans `AppColors` avec section commentée et docstrings.

---

### RES-004 — Extension `lerp()` et `copyWith()` du `AppThemeExtension`

- **Contexte** : L'extension actuelle a 6 propriétés `Color` avec `lerp()` et `copyWith()` implémentés. La spec ajoute ~10 nouveaux tokens (`textWarning`, `textInfo`, `primarySubtle`, `primaryMuted`, `primaryBorder`, `hoverSubtle`, `highlightSubtle`, `overlayLight`, `focusRing`, `iconCircleBg`). Tous sont des `Color`. Question : risque d'interpolation pour les tokens alpha (`primarySubtle = rgba(..., 0.10)`) entre dark et light ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Extension mécanique : `Color.lerp(this.x, other.x, t)!` pour chaque token | Simple. Cohérent avec l'existant. | — | **Élevé** |

- **Décision** : **Option A** — extension mécanique.

- **Rationale** :
  1. **`Color.lerp()` Flutter natif** gère correctement les composantes RGBA (interpolation linéaire sur chacune des 4 composantes). Les tokens alpha (`rgba(255, 255, 255, 0.04)` dark → `rgba(0, 0, 0, 0.04)` light) sont interpolés sans problème.
  2. **Pas d'optimisation prématurée** : `lerp()` est appelé uniquement lors d'un theme switching animé (rare). Performance négligeable même avec 16 propriétés.
  3. **Test trivial** : un test unitaire avec `t = 0` et `t = 1` valide chaque propriété.

- **Alternatives rejetées** : aucune autre option viable.

- **Impact sur le plan** : extension mécanique de `app_theme_extension.dart` avec ~16 propriétés au total (6 existantes + ~10 nouvelles). Tests unitaires à compléter.

---

### RES-005 — Refonte `AppTheme.dark` et `AppTheme.light`

- **Contexte** : `AppTheme.dark` consomme actuellement `AppColors.amber400` comme `primary` (= `#FBBF24` Tailwind). La spec demande `primary = #e0a820` (= `AppColors.primaryAmberDark` après RES-003). 14+ usages `AppColors.amber*` dans `app_theme.dart` à auditer. Idem pour `light`.

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Refonte complète : remplacer chaque `AppColors.amber*` par sa contrepartie sémantique correcte | Cohérence finale. | Effort de relecture important sur les 14+ usages. | **Élevé** |
| B — Refonte minimale : ne changer que `primary` et `surface` ; laisser le reste pointer vers `amber*` | Moins d'effort. | Cohérence partielle. Les boutons, FABs, navigation continueront d'utiliser amber Tailwind. | Bas |

- **Décision** : **Option A**. Audit ligne par ligne de `app_theme.dart` (lignes 16-160 environ pour les 2 thèmes). Pour chaque `AppColors.amber*` :
  - Si c'est un usage **primary semantic** (boutons, FAB, selectedItem, focused border) → remplacer par `AppColors.primaryAmberDark` (dark) ou `AppColors.amber600` (light, inchangé).
  - Si c'est un usage **palette** (gradient legacy, contrast, container) → conserver `AppColors.amber*` ou supprimer si gradient anti-pattern.

- **Rationale** :
  1. La spec exige cohérence avec Angular v5 dark (`--color-primary: #e0a820`). La majorité des usages `AppColors.amber400` dans `AppTheme.dark` correspondent sémantiquement à cette primary.
  2. La refonte minimale (option B) laisserait des incohérences visuelles entre les boutons (amber Tailwind) et les éléments primary (amber custom).

- **Alternatives rejetées** : B — incohérence visuelle inacceptable au final.

- **Impact sur le plan** : tâche d'audit + refactoring de `app_theme.dart` ligne par ligne. Tests visuels manuels pour vérifier le rendu avant/après. Estimation ~3-4h sur les 16h totales.

---

### RES-006 — Hardcodes `AppColors.amber100` hors AppTheme

- **Contexte** : Audit grep révèle 2 hardcodes :
  - `list_item.dart:76` : `color: iconBackgroundColor ?? AppColors.amber100` (fond d'icône)
  - `recent_transactions_section.dart:211` : idem
  - `patrimoine_card.dart:111-112` : gradient anti-pattern (à marquer `@Deprecated`)

  Question : corriger dans KKS-237 ou différer ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Corriger dans KKS-237 (remplacer `amber100` par token sémantique `iconCircleBg`) | Cohérence immédiate. | Élargit le scope KKS-237 (touche `list_item.dart` et `recent_transactions_section.dart`). | Moyen |
| B — Différer à KKS-238 ou KKS-240 (refonte composants / écrans) | Scope KKS-237 reste fermé. | Hardcodes persistent temporairement. | **Élevé** |

- **Décision** : **Option B** — différer. Documenter dans la PR de KKS-237 (audit informatif SC-011) sans corriger. La correction relève de KKS-238 (refonte composants `list_item.dart`) et KKS-240 (refonte `recent_transactions_section.dart` dans dashboard).

- **Rationale** :
  1. **Périmètre fermé** : la spec KKS-237 exclut explicitement la modification des composants et écrans (cf. "Hors périmètre" et Edge Cases).
  2. **Risque de scope creep** : élargir KKS-237 retarde le débloquage de KKS-238/240.
  3. **Cohérence avec SC-011** : l'audit informatif est précisément conçu pour ce cas — quantifier sans bloquer.

- **Alternatives rejetées** : A — viole le périmètre de la spec.

- **Impact sur le plan** : aucune tâche d'implémentation dans KKS-237 pour ces hardcodes. Mention dans la PR.

---

### RES-007 — Marquage `@Deprecated` sur widgets gradient

- **Contexte** : `patrimoine_card.dart` utilise un `LinearGradient(amber900→indigo900)` en dark et `amber50→indigo50` en light. La spec FR-021 demande un marquage `@Deprecated`. Question : annoter la classe entière, ou seulement la propriété/méthode qui produit le gradient ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `@Deprecated` sur la classe `PatrimoineCard` entière | Avertissement IDE sur tous les usages du widget. | Fausse alerte : le widget reste utilisé jusqu'à KKS-240. | Moyen |
| B — `@Deprecated` sur la méthode `build()` ou propriété privée du gradient | Avertissement ciblé sur le code à supprimer. | Pas tous les éditeurs Dart ne propagent les annotations sur méthodes privées. | Bas |
| C — Commentaire `// TODO(KKS-240): ...` sans annotation Dart | Pas d'avertissement IDE perdu si non remarqué. | Pas exploité par les outils. | Bas |
| D — `@Deprecated` sur la classe + commentaire référence KKS-240 | Avertissement IDE + traçabilité. | Idem option A : fausse alerte temporaire. | **Élevé** |

- **Décision** : **Option D** — `@Deprecated('Gradient décoratif interdit en dark v5 — refonte hero flat dans KKS-240. Token Angular équivalent neutralisé : --hero-gradient: none.')` sur la classe `PatrimoineCard`.

- **Rationale** :
  1. **Visibilité IDE forte** : tout consommateur de `PatrimoineCard` reçoit l'avertissement à l'édition. Augmente les chances de migration cohérente.
  2. **Référence Linear** : le message inclut KKS-240, traçabilité claire.
  3. **Acceptation de la fausse alerte temporaire** : entre KKS-237 et KKS-240, le widget est utilisé mais `@Deprecated`. C'est attendu et explicite.

- **Alternatives rejetées** :
  - B : annotation sur méthode privée moins visible.
  - C : commentaire perdu.

- **Impact sur le plan** : annotation `@Deprecated` sur 1 classe (`PatrimoineCard`). Vérifier s'il y a d'autres widgets avec gradient à marquer (audit grep `LinearGradient` côté Flutter).

---

### RES-008 — Format de l'avertissement obsolète `docs/design-tokens.md`

- **Contexte** : FR-023 a déjà donné un format suggéré. Question : appliquer tel quel ou enrichir ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Format FR-023 tel quel (avertissement compact + liste de redirections) | Direct, conforme à la décision clarify CL-005. | — | **Élevé** |
| B — Enrichir avec un exemple visuel de structure 2 couches | Pédagogique. | Risque de désynchronisation : si le code SCSS évolue, l'exemple aussi. | Bas |

- **Décision** : **Option A** — appliquer le format FR-023 tel quel. Format final :

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

- **Rationale** : minimal, clair, pointeur vers les sources réelles.

- **Alternatives rejetées** : B — risque de doc qui se désynchronise à nouveau (le mal qu'on cherche à éliminer).

- **Impact sur le plan** : 1 modification de `docs/design-tokens.md` (insertion en entête).

---

## Analyse du codebase

### Patterns existants identifiés

| Pattern | Localisation | Usage prévu dans KKS-237 |
|---------|--------------|--------------------------|
| `class Foo { Foo._(); static const ...; }` (constructeur privé + constantes statiques) | `AppColors`, `AppTypography`, `AppShadows`, `AppRadius`, `AppSpacing`, `AppDurations` | À conserver — pattern projet |
| `ThemeExtension<T>` Material 3 | `AppThemeExtension` | À étendre |
| `@Deprecated('message')` annotation Dart standard | Pas trouvé dans le projet à ce jour | À introduire |
| `Color.lerp()` natif Flutter | `AppThemeExtension.lerp()` | À étendre |
| `ThemeData.copyWith()` + `extensions: const <ThemeExtension<dynamic>>[...]` | `AppTheme.dark`, `AppTheme.light` | À conserver |
| `const Color(0xFF...)` (couleurs ARGB) | `AppColors` | À conserver |
| `BoxShadow` const list | `AppShadows.sm`, `.md`, `.lg` | À étendre (double-layer + helper Brightness) |

### Stack technique vérifiée

- **Flutter** ≥ 3.27 (constitution v3.0.0) → `ThemeExtension<T>` stable, `Color.lerp` natif, `@Deprecated` standard Dart.
- **Material 3** activé via `useMaterial3: true` dans `AppTheme` (à vérifier au moment de l'implémentation).
- **`AppThemeExtension`** consommée par 14+ widgets via `Theme.of(context).extension<AppThemeExtension>()` — pattern stable.

### Audit des consommateurs (résultats `grep`)

| Constante | Fichiers consommateurs | Action KKS-237 |
|-----------|------------------------|----------------|
| `AppColors.incomeDark/expenseDark/subscriptionDark/debtOweDark/debtOwedDark` | `app_theme_extension.dart` (10 occurrences, 1 fichier) | Mise à jour valeurs en place |
| `AppColors.amber*` | `app_theme.dart` (14+ occurrences, primary/FAB/selectedItem/border/etc.) | Refonte ciblée vers `primaryAmberDark` (dark) et `amber600` (light) selon RES-005 |
| `AppColors.amber100` (fond d'icône) | `list_item.dart:76`, `recent_transactions_section.dart:211` | **Différé KKS-238/240** (RES-006) |
| `AppColors.amber900/indigo900/amber50/indigo50` (gradient PatrimoineCard) | `patrimoine_card.dart:111-112` | Marquage `@Deprecated` sur la classe (RES-007) |

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| Flutter SDK | ≥ 3.27 (déjà en place) | `ThemeExtension`, `Color.lerp`, `@Deprecated` | Aucun |
| Dart core | ≥ 3.6 | `@Deprecated` annotation | Aucun |
| `phosphor_flutter` | v2.1.0 | Icônes — non touchées dans KKS-237 | Aucun |

**Aucune nouvelle dépendance** (`pubspec.yaml` inchangé, conforme NFR-004).

---

## Ordre d'implémentation suggéré (input pour `/devflow.plan`)

Pour minimiser les états intermédiaires cassés (ex: `AppTheme` qui pointe vers une constante pas encore renommée) :

1. **AppColors — palette gris propriétaire** : refonte des 10 nuances (`gray50` → `gray900`). L'app peut paraître plus sombre temporairement mais reste fonctionnelle.
2. **AppColors — couleurs sémantiques dark mises à jour** : `incomeDark`, `expenseDark`, `subscriptionDark`, `debtOweDark`, `debtOwedDark` valeurs nouvelles.
3. **AppColors — nouvelles constantes sémantiques dark** : `primaryAmberDark`, `textWarningDark`, `textInfoDark`, `primarySubtleDark`, `primaryMutedDark`, `primaryBorderDark`, `hoverBgDark`, `hoverSubtleDark`, `highlightSubtleDark`, `overlayLightDark`, `focusRingDark`, `iconCircleBgDark`.
4. **AppColors — nouvelles constantes sémantiques light** : `textWarningLight`, `textInfoLight`, `primarySubtleLight`, `primaryMutedLight`, `primaryBorderLight`, `hoverBgLight`, `hoverSubtleLight`, `highlightSubtleLight`, `overlayLightLight`, `focusRingLight`, `iconCircleBgLight`.
5. **AppTypography** : ajout `size2Xs = 10.0`, `sizeHero = 36.0`, `labelLetterSpacingFactor = 0.05`, `labelLetterSpacingForSize10/12/14`.
6. **AppShadows** : refonte `md` et `lg` en double-layer ; ajout `coloredPrimaryDark`, `coloredPrimaryLight`, `coloredPrimary(Brightness)` ; `@Deprecated` sur `colored(Color, alpha)`.
7. **AppThemeExtension** : ajout des ~10 nouvelles propriétés (textWarning, textInfo, primarySubtle, primaryMuted, primaryBorder, hoverSubtle, highlightSubtle, overlayLight, focusRing, iconCircleBg) + extension `lerp()` et `copyWith()`. Mise à jour des instances `light` et `dark`.
8. **AppTheme.dark** : refonte ciblée des `AppColors.amber*` vers `primaryAmberDark` selon RES-005.
9. **AppTheme.light** : refonte ciblée vers `amber600` (primary) + tokens light.
10. **PatrimoineCard** : annotation `@Deprecated('...')` sur la classe.
11. **Audit grep gradient** : `grep -rn "LinearGradient" flutter/lib/src/features/` pour détecter d'autres gradients à marquer.
12. **Audit informatif hardcodes Tailwind** (SC-011) : `grep -E '#(F59E0B|D97706|...)' flutter/lib/src/features/` — résultat consigné dans la PR.
13. **`docs/design-tokens.md`** : insertion de l'avertissement obsolète en entête.
14. **Tests** : ajustements des tests qui valident des valeurs hex précises (cf. NFR-002, Edge Case "Tests existants").

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 8 |
| Décisions prises | 8 |
| Nouvelles dépendances | 0 |
| Patterns réutilisés | 7 (constructeur privé + statiques, ThemeExtension, Color.lerp, @Deprecated, ThemeData.copyWith, const Color, BoxShadow const list) |
| Fichiers Flutter à modifier | 5 (`app_colors.dart`, `app_typography.dart`, `app_shadows.dart`, `app_theme_extension.dart`, `app_theme.dart`) + 1 widget (`patrimoine_card.dart`) + 1 doc (`docs/design-tokens.md`) |
| Estimation effort revisée | ~16h (cohérent avec l'estimation Linear initiale) |
