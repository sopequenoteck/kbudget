# API Contracts Consumed: 083-flutter-bank-accounts

## GET /api/banks (public)

Endpoint consommé depuis le backend KKS-081.

**Response**: `200 OK`

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
    "brandColor": "#6b7280",
    "logoUrl": "/api/bank-logos/other.svg"
  }
]
```

## GET /api/accounts (enrichi)

Champs bank ajoutés à la réponse existante :

```json
{
  "id": "uuid",
  "nom": "Compte courant",
  "type": "COURANT",
  "bankCode": "SG",
  "bankName": "Société Générale",
  "bankCountry": "FR",
  "bankBrandColor": "#e2001a",
  "bankLogoUrl": "/api/bank-logos/sg.svg",
  "bankCustomName": null,
  "bankCustomLogo": null,
  "..."
}
```

## POST/PUT /api/accounts (enrichi)

Champs bank ajoutés à la requête existante :

```json
{
  "nom": "Mon compte",
  "type": "COURANT",
  "bankCode": "SG",
  "bankCustomName": null,
  "bankCustomLogo": null,
  "..."
}
```

Pour une banque custom :

```json
{
  "nom": "Micro-finance",
  "type": "COURANT",
  "bankCode": "OTHER",
  "bankCustomName": "Ma Banque Locale",
  "bankCustomLogo": "data:image/jpeg;base64,/9j/4AAQ...",
  "..."
}
```
