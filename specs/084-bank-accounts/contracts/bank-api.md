# API Contract: Bank Accounts

**Date**: 2026-03-14
**Status**: Done (rétroactif)

## GET /banks

Liste des banques supportées (endpoint public, pas d'authentification requise).

**Request**:
```http
GET /api/banks HTTP/1.1
```

**Response** `200 OK`:
```json
[
  {
    "code": "SG",
    "name": "Société Générale",
    "country": "FR",
    "brandColor": "#e4002b",
    "logoUrl": "/api/bank-logos/sg.svg"
  },
  {
    "code": "ECOBANK",
    "name": "Ecobank",
    "country": "TG",
    "brandColor": "#0033a0",
    "logoUrl": "/api/bank-logos/ecobank.svg"
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

**Tri** : France → Togo/UEMOA → International → OTHER (toujours en dernier).

## POST /accounts (enrichi)

**Request** (champs bank ajoutés) :
```json
{
  "nom": "Compte courant",
  "type": "COURANT",
  "soldeInitial": 0,
  "icone": "🏦",
  "couleur": "#e4002b",
  "devise": "EUR",
  "bankCode": "SG",
  "bankCustomName": null,
  "bankCustomLogo": null
}
```

**Avec banque custom** :
```json
{
  "nom": "Compte courant",
  "type": "COURANT",
  "soldeInitial": 0,
  "icone": "🏦",
  "couleur": "#333333",
  "devise": "EUR",
  "bankCode": "OTHER",
  "bankCustomName": "Ma Banque Locale",
  "bankCustomLogo": "data:image/png;base64,iVBOR..."
}
```

## GET /accounts (réponse enrichie)

**Response** (7 champs bank résolus ajoutés) :
```json
{
  "id": "uuid",
  "nom": "Compte courant",
  "type": "COURANT",
  "soldeInitial": 0,
  "icone": "🏦",
  "couleur": "#e4002b",
  "devise": "EUR",
  "isDefault": false,
  "actif": true,
  "bankCode": "SG",
  "bankName": "Société Générale",
  "bankCountry": "FR",
  "bankBrandColor": "#e4002b",
  "bankLogoUrl": "/api/bank-logos/sg.svg",
  "bankCustomName": null,
  "bankCustomLogo": null,
  "updatedAt": "2026-03-14T10:00:00"
}
```

**Pour banque custom (OTHER)** :
```json
{
  "bankCode": "OTHER",
  "bankName": "Ma Banque Locale",
  "bankCountry": null,
  "bankBrandColor": null,
  "bankLogoUrl": "data:image/png;base64,iVBOR...",
  "bankCustomName": "Ma Banque Locale",
  "bankCustomLogo": "data:image/png;base64,iVBOR..."
}
```

## Logos statiques

```http
GET /api/bank-logos/{code}.svg HTTP/1.1
```

29 fichiers SVG servis en statique. Pas d'authentification requise (assets publics dans `static/bank-logos/`).
