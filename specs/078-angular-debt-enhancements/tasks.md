# Tasks: Améliorations dettes Angular

**Input**: Design documents from `/specs/078-angular-debt-enhancements/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Tests unitaires demandés (SC-006 dans spec.md).

**Organization**: Tasks groupées par user story. US1 et US2 sont parallélisables après la phase fondation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Modèles partagés, service enrichi, système toast — prérequis pour toutes les stories.

- [x] T001 Enrichir les interfaces Debt, DebtRequest + ajouter AccountSummary, DebtRepayRequest, DebtPaymentResponse, DebtSnoozeRequest dans `app/src/app/core/models/debt.model.ts` (voir data-model.md)
- [x] T002 [P] Ajouter `DEBT_REMINDER`, `BUDGET_THRESHOLD`, `BUDGET_EXCEEDED` au type NotificationType dans `app/src/app/core/models/notification.model.ts`
- [x] T003 [P] Créer le ToastService (signal-based: `toasts: signal<Toast[]>`, méthodes `success()`, `error()`, `info()`, auto-dismiss 4s) dans `app/src/app/shared/components/toast/toast.service.ts`
- [x] T004 [P] Créer le composant Toast (affichage des toasts en bas à droite, animation entrée/sortie, icônes par type, design tokens CSS) dans `app/src/app/shared/components/toast/toast.ts` + `toast.scss`
- [x] T005 Intégrer le composant Toast dans le Shell : ajouter `<app-toast />` dans `app/src/app/shared/components/shell/shell.html`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Service enrichi + routing détail — DOIT être complété avant toute user story.

**CRITICAL**: No user story work can begin until this phase is complete.

- [x] T006 Enrichir le DebtService avec 3 nouvelles méthodes : `repay(debtId, request: DebtRepayRequest)`, `getPayments(debtId)`, `snooze(debtId, request: DebtSnoozeRequest)` dans `app/src/app/core/services/debt.ts`
- [x] T007 Ajouter la route `/debts/:id` vers DebtDetail dans `app/src/app/features/debts/debts.routes.ts` (lazy-loaded)
- [x] T008 Modifier la liste des dettes : tap sur une dette → `router.navigate(['/debts', debt.id])` au lieu d'ouvrir le modal d'édition dans `app/src/app/features/debts/debts.ts`

**Checkpoint**: Foundation ready — les user stories peuvent commencer.

---

## Phase 3: User Story 1 - Rembourser une dette (Priority: P1) MVP

**Goal**: L'utilisateur peut consulter le détail d'une dette (montant restant, barre de progression) et effectuer un remboursement (total ou partiel) via un dialog.

**Independent Test**: Ouvrir le détail d'une dette, cliquer "Rembourser", valider, vérifier que le montant restant se met à jour et un toast s'affiche.

### Implementation for User Story 1

- [x] T009 [US1] Créer le composant DebtDetail — layout de base : header avec personne + sens (badge EMPRUNT/PRET), montant initial, montant restant, badge "Remboursé" conditionnel, bouton "Modifier" (ouvre le modal existant), bouton retour dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts` + `debt-detail.scss`. Charger la dette via `DebtService.getById()` avec le param route `:id`. Afficher catégorie, devise, date, dueDate si définis.
- [x] T010 [US1] Ajouter la barre de progression au DebtDetail : calcul `(montant - montantRestant) / montant * 100`, couleur catégorie ou primaire, pourcentage affiché, dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts`
- [x] T011 [US1] Créer le composant RepayDialog — dialog standalone (overlay + backdrop) avec : sélecteur de compte source (comptes actifs via AccountService.getAll()), champ montant pré-rempli avec montantRestant (max = montantRestant, min = 0.01), bouton "Rembourser", bouton "Annuler". Pré-sélectionner le compte associé à la dette si existant. Validation : montant > 0, montant <= montantRestant, compte requis dans `app/src/app/features/debts/components/repay-dialog/repay-dialog.ts` + `repay-dialog.scss`
- [x] T012 [US1] Wirer le flux remboursement dans DebtDetail : bouton "Rembourser" ouvre RepayDialog → validation → `DebtService.repay()` → ferme dialog → rafraîchit la dette → toast succès ("Remboursement de X € enregistré. Reste : Y €" ou "Dette remboursée !" si soldé). Désactiver le bouton "Rembourser" si `rembourse === true` ou si aucun compte actif n'existe (tooltip explicatif). Gérer les erreurs API avec toast error dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts`

**Checkpoint**: US1 fonctionnelle — remboursement complet avec feedback visuel.

---

## Phase 4: User Story 2 - Formulaire dette enrichi (Priority: P1)

**Goal**: L'utilisateur peut créer/modifier une dette avec compte bancaire, rappel et toggle patrimoine.

**Independent Test**: Créer une dette avec un compte associé et un rappel, vérifier que les valeurs sont sauvegardées et ré-affichées en édition.

### Implementation for User Story 2

- [x] T013 [P] [US2] Ajouter le champ "Compte bancaire" (select optionnel) au formulaire : liste des comptes actifs via `AccountService.getAll()`, avec un `effect()` qui force la devise = devise du compte sélectionné et masque le champ devise quand un compte est sélectionné. Quand un compte est sélectionné, auto-set `includeInBalance = true` dans `app/src/app/features/debts/components/debt-form/debt-form.ts`
- [x] T014 [US2] Ajouter le toggle "Inclure dans le patrimoine" au formulaire : checkbox/toggle visible uniquement quand aucun compte n'est sélectionné (`@if (!accountId())`), default false, dans `app/src/app/features/debts/components/debt-form/debt-form.ts`
- [x] T015 [US2] Ajouter les champs rappel au formulaire : date picker "Date de rappel" (optionnel) + time picker "Heure de rappel" (optionnel, affiché seulement si date rappel définie), dans `app/src/app/features/debts/components/debt-form/debt-form.ts`
- [x] T016 [US2] Mapper les nouveaux champs dans le formulaire pour l'édition : pré-remplir accountId, includeInBalance, reminderDate, reminderTime depuis la dette existante (`ModalService.editingEntity()`). S'assurer que le DebtRequest envoyé inclut les nouveaux champs dans `app/src/app/features/debts/components/debt-form/debt-form.ts`

**Checkpoint**: US2 fonctionnelle — formulaire enrichi avec tous les champs dynamiques.

---

## Phase 5: User Story 3 - Consulter l'historique des paiements (Priority: P2)

**Goal**: L'utilisateur voit la liste chronologique des paiements d'une dette avec total cumulé.

**Independent Test**: Ouvrir le détail d'une dette avec des paiements existants, vérifier la liste (date, montant, compte) et le total.

**Depends on**: US1 (DebtDetail existe)

### Implementation for User Story 3

- [x] T017 [US3] Ajouter la section "Historique des paiements" au DebtDetail : appel `DebtService.getPayments(debtId)`, liste chronologique (plus récent en premier) affichant date, montant formaté avec devise, nom du compte source. Total cumulé en bas de la liste. État vide si aucun paiement ("Aucun paiement enregistré"). Rafraîchir l'historique après chaque remboursement dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts`

**Checkpoint**: US3 fonctionnelle — historique visible dans le détail.

---

## Phase 6: User Story 4 - Reporter un rappel de dette (Priority: P2)

**Goal**: L'utilisateur peut reporter un rappel à une nouvelle date/heure via un dialog.

**Independent Test**: Depuis le détail d'une dette avec rappel, cliquer "Reporter", choisir nouvelle date/heure, valider, vérifier mise à jour.

### Implementation for User Story 4

- [x] T018 [US4] Créer le composant SnoozeDialog — dialog standalone avec : date picker "Nouvelle date" (required, validation `@FutureOrPresent`), time picker "Heure" (required), bouton "Reporter", bouton "Annuler". Erreur de validation si date dans le passé dans `app/src/app/features/debts/components/snooze-dialog/snooze-dialog.ts` + `snooze-dialog.scss`
- [x] T019 [US4] Wirer le flux report dans DebtDetail : ajouter un bouton "Reporter le rappel" (visible si `reminderDate !== null`) → ouvre SnoozeDialog → validation → `DebtService.snooze()` → ferme dialog → rafraîchit la dette → toast succès dans `app/src/app/features/debts/components/debt-detail/debt-detail.ts`

**Checkpoint**: US4 fonctionnelle — report de rappel opérationnel.

---

## Phase 7: User Story 5 - Actions notification dette (Priority: P3)

**Goal**: Les notifications dette proposent les actions "Reporter" et "Rembourser" directement.

**Independent Test**: Voir une notification DEBT_DUE ou DEBT_REMINDER, vérifier que les boutons "Reporter" et "Rembourser" sont présents et ouvrent les dialogs respectifs.

**Depends on**: US1 (RepayDialog), US4 (SnoozeDialog)

### Implementation for User Story 5

- [x] T020 [US5] Ajouter les boutons d'action "Reporter" et "Rembourser" dans le NotificationPanel pour les notifications de type `DEBT_DUE` et `DEBT_REMINDER`. Afficher les boutons sous chaque notification concernée. Charger la dette via `DebtService.getById(notification.entityId)` au clic dans `app/src/app/shared/components/notification-panel/notification-panel.ts`
- [x] T021 [US5] Wirer les actions notification : "Rembourser" → ouvre RepayDialog avec la dette chargée → flux identique à US1. "Reporter" → ouvre SnoozeDialog → flux identique à US4. Après action réussie, marquer la notification comme lue via `NotificationService.markAsRead()` dans `app/src/app/shared/components/notification-panel/notification-panel.ts`

**Checkpoint**: US5 fonctionnelle — actions directes depuis les notifications.

---

## Phase 8: Tests unitaires

**Purpose**: Couverture test de tous les composants nouveaux/modifiés (SC-006).

- [x] T022 [P] Tests unitaires DebtDetail : vérifie affichage montant restant, barre de progression, badge "Remboursé", bouton désactivé si remboursé, bouton désactivé si aucun compte actif dans `app/src/app/features/debts/components/debt-detail/debt-detail.spec.ts`
- [x] T023 [P] Tests unitaires RepayDialog : vérifie pré-remplissage montant, pré-sélection compte associé, validation montant > 0 et <= montantRestant, compte requis dans `app/src/app/features/debts/components/repay-dialog/repay-dialog.spec.ts`
- [x] T024 [P] Tests unitaires SnoozeDialog : vérifie validation date future, champs requis, soumission dans `app/src/app/features/debts/components/snooze-dialog/snooze-dialog.spec.ts`
- [x] T025 [P] Tests unitaires DebtForm enrichi : vérifie devise forcée quand compte sélectionné, toggle patrimoine masqué quand compte, includeInBalance auto-true, pré-remplissage en édition dans `app/src/app/features/debts/components/debt-form/debt-form.spec.ts`
- [x] T026 [P] Tests unitaires ToastService : vérifie success/error/info, auto-dismiss, suppression manuelle dans `app/src/app/shared/components/toast/toast.service.spec.ts`
- [x] T027 [P] Tests unitaires NotificationPanel actions dette : vérifie affichage boutons pour DEBT_DUE/DEBT_REMINDER, non-affichage pour autres types dans `app/src/app/shared/components/notification-panel/notification-panel.spec.ts`

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et edge cases.

- [x] T028 Vérifier les edge cases : montant remboursement > restant (plafonnement), aucun compte actif (bouton désactivé + tooltip), dette déjà remboursée (badge + bouton désactivé), montant = 0 (validation), date passée dans snooze (validation) — test manuel dans le navigateur
- [x] T029 Vérifier le responsive mobile : DebtDetail, RepayDialog, SnoozeDialog, DebtForm enrichi — design compact, touch-friendly
- [x] T030 Run `cd app && ng lint` et corriger les éventuelles erreurs de lint

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 (model) — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 completion
- **US2 (Phase 4)**: Depends on Phase 2 completion — **parallélisable avec US1** (fichiers différents)
- **US3 (Phase 5)**: Depends on US1 (DebtDetail existe)
- **US4 (Phase 6)**: Depends on Phase 2 — parallélisable avec US1/US2
- **US5 (Phase 7)**: Depends on US1 (RepayDialog) + US4 (SnoozeDialog)
- **Tests (Phase 8)**: Depends on toutes les stories implémentées
- **Polish (Phase 9)**: Depends on Phase 8

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundation)
                         │
            ┌────────────┼────────────┐
            ▼            ▼            ▼
         US1 (P1)    US2 (P1)     US4 (P2)
            │                         │
            ▼                         │
         US3 (P2)                     │
            │                         │
            └────────────┬────────────┘
                         ▼
                      US5 (P3)
                         │
                         ▼
                   Tests (Phase 8)
                         │
                         ▼
                   Polish (Phase 9)
```

### Parallel Opportunities

- **Phase 1**: T002, T003, T004 en parallèle (après T001 pour T002)
- **Phase 2**: T007, T008 en parallèle (après T006)
- **Phases 3+4+6**: US1, US2, US4 en parallèle (fichiers différents)
- **Phase 8**: Tous les tests (T022-T027) en parallèle

---

## Parallel Example: US1 + US2 + US4

```bash
# Après Phase 2, lancer en parallèle :
# Développeur A : US1 (debt-detail/ + repay-dialog/)
# Développeur B : US2 (debt-form/)
# Développeur C : US4 (snooze-dialog/)
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundation (T006-T008)
3. Complete Phase 3: US1 — Remboursement (T009-T012)
4. **STOP and VALIDATE**: Ouvrir le détail d'une dette, rembourser, vérifier montant restant + barre + toast
5. Commit et démo possible

### Incremental Delivery

1. Setup + Foundation → Infrastructure prête
2. US1 (Remboursement) → MVP livrable
3. US2 (Formulaire enrichi) → Création de dettes complètes
4. US3 (Historique) → Visibilité paiements
5. US4 (Report rappel) → Gestion rappels
6. US5 (Actions notification) → Productivité
7. Tests + Polish → Qualité

---

## Notes

- [P] tasks = fichiers différents, aucune dépendance
- Les dialogs RepayDialog et SnoozeDialog sont standalone (pas via ModalService)
- Le ToastService est réutilisable par toute l'application
- Chaque US est commitée séparément pour traçabilité
- Commit après chaque phase ou groupe logique de tâches
