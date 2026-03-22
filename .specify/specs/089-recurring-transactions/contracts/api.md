# API Contracts: Transactions récurrentes & améliorations abonnements

**Feature**: 089-recurring-transactions
**Base path**: /api
**Auth**: Bearer JWT (toutes les routes)

## Récurrences

### POST /transactions/recurring

Créer une transaction récurrente.

**Request**:
```json
{
  "libelle": "Loyer",
  "montant": 800.00,
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "categoryId": "uuid",
  "accountId": "uuid",
  "note": "Appartement principal"
}
```

**Response** (201):
```json
{
  "id": "uuid",
  "libelle": "Loyer",
  "montant": 800.00,
  "type": "DEPENSE",
  "frequency": "MENSUEL",
  "nextOccurrence": "2026-04-01",
  "recurringActive": true,
  "category": { "id": "uuid", "nom": "Logement", "icone": "🏠", "couleur": "#..." },
  "account": { "id": "uuid", "nom": "Compte courant" },
  "note": "Appartement principal"
}
```

**Erreurs**: 400 (validation), 404 (catégorie/compte introuvable)

---

### GET /transactions/recurring

Lister les transactions récurrentes actives de l'utilisateur.

**Response** (200): `RecurringTransactionResponse[]`

---

### POST /transactions/recurring/{id}/validate

Valider une occurrence — crée la transaction effective et avance nextOccurrence.

**Response** (200): `TransactionResponse` (la transaction créée)

**Erreurs**: 404 (récurrence introuvable), 400 (récurrence inactive)

---

### POST /transactions/recurring/{id}/skip

Passer une occurrence — avance nextOccurrence sans créer de transaction.

**Response** (200): `RecurringTransactionResponse` (avec nextOccurrence mis à jour)

**Erreurs**: 404, 400 (inactive)

---

### POST /transactions/recurring/{id}/deactivate

Désactiver une récurrence (recurringActive = false).

**Response** (204): No Content

**Erreurs**: 404

## Paiements d'abonnements

### POST /subscriptions/{id}/pay

Payer un abonnement — crée une transaction liée par subscriptionId.

**Response** (201): `TransactionResponse`

**Erreurs**: 404 (abonnement introuvable), 400 (abonnement inactif), 400 (aucun compte disponible)

---

### GET /subscriptions/{id}/payments

Historique des paiements d'un abonnement.

**Response** (200):
```json
[
  {
    "id": "uuid",
    "montant": 13.49,
    "date": "2026-03-01",
    "accountName": "Compte courant"
  }
]
```

---

### GET /subscriptions/{id}/payments/total

Nombre total de paiements effectués pour un abonnement (count, pas somme monétaire).

**Response** (200):
```json
42
```

**Note**: Retourne un `long` (count). Le cumul monétaire est calculé côté frontend en sommant les montants de la liste GET /subscriptions/{id}/payments.
