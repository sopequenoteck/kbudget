# Quickstart: Documentation API OpenAPI / Swagger UI

**Branch**: `001-springdoc-openapi` | **Date**: 2026-02-07

## Verification rapide apres implementation

### 1. Compilation

```bash
cd api && mvn clean compile
```

Attendu : BUILD SUCCESS, aucune erreur de compilation.

### 2. Tests

```bash
cd api && mvn test
```

Attendu : 84 tests passent (aucun test casse par l'ajout de springdoc).

### 3. Demarrage

```bash
cd api && mvn spring-boot:run
```

### 4. Swagger UI

Ouvrir dans un navigateur :
```
http://localhost:8080/api/swagger-ui.html
```

Verifier :
- La page Swagger UI s'affiche
- 4 groupes visibles : Authentification, Transactions, Abonnements, Dettes
- Chaque endpoint a un resume descriptif
- Le bouton "Authorize" est present (cadenas en haut a droite)

### 5. Spec OpenAPI JSON

```bash
curl http://localhost:8080/api/v3/api-docs | python3 -m json.tool | head -20
```

Verifier : le JSON contient `"openapi": "3.1.0"`, `"title": "Budget API"`, et les paths des 16 endpoints.

### 6. Test authentification Swagger UI

1. Appeler `POST /auth/login` depuis Swagger UI avec des credentials valides
2. Copier le token de la reponse
3. Cliquer sur "Authorize", coller le token
4. Appeler `GET /transactions` — verifier la reponse 200

## Fichiers modifies

| Fichier | Modification |
|---------|-------------|
| `api/pom.xml` | +1 dependance springdoc-openapi |
| `api/src/.../config/SecurityConfig.java` | +3 routes publiques (swagger-ui, api-docs) |
| `api/src/.../config/OpenApiConfig.java` | Nouveau fichier — bean OpenAPI (metadata + JWT) |
| `api/src/.../controller/AuthController.java` | +@Tag, +@Operation sur 2 methodes |
| `api/src/.../controller/TransactionController.java` | +@Tag, +@Operation sur 6 methodes |
| `api/src/.../controller/SubscriptionController.java` | +@Tag, +@Operation sur 5 methodes |
| `api/src/.../controller/DebtController.java` | +@Tag, +@Operation sur 5 methodes |
| `README.md` | +URL Swagger UI dans la section documentation |
