# Quickstart: Backend Debt Enhancements

## Prérequis

- Java 21, Maven, PostgreSQL 15+
- Profil `dev` activé
- Taux de change configurés si multi-devise (KKS-156)
- Système de notifications fonctionnel (KKS-158)

## Lancer le backend

```bash
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## Tester

```bash
cd api && mvn test                              # Tous les tests
cd api && mvn test -Dtest=DebtServiceTest        # Tests unitaires DebtService
cd api && mvn test -Dtest=DebtControllerTest      # Tests intégration endpoints
```

## Fichiers clés à modifier

| Fichier | Modification |
|---------|-------------|
| `model/Debt.java` | +account, +includeInBalance, +reminderDate, +reminderTime |
| `model/Transaction.java` | +debt (FK nullable) |
| `service/DebtService.java` | +repay(), +getPayments(), +snooze(), logique devise/compte |
| `controller/DebtController.java` | +3 endpoints (repay, payments, snooze) |
| `repository/DebtRepository.java` | +requêtes rappels, dettes avec includeInBalance |
| `repository/TransactionRepository.java` | +sumByDebtId(), +findByDebtId() |
| `dto/request/DebtRequest.java` | +accountId, +includeInBalance, +reminderDate, +reminderTime |
| `dto/response/DebtResponse.java` | +account, +includeInBalance, +reminder*, +montantRestant |
| `dto/request/DebtRepayRequest.java` | NOUVEAU |
| `dto/request/DebtSnoozeRequest.java` | NOUVEAU |
| `dto/response/DebtPaymentResponse.java` | NOUVEAU |
| `dto/response/TransactionResponse.java` | +debtId |
| `dto/response/TotalBalanceResponse.java` | NOUVEAU |
| `dto/response/CurrencyBalance.java` | NOUVEAU |
| `enums/NotificationType.java` | +DEBT_REMINDER |
| `service/NotificationScheduler.java` | +méthode @Scheduled chaque minute pour rappels |
| `service/AccountService.java` | +getTotalBalance() |
| `controller/AccountController.java` | +GET /accounts/total-balance |
| `V18__add_debt_enhancements.sql` | Migration Flyway |

## Ordre d'implémentation suggéré

1. Migration Flyway V18
2. Entités (Debt + Transaction) + enum NotificationType
3. DTOs (request + response)
4. Repository (requêtes)
5. DebtService (repay, payments, snooze, logique devise/compte)
6. DebtController (3 nouveaux endpoints)
7. AccountService + Controller (total-balance)
8. NotificationScheduler (rappels à la minute)
9. Tests unitaires (DebtService)
10. Tests intégration (DebtController, AccountController)
