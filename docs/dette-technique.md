# Dette technique

Dettes identifiees au fil du projet. A traiter par lot lors des phases de refactoring.

## Format

Chaque entree suit : description, impact, correction proposee, date d'identification.

---

### DT-001 — Deux formats d'erreur API coexistent

**Identifie** : 2026-03-30

**Description** : Le format standard (`{ timestamp, status, message }` via `GlobalExceptionHandler.errorBody()`) et le format JWT (`{ error, message }` via le record `ErrorResponse`) coexistent. Le frontend doit gerer deux structures differentes selon le code HTTP.

**Impact** : Contrat d'API incoherent. Chaque nouveau client doit connaitre l'exception au format.

**Correction proposee** : Unifier sur `{ error, message }` partout. Le status HTTP est deja dans la reponse, le timestamp est rarement exploite cote client. Migrer `GlobalExceptionHandler.errorBody()` vers `ErrorResponse` avec un champ `error` generique (ex: `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `INTERNAL_ERROR`).

**Fichiers concernes** : `GlobalExceptionHandler.java`, `ErrorResponse.java`, intercepteur Angular, api-errors.md
