# Quickstart: Banques sur les comptes — Angular

**Feature**: 082-angular-bank-accounts | **Date**: 2026-03-13

## Prérequis

- Backend KKS-081 déployé avec `GET /api/banks` fonctionnel
- Logos SVG servis depuis `/api/bank-logos/`
- Node.js installé, `npm install` effectué dans `app/`

## Lancer le dev

```bash
# Backend (nécessaire pour les logos et l'API banks)
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Frontend Angular
cd app && ng serve
```

## Vérifier le backend

```bash
# Liste des banques (public, pas d'auth)
curl http://localhost:8080/api/banks | jq '.[0:3]'

# Vérifier un logo SVG
curl -I http://localhost:8080/api/bank-logos/sg.svg

# Créer un compte avec banque
curl -X POST http://localhost:8080/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nom":"Compte SG","type":"COURANT","bankCode":"SG"}'
```

## Fichiers clés à modifier/créer

| Action | Fichier | Description |
|--------|---------|-------------|
| NEW | `core/models/bank.model.ts` | Interface `BankResponse` |
| UPDATE | `core/models/account.model.ts` | +7 champs bank sur `Account`, +3 sur `AccountRequest` |
| NEW | `core/services/bank.ts` | `BankService` signal-based avec cache |
| NEW | `shared/components/account-bank-icon/` | Composant résolution logo |
| NEW | `shared/components/bank-select/` | Sélecteur banque groupé |
| UPDATE | `shared/components/account-form/` | Section banque + masquage conditionnel |
| UPDATE | `shared/components/select-picker/` | +`iconUrl` optionnel sur `SelectPickerItem` |
| UPDATE | `features/settings/components/accounts/` | Logo banque dans la liste |

## Tests

```bash
cd app && ng test
```
