# Data Model: Settings — Profil

**Feature**: 049-flutter-settings-profile | **Date**: 2026-02-23

## Entités

### User (existant — aucune modification)

Modèle domaine Freezed déjà défini dans `flutter/lib/src/domain/models/user.dart`.

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | String | Non | UUID unique de l'utilisateur |
| email | String | Non | Adresse email (lecture seule) |
| name | String? | Oui | Nom affiché (lecture seule, peut être null) |
| defaultCurrency | Currency | Non | Devise par défaut (modifiable). Default: `Currency.eur` |

### Currency (existant — aucune modification)

Enum déjà défini dans `flutter/lib/src/domain/enums/currency.dart`.

| Valeur | Symbole | Nom complet | Décimales |
|--------|---------|-------------|-----------|
| eur | € | Euro | 2 |
| xof | CFA | Franc CFA (BCEAO) | 0 |
| usd | $ | Dollar américain | 2 |
| gbp | £ | Livre sterling | 2 |
| chf | CHF | Franc suisse | 2 |
| cad | CA$ | Dollar canadien | 2 |
| mad | MAD | Dirham marocain | 2 |

## DTOs (nouveaux)

### UserResponse (DTO de transport)

Reçu du backend via GET/PUT `/users/me`.

| Champ | Type JSON | Description |
|-------|-----------|-------------|
| name | string? | Nom de l'utilisateur (peut être null) |
| email | string | Adresse email |
| defaultCurrency | string | Code devise en majuscules (ex: "EUR", "XOF") |

**Note** : Le backend ne retourne pas l'`id` dans `UserResponse`. L'id est connu via le token JWT.

### UserUpdateRequest (DTO de transport)

Envoyé au backend via PUT `/users/me`.

| Champ | Type JSON | Validation backend | Description |
|-------|-----------|-------------------|-------------|
| defaultCurrency | string | @NotNull, valeur de l'enum Currency | Code devise en majuscules |

## Relations

```
User 1──1 Currency (defaultCurrency)
```

Relation simple : chaque utilisateur a exactement une devise par défaut. La devise est une valeur fixe (enum), pas une entité persistée.

## Transitions d'état

### État de l'écran Profil

```
[Initial] → Loading → Loaded(User)
                    → Error(message)

[Loaded] → Saving → Loaded(User updated) + SnackBar succès
                  → Loaded(User original) + SnackBar erreur
```

- **Loading** : Chargement initial via GET /users/me
- **Loaded** : Données affichées, modification possible
- **Saving** : PUT /users/me en cours (bouton disabled, indicateur)
- **Error** : Erreur réseau/serveur avec option retry

## Mapping DTO → Domain

| UserResponse (DTO) | User (Domain) | Transformation |
|--------------------|---------------|----------------|
| — | id | Non fourni par l'API. Utiliser `'profile'` comme id sentinelle (jamais utilisé en dehors du mapping — l'écran profil ne manipule pas l'id). |
| email | email | Direct |
| name | name | Direct (nullable) |
| defaultCurrency | defaultCurrency | `Currency.values.byName(response.defaultCurrency.toLowerCase())` |
