# Quickstart: Notification System

**Branch**: `072-notification-system`

## Prerequis

- Java 21, Maven
- PostgreSQL 15+ en cours d'execution
- Node.js (pour Angular)
- Flutter SDK >= 3.27

## 1. Backend — demarrer l'API

```bash
cd api
mvn clean compile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

Verifier que l'API repond :
```bash
curl http://localhost:8080/api/actuator/health
```

## 2. Migration Flyway

La migration V15 s'execute automatiquement au demarrage. Verifier :
```bash
curl -s http://localhost:8080/api/actuator/health | jq .
```

## 3. Tester les endpoints notification

### S'authentifier
```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"password"}' | jq -r .accessToken)
```

### Lister les notifications
```bash
curl -s http://localhost:8080/api/notifications \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### Compter les non lues
```bash
curl -s http://localhost:8080/api/notifications/unread-count \
  -H "Authorization: Bearer $TOKEN" | jq .
```

## 4. Tester le WebSocket STOMP

Utiliser un client STOMP (ex: wscat + stomp-cli ou extension navigateur) :

```
CONNECT
Authorization: Bearer <token>
accept-version:1.2
host:localhost

SUBSCRIBE
id:sub-0
destination:/user/queue/notifications
```

## 5. Frontend Angular

```bash
cd app
npm install @stomp/stompjs
ng serve
```

Ouvrir `http://localhost:4200` — la cloche de notification devrait apparaitre dans l'AppBar.

## 6. Flutter

```bash
cd flutter
flutter pub add stomp_dart_client flutter_local_notifications
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## 7. Declencher une notification de test

Creer un abonnement avec echeance demain, puis forcer l'execution du job :
```bash
# L'endpoint de test n'existe qu'en profil dev
curl -X POST http://localhost:8080/api/notifications/trigger-daily-job \
  -H "Authorization: Bearer $TOKEN"
```

Ou attendre l'execution automatique du job quotidien (6h UTC).

## 8. Intégration KKS-157 (Budget par catégorie)

Quand KKS-157 sera implémenté, le `BudgetService` devra appeler `NotificationService.checkBudgetThresholds()` après chaque création/modification de transaction :

```java
// Dans BudgetService ou TransactionService, après mise à jour du total de la catégorie :
notificationService.checkBudgetThresholds(
    userId,
    categoryId,
    previousTotal,    // total avant la transaction
    newTotal,          // total après la transaction
    budgetLimit,       // plafond budget de la catégorie
    thresholdPercent   // seuil d'alerte (ex: 80)
);
```

Le hook gère automatiquement :
- La vérification des préférences utilisateur (type de notification activé)
- La création des notifications BUDGET_THRESHOLD et BUDGET_EXCEEDED
- L'envoi en temps réel via WebSocket STOMP
