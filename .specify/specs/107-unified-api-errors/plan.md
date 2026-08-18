# Implementation Plan: Contrat unifie des erreurs API

**Branch**: `courante (aucun changement de branche autorise)` | **Date**: 2026-08-18 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `.specify/specs/107-unified-api-errors/spec.md`

## Summary

Remplacer dans `GlobalExceptionHandler` les corps historiques ou hybrides par le record existant `ErrorResponse(error, message)`, sans changer les statuts HTTP. Chaque branche generique recoit le code stable defini par la specification, les exceptions specialisees conservent leur code, les conflits connus gardent leur traduction publique et les erreurs 500 utilisent un message constant qui ne depend jamais de l'exception. Mettre ensuite en conformite les tests backend, verifier et adapter les consommateurs Angular et leurs tests au seul acces `HttpErrorResponse.error.message` / `HttpErrorResponse.error.error`, puis faire de `docs/api-errors.md` la reference unique du contrat.

## Technical Context

**Language/Version**: Java 21; TypeScript 5.9  
**Primary Dependencies**: Spring Boot 4.x (Spring Web MVC, Spring Security, Jakarta Validation); Angular 21, RxJS 7.8  
**Storage**: N/A — aucun modele persistant ni migration  
**Testing**: JUnit 5, AssertJ et Spring MVC Test cote backend; Vitest cote Angular  
**Target Platform**: API REST auto-hebergee et PWA Angular  
**Project Type**: Application web avec backend Maven (`api/`) et frontend Angular (`app/`)  
**Performance Goals**: Aucun changement mesurable de latence ou de charge; construction d'un DTO constant par erreur  
**Constraints**: Corps gere exactement `{ error, message }`; statuts HTTP inchanges; champs non vides; aucune modification des filtres, allowlists ou decisions d'authentification; aucun detail interne dans le 500; Flutter hors perimetre  
**Scale/Scope**: Un gestionnaire global et son DTO existant, leurs tests, les consommateurs Angular qui lisent un corps d'erreur, leurs tests affectes, et une documentation de contrat

## Constitution Check

| Principe | Statut | Justification |
|---|---|---|
| I. API-First | PASS | Le contrat REST devient un DTO JSON explicite et documente; le statut reste uniquement dans la reponse HTTP. |
| II. Securite par defaut | PASS | Le chemin 500 masque classe, cause, message technique et stack trace; aucune regle JWT ou d'autorisation n'est modifiee. |
| III. Simplicite & YAGNI | PASS | Le record `ErrorResponse` existant est reutilise; aucun nouveau framework, mapper ou niveau d'abstraction n'est ajoute. |
| IV. Mobile-First UX | PASS | Angular conserve ses messages et fallbacks; Flutter est explicitement hors perimetre et son comportement n'est pas modifie. |
| V. Testabilite | PASS | Chaque branche du handler, les deux conflits specialises, les fallbacks Angular et le masquage du 500 ont des assertions comportementales. |
| VI. Observabilite | PASS | Les logs existants sont conserves, notamment la trace serveur du 500, tandis que le corps public est assaini. |
| VII. Self-Hosted Ready | PASS | Aucun service, stockage ou dependance externe n'est introduit. |

**GATE RESULT**: PASS. La conception detaillee ne cree aucune violation supplementaire: elle reutilise les modules, DTO et outils de test existants.

## Project Structure

### Documentation de la feature

```text
.specify/specs/107-unified-api-errors/
├── assessment.json       # entree, non modifiee
├── workflow-state.json   # entree, non modifiee
├── spec.md               # entree, non modifiee
├── plan.md               # present plan
└── tasks.md              # produit par l'activite tasks ulterieure
```

### Code source concerne

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── config/GlobalExceptionHandler.java
│   └── dto/response/ErrorResponse.java
└── src/test/java/fr/kksdev/budget/api/
    ├── config/GlobalExceptionHandlerTest.java
    └── controller/                         # tests d'integration des payloads specialises affectes

app/
└── src/app/
    ├── core/services/auth.ts
    ├── shared/components/transfer-form/transfer-form.ts
    └── features/
        ├── auth/pages/accept-invite/accept-invite.ts
        ├── budgets/components/budget-form/budget-form.ts
        └── settings/                       # comptes, imports CSV et dialogues de compte

docs/
└── api-errors.md
```

**Structure Decision**: Conserver l'architecture web existante. Le backend porte le contrat public via `ErrorResponse`; Angular ne declare pas un second schema concurrent et accede defensivement aux deux champs du corps. Les tests restent colocalises selon les conventions Maven et Angular existantes.

## Design Decisions

### D1 — `ErrorResponse` est l'unique corps construit par le handler

Faire retourner `ResponseEntity<ErrorResponse>` par toutes les methodes de `GlobalExceptionHandler`. Supprimer `errorBody(int, String)`, `LocalDateTime` et `Map` devenus inutiles. Le record conserve exactement deux proprietes serialisees, sans dupliquer le statut HTTP.

La correspondance des handlers generiques est fermee et explicite:

| Exception geree | Statut conserve | `error` | Regle de `message` |
|---|---:|---|---|
| `IllegalArgumentException`, `IllegalStateException` | 400 | `BAD_REQUEST` | message existant, fallback public non vide |
| `HttpMessageNotReadableException` | 400 | `MALFORMED_REQUEST` | `Requete invalide`, sans cause technique |
| `MethodArgumentNotValidException` | 400 | `VALIDATION_ERROR` | concatenation existante `champ: contrainte; ...`, fallback `Erreur de validation` |
| `AccessDeniedException` | 403 | `ACCESS_DENIED` | message existant, fallback public non vide |
| `FeatureDisabledException` | 403 | `FEATURE_DISABLED` | message existant, fallback public non vide |
| `EntityNotFoundException` | 404 | `NOT_FOUND` | message metier existant, fallback public non vide |
| `ConflictException` non specialisee | 409 | `CONFLICT` | message metier existant, fallback public non vide |
| `CsvProfileNotFoundException` | 422 | `CSV_PROFILE_NOT_FOUND` | message existant, fallback public non vide |
| `Exception` inattendue | 500 | `INTERNAL_ERROR` | constante `Une erreur interne est survenue` |

Les libelles de fallback seront definis pres du handler (helper prive simple ou constantes) afin que la garantie de chaines non vides s'applique aussi aux exceptions creees avec un message null ou blanc, sans modifier les exceptions ni les services metier.

### D2 — Conflits specialises conserves, conflit generique normalise

`handleConflict` compare uniquement les deux codes publics connus. `LAST_ADMIN_CANNOT_BE_DISABLED` et `EMAIL_ALREADY_EXISTS` restent la valeur de `error` et sont traduits par les messages stables existants. Toute autre valeur, y compris null ou blanc, utilise `CONFLICT`; une valeur textuelle non vide est conservee comme message metier. Le message d'exception ne sert donc plus de code machine pour le cas generique.

### D3 — Exceptions specialisees sans regression

Les handlers qui retournent deja `ErrorResponse` gardent statut, code et message: `INVALID_IMAGE_FORMAT`, `FILE_TOO_LARGE`, `AVATAR_NOT_FOUND`, `PASSWORD_INCORRECT`, `INVALID_EXPORT_FORMAT`, `PASSWORD_UNCHANGED`, `PASSWORD_RESET_NOT_REQUIRED`, `TOKEN_EXPIRED`, `TOKEN_REVOKED`, `TOKEN_REUSE_DETECTED`, `TOKEN_INVALID`, `CONFIRMATION_REQUIRED` et `LAST_ADMIN_DELETION_FORBIDDEN`. La garantie non vide est appliquee sans changer leur identifiant ni leur statut.

### D4 — Frontiere de securite inchangee

Ne modifier ni `SecurityConfig`, ni les filtres/points d'entree Spring Security, ni `auth.interceptor.ts`. `AccessDeniedException` n'est unifiee que lorsqu'elle atteint le gestionnaire global. Le handler generique continue de journaliser l'exception complete cote serveur mais ne construit jamais le corps depuis `ex.getMessage()`, `ex.getCause()` ou le nom de classe.

### D5 — Migration Angular ciblee par inventaire

Verifier les lecteurs actuels du corps dans `auth.ts`, les formulaires budget/virement/invitation, les composants comptes/imports et les dialogues de compte. Ils doivent utiliser `error.error?.message` pour l'affichage et `error.error?.error` pour les branches machine, avec leur fallback utilisateur actuel lorsque `error`, le corps ou le champ attendu est absent ou d'un type incorrect. Les flux 401 de refresh/deconnexion restent intacts. Seuls les consommateurs dont les fixtures ou la logique supposent encore `timestamp/status/message` necessitent une modification.

### D6 — Documentation normative unique

Reecrire `docs/api-errors.md` autour de `ApiError { error: string; message: string }`, avec un exemple canonique et une matrice exhaustive code/statut/categorie. Retirer les interfaces, exemples et avertissements qui presentent le format historique ou hybride. Distinguer clairement les erreurs produites par le handler des reponses de securite hors handler, sans promettre leur unification.

## Implementation Sequence

1. Etendre `GlobalExceptionHandlerTest` avant la migration avec un test parametre ou des cas descriptifs couvrant chaque handler, le statut, les deux seules proprietes, les valeurs non vides, les fallbacks null/blanc, les conflits specialises/generique et l'absence des marqueurs techniques dans le 500.
2. Migrer les handlers generiques vers `ErrorResponse`, centraliser seulement la normalisation minimale des messages, puis supprimer la construction historique.
3. Rejouer les tests controleur qui assertent `EMAIL_ALREADY_EXISTS`, `LAST_ADMIN_CANNOT_BE_DISABLED` et les autres codes specialises; adapter uniquement les attentes de champs historiques.
4. Inventorier les consommateurs Angular par recherche statique, adapter les acces ou types necessaires et ajouter/mettre a jour les tests Vitest pour les messages, fallbacks et branches specialisees.
5. Mettre a jour `docs/api-errors.md`, puis verifier par recherche qu'aucun format historique n'y demeure et que tous les codes generiques et specialises du perimetre sont documentes.
6. Executer les suites backend et frontend ciblees, puis les suites completes et les controles de format/lint pertinents.

## Test Strategy and Requirements Coverage

| Niveau | Verification | Exigences couvertes |
|---|---|---|
| Unitaire backend | Appeler chaque handler, verifier statut, `error`, `message`, ensemble exact des champs et fallback non vide | FR-001 a FR-009, FR-013, FR-014 |
| Integration backend | Conserver les payloads specialises observes via MockMvc, notamment les deux conflits | FR-003, FR-005, FR-006, SC-002, SC-003 |
| Securite backend | Injecter dans une exception 500 un nom de classe, une pseudo-requete SQL et une cause; verifier leur absence du corps | FR-009, FR-010, SC-004 |
| Unitaire Angular | Fournir des `HttpErrorResponse` au nouveau format, avec corps absent et mal forme; verifier message, fallback et branches par code | FR-011, FR-012, FR-015, SC-003 |
| Documentation | Rechercher les anciens champs et comparer la matrice aux constantes/assertions du handler | FR-016, SC-006 |
| Non-regression | Suites Maven et Vitest completes; lint/format Angular | SC-001 a SC-005 |

Les tests de structure doivent serialiser le DTO ou inspecter ses deux composants sans dependre de l'ordre JSON. L'absence de `timestamp` et `status` est verifiee explicitement. Les tests d'authentification existants servent de garde de non-regression mais aucune nouvelle attente ne force les reponses hors handler dans ce contrat.

## Validation Plan

| ID | Commande | Repertoire | But | Bloquant | Timeout |
|---|---|---|---|---|---:|
| V-01 | `./mvnw -Dtest=GlobalExceptionHandlerTest test` | `api` | Valider toutes les branches et invariants du contrat backend | Oui | 300 s |
| V-02 | `./mvnw test` | `api` | Detecter les regressions backend et controleur, statuts compris | Oui | 1200 s |
| V-03 | `npm test -- --run` | `app` | Valider les consommateurs et la suite Angular | Oui | 900 s |
| V-04 | `npm run lint` | `app` | Verifier la qualite statique TypeScript | Oui | 300 s |
| V-05 | `npm run format:check` | `app` | Verifier le format des fichiers Angular touches | Non | 300 s |
| V-07 | `rg -n 'BAD_REQUEST|ACCESS_DENIED|FEATURE_DISABLED|CSV_PROFILE_NOT_FOUND|NOT_FOUND|MALFORMED_REQUEST|VALIDATION_ERROR|CONFLICT|INTERNAL_ERROR' docs/api-errors.md` | `.` | Confirmer la presence de tous les codes generiques documentes | Oui | 30 s |

## Risks and Mitigations

| Risque restant | Impact | Mitigation planifiee |
|---|---|---|
| Des consommateurs non inventories utilisent encore `timestamp` ou `status` | Rupture client apres deploiement | Recherche globale dans le depot, documentation du breaking change et fallbacks Angular; clients externes signales comme risque de livraison. |
| Messages metier variables ou nuls | Champ `message` instable ou invalide | Code machine stable et normalisation null/blanc testee pour chaque categorie. |
| Coexistence temporaire ancien backend/nouveau frontend | Fallback affiche pendant un deploiement decale | Acces optionnels Angular et fallbacks existants, sans reintroduire la lecture des champs historiques. |
| Reponses Spring Security distinctes | Impression d'unification incomplete | Frontiere documentee et tests de non-regression; traitement separe requis dans une autre feature. |
| Assertion documentaire trop large sur les mots `status` ou `timestamp` | Faux positif si ces mots decrivent explicitement leur retrait | Formuler la documentation sans exemples/interfaces historiques et completer V-06 par une revue de la matrice. |

## Complexity Tracking

Aucune violation de constitution ni complexite additionnelle n'est requise. Le changement reutilise un DTO existant, conserve les limites de modules et n'introduit ni persistance, ni dependance, ni abstraction transversale nouvelle.
