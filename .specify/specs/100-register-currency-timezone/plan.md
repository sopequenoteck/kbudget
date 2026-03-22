# Implementation Plan: Devise et fuseau horaire a l'inscription

**Branch**: `100-register-currency-timezone` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/100-register-currency-timezone/spec.md`

## Summary

Enrichir le flux d'inscription pour accepter une devise et un fuseau horaire optionnels. La devise est choisie par l'utilisateur via un selecteur dans le formulaire ; le timezone est detecte automatiquement par le client. Ces valeurs initialisent le compte par defaut et les preferences utilisateur des l'inscription. Nettoyage du selecteur devise fantome dans le profil Angular.

## Technical Context

**Language/Version**: Java 21 (backend), TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: Spring Boot 4.0.2, Angular 21, Flutter >= 3.27, flutter_riverpod, Freezed
**Storage**: PostgreSQL 15+ (tables existantes `users`, `accounts`, `user_preferences`)
**Testing**: JUnit 5 + Mockito (backend), Vitest (Angular), flutter_test (Flutter)
**Target Platform**: Web PWA + Mobile natif (iOS/Android)
**Project Type**: Monorepo web-service + PWA + mobile-app
**Performance Goals**: N/A (inscription = operation ponctuelle, pas de contrainte de debit)
**Constraints**: Retrocompatibilite obligatoire (clients non mis a jour)
**Scale/Scope**: 3 modules impactes (api, app, flutter), ~15 fichiers modifies

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Detail |
|----------|--------|--------|
| I. API-First | PASS | RegisterRequest enrichi cote backend d'abord, consomme par les frontends |
| II. Securite par defaut | PASS | `/auth/register` est deja route publique dans SecurityConfig. Validation Currency via enum, timezone via ZoneId.of(). Bean Validation sur RegisterRequest |
| III. Simplicite & YAGNI | PASS | Modification de 3 fichiers backend existants (RegisterRequest, AuthService, AccountService) + creation eager des preferences. Pas de nouveau pattern |
| IV. Mobile-First UX | PASS | Un seul champ ajoute au formulaire (selecteur devise). Timezone invisible. Inscription reste en < 60s |
| V. Testabilite | PASS | Tests unitaires AuthService (devise + timezone), tests integration AuthController, tests frontend (formulaire) |
| VI. Observabilite | PASS | Log existant dans AuthService.register() suffit. Log dans createDefaultAccount() deja present |
| VII. Self-Hosted Ready | PASS | Aucune dependance externe ajoutee. Intl API et DateTime natifs |

**Gate Result**: PASS - Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/100-register-currency-timezone/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── register-endpoint.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
api/
├── src/main/java/fr/kksdev/budget/api/
│   ├── dto/request/RegisterRequest.java          # +currency, +timezone
│   ├── service/AuthService.java                  # register() enrichi
│   ├── service/AccountService.java               # createDefaultAccount(user, currency)
│   └── service/PreferenceService.java            # createInitialPreference(user, currency, timezone)
└── src/test/java/fr/kksdev/budget/api/
    ├── service/AuthServiceTest.java              # nouveaux tests
    ├── service/AccountServiceTest.java           # test createDefaultAccount avec devise
    └── controller/AuthControllerTest.java        # test integration register

app/
└── src/app/
    ├── features/auth/auth.ts                     # registerForm + currency field
    ├── features/auth/auth.html                   # selecteur devise + timezone detection
    ├── features/settings/components/profile/
    │   ├── profile.ts                            # suppression currencyControl, ajout lien
    │   └── profile.html                          # remplacement selecteur par lien
    └── core/services/auth.ts                     # register() enrichi

flutter/
└── lib/src/
    ├── features/auth/presentation/register_screen.dart  # selecteur devise + timezone
    ├── features/auth/application/auth_notifier.dart      # register() enrichi
    ├── features/auth/data/auth_remote_data_source.dart   # payload enrichi
    └── data/remote/dtos/auth_dtos.dart                   # RegisterRequest +currency +timezone
```

**Structure Decision**: Modification de fichiers existants uniquement. Aucun nouveau fichier source cree (sauf potentiellement un methode dans PreferenceService). Pas de migration Flyway necessaire (les colonnes existent deja).

## Complexity Tracking

Aucune violation de constitution a justifier.

## Design Decisions

### D1: Validation de la devise

La devise est validee par le type enum `Currency` de Jackson. Si le client envoie une valeur inconnue (ex: "BTC"), la deserialisation echoue et Spring retourne automatiquement une erreur 400. Pas besoin de validation custom.

### D2: Validation du timezone

Contrairement a la devise, le timezone est un String libre. AuthService passe le timezone brut a `PreferenceService.createInitialPreference()` qui valide via `ZoneId.of(timezone)`. Si invalide, PreferenceService utilise le fallback "Europe/Paris" silencieusement (pas de rejet — le timezone est envoye automatiquement par le client, pas choisi par l'utilisateur).

### D3: Creation eager des preferences

Aujourd'hui `PreferenceService.getOrCreate()` cree les preferences a la premiere consultation (lazy). Pour cette feature, `AuthService.register()` appellera une nouvelle methode `createInitialPreference(user, currency, timezone)` qui cree les preferences immediatement. `getOrCreate()` reste comme fallback pour les utilisateurs existants qui n'ont pas encore de preferences.

### D4: Signature enrichie de createDefaultAccount

`AccountService.createDefaultAccount(User user)` devient `createDefaultAccount(User user, Currency currency)`. L'ancienne signature peut etre supprimee car elle n'est appelee que depuis `AuthService.register()`.

### D5: Profil Angular — suppression du selecteur fantome

Le selecteur "Devise par defaut" dans le profil appelle `PUT /users/me { defaultCurrency }` mais `UserUpdateRequest` n'a que `name`. Le champ est ignore cote backend. On le remplace par un lien navigant vers `/settings/currencies`.
