# Quickstart: Comptes Bancaires

**Branch**: `026-bank-accounts` | **Date**: 2026-02-15

## Prérequis

- Java 21+
- Maven 3.9+
- PostgreSQL 15+ (accessible sur `192.168.1.81:5432` en dev)
- Profil `dev` actif

## Lancer le backend

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Vérifier la migration V7

La migration `V7__add_accounts.sql` s'exécute automatiquement au démarrage via Flyway. Vérifier :

```bash
# Via API health
curl http://localhost:8080/api/actuator/health

# Via psql
psql -h 192.168.1.81 -U budget_u -d budget_db -c "SELECT * FROM accounts;"
```

## Tester les endpoints

### 1. S'authentifier

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"password"}' | jq -r '.token')
```

### 2. Lister les comptes (le compte par défaut existe)

```bash
curl -s http://localhost:8080/api/accounts \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 3. Créer un compte

```bash
curl -s -X POST http://localhost:8080/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nom":"Livret A","type":"EPARGNE","soldeInitial":5000.00}' | jq
```

### 4. Créer une transaction sur un compte

```bash
curl -s -X POST http://localhost:8080/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "montant": 50.00,
    "libelle": "Courses",
    "type": "DEPENSE",
    "date": "2026-02-15",
    "accountId": "<UUID_DU_COMPTE>"
  }' | jq
```

### 5. Effectuer un virement

```bash
curl -s -X POST http://localhost:8080/api/accounts/transfer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fromAccountId": "<UUID_COMPTE_A>",
    "toAccountId": "<UUID_COMPTE_B>",
    "montant": 200.00
  }' | jq
```

## Lancer les tests

```bash
cd api && mvn test
```

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `model/Account.java` | Entité JPA |
| `enums/AccountType.java` | Enum COURANT/EPARGNE/ESPECES |
| `controller/AccountController.java` | Endpoints REST |
| `service/AccountService.java` | Logique métier |
| `repository/AccountRepository.java` | Accès données |
| `dto/request/AccountRequest.java` | DTO création/modification |
| `dto/request/TransferRequest.java` | DTO virement |
| `dto/response/AccountResponse.java` | DTO réponse avec solde |
| `dto/response/TransferResponse.java` | DTO réponse virement |
| `dto/response/AccountSummary.java` | DTO résumé pour inclusion |
| `V7__add_accounts.sql` | Migration Flyway |
