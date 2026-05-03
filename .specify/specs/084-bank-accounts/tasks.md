# Tasks: Banques sur les comptes — liste pré-définie avec logos embarqués

**Input**: Design documents from `/specs/084-bank-accounts/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/bank-api.md
**Status**: Done (tâches rétroactives — KKS-197/198/199 terminées)

**Tests**: Inclus (tests d'intégration backend + tests widget Flutter).

**Organization**: Tâches groupées par user story, chaque story couvrant les 3 plateformes (backend, Angular, Flutter).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans les descriptions

## Phase 1: Setup (Infrastructure partagée)

**Purpose**: Assets SVG, migration BDD, registre statique des banques

- [x] T001 Sourcer et embarquer les 29 logos SVG des banques dans `api/src/main/resources/static/bank-logos/*.svg`
- [x] T002 [P] Copier les 29 logos SVG dans `flutter/assets/banks/*.svg` et déclarer dans `flutter/pubspec.yaml`
- [x] T003 Créer la migration Flyway V19 pour enrichir la table accounts (+bankCode, bankCustomName, bankCustomLogo) dans `api/src/main/resources/db/migration/V19__add_bank_to_accounts.sql`
- [x] T004 [P] Créer le record Bank (code, name, country, brandColor, logoUrl) dans `api/src/main/java/fr/kksdev/budget/api/model/Bank.java`
- [x] T005 Créer BankRegistry avec les 29 banques statiques (findByCode, getAll) dans `api/src/main/java/fr/kksdev/budget/api/service/BankRegistry.java`
- [x] T006 [P] Créer la migration Drift v2→v3 (+3 colonnes accounts) dans `flutter/lib/src/data/local/database.dart`

---

## Phase 2: Foundational (Data layer + API endpoint)

**Purpose**: Endpoint GET /banks, enrichissement Account entity/DTOs, BankService — bloque toutes les user stories

**CRITICAL**: Aucune user story ne peut commencer avant cette phase

- [x] T007 Enrichir l'entité Account JPA (+bankCode, bankCustomName, bankCustomLogo) dans `api/src/main/java/fr/kksdev/budget/api/model/Account.java`
- [x] T008 Créer BankResponse DTO dans `api/src/main/java/fr/kksdev/budget/api/dto/BankResponse.java`
- [x] T009 [P] Enrichir AccountRequest DTO (+bankCode, bankCustomName, bankCustomLogo) dans `api/src/main/java/fr/kksdev/budget/api/dto/AccountRequest.java`
- [x] T010 [P] Enrichir AccountResponse DTO (+7 champs bank résolus) dans `api/src/main/java/fr/kksdev/budget/api/dto/AccountResponse.java`
- [x] T011 Créer BankService (getAllBanks trié, resolveBank → BankResolvedInfo) dans `api/src/main/java/fr/kksdev/budget/api/service/BankService.java`
- [x] T012 Créer BankController GET /banks (public) dans `api/src/main/java/fr/kksdev/budget/api/controller/BankController.java`
- [x] T013 Déclarer GET /banks comme route publique dans `api/src/main/java/fr/kksdev/budget/api/config/SecurityConfig.java`
- [x] T014 Mettre à jour AccountService pour mapper les champs bank dans les opérations CRUD dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T015 [P] Créer Bank model Freezed dans `flutter/lib/src/domain/models/bank.dart`
- [x] T016 [P] Créer BankResponse DTO dans `flutter/lib/src/data/remote/dtos/bank_dtos.dart`
- [x] T017 Créer BankRemoteDataSource (GET /api/banks) dans `flutter/lib/src/data/remote/data_sources/bank_remote_data_source.dart`
- [x] T018 Créer BankRepository interface dans `flutter/lib/src/domain/repositories/bank_repository.dart`
- [x] T019 Créer BankRepositoryRemote implémentation dans `flutter/lib/src/features/accounts/data/bank_repository_remote.dart`
- [x] T020 Créer banksProvider (FutureProvider) dans `flutter/lib/src/features/accounts/application/bank_provider.dart`
- [x] T021 [P] Enrichir Account model Freezed (+7 champs bank) dans `flutter/lib/src/domain/models/account.dart`
- [x] T022 [P] Enrichir Account interface Angular (+7 champs bank) dans `app/src/app/core/models/account.model.ts`
- [x] T023 Créer BankService Angular (signal-based, cache lazy, GET /banks) dans `app/src/app/core/services/bank.ts`
- [x] T024 Tests BankService backend dans `api/src/test/java/.../service/BankServiceTest.java`
- [x] T025 [P] Tests BankController backend dans `api/src/test/java/.../controller/BankControllerTest.java`

**Checkpoint**: API fonctionnelle, data layer prêt sur les 3 plateformes

---

## Phase 3: User Story 1 - Sélectionner une banque lors de la création d'un compte (Priority: P1)

**Goal**: L'utilisateur choisit une banque connue dans un sélecteur groupé par pays. Le logo et la couleur brand sont appliqués automatiquement.

**Independent Test**: Créer un compte avec "Société Générale" sélectionnée → vérifier logo SG et couleur #e4002b affichés partout.

### Implementation for User Story 1

- [x] T026 [P] [US1] Créer BankSelect composant Angular (ControlValueAccessor, groupement FR/TG/Intl, recherche temps réel) dans `app/src/app/shared/components/bank-select/bank-select.ts`
- [x] T027 [P] [US1] Créer BankSelectPicker composant Flutter (bottom sheet, groupement, recherche) dans `flutter/lib/src/common_widgets/bank_select_picker.dart`
- [x] T028 [US1] Intégrer BankSelect dans AccountForm Angular (sélecteur banque, masquage icône/couleur si banque connue) dans `app/src/app/features/accounts/account-form/`
- [x] T029 [US1] Intégrer BankSelectPicker dans AccountFormScreen Flutter (sélecteur banque, masquage conditionnel) dans `flutter/lib/src/features/accounts/presentation/account_form_screen.dart`

**Checkpoint**: Création de compte avec banque connue fonctionnelle sur Angular et Flutter

---

## Phase 4: User Story 2 - Utiliser une banque non listée "Autre" (Priority: P1)

**Goal**: L'utilisateur sélectionne "Autre", saisit un nom custom, uploade optionnellement un logo compressé.

**Independent Test**: Créer un compte avec "Autre" + nom custom + logo uploadé → vérifier affichage du logo custom.

### Implementation for User Story 2

- [x] T030 [P] [US2] Créer image.utils.ts (compressImage partagé) dans `app/src/app/shared/utils/image.utils.ts`
- [x] T031 [US2] Ajouter logique "Autre" dans AccountForm Angular (champs nom custom, upload logo, compression) dans `app/src/app/features/accounts/account-form/`
- [x] T032 [US2] Ajouter logique "Autre" dans AccountFormScreen Flutter (nom custom, upload logo 512px via image_picker) dans `flutter/lib/src/features/accounts/presentation/account_form_screen.dart`

**Checkpoint**: Création de compte avec banque custom fonctionnelle sur les 2 frontends

---

## Phase 5: User Story 3 - Consulter la liste des banques pré-définies (Priority: P2)

**Goal**: Les banques sont affichées groupées par pays avec recherche en temps réel dans le sélecteur.

**Independent Test**: Ouvrir le sélecteur, vérifier 3 groupes (FR/TG/Intl) + filtrage par recherche.

### Implementation for User Story 3

- [x] T033 [US3] Implémenter le tri getAllBanks (FR→TG→Intl→OTHER) dans BankService backend dans `api/src/main/java/fr/kksdev/budget/api/service/BankService.java`
- [x] T034 [P] [US3] Implémenter groupedBanks computed + filteredGroups dans BankSelect Angular dans `app/src/app/shared/components/bank-select/bank-select.ts`
- [x] T035 [P] [US3] Implémenter groupement + recherche dans BankSelectPicker Flutter dans `flutter/lib/src/common_widgets/bank_select_picker.dart`

**Checkpoint**: Sélecteur avec groupement et recherche fonctionnels

---

## Phase 6: User Story 4 - Rétrocompatibilité des comptes existants (Priority: P1)

**Goal**: Comptes existants reçoivent `bank_code = 'OTHER'` via migration. Affichage inchangé (emoji + couleur d'origine).

**Independent Test**: Après migration, vérifier que les comptes existants s'affichent exactement comme avant.

### Implementation for User Story 4

- [x] T036 [P] [US4] Créer AccountBankIcon composant Angular (cascade : SVG banque → data URI custom → emoji fallback) dans `app/src/app/shared/components/account-bank-icon/account-bank-icon.ts`
- [x] T037 [P] [US4] Créer AccountBankIcon widget Flutter (cascade : SVG asset → base64 → emoji fallback) dans `flutter/lib/src/common_widgets/account_bank_icon.dart`
- [x] T038 [US4] Remplacer les affichages emoji par AccountBankIcon dans tous les écrans Angular (dashboard, listes, sélecteurs)
- [x] T039 [US4] Remplacer les affichages emoji par AccountBankIcon dans tous les écrans Flutter (AccountListTile, HeroAccountSection, formulaires)
- [x] T040 [P] [US4] Enrichir SelectPickerItem avec imageUrl dans `app/src/app/shared/components/select-picker/`
- [x] T041 [P] [US4] Enrichir SelectPickerItem avec imageUrl dans `flutter/lib/src/common_widgets/select_picker.dart`
- [x] T042 [US4] Tests widget AccountBankIcon Flutter (9 tests : SVG, base64, emoji fallback) dans `flutter/test/src/common_widgets/account_bank_icon_test.dart`
- [x] T042b [P] [US4] Tests unitaires Angular composants bank (BankSelect, AccountBankIcon, AccountForm enrichi) — couverts dans la suite de tests Angular (347 tests total)

**Checkpoint**: Tous les comptes (nouveaux et existants) s'affichent correctement avec la cascade de résolution

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, nettoyage

- [x] T043 [P] Mettre à jour la documentation (README.md, docs/architecture.md) avec les informations banque
- [x] T044 [P] Synchroniser CLAUDE.md avec les changements (Recent Changes, Active Technologies)
- [x] T045 Vérifier que tous les tests passent (442 backend, 347 Angular, 604 Flutter)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — démarrage immédiat
- **Foundational (Phase 2)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2 — sélecteur banque connue
- **US2 (Phase 4)**: Dépend de Phase 2 + US1 (réutilise le sélecteur) — option "Autre"
- **US3 (Phase 5)**: Dépend de Phase 2 — groupement/recherche (implémenté en même temps que US1)
- **US4 (Phase 6)**: Dépend de Phase 2 — cascade d'affichage (indépendant de US1/US2)
- **Polish (Phase 7)**: Dépend de toutes les user stories

### User Story Dependencies

- **US1 (P1)**: Après Phase 2. Indépendant des autres stories.
- **US2 (P1)**: Après Phase 2. Réutilise le sélecteur de US1.
- **US3 (P2)**: Après Phase 2. Implémenté en même temps que US1 (même composant sélecteur).
- **US4 (P1)**: Après Phase 2. Totalement indépendant.

### Parallel Opportunities

- T001/T002 (assets SVG) en parallèle avec T003 (migration) et T004/T005 (registre)
- T009/T010 (DTOs) en parallèle
- T015/T016 (Flutter models) en parallèle avec T022/T023 (Angular models)
- T024/T025 (tests backend) en parallèle
- T026/T027 (sélecteurs Angular/Flutter) en parallèle
- T036/T037 (AccountBankIcon Angular/Flutter) en parallèle
- US1 et US4 peuvent être implémentées en parallèle

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Backend DTOs en parallèle :
Task T009: "Enrichir AccountRequest DTO"
Task T010: "Enrichir AccountResponse DTO"

# Flutter + Angular data layer en parallèle :
Task T015: "Créer Bank model Freezed"
Task T016: "Créer BankResponse DTO Flutter"
Task T022: "Enrichir Account interface Angular"
Task T023: "Créer BankService Angular"

# Tests backend en parallèle :
Task T024: "Tests BankService"
Task T025: "Tests BankController"
```

---

## Implementation Strategy

### MVP First (US1 + US4)

1. Phase 1: Setup (assets, migration, registre)
2. Phase 2: Foundational (API, data layer)
3. Phase 3: US1 — sélecteur banque connue
4. Phase 6: US4 — cascade d'affichage + rétrocompatibilité
5. **VALIDATE**: Comptes avec banque connue fonctionnels + existants préservés

### Incremental Delivery

1. Setup + Foundational → API prête, endpoint GET /banks fonctionnel
2. US1 + US3 → Sélecteur banque avec groupement et recherche (MVP)
3. US2 → Option "Autre" avec logo custom
4. US4 → AccountBankIcon cascade + remplacement dans tous les écrans
5. Polish → Documentation, tests finaux

### Exécution réelle (KKS-197/198/199)

L'implémentation a suivi cet ordre :
1. **KKS-197** (backend) : Phase 1 + Phase 2 (T001–T025)
2. **KKS-198** (Angular) : US1–US4 côté Angular (T026, T028, T030–T031, T034, T036, T038, T040)
3. **KKS-199** (Flutter) : US1–US4 côté Flutter (T027, T029, T032, T035, T037, T039, T041–T042)

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label = traçabilité vers la user story
- Toutes les tâches sont marquées [x] (done) — spec rétroactive
- 46 tâches au total couvrant 76 fichiers modifiés/créés
- 442 tests backend + 347 tests Angular + 604 tests Flutter validés
