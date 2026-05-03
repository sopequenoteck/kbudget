# API Contract: Notification System

**Base path**: `/api`
**Auth**: JWT Bearer token (header `Authorization: Bearer <token>`)

## Endpoints REST

### GET /notifications

Liste paginee des notifications de l'utilisateur authentifie.

**Query params**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | int | 0 | Numero de page (0-indexed, retourne en tant que "number" dans la reponse — convention Spring Data) |
| size | int | 20 | Taille de page |
| unread | boolean | — | Si present, filtre par statut de lecture |

**Response 200**:
```json
{
  "content": [
    {
      "id": "uuid",
      "type": "SUBSCRIPTION_DUE",
      "title": "Abonnement Netflix",
      "message": "Abonnement Netflix — echeance demain",
      "entityType": "SUBSCRIPTION",
      "entityId": "uuid",
      "read": false,
      "readAt": null,
      "createdAt": "2026-03-06T07:00:00"
    }
  ],
  "number": 0,
  "size": 20,
  "totalElements": 42,
  "totalPages": 3
}
```

### GET /notifications/unread-count

Nombre de notifications non lues.

**Response 200**:
```json
{
  "count": 5
}
```

### PUT /notifications/{id}/read

Marque une notification comme lue.

**Response 200**:
```json
{
  "id": "uuid",
  "type": "SUBSCRIPTION_DUE",
  "title": "Abonnement Netflix",
  "message": "Abonnement Netflix — echeance demain",
  "entityType": "SUBSCRIPTION",
  "entityId": "uuid",
  "read": true,
  "readAt": "2026-03-06T12:30:00",
  "createdAt": "2026-03-06T07:00:00"
}
```

### PUT /notifications/read-all

Marque toutes les notifications non lues comme lues.

**Response 204**: No content

### DELETE /notifications/{id}

Supprime une notification.

**Response 204**: No content

### DELETE /notifications

Supprime toutes les notifications de l'utilisateur (vider l'historique).

**Response 204**: No content

## WebSocket STOMP

### Endpoint de connexion

```
ws://{host}/api/ws
```

### Authentification

Frame STOMP `CONNECT` avec header :
```
Authorization: Bearer <jwt-access-token>
```

### Subscription

Le client subscribe a sa queue personnelle :
```
/user/queue/notifications
```

### Message recu (notification)

```json
{
  "id": "uuid",
  "type": "SUBSCRIPTION_DUE",
  "title": "Abonnement Netflix",
  "message": "Abonnement Netflix — echeance demain",
  "entityType": "SUBSCRIPTION",
  "entityId": "uuid",
  "read": false,
  "readAt": null,
  "createdAt": "2026-03-06T07:00:00"
}
```

## Preferences de notification

### Enrichissement PUT /users/me/preferences

**Request body** (champs ajoutes aux existants) :
```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS"],
  "enabledNotificationTypes": ["BUDGET_THRESHOLD", "BUDGET_EXCEEDED", "SUBSCRIPTION_DUE", "DEBT_DUE"],
  "timezone": "Europe/Paris"
}
```

**Response** (champs ajoutes aux existants) :
```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS"],
  "enabledNotificationTypes": ["BUDGET_THRESHOLD", "BUDGET_EXCEEDED", "SUBSCRIPTION_DUE", "DEBT_DUE"],
  "timezone": "Europe/Paris"
}
```

**Defaut**: Si `enabledNotificationTypes` est null (jamais configure), tous les types sont actifs.

## Endpoints dev-only (@Profile("dev"))

### POST /notifications/trigger-daily-job

Declenche manuellement le job quotidien de rappels (abonnements + dettes J-1 + purge 90 jours). Utile pour les tests.

**Response 200**: No content (les notifications sont creees en base et envoyees via WebSocket si connecte)

> **Note**: Cet endpoint n'est disponible qu'avec le profil Spring `dev`. Il n'est pas expose en production.

## Codes erreur

| Code | Condition |
|------|-----------|
| 401 | Token JWT manquant ou invalide |
| 403 | Tentative d'acces a une notification d'un autre utilisateur |
| 404 | Notification introuvable |
