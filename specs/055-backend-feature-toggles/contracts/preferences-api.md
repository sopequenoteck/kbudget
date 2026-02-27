# API Contract: Préférences utilisateur

**Base path**: `/api/users/me/preferences`
**Auth**: JWT Bearer token (obligatoire)

---

## GET /users/me/preferences

Récupérer les préférences de l'utilisateur authentifié.

### Response 200

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "DEBTS", "SHOP"]
}
```

### Response 200 — Préférences personnalisées

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "SHOP"],
  "navOrder": ["SHOP", "SUBSCRIPTIONS"]
}
```

### Response 200 — Toutes features désactivées

```json
{
  "enabledFeatures": [],
  "navOrder": []
}
```

### Response 401

Pas de token ou token invalide.

---

## PUT /users/me/preferences

Mettre à jour les préférences. `enabledFeatures` est obligatoire, `navOrder` est optionnel.

### Request — Toggle features (navOrder auto-géré)

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "SHOP"]
}
```

### Request — Toggle features + réordonnement explicite

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"],
  "navOrder": ["SHOP", "DEBTS", "SUBSCRIPTIONS"]
}
```

### Request — Désactiver toutes les features

```json
{
  "enabledFeatures": []
}
```

### Response 200

Retourne les préférences mises à jour (même format que GET).

```json
{
  "enabledFeatures": ["SUBSCRIPTIONS", "SHOP"],
  "navOrder": ["SUBSCRIPTIONS", "SHOP"]
}
```

### Response 400 — Feature inconnue

```json
{
  "timestamp": "2026-02-27T10:00:00",
  "status": 400,
  "message": "Fonctionnalité inconnue : UNKNOWN_FEATURE"
}
```

### Response 400 — navOrder incohérent

```json
{
  "timestamp": "2026-02-27T10:00:00",
  "status": 400,
  "message": "L'ordre de navigation doit contenir exactement les fonctionnalités activées"
}
```

### Response 400 — Doublons dans navOrder

```json
{
  "timestamp": "2026-02-27T10:00:00",
  "status": 400,
  "message": "L'ordre de navigation ne doit pas contenir de doublons"
}
```

### Response 401

Pas de token ou token invalide.

---

## DTOs

### UserPreferenceRequest (PUT body)

| Champ | Type | Requis | Validation |
|-------|------|--------|------------|
| `enabledFeatures` | `List<Feature>` | oui | Non-null, valeurs strictement parmi l'enum Feature : `SUBSCRIPTIONS`, `DEBTS`, `SHOP`. Toute autre valeur provoque une erreur 400. |
| `navOrder` | `List<Feature>` | non | Si fourni : doit contenir exactement les features activées, sans doublons. Mêmes valeurs enum que enabledFeatures. |

### UserPreferenceResponse (GET/PUT response)

| Champ | Type | Description |
|-------|------|-------------|
| `enabledFeatures` | `List<Feature>` | Features optionnelles activées (valeurs enum) |
| `navOrder` | `List<Feature>` | Ordre des onglets (features activées uniquement, valeurs enum) |
