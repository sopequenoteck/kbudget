# API Contract: Preferences (enrichi textScale)

## GET /users/me/preferences

**Response** (ajout du champ `textScale`) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP", "BUDGETS"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP", "BUDGETS"],
  "shopAccountId": null,
  "includeShopInBalance": false,
  "currencies": ["EUR", "XOF"],
  "enabledNotificationTypes": ["SUBSCRIPTION_DUE", "DEBT_DUE"],
  "timezone": "Europe/Paris",
  "textScale": "MEDIUM"
}
```

## PUT /users/me/preferences

**Request** (textScale nullable — partial update) :

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP", "BUDGETS"],
  "textScale": "LARGE"
}
```

Si `textScale` est absent ou null, la valeur actuelle est conservée.

**Valeurs acceptées** : `SMALL`, `MEDIUM`, `LARGE`

**Response** : même format que GET (toutes les préférences courantes).
