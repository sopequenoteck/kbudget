# Quickstart: Backend Budget Categories

**Feature**: 073-backend-budget-categories
**Date**: 2026-03-08

## Prerequis

- Java 21, Maven, PostgreSQL 15+ en cours d'execution
- Profil `dev` active (`spring.profiles.active=dev`)
- Au moins un utilisateur, une categorie et un compte existants

## Demarrage

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

La migration Flyway V17 s'execute automatiquement au demarrage et cree les tables `budgets` et `budget_snapshots`.

## Verification rapide

### 1. Activer le feature toggle BUDGETS

```bash
# Recuperer les preferences actuelles
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/users/me/preferences | jq

# Activer BUDGETS dans enabledFeatures
curl -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  http://localhost:8080/api/users/me/preferences \
  -d '{"enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP", "BUDGETS"]}'
```

### 2. Creer un budget

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  http://localhost:8080/api/budgets \
  -d '{"categoryId": "<CATEGORY_UUID>", "montant": 500, "frequence": "MENSUEL"}'
```

### 3. Lister les budgets

```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/budgets | jq
```

### 4. Consulter l'overview

```bash
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/budgets/overview | jq
```

### 5. Consulter l'historique

```bash
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/budgets/history?month=2026-02" | jq
```

## Tests

```bash
cd api && mvn test -Dtest="BudgetControllerTest"
cd api && mvn test -Dtest="BudgetServiceTest"
```

## Fichiers crees/modifies

| Action | Fichier |
|--------|---------|
| Cree | `model/Budget.java` |
| Cree | `model/BudgetSnapshot.java` |
| Cree | `repository/BudgetRepository.java` |
| Cree | `repository/BudgetSnapshotRepository.java` |
| Cree | `service/BudgetService.java` |
| Cree | `controller/BudgetController.java` |
| Cree | `dto/request/BudgetRequest.java` |
| Cree | `dto/response/BudgetResponse.java` |
| Cree | `dto/response/BudgetOverviewResponse.java` |
| Cree | `dto/response/BudgetOverviewItemResponse.java` |
| Cree | `dto/response/BudgetHistoryResponse.java` |
| Cree | `dto/response/BudgetHistoryItemResponse.java` |
| Cree | `db/migration/V17__add_budgets.sql` |
| Modifie | `enums/Feature.java` (+ BUDGETS) |
| Modifie | `enums/Frequency.java` (+ HEBDOMADAIRE) |
| Modifie | `repository/TransactionRepository.java` (+ query somme par categorie) |
