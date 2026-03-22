# Quickstart: Transactions récurrentes & améliorations abonnements

**Feature**: 089-recurring-transactions (consolidée)
**Status**: Done (rétroactive)

## Prérequis

- Backend démarré avec profil dev (`mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- PostgreSQL 15+ avec migration V20 appliquée
- Système de notifications fonctionnel (KKS-158 / feature 072)

## Tester les récurrences

### 1. Créer une récurrence

```bash
curl -X POST http://localhost:8080/api/transactions/recurring \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "libelle": "Loyer",
    "montant": 800.00,
    "type": "DEPENSE",
    "frequency": "MENSUEL",
    "nextOccurrence": "2026-04-01",
    "categoryId": "<category-uuid>",
    "accountId": "<account-uuid>"
  }'
```

### 2. Lister les récurrences actives

```bash
curl http://localhost:8080/api/transactions/recurring \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Valider une occurrence

```bash
curl -X POST http://localhost:8080/api/transactions/recurring/<id>/validate \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Passer une occurrence

```bash
curl -X POST http://localhost:8080/api/transactions/recurring/<id>/skip \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Désactiver une récurrence

```bash
curl -X POST http://localhost:8080/api/transactions/recurring/<id>/deactivate \
  -H "Authorization: Bearer $TOKEN"
```

## Tester les paiements d'abonnements

### 1. Payer un abonnement

```bash
curl -X POST http://localhost:8080/api/subscriptions/<id>/pay \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Historique des paiements

```bash
curl http://localhost:8080/api/subscriptions/<id>/payments \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Total cumulé

```bash
curl http://localhost:8080/api/subscriptions/<id>/total-paid \
  -H "Authorization: Bearer $TOKEN"
```

## Tests

```bash
# Backend (488 tests)
cd api && mvn test

# Angular (379 tests)
cd app && ng test

# Flutter (626 tests)
cd flutter && flutter test
```

## Sous-specs de référence

| Spec | Scope |
|------|-------|
| specs/085-recurring-transactions-backend/ | Backend complet |
| specs/086-angular-recurring-transactions/ | Angular : écran + détail + notifications |
| specs/087-angular-recurring-form/ | Angular : formulaire + conversion |
| specs/088-flutter-recurring-transactions/ | Flutter : écran + détail + notifications |
