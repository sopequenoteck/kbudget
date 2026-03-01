# Tasks: Virement entre comptes Angular

**Input**: Design documents from `/specs/066-angular-transfer-form/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Non demandés explicitement dans la spec. Tests unitaires inclus dans US1 car le projet a une convention de tests sur les formulaires.

**Organization**: Tasks groupées par user story pour permettre l'implémentation et le test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Vérification des prérequis et modèles de données

- [X] T001 Ajouter les interfaces `TransferRequest`, `TransferResponse` et `TransactionRef` dans `app/src/app/core/models/account.model.ts`
- [X] T002 Ajouter la méthode `transfer(request: TransferRequest): Observable<TransferResponse>` dans `app/src/app/core/services/account.ts` — appel `POST /accounts/transfer` avec `tap(() => this.refresh())`

**Checkpoint**: Couche service prête — le frontend peut maintenant appeler l'API transfer.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Intégration du type 'transfer' dans le système de modales existant

**CRITICAL**: Ces tâches doivent être terminées avant l'implémentation du formulaire.

- [X] T003 Ajouter `'transfer'` au type `ModalType` et le titre "Nouveau virement" dans le computed `modalTitle` de `app/src/app/core/services/modal.service.ts`

**Checkpoint**: Le système de modales supporte le type 'transfer' — l'implémentation du formulaire peut commencer.

---

## Phase 3: User Story 1 - Effectuer un virement entre comptes (Priority: P1) MVP

**Goal**: L'utilisateur peut ouvrir un formulaire de virement, sélectionner deux comptes différents, saisir un montant et une note optionnelle, et effectuer le virement.

**Independent Test**: Créer un virement entre deux comptes et vérifier que deux transactions liées apparaissent dans la liste.

### Implementation for User Story 1

- [X] T004 [P] [US1] Créer le composant `TransferForm` (standalone, OnPush, signals) dans `app/src/app/shared/components/transfer-form/transfer-form.ts` — Reactive Form avec champs `fromAccountId` (required), `toAccountId` (required), `montant` (required, min 0.01), `note` (optional, maxLength 500). Signals : `activeAccounts` (comptes actifs depuis `AccountService`), `accountItems` (computed `SelectItem[]` avec icône + solde), `submitting`, `errorMessage`. Outputs : `saved` (émet `TransferResponse`), `cancelled`. Soumission via `firstValueFrom(accountService.transfer(request))`.
- [X] T005 [US1] Ajouter le validateur cross-champ `differentAccountsValidator` dans `app/src/app/shared/components/transfer-form/transfer-form.ts` — `AbstractValidatorFn` au niveau du `FormGroup` qui vérifie `fromAccountId !== toAccountId`, retourne `{ sameAccount: true }` si identiques. (Dépend de T004 — même fichier)
- [X] T006 [US1] Créer le template `app/src/app/shared/components/transfer-form/transfer-form.html` — message "pas assez de comptes" si `hasEnoughAccounts() === false`; deux `app-select-picker` (compte source, compte destination); bannière d'erreur `sameAccount` conditionnelle; champ montant (input number); champ note (textarea, optionnel); bannière erreur serveur (`errorMessage()`); bouton "Effectuer le virement" avec état `submitting()` et disabled si form invalide.
- [X] T007 [P] [US1] Créer les styles `app/src/app/shared/components/transfer-form/transfer-form.scss` — layout formulaire cohérent avec `TransactionForm` et `SubscriptionForm` existants; utiliser les design tokens `var(--*)`.
- [X] T008 [US1] Intégrer `TransferForm` dans le Shell : importer le composant dans `app/src/app/shared/components/shell/shell.ts`, ajouter le handler `onTransferSaved()` qui incrémente `transactionService.refreshTrigger` et ferme la modale, ajouter le `@case ('transfer')` dans `app/src/app/shared/components/shell/shell.html` avec `<app-transfer-form (saved)="onTransferSaved()" (cancelled)="onModalClose()" />`.
- [X] T009 [US1] Écrire les tests unitaires dans `app/src/app/shared/components/transfer-form/transfer-form.spec.ts` — convention `should_[résultat]_when_[condition]`. Tests : should_create_component, should_show_warning_when_less_than_2_accounts, should_show_form_when_2_or_more_accounts, should_show_error_when_same_account_selected, should_accept_when_different_accounts, should_reject_when_amount_is_zero, should_submit_when_valid_data, should_close_without_side_effects_when_cancelled.

**Checkpoint**: L'utilisateur peut effectuer un virement complet via le Shell. Testable indépendamment.

---

## Phase 4: User Story 2 - Accès conditionnel au virement (Priority: P2)

**Goal**: L'option "Virement" n'apparaît dans le FAB que si l'utilisateur a au moins 2 comptes actifs.

**Independent Test**: Vérifier la visibilité de l'action "Virement" dans le FAB avec 0, 1, puis 2+ comptes actifs.

### Implementation for User Story 2

- [X] T010 [US2] Ajouter l'action `TRANSFER_ACTION = { type: 'transfer', label: 'Virement', icon: '↔️' }` dans le FAB : ajouter le computed `hasEnoughAccounts` (>= 2 comptes actifs) et inclure `TRANSFER_ACTION` dans le computed `actions` uniquement si `hasEnoughAccounts()` est true, dans `app/src/app/shared/components/fab/fab.ts`.

**Checkpoint**: L'option Virement est conditionnelle dans le FAB. Testable indépendamment.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage

- [X] T011 Vérifier le parcours complet : FAB → modal → formulaire → soumission → fermeture → rafraîchissement liste. Valider avec le quickstart (`specs/066-angular-transfer-form/quickstart.md`).
- [X] T012 Vérifier que `ng lint` et `npm run format` passent sans erreur sur les fichiers modifiés dans `app/`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — peut commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (T001, T002) — BLOQUE les user stories
- **US1 (Phase 3)**: Dépend de Phase 2 (T003) — MVP
- **US2 (Phase 4)**: Aucune dépendance sur les phases précédentes — le FAB utilise uniquement le signal `accounts` existant dans `AccountService`
- **Polish (Phase 5)**: Dépend de US1 et US2

### User Story Dependencies

- **User Story 1 (P1)**: Dépend de Phase 2. Aucune dépendance sur d'autres stories.
- **User Story 2 (P2)**: Aucune dépendance. Indépendant de US1 (concerne le FAB, pas le formulaire). Utilise le signal `accounts` déjà existant dans `AccountService`.
- **User Story 3 (P3)**: Intégrée dans US1 — le champ note est un champ optionnel du formulaire, pas une story séparée au niveau des tâches.

### Within Each User Story

- T004 et T005 (composant + validateur) : séquentiels (même fichier `transfer-form.ts`)
- T006 (template) : dépend de T004
- T007 (styles) : parallélisable avec T004/T005
- T008 (intégration shell) : dépend de T004 et T006
- T009 (tests) : dépend de T004, T005, T006

### Parallel Opportunities

- T004 et T007 peuvent être lancés en parallèle (fichiers différents)
- T005 est dans le même fichier que T004, exécution séquentielle
- US1 (Phase 3) et US2 (Phase 4) peuvent être travaillées en parallèle après Phase 2

---

## Parallel Example: User Story 1

```bash
# Parallélisable :
Task T004: "Créer TransferForm dans transfer-form.ts"
Task T007: "Créer styles dans transfer-form.scss"

# Séquentiel (dépendances) :
T004 → T005 → T006 → T008 → T009
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 : Setup (T001-T002) — modèles + service
2. Phase 2 : Foundational (T003) — ModalType
3. Phase 3 : User Story 1 (T004-T009) — formulaire complet
4. **STOP and VALIDATE** : tester le virement end-to-end via le Shell
5. Déployer/démontrer

### Incremental Delivery

1. Setup + Foundational → infrastructure prête
2. US1 → formulaire fonctionnel → test → **MVP livrable**
3. US2 → accès conditionnel via FAB → test → livraison incrémentale
4. Polish → validation finale + lint

---

## Notes

- US3 (note optionnelle) est intégrée dans US1 car le champ note fait partie du formulaire de base
- [P] tasks = fichiers différents, pas de dépendances
- [Story] label mappe la tâche à la user story correspondante
- Commit après chaque tâche ou groupe logique
- La feature est server-only : pas de stockage local (pas de Drift/SQLite)
