# Clarify Log — KKS-237 : Refonte tokens design Flutter (palette propriétaire v5)

> Date : 2026-05-03
> Issue : [KKS-237](https://linear.app/kksdev/issue/KKS-237/phase-1-etape-1-refonte-tokens-design-flutter-palette-proprietaire)
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | NC-1 | Structure `AppThemeExtension` (une seule ou plusieurs) | 7 — Contraintes | H | M | HAUT | Conserver l'extension existante (déjà 6 propriétés, 14+ widgets consommateurs) et l'étendre. Une seule extension. | Auto |
| CL-002 | A7 | `ThemeExtension<T>` Flutter fonctionnel | 7 — Contraintes | H | B | HAUT | Validé via lecture de `flutter/lib/src/theme/app_theme_extension.dart` (en production). | Auto |
| CL-003 | A3 | Hardcodes Tailwind hors `AppColors` | 6 — Edge cases | H | M | HAUT | Différé à KKS-240. Audit informatif (grep) pendant l'implémentation KKS-237, non bloquant. | Auto |
| CL-004 | NC-3 | Conversion letter-spacing CSS (0.05em) → Flutter | 7 — Contraintes | M | M | MOYEN | Approche hybride : facteur dynamique `0.05` + constantes pré-calculées (`forSize10 = 0.5`, `forSize12 = 0.6`, `forSize14 = 0.7`). | Auto |
| CL-005 | NC-2 | Sort de `docs/design-tokens.md` | 1 — Scope | M | B | BAS | Option B : marquer obsolète en entête + redirection vers `app/src/styles/tokens/`, `app/src/styles/themes/`, `DESIGN.md`. | Interactif |

---

## Résolutions détaillées

### CL-001 — Structure `AppThemeExtension`

- **Catégorie** : 7 (Contraintes techniques)
- **Score** : HAUT
- **Contexte** : NC-1 de la spec. Question initiale : créer un seul `AppThemeExtension` regroupant tous les tokens semantiques manquants au `ColorScheme` Material, ou plusieurs extensions thématiques séparées (`BusinessColors`, `InteractiveColors`, `FeedbackColors`) ? Une seule extension = simple à consommer, gros fichier. Plusieurs = découpage propre, plus de boilerplate.
- **Analyse** : exploration du code Flutter existant via `grep -rn "ThemeExtension\|AppThemeExtension" flutter/lib --include="*.dart"`. Découverte : `AppThemeExtension` existe déjà dans `flutter/lib/src/theme/app_theme_extension.dart` avec 6 propriétés business (`incomeColor`, `expenseColor`, `debtOweColor`, `debtOwedColor`, `subscriptionColor`, `secondaryColor`). Consommée dans 14+ widgets : `dashboard/widgets/income_expense_cards.dart`, `dashboard/widgets/recent_transactions_section.dart`, `transactions/widgets/transaction_summary_card.dart`, `transactions/widgets/transaction_day_group.dart`, `debts/presentation/debt_list_screen.dart`, `debts/presentation/debt_detail_screen.dart`, `subscriptions/presentation/subscription_detail_screen.dart`, `utils/amount_formatter.dart`, etc.
- **Décision** : conserver l'`AppThemeExtension` existant et l'étendre avec les nouveaux tokens semantiques manquants (`textWarning`, `textInfo`, `primarySubtle`, `primaryMuted`, `primaryBorder`, `hoverSubtle`, `highlightSubtle`, `overlayLight`, `focusRing`, `iconCircleBg`). **Une seule extension**, pas plusieurs. Compatibilité préservée pour les 14+ widgets existants.
- **Impact sur spec.md** : NC-1 supprimé. FR-009/010/011 reformulés pour préciser "extension de l'`AppThemeExtension` existant". US3 et US4 reformulés. Mention explicite des 6 propriétés actuelles à conserver.

### CL-002 — `ThemeExtension<T>` Flutter fonctionnel

- **Catégorie** : 7 (Contraintes techniques)
- **Score** : HAUT
- **Contexte** : Assumption A7 — Flutter peut implémenter les tokens business via `ThemeExtension<T>` (mécanisme natif Flutter Material 3). À valider pour ne pas bâtir la spec sur une fondation technique incertaine.
- **Analyse** : `flutter/lib/src/theme/app_theme_extension.dart` ligne 4 : `class AppThemeExtension extends ThemeExtension<AppThemeExtension>`. Les méthodes `copyWith()` et `lerp()` sont implémentées. Les instances statiques `AppThemeExtension.light` et `AppThemeExtension.dark` sont injectées dans `AppTheme.light` et `AppTheme.dark` via `extensions: const <ThemeExtension<dynamic>>[AppThemeExtension.light]`. Mécanisme Material 3 stable depuis Flutter 3.10+, projet utilise Flutter ≥ 3.27 (cf. constitution v3.0.0).
- **Décision** : A7 validé. Aucune approche alternative (singleton, provider) à prévoir.
- **Impact sur spec.md** : A7 reformulé en "Validé via lecture du code existant" avec citation du fichier source.

### CL-003 — Hardcodes Tailwind hors `AppColors`

- **Catégorie** : 6 (Edge cases)
- **Score** : HAUT
- **Contexte** : Assumption A3 — aucun widget ne consomme directement les valeurs hex Tailwind hors des tokens. Si fausse, révèle du travail caché potentiellement à intégrer dans la spec ou à différer.
- **Analyse** : la vérification exhaustive nécessite un grep complet sur `flutter/lib/src/features/` qui dépasse le scope de cette feature (refonte des tokens uniquement). Les hardcodes éventuels dans les widgets relèvent du scope KKS-240 (refonte écrans L). Documenter l'audit comme livrable informatif de KKS-237 sans en faire un bloquant.
- **Décision** : différé à KKS-240. Pendant l'implémentation de KKS-237, exécuter le grep informatif et consigner le comptage dans la PR — résultat servira à dimensionner KKS-240.
- **Impact sur spec.md** : SC-011 ajouté pour formaliser l'audit informatif.

### CL-004 — Conversion letter-spacing CSS (0.05em) → Flutter

- **Catégorie** : 7 (Contraintes techniques)
- **Score** : MOYEN
- **Contexte** : NC-3 de la spec. La valeur CSS `letter-spacing: 0.05em` est relative à la taille de police. En Flutter, `TextStyle.letterSpacing` attend une valeur absolue en logical pixels. Question : facteur multiplicatif Flutter ou constantes pré-calculées par taille ?
- **Analyse** : deux usages probables dans le projet :
  - **Dynamique** dans des helpers utilitaires (e.g. `Text(label, style: TextStyle(fontSize: size, letterSpacing: size * factor))`).
  - **Statique** dans des `TextStyle` constants ou des `const` widgets où le compilateur exige une valeur littérale (`const TextStyle(fontSize: 12, letterSpacing: 0.6)`).
  Ces deux usages coexistent dans Flutter, choisir l'un ou l'autre force des contournements.
- **Décision** : approche hybride dans `AppTypography` :
  - **Facteur** : `static const double labelLetterSpacingFactor = 0.05;` pour usages dynamiques.
  - **Constantes pré-calculées** pour usages statiques en `TextStyle` constants : `labelLetterSpacingForSize10 = 0.5`, `labelLetterSpacingForSize12 = 0.6`, `labelLetterSpacingForSize14 = 0.7`.
- **Impact sur spec.md** : NC-3 supprimé. FR-015 reformulé avec la convention hybride explicite.

### CL-005 — Sort de `docs/design-tokens.md`

- **Catégorie** : 1 (Scope fonctionnel)
- **Score** : BAS
- **Contexte** : NC-2 / FR-023 de la spec. Le fichier se proclame "Source de vérité unique" mais ses valeurs (palette Tailwind partout) ne correspondent ni à `_primitives.scss` (palette gris propriétaire) ni à `_dark.scss` / `_light.scss` (couleurs custom dark). La désynchronisation existe déjà ; la spec initiale a été biaisée par cette mauvaise lecture.
- **Analyse** : deux options.
  - **A. Mettre à jour le contenu** pour refléter `_primitives.scss` + tokens semantiques actuels. Effort ~2h. Avantage : source de vérité unique cross-stack maintenue. Inconvénient : double maintenance dette code/doc, désynchronisation systématique sur 5 ans.
  - **B. Marquer obsolète + redirection** vers `app/src/styles/tokens/`, `app/src/styles/themes/`, `DESIGN.md`. Effort ~10min. Avantage : pointe vers la source réelle, élimine la dette. Inconvénient : perte d'une vue consolidée cross-stack — mais cette vue était déjà incorrecte donc valeur perdue faible.
- **Décision** : Option B. Validée par l'utilisateur le 2026-05-03 avec justification : "sur 5 ans de maintenance, la duplication doc / code est une dette qui grossit. Le code SCSS Angular est déjà très lisible. Maintenir le doc dupliqué le désynchroniserait à nouveau systématiquement."
- **Impact sur spec.md** : NC-2 supprimé. FR-023 reformulé avec format d'avertissement explicite.

---

## Points différés

> Points non résolus dans cette session (au-delà du top 5), à traiter lors d'une prochaine itération si nécessaire ou pendant l'implémentation.

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| CL-006 | A5 | Light theme partiellement Tailwind-compatible | 1 — Scope | M | B | BAS | Décision implicite déjà actée dans la spec (A5 + FR-012 cohérents). Pas de divergence à clarifier. |
| CL-007 | A2 | `AppRadius` / `AppSpacing` / `AppDurations` alignés | 9 — Signaux | M | B | BAS | Déjà validé par audit flutter-dev du 2026-05-03 (lecture directe `_primitives.scss`). |
| CL-008 | A4 | Tooling Flutter (`flutter analyze` / `flutter test`) fonctionnel | 4 — NFR | B | B | BAS | Validation triviale au moment de l'implémentation. |
| CL-009 | FR-019 | "peut être conservée" sur ancienne API `AppShadows.colored(Color, alpha)` | 1 — Scope | B | M | BAS | Détail d'implémentation — décision tactique pendant le code (laisser ou supprimer l'ancienne API selon nombre d'usages observés). |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 9 |
| Catégories couvertes | 4/11 (1 — Scope, 4 — NFR, 6 — Edge cases, 7 — Contraintes, 9 — Signaux) |
| Résolus automatiquement | 4 (CL-001, CL-002, CL-003, CL-004) |
| Résolus interactivement | 1 (CL-005) |
| Différés | 4 (CL-006, CL-007, CL-008, CL-009) |
| Modifications spec.md | NC-1, NC-2, NC-3 supprimés ; FR-009, FR-010, FR-011, FR-015, FR-023 reformulés ; SC-010 reformulé ; SC-011 ajouté ; A7 confirmé ; section Open Questions remplacée par référence à ce fichier |
