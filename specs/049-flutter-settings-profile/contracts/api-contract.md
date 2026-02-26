# API Contract: User Profile

**Feature**: 049-flutter-settings-profile | **Date**: 2026-02-23

## Endpoints consommés (backend existant)

### GET /api/users/me

Récupère le profil de l'utilisateur authentifié.

**Auth**: JWT Bearer token requis
**Response**: `200 OK`

```json
{
  "name": "Kelly",
  "email": "kelly@example.com",
  "defaultCurrency": "EUR"
}
```

**Erreurs**:

| Code | Cas | Comportement Flutter |
|------|-----|---------------------|
| 401 | Token expiré/invalide | Refresh token automatique via JwtInterceptor |
| 404 | User not found | Afficher erreur générique + retry |
| 500 | Erreur serveur | Afficher erreur générique + retry |

---

### PUT /api/users/me

Met à jour le profil de l'utilisateur authentifié.

**Auth**: JWT Bearer token requis
**Request**: `Content-Type: application/json`

```json
{
  "defaultCurrency": "XOF"
}
```

**Validation backend**: `defaultCurrency` doit être une valeur valide de l'enum Currency (EUR, XOF, USD, GBP, CHF, CAD, MAD).

**Response**: `200 OK`

```json
{
  "name": "Kelly",
  "email": "kelly@example.com",
  "defaultCurrency": "XOF"
}
```

**Erreurs**:

| Code | Cas | Comportement Flutter |
|------|-----|---------------------|
| 400 | defaultCurrency invalide | Impossible si le picker est correctement implémenté |
| 401 | Token expiré/invalide | Refresh token automatique via JwtInterceptor |
| 404 | User not found | Afficher erreur générique |
| 500 | Erreur serveur | Afficher erreur réseau + restaurer valeur précédente |

## Notes

- Le backend ne retourne pas l'`id` de l'utilisateur dans `UserResponse`
- Seul `defaultCurrency` est modifiable via PUT. `name` et `email` sont en lecture seule depuis ce endpoint.
- Le champ `name` peut être `null` dans la réponse
