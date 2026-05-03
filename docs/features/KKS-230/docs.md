# Docs — KKS-230 Autocomplete sur le champ libellé de saisie des transactions

**Date de livraison** : 2026-04-14
**Linear** : [KKS-230](https://linear.app/kksdev/issue/KKS-230)
**Branche** : `feature/KKS-230-autocomplete-libelle-transactions`
**Version cible** : prochaine release (à incrémenter dans `VERSION` + `api/pom.xml` + `app/package.json`)

---

## Résumé

La saisie du libellé d'une transaction propose désormais des suggestions issues des transactions précédentes de l'utilisateur. L'objectif : réduire la friction de saisie, en particulier pour les commerces et dépenses récurrents. Le comportement est identique sur la PWA Angular et l'app Flutter. Aucune hygiène de données (pas d'entité `Merchant`, pas de fusion automatique) — seul le confort de saisie est amélioré.

---

## Guide utilisateur

### Comportement général

- **Seuil** : les suggestions apparaissent à partir de **2 caractères** saisis. Au focus seul, aucune liste, aucune requête.
- **Tri** : les libellés les plus fréquemment utilisés apparaissent en premier. En cas d'égalité, le plus récemment utilisé est priorisé.
- **Nombre** : jusqu'à **5 suggestions** affichées (le backend peut en retourner plus, l'UI tronque).
- **Filtrage** : insensible à la casse ET aux accents. Taper `cafe` propose `Café du coin`, taper `market` propose `Carrefour Market`.
- **Saisie libre** : toujours possible. Un libellé inédit est accepté sans contrainte, même si des suggestions sont affichées.
- **Isolation** : vous ne voyez jamais les libellés d'un autre utilisateur.

### Interactions Angular (PWA)

| Action | Effet |
|--------|-------|
| Clic sur une suggestion | Remplit le champ et ferme la liste |
| `↓` / `↑` (flèches) | Navigue dans la liste (wrap à la fin) |
| `Entrée` | Sélectionne la suggestion active |
| `Échap` | Ferme la liste sans modifier le champ |
| Clic en dehors | Ferme la liste |
| Saisie continue | Rafraîchit la liste après un léger délai (200 ms debounce) |

### Interactions Flutter

- Clic sur une suggestion → remplit le champ
- Saisie libre acceptée
- Debounce 200 ms identique
- L'overlay utilise les tokens visuels centralisés (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppShadows`)

### Accessibilité (Angular)

Le composant respecte les attributs ARIA pour lecteurs d'écran : `role="combobox"`, `aria-autocomplete="list"`, `aria-expanded`, `aria-controls`, `aria-activedescendant`. Les options portent `role="option"` et `aria-selected`.

---

## API Backend

### Endpoint

```
GET /api/transactions/libelles?q=<query>&limit=<n>
Authorization: Bearer <JWT>
```

| Paramètre | Type | Défaut | Contrainte | Description |
|-----------|------|:------:|------------|-------------|
| `q` | string | — | max 255 | Filtre `contains` case/accent-insensible. Omis ou vide → pas de filtre. |
| `limit` | int | 20 | clampé `[1, 50]` | Nombre maximum de libellés retournés. |

### Réponse

**200 OK** — `application/json`
```json
["Carrefour", "Carrefour Market", "Carte bleue"]
```

Liste des libellés distincts de l'utilisateur authentifié, triés par fréquence d'utilisation décroissante puis par date de dernière utilisation décroissante en cas d'égalité.

### Erreurs

| Code | Condition |
|------|-----------|
| `401 Unauthorized` | JWT absent, expiré ou invalide |
| `400 Bad Request` | Paramètres mal typés ou `q` > 255 caractères |
| `500 Internal Server Error` | Erreur DB ou extension `unaccent` indisponible |

### Swagger UI

L'endpoint est documenté dans `/api/swagger-ui.html` sous le tag **Transactions** avec descriptions enrichies (`@Parameter`) sur `q` et `limit`, et exemples d'usage.

### Exemple curl

```bash
TOKEN="<votre-jwt>"

# Tous les libellés par fréquence
curl -s "http://localhost:8080/api/transactions/libelles" \
  -H "Authorization: Bearer $TOKEN" | jq

# Filtre accent-insensible
curl -s "http://localhost:8080/api/transactions/libelles?q=cafe" \
  -H "Authorization: Bearer $TOKEN" | jq

# Limite
curl -s "http://localhost:8080/api/transactions/libelles?q=car&limit=5" \
  -H "Authorization: Bearer $TOKEN" | jq
```

Exemples complets dans [`docs/api-examples.md`](../../api-examples.md).

---

## Changements techniques

### Backend Spring Boot (`api/`)

**Fichiers créés**
- `api/src/main/resources/db/migration/V27__enable_unaccent_extension.sql` — active l'extension PostgreSQL `unaccent` (idempotent)
- `api/src/test/java/fr/kksdev/budget/api/H2UnaccentFunction.java` — UDF Java simulant `UNACCENT` pour les tests H2 (via `java.text.Normalizer`)
- `api/src/test/resources/h2-unaccent.sql` — script `CREATE ALIAS` chargé par `@Sql` dans les tests repository

**Fichiers modifiés**
- `api/src/main/java/fr/kksdev/budget/api/controller/TransactionController.java` — nouvel endpoint `GET /libelles`, `@Validated` + `@Size` + `@Parameter` SpringDoc
- `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java` — méthode `getLibelleSuggestions(userId, q, limit)` avec clamp
- `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java` — native query `findLibelleSuggestions` avec `GROUP BY libelle ORDER BY COUNT(*) DESC, MAX(date) DESC` et filtre `LOWER(UNACCENT(...))`

**Dépendances** : aucune nouvelle. L'extension PostgreSQL `unaccent` fait partie de `postgresql-contrib` standard (disponible sur RDS, Supabase, Neon, Postgres self-hosted).

### Frontend Angular (`app/`)

**Fichiers créés**
- `app/src/app/shared/components/autocomplete/autocomplete.ts` — composant partagé `AutocompleteComponent`, standalone, OnPush, signals-first, `ViewEncapsulation.None`
- `app/src/app/shared/components/autocomplete/autocomplete.html`
- `app/src/app/shared/components/autocomplete/autocomplete.scss` — input structurellement neutre (styles portés par le contexte parent)
- `app/src/app/shared/components/autocomplete/autocomplete.spec.ts` — 23 tests unitaires (debounce, clavier, ARIA, filtrage, escape, troncature)
- `app/src/app/features/transactions/services/transaction-libelle.service.ts` — wrapper HTTP avec gestion d'erreur gracieuse (`of([])`)
- `app/src/app/features/transactions/services/transaction-libelle.service.spec.ts`

**Fichiers modifiés**
- `app/src/app/features/transactions/components/transaction-form/transaction-form.{ts,html,spec.ts}` — intégration `<app-autocomplete>` avec wiring `[value]/(valueChange)` + `patchValue`, `takeUntilDestroyed` sur la subscription
- `app/src/styles/_bottom-sheet.scss` — `.bsheet__libelle` split en container (flex/min-width) + styles visuels via sélecteur descendant pour fonctionner avec `<app-autocomplete>` ou un input direct

**Dépendances** : aucune (pas d'`@angular/material`, composant maison).

**API du composant `<app-autocomplete>`** :
```typescript
// Inputs
value = model<string>('')              // two-way binding
suggestions = input<string[]>([])
minChars = input<number>(2)
maxDisplay = input<number>(5)
placeholder = input<string>('')
ariaLabel = input<string>('')
disabled = input<boolean>(false)

// Outputs
selected = output<string>()            // sur clic/Enter
queryChange = output<string>()         // debounced 200ms après ≥ minChars
```

### Frontend Flutter (`flutter/`)

**Fichiers créés**
- `flutter/lib/src/features/transactions/application/libelle_suggestions_provider.dart` — `FutureProvider.family<List<String>, String>` avec garde `query.length < 2`
- `flutter/lib/src/features/transactions/presentation/widgets/libelle_autocomplete_field.dart` — `ConsumerStatefulWidget` basé sur `RawAutocomplete<String>`, debounce 200 ms, listener controller dans `initState`/`dispose`
- `flutter/test/src/features/transactions/libelle_autocomplete_field_test.dart` — 7 widget tests

**Fichiers modifiés**
- `flutter/lib/src/domain/repositories/transaction_repository.dart` — méthode abstraite `getLibelleSuggestions`
- `flutter/lib/src/data/remote/data_sources/transaction_remote_data_source.dart` — appel Dio `GET /transactions/libelles`
- `flutter/lib/src/data/local/daos/transaction_dao.dart` — requête Drift `customSelect` avec agrégation
- `flutter/lib/src/features/transactions/data/transaction_repository_remote.dart` — implémentation remote avec catch `DioException` → `[]`
- `flutter/lib/src/features/transactions/data/transaction_repository_local.dart` — implémentation Drift + filtrage accent-insensible en Dart via `diacritic`
- `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — intégration `LibelleAutocompleteField`
- `flutter/pubspec.yaml` — ajout `diacritic: ^0.1.6`

### Data model

**Aucune nouvelle entité, aucune nouvelle colonne, aucun nouvel index.** La feature exploite la table `transactions` existante via agrégation `GROUP BY libelle` sur `Transaction.libelle` (varchar 255, non-nullable). Seule évolution schéma : activation de l'extension `unaccent`.

---

## Configuration

### Backend

Aucune variable d'environnement nouvelle. La migration Flyway `V27` s'applique automatiquement au démarrage. Vérification post-déploiement :

```sql
SELECT extname FROM pg_extension WHERE extname = 'unaccent';
-- → doit retourner 1 ligne
```

### Angular

Aucune configuration. Le composant `<app-autocomplete>` est réutilisable dans d'autres formulaires via l'import standalone :

```typescript
import { Autocomplete } from 'shared/components/autocomplete/autocomplete';
// puis dans @Component imports: [Autocomplete, ...]
```

### Flutter

Aucune configuration. Le package `diacritic: ^0.1.6` est ajouté à `pubspec.yaml` — `flutter pub get` au premier build.

---

## Tests et validation

### Backend (`mvn test`)

**40 tests verts**, BUILD SUCCESS.

| Test | Couvre |
|------|--------|
| `should_return_401_when_unauthenticated` | JWT obligatoire (FR-006) |
| `should_isolate_libelles_by_user` | Isolation cross-user (FR-005, SC-004) |
| `should_return_distinct_libelles_for_user` | Distinct GROUP BY (FR-001) |
| `should_order_by_frequency_desc` | Tri fréquence (FR-004) |
| `should_tiebreak_by_last_date_desc` | Tie-break date (FR-004) |
| `should_filter_contains_case_insensitive` | Filtre contains (FR-017) |
| `should_filter_accent_insensitive` | UNACCENT (FR-017) |
| `should_clamp_limit_between_1_and_50` | Clamp limit (FR-003) |
| `should_respond_under_100ms_on_10k_transactions` | Perf NFR-001 |

### Angular (`ng lint` + `ng test`)

- Lint clean
- 23 tests `autocomplete.spec.ts` (debounce fakeTimers, navigation clavier wrap, filtrage accent/case, troncature, ARIA, escape, saisie libre)
- 3 tests `transaction-libelle.service.spec.ts` (GET avec params, erreur → [], pas de `q` si vide)

### Flutter (`flutter analyze` + `flutter test`)

- Analyze clean
- 7 widget tests `libelle_autocomplete_field_test.dart` (seuil 2 chars, suggestions via provider, sélection, debounce 200 ms, troncature 5, accent-insensible, saisie libre)

### Validation manuelle

Voir [`quickstart.md`](quickstart.md) pour le script complet :
1. Connexion → formulaire transaction → taper 2+ caractères
2. Vérifier suggestions triées par fréquence
3. Tester ↑↓, Enter, Escape, clic
4. Tester libellé inédit → soumission OK
5. Tester utilisateur secondaire → isolation
6. Swagger UI : `/api/swagger-ui.html` → `GET /transactions/libelles` documenté

### Dette technique introduite

Deux entrées dans [`docs/dette-technique.md`](../../dette-technique.md) :

- **DT-002** — Absence d'entité `Merchant`. Quand des stats par commerçant seront nécessaires, prévoir entité + écran de fusion + dédup Jaro-Winkler (réutiliser KKS-099).
- **DT-003** — `AutocompleteComponent` sans `ControlValueAccessor`. Pour l'instant, l'intégration dans un `ReactiveForm` se fait via wiring manuel `[value]/(valueChange)` + `patchValue`, et l'état visuel `ng-invalid.ng-touched` n'est pas propagé automatiquement (validation logique intacte). Correction future : implémenter CVA pour permettre `formControlName`.

---

## Critères de succès validés

| # | Critère | Validation |
|---|---------|------------|
| SC-001 | Complétion d'un libellé en 2-3 interactions | ✅ Tests clavier + clic |
| SC-002 | Refresh < 300 ms (debounce + backend + filtre client) | ✅ Debounce 200 ms + query < 100 ms |
| SC-003 | Backend < 100 ms sur 10 000 transactions | ✅ Test `should_respond_under_100ms_on_10k_transactions` |
| SC-004 | 0 fuite cross-user | ✅ Test d'intégration avec 2 users |
| SC-005 | Libellé inédit accepté 100% | ✅ Tests saisie libre Angular + Flutter |
| SC-006 | Endpoint visible dans Swagger UI | ✅ `@Operation` + `@Parameter` SpringDoc |
| SC-007 | Pas de `CREATE TABLE` / `ALTER TABLE` | ✅ Seule migration V27 = `CREATE EXTENSION IF NOT EXISTS unaccent` |

---

## Liens

- [`spec.md`](spec.md) — spécification fonctionnelle
- [`plan.md`](plan.md) — plan d'implémentation
- [`research.md`](research.md) — décisions techniques (R1..R8)
- [`contracts.md`](contracts.md) — contrats interfaces/API
- [`data-model.md`](data-model.md) — modèle de données
- [`tasks.md`](tasks.md) — liste des 49 tâches et statut
- [`quickstart.md`](quickstart.md) — guide de validation manuelle
- [`review-log.md`](review-log.md) — historique des reviews
- [Swagger UI](http://localhost:8080/api/swagger-ui.html) — documentation API live
