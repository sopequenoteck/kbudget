# Quickstart: Transactions Recurrentes & Paiements Abonnements (Backend)

**Branch**: `085-recurring-transactions-backend`

## Prerequis

- Java 21, Maven, PostgreSQL 15+
- Le systeme de notifications (feature 072) doit etre en place

## Demarrage rapide

```bash
cd api
mvn clean compile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

La migration Flyway V20 s'execute automatiquement au demarrage.

## Tester les endpoints

### 1. Creer une transaction recurrente

```bash
curl -X POST http://localhost:8080/api/transactions/recurring \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "montant": 800.00,
    "libelle": "Loyer",
    "type": "DEPENSE",
    "frequency": "MENSUEL",
    "nextOccurrence": "2026-04-01"
  }'
```

### 2. Lister les recurrences actives

```bash
curl http://localhost:8080/api/transactions/recurring \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Valider une occurrence

```bash
curl -X POST http://localhost:8080/api/transactions/recurring/{id}/validate \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Passer une occurrence

```bash
curl -X PATCH http://localhost:8080/api/transactions/recurring/{id}/skip \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Desactiver une recurrence

```bash
curl -X PATCH http://localhost:8080/api/transactions/recurring/{id}/deactivate \
  -H "Authorization: Bearer $TOKEN"
```

### 6. Payer un abonnement

```bash
curl -X POST http://localhost:8080/api/subscriptions/{id}/pay \
  -H "Authorization: Bearer $TOKEN"
```

### 7. Historique des paiements d'un abonnement

```bash
curl http://localhost:8080/api/subscriptions/{id}/payments \
  -H "Authorization: Bearer $TOKEN"
```

### 8. Cumul des paiements

```bash
curl http://localhost:8080/api/subscriptions/{id}/payments/total \
  -H "Authorization: Bearer $TOKEN"
```

## Lancer les tests

```bash
cd api
mvn test                                          # Tous les tests
mvn test -Dtest=RecurringTransactionServiceTest    # Tests service recurrences
mvn test -Dtest=SubscriptionPaymentServiceTest     # Tests service paiements
mvn test -Dtest=RecurringTransactionControllerTest # Tests controller
```
