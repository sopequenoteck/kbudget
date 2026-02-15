# Implementation Plan: Comptes Bancaires

**Branch**: `026-bank-accounts` | **Date**: 2026-02-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/026-bank-accounts/spec.md`

## Summary

Ajout d'une entite Account au backend Spring Boot permettant de gerer des comptes bancaires (Courant, Epargne, Especes). Les transactions existantes sont rattachees a un compte par defaut via migration Flyway V7. Le solde est calcule a la volee via SUM SQL. Les virements entre comptes creent deux transactions liees par un UUID partage, avec suppression cascade et propagation automatique des modifications.

## Technical Context

**Language/Version**: Java 21
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Spring Security, Flyway, jjwt 0.12.6, Lombok
**Storage**: PostgreSQL 15+, Flyway migrations (V1-V6 existantes, V7 pour cette feature)
**Testing**: JUnit 5 + Spring Boot Test + H2 (in-memory)
**Target Platform**: Linux server (self-hosted via Docker + Caddy)
**Project Type**: Web application (backend uniquement pour cette feature)
**Performance Goals**: Single-user, pas de contrainte specifique. Calcul SUM SQL performant a cette echelle.
**Constraints**: Self-hosted, PostgreSQL seule dependance infra. Pas de cache, pas de CQRS.
**Scale/Scope**: Single-user. Volume max estime : ~50 comptes, ~10k transactions.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Endpoints REST avec DTOs separes (AccountRequest/AccountResponse). Aucune entite JPA exposee. |
| II. Securite par defaut | PASS | JWT sur tous les endpoints. Isolation par user via `user_id`. Bean Validation sur inputs. |
| III. Simplicite & YAGNI | PASS | Controller → Service → Repository. Pas de pattern complexe. Enum AccountType. Lombok. |
| IV. Mobile-First UX | N/A | Backend uniquement (frontend dans une branche separee). |
| V. Testabilite | PASS | Tests d'integration prevus sur tous les endpoints. Nommage `should_X_when_Y`. |
| VI. Observabilite | PASS | Logs INFO sur chaque action CRUD. Logs ERROR avec contexte (userId, accountId). |
| VII. Self-Hosted Ready | PASS | PostgreSQL seule dependance. Configuration via profils Spring. |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/026-bank-accounts/
├── plan.md              # Ce fichier
├── research.md          # Decisions techniques
├── data-model.md        # Modele de donnees
├── quickstart.md        # Guide de demarrage rapide
├── contracts/
│   ├── accounts-api.yaml          # Contrat API comptes + virements
│   └── transactions-api-changes.yaml  # Modifications aux endpoints existants
└── tasks.md             # Genere par /speckit.tasks
```

### Source Code (repository root)

```text
api/src/main/java/fr/kksdev/budget/api/
├── controller/
│   └── AccountController.java         # NOUVEAU — Endpoints REST comptes + virement
├── dto/
│   ├── request/
│   │   ├── AccountRequest.java        # NOUVEAU — Creation/modification compte
│   │   ├── TransferRequest.java       # NOUVEAU — Virement entre comptes
│   │   ├── TransactionRequest.java    # MODIFIE — +accountId
│   │   └── SubscriptionRequest.java   # MODIFIE — +accountId (optionnel)
│   └── response/
│       ├── AccountResponse.java       # NOUVEAU — Reponse avec solde calcule
│       ├── TransferResponse.java      # NOUVEAU — Reponse virement (2 transactions)
│       ├── AccountSummary.java        # NOUVEAU — Resume pour inclusion
│       ├── TransactionResponse.java   # MODIFIE — +account +transferId
│       └── SubscriptionResponse.java  # MODIFIE — +account (optionnel)
├── enums/
│   └── AccountType.java               # NOUVEAU — COURANT, EPARGNE, ESPECES + defaults icone/couleur
├── model/
│   ├── Account.java                   # NOUVEAU — Entite JPA
│   ├── Transaction.java               # MODIFIE — +account +transferId
│   └── Subscription.java              # MODIFIE — +account (optionnel)
├── repository/
│   ├── AccountRepository.java         # NOUVEAU — Spring Data JPA
│   └── TransactionRepository.java     # MODIFIE — +requetes SUM et transferId
├── service/
│   ├── AccountService.java            # NOUVEAU — Logique metier comptes + virements
│   ├── TransactionService.java        # MODIFIE — cascade/propagation virements
│   ├── SubscriptionService.java       # MODIFIE — support account optionnel
│   ├── AuthService.java               # MODIFIE — creation compte defaut au register
│   └── CategoryService.java           # MODIFIE — seed categorie "Virement"
└── ...

api/src/main/resources/db/migration/
└── V7__add_accounts.sql               # NOUVEAU — Migration complete

api/src/test/java/fr/kksdev/budget/api/controller/
└── AccountControllerTest.java         # NOUVEAU — Tests d'integration
```

**Structure Decision**: Monorepo existant, module `api/`. Nouveaux fichiers dans les packages existants suivant le pattern Controller → Service → Repository.

## Fichiers a creer (12)

| # | Fichier | Description |
|---|---------|-------------|
| 1 | `enums/AccountType.java` | Enum COURANT, EPARGNE, ESPECES avec defaults icone/couleur (R9) |
| 2 | `model/Account.java` | Entite JPA |
| 3 | `dto/request/AccountRequest.java` | DTO creation/modification |
| 4 | `dto/request/TransferRequest.java` | DTO virement |
| 5 | `dto/response/AccountResponse.java` | DTO reponse avec solde |
| 6 | `dto/response/TransferResponse.java` | DTO reponse virement |
| 7 | `dto/response/AccountSummary.java` | DTO resume pour inclusion |
| 8 | `repository/AccountRepository.java` | Repository Spring Data |
| 9 | `service/AccountService.java` | Logique metier (inclut defaults icone/couleur par type, voir R9) |
| 10 | `controller/AccountController.java` | Endpoints REST |
| 11 | `V7__add_accounts.sql` | Migration Flyway |
| 12 | `controller/AccountControllerTest.java` | Tests d'integration |

## Fichiers a modifier (11)

| # | Fichier | Modification |
|---|---------|-------------|
| 1 | `model/Transaction.java` | +champs `account` (ManyToOne) et `transferId` (UUID) |
| 2 | `model/Subscription.java` | +champ `account` (ManyToOne, nullable) |
| 3 | `dto/request/TransactionRequest.java` | +champ `accountId` |
| 4 | `dto/response/TransactionResponse.java` | +champs `account` (AccountSummary) et `transferId` |
| 5 | `dto/request/SubscriptionRequest.java` | +champ `accountId` (optionnel) |
| 6 | `dto/response/SubscriptionResponse.java` | +champ `account` (AccountSummary, nullable) |
| 7 | `repository/TransactionRepository.java` | +requetes SUM par account et findByTransferId |
| 8 | `service/TransactionService.java` | +logique account, cascade/propagation virements |
| 9 | `service/SubscriptionService.java` | +resolution account optionnel |
| 10 | `service/AuthService.java` | +creation compte defaut au register |
| 11 | `service/CategoryService.java` | +seed categorie "Virement" |

## Regles metier cles

1. **Solde initial fige** : `initialBalance` est ignore dans PUT. Corrections via transaction d'ajustement.
2. **Un seul defaut par user** : Contrainte DB (partial unique index) + logique service (swap atomique).
3. **Suppression cascade virements** : Supprimer une transaction de virement supprime automatiquement la transaction liee.
4. **Propagation modification virements** : Modifier le montant d'une transaction de virement propage le changement a la transaction liee.
5. **Compte obligatoire pour transactions** : Si accountId absent, utiliser le compte par defaut.
6. **Pas de suppression avec donnees** : Un compte avec transactions/abonnements ne peut etre que desactive, jamais supprime.

## Complexity Tracking

Aucune violation de la constitution detectee. Pas de deviation a justifier.
