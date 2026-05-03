# Data Model: Banques sur les comptes — Angular

**Feature**: 082-angular-bank-accounts | **Date**: 2026-03-13

## Interfaces TypeScript

### BankResponse (NEW)

```typescript
// core/models/bank.model.ts
export interface BankResponse {
  code: string;        // ex: "SG", "BNP", "OTHER"
  name: string;        // ex: "Société Générale"
  country: string | null; // "FR", "TG", ou null (international)
  brandColor: string | null;  // ex: "#e2001a" (null pour OTHER)
  logoUrl: string | null;     // ex: "/api/bank-logos/sg.svg" (null pour OTHER)
}
```

**Source** : `GET /api/banks` (endpoint public, pas d'auth)
**Cardinalité** : 29 banques + OTHER = 30 items
**Tri** : FR → TG → International → OTHER (dernier)

### Account (UPDATE)

```typescript
// core/models/account.model.ts — champs ajoutés
export interface Account {
  // ... champs existants (id, nom, type, soldeInitial, solde, icone, couleur, isDefault, actif, currency)

  // NEW — bank fields (résolus par le backend)
  bankCode: string;           // "SG", "BNP", "OTHER", etc. Default: "OTHER"
  bankName: string | null;    // "Société Générale" (null si OTHER sans custom)
  bankCountry: string | null; // "FR", "TG", null
  bankBrandColor: string | null; // "#e2001a" (null si OTHER)
  bankLogoUrl: string | null; // "/api/bank-logos/sg.svg" (null si OTHER)
  bankCustomName: string | null; // Pour OTHER uniquement
  bankCustomLogo: string | null; // Data URI pour OTHER uniquement
}
```

### AccountRequest (UPDATE)

```typescript
// core/models/account.model.ts — champs ajoutés
export interface AccountRequest {
  // ... champs existants (nom, type, soldeInitial, icone, couleur, actif, currency)

  // NEW — bank fields
  bankCode?: string;         // Default: "OTHER"
  bankCustomName?: string;   // Max 100 caractères, pour OTHER uniquement
  bankCustomLogo?: string;   // Data URI, pour OTHER uniquement
}
```

### SelectPickerItem (UPDATE)

```typescript
// shared/components/select-picker/select-picker.ts — champ ajouté
export interface SelectPickerItem {
  // ... champs existants (id, label, icon, secondaryText, color)

  // NEW
  iconUrl?: string | null; // URL image (prioritaire sur icon emoji si présent)
}
```

## Relations

```
BankResponse (registre statique, 29+1)
    ↓ bankCode
Account (enrichi, champs bank résolus par backend)
    ↓ utilisé dans
AccountBankIcon (composant résolution visuelle)
```

## Règles de validation

| Champ | Règle | Source |
|-------|-------|--------|
| `bankCode` | Optionnel, default "OTHER". Doit exister dans le registre backend | Backend (Bean Validation) |
| `bankCustomName` | Max 100 caractères. Pertinent uniquement si `bankCode = "OTHER"` | Backend (`@Size(max=100)`) |
| `bankCustomLogo` | Data URI base64 (JPEG). Pertinent uniquement si `bankCode = "OTHER"` | Frontend (compression canvas) |

## Groupement des banques (UI)

| Groupe | Critère | Exemples |
|--------|---------|----------|
| France | `country = "FR"` | SG, BNP, CA, LCL, CM, CE, LBP, BP, BOURSO, FORTUNEO, HELLO, N26, REVOLUT, HSBC_FR, BIA |
| Afrique de l'Ouest | `country = "TG"` | ECOBANK, BOA, ORABANK, CORIS, BSIC, UTB, SUNU, BDT, NSIA, BTCI, SGTO, UBA |
| International | `country = null` | WISE |
| Autre | `code = "OTHER"` | (option synthétique, toujours en dernier) |

## États de résolution visuelle (AccountBankIcon)

| bankCode | bankCustomLogo | Affichage |
|----------|---------------|-----------|
| ≠ OTHER | — | `<img src="bankLogoUrl">` (SVG backend) |
| OTHER | non null | `<img src="bankCustomLogo">` (data URI) |
| OTHER | null | `<span>{{ account.icone }}</span>` (emoji) |
