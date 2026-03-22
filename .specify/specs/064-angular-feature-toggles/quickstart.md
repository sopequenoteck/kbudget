# Quickstart: Feature Toggles Angular

**Branch**: `064-angular-feature-toggles`

## Prérequis

- Node.js + npm installés
- Backend Spring Boot lancé (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Un utilisateur existant avec un token JWT valide

## Lancer le dev server

```bash
cd app && ng serve
```

→ `http://localhost:4200`

## Vérifier l'API backend

```bash
# Login pour obtenir un token
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}' | jq .token

# GET preferences (remplacer TOKEN)
curl -s http://localhost:8080/api/users/me/preferences \
  -H "Authorization: Bearer TOKEN" | jq .

# PUT preferences (toggle Boutique off)
curl -s -X PUT http://localhost:8080/api/users/me/preferences \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabledFeatures":["SUBSCRIPTIONS","DEBTS"]}' | jq .
```

## Fichiers à créer

| Fichier | Description |
|---------|-------------|
| `app/src/app/core/models/preference.model.ts` | Feature enum + interfaces UserPreference |
| `app/src/app/core/services/preference.ts` | PreferenceService (API + signals) |
| `app/src/app/core/guards/feature.guard.ts` | featureGuard (CanActivateFn) |
| `app/src/app/features/settings/components/features/features.ts` | Composant settings features |
| `app/src/app/features/settings/components/features/features.html` | Template |
| `app/src/app/features/settings/components/features/features.scss` | Styles |
| `app/src/app/features/shop/shop-placeholder.ts` | Placeholder "Coming soon" |

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `app/src/app/app.routes.ts` | Ajouter route `/shop` avec featureGuard |
| `app/src/app/features/settings/settings.routes.ts` | Ajouter route `features` |
| `app/src/app/features/settings/settings.ts` | Ajouter section "Fonctionnalités" dans SECTIONS |
| `app/src/app/shared/components/shell/shell.ts` | Injecter PreferenceService, computed() pour nav items |
| `app/src/app/shared/components/shell/shell.html` | Navigation dynamique via signal |
| `app/src/app/shared/components/fab/fab.ts` | Filtrer actions par features activées |

## Tests

```bash
cd app && ng test
```
