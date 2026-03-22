# API Contract: User Preferences (Feature Toggles)

**Base URL**: `/api/users/me/preferences`
**Auth**: JWT Bearer token requis

## GET /users/me/preferences

Retourne les préférences de l'utilisateur authentifié. Crée les préférences par défaut si aucune n'existe (ne retourne jamais 404).

### Response 200

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "shopAccountId": null,
  "includeShopInBalance": false
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `enabledFeatures` | `string[]` | Features activées. Valeurs : `SUBSCRIPTIONS`, `DEBTS`, `SHOP` |
| `navOrder` | `string[]` | Ordre de navigation, même ensemble que `enabledFeatures` |
| `shopAccountId` | `string?` | UUID du compte lié à la boutique |
| `includeShopInBalance` | `boolean` | Inclure le solde boutique dans le total |

### Response 401

Token JWT invalide ou absent.

---

## PUT /users/me/preferences

Met à jour les préférences de l'utilisateur authentifié.

### Request Body

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"],
  "navOrder": null,
  "shopAccountId": null,
  "includeShopInBalance": null
}
```

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `enabledFeatures` | `string[]` | oui | Features à activer |
| `navOrder` | `string[]?` | non | Si null → auto-géré par le serveur |
| `shopAccountId` | `string?` | non | Si null → ignoré (pas de mise à null) |
| `includeShopInBalance` | `boolean?` | non | Si null → ignoré (pas de mise à null) |

### Validation Rules

- `enabledFeatures` ne contient que des valeurs de l'enum Feature (`SUBSCRIPTIONS`, `DEBTS`, `SHOP`)
- Si `navOrder` fourni : doit contenir exactement les mêmes valeurs que `enabledFeatures`, sans doublon
- Si `navOrder` null : le serveur conserve l'ordre existant, retire les features désactivées, ajoute les nouvelles en fin

### Response 200

Même format que GET — retourne l'état mis à jour.

### Response 400

Validation échouée (feature inconnue, navOrder incohérent, doublons).

### Response 401

Token JWT invalide ou absent.

---

## Usage Flutter

Pour cette feature (toggles uniquement), le PUT enverra :
- `enabledFeatures` : la liste mise à jour
- `navOrder` : `null` (auto-géré par le serveur)
- `shopAccountId` : `null` (ignoré)
- `includeShopInBalance` : `null` (ignoré)
