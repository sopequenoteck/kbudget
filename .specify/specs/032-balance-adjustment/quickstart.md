# Quickstart: Ajustement de solde

**Feature**: 032-balance-adjustment

## Prérequis

- Java 21, Maven, PostgreSQL 15+ (profil dev)
- Node.js, Angular CLI (pour le frontend)

## Séquence d'implémentation

### 1. Backend — Enum & Query (base)

```
api/src/main/java/fr/kksdev/budget/api/enums/TransactionType.java
  → Ajouter AJUSTEMENT

api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java
  → Modifier calculateBalanceByAccountId pour AJUSTEMENT
```

### 2. Backend — Catégorie système lazy

```
api/src/main/java/fr/kksdev/budget/api/service/CategoryService.java
  → Ajouter findOrCreateAdjustmentCategory(UUID userId)
```

### 3. Backend — Service adjust-balance

```
api/src/main/java/fr/kksdev/budget/api/service/AccountService.java
  → Ajouter adjustBalance(UUID accountId, BigDecimal newBalance, UUID userId)
```

### 4. Backend — DTO + Controller

```
api/src/main/java/fr/kksdev/budget/api/dto/request/AdjustBalanceRequest.java
  → Nouveau record { BigDecimal newBalance }

api/src/main/java/fr/kksdev/budget/api/controller/AccountController.java
  → POST /{id}/adjust-balance
```

### 5. Backend — Immutabilité AJUSTEMENT

```
api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java
  → Guards dans update() et delete()
```

### 6. Backend — Résumé mensuel

```
api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java
  → getMonthlySummary() : exclure AJUSTEMENT de recettes/dépenses, inclure dans solde
```

### 7. Backend — Tests

```
api/src/test/java/.../service/AccountServiceTest.java (ou intégration)
  → Tests adjust-balance (hausse, baisse, identique, inactif)

api/src/test/java/.../service/TransactionServiceTest.java
  → Tests immutabilité AJUSTEMENT (403 sur update/delete)
```

### 8. Frontend — Model & Service

```
app/src/app/core/models/transaction.model.ts
  → Ajouter AJUSTEMENT à TransactionType enum

app/src/app/core/services/account.ts
  → Ajouter adjustBalance(id, newBalance)
```

### 9. Frontend — Formulaire d'édition de compte

```
app/src/app/shared/components/account-form/account-form.ts
app/src/app/shared/components/account-form/account-form.html
app/src/app/shared/components/account-form/account-form.scss
  → Ajouter affichage solde actuel + champ "Nouveau solde" en mode édition
```

### 10. Frontend — Liste des transactions

```
app/src/app/features/transactions/transactions.ts
app/src/app/features/transactions/transactions.html
  → Afficher AJUSTEMENT correctement (icône, couleur, pas de filtre dédié)
  → Masquer edit/delete pour type AJUSTEMENT
```

## Vérification rapide

```bash
# Backend
cd api && mvn clean test

# Frontend
cd app && ng test
cd app && ng build
```

## Endpoint test

```bash
# Ajuster le solde à 750 EUR
curl -X POST http://localhost:8080/api/accounts/{id}/adjust-balance \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"newBalance": 750.00}'
```
