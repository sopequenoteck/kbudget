# Quickstart: 080-debt-enhancements

## Prérequis

- Java 21, Maven
- Node.js, Angular CLI
- Flutter >= 3.27, Dart >= 3.6
- PostgreSQL 15+ (avec migrations Flyway V1-V18)

## Backend

```bash
cd api
mvn clean compile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
# API disponible sur http://localhost:8080/api
# Swagger: http://localhost:8080/api/swagger-ui.html
```

### Vérifier les endpoints dette

```bash
# Créer une dette
curl -X POST http://localhost:8080/api/debts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"personne":"Paul","montant":200,"sens":"EMPRUNT","date":"2026-03-10"}'

# Rembourser partiellement
curl -X POST http://localhost:8080/api/debts/$DEBT_ID/repay \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"accountId":"$ACCOUNT_ID","amount":50}'

# Historique des paiements
curl http://localhost:8080/api/debts/$DEBT_ID/payments \
  -H "Authorization: Bearer $TOKEN"

# Reporter un rappel
curl -X POST http://localhost:8080/api/debts/$DEBT_ID/snooze \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reminderDate":"2026-03-20","reminderTime":"14:00"}'

# Solde total
curl http://localhost:8080/api/accounts/total-balance \
  -H "Authorization: Bearer $TOKEN"
```

## Frontend Angular

```bash
cd app
ng serve
# http://localhost:4200
# Naviguer vers Dettes → cliquer sur une dette → détail avec progress bar et historique
```

## Flutter

```bash
cd flutter
dart run build_runner build --delete-conflicting-outputs  # si nécessaire
flutter run
# Naviguer vers Dettes → cliquer sur une dette → détail
```

## Tests

```bash
# Backend
cd api && mvn test

# Angular
cd app && ng test

# Flutter
cd flutter && flutter test test/src/features/debts/
```

## Flux de test manuel

1. **Créer** une dette de 200€ (EMPRUNT) sans compte
2. **Associer** un compte bancaire → vérifier que la devise est forcée
3. **Rembourser** 50€ → vérifier montant restant = 150€
4. **Consulter** l'historique des paiements → 1 paiement listé
5. **Configurer** un rappel → vérifier la notification à l'échéance
6. **Reporter** le rappel → vérifier la nouvelle date
7. **Rembourser** le solde restant → vérifier badge "Remboursé"
8. **Vérifier** le solde total via GET /accounts/total-balance
