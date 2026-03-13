# Quickstart: Banques sur les comptes — Backend

**Feature**: 081-backend-bank-accounts | **Date**: 2026-03-13

## Prérequis

- Java 21
- Maven
- PostgreSQL 15+ (ou profil dev avec H2)
- Les fichiers SVG de logos dans `api/src/main/resources/static/bank-logos/`

## Build & Run

```bash
cd api
mvn clean compile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Tester la feature

### 1. Lister les banques (public, sans auth)

```bash
curl http://localhost:8080/api/banks | jq
```

Attendu : 29 banques avec code, name, country, brandColor, logoUrl.

### 2. Vérifier un logo SVG (public)

```bash
curl http://localhost:8080/api/bank-logos/sg.svg
```

Attendu : contenu SVG.

### 3. Créer un compte avec banque connue

```bash
curl -X POST http://localhost:8080/api/accounts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Compte SG",
    "type": "COURANT",
    "soldeInitial": 500,
    "bankCode": "SG"
  }'
```

Attendu : réponse avec bankCode="SG", bankName="Société Générale", bankBrandColor="#e2001a".

### 4. Créer un compte avec banque personnalisée

```bash
curl -X POST http://localhost:8080/api/accounts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Compte local",
    "type": "COURANT",
    "soldeInitial": 100,
    "bankCode": "OTHER",
    "bankCustomName": "Ma Banque Locale"
  }'
```

### 5. Créer un compte sans bankCode (default OTHER)

```bash
curl -X POST http://localhost:8080/api/accounts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Compte espèces",
    "type": "ESPECES",
    "soldeInitial": 50
  }'
```

Attendu : bankCode="OTHER" dans la réponse.

### 6. Vérifier la migration (comptes existants)

```bash
curl http://localhost:8080/api/accounts \
  -H "Authorization: Bearer <token>" | jq '.[].bankCode'
```

Attendu : tous les comptes existants ont bankCode="OTHER".

## Tests

```bash
cd api
mvn test -Dtest=BankControllerTest
mvn test -Dtest=BankServiceTest
mvn test
```
