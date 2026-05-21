# Feature Specification: Récurrences liste Flutter (alignement DESIGN.md v5)

**Issue** : KKS-251 | **Parent** : KKS-242  
**Feature Branch** : `develop`  
**Créé** : 2026-05-21  
**Statut** : Draft  
**Priorité** : High (3pts)  
**Labels** : Feature

---

## Contexte

Source de vérité Angular : `app/src/app/features/transactions/components/recurring-list/recurring-list.html` + `recurring-list.scss` + `recurring-list.ts`.

Écran Flutter actuel : `recurring_list_screen.dart` (241L) + `recurring_list_item.dart` (230L) + `recurring_list_skeleton.dart`.

### Delta Angular → Flutter

| Élément | Angular | Flutter actuel | Action |
|---------|---------|---------------|--------|
| Icône catégorie | 36px cercle (radius-round) | 40px carré (radius-md) | Corriger |
| Interaction row | Tap → action sheet | LongPress → bottom sheet, Swipe → actions | Refondre |
| Sous-titre | `fréquence · date_relative` | Compte uniquement | Corriger |
| Montant | Coloré (expense/income) | Neutre | Corriger |
| Status badge | Absent (grouping visuel) | `_StatusBadge` inline | Supprimer |
| Swipe gestures | Absent | `Dismissible` (valider/passer) | Supprimer |
| Grouping visuel | Headers colorés par statut | Tri silencieux (pas de headers) | Ajouter |
| Carte groupe | `surface/radius-xl` + Divider | Plat sans conteneur | Ajouter |
| Bouton "Tout payé" | Header "EN RETARD" uniquement | Absent | Ajouter |
| Monthly summary | 2 lignes (net + charges) | Absent | Ajouter |
| Action sheet design | Summary + 3 boutons stylisés | ListTile basique | Refondre |
| Désactivation | 3ème bouton action sheet (direct) | AlertDialog confirm | Simplifier |
| État vide | `EmptyStateWidget` | Column custom | Remplacer |
| État erreur | `EmptyStateWidget` | Column custom | Remplacer |
| Skeleton count | 5 items (`Array(5)`) | 6 items | Aligner → 5 |

Hors scope : création de récurrences (formulaire KKS-241), conversion multi-devises (pas de ConversionService en Flutter — monthly summary en valeur nominale).

---

## User Scenarios & Testing

### User Story 1 — Transaction row aligné Angular (P1)

L'utilisateur ouvre l'écran Récurrences et voit chaque ligne avec une icône cercle 36px, le libellé, le sous-titre `fréquence · date_relative`, et le montant coloré à droite. Taper sur une ligne ouvre l'action sheet. Les swipe gestures et le badge statut disparaissent.

**Why this priority** : Cœur visuel de l'écran — chaque ligne diverge de l'Angular sur 5 points. Correction directe de la lisibilité (montant coloré) et de l'ergonomie (tap vs longPress, plus découvrable).

**Independent Test** : Ouvrir l'écran Récurrences avec des données → vérifier qu'une ligne affiche icône cercle 36px, libellé (`sizeSm/medium`), sous-titre (`fréquence · dans X j.`, `sizeXs/onSurfaceVariant`), montant coloré. Taper une ligne → action sheet s'ouvre. Aucun badge statut visible. Swipe → aucune action.

**Acceptance Scenarios** :

1. **Given** l'écran affiche une récurrence active, **When** la ligne s'affiche, **Then** : icône emoji catégorie dans cercle 36px (fond couleur catégorie avec `26` alpha, ou `iconCircleBg` si pas de couleur), libellé en `sizeSm/medium/onSurfaceVariant`, sous-titre `"fréquence · date_relative"` en `sizeXs/onSurfaceVariant`.
2. **Given** une récurrence est une DÉPENSE, **When** son montant s'affiche, **Then** il s'affiche en `expenseColor`. Si c'est une RECETTE → `incomeColor`.
3. **Given** l'utilisateur tape sur une ligne, **When** le tap se déclenche, **Then** l'action sheet de cette récurrence s'ouvre via `showModalBottomSheet`. Le tap sur la ligne (pas longPress).
4. **Given** l'utilisateur tente un swipe sur une ligne, **When** le geste se déclenche, **Then** aucune action ne se produit. Le `Dismissible` est supprimé.
5. **Given** une récurrence est en retard, **When** sa ligne s'affiche, **Then** aucun badge `_StatusBadge` n'apparaît dans la ligne (le statut est indiqué par le header de groupe, FR-006).

---

### User Story 2 — Groupes visuels par statut et monthly summary (P2)

L'utilisateur voit les récurrences regroupées visuellement par statut ("EN RETARD", "AUJOURD'HUI", "À VENIR") avec des headers colorés, chaque groupe dans une carte arrondie. Une monthly summary card au sommet de la liste synthétise le bilan net et les charges. Le groupe "EN RETARD" a un bouton "Tout payé".

**Why this priority** : Le grouping visuel est la différence la plus structurante vs l'Angular. La monthly summary donne le contexte financier immédiat. Ces deux éléments ensemble constituent la valeur principale de l'écran.

**Independent Test** : Charger des récurrences dans les 3 statuts → vérifier les 3 headers colorés, les cartes de groupe, les Dividers. Vérifier la monthly summary au-dessus de la liste. Vérifier le bouton "Tout payé" uniquement sur "EN RETARD".

**Acceptance Scenarios** :

1. **Given** des récurrences existent dans plusieurs statuts, **When** l'écran s'affiche, **Then** les headers de groupe apparaissent dans l'ordre : "EN RETARD" (`expenseColor`), "AUJOURD'HUI" (`colorScheme.primary`), "À VENIR" (`onSurfaceVariant`). Chaque header : `sizeXs/semiBold/uppercase/letterSpacing`.
2. **Given** un groupe de récurrences est affiché, **When** la carte s'affiche, **Then** le groupe est dans un `Container(color: surface, radius: xl, Clip.antiAlias)` avec `Divider(outlineVariant)` entre les items.
3. **Given** le groupe "EN RETARD" est affiché, **When** le header apparaît, **Then** un bouton "Tout payé" est visible à droite (`radius-round`, fond `colorScheme.primary`, text blanc, `sizeXs/semiBold`). Ce bouton n'apparaît pas sur les autres groupes.
4. **Given** des récurrences actives sont chargées, **When** la monthly summary s'affiche, **Then** elle montre : ligne 1 "BILAN MENSUEL" (uppercase, sizeXs, text-tertiary) + montant net (`+X.XX €` en `incomeColor` ou `-X.XX €` en `expenseColor`), ligne 2 "N CHARGES" + "~X.XX €/mois". Les montants sont convertis en devise primaire via `CurrencyConverter.convert()` + `exchangeRateListProvider` (aligne sur Angular `ConversionService`). Si le taux est absent, fallback en valeur nominale.
5. **Given** un statut n'a aucune récurrence, **When** l'écran s'affiche, **Then** le header et la carte de ce groupe n'apparaissent pas.

---

### User Story 3 — Action sheet design aligné Angular (P3)

L'utilisateur tape une récurrence → un bottom sheet s'ouvre avec un résumé (fréquence, montant, date prochaine) et 3 boutons stylisés (Marquer payée en primary, Passer occurrence en neutre, Désactiver en danger text). La désactivation n'ouvre plus d'`AlertDialog` de confirmation.

**Why this priority** : Amélioration UX du flux d'action, non bloquante. US1 + US2 livrent de la valeur sans cette US.

**Independent Test** : Taper une ligne → vérifier le résumé dans le bottom sheet (fréquence uppercase, montant bold large, "Prochaine : X"). Taper "Désactiver" → la récurrence est désactivée directement (pas de dialog).

**Acceptance Scenarios** :

1. **Given** l'utilisateur tape une ligne, **When** le bottom sheet s'ouvre, **Then** il affiche : fréquence en uppercase (`sizeXs`, `onSurfaceVariant`, letterspacing), montant en `sizeXl/bold` (coloré expense/income), "Prochaine : {date_relative}" en `sizeXs/onSurfaceVariant`.
2. **Given** l'action sheet est ouverte, **When** l'utilisateur tape "Marquer comme payée", **Then** `validate(id)` est appelé, le bottom sheet se ferme, un SnackBar confirme (`recurringValidateSuccess`).
3. **Given** l'action sheet est ouverte, **When** l'utilisateur tape "Passer cette occurrence", **Then** `skip(id)` est appelé, le bottom sheet se ferme, un SnackBar confirme (`recurringSkipSuccess`).
4. **Given** l'action sheet est ouverte, **When** l'utilisateur tape "Désactiver la récurrence", **Then** `deactivate(id)` est appelé directement (sans `AlertDialog`), le bottom sheet se ferme, un SnackBar confirme (`recurringDeactivateSuccess`). L'`AlertDialog` existant est supprimé.
5. **Given** une action est en cours (`mutatingIds`), **When** les boutons s'affichent, **Then** tous les boutons sont désactivés (`onPressed: null`) et un indicateur de chargement remplace le contenu du bouton actif.

---

### Edge Cases

- Que se passe-t-il si "Tout payé" est tapé alors qu'aucune récurrence n'est en retard ? Le bouton n'est pas affiché (FR-009 : affiché uniquement si le groupe "EN RETARD" existe).
- Que se passe-t-il si `validate(id)` échoue dans un `validateAll` ? Arrêt au premier échec (aligne sur Angular `try/catch` global) — les items déjà validés le restent, un SnackBar d'erreur s'affiche.
- Que se passe-t-il si la liste est vide après un `validateAll` ? L'état empty s'affiche normalement.
- Que se passe-t-il si `nextOccurrence` est dans le passé depuis plusieurs semaines ? La date relative affiche "il y a X j." selon la même logique que Angular.

---

## Requirements

### Functional Requirements

#### US1 — Transaction row

- **FR-001** : `RecurringListItem` doit afficher l'icône catégorie dans un **cercle de 36px** (`borderRadius: AppRadius.round`). Fond : couleur catégorie avec alpha `0x26` si disponible, sinon `AppThemeExtension.iconCircleBg`.
- **FR-002** : Le tap sur une ligne appelle un callback `onTap` fourni par le screen. Suppression de `Dismissible`, `GestureDetector.onLongPress`, `_SwipeBackground`.
- **FR-003** : Le sous-titre affiche `"${frequencyLabel} · ${RelativeDateFormatter.formatCompact(nextOccurrence)}"` en `sizeXs/onSurfaceVariant`. Utiliser `RelativeDateFormatter.formatCompact()` défini dans `lib/src/utils/relative_date_formatter.dart` (voir NFR-002). Ne pas créer de fichier `date_formatter.dart` séparé.
- **FR-004** : Le montant s'affiche en `AppThemeExtension.expenseColor` si `type == TransactionType.depense`, en `AppThemeExtension.incomeColor` si `type == TransactionType.recette`.
- **FR-005** : Supprimer `_StatusBadge`, `_SwipeBackground`, `Dismissible` du widget. Supprimer les imports `AppColors` devenus inutiles.

#### US2 — Grouping visuel + monthly summary

- **FR-006** : `RecurringListScreen` affiche un header de groupe avant chaque carte. Libellé : `l10n.recurringOverdue` / `l10n.recurringToday` / `l10n.recurringUpcoming` en `sizeXs/semiBold/uppercase/letterSpacing: AppTypography.labelLetterSpacingForSize12`.
- **FR-007** : Couleurs des headers : overdue → `AppThemeExtension.expenseColor`, today → `colorScheme.primary`, upcoming → `colorScheme.onSurfaceVariant`.
- **FR-008** : Chaque groupe est dans un `Container(color: colorScheme.surface, radius: AppRadius.xl, clipBehavior: Clip.antiAlias)` avec `Divider(height:1, thickness:1, color: colorScheme.outlineVariant)` entre les items.
- **FR-009** : Le header du groupe `overdue` affiche à droite un bouton "Tout payé" (`AppRadius.round`, fond `colorScheme.primary`, text `onPrimary`, `sizeXs/semiBold`). Il appelle `validateAll(overdue_ids)` sur le notifier.
- **FR-010** : `RecurringListScreen` affiche en haut de la liste (avant les groupes) une monthly summary card avec : ligne 1 — "BILAN MENSUEL" + montant net formaté (`+X.XX €` en `incomeColor` si net ≥ 0, `-X.XX €` en `expenseColor` si net < 0, toujours 2 décimales), ligne 2 — "{N} CHARGES" + "~{totalExpenses} €/mois". Le calcul normalise les montants en mensuel (`hebdo × 4.33`, `annuel ÷ 12`) puis convertit en devise primaire via `CurrencyConverter.convert()` + `ref.watch(exchangeRateListProvider).items` (aligne sur Angular). Si taux absent → fallback valeur nominale. La summary s'affiche toujours quand la liste n'est pas vide (y compris si `expenseCount = 0`).

#### US3 — Action sheet

- **FR-011** : L'action sheet (via `showModalBottomSheet`) affiche un bloc résumé : fréquence en uppercase (`sizeXs`, `onSurfaceVariant`, `letterSpacing`), montant en `sizeXl/bold` (coloré expense/income), "Prochaine : {date_relative}" en `sizeXs/onSurfaceVariant`.
- **FR-012** : L'action sheet affiche 3 boutons pleine largeur stylisés avec icônes `PhosphorIcon(size: 20)` : "Marquer comme payée" (fond `primary`, text `onPrimary`, icône `check`), "Passer cette occurrence" (fond `surfaceContainerHighest`, text `onSurface`, icône `skipForward`), "Désactiver la récurrence" (fond `surfaceContainerHighest`, text `expenseColor`, icône `pause` — Flutter actuel utilise `.x`, à corriger).
- **FR-013** : Supprimer `_showDeactivateConfirm` et son `AlertDialog`. "Désactiver" appelle directement `deactivate(id)`.

#### Communs

- **FR-014** : État vide → `EmptyStateWidget(icon: PhosphorIconsRegular.repeat, message: l10n.recurringEmpty)` sans CTA (pas de création depuis cet écran).
- **FR-015** : État erreur → `EmptyStateWidget(icon: PhosphorIconsRegular.warning, message: l10n.errorGeneric, ctaLabel: l10n.retry, onCtaTap: loadItems)`.
- **FR-016** : `RecurringListSkeleton` : 6 → 5 items (aligne sur `Array(5)` Angular). Icône : 40px carré → 36px cercle (`borderRadius: AppRadius.round`). Côté droit : supprimer le placeholder badge-round (60px), conserver uniquement un placeholder montant (80px, `AppRadius.sm`) — aligne sur la nouvelle structure de ligne sans `_StatusBadge`.

### Non-Functional Requirements

- **NFR-001** : Ajouter `validateAll(List<String> ids)` dans `RecurringListNotifier` — appels séquentiels à `validate(id)` (aligne sur Angular `for...of` + `await`). Comportement en cas d'échec : arrêt au premier échec (try/catch global, aligne Angular). SnackBar succès : `"${ids.length} transaction${ids.length > 1 ? 's' : ''} validée${ids.length > 1 ? 's' : ''}"`. SnackBar erreur : `l10n.errorGeneric`. Aucune modification de `RecurringTransactionRepository` ni des couches data.
- **NFR-002** : Étendre `lib/src/utils/relative_date_formatter.dart` — ajouter `RelativeDateFormatter.formatCompact(DateTime)` aligné sur Angular : aujourd'hui → `"aujourd'hui"`, hier → `"hier"`, demain → `"demain"` (délègue à `format()`), passé 2-7j → `"il y a X j."`, futur 2-30j → `"dans X j."`, futur > 30j → `DateFormat('dd MMM', 'fr').format(date)`. Ne pas créer de nouveau fichier (Constitution Principe III YAGNI).
- **NFR-003** : Aucune modification de `RecurringTransactionRepository`, du domain model, des DTOs.
- **NFR-004** : Les tests existants (`recurring_list_screen_test.dart`, `recurring_list_notifier_test.dart`) doivent être adaptés. Nouveaux tests : `_StatusGroupHeader`, `_MonthlySummaryCard`, `validateAll`.
- **NFR-005** : Le bottom sheet d'actions est géré dans `RecurringListScreen` (accès direct à `ref`), pas dans `RecurringListItem`. `RecurringListItem` expose uniquement `onTap: VoidCallback`. Pattern confirmé par le codebase : tous les `showModalBottomSheet` avec actions métier sont dans les screens (cf. `subscription_list_screen`, `debt_list_screen`, `users_screen`).
- **NFR-006** : `validateAll` — état "in progress" via id fictif `'__all__'` ajouté à `mutatingIds` (option retenue). Pas de breaking change sur `ListState<T>`, cohérent avec le pattern `mutatingIds` existant. Le screen vérifie `mutatingIds.contains('__all__')` pour désactiver le bouton "Tout payé" pendant l'opération. Angular équivalent : `actionInProgress.set('all')`.

### Key Entities

- **RecurringTransaction** : entité existante, aucune modification. Champs utilisés : `id`, `libelle`, `montant`, `type`, `frequency`, `nextOccurrence`, `categoryIcon`, `categoryColor`, `status` (computed), `accountCurrency` (`Currency?`, nullable — si null, fallback valeur nominale dans monthly summary).
- **RecurringStatus** : enum existant (`overdue`, `today`, `upcoming`), aucune modification.

---

## Success Criteria

### Measurable Outcomes

- **SC-001** : Chaque ligne affiche icône cercle 36px, sous-titre `fréquence · date_relative`, montant coloré — vérifiable visuellement.
- **SC-002** : Tap sur une ligne → action sheet s'ouvre en < 300ms. Aucun swipe accidentel ne déclenche d'action.
- **SC-003** : Les headers de groupe apparaissent avec la bonne couleur pour chaque statut. Les groupes absents (0 items) ne génèrent pas de header.
- **SC-004** : La monthly summary affiche le bon NET (somme normalisée en mensuel, RECETTES - DEPENSES).
- **SC-005** : "Tout payé" valide toutes les récurrences overdue et le groupe disparaît ensuite.
- **SC-006** : Désactiver depuis l'action sheet ne déclenche pas d'AlertDialog.
- **SC-007** : 100% des tests existants PASS après adaptation.

---

## Assumptions

- **ASS-001** : ~~Flutter n'implémente pas la conversion multi-devises dans la monthly summary.~~ **Invalidée (Q-001 résolu)** : Flutter dispose de `CurrencyConverter` + `exchangeRateListProvider`, déjà utilisés dans `subscription_list_screen` et `debt_list_screen`. La monthly summary utilise la conversion comme Angular.
- **ASS-002** : Il n'existe pas d'endpoint API bulk pour `validateAll`. Les appels sont séquentiels. Si l'API déploie un endpoint `/bulk-validate` dans le futur, le notifier peut être mis à jour.
- **ASS-003** : La suppression de `Dismissible` (swipe gestures) est voulue pour s'aligner sur le paradigme Angular (tap → action sheet). Aucun utilisateur ne sera notifié de ce changement de paradigme.
- **ASS-004** : Le `showModalBottomSheet` standard de Flutter est suffisant pour l'action sheet — pas besoin de `DraggableScrollableSheet` (contenu fixe, 3 boutons).

---

## Questions ouvertes

| # | Question | Statut | Réponse |
|---|----------|--------|---------|
| Q-001 | Monthly summary : ignorer la conversion multi-devises et afficher en valeur nominale ? | Résolu | Non — aligner sur Angular. Flutter a `CurrencyConverter` + `exchangeRateListProvider`. Utiliser conversion, fallback valeur nominale si taux absent. |
| Q-002 | `validateAll` : arrêter au premier échec ou continuer et afficher le nombre d'erreurs ? | Résolu | Arrêt au 1er échec — aligne Angular (`for...of` dans `try/catch` global) |
| Q-003 | `date_formatter.dart` : nouveau fichier ou extension de `RelativeDateFormatter` existant ? | Résolu | Étendre `RelativeDateFormatter` — ajouter `formatCompact()`. YAGNI, pas de nouveau fichier. |
| Q-004 | Bottom sheet d'actions : géré dans `RecurringListScreen` (accès `ref`) ou dans `RecurringListItem` ? | Résolu | Dans `RecurringListScreen`. Pattern codebase Flutter confirmé. `RecurringListItem` → `onTap: VoidCallback` uniquement. |
| Q-005 | `validateAll` état "in progress" : id fictif `'__all__'` dans `mutatingIds`, bool `isValidatingAll` dans `ListState`, ou état local screen ? | Résolu | Id fictif `'__all__'` dans `mutatingIds`. Pas de breaking change, cohérent avec le pattern. |
