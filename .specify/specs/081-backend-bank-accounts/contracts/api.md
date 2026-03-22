# API Contracts: Banques sur les comptes

**Feature**: 081-backend-bank-accounts | **Date**: 2026-03-13

## Nouveaux endpoints

### GET /api/banks

Liste toutes les banques supportées.

**Auth**: Public (pas de JWT requis)

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

**Notes** :
- Retourne toujours les 29 entrées, triées par pays (FR, TG) puis par nom
- OTHER est toujours en dernier
- Pas de pagination (liste fixe)

---

## Endpoints modifiés

### POST /api/accounts (création)

**Auth**: JWT requis

**Request** (champs ajoutés) :

```json
{
  "nom": "Mon compte courant",
  "type": "COURANT",
  "soldeInitial": 1000.00,
  "icone": "🏦",
  "couleur": "#3b82f6",
  "actif": true,
  "currency": "EUR",
  "bankCode": "SG",
  "bankCustomName": null,
  "bankCustomLogo": null
}
```

| Champ | Type | Requis | Validation | Description |
|-------|------|--------|------------|-------------|
| bankCode | String | Non (default: "OTHER") | Doit exister dans le registre des banques | Code de la banque |
| bankCustomName | String | Non | Max 100 caractères | Nom personnalisé (utilisé si bankCode="OTHER") |
| bankCustomLogo | String | Non | Aucune (texte libre) | Logo en base64 data URI (utilisé si bankCode="OTHER") |

**Response** (champs ajoutés dans AccountResponse) :

```json
{
  "id": "uuid",
  "nom": "Mon compte courant",
  "type": "COURANT",
  "soldeInitial": 1000.00,
  "solde": 1000.00,
  "icone": "🏦",
  "couleur": "#3b82f6",
  "isDefault": false,
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

| Champ réponse | Type | Description |
|---------------|------|-------------|
| bankCode | String | Code de la banque associée |
| bankName | String | Nom résolu (banque connue) ou null (OTHER sans custom name) |
| bankCountry | String | Pays résolu (banque connue) ou null (OTHER) |
| bankBrandColor | String | Couleur brand résolue ou "#6b7280" (OTHER) |
| bankLogoUrl | String | URL logo résolu ou "/api/bank-logos/other.svg" |
| bankCustomName | String | Nom personnalisé (si OTHER), null sinon |
| bankCustomLogo | String | Logo personnalisé (si OTHER), null sinon |

### PUT /api/accounts/{id} (modification)

Mêmes champs ajoutés que POST. Permet de changer la banque d'un compte existant.

### GET /api/accounts et GET /api/accounts/{id}

Les réponses incluent les nouveaux champs bankCode, bankName, bankCountry, bankBrandColor, bankLogoUrl, bankCustomName, bankCustomLogo.

---

## Erreurs

| Code | Condition | Corps |
|------|-----------|-------|
| 400 | bankCode invalide (pas dans le registre) | `{"error": "Invalid bank code: INEXISTANT"}` |
| 400 | bankCustomName > 100 caractères | `{"error": "Bank custom name must not exceed 100 characters"}` |

---

## Ressources statiques

### GET /api/bank-logos/{code}.svg

**Auth**: Public
**Content-Type**: `image/svg+xml`
**Cache**: Servi par Spring Boot static resource handler (cache par défaut)

Fichiers disponibles : `sg.svg`, `bnp.svg`, `boa.svg`, `bourso.svg`, `bp.svg`, `bsic.svg`, `ca.svg`, `ce.svg`, `cm.svg`, `coris.svg`, `ecobank.svg`, `fortuneo.svg`, `hello.svg`, `hsbc_fr.svg`, `lbp.svg`, `lcl.svg`, `n26.svg`, `orabank.svg`, `other.svg`, `revolut.svg`, `utb.svg`, `sunu.svg`, `bdt.svg`, `nsia.svg`, `btci.svg`, `bia.svg`, `sgto.svg`, `uba.svg`, `wise.svg`
