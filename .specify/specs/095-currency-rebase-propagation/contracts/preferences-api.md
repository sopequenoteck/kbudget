# API Contract: Preferences — Currency Rebase

**Feature**: 095-currency-rebase-propagation
**Date**: 2026-03-15

## Endpoints impactés

### PUT /api/users/me/preferences (existant, comportement enrichi)

**Changement** : Quand `currencies[0]` change par rapport à la valeur actuelle en base, le serveur appelle `rebaseRates()` automatiquement avant de sauvegarder. L'opération est transactionnelle.

**Request** (inchangé) :
```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"],
  "currencies": ["XOF", "EUR", "USD"],
  "...": "..."
}
```

**Response** (inchangé) :
```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"],
  "currencies": ["XOF", "EUR", "USD"],
  "...": "..."
}
```

**Nouveau comportement** :
- Si `request.currencies[0]` ≠ `stored.currencies[0]` → `rebaseRates(userId, oldPrimary, newPrimary)` est appelé
- Si le rebase échoue → HTTP 500 + rollback complet (devise ET taux inchangés)
- Si `currencies` est null dans la request → aucun rebase (partial update)
- Si `currencies[0]` est identique → aucun rebase

**Codes d'erreur** :
| Code | Cas |
|------|-----|
| 200  | Préférences mises à jour (avec ou sans rebase) |
| 400  | Validation échouée (devises vides, doublons, etc.) |
| 500  | Rebase échoué (rollback complet) |

### GET /api/exchange-rates (existant, inchangé)

Utilisé par les frontends pour recharger les taux après un changement de devise.

**Response** :
```json
[
  {
    "id": "...",
    "baseCurrency": "XOF",
    "targetCurrency": "EUR",
    "rate": 0.001524,
    "updatedAt": "..."
  }
]
```

## WebSocket STOMP (nouveau comportement)

Après un rebase réussi, le serveur envoie un événement WebSocket STOMP à l'utilisateur :

**Destination** : `/user/queue/exchange-rates`
**Payload** :
```json
{
  "type": "EXCHANGE_RATES_UPDATED",
  "message": "Taux de change rebasés"
}
```

Les clients connectés (y compris sur d'autres devices) écoutent ce topic et déclenchent `GET /api/exchange-rates` automatiquement.

## Séquence d'appels frontend

### Device actif (celui qui change la devise)

```
1. PUT /api/users/me/preferences  { currencies: ["XOF", "EUR"] }
   → 200 OK (backend a rebasé les taux + poussé WebSocket)
2. GET /api/exchange-rates
   → 200 OK (taux rebasés sur XOF)
3. UI recalcule les montants avec les nouveaux taux
```

### Autre device connecté (WebSocket)

```
1. Reçoit événement STOMP EXCHANGE_RATES_UPDATED
2. GET /api/exchange-rates
   → 200 OK (taux rebasés sur XOF)
3. UI recalcule les montants avec les nouveaux taux
```

### Échec du rechargement (GET /exchange-rates)

```
1. PUT /api/users/me/preferences → 200 OK (rebase réussi)
2. GET /api/exchange-rates → erreur réseau
3. Afficher toast/SnackBar "Échec du rechargement des taux" + bouton retry
4. Garder les anciennes valeurs avec indicateur "taux périmés"
```
