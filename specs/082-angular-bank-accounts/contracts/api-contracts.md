# API Contracts: Banques sur les comptes — Angular

**Feature**: 082-angular-bank-accounts | **Date**: 2026-03-13

## Endpoints consommés (backend existant KKS-081)

### GET /api/banks

**Auth**: Public (pas de JWT requis)
**Description**: Récupère la liste des 29 banques prédéfinies + OTHER

**Response** `200 OK`:
```json
[
  {
    "code": "SG",
    "name": "Société Générale",
    "country": "FR",
    "brandColor": "#e2001a",
    "logoUrl": "/api/bank-logos/sg.svg"
  },
  {
    "code": "OTHER",
    "name": "Autre",
    "country": null,
    "brandColor": null,
    "logoUrl": null
  }
]
```

**Tri**: FR → TG → International → OTHER (dernier)

### GET /api/accounts (enrichi)

**Auth**: JWT Bearer token
**Description**: Liste des comptes de l'utilisateur avec champs bank résolus

**Response** `200 OK` (champs bank ajoutés):
```json
{
  "id": "uuid",
  "nom": "Compte courant",
  "type": "COURANT",
  "soldeInitial": 0,
  "solde": 1500.00,
  "icone": "🏦",
  "couleur": "#f59e0b",
  "isDefault": true,
  "actif": true,
  "currency": "EUR",
  "isShopAccount": false,
  "bankCode": "SG",
  "bankName": "Société Générale",
  "bankCountry": "FR",
  "bankBrandColor": "#e2001a",
  "bankLogoUrl": "/api/bank-logos/sg.svg",
  "bankCustomName": null,
  "bankCustomLogo": null
}
```

### POST /api/accounts & PUT /api/accounts/{id} (enrichi)

**Auth**: JWT Bearer token
**Request body** (champs bank ajoutés):
```json
{
  "nom": "Compte courant",
  "type": "COURANT",
  "soldeInitial": 0,
  "icone": "🏦",
  "couleur": "#f59e0b",
  "currency": "EUR",
  "bankCode": "SG",
  "bankCustomName": null,
  "bankCustomLogo": null
}
```

| Champ | Type | Requis | Contraintes |
|-------|------|--------|-------------|
| `bankCode` | string | Non | Default "OTHER", doit exister dans le registre |
| `bankCustomName` | string | Non | Max 100 chars, pertinent si bankCode=OTHER |
| `bankCustomLogo` | string | Non | Data URI, pertinent si bankCode=OTHER |

### Logos SVG statiques

**URL pattern**: `/api/bank-logos/{code}.svg`
**Exemples**: `/api/bank-logos/sg.svg`, `/api/bank-logos/bnp.svg`
**Format**: SVG, servis comme ressources statiques par Spring Boot
**Fallback**: Si 404, afficher icône placeholder générique
