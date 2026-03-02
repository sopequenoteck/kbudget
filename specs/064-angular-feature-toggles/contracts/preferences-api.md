# API Contract: User Preferences

**Base path**: `/api/users/me/preferences`
**Auth**: JWT Bearer token (header `Authorization`)

## GET /users/me/preferences

Récupère les préférences de l'utilisateur connecté.

### Response 200

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS"],
  "shopAccountId": null,
  "includeShopInBalance": false
}
```

### Response 401

Token absent ou invalide.

---

## PUT /users/me/preferences

Met à jour les préférences.

### Request Body

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "SHOP"],
  "navOrder": ["SHOP", "SUBSCRIPTIONS"],
  "shopAccountId": null,
  "includeShopInBalance": null
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `enabledFeatures` | `string[]` | **oui** | Valeurs : `SUBSCRIPTIONS`, `DEBTS`, `SHOP` |
| `navOrder` | `string[] \| null` | non | Si fourni : exactement les mêmes features qu'enabledFeatures, sans doublon. Si absent : auto-géré par le backend. |
| `shopAccountId` | `string \| null` | non | UUID. Si null dans body : champ existant conservé. |
| `includeShopInBalance` | `boolean \| null` | non | Si null dans body : valeur existante conservée. |

### Response 200

Même shape que GET.

### Response 400

- `enabledFeatures` absent ou null
- `navOrder` contient des doublons
- `navOrder` ne correspond pas à `enabledFeatures`

### Response 404

- `shopAccountId` invalide ou n'appartient pas à l'utilisateur

---

## Comportement getOrCreate

Si aucune préférence n'existe pour l'utilisateur, le backend crée automatiquement une entrée avec :
- `enabledFeatures`: `[SUBSCRIPTIONS, DEBTS, SHOP]`
- `navOrder`: `[SUBSCRIPTIONS, DEBTS, SHOP]`
- `includeShopInBalance`: `false`
- `shopAccountId`: `null`
