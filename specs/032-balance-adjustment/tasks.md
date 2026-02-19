# Tasks: Ajustement de solde de compte bancaire

**Input**: Design documents from `/specs/032-balance-adjustment/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/adjust-balance.yaml

**Tests**: Inclus (Principe V de la constitution — tests d'intégration obligatoires sur les endpoints).

**Organization**: Tasks groupées par user story. US3 est un sous-cas de US1 (pas de code supplémentaire requis).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2)
- Chemins exacts dans les descriptions

---

## Phase 1: Foundational (Prérequis domaine)

**Purpose**: Étendre le domaine (enum, query, catégorie lazy) avant toute implémentation de user story.

**CRITICAL**: Aucune tâche US ne peut démarrer avant la fin de cette phase.

- [x] T001 [P] Ajouter la valeur `AJUSTEMENT` à l'enum TransactionType dans `api/src/main/java/fr/kksdev/budget/api/enums/TransactionType.java`
- [x] T002 [P] Ajouter `AJUSTEMENT = 'AJUSTEMENT'` à l'enum TransactionType dans `app/src/app/core/models/transaction.model.ts`
- [x] T003 [P] Modifier la query native `calculateBalanceByAccountId` pour traiter AJUSTEMENT comme montant signé (CASE WHEN AJUSTEMENT THEN montant) dans `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java`
- [x] T004 [P] Ajouter la méthode `findOrCreateAdjustmentCategory(UUID userId)` qui retourne ou crée la catégorie système "Ajustement" (nom="Ajustement", icone="⚖️", couleur="#6b7280", isSystem=true) dans `api/src/main/java/fr/kksdev/budget/api/service/CategoryService.java`

**Checkpoint**: Domaine étendu — les user stories peuvent démarrer.

---

## Phase 2: User Story 1 — Ajuster le solde d'un compte (Priority: P1) MVP

**Goal**: L'utilisateur peut ajuster le solde d'un compte via le formulaire d'édition. Le backend crée une transaction AJUSTEMENT signée. Aucune transaction si solde identique. Refus si compte inactif.

**Independent Test**: Modifier le solde d'un compte existant via `POST /accounts/{id}/adjust-balance` et vérifier que le nouveau solde est correct.

### Implementation

- [x] T005 [P] [US1] Créer le record `AdjustBalanceRequest` avec champ `@NotNull BigDecimal newBalance` dans `api/src/main/java/fr/kksdev/budget/api/dto/request/AdjustBalanceRequest.java`
- [x] T006 [P] [US1] Implémenter `adjustBalance(UUID accountId, BigDecimal newBalance, UUID userId)` dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java` — calculer diff, vérifier compte actif, skip si diff==0, créer Transaction(type=AJUSTEMENT, montant=diff signé, libelle="Ajustement de solde", date=today, category=findOrCreateAdjustmentCategory), retourner AccountResponse avec solde mis à jour. Méthode `@Transactional` pour atomicité (FR-010). Logger au niveau INFO : accountId, diff, userId (Constitution VI).
- [x] T007 [US1] Ajouter endpoint `@PostMapping("/{id}/adjust-balance")` retournant `ResponseEntity<AccountResponse>` (HTTP 200) dans `api/src/main/java/fr/kksdev/budget/api/controller/AccountController.java` — dépend de T005, T006
- [x] T008 [P] [US1] Ajouter méthode `adjustBalance(id: string, newBalance: number): Observable<Account>` (POST) dans `app/src/app/core/services/account.ts`
- [x] T009 [US1] Modifier le formulaire d'édition de compte : en mode édition, afficher le solde actuel (lecture seule) et un champ "Nouveau solde" (éditable). À la soumission, si le nouveau solde diffère, appeler `accountService.adjustBalance()` puis fermer le formulaire. Fichiers : `app/src/app/shared/components/account-form/account-form.ts`, `account-form.html`, `account-form.scss` — dépend de T008
- [x] T010 [US1] Écrire les tests d'intégration pour l'endpoint adjust-balance : should_adjustBalance_when_newBalanceHigher, should_adjustBalance_when_newBalanceLower, should_notCreateTransaction_when_sameBalance, should_rejectAdjustment_when_accountInactive, should_rejectAdjustment_when_accountNotFound, should_acceptNegativeBalance dans `api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java` — dépend de T007

**Checkpoint**: US1 fonctionnelle et testable. L'utilisateur peut ajuster le solde de n'importe quel compte actif.

---

## Phase 3: User Story 2 — Consulter l'historique des ajustements (Priority: P2)

**Goal**: Les transactions d'ajustement apparaissent dans l'historique avec catégorie "Ajustement" et libellé "Ajustement de solde". Elles sont immutables (403 API, boutons masqués frontend). Le résumé mensuel les exclut de recettes/dépenses mais les inclut dans le solde.

**Independent Test**: Après un ajustement, la transaction apparaît dans la liste avec catégorie "Ajustement" ; tenter PUT/DELETE retourne 403.

### Implementation

- [x] T011 [P] [US2] Ajouter des guards d'immutabilité et de création dans TransactionService (`api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java`) : (a) dans `create()`, si `request.type() == AJUSTEMENT`, lancer `IllegalArgumentException("Les transactions d'ajustement ne peuvent être créées que via l'endpoint adjust-balance")` (→ HTTP 400) (FR-014) ; (b) dans `update()` et `delete()`, si `transaction.getType() == AJUSTEMENT`, lancer `AccessDeniedException("Les transactions d'ajustement ne peuvent pas être modifiées/supprimées")` (→ HTTP 403)
- [x] T012 [US2] Modifier `getMonthlySummary()` pour que les transactions AJUSTEMENT ne comptent ni dans `totalRecettes` ni dans `totalDepenses` mais soient incluses dans le `solde` (recettes - dépenses + ajustements) (FR-013) dans `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java` — même fichier que T011, séquentiel
- [x] T013 [P] [US2] Modifier la liste des transactions Angular : afficher les transactions AJUSTEMENT avec leur catégorie et montant signé (classe CSS `amount-adjustment` neutre), et ne pas ouvrir le modal d'édition au clic sur une transaction AJUSTEMENT (évite un modal sans action possible). Fichiers : `app/src/app/features/transactions/transactions.ts`, `transactions.html`
- [x] T014 [US2] Écrire les tests d'intégration pour l'immutabilité et la protection de création : should_return403_when_updatingAdjustmentTransaction, should_return403_when_deletingAdjustmentTransaction, should_return400_when_creatingAdjustmentDirectly dans `api/src/test/java/fr/kksdev/budget/api/controller/TransactionControllerTest.java` — dépend de T011

**Checkpoint**: US2 fonctionnelle. L'historique affiche les ajustements, ils sont protégés contre modification/suppression.

---

## Phase 4: User Story 3 — Ajuster le solde du compte par défaut initial (Priority: P3)

**Goal**: Un nouvel utilisateur peut renseigner son vrai solde sur le compte par défaut (solde initial = 0).

**Independent Test**: Compte avec solde 0, ajuster à 1500 EUR → solde final = 1500 EUR.

> **Note** : US3 est un sous-cas de US1 (confirmé dans la spec). L'implémentation de US1 couvre déjà ce scénario — aucun code supplémentaire n'est requis. La validation est couverte par les tests d'intégration de T010.

---

## Phase 5: Polish & Validation

**Purpose**: Vérification globale et nettoyage

- [x] T015 Lancer les tests backend complets — `cd api && mvn clean test`
- [x] T016 Lancer le build et lint frontend — `cd app && ng build && ng lint`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)** : Pas de dépendances — démarrage immédiat. Toutes les tâches [P].
- **US1 (Phase 2)** : Dépend de Phase 1 complète.
- **US2 (Phase 3)** : Dépend de Phase 1 complète. Indépendant de US1 côté backend (guards + résumé). Côté frontend, bénéficie de US1 pour tester le flux complet.
- **US3 (Phase 4)** : Aucun code — couvert par US1.
- **Polish (Phase 5)** : Dépend de US1 + US2 complètes.

### User Story Dependencies

```
Phase 1 (Foundational)
  ├── Phase 2 (US1) ──┐
  └── Phase 3 (US2) ──┼── Phase 5 (Polish)
                       │
       Phase 4 (US3) ─┘  (pas de code)
```

- **US1** et **US2** peuvent être implémentées en parallèle après Phase 1.
- **US2 backend** (T011-T012, T014) ne dépend pas de US1.
- **US2 frontend** (T013) ne dépend pas de US1 mais le flux complet (créer un ajustement puis le voir) nécessite US1.

### Within Each User Story

- DTO et service en parallèle [P] → controller (dépend des deux) → tests (dépend du controller)
- Frontend service [P] → formulaire/liste (dépend du service)

### Parallel Opportunities

```
Phase 1 : T001 ║ T002 ║ T003 ║ T004  (4 tâches en parallèle)
Phase 2 : T005 ║ T006 ║ T008          (3 tâches en parallèle)
          → T007 (dépend T005+T006)
          → T009 (dépend T008)
          → T010 (dépend T007)
Phase 3 : T011 ║ T013                  (backend ║ frontend)
          → T012 (après T011, même fichier)
          → T014 (après T011)
```

---

## Parallel Example: User Story 1

```bash
# Lancer en parallèle après Phase 1 :
Task T005: "Créer AdjustBalanceRequest DTO"
Task T006: "Implémenter adjustBalance() dans AccountService"
Task T008: "Ajouter adjustBalance() au service Angular"

# Puis séquentiellement :
Task T007: "Ajouter endpoint POST /{id}/adjust-balance" (après T005+T006)
Task T009: "Modifier account-form" (après T008)
Task T010: "Tests intégration endpoint" (après T007)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 : Foundational (4 tâches, toutes parallèles)
2. Phase 2 : US1 — Ajuster le solde (6 tâches)
3. **STOP et VALIDER** : Tester via `POST /accounts/{id}/adjust-balance` + formulaire Angular
4. Commit + déploiement MVP

### Incremental Delivery

1. Phase 1 → Domaine étendu
2. Phase 2 (US1) → L'utilisateur peut ajuster le solde → **MVP livrable**
3. Phase 3 (US2) → Historique traçable, immutabilité, résumé mensuel correct
4. Phase 5 → Validation globale

---

## Notes

- Aucune migration Flyway requise (R3 research.md)
- Le montant AJUSTEMENT est signé (+/-), contrairement à DEPENSE/RECETTE (R1 research.md)
- La catégorie "Ajustement" est créée lazy, pas en seed (R6 research.md)
- Pattern identique à `transfer()` dans AccountService (R4 research.md)
- 16 tâches total : 4 foundational + 6 US1 + 4 US2 + 2 polish
