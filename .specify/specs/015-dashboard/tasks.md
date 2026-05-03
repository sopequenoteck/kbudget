# Tasks: Écran Dashboard

**Input**: Design documents from `/specs/015-dashboard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Non demandés dans la spec. Aucune tâche de test générée.

**Organization**: Tasks groupées par user story pour une implémentation et un test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup

**Purpose**: Aucun setup nécessaire — le composant Dashboard existe déjà (vide), les routes sont configurées, les services et composants partagés sont en place.

*(Pas de tâche dans cette phase)*

---

## Phase 2: Foundational (Prérequis bloquants)

**Purpose**: Modifier le Shell pour exposer les méthodes d'édition nécessaires au Dashboard et aux futurs écrans.

- [x] T001 Ajouter les méthodes `openEditTransaction(t: Transaction)`, `openEditSubscription(s: Subscription)`, `openEditDebt(d: Debt)` sur le Shell dans `app/src/app/shared/components/shell/shell.ts`. Chaque méthode doit setter le signal `editing*` correspondant et `activeModal` au bon type. Pattern : réutiliser la logique existante de `onSpeedDialAction` + setter l'entité en édition.

**Checkpoint**: Le Shell expose 3 méthodes publiques d'édition. Les user stories peuvent commencer.

---

## Phase 3: User Story 1 — Bilan mensuel (Priority: P1) MVP

**Goal**: L'utilisateur voit 3 cartes financières (Recettes/Dépenses/Solde) avec un sélecteur de mois.

**Independent Test**: Ouvrir /dashboard, vérifier les 3 cartes avec les montants du mois en cours, naviguer entre les mois.

### Implementation for User Story 1

- [x] T002 [US1] Implémenter le composant Dashboard dans `app/src/app/features/dashboard/dashboard.ts` : injecter TransactionService, ajouter les signals `selectedMonth`, `selectedYear`, `summaryLoading`, `summaryError`, `summary` (MonthlySummary | null), le computed `selectedMonthLabel`, les méthodes `prevMonth()`, `nextMonth()`, `loadSummary()`, et un effect() qui déclenche loadSummary quand month/year/refreshTrigger changent. Pattern : reproduire le pattern de `transactions.ts` (signals, effect, subscribe).
- [x] T003 [US1] Créer le template dans `app/src/app/features/dashboard/dashboard.html` : section `.month-selector` (boutons ◀/▶ + label mois), section `.summary` avec 3 cartes (Recettes vert via AmountPipe 'RECETTE', Dépenses rouge via AmountPipe 'DEPENSE', Solde avec ngClass conditionnel). Ajouter les états loading (spinner), error (message + bouton Réessayer) et empty (cartes à 0,00 EUR) pour la section bilan. Pattern : reproduire le HTML de `transactions.html` lignes 1-24.
- [x] T004 [P] [US1] Créer les styles dans `app/src/app/features/dashboard/dashboard.scss` : classes `.month-selector`, `.month-selector__btn`, `.month-selector__label`, `.summary`, `.summary__card`, `.summary__card--income`, `.summary__card--expense`, `.summary__card--balance`, `.summary__label`, `.summary__value`, `.state-loading`, `.state-error`, `.state-empty`, `.spinner`. Utiliser les tokens design system (`--space-*`, `--surface-raised`, `--color-income`, `--color-expense`, `--border-default`, `--radius-md`). Pattern : reproduire le SCSS de `transactions.scss`.

**Checkpoint**: Le bilan mensuel s'affiche avec navigation entre mois. MVP fonctionnel.

---

## Phase 4: User Story 2 — Aperçu transactions (Priority: P2)

**Goal**: L'utilisateur voit les 5 dernières transactions avec "Voir tout" et édition au clic.

**Independent Test**: Vérifier que les 5 transactions récentes apparaissent, que "Voir tout" navigue vers /transactions, et que le clic ouvre la modale d'édition.

### Implementation for User Story 2

- [x] T005 [US2] Étendre le composant Dashboard dans `app/src/app/features/dashboard/dashboard.ts` : injecter Shell (parent) via `inject(Shell)`, ajouter les signals `transactionsLoading`, `transactionsError`, `transactions` (Transaction[]), le computed `recentTransactions` (tri date DESC, slice 0-5), la méthode `loadTransactions()` appelée depuis un effect() réagissant au refreshTrigger du TransactionService, la méthode `onTransactionClick(t: Transaction)` qui appelle `shell.openEditTransaction(t)`. Ajouter les imports : ListItem, AmountPipe, RelativeDatePipe, RouterLink, NgClass.
- [x] T006 [US2] Étendre le template `app/src/app/features/dashboard/dashboard.html` : ajouter section "Dernières transactions" avec header (titre "Dernières transactions" + lien routerLink="/transactions" "Voir tout"), états loading/error/empty indépendants, liste `<ul>` avec `@for` sur `recentTransactions()` rendant `<app-list-item>` avec [icon] (catégorie ou emoji par défaut), [title] (libellé), [value] (montant | amount: type), [subtitle] (catégorie.nom), [rightSubtitle] (date | relativeDate), [valueClass] (amount-income/amount-expense selon type), (pressed)="onTransactionClick(transaction)".
- [x] T007 [P] [US2] Étendre les styles `app/src/app/features/dashboard/dashboard.scss` : ajouter classes `.dashboard-section`, `.dashboard-section__header` (flexbox, justify-content space-between, align-items center), `.dashboard-section__title` (font-size lg, semibold), `.dashboard-section__link` (color primary, font-size sm), `.dashboard-list` (list-style none, padding 0, `li:not(:last-child)` border-bottom). Ces classes sont réutilisées par US3 et US4.

**Checkpoint**: Les 5 transactions récentes apparaissent, "Voir tout" et édition au clic fonctionnent.

---

## Phase 5: User Story 3 — Aperçu abonnements (Priority: P3)

**Goal**: L'utilisateur voit 3 abonnements actifs avec total mensuel, "Voir tout" et édition au clic.

**Independent Test**: Vérifier l'affichage de 3 abonnements, le total mensuel (conversion annuel/12), la navigation et l'édition.

### Implementation for User Story 3

- [x] T008 [US3] Étendre le composant Dashboard dans `app/src/app/features/dashboard/dashboard.ts` : injecter SubscriptionService, ajouter les signals `subscriptionsLoading`, `subscriptionsError`, `subscriptions` (Subscription[]), les computed `activeSubscriptions` (tri nom ASC, slice 0-3), `monthlySubTotal` (somme : mensuel tel quel + annuel/12), la méthode `loadSubscriptions()` appelée depuis un effect() réagissant au refreshTrigger du SubscriptionService, la méthode `onSubscriptionClick(s: Subscription)` qui appelle `shell.openEditSubscription(s)`.
- [x] T009 [US3] Étendre le template `app/src/app/features/dashboard/dashboard.html` : ajouter section "Abonnements actifs" avec header (titre + lien routerLink="/subscriptions"), sous-header affichant le total mensuel formaté (monthlySubTotal | amount), états loading/error/empty, liste `<app-list-item>` avec [icon] (emoji 🔄), [title] (nom), [value] (montant | amount), [subtitle] (fréquence : "Mensuel" ou "Annuel"), (pressed)="onSubscriptionClick(subscription)".

**Checkpoint**: Les 3 abonnements actifs s'affichent avec total mensuel, navigation et édition fonctionnent.

---

## Phase 6: User Story 4 — Aperçu dettes (Priority: P3)

**Goal**: L'utilisateur voit 3 dettes en cours avec résumé je dois/on me doit, "Voir tout" et édition au clic.

**Independent Test**: Vérifier l'affichage de 3 dettes, les totaux par sens, la navigation et l'édition.

### Implementation for User Story 4

- [x] T010 [US4] Étendre le composant Dashboard dans `app/src/app/features/dashboard/dashboard.ts` : injecter DebtService, ajouter les signals `debtsLoading`, `debtsError`, `debts` (Debt[]), les computed `activeDebts` (filtre non remboursé, tri date DESC, slice 0-3), `totalJeDois` (somme JE_DOIS non remboursés), `totalOnMeDoit` (somme ON_ME_DOIT non remboursés), la méthode `loadDebts()` appelée depuis un effect() réagissant au refreshTrigger du DebtService, la méthode `onDebtClick(d: Debt)` qui appelle `shell.openEditDebt(d)`.
- [x] T011 [US4] Étendre le template `app/src/app/features/dashboard/dashboard.html` : ajouter section "Dettes en cours" avec header (titre + lien routerLink="/debts"), sous-header avec résumé 2 lignes ("Je dois : X EUR" en couleur debt-owe, "On me doit : X EUR" en couleur debt-owed), états loading/error/empty, liste `<app-list-item>` avec [icon] (emoji par sens : 📤 JE_DOIS / 📥 ON_ME_DOIT), [title] (personne), [value] (montant | amount: sens), [subtitle] (date | relativeDate), [valueClass] (debt-owe/debt-owed selon sens), (pressed)="onDebtClick(debt)".

**Checkpoint**: Les 3 dettes en cours s'affichent avec résumé, navigation et édition fonctionnent.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Ajustements finaux affectant plusieurs user stories.

- [x] T012 Vérifier la cohérence des classes SCSS entre toutes les sections dans `app/src/app/features/dashboard/dashboard.scss` : espacement entre sections (gap/margin), responsive mobile-first, alignement des cartes summary sur petit écran (flex-wrap si nécessaire).
- [x] T013 Valider le scénario quickstart.md : ouvrir /dashboard, vérifier les 8 points de validation (bilan, sélecteur, transactions, abonnements, dettes, "Voir tout", édition au clic, isolation erreurs).
- [x] T014 Exécuter `ng lint` et `npm run format` pour s'assurer que le code respecte les conventions dans `app/`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Vide — rien à faire
- **Phase 2 (Foundational)**: Modifie shell.ts — BLOQUE toutes les user stories (pour l'édition au clic)
- **Phase 3 (US1)**: Dépend de Phase 2. Peut commencer immédiatement après.
- **Phase 4 (US2)**: Dépend de Phase 3 (le composant Dashboard doit exister avec ses imports de base)
- **Phase 5 (US3)**: Dépend de Phase 4 (les classes SCSS de section sont créées en T007)
- **Phase 6 (US4)**: Dépend de Phase 4 (même raison que US3). US3 et US4 sont parallélisables entre eux.
- **Phase 7 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Indépendant — crée le composant Dashboard de base
- **US2 (P2)**: Dépend de US1 (même fichier .ts/.html) + crée les classes SCSS de section
- **US3 (P3)**: Dépend de US2 pour les classes SCSS de section. Parallélisable avec US4.
- **US4 (P3)**: Dépend de US2 pour les classes SCSS de section. Parallélisable avec US3.

### Parallel Opportunities

- T004 (SCSS US1) est parallélisable avec T002/T003
- T007 (SCSS sections US2) est parallélisable avec T005/T006
- US3 et US4 sont parallélisables entre eux (fichiers différents : non, même fichier — mais sections indépendantes dans le même fichier)

---

## Parallel Example: User Story 1

```bash
# Lancer en parallèle :
Task T002: "Implémenter le composant Dashboard (TS) dans dashboard.ts"
Task T004: "Créer les styles (SCSS) dans dashboard.scss"

# Ensuite séquentiellement :
Task T003: "Créer le template (HTML) dans dashboard.html" (dépend du TS pour les bindings)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (T001 — modifier Shell)
2. Complete Phase 3: User Story 1 (T002-T004 — bilan mensuel)
3. **STOP and VALIDATE**: Le dashboard affiche le bilan du mois en cours avec sélecteur
4. Commit

### Incremental Delivery

1. Phase 2 (T001) → Shell prêt
2. Phase 3 US1 (T002-T004) → Bilan mensuel fonctionnel → Commit
3. Phase 4 US2 (T005-T007) → + Aperçu transactions → Commit
4. Phase 5 US3 (T008-T009) → + Aperçu abonnements → Commit
5. Phase 6 US4 (T010-T011) → + Aperçu dettes → Commit
6. Phase 7 (T012-T014) → Polish → Commit final

---

## Notes

- Toutes les tâches modifient le même composant (dashboard.ts/html/scss) — l'exécution séquentielle par phase est recommandée
- Chaque phase est un incrément livrable et testable
- Le Shell (T001) est le seul fichier partagé modifié hors du composant Dashboard
- Pas de nouveau service, pas de nouveau modèle, pas de nouvelle route
- Commit après chaque phase validée
