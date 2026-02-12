# Tasks: Écran Subscriptions (liste + filtre actif)

**Input**: Design documents from `/specs/013-subscription-list/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Tests unitaires Vitest requis (constitution V. Testabilité).

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

## Path Conventions

- **Frontend**: `app/src/app/features/subscriptions/`
- **Services existants**: `app/src/app/core/services/subscription.ts`
- **Composants partagés**: `app/src/app/shared/`

---

## Phase 1: Setup

**Purpose**: Pas d'initialisation nécessaire — le projet, les services et les composants partagés existent déjà.

*Phase vide — passer directement à Phase 2.*

---

## Phase 2: Foundational (Composant de base)

**Purpose**: Mettre en place la structure du composant Subscriptions avec les imports, signals et le mécanisme de chargement de données.

- [x] T001 Implémenter le composant Subscriptions avec les imports, signals (subscriptions, loading, error, statusFilter), effect réactif sur refreshTrigger + statusFilter, et méthode async loadData() utilisant `firstValueFrom()` (pas de subscribe() manuel — convention projet). L'effect DOIT écouter `refreshTrigger` du SubscriptionService pour couvrir FR-010 (refresh auto après CRUD). Dans `app/src/app/features/subscriptions/subscriptions.ts`
- [x] T002 Ajouter les helpers et computed signals dans le composant : `getNextRenewalDate(subscription)` (calcul prochaine date depuis dateDebut + frequence), `formatAmount(subscription)` (montant combiné avec fréquence ex: "24,90 €/mois"), `monthlyTotal` (computed : total mensuel des actifs, annuels / 12), `sortedSubscriptions` (computed : tri alphabétique par nom) dans `app/src/app/features/subscriptions/subscriptions.ts`

**Checkpoint**: Le composant charge les données depuis l'API et expose les signals nécessaires.

---

## Phase 3: User Story 1 - Consulter ses abonnements (Priority: P1) MVP

**Goal**: L'utilisateur voit la liste de tous ses abonnements avec nom, montant/fréquence, date de renouvellement, résumé total mensuel et badge "Inactif".

**Independent Test**: Naviguer vers `/subscriptions`, vérifier que les abonnements s'affichent avec toutes les informations, le résumé total mensuel est visible, et les abonnements inactifs ont un badge.

### Implementation for User Story 1

- [x] T003 [P] [US1] Implémenter le template : section résumé total mensuel (affiché si au moins 1 actif) + liste des abonnements triés par nom avec `<app-list-item>` pour chaque élément (icon="🔄", title=nom, value=formatAmount(), subtitle="Renouvellement: {date}" formatée via `Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long' })` — ne PAS utiliser RelativeDatePipe). Le badge "Inactif" est un `<span class="badge-inactive">` positionné dans un wrapper `<div>` autour de chaque `<app-list-item>` (le composant ListItem n'a pas d'input badge). Dans `app/src/app/features/subscriptions/subscriptions.html`
- [x] T004 [P] [US1] Implémenter les styles : résumé total mensuel (carte centrée), liste d'abonnements (ul sans style, bordures entre items), badge "Inactif" (`.badge-inactive` : position absolute en haut-droite du wrapper item, petit label avec `var(--bg-error)` et `var(--text-inverse)`, font-size petit, border-radius), états visuels interactifs hover/focus sur chaque item (FR-011 : pas d'action au clic, visuel seulement) dans `app/src/app/features/subscriptions/subscriptions.scss`

**Checkpoint**: L'écran affiche la liste complète des abonnements avec résumé et badge. Fonctionnel et testable.

---

## Phase 4: User Story 2 - Filtrer les abonnements par statut (Priority: P2)

**Goal**: L'utilisateur peut filtrer par Tous / Actifs / Inactifs via un toggle.

**Independent Test**: Cliquer sur chaque option du filtre et vérifier que seuls les abonnements correspondants sont affichés.

### Implementation for User Story 2

- [x] T005 [US2] Ajouter le toggle filtre (Tous / Actifs / Inactifs) dans le template, avec appel à `setStatusFilter()` et classe `.active` sur le bouton sélectionné dans `app/src/app/features/subscriptions/subscriptions.html`
- [x] T006 [US2] Ajouter les styles du toggle filtre (même pattern que `.type-filter` de Transactions : bordure, flex, bouton actif avec couleur primaire) dans `app/src/app/features/subscriptions/subscriptions.scss`
- [x] T007 [US2] Ajouter la méthode `setStatusFilter(filter)` dans le composant, qui met à jour le signal `statusFilter` (l'effect réactif de T001 relance automatiquement `loadData()` avec le paramètre `actif` correspondant) dans `app/src/app/features/subscriptions/subscriptions.ts`

**Checkpoint**: Le filtre fonctionne et la liste se met à jour côté serveur.

---

## Phase 5: User Story 3 - Gérer les états de chargement et d'erreur (Priority: P3)

**Goal**: L'écran affiche correctement les états loading (spinner), error (message + retry), et empty ("Aucun abonnement").

**Independent Test**: Simuler chaque état et vérifier l'affichage correspondant.

### Implementation for User Story 3

- [x] T008 [US3] Ajouter les blocs conditionnels @if/@else pour les 3 états (loading → spinner, error → message + bouton Réessayer, empty → "Aucun abonnement") dans `app/src/app/features/subscriptions/subscriptions.html`
- [x] T009 [US3] Ajouter les styles des états (`.state-loading` avec spinner animé, `.state-error`, `.state-empty` — même pattern que Transactions) dans `app/src/app/features/subscriptions/subscriptions.scss`

**Checkpoint**: Tous les états s'affichent correctement. L'écran est complet.

---

## Phase 6: Tests unitaires

**Purpose**: Valider la logique métier du composant via tests Vitest (constitution V. Testabilité).

- [x] T010 [P] Créer le fichier de test `app/src/app/features/subscriptions/subscriptions.spec.ts` avec setup TestBed (BrowserTestingModule, platformBrowserTesting, mock SubscriptionService) et tester les computed signals : `monthlyTotal` (should_compute_monthly_total_with_mixed_frequencies, should_return_zero_when_no_active_subscriptions, should_divide_annual_by_12), `sortedSubscriptions` (should_sort_alphabetically_by_name)
- [x] T011 [P] Tester les helpers dans `subscriptions.spec.ts` : `getNextRenewalDate` (should_return_next_date_for_monthly, should_return_next_date_for_annual, should_handle_future_start_date), `formatAmount` (should_format_monthly, should_format_annual)
- [x] T012 Tester le comportement réactif dans `subscriptions.spec.ts` : should_reload_data_when_filter_changes, should_set_loading_true_during_load, should_set_error_on_api_failure, should_reload_on_refreshTrigger_change

**Checkpoint**: Tous les tests passent avec `cd app && npx vitest run`.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et vérifications transversales.

- [x] T013 Vérifier que la liste se rafraîchit après ajout/modification/suppression via la modal (tester le flow FAB → modal → sauvegarde → liste mise à jour). Le `refreshTrigger` du SubscriptionService est déjà câblé (create/update/delete appellent `refresh()`).
- [x] T014 Exécuter `cd app && ng lint` et `cd app && npm run format` pour vérifier conformité ESLint + Prettier dans `app/src/app/features/subscriptions/`
- [x] T015 Valider le quickstart.md : exécuter les 6 vérifications listées dans `specs/013-subscription-list/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Vide — pas de setup nécessaire
- **Phase 2 (Foundational)**: Pas de dépendance — peut démarrer immédiatement
- **Phase 3 (US1)**: Dépend de Phase 2 (composant de base avec signals et loadData)
- **Phase 4 (US2)**: Dépend de Phase 2 (composant de base). Peut être fait en parallèle avec US1 mais touche les mêmes fichiers.
- **Phase 5 (US3)**: Dépend de Phase 2 (composant de base). Peut être fait en parallèle avec US1 mais touche les mêmes fichiers.
- **Phase 6 (Tests)**: Dépend de Phase 2 (composant de base). Peut démarrer après Phase 2, en parallèle conceptuel avec US1-US3 mais nécessite le .ts final.
- **Phase 7 (Polish)**: Dépend de toutes les phases précédentes complètes

### User Story Dependencies

- **US1 (P1)**: Dépend de Phase 2 — Pas de dépendance sur d'autres stories
- **US2 (P2)**: Dépend de Phase 2 — Indépendant de US1 fonctionnellement, mais partage les mêmes fichiers
- **US3 (P3)**: Dépend de Phase 2 — Indépendant de US1/US2 fonctionnellement, mais partage les mêmes fichiers

### Within Each User Story

- Template (.html) et styles (.scss) peuvent être faits en parallèle [P]
- La logique composant (.ts) doit être en place avant le template

### Parallel Opportunities

- T003 et T004 peuvent être faits en parallèle (template + styles US1)
- T008 et T009 peuvent être faits en parallèle (template + styles US3)
- T010 et T011 peuvent être faits en parallèle (tests computed + tests helpers)

---

## Parallel Example: User Story 1

```bash
# Lancer template et styles en parallèle :
Task: "Implémenter le template liste + résumé dans subscriptions.html"
Task: "Implémenter les styles liste + résumé dans subscriptions.scss"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 2 : Composant de base (T001, T002)
2. Compléter Phase 3 : User Story 1 (T003, T004)
3. **STOP et VALIDER** : L'écran affiche la liste avec résumé et badge
4. Démo possible dès ce point

### Incremental Delivery

1. Phase 2 → Foundation prête
2. US1 (Phase 3) → Liste affichée avec résumé → MVP
3. US2 (Phase 4) → Filtre ajouté → Écran enrichi
4. US3 (Phase 5) → États loading/error/empty → Écran complet
5. Phase 6 → Tests unitaires (T010-T012)
6. Phase 7 → Polish, lint, validation

---

## Notes

- Feature purement frontend : 3 fichiers à modifier (`subscriptions.ts`, `.html`, `.scss`) + 1 fichier de test à créer (`subscriptions.spec.ts`)
- Pattern de référence : écran Transactions (`features/transactions/`)
- 1 nouveau fichier à créer (spec.ts), aucune dépendance à installer
- Commit recommandé après chaque phase complète
