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

---

### DT-002 — Libelles transactions sans entite Merchant (KKS-230)

**Identifie** : 2026-04-13

**Description** : L'autocomplete libelle (KKS-230) exploite directement le champ `Transaction.libelle` via une agregation `GROUP BY libelle`. Aucune entite `Merchant`/`Payee` n'est creee (YAGNI, constitution #3). Les variantes orthographiques s'accumulent ("Carrefour", "carrefour market", "CARREFOUR").

**Impact** : Le jour ou une feature aval necessitera des stats par commercant (top merchants, depenses par enseigne, auto-categorisation), une migration sera necessaire sur des libelles potentiellement sales.

**Correction proposee** : Quand ce besoin apparaitra, prevoir :
1. Creer une entite `Merchant` liee a `Transaction` via `merchant_id` nullable.
2. Ecran de fusion manuelle des doublons.
3. Dedup automatique reutilisant la logique Jaro-Winkler deja disponible dans l'import CSV (KKS-099 — `api/src/main/java/fr/kksdev/budget/api/service/importcsv/`).
4. Job de backfill des transactions existantes.

**Fichiers concernes** (futurs) : nouvelle entite `Merchant`, `TransactionService`, migration Flyway de schema, ecran de fusion frontend.

**Dependance** : blocs sont interdependants — ne pas demarrer avant d'avoir un cas d'usage metier concret qui justifie la complexite.
