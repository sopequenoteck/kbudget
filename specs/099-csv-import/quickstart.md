# Quickstart: Import de releves bancaires CSV

**Branch**: `099-csv-import` | **Date**: 2026-03-20

## Prerequisites

- Java 21, Maven, PostgreSQL 15+ (backend)
- Node.js, Angular CLI (frontend)
- Un compte existant dans l'application avec un bankCode (ex: "SG")

## Backend Setup

```bash
cd api

# Ajouter les dependances au pom.xml :
# - org.apache.commons:commons-csv:1.11.0
# - org.apache.commons:commons-text:1.12.0

# Build
mvn clean compile

# Run (profil dev)
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Tests
mvn test
```

**Flyway** : La migration V22 cree les tables `import_profiles`, `import_drafts`, `import_draft_lines`, `category_rules`, `import_history`. Elle s'applique automatiquement au demarrage.

**Config multipart** : Ajouter dans `application.yaml` :
```yaml
spring:
  servlet:
    multipart:
      max-file-size: 5MB
      max-request-size: 6MB
```

## Frontend Setup

```bash
cd app

# Install (si nouveau package)
npm install

# Dev server
ng serve

# Tests
ng test
```

## Flow de test rapide

1. **Creer un compte** avec bankCode "SG" (Societe Generale)
2. **Preparer un CSV** de test :
```csv
Date de l'operation;Detail;Montant
16/03/2026;CARTE X3855 16/03 UEP*SUPER U 101607535098170IOPD;-45.50
15/03/2026;VIR SEPA M DUPONT LOYER MARS;150.00
14/03/2026;CARTE X3855 14/03 PHARMACIE DU CENTRE;-12.80
```
3. **Upload via API** :
```bash
curl -X POST http://localhost:8080/api/imports/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@releve_test.csv" \
  -F "accountId=<uuid-du-compte>"
```
4. **Verifier le brouillon** retourne : 3 lignes, libelles nettoyes ("SUPER U", "VIR SEPA M DUPONT LOYER MARS", "PHARMACIE DU CENTRE")
5. **Confirmer l'import** :
```bash
curl -X POST http://localhost:8080/api/imports/drafts/<draft-id>/confirm \
  -H "Authorization: Bearer <token>"
```
6. **Verifier** que 3 transactions existent dans le compte

## Structure des fichiers crees

### Backend (api/src/main/java/fr/kksdev/budget/api/)

```
model/
  ImportProfile.java
  ImportDraft.java
  ImportDraftLine.java
  CategoryRule.java
  ImportHistory.java

enums/
  ImportDraftStatus.java
  ImportLineStatus.java

repository/
  ImportProfileRepository.java
  ImportDraftRepository.java
  ImportDraftLineRepository.java
  CategoryRuleRepository.java
  ImportHistoryRepository.java

service/
  ImportService.java              # Orchestration upload/confirm
  ImportProfileRegistry.java      # Profils pre-configures (statique)
  CsvParsingService.java          # Parsing CSV + detection format
  LabelCleaningService.java       # Nettoyage des libelles
  DeduplicationService.java       # Detection doublons
  CategoryRuleService.java        # CRUD regles + application
  ImportDraftCleanupJob.java      # Job quotidien expiration

controller/
  ImportController.java           # Tous les endpoints /imports/**

dto/request/
  ImportLineUpdateRequest.java
  ImportLineBatchUpdateRequest.java
  CategoryRuleRequest.java
  CsvMappingRequest.java

dto/response/
  ImportDraftResponse.java
  ImportDraftSummaryResponse.java
  ImportDraftLineResponse.java
  ImportConfirmResponse.java
  CsvPreviewResponse.java
  CategoryRuleResponse.java
  ImportProfileResponse.java
  ImportHistoryResponse.java
```

### Frontend (app/src/app/)

```
core/services/
  import.ts                       # ImportService (signal-based)
  category-rule.ts                # CategoryRuleService

features/settings/components/
  import-settings/
    import-settings.ts            # Hub Settings > Import
    import-settings.html
    import-settings.scss
  import-review/
    import-review.ts              # Review d'un brouillon
    import-review.html
    import-review.scss
  csv-mapping/
    csv-mapping.ts                # Mapping manuel des colonnes
    csv-mapping.html
    csv-mapping.scss

shared/components/
  file-upload/                    # Composant reutilisable d'upload CSV
    file-upload.ts
    file-upload.html
    file-upload.scss
```
