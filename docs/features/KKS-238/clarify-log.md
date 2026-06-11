# Clarify Log — KKS-238 : Phase 1 / Étape 2 — Composants shared Flutter (8 widgets)

> Date : 2026-05-03 (initial), **2026-05-07 (audit comparatif Angular et révisions)**
> Issue : [KKS-238](https://linear.app/kksdev/issue/KKS-238/phase-1-etape-2-composants-shared-flutter-8-widgets)
> Spec : [spec.md](./spec.md)

---

## Note méthodologique — révision du 2026-05-07

La session de clarify du 2026-05-03 a résolu 5 points en automatique. À la relecture, **CL-002 a été identifié comme fondé sur des hypothèses non vérifiées** (capacités de `CalendarDatePicker` Material 3 supposées). Un **audit comparatif Angular** a été lancé sur les 8 composants sources avant de figer la spec.

Résultat de l'audit : 4 décisions corrigées (CL-002, CL-003, CL-004 justification, CL-005 résolu) + 3 écarts mineurs hors-CL corrigés directement dans la spec (EmptyState renommage params, VariationBadge texte vs pill, PageHeader titre flex-end + pas de trailing) + 1 nouveau point résolu (CL-007 typing `Category.id: String`).

L'audit complet est conservé dans la section « Audit comparatif Angular » de la spec.

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md §US-003 | Pattern technique pour `SectionHeaderSticky` | 7 — Contraintes | H | H | **CRITIQUE** | `SliverPersistentHeader(pinned: true)` (validé après audit) | Auto |
| CL-002 | spec.md §US-001 | `InlineDatePicker` — Material vs custom | 7 — Contraintes | H | H | **CRITIQUE** (révisé) | **Réimplémentation custom Flutter** (révision après audit Angular) | Auto + audit |
| CL-003 | spec.md §US-002 | `CategorySelectExpand` — dumb vs intégration Riverpod | 1 — Scope fonctionnel | H | H | **CRITIQUE** (révisé) | **Composite stateful avec embed `CategoryFormWidget`** — Option A alignée Angular (révision après audit) | Auto + audit + arbitrage utilisateur |
| CL-004 | spec.md §US-007 | `ConfirmDialogCustom` — service vs statique | 1 — Scope fonctionnel | M | B | **BAS** | Méthode statique `Future<bool>` uniquement. Justification corrigée : idiomatique Flutter `showDialog` (pas YAGNI Constitution comme initialement énoncé) | Auto + audit |
| CL-005 | spec.md §US-008 | `VariationBadge` à zéro : afficher ou masquer | 6 — Edge cases | M | M | **MOYEN** (était BAS, requalifié) | **Masqué** si `delta == 0 && percentage == null` (logique Angular `@if` exact) | Auto via audit |
| CL-006 | spec.md §FR-016 | Remplacement temporaire `SegmentedFilter` | 1 — Scope fonctionnel | M | B | **BAS** | `FilterChip` Material 3 + TODO KKS-240 | Auto |
| CL-007 | spec.md §FR-004 | `Category.id` typing Flutter : `int` ou `String` | 2 — Modèle de données | H | B | **HAUT** | **`String`** — confirmé dans `category.dart:9` (cohérent Angular) | Auto via vérification code |

## Résolutions détaillées

### CL-001 — Pattern technique `SectionHeaderSticky` (validé après audit)

- **Catégorie** : 7 — Contraintes (technique)
- **Score** : CRITIQUE
- **Contexte** : Le pattern Angular utilise `IntersectionObserver` sur un sentinel `.sticky-sentinel { height: 1px; }` placé juste avant le `<header class="section-header">`. État `isStuck` est un signal géré par chaque feature (debts, subscriptions, etc.).
- **Analyse** : Côté Flutter, deux mécanismes — `SliverPersistentHeader(pinned: true)` (natif slivers, expose `shrinkOffset` dans `delegate.build()`) ou `NotificationListener<ScrollNotification>` (capture position de scroll parent). La description Linear KKS-238 nomme explicitement `SliverPersistentHeader pinned`, et c'est le mécanisme natif Flutter pour ce pattern. Performance optimale (pas de rebuild parent à chaque scroll).
- **Décision** : `SliverPersistentHeader` avec `pinned: true`. Le delegate expose `(BuildContext, double shrinkOffset, bool overlapsContent)`. Bascule de fond `Colors.transparent` → `colorScheme.surfaceContainerHighest` quand `shrinkOffset > 0`, animée via `AnimatedContainer` (300 ms). Le composant Flutter sera plus consolidé que le pattern Angular (un seul widget vs SCSS+TS+HTML éclatés).
- **Impact sur spec.md** : retire le `[NEEDS CLARIFICATION]` US-003 ; clôt Q1 ; FR-007 cite `SliverPersistentHeader.pinned`.

### CL-002 — Stratégie `InlineDatePicker` (révisée — Material → custom)

- **Catégorie** : 7 — Contraintes (technique / dépendances)
- **Score** : CRITIQUE (était HAUT, requalifié après audit)
- **Contexte** : Le pattern Angular `<app-inline-date-picker>` est un calendrier custom 100%. Question initiale : suffit-il d'utiliser `CalendarDatePicker` Material 3 personnalisé, ou faut-il réimplémenter ?
- **Analyse initiale (2026-05-03 — incomplète)** : Constitution YAGNI + NFR-005 → favoriser `CalendarDatePicker` Material 3 + `DatePickerThemeData`. **Décision auto** sans vérification du composant Angular réel.
- **Audit (2026-05-07)** : lecture des fichiers `inline-date-picker.ts/.html/.scss` (~400 lignes total). Constatations bloquantes pour `CalendarDatePicker` Material :
  - Cellules **cercle complet** (`radius-round` 36×36px) — Material rend des carrés, non hackable via Theme.
  - Headers `L M M J V S D` (1 lettre) — format locale Material non customisable directement.
  - Tap sur label mois → `goToToday()` — Material ouvre un popup année/décennie, comportement non débrayable.
  - **Concept `originalValue`** — cellule de la date initiale en mode édition mise en valeur discrètement (`hover-subtle`) pour visualiser l'écart avec la nouvelle sélection. **Inexistant en Material**, impossible à reproduire via Theme.
  - Format date = ISO string (`'2026-05-06'`), pas `DateTime` — évite les dérives timezone, cohérent cross-stack.
- **Décision révisée** : **réimplémentation custom Flutter** (~300-400 lignes Dart). Charge équivalente au custom Angular. Pattern visuel et concept `originalValue` reproduits intégralement. Aucune dépendance package externe.
- **Impact sur spec.md** : refonte US-001 (acceptance scenarios + bloc « Décision technique » détaillé) ; FR-001/002/003 reformulés (`originalValue: String?`, format ISO, cercle 36×36, lundi-first hardcodé) ; clôt Q2.

### CL-003 — `CategorySelectExpand` composite stateful (révisé — dumb → embed)

- **Catégorie** : 1 — Scope fonctionnel (architecture composant)
- **Score** : CRITIQUE (était MOYEN, requalifié après audit + impact FR-019 nouveau)
- **Contexte** : Question initiale : dumb component (parent gère création) vs intégration Riverpod. La résolution initiale (2026-05-03) supposait dumb component aligné Angular.
- **Analyse initiale (incomplète)** : « le pattern Angular fait du dumb component ». **Faux** — vérification Angular non faite.
- **Audit (2026-05-07)** : lecture de `category-select.ts/.html` (262 lignes). Constatations :
  - Implémente `ControlValueAccessor` (s'intègre Reactive Forms via `formControlName`)
  - **Embed `<app-category-form>`** complet en mode `'create'` — pas dumb au sens strict
  - Outputs : `selected: string` (id), `created: Category` (objet complet retourné après save), `isCreating: boolean` (effect signal)
  - 2 modes internes : `'list'` / `'create'` (signal `mode`)
  - ViewChild pour `categoryForm()?.submit()` depuis le bouton header
  - Reset au `ngOnDestroy` : retour mode `'list'` si en mode `'create'`
  - Recherche conservée au retour mode création
- **Décision révisée — arbitrage utilisateur (2026-05-07)** : **Option A** (alignée Angular) — `CategorySelectExpand` est un `StatefulWidget` composite qui embed un `CategoryFormWidget` en mode `'create'`. **Cela impose l'extraction d'un `CategoryFormWidget` réutilisable** depuis `category_form_screen.dart` actuel (FR-019 nouveau).
- **Architecture Flutter** :
  - Inputs : `categories: List<Category>`, `selectedId: String?`, `searchPlaceholder: String?`
  - Outputs : `onSelected: ValueChanged<String>`, `onCreated: ValueChanged<Category>`, `onCreatingChanged: ValueChanged<bool>?`
  - 2 modes signal-like via `setState`
  - Reset à `dispose()`
- **Impact sur spec.md** : refonte US-002 (bloc « Décision technique » Option A) ; FR-004/005/006 reformulés ; **FR-019 nouveau** (extraction `CategoryFormWidget`) ; ajout entité `CategoryFormWidget` dans Key Entities ; A-003 ajusté (US-002 dépend de FR-019, les 7 autres sont parallélisables) ; clôt Q3.

### CL-004 — `ConfirmDialogCustom` méthode statique (justification corrigée)

- **Catégorie** : 1 — Scope fonctionnel (architecture composant)
- **Score** : BAS
- **Contexte** : Initialement résolu sur la base « YAGNI Constitution ». Justification questionnée à l'audit.
- **Analyse (audit 2026-05-07)** : le pattern Angular est un **composant overlay rendu globalement dans le shell**, piloté par `ConfirmService` signal-based, qui expose `confirm(): Promise<boolean>`. Avec gestion Escape, click outside, focus trap (`cdkTrapFocus`), `role="alertdialog"`. La raison **n'est pas YAGNI** : Angular doit recourir à un service global parce qu'il n'a pas d'équivalent natif simple à `showDialog`.
- **Décision validée** : Méthode statique `Future<bool>` uniquement. Justification **corrigée** : Flutter a `showDialog` natif qui empile une route modal au-dessus de tout — c'est l'équivalent idiomatique de l'overlay global Angular, géré par le `Navigator`. Pas besoin de service Riverpod : il n'apporte rien de plus.
- **Détails contractuels confirmés par l'audit** :
  - Icône en header 20px, titre H2
  - Boutons en pills compacts (pas Material `TextButton`)
  - Bouton Annuler avec icône **X** Phosphor 14px
  - Bouton Confirmer avec icône **Check** (variant `default`) ou **Trash** (variant `danger`) 14px
  - Escape → `false`, click outside → `false`
- **Impact sur spec.md** : FR-012 mis à jour avec la bonne justification ; FR-013 enrichi avec les icônes des boutons.

### CL-005 — `VariationBadge` à zéro (résolu via audit)

- **Catégorie** : 6 — Edge cases (mais avec impact API)
- **Score** : MOYEN (initialement BAS, requalifié car le verdict change la signature publique)
- **Contexte** : Cas zéro initialement différé (« afficher 0 € neutre ou masquer »).
- **Audit (2026-05-07)** : lecture de `dashboard.scss` (lignes 110-130) et `dashboard.html` (lignes 53-60). Constatations :
  - Pas un pill — texte `inline-flex` xs medium, **pas de fond**
  - Format complet : `+150,00 € ce mois (+12,5%)` — inclut **suffixe `'ce mois'`** et **pourcentage optionnel**
  - 3 états de couleur : `positive` (`text-success`), `negative` (`text-error`), `neutral` (`text-secondary` — **pas tertiary**)
  - Markup conditionnel : `@if (convertedNet() !== 0 || convertedVariationPct() !== null)` — **masqué si zéro ET pas de pourcentage**
- **Décision** : Le badge est **masqué** (`SizedBox.shrink()`) si `delta == 0 && percentage == null`. Sinon affiché en couleur appropriée. Cohérent avec la logique Angular exacte.
- **Impact sur spec.md** : refonte US-008 (« pill » → « texte coloré ») ; FR-014 enrichi avec `percentage: num?`, `suffix: String?` (défaut `'ce mois'`) et règle de masquage ; clôt Q5.

### CL-006 — Remplacement temporaire `SegmentedFilter`

- **Catégorie** : 1 — Scope fonctionnel (cleanup transversal)
- **Score** : BAS
- **Contexte** : `SegmentedFilter` utilisé par 2 écrans. Suppression actée Phase 0 (DESIGN.md anti-pattern). Mais suppression sèche = régression fonctionnelle des filtres.
- **Décision** : `Wrap` de `FilterChip` Material 3 standard avec commentaire `// TODO KKS-240 : remplacer par groupement + sections (DESIGN.md anti-pattern segmented control)`. Pas de régression, dette technique tracée. Refonte propre Étape 4.
- **Impact sur spec.md** : FR-016 reformulé.

### CL-007 — `Category.id` typing Flutter (nouveau, vérification code)

- **Catégorie** : 2 — Modèle de données
- **Score** : HAUT (Impact H sur signatures publiques de `CategorySelectExpand`, Incertitude B après vérification code)
- **Contexte** : Le `category-select.ts` Angular type `selected: output<string>` et le modèle `Category.id: string`. Mon FR-004 initial typait `selectedId: int?` — incohérent.
- **Analyse** : lecture de `flutter/lib/src/domain/models/category.dart` ligne 9 → `required String id`. Le typing Flutter est **déjà** `String`, cohérent avec Angular.
- **Décision** : `selectedId: String?`, `onSelected: ValueChanged<String>`, `onCreated: ValueChanged<Category>`. Aligné Flutter codebase + Angular.
- **Impact sur spec.md** : FR-004 corrigé ; Key Entities précise `id: String`.

## Points différés

> Aucun point différé après l'audit du 2026-05-07. Tous les points initialement différés (CL-005) ont été résolus via l'audit Angular.

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| — | — | — | — | — | — | — | (aucun) |

## Résumé

| Métrique | Valeur (initiale 2026-05-03) | Valeur (post-audit 2026-05-07) |
|----------|------------------------------|--------------------------------|
| Points identifiés | 6 | **7** (CL-007 ajouté via audit) |
| Catégories couvertes | 3/11 | **4/11** (Scope fonctionnel, Contraintes, Edge cases, Modèle de données) |
| Résolus automatiquement | 5 | **6** (CL-001/002/004/005/006/007) |
| Résolus interactivement (arbitrage utilisateur) | 0 | **1** (CL-003 — choix Option A) |
| Différés | 1 (CL-005) | **0** |
| Modifications spec.md | 9 zones (NEEDS CLARIFICATION + Q1-Q4/Q6 + FR-001 à FR-016 + NFR-004) | **+ 8 zones** (US-001/002/005/006/008 refondues, FR-001/004/006/010/011/014 reformulés, FR-019 ajouté, Key Entities enrichi, A-003 ajusté, section « Audit comparatif Angular » ajoutée) |
| Décisions corrigées par l'audit | — | **3** (CL-002 Material→custom, CL-003 dumb→composite, CL-004 justification YAGNI→idiomatique Flutter) |
