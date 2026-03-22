# Data Model: Documentation API OpenAPI / Swagger UI

**Branch**: `001-springdoc-openapi` | **Date**: 2026-02-07

## Pas de nouvelles entites

Cette feature ne cree aucune entite de donnees, table, ni migration Flyway. Elle concerne exclusivement la couche de presentation (documentation auto-generee depuis les entites et DTOs existants).

## Entites existantes documentees par springdoc

Les entites suivantes seront automatiquement exposees dans la spec OpenAPI via leurs DTOs :

| Entite | DTO Request | DTO Response | Tag Swagger UI |
|--------|-------------|--------------|----------------|
| User | RegisterRequest, LoginRequest | AuthResponse | Authentification |
| Transaction | TransactionRequest | TransactionResponse, MonthlySummaryResponse | Transactions |
| Subscription | SubscriptionRequest | SubscriptionResponse | Abonnements |
| Debt | DebtRequest | DebtResponse | Dettes |

## Nouveaux composants de configuration

| Composant | Type | Description |
|-----------|------|-------------|
| OpenApiConfig | Classe @Configuration | Bean OpenAPI avec metadata (titre, description, version) et schema de securite JWT Bearer |

Ce composant ne touche pas au modele de donnees — il configure uniquement les metadata et le schema d'authentification pour la documentation generee.
