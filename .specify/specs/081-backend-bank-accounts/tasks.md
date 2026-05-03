# Tasks: Banques sur les comptes — Backend

**Input**: Design documents from `/specs/081-backend-bank-accounts/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.md

**Tests**: Inclus — la constitution exige des tests d'intégration sur les endpoints et des tests unitaires sur les services.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Backend: `api/src/main/java/fr/kksdev/budget/api/`
- Tests: `api/src/test/java/fr/kksdev/budget/api/`
- Resources: `api/src/main/resources/`

---

## Phase 1: Setup

**Purpose**: Migration Flyway et infrastructure statique (logos)

- [x] T001 Créer la migration Flyway V19 ajoutant bank_code, bank_custom_name, bank_custom_logo à la table accounts dans `api/src/main/resources/db/migration/V19__add_bank_to_accounts.sql`
- [x] T002 [P] Déplacer les fichiers SVG de logos de `api/src/main/resources/static/banks/` vers `api/src/main/resources/static/bank-logos/` pour éviter le conflit de path avec le endpoint REST GET /api/banks

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Registre des banques et modèle Bank — prérequis de toutes les user stories

- [x] T003 Créer le record Bank (code, name, country, brandColor, logoUrl) dans `api/src/main/java/fr/kksdev/budget/api/model/Bank.java`
- [x] T004 Créer la classe BankRegistry (Map statique des 29 banques, méthodes findByCode et getAll) dans `api/src/main/java/fr/kksdev/budget/api/service/BankRegistry.java`
- [x] T005 Enrichir l'entité Account avec les champs bankCode (String, default "OTHER"), bankCustomName (String, nullable), bankCustomLogo (String/TEXT, nullable) dans `api/src/main/java/fr/kksdev/budget/api/model/Account.java`
- [x] T006 Ajouter `/banks` et `/bank-logos/**` aux routes publiques dans `api/src/main/java/fr/kksdev/budget/api/config/SecurityConfig.java`

**Checkpoint**: Fondation prête — BankRegistry accessible, Account enrichi, routes publiques configurées.

---

## Phase 3: User Story 1 — Consulter la liste des banques supportées (Priority: P1) — MVP

**Goal**: Endpoint public GET /api/banks retournant les 29 banques avec code, nom, pays, couleur et logoUrl.

**Independent Test**: `curl http://localhost:8080/api/banks | jq length` → 29

### Tests for User Story 1

- [x] T007 [P] [US1] Tests d'intégration BankController : GET /banks retourne 29 banques, chaque banque a code/name/country/brandColor/logoUrl, endpoint accessible sans auth dans `api/src/test/java/fr/kksdev/budget/api/controller/BankControllerTest.java`

### Implementation for User Story 1

- [x] T008 [P] [US1] Créer BankResponse (record DTO : code, name, country, brandColor, logoUrl) dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BankResponse.java`
- [x] T009 [US1] Créer BankService avec méthode getAllBanks() retournant List<BankResponse> triée par pays (FR → TG → International → OTHER en dernier) puis par nom alphabétique dans `api/src/main/java/fr/kksdev/budget/api/service/BankService.java`
- [x] T010 [US1] Créer BankController avec endpoint GET /banks retournant la liste des banques dans `api/src/main/java/fr/kksdev/budget/api/controller/BankController.java`
- [x] T011 [US1] Tests unitaires BankService : getAllBanks retourne 29 entrées, tri correct (FR → TG → International → OTHER en dernier), findByCode résolution correcte dans `api/src/test/java/fr/kksdev/budget/api/service/BankServiceTest.java`

**Checkpoint**: GET /api/banks fonctionnel et testé. Les logos SVG sont servis à /api/bank-logos/{code}.svg.

---

## Phase 4: User Story 2 — Associer une banque connue à un compte (Priority: P1)

**Goal**: Création/modification d'un compte avec bankCode valide. La réponse contient les infos banque résolues.

**Independent Test**: `POST /api/accounts` avec bankCode="SG" → réponse contient bankName="Société Générale", bankBrandColor="#e2001a"

### Tests for User Story 2

- [x] T012 [P] [US2] Tests d'intégration AccountController pour bank : création avec bankCode valide, création sans bankCode → default "OTHER", création avec bankCode invalide (400), mise à jour bankCode, GET retourne infos banque résolues dans `api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java` (ajouter aux tests existants)

### Implementation for User Story 2

- [x] T013 [US2] Enrichir AccountRequest avec champs bankCode (String, nullable), bankCustomName (@Size max 100, nullable), bankCustomLogo (String, nullable) dans `api/src/main/java/fr/kksdev/budget/api/dto/request/AccountRequest.java`
- [x] T014 [US2] Enrichir AccountResponse avec champs bankCode, bankName, bankCountry, bankBrandColor, bankLogoUrl, bankCustomName, bankCustomLogo dans `api/src/main/java/fr/kksdev/budget/api/dto/response/AccountResponse.java`
- [x] T015 [US2] Enrichir AccountSummary avec champ bankCode dans `api/src/main/java/fr/kksdev/budget/api/dto/response/AccountSummary.java`
- [x] T016 [US2] Ajouter méthode resolveBank(Account) dans BankService pour résoudre bankCode → infos complètes dans `api/src/main/java/fr/kksdev/budget/api/service/BankService.java`
- [x] T017 [US2] Modifier AccountService : valider bankCode via BankRegistry lors de create/update, default "OTHER" si null, injecter BankService pour la résolution dans les réponses dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T018 [US2] Tests unitaires BankService.resolveBank : banque connue → infos résolues, OTHER → infos par défaut dans `api/src/test/java/fr/kksdev/budget/api/service/BankServiceTest.java` (compléter)

**Checkpoint**: Création/modification de comptes avec banque connue fonctionne. Réponses enrichies avec infos banque résolues.

---

## Phase 5: User Story 3 — Utiliser une banque personnalisée OTHER (Priority: P2)

**Goal**: Création d'un compte avec bankCode="OTHER" + champs personnalisés (bankCustomName, bankCustomLogo).

**Independent Test**: `POST /api/accounts` avec bankCode="OTHER", bankCustomName="Ma Banque" → réponse contient les champs custom

### Tests for User Story 3

- [x] T019 [P] [US3] Tests d'intégration : création avec OTHER + customName, création avec OTHER + customLogo, création avec OTHER + customLogo non-base64 (valeur stockée telle quelle sans erreur), création avec bankCustomName > 100 chars → 400, champs custom ignorés quand bankCode connu dans `api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java` (compléter)

### Implementation for User Story 3

- [x] T020 [US3] Ajuster BankService.resolveBank pour retourner bankCustomName/bankCustomLogo quand bankCode="OTHER", et les ignorer quand bankCode est une banque connue dans `api/src/main/java/fr/kksdev/budget/api/service/BankService.java`
- [x] T021 [US3] Tests unitaires : resolveBank avec OTHER + custom fields, resolveBank avec banque connue ignore les custom fields dans `api/src/test/java/fr/kksdev/budget/api/service/BankServiceTest.java` (compléter)

**Checkpoint**: Comptes avec banque personnalisée fonctionnels. Champs custom correctement gérés selon le bankCode.

---

## Phase 6: User Story 4 — Rétrocompatibilité des comptes existants (Priority: P1)

**Goal**: Après migration V19, tous les comptes existants ont bankCode="OTHER". Les champs icone/couleur sont préservés.

**Independent Test**: Après migration, `SELECT bank_code FROM accounts` → tous "OTHER". Les champs icone et couleur inchangés.

### Tests for User Story 4

- [x] T022 [US4] Tests d'intégration : (1) vérifier qu'un compte existant (sans bankCode) retourne bankCode="OTHER" avec icone et couleur préservés après migration ; (2) vérifier qu'un compte migré puis mis à jour avec bankCode="SG" retourne à la fois icone/couleur (préservés) ET bankName/bankBrandColor (résolus) dans `api/src/test/java/fr/kksdev/budget/api/controller/AccountControllerTest.java` (compléter)

### Implementation for User Story 4

- [x] T023 [US4] Vérifier que la migration V19 (T001) initialise correctement bank_code='OTHER' pour les comptes existants et que les colonnes icone/couleur sont inchangées — pas de code supplémentaire nécessaire si T001 est correct, sinon ajuster

**Checkpoint**: Migration rétrocompatible validée. Aucune régression sur les comptes existants.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Logging, validation finale, documentation

- [x] T024 [P] Ajouter logging INFO dans AccountService pour les opérations de changement de banque (création avec bankCode, modification de bankCode) dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T025 [P] Vérifier que les 29 fichiers SVG sont présents dans `api/src/main/resources/static/bank-logos/` et que les codes correspondent au BankRegistry
- [x] T026 Exécuter la validation quickstart.md : tester les 6 scénarios curl manuellement ou via tests
- [x] T027 Lancer `cd api && mvn clean test` pour valider que tous les tests passent (existants + nouveaux)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Pas de dépendance — migration + logos
- **Phase 2 (Foundational)**: Dépend de Phase 1 (migration doit exister pour les tests)
- **Phase 3 (US1)**: Dépend de Phase 2 (BankRegistry + Bank model)
- **Phase 4 (US2)**: Dépend de Phase 2 (Account enrichi + BankRegistry)
- **Phase 5 (US3)**: Dépend de Phase 4 (enrichissement Account/DTOs déjà en place)
- **Phase 6 (US4)**: Dépend de Phase 1 (migration V19)
- **Phase 7 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Indépendant — endpoint GET /banks isolé
- **US2 (P1)**: Indépendant de US1 — enrichissement Account via BankRegistry
- **US3 (P2)**: Dépend de US2 — extension du comportement OTHER sur les mêmes DTOs/service
- **US4 (P1)**: Indépendant — vérifie la migration V19

### Within Each User Story

- Tests écrits en premier (FAIL avant implémentation)
- DTOs avant services
- Services avant controllers
- Tests unitaires après implémentation service

### Parallel Opportunities

- T001 et T002 en parallèle (fichiers différents)
- T003 et T006 en parallèle (Bank model et SecurityConfig)
- T007 et T008 en parallèle (tests et DTO)
- T012 et T019 en parallèle (tests US2 et US3 si US2 implémenté)
- US1 et US2 en parallèle après Phase 2 (fichiers différents)
- US4 peut être vérifié dès Phase 1 terminée

---

## Parallel Example: Phase 2

```bash
# Après Phase 1, lancer en parallèle :
Task T003: "Créer record Bank dans model/Bank.java"
Task T006: "Ajouter routes publiques dans SecurityConfig.java"

# Puis séquentiellement (dépend de T003) :
Task T004: "Créer BankRegistry dans service/BankRegistry.java"
Task T005: "Enrichir Account entity"
```

## Parallel Example: US1 + US2

```bash
# Après Phase 2, lancer en parallèle :
# US1:
Task T008: "Créer BankResponse DTO"
Task T010: "Créer BankController"

# US2 (en parallèle de US1):
Task T013: "Enrichir AccountRequest"
Task T014: "Enrichir AccountResponse"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (migration + logos) — 2 tâches
2. Phase 2: Foundational (Bank model + registry + Account enrichi + SecurityConfig) — 4 tâches
3. Phase 3: User Story 1 (GET /banks) — 5 tâches
4. **STOP and VALIDATE**: curl GET /api/banks → 29 banques

### Incremental Delivery

1. Setup + Foundational → Fondation prête
2. US1 (GET /banks) → Test → Commit
3. US2 (Associer banque connue) → Test → Commit
4. US3 (Banque personnalisée OTHER) → Test → Commit
5. US4 (Rétrocompatibilité migration) → Test → Commit
6. Polish → Tests complets → Commit final

---

## Notes

- Les tests d'intégration AccountController existants doivent être adaptés (ajout bankCode dans les fixtures de test)
- BankRegistry est une classe utilitaire pure (pas un @Service Spring) — testable sans contexte Spring
- Les logos SVG dans `static/bank-logos/` sont servis automatiquement par Spring Boot
- Le bankCode par défaut "OTHER" assure la rétrocompatibilité sans intervention du client
