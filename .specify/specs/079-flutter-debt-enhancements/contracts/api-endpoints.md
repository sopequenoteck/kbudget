# API Contracts: Debt Enhancements (Flutter consumer)

**Feature**: 079-flutter-debt-enhancements | **Date**: 2026-03-13

Ces endpoints sont DÉJÀ implémentés côté backend (KKS-077). Ce document décrit les contrats que le Flutter client consomme.

## Endpoints existants (enrichis)

### GET /api/debts

Retourne la liste des dettes de l'utilisateur authentifié.

**Response enrichie** (nouveaux champs) :
```json
[
  {
    "id": "uuid",
    "personne": "Jean",
    "montant": 500.0,
    "sens": "EMPRUNT",
    "date": "2026-01-15",
    "currency": "EUR",
    "rembourse": false,
    "categoryId": "uuid",
    "accountId": "uuid",
    "accountName": "Compte Courant",
    "includeInBalance": true,
    "dueDate": "2026-06-15",
    "reminderDate": "2026-03-15",
    "reminderTime": "09:00",
    "remainingAmount": 300.0,
    "updatedAt": "2026-03-13T10:00:00"
  }
]
```

### GET /api/debts/{id}

Retourne une dette par ID. Même format que ci-dessus (objet unique).

### POST /api/debts

Crée une dette. **Request enrichie** :
```json
{
  "personne": "Jean",
  "montant": 500.0,
  "sens": "EMPRUNT",
  "date": "2026-01-15",
  "rembourse": false,
  "categoryId": "uuid",
  "accountId": "uuid",
  "currency": "EUR",
  "includeInBalance": true,
  "dueDate": "2026-06-15",
  "reminderDate": "2026-03-15",
  "reminderTime": "09:00"
}
```

### PUT /api/debts/{id}

Mise à jour. Même format request.

## Nouveaux endpoints (KKS-077)

### POST /api/debts/{id}/repay

Enregistre un remboursement. Crée une transaction côté serveur.

**Request** :
```json
{
  "accountId": "uuid",
  "amount": 100.0
}
```

**Response** : Debt enrichie (objet complet mis à jour avec nouveau `remainingAmount`, `rembourse` potentiellement true).

### GET /api/debts/{id}/payments

Retourne l'historique des paiements pour une dette.

**Response** :
```json
[
  {
    "id": "uuid",
    "montant": 100.0,
    "date": "2026-03-10",
    "accountName": "Compte Courant"
  },
  {
    "id": "uuid",
    "montant": 200.0,
    "date": "2026-03-12",
    "accountName": "Épargne"
  }
]
```

### POST /api/debts/{id}/snooze

Reporte le rappel d'une dette.

**Request** :
```json
{
  "reminderDate": "2026-03-20",
  "reminderTime": "14:00"
}
```

**Response** : Debt enrichie (objet complet mis à jour avec nouveau `reminderDate`/`reminderTime`).

## Endpoint existant consommé

### GET /api/accounts

Utilisé pour la liste des comptes actifs dans le sélecteur (formulaire + bottom sheet remboursement). Déjà implémenté et consommé par `AccountNotifier`.
