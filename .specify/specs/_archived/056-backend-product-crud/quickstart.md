# Quickstart: 056-backend-product-crud

## Prérequis

- Java 21
- Maven
- PostgreSQL 15+ (ou profil `dev` avec `create-drop`)

## Lancer le backend

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Tester les endpoints

### 1. Authentification

```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq -r '.accessToken')
```

### 2. Vérifier que SHOP est activé

```bash
curl -s http://localhost:8080/api/users/me/preferences \
  -H "Authorization: Bearer $TOKEN" | jq
# enabledFeatures doit contenir "SHOP"
```

### 3. Créer un produit

```bash
curl -s -X POST http://localhost:8080/api/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "T-shirt test",
    "prixAchat": 8.50,
    "prixVente": 15.00,
    "stock": 10
  }' | jq
```

### 4. Lister les produits

```bash
curl -s http://localhost:8080/api/products \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 5. Consulter un produit

```bash
PRODUCT_ID="<uuid-from-step-3>"
curl -s http://localhost:8080/api/products/$PRODUCT_ID \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 6. Modifier un produit

```bash
curl -s -X PUT http://localhost:8080/api/products/$PRODUCT_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "T-shirt modifié",
    "prixAchat": 9.00,
    "prixVente": 18.00,
    "stock": 20,
    "actif": true
  }' | jq
```

### 7. Supprimer un produit

```bash
curl -s -X DELETE http://localhost:8080/api/products/$PRODUCT_ID \
  -H "Authorization: Bearer $TOKEN" -w "\nHTTP %{http_code}\n"
# Attendu : HTTP 204
```

## Lancer les tests

```bash
cd api && mvn test -Dtest=ProductControllerIntegrationTest
cd api && mvn test -Dtest=ProductServiceTest
```

## Fichiers créés/modifiés

| Fichier | Action |
|---------|--------|
| `model/Product.java` | Créé — Entité JPA |
| `dto/request/ProductRequest.java` | Créé — DTO requête (création) |
| `dto/request/ProductUpdateRequest.java` | Créé — DTO requête (modification, inclut `actif`) |
| `dto/response/ProductResponse.java` | Créé — DTO réponse |
| `repository/ProductRepository.java` | Créé — Interface JPA |
| `service/ProductService.java` | Créé — Logique métier + toggle check |
| `controller/ProductController.java` | Créé — Endpoints REST |
| `config/GlobalExceptionHandler.java` | Modifié — Handler `FeatureDisabledException` |
| `service/PreferenceService.java` | Modifié — Ajout `isFeatureEnabled()` |
| `db/migration/V10__add_products.sql` | Créé — Table products |
