# Quickstart: Currency Dashboard

**Feature Branch**: `070-currency-dashboard`

## Prerequis

- Java 21 + Maven
- PostgreSQL 15+ (local ou Docker)
- Node.js + Angular CLI
- Flutter SDK >= 3.27
- Profil dev actif pour le backend

## Demarrage rapide

### 1. Backend

```bash
cd api
mvn clean compile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

Les migrations Flyway V13 et V14 s'executent automatiquement au demarrage.

Verifier :
- `GET /api/exchange-rates` → `[]` (liste vide)
- `GET /api/users/me/preferences` → `{ ..., "currencies": ["EUR"] }`
- `GET /api/currencies` → liste des 7 devises

### 2. Angular

```bash
cd app
ng serve
# http://localhost:4200
```

### 3. Flutter

```bash
cd flutter
dart run build_runner build --delete-conflicting-outputs  # Si nouveaux modeles Freezed
flutter run
```

## Tester la feature

### Scenario minimal

1. **Creer 2 comptes** dans des devises differentes (EUR + XOF)
2. **Ajouter un taux** : PUT `/api/exchange-rates` `{ "baseCurrency": "EUR", "targetCurrency": "XOF", "rate": 655.957 }`
3. **Consulter le dashboard** : le patrimoine total est affiche en EUR (devise principale)
4. **Tapper le pill XOF** : le dashboard se recalcule en XOF instantanement
5. **Verifier la persistance** : quitter le dashboard, revenir — XOF est toujours la devise principale

### Endpoints cles a tester

| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET | /exchange-rates | Lister les taux |
| PUT | /exchange-rates | Creer/modifier un taux (upsert) |
| DELETE | /exchange-rates/{base}/{target} | Supprimer un taux |
| GET | /users/me/preferences | Lire preferences (incl. currencies) |
| PUT | /users/me/preferences | Modifier preferences (incl. currencies) |

## Points d'attention

- La migration V14 **supprime** `User.defaultCurrency` — le code doit etre adapte avant
- Les taux sont automatiquement inverses quand la devise principale change
- Les conversions sont 100% cote client — aucun montant stocke n'est modifie
- `build_runner` necessaire apres creation des modeles Freezed (ExchangeRate)
