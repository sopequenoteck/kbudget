# Tasks: ModalService et câblage édition/suppression

**Input**: Design documents from `/specs/016-modal-service/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Non demandés dans la spec — aucune tâche de test générée.

**Organization**: Tâches groupées par user story. US3 (centralisation) est implémentée en Phase 2 car c'est un prérequis fondamental pour US1 et US2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (ModalService + migration Shell)

**Purpose**: Créer le ModalService centralisé et migrer le Shell pour l'utiliser. Implémente US3 (centralisation) comme fondation pour les user stories suivantes.

**⚠️ CRITICAL**: US1 et US2 ne peuvent commencer qu'après cette phase.

- [X] T001 [US3] Créer le ModalService dans `app/src/app/core/services/modal.service.ts` — Service injectable `providedIn: 'root'` avec : signal `activeModal` (`ModalType | null`), signal `editingEntity` (`Transaction | Subscription | Debt | null`), computed `modalOpen` (`activeModal() !== null`), computed `modalTitle` (titre dynamique selon type + mode create/edit : "Nouvelle transaction" / "Modifier la transaction" / "Nouvel abonnement" / "Modifier l'abonnement" / "Nouvelle dette" / "Modifier la dette"), méthode `openModal(type: ModalType, entity?)` qui set editingEntity puis activeModal, méthode `closeModal()` qui reset les deux à null. Déplacer le type `ModalType` ici (réexporter depuis fab.ts si nécessaire pour ne pas casser l'import existant).

- [X] T002 [US3] Refactorer le Shell pour utiliser ModalService dans `app/src/app/shared/components/shell/shell.ts` — Injecter `ModalService` via `inject()`. Supprimer les signaux locaux : `activeModal`, `editingTransaction`, `editingSubscription`, `editingDebt`, `modalOpen`, `modalTitle`. Supprimer les méthodes : `openEditTransaction`, `openEditSubscription`, `openEditDebt`. Exposer `modalService` en propriété readonly. Mettre à jour `onSpeedDialAction` → `this.modalService.openModal(type)`. Mettre à jour `onModalClose` → `this.modalService.closeModal()`. Mettre à jour l'effect NavigationEnd → `this.modalService.closeModal()`. Mettre à jour `onTransactionSaved/onSubscriptionSaved/onDebtSaved` : remplacer `this.editingTransaction()` par `this.modalService.editingEntity() as Transaction | null` (idem pour les autres), puis appeler `this.modalService.closeModal()` au lieu de set null manuellement. Supprimer les imports `MODAL_TITLES` (logique déplacée dans ModalService).

- [X] T003 [US3] Mettre à jour le template Shell dans `app/src/app/shared/components/shell/shell.html` — Remplacer `modalOpen()` → `modalService.modalOpen()`. Remplacer `modalTitle()` → `modalService.modalTitle()`. Remplacer `activeModal()` → `modalService.activeModal()`. Remplacer `editingTransaction()` → `$any(modalService.editingEntity())`. Remplacer `editingSubscription()` → `$any(modalService.editingEntity())`. Remplacer `editingDebt()` → `$any(modalService.editingEntity())`.

**Checkpoint**: ModalService fonctionnel, Shell migré. La création via FAB speed dial continue de fonctionner. US3 complète.

---

## Phase 2: User Story 1 - Éditer une entité existante (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur tape sur un élément de liste → modale s'ouvre pré-remplie → modification → sauvegarde → liste mise à jour.

**Independent Test**: Naviguer vers Transactions, taper sur un élément, modifier le montant, sauvegarder. Vérifier que la liste reflète le changement. Répéter pour Abonnements et Dettes.

### Implementation for User Story 1

- [X] T004 [P] [US1] Câbler l'écran Transactions pour l'édition dans `app/src/app/features/transactions/transactions.ts` et `app/src/app/features/transactions/transactions.html` — TS : injecter `ModalService`, ajouter méthode `onTransactionPressed(transaction: Transaction)` qui appelle `this.modalService.openModal('transaction', transaction)`. HTML : sur chaque `<app-list-item>` dans la boucle `@for`, ajouter `(pressed)="onTransactionPressed(transaction)"`.

- [X] T005 [P] [US1] Câbler l'écran Subscriptions pour l'édition dans `app/src/app/features/subscriptions/subscriptions.ts` et `app/src/app/features/subscriptions/subscriptions.html` — TS : injecter `ModalService`, ajouter méthode `onSubscriptionPressed(subscription: Subscription)` qui appelle `this.modalService.openModal('subscription', subscription)`. HTML : sur chaque `<app-list-item>`, ajouter `(pressed)="onSubscriptionPressed(subscription)"`.

- [X] T006 [P] [US1] Câbler l'écran Debts pour l'édition dans `app/src/app/features/debts/debts.ts` et `app/src/app/features/debts/debts.html` — TS : injecter `ModalService`, ajouter méthode `onDebtPressed(debt: Debt)` qui appelle `this.modalService.openModal('debt', debt)`. HTML : sur chaque `<app-list-item>`, ajouter `(pressed)="onDebtPressed(debt)"`.

**Checkpoint**: Édition fonctionnelle sur les 3 écrans. Tap → modale pré-remplie → modifier → sauvegarder → liste mise à jour. US1 complète.

---

## Phase 3: User Story 2 - Supprimer une entité existante (Priority: P2)

**Goal**: En mode édition, un bouton "Supprimer" apparaît. Clic → confirmation inline → suppression → modale ferme → liste mise à jour.

**Independent Test**: Ouvrir une transaction existante, cliquer "Supprimer", confirmer. Vérifier que l'élément disparaît de la liste. Vérifier que le bouton est absent en mode création.

### Implementation for User Story 2

- [X] T007 [P] [US2] Ajouter le bouton Supprimer + confirmation au formulaire Transaction dans `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` et `app/src/app/features/transactions/components/transaction-form/transaction-form.html` — TS : ajouter `readonly deleted = output<string>()`, ajouter `readonly showDeleteConfirm = signal(false)`, ajouter méthode `onDelete()` qui toggle `showDeleteConfirm`, ajouter méthode `onConfirmDelete()` qui émet `deleted.emit(this.transaction()!.id)` et reset showDeleteConfirm, ajouter méthode `onCancelDelete()` qui set showDeleteConfirm à false. HTML : dans `.form-actions`, ajouter conditionnellement (`@if (isEditMode())`) un bouton "Supprimer" de classe `btn-danger` qui appelle `onDelete()`. Quand `showDeleteConfirm()` est true, remplacer le bouton par une zone de confirmation avec deux boutons "Confirmer" (`btn-danger`, appelle `onConfirmDelete()`) et "Annuler" (`btn-outline`, appelle `onCancelDelete()`).

- [X] T008 [P] [US2] Ajouter le bouton Supprimer + confirmation au formulaire Subscription dans `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts` et `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html` — Même pattern que T007 : output `deleted`, signal `showDeleteConfirm`, méthodes `onDelete/onConfirmDelete/onCancelDelete`, zone de confirmation inline en mode édition.

- [X] T009 [P] [US2] Ajouter le bouton Supprimer + confirmation au formulaire Debt dans `app/src/app/features/debts/components/debt-form/debt-form.ts` et `app/src/app/features/debts/components/debt-form/debt-form.html` — Même pattern que T007 : output `deleted`, signal `showDeleteConfirm`, méthodes `onDelete/onConfirmDelete/onCancelDelete`, zone de confirmation inline en mode édition.

- [X] T010 [US2] Gérer les événements de suppression dans le Shell dans `app/src/app/shared/components/shell/shell.ts` — Ajouter 3 méthodes async : `onTransactionDeleted(id: string)` qui appelle `firstValueFrom(this.transactionService.delete(id))` puis `this.modalService.closeModal()`, `onSubscriptionDeleted(id: string)` idem avec subscriptionService, `onDebtDeleted(id: string)` idem avec debtService. Le refreshTrigger des services existants déclenche automatiquement le rechargement des listes. Encapsuler chaque appel dans un try/catch : en cas d'erreur, logger via `isDevMode() && console.error(...)` et ne PAS fermer la modale (l'utilisateur reste sur le formulaire).

- [X] T011 [US2] Connecter les outputs deleted dans le template Shell dans `app/src/app/shared/components/shell/shell.html` — Sur chaque formulaire dans le `@switch`, ajouter le binding `(deleted)="onTransactionDeleted($event)"` / `(deleted)="onSubscriptionDeleted($event)"` / `(deleted)="onDebtDeleted($event)"`.

**Checkpoint**: Suppression fonctionnelle sur les 3 types d'entités. Bouton absent en mode création. US2 complète.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage.

- [X] T012 Ajouter les styles CSS pour le bouton Supprimer et la zone de confirmation — D'abord, ajouter `.btn-danger` dans `app/src/styles/_buttons.scss` (fond `var(--bg-error)`, texte `var(--text-inverse)`, hover assombri). Puis ajouter `.delete-confirm` dans les SCSS des formulaires (`transaction-form.scss`, `subscription-form.scss`, `debt-form.scss`) : flex, gap, message "Supprimer cet élément ?".

- [X] T013 Exécuter la validation complète — Lancer `cd app && ng lint`, `cd app && npx vitest run`, `cd app && ng build`. Vérifier les scénarios du quickstart.md manuellement.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: T001 → T002 → T003 (séquentiel : service → shell.ts → shell.html)
- **Phase 2 (US1)**: Dépend de Phase 1. T004, T005, T006 en parallèle (fichiers différents)
- **Phase 3 (US2)**: Dépend de Phase 2. T007, T008, T009 en parallèle → T010 → T011
- **Phase 4 (Polish)**: Dépend de Phase 3. T012 parallélisable avec T010-T011 (fichiers différents)

### User Story Dependencies

- **US3 (P3 → Phase 1)**: Aucune dépendance — fondation
- **US1 (P1 → Phase 2)**: Dépend de US3 (ModalService doit exister)
- **US2 (P2 → Phase 3)**: Dépend de US1 (édition doit fonctionner pour accéder au mode édition)

### Parallel Opportunities

- T004 + T005 + T006 : 3 écrans de liste indépendants
- T007 + T008 + T009 : 3 formulaires indépendants
- T012 parallélisable avec T010-T011

---

## Parallel Example: User Story 1

```text
# Après Phase 1 complétée, lancer les 3 écrans en parallèle :
T004: Câbler transactions (transactions.ts + transactions.html)
T005: Câbler subscriptions (subscriptions.ts + subscriptions.html)
T006: Câbler debts (debts.ts + debts.html)
```

## Parallel Example: User Story 2

```text
# Lancer les 3 formulaires en parallèle :
T007: Bouton Supprimer dans transaction-form (.ts + .html)
T008: Bouton Supprimer dans subscription-form (.ts + .html)
T009: Bouton Supprimer dans debt-form (.ts + .html)

# Puis séquentiellement :
T010: Handler delete dans Shell .ts
T011: Binding (deleted) dans Shell .html
```

---

## Implementation Strategy

### MVP First (US3 + US1)

1. Phase 1 : ModalService + migration Shell (US3) — 3 tâches
2. Phase 2 : Câbler édition sur les 3 écrans (US1) — 3 tâches
3. **STOP and VALIDATE** : Tester l'édition sur les 3 types d'entités
4. Déployer si prêt (édition fonctionne, suppression viendra ensuite)

### Incremental Delivery

1. Phase 1 → US3 fonctionnelle (ModalService centralisé)
2. Phase 2 → US1 fonctionnelle (édition via tap)
3. Phase 3 → US2 fonctionnelle (suppression avec confirmation)
4. Phase 4 → Polish (styles, lint, build)

---

## Notes

- Total : **13 tâches** (3 foundational + 3 US1 + 5 US2 + 2 polish)
- Feature frontend-only : 1 fichier créé, 12 fichiers modifiés
- Pas de nouveaux endpoints API
- Les services CRUD existants gèrent déjà create/update/delete + refreshTrigger
- US3 est implémentée en Phase 1 car c'est un prérequis architectural, malgré sa priorité P3 dans la spec
