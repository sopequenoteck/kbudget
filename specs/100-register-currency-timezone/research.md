# Research: 100-register-currency-timezone

**Date**: 2026-03-21

## Aucune recherche necessaire

Cette feature modifie des patterns existants et bien etablis dans le codebase. Aucun NEEDS CLARIFICATION identifie dans le Technical Context.

## Decisions prises

### Validation timezone serveur

- **Decision**: Utiliser `java.time.ZoneId.of(timezone)` pour valider les identifiants IANA
- **Rationale**: Deja utilise dans `PreferenceService.update()` (ligne 88) et `NotificationScheduler`. Pattern prouve dans le codebase
- **Alternatives**: Valider contre une liste blanche hardcodee → rejete car limite inutilement et maintenance supplementaire

### Detection timezone client (Angular)

- **Decision**: `Intl.DateTimeFormat().resolvedOptions().timeZone`
- **Rationale**: API standard supportee par tous les navigateurs modernes (> 97% selon caniuse). Retourne un identifiant IANA (ex: "Africa/Lome")
- **Alternatives**: `moment-timezone` ou `luxon` → rejete car dependance externe inutile pour une seule operation

### Detection timezone client (Flutter)

- **Decision**: `DateTime.now().timeZoneName` pour obtenir l'abbreviation, convertir en identifiant IANA
- **Rationale**: API native Dart, pas de dependance supplementaire
- **Alternatives**: Package `flutter_timezone` → option de fallback si `DateTime.now().timeZoneName` ne retourne pas un identifiant IANA exploitable. A valider lors de l'implementation

### Strategie de retrocompatibilite

- **Decision**: Champs `currency` et `timezone` optionnels (nullable) dans RegisterRequest. Fallbacks: EUR et Europe/Paris
- **Rationale**: Jackson ignore les champs null automatiquement. Les clients non mis a jour envoient `{ email, password, name }` → les nouveaux champs sont null → fallback applique
- **Alternatives**: Versioning d'API (v2/register) → rejete car sur-ingenierie pour 2 champs optionnels
