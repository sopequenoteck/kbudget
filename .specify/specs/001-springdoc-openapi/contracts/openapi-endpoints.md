# API Contracts: Documentation Endpoints

**Branch**: `001-springdoc-openapi` | **Date**: 2026-02-07

## Nouveaux endpoints exposes par springdoc (auto-generes)

Ces endpoints sont crees automatiquement par la librairie, aucun code controller a ecrire.

### GET /api/v3/api-docs

**Description**: Specification OpenAPI 3.1 au format JSON
**Authentification**: Aucune (route publique)
**Response 200**:
```
Content-Type: application/json
Body: document OpenAPI 3.1 complet (info, paths, components, securitySchemes)
```

### GET /api/v3/api-docs.yaml

**Description**: Specification OpenAPI 3.1 au format YAML
**Authentification**: Aucune (route publique)
**Response 200**:
```
Content-Type: application/vnd.oai.openapi
Body: document OpenAPI 3.1 au format YAML
```

### GET /api/swagger-ui.html

**Description**: Redirect vers l'interface Swagger UI
**Authentification**: Aucune (route publique)
**Response 302**: Redirect vers `/api/swagger-ui/index.html`

### GET /api/swagger-ui/**

**Description**: Assets statiques de l'interface Swagger UI (HTML, CSS, JS)
**Authentification**: Aucune (route publique)
**Response 200**: Fichiers statiques

## Endpoints existants documentes

Aucune modification de contrat sur les 16 endpoints existants. Seules des annotations descriptives sont ajoutees (@Tag, @Operation) qui n'affectent ni les chemins, ni les parametres, ni les corps de requete/reponse.

| Controller | Endpoints | Tag |
|------------|-----------|-----|
| AuthController | POST /auth/register, POST /auth/login | Authentification |
| TransactionController | POST/GET/PUT/DELETE /transactions, GET /transactions/summary | Transactions |
| SubscriptionController | POST/GET/PUT/DELETE /subscriptions | Abonnements |
| DebtController | POST/GET/PUT/DELETE /debts | Dettes |
