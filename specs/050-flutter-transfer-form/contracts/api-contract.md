# API Contract: Transfer

**Feature**: 050-flutter-transfer-form | **Date**: 2026-02-23

## Endpoint consommé (backend existant)

### POST /api/accounts/transfer

Crée un virement entre deux comptes de l'utilisateur authentifié.

**Auth**: JWT Bearer token requis
**Request**: `Content-Type: application/json`

```json
{
  "fromAccountId": "uuid-compte-source",
  "toAccountId": "uuid-compte-destination",
  "montant": 150.00,
  "note": "Épargne mensuelle"
}
```

**Validation backend**:
- `fromAccountId` : requis, UUID valide, compte appartenant à l'utilisateur authentifié
- `toAccountId` : requis, UUID valide, compte appartenant à l'utilisateur authentifié, différent de `fromAccountId`
- `montant` : requis, >= 0.01
- `note` : optionnel, max 500 caractères

**Response**: `201 Created`

```json
{
  "transferId": "uuid-du-virement",
  "debitTransaction": {
    "id": "uuid-transaction-debit",
    "montant": 150.00,
    "libelle": "Virement Courant → Épargne",
    "type": "DEPENSE",
    "date": "2026-02-23",
    "accountId": "uuid-compte-source",
    "accountNom": "Courant"
  },
  "creditTransaction": {
    "id": "uuid-transaction-credit",
    "montant": 150.00,
    "libelle": "Virement Courant → Épargne",
    "type": "RECETTE",
    "date": "2026-02-23",
    "accountId": "uuid-compte-destination",
    "accountNom": "Épargne"
  }
}
```

**Erreurs**:

| Code | Cas | Comportement Flutter |
|------|-----|---------------------|
| 400 | Validation échouée (montant invalide, même compte) | Afficher message d'erreur dans le formulaire |
| 401 | Token expiré/invalide | Refresh token automatique via JwtInterceptor |
| 404 | Compte introuvable | Afficher erreur générique dans le formulaire |
| 500 | Erreur serveur | Afficher erreur réseau dans le formulaire |

## Notes

- Le backend génère automatiquement le `transferId` (UUID) et les libellés des transactions
- La date est la date courante côté serveur (pas envoyée dans la requête)
- Les deux transactions sont créées atomiquement (même transaction DB)
- Le champ `note` est partagé entre les deux transactions créées
