# API Endpoints: 087-angular-recurring-form

## Endpoint consommé (existant — backend KKS-085)

### POST /api/transactions/recurring

Crée une transaction récurrente.

**Request**:
```json
{
  "montant": 50.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "categoryId": "uuid-category",
  "accountId": "uuid-account",
  "note": "Loyer mensuel"
}
```

**Response** (201 Created):
```json
{
  "id": "uuid",
  "montant": 50.00,
  "libelle": "Loyer",
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "recurringActive": true,
  "category": { "id": "uuid", "nom": "Logement", "icone": "🏠", "couleur": "#..." },
  "account": { "id": "uuid", "nom": "Compte courant" }
}
```

**Erreurs**:
- 400 Bad Request — champs manquants ou invalides (montant ≤ 0, date dans le passé)
- 401 Unauthorized — JWT absent ou expiré
- 404 Not Found — categoryId ou accountId invalide

## Aucun nouvel endpoint

Cette feature ne crée aucun nouvel endpoint backend. Elle consomme uniquement l'endpoint existant ci-dessus.
