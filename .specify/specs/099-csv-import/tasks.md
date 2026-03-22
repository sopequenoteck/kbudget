# Tasks: Import de releves bancaires CSV

**Input**: Design documents from `/specs/099-csv-import/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/api-endpoints.md

**Tests**: Non demandes explicitement dans la spec. Les taches de test ne sont pas incluses. Les tests seront ecrits si demandes separement.

**Organization**: Tasks groupees par user story pour permettre l'implementation et le test independant de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Dependances, configuration, migration BDD

- [x] T001 Ajouter les dependances Apache Commons CSV 1.11.0 et Apache Commons Text 1.12.0 dans `api/pom.xml`
- [x] T002 Configurer le multipart file upload (max-file-size: 5MB, max-request-size: 6MB) dans `api/src/main/resources/application.yaml` et `api/src/main/resources/application-dev.yaml`
- [x] T003 Creer la migration Flyway V22 avec les 5 tables (import_profiles, import_drafts, import_draft_lines, category_rules, import_history) et leurs index dans `api/src/main/resources/db/migration/V22__csv_import.sql`
- [x] T004 [P] Creer l'enum ImportDraftStatus (PENDING, COMPLETED, EXPIRED) dans `api/src/main/java/fr/kksdev/budget/api/enums/ImportDraftStatus.java`
- [x] T005 [P] Creer l'enum ImportLineStatus (READY, NEEDS_REVIEW, DUPLICATE, SKIPPED) dans `api/src/main/java/fr/kksdev/budget/api/enums/ImportLineStatus.java`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Entites JPA, repositories et registre de profils pre-configures — necessaires avant toute implementation de user story

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 [P] Creer l'entite ImportDraft (id, user, account, status, fileName, totalLines, readyCount, reviewCount, duplicateCount, skippedCount, profileId, profileSource, createdAt, expiresAt) dans `api/src/main/java/fr/kksdev/budget/api/model/ImportDraft.java`
- [x] T007 [P] Creer l'entite ImportDraftLine (id, draft, lineNumber, rawLabel, cleanLabel, amount, date, transactionType, status, statusMessage, category, duplicateTransactionId, createdAt, updatedAt) dans `api/src/main/java/fr/kksdev/budget/api/model/ImportDraftLine.java`
- [x] T008 [P] Creer l'entite CategoryRule (id, user, pattern, category, createdAt) dans `api/src/main/java/fr/kksdev/budget/api/model/CategoryRule.java`
- [x] T009 [P] Creer l'entite ImportHistory (id, user, account, transactionCount, fileName, importedAt) dans `api/src/main/java/fr/kksdev/budget/api/model/ImportHistory.java`
- [x] T010 [P] Creer l'entite ImportProfile (id, user, name, separator, dateFormat, dateColumn, amountColumn, debitColumn, creditColumn, labelColumn, encoding, decimalSeparator, skipHeaderLines, createdAt, updatedAt) dans `api/src/main/java/fr/kksdev/budget/api/model/ImportProfile.java`
- [x] T011 [P] Creer ImportDraftRepository (findByUserIdAndAccountIdAndStatus, findByUserId, deleteByStatusAndExpiresAtBefore) dans `api/src/main/java/fr/kksdev/budget/api/repository/ImportDraftRepository.java`
- [x] T012 [P] Creer ImportDraftLineRepository (findByDraftIdOrderByLineNumber, countByDraftIdAndStatus) dans `api/src/main/java/fr/kksdev/budget/api/repository/ImportDraftLineRepository.java`
- [x] T013 [P] Creer CategoryRuleRepository (findByUserIdOrderByCreatedAtAsc, existsByUserIdAndPatternIgnoreCase) dans `api/src/main/java/fr/kksdev/budget/api/repository/CategoryRuleRepository.java`
- [x] T014 [P] Creer ImportHistoryRepository (findByUserIdOrderByImportedAtDesc) dans `api/src/main/java/fr/kksdev/budget/api/repository/ImportHistoryRepository.java`
- [x] T015 [P] Creer ImportProfileRepository (findByUserId) dans `api/src/main/java/fr/kksdev/budget/api/repository/ImportProfileRepository.java`
- [x] T016 Creer ImportProfileRegistry (classe statique, pattern BankRegistry) avec le profil Societe Generale (SG) et le record ImportProfileConfig dans `api/src/main/java/fr/kksdev/budget/api/service/ImportProfileRegistry.java`
- [x] T017 [P] Creer les DTOs response : ImportDraftResponse, ImportDraftSummaryResponse, ImportDraftLineResponse, ImportConfirmResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/response/` (4 fichiers)
- [x] T018 [P] Creer les DTOs request : ImportLineUpdateRequest, ImportLineBatchUpdateRequest dans `api/src/main/java/fr/kksdev/budget/api/dto/request/` (2 fichiers)

**Checkpoint**: Foundation ready — entities, repositories, registry, DTOs de base prets. User story implementation can now begin.

---

## Phase 3: User Story 1 — Importer un releve CSV depuis un compte (Priority: P1) MVP

**Goal**: L'utilisateur uploade un CSV depuis l'icone d'import d'un compte, le systeme parse automatiquement, nettoie les libelles, et l'utilisateur confirme l'import pour creer les transactions en masse.

**Independent Test**: Uploader un CSV SG reel, verifier que le parsing produit des lignes avec libelles nettoyes et types corrects, confirmer l'import et verifier que les transactions sont creees dans le bon compte.

### Backend US1

- [x] T019 [US1] Implementer LabelCleaningService (pipeline regex configurable par profil, regles generiques en fallback, guard chaine vide) dans `api/src/main/java/fr/kksdev/budget/api/service/LabelCleaningService.java`
- [x] T020 [US1] Implementer CsvParsingService (detection format via bankCode + fallback analyse contenu, parsing Commons CSV, detection strategie montant signe/double colonne, application nettoyage libelles, creation des ImportDraftLine avec statut READY ou NEEDS_REVIEW) dans `api/src/main/java/fr/kksdev/budget/api/service/CsvParsingService.java`
- [x] T021 [US1] Implementer ImportService — methode upload(MultipartFile, accountId, userId) : validation fichier (taille, format, compte actif), verification brouillon existant (409 si deja un PENDING pour ce compte), resolution profil (registry par bankCode → fallback analyse), delegation parsing, persistance brouillon + lignes, retour ImportDraftResponse dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T022 [US1] Implementer ImportService — methode confirm(draftId, userId) : verification statut PENDING, verification que toutes les lignes sont READY ou SKIPPED (rejet si NEEDS_REVIEW ou DUPLICATE non resolues), creation transactions via transactionRepository.saveAll() dans @Transactional tout-ou-rien, creation ImportHistory, passage draft en COMPLETED, retour ImportConfirmResponse dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T023 [US1] Implementer ImportService — methodes getDraft(draftId, userId), deleteDraft(draftId, userId), updateLine(draftId, lineId, request, userId) dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T024 [US1] Creer ImportController avec les endpoints : POST /imports/upload (multipart), GET /imports/drafts/{draftId}, PUT /imports/drafts/{draftId}/lines/{lineId}, POST /imports/drafts/{draftId}/confirm, DELETE /imports/drafts/{draftId} dans `api/src/main/java/fr/kksdev/budget/api/controller/ImportController.java`
- [x] T025 [US1] Ajouter les routes /imports/** dans SecurityConfig (routes authentifiees) dans `api/src/main/java/fr/kksdev/budget/api/config/SecurityConfig.java`

### Frontend US1

- [x] T026 [US1] Creer le service Angular ImportService (signal-based, refreshTrigger, methodes upload, getDraft, updateLine, confirm, deleteDraft) dans `app/src/app/core/services/import.ts`
- [x] T027 [US1] Creer le modele TypeScript ImportDraft, ImportDraftLine, ImportConfirmResult et les types associes dans `app/src/app/core/models/import.model.ts`
- [x] T028 [US1] Creer le composant ImportReview (affichage des lignes du brouillon par statut, edition categorie/statut par ligne, bouton confirmer actif quand toutes les lignes sont READY ou SKIPPED, indicateur de progression basique) dans `app/src/app/features/settings/components/import-review/import-review.ts` et `.html` et `.scss`
- [x] T029 [US1] Ajouter l'icone d'import (PhosphorIcons upload) sur chaque compte dans la page comptes — clic declenche un file input hidden (accept=".csv"), upload via ImportService, puis navigation vers /settings/import/review/:draftId dans `app/src/app/features/settings/components/accounts/accounts.ts`
- [x] T030 [US1] Ajouter les routes /settings/import et /settings/import/review/:draftId dans `app/src/app/features/settings/settings.routes.ts`
- [x] T031 [US1] Creer un composant minimal ImportSettings (hub) qui redirige vers le review apres upload — sera enrichi en US2 dans `app/src/app/features/settings/components/import-settings/import-settings.ts` et `.html` et `.scss`
- [x] T032 [US1] Ajouter l'entree "Import" dans le tableau SECTIONS du hub Settings (groupe management, icone phUploadSimple, couleur #10b981) dans `app/src/app/features/settings/settings.ts`

**Checkpoint**: US1 complete — import CSV de bout en bout fonctionnel (upload SG → parsing → review → confirm → transactions creees). MVP deployable.

---

## Phase 4: User Story 2 — Page dediee Import avec gestion des brouillons (Priority: P2)

**Goal**: Page Settings > Import complete avec liste des brouillons en cours, historique des imports finalises, et reprise de brouillon.

**Independent Test**: Creer un brouillon, quitter la page, revenir et le reprendre. Verifier l'historique apres un import finalise. Verifier qu'un brouillon expire apres 7 jours.

### Backend US2

- [x] T033 [US2] Creer les DTOs ImportHistoryResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/response/ImportHistoryResponse.java`
- [x] T034 [US2] Implementer ImportService — methodes listDrafts(userId), listHistory(userId, page, size) dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T035 [US2] Ajouter les endpoints GET /imports/drafts (liste brouillons), GET /imports/history (historique pagine) dans `api/src/main/java/fr/kksdev/budget/api/controller/ImportController.java`
- [x] T036 [US2] Implementer ImportDraftCleanupJob (@Scheduled cron 0 0 3 * * *, suppression brouillons expires, pattern NotificationScheduler) dans `api/src/main/java/fr/kksdev/budget/api/service/ImportDraftCleanupJob.java`

### Frontend US2

- [x] T037 [US2] Enrichir ImportSettings avec 3 sections : brouillons en cours (liste avec nom compte, nb lignes, date, bouton reprendre/supprimer), historique (liste avec date, compte, nb transactions), bouton "Nouvel import" (file input + select compte) dans `app/src/app/features/settings/components/import-settings/import-settings.ts` et `.html` et `.scss`
- [x] T038 [US2] Implementer la navigation depuis l'icone d'import d'un compte vers /settings/import avec query param ?accountId=xxx pour pre-selection du compte dans `app/src/app/features/settings/components/accounts/accounts.ts` et `import-settings.ts`

**Checkpoint**: US2 complete — page Import fonctionnelle avec brouillons, historique, et cleanup automatique.

---

## Phase 5: User Story 3 — Categorisation intelligente et regles de mapping (Priority: P2)

**Goal**: Le systeme propose automatiquement des categories basees sur les regles de l'utilisateur. L'utilisateur peut gerer ses regles depuis Settings > Import.

**Independent Test**: Importer un CSV, categoriser manuellement une ligne, creer la regle, puis importer un second CSV avec le meme libelle et verifier la categorie pre-remplie.

### Backend US3

- [x] T039 [US3] Implementer CategoryRuleService (CRUD regles, methode applyRules(List<ImportDraftLine>, userId) qui matche les patterns par containment case-insensitive en ordre de creation) dans `api/src/main/java/fr/kksdev/budget/api/service/CategoryRuleService.java`
- [x] T040 [US3] Creer les DTOs CategoryRuleRequest et CategoryRuleResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/request/CategoryRuleRequest.java` et `api/src/main/java/fr/kksdev/budget/api/dto/response/CategoryRuleResponse.java`
- [x] T041 [US3] Ajouter les endpoints GET /imports/rules, POST /imports/rules, PUT /imports/rules/{ruleId}, DELETE /imports/rules/{ruleId} dans `api/src/main/java/fr/kksdev/budget/api/controller/ImportController.java`
- [x] T042 [US3] Integrer CategoryRuleService dans CsvParsingService — appliquer les regles apres parsing pour pre-remplir les categories et passer les lignes matchees en READY dans `api/src/main/java/fr/kksdev/budget/api/service/CsvParsingService.java`
- [x] T043 [US3] Ajouter dans ImportService.updateLine() la proposition de creation de regle quand l'utilisateur assigne manuellement une categorie (retourner un flag suggestRule dans ImportDraftLineResponse) dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`

### Frontend US3

- [x] T044 [US3] Creer le service Angular CategoryRuleService (signal-based, CRUD regles) dans `app/src/app/core/services/category-rule.ts`
- [x] T045 [US3] Ajouter la section "Regles de categorisation" dans ImportSettings (liste des regles avec pattern + categorie, boutons ajouter/modifier/supprimer, formulaire modal) dans `app/src/app/features/settings/components/import-settings/import-settings.ts` et `.html` et `.scss`
- [x] T046 [US3] Enrichir ImportReview — quand l'utilisateur assigne une categorie a une ligne, proposer un dialog de creation de regle si suggestRule=true dans `app/src/app/features/settings/components/import-review/import-review.ts` et `.html`

**Checkpoint**: US3 complete — categorisation automatique fonctionnelle, regles CRUD, proposition de creation de regle.

---

## Phase 6: User Story 4 — Deduplication et resolution de conflits (Priority: P2)

**Goal**: Le systeme detecte les doublons potentiels lors du parsing et les presente a l'utilisateur pour resolution.

**Independent Test**: Creer une transaction manuellement, importer un CSV contenant la meme transaction, verifier que la ligne est marquee DUPLICATE avec reference vers la transaction existante.

### Backend US4

- [x] T047 [US4] Implementer DeduplicationService (requete transactions existantes sur plage dates CSV ± 3 jours, matching exact date+montant, matching flou libelle Jaro-Winkler seuil 0.85, retour des duplicates avec reference transactionId) dans `api/src/main/java/fr/kksdev/budget/api/service/DeduplicationService.java`
- [x] T048 [US4] Ajouter la methode findByUserIdAndAccountIdAndDateBetween dans TransactionRepository pour la fenetre de deduplication dans `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java`
- [x] T049 [US4] Integrer DeduplicationService dans ImportService.upload() — apres parsing, avant persistance, marquer les lignes DUPLICATE avec duplicateTransactionId dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`

### Frontend US4

- [x] T050 [US4] Enrichir ImportReview — afficher les lignes DUPLICATE avec un comparatif visuel (transaction existante vs ligne importee), boutons "Importer quand meme" (→ READY) et "Ignorer" (→ SKIPPED) dans `app/src/app/features/settings/components/import-review/import-review.ts` et `.html` et `.scss`

**Checkpoint**: US4 complete — deduplication fonctionnelle, resolution interactive des doublons.

---

## Phase 7: User Story 5 — Profils d'import par banque et mapping custom (Priority: P3)

**Goal**: Detection automatique du format CSV par profil pre-configure, mapping manuel pour banques inconnues, sauvegarde de profils personnalises.

**Independent Test**: Importer un CSV SG (detection auto), puis un CSV inconnu (mapping manuel), sauvegarder le profil, reimporter un CSV de la meme banque (profil auto-applique).

### Backend US5

- [x] T051 [US5] Creer les DTOs CsvMappingRequest, CsvPreviewResponse, ImportProfileResponse dans `api/src/main/java/fr/kksdev/budget/api/dto/request/CsvMappingRequest.java` et `api/src/main/java/fr/kksdev/budget/api/dto/response/CsvPreviewResponse.java` et `api/src/main/java/fr/kksdev/budget/api/dto/response/ImportProfileResponse.java`
- [x] T052 [US5] Implementer ImportService — methode preview(MultipartFile, separator, encoding, skipHeaderLines) : lecture des 5 premieres lignes, detection separateur et encodage, retour headers + rows dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T053 [US5] Implementer ImportService — methode uploadWithMapping(MultipartFile, accountId, CsvMappingRequest, userId) : parsing avec mapping custom, sauvegarde optionnelle du profil (saveAsProfile + profileName) dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T054 [US5] Implementer ImportService — methodes listProfiles(userId), deleteProfile(profileId, userId) dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T055 [US5] Ajouter les endpoints GET /imports/preview (multipart), POST /imports/upload-with-mapping (multipart), GET /imports/profiles, DELETE /imports/profiles/{profileId} dans `api/src/main/java/fr/kksdev/budget/api/controller/ImportController.java`
- [x] T056 [US5] Enrichir la resolution de profil dans CsvParsingService — apres registry statique, chercher les profils custom de l'utilisateur avant le fallback analyse contenu dans `api/src/main/java/fr/kksdev/budget/api/service/CsvParsingService.java`

### Frontend US5

- [x] T057 [US5] Creer le composant CsvMapping (preview des colonnes detectees, selection manuelle date/montant/libelle, choix separateur/encodage/format date, option sauvegarder comme profil) dans `app/src/app/features/settings/components/csv-mapping/csv-mapping.ts` et `.html` et `.scss`
- [x] T058 [US5] Enrichir ImportService Angular — methodes preview(), uploadWithMapping(), getProfiles(), deleteProfile() dans `app/src/app/core/services/import.ts`
- [x] T059 [US5] Enrichir ImportSettings — gerer le cas 422 (format non reconnu) en naviguant vers CsvMapping, ajouter section "Profils" (liste profils pre-configures en lecture seule + profils custom editables/supprimables) dans `app/src/app/features/settings/components/import-settings/import-settings.ts` et `.html`
- [x] T060 [US5] Ajouter la route /settings/import/mapping dans `app/src/app/features/settings/settings.routes.ts`

**Checkpoint**: US5 complete — detection auto, mapping manuel, profils custom sauvegardables.

---

## Phase 8: User Story 6 — Actions groupees et progression (Priority: P3)

**Goal**: Actions en masse sur les lignes d'un brouillon et indicateur de progression par statut.

**Independent Test**: Importer un CSV de 50+ lignes, selectionner plusieurs lignes, appliquer une categorie en masse, verifier la mise a jour et l'indicateur de progression.

### Backend US6

- [x] T061 [US6] Implementer ImportService — methode batchUpdateLines(draftId, ImportLineBatchUpdateRequest, userId) : mise a jour en masse categorie et/ou statut, recalcul des compteurs du brouillon dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T062 [US6] Ajouter l'endpoint PUT /imports/drafts/{draftId}/lines/batch dans `api/src/main/java/fr/kksdev/budget/api/controller/ImportController.java`

### Frontend US6

- [x] T063 [US6] Enrichir ImportReview — ajouter selection multiple (checkboxes), barre d'actions groupees (assigner categorie, ignorer, valider), indicateur de progression par statut (READY/NEEDS_REVIEW/DUPLICATE/SKIPPED avec compteurs et barre de progression), bouton "Confirmer" actif uniquement quand aucune ligne NEEDS_REVIEW dans `app/src/app/features/settings/components/import-review/import-review.ts` et `.html` et `.scss`

**Checkpoint**: US6 complete — actions groupees et progression fonctionnels.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Qualite, logging, edge cases

- [x] T064 Ajouter le logging INFO dans ImportService (upload, confirm, cleanup) et ERROR pour les erreurs de parsing dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java`
- [x] T065 [P] Verifier les edge cases : CSV vide, CSV > 5 Mo, montants invalides, dates invalides, compte inactif, compte supprime pendant brouillon, nettoyage libelle vide — s'assurer que les messages d'erreur sont explicites dans `api/src/main/java/fr/kksdev/budget/api/service/ImportService.java` et `CsvParsingService.java`
- [x] T066 [P] Valider le flow complet via quickstart.md : creer un compte SG, uploader le CSV de test, verifier parsing + libelles nettoyes + confirmation + transactions creees
- [x] T067 Verifier la coherence design tokens Angular : utiliser var(--token) pour tous les styles de import-settings, import-review, csv-mapping dans `app/src/app/features/settings/components/import-*/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (enums T004-T005 needed by entities) — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — delivers MVP
- **US2 (Phase 4)**: Depends on US1 (besoin du flow upload/confirm pour le hub)
- **US3 (Phase 5)**: Depends on Foundational only — peut etre fait en parallele de US1 pour le backend, mais le frontend s'integre dans ImportReview (US1)
- **US4 (Phase 6)**: Depends on US1 (s'integre dans le flow upload)
- **US5 (Phase 7)**: Depends on US1 (enrichit le flow upload avec le fallback mapping)
- **US6 (Phase 8)**: Depends on US1 (enrichit ImportReview)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational)
    │
    ▼
Phase 3 (US1 — MVP) ◄── REQUIRED FIRST
    │
    ├──► Phase 4 (US2 — Page Import)
    ├──► Phase 5 (US3 — Categorisation) ← backend parallelisable avec US1
    ├──► Phase 6 (US4 — Deduplication)
    ├──► Phase 7 (US5 — Profils custom)
    └──► Phase 8 (US6 — Actions groupees)
              │
              ▼
         Phase 9 (Polish)
```

### Within Each User Story

- Backend avant frontend (API-First, constitution principe I)
- Services avant controller
- DTOs avant services qui les utilisent
- Integration dans services existants en dernier

### Parallel Opportunities

**Phase 1**: T004 et T005 en parallele (enums independants)
**Phase 2**: T006-T015 tous parallelisables (entites et repositories independants), T017-T018 parallelisables (DTOs)
**Phase 3 backend**: T019 et T020 partiellement parallelisables (LabelCleaningService est appele par CsvParsingService mais peut etre code en parallele)
**Phase 3 frontend**: T026-T027 parallelisables (service et modeles)
**US2-US6**: Les backends de US3 et US4 sont parallelisables entre eux (services independants)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch all entities in parallel:
Task T006: "ImportDraft entity"
Task T007: "ImportDraftLine entity"
Task T008: "CategoryRule entity"
Task T009: "ImportHistory entity"
Task T010: "ImportProfile entity"

# Launch all repositories in parallel:
Task T011: "ImportDraftRepository"
Task T012: "ImportDraftLineRepository"
Task T013: "CategoryRuleRepository"
Task T014: "ImportHistoryRepository"
Task T015: "ImportProfileRepository"
```

## Parallel Example: Phase 3 Backend (US1)

```bash
# Launch services in parallel (different files):
Task T019: "LabelCleaningService"
Task T020: "CsvParsingService" (depends on T019 interface, but can be coded in parallel)

# Sequential after services:
Task T021-T023: "ImportService" (depends on T019, T020)
Task T024: "ImportController" (depends on T021-T023)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T018)
3. Complete Phase 3: User Story 1 (T019-T032)
4. **STOP and VALIDATE**: Upload un CSV SG, verifier parsing + libelles nettoyes + confirmation
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 → Test independently → Deploy (MVP!)
3. US2 + US3 → Ajouter page import + categorisation → Deploy
4. US4 → Ajouter deduplication → Deploy
5. US5 + US6 → Profils custom + actions groupees → Deploy (feature complete)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Cette iteration couvre backend (Spring Boot) + frontend (Angular) uniquement. Flutter sera traite dans une iteration ulterieure.
- Pense a verifier `/sync-doc` apres les commits
