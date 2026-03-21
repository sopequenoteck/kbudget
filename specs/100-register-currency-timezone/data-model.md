# Data Model: 100-register-currency-timezone

**Date**: 2026-03-21

## Entities modifiees

### RegisterRequest (DTO)

Enrichissement du record existant avec 2 champs optionnels.

| Champ | Type | Obligatoire | Validation | Defaut |
|-------|------|-------------|------------|--------|
| email | String | oui | @NotBlank @Email | - |
| password | String | oui | @NotBlank @Size(min=6) | - |
| name | String | non | @Size(max=100) | null |
| **currency** | Currency (enum) | **non** | Enum valide (Jackson deserialisation) | null → EUR |
| **timezone** | String | **non** | ZoneId.of() dans le service | null → "Europe/Paris" |

### Account (entite existante)

Pas de modification du schema. Le champ `currency` (Currency, default EUR) est deja present. La modification est dans le code de creation : `createDefaultAccount(user, currency)` utilise la devise fournie au lieu du defaut EUR hardcode.

### UserPreference (entite existante)

Pas de modification du schema. Les champs `currencies` (List\<Currency\>, default [EUR]) et `timezone` (String, default "Europe/Paris") existent deja. La modification est dans le timing de creation : eager (a l'inscription) au lieu de lazy (a la premiere consultation).

## Pas de migration Flyway

Aucune modification de schema de base de donnees. Toutes les colonnes necessaires existent deja :
- `accounts.currency` (ajoute en Flyway V19)
- `user_preferences.currencies` (ajoute en Flyway V14)
- `user_preferences.timezone` (ajoute en Flyway V14)

## Flux de donnees

```
Client (Angular/Flutter)
  │
  │ POST /api/auth/register
  │ { email, password, name, currency?: "XOF", timezone?: "Africa/Lome" }
  │
  ▼
AuthService.register()
  │
  ├─→ userRepository.save(user)
  ├─→ categoryService.seedSystemCategories(user)
  ├─→ accountService.createDefaultAccount(user, currency ?? EUR)
  │     └─→ Account { currency: XOF, ... }
  └─→ preferenceService.createInitialPreference(user, currency ?? EUR, timezone ?? "Europe/Paris")
        └─→ UserPreference { currencies: [XOF], timezone: "Africa/Lome", ... }
```
