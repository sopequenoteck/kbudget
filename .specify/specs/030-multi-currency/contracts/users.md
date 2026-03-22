# API Contract: Users (multi-currency)

## Nouveaux endpoints

### GET /api/users/me — Profil utilisateur

**Auth** : JWT requis

**Response** (UserResponse — NEW) :
```json
{
  "name": "Kelly",
  "email": "kelly@example.com",
  "defaultCurrency": "EUR"
}
```

### PUT /api/users/me — Modifier le profil

**Auth** : JWT requis

**Request** (UserUpdateRequest — NEW) :
```json
{
  "name": "Kelly",                // optionnel
  "defaultCurrency": "XOF"       // optionnel
}
```

**Validation** :
- `name` : si fourni, `@Size(min = 1, max = 255)`
- `defaultCurrency` : si fourni, doit être un code Currency valide (enum)
- Au moins un champ doit être fourni

**Response** : `UserResponse` avec les valeurs mises à jour.

**Codes d'erreur** :
- 400 : Currency invalide ou aucun champ fourni
- 401 : Non authentifié

**Note** : La modification de `defaultCurrency` n'affecte PAS les comptes, dettes ou abonnements existants. Elle n'affecte que les futures créations (pré-remplissage).
