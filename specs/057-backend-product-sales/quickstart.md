# Quickstart: 057-backend-product-sales

## Prerequis

- Java 21, Maven, PostgreSQL 15+ (ou Docker)
- Feature KKS-118 (Product CRUD) mergee

## Lancer en dev

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Tester les nouveaux endpoints

### 1. Authentification

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}' | jq -r '.token')
```

### 2. Creer un produit

```bash
curl -X POST http://localhost:8080/api/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nom":"Bracelet","prixAchat":8.00,"prixVente":15.00,"stock":10}'
```

### 3. Vendre un produit

```bash
curl -X POST http://localhost:8080/api/products/{id}/sell \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Restocker un produit

```bash
curl -X POST http://localhost:8080/api/products/{id}/restock \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"quantity":5}'
```

### 5. Historique des ventes

```bash
curl http://localhost:8080/api/products/{id}/sales \
  -H "Authorization: Bearer $TOKEN"
```

### 6. Verifier le compte Boutique

```bash
curl http://localhost:8080/api/accounts \
  -H "Authorization: Bearer $TOKEN"
# → Un compte avec "isShopAccount": true devrait apparaitre apres la premiere vente
```

### 7. Preferences boutique

```bash
# Lire
curl http://localhost:8080/api/preferences \
  -H "Authorization: Bearer $TOKEN"

# Modifier (inclure boutique dans solde total)
curl -X PUT http://localhost:8080/api/preferences \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabledFeatures":["SUBSCRIPTIONS","DEBTS","SHOP"],"includeShopInBalance":true}'
```

## Lancer les tests

```bash
cd api && mvn test
cd api && mvn test -Dtest=ProductSalesIntegrationTest
```
