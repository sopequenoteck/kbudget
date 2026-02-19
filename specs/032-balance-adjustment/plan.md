# Implementation Plan: Ajustement de solde de compte bancaire

**Branch**: `032-balance-adjustment` | **Date**: 2026-02-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/032-balance-adjustment/spec.md`

## Summary

Permettre à l'utilisateur de corriger le solde d'un compte bancaire via un endpoint REST dédié `POST /accounts/{id}/adjust-balance`. Le système calcule la différence entre le solde actuel et le nouveau solde souhaité, puis crée une transaction de type `AJUSTEMENT` (nouveau TransactionType) avec montant signé. Les transactions d'ajustement sont immutables (403 sur edit/delete). Côté frontend Angular, le formulaire d'édition de compte affiche le solde actuel et permet de saisir un nouveau solde.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (frontend)
**Primary Dependencies**: Spring Boot 4.0.2, Spring Data JPA, Angular 21
**Storage**: PostgreSQL 15+ (aucune migration Flyway requise — VARCHAR(50) pour type, NUMERIC(19,2) pour montant)
**Testing**: JUnit 5 + Spring Boot Test + Mockito (backend), Jasmine/Karma (frontend)
**Target Platform**: Web application (PWA Angular mobile-first)
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: N/A (single-user, opération ponctuelle)
**Constraints**: Atomicité du calcul solde + création transaction (`@Transactional`)
**Scale/Scope**: 1 nouvel endpoint, 1 enum étendu, ~10 fichiers modifiés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | ✅ | Endpoint REST `POST /accounts/{id}/adjust-balance` avec DTO dédié `AdjustBalanceRequest`. Réponse via `AccountResponse` existant. |
| II. Sécurité par défaut | ✅ | Endpoint protégé JWT (route non publique). Filtrage par userId. Bean Validation sur `newBalance` (`@NotNull`). Erreur 403 générique sur tentative de modification d'ajustement. |
| III. Simplicité & YAGNI | ✅ | Méthode `adjustBalance()` dans AccountService existant (pattern de `transfer()`). Enum `AJUSTEMENT` ajouté à TransactionType existant. Pas de nouveau service ni pattern complexe. |
| IV. Mobile-First UX | ✅ | Ajustement en 2-3 interactions via le formulaire d'édition existant. Pas de navigation supplémentaire. |
| V. Testabilité | ✅ | Tests d'intégration endpoint (hausse, baisse, identique, inactif, 403). Tests unitaires service. Nommage `should_X_when_Y`. |
| VI. Observabilité | ✅ | `log.info("Solde ajusté: accountId={}, diff={}, userId={}")`. `log.warn` sur tentatives de modification d'ajustement. |
| VII. Self-Hosted Ready | ✅ | Aucune dépendance externe ajoutée. PostgreSQL seul. |

**Résultat** : Aucune violation. Gate OK.

## Project Structure

### Documentation (this feature)

```text
specs/032-balance-adjustment/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 — décisions techniques
├── data-model.md        # Phase 1 — modèle de données
├── quickstart.md        # Phase 1 — séquence d'implémentation
├── contracts/
│   └── adjust-balance.yaml  # Phase 1 — contrat OpenAPI
└── tasks.md             # Phase 2 — tâches (/speckit.tasks)
```

### Source Code (fichiers impactés)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── enums/
│   │   └── TransactionType.java          # +AJUSTEMENT
│   ├── dto/request/
│   │   └── AdjustBalanceRequest.java     # NOUVEAU
│   ├── controller/
│   │   └── AccountController.java        # +POST /{id}/adjust-balance
│   ├── service/
│   │   ├── AccountService.java           # +adjustBalance()
│   │   ├── TransactionService.java       # +guard création AJUSTEMENT (400), +guards immutabilité (403), +résumé mensuel
│   │   └── CategoryService.java          # +findOrCreateAdjustmentCategory()
│   └── repository/
│       └── TransactionRepository.java    # +query balance AJUSTEMENT
└── src/test/java/fr/kksdev/budget/api/
    ├── controller/
    │   ├── AccountControllerTest.java           # +tests adjust-balance
    │   └── TransactionControllerTest.java       # +tests immutabilité, +test création directe 400
    └── service/
        └── TransactionServiceTest.java          # +tests immutabilité

app/
└── src/app/
    ├── core/
    │   ├── models/
    │   │   └── transaction.model.ts       # +AJUSTEMENT enum
    │   └── services/
    │       └── account.ts                 # +adjustBalance()
    ├── shared/components/
    │   └── account-form/
    │       ├── account-form.ts            # +champ nouveau solde
    │       ├── account-form.html          # +section ajustement
    │       └── account-form.scss          # +styles
    └── features/transactions/
        ├── transactions.ts                # +gestion type AJUSTEMENT
        └── transactions.html              # +affichage, masquage edit/delete
```

**Structure Decision** : Web application existante (monorepo api/ + app/). Aucun nouveau module, service, ou package créé. Modifications dans les fichiers existants + 1 nouveau DTO.

## Complexity Tracking

> Aucune violation de constitution — tableau non requis.
