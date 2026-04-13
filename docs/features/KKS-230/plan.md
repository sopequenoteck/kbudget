# Implementation Plan: Autocomplete sur le champ libellé de saisie des transactions

**Branch** : `feature/KKS-230-autocomplete-libelle-transactions`
**Date** : 2026-04-13
**Spec** : [`spec.md`](spec.md)
**Research** : [`research.md`](research.md)
**Linear** : [KKS-230](https://linear.app/kksdev/issue/KKS-230)

## Summary

Ajouter un endpoint `GET /api/transactions/libelles` retournant les libellés distincts de l'utilisateur authentifié, triés par fréquence puis date de dernière utilisation, avec filtre `q` `contains` case-insensitive et accent-insensible via `unaccent`. Intégration dans les formulaires de saisie Angular et Flutter avec un composant autocomplete maison (signals-first côté Angular, `RawAutocomplete` côté Flutter). Aucune entité nouvelle, seule migration : activation extension PostgreSQL `unaccent`.

## Technical Context

**Backend** : Java 21 + Spring Boot 3.x, Spring Security (JWT), Spring Data JPA, Flyway, PostgreSQL, Lombok, SpringDoc OpenAPI, JUnit 5.
**Frontend Angular** : Angular 18+ standalone, signals-first (`signal`, `computed`, `effect`, `input`, `output`, `model`), RxJS limité HTTP, SCSS tokens DESIGN.md, Jasmine/Karma.
**Frontend Flutter** : Dart, Riverpod (Notifier/Provider), Freezed, Drift (offline), Dio (remote), go_router, flutter_test.
**Storage** : PostgreSQL (extension `unaccent` à activer).
**Target** : Web (PWA) + Android/iOS (Flutter) + self-hosted backend.
**Performance** : `GET /api/transactions/libelles` < 100ms sur 10 000 transactions / user (NFR-001).
**Scale** : ~16 comptes actifs, < 1000 libellés distincts par user (A1).

## Constitution Check

| # | Principe | Vérification | Statut |
|---|----------|--------------|--------|
| 1 | **API-First** | Nouveau endpoint `GET /api/transactions/libelles` exposé en premier, DTO réponse = `List<String>` (pas d'entité JPA), implémentation backend avant fronts | ✅ PASS |
| 2 | **Sécurité par défaut** | JWT obligatoire (route non publique dans `SecurityConfig`), filtre strict par `userId` via `Authentication` (pattern existant), tests 401 et cross-user | ✅ PASS |
| 3 | **Simplicité & YAGNI** | Controller → Service → Repository standard, aucune entité nouvelle, aucun DTO wrapper, native query unique | ✅ PASS |
| 4 | **Mobile-First UX** | Composant Angular mobile-friendly (zones tactiles, overlay/bottom-sheet), Flutter `RawAutocomplete` au pouce, 5 suggestions max lisibles | ✅ PASS |
| 5 | **Testabilité** | Tests intégration endpoint (filtre user, tri, q, limit, 401), tests unitaires service, tests front (selection, clavier, debounce) | ✅ PASS |
| 6 | **Observabilité** | Log SLF4J INFO dans controller à chaque appel (FR-013) | ✅ PASS |
| 7 | **Self-Hosted Ready** | `unaccent` fait partie de `postgresql-contrib`, pas de nouveau service, migration Flyway idempotente | ✅ PASS |

**Résultat** : ✅ Aucune dérogation. Pas de Complexity Tracking nécessaire.

## Project Structure

### Documentation (cette feature)

```text
docs/features/KKS-230/
├── spec.md          # Phase specify
├── clarify-log.md   # Phase clarify
├── review-log.md    # Phase review-spec
├── research.md      # Phase research (décisions techniques)
├── plan.md          # CE FICHIER
├── data-model.md    # Modèle (réutilise Transaction existante, pas de nouvelle entité)
├── quickstart.md    # Guide de démarrage feature
└── tasks.md         # /devflow.tasks (ultérieur)
```

### Source Code (impact)

```text
api/src/main/java/fr/kksdev/budget/api/
├── controller/TransactionController.java         (M) +GET /libelles
├── service/TransactionService.java               (M) +getLibelleSuggestions(userId, q, limit)
├── repository/TransactionRepository.java         (M) +findLibelleSuggestions(...)
└── dto/request/                                  (—) pas de nouveau DTO
api/src/main/resources/db/migration/
└── V27__enable_unaccent_extension.sql            (C) CREATE EXTENSION IF NOT EXISTS unaccent;
api/src/test/java/fr/kksdev/budget/api/
├── controller/TransactionControllerTest.java     (M) +tests endpoint libelles
├── service/TransactionServiceTest.java           (M) +tests unitaires service
└── repository/TransactionRepositoryTest.java     (M) +tests tri/filtre/unaccent

app/src/app/
├── shared/components/autocomplete/
│   ├── autocomplete.ts                           (C) composant standalone signals
│   ├── autocomplete.scss                         (C) tokens DESIGN.md
│   ├── autocomplete.html                         (C) template
│   └── autocomplete.spec.ts                      (C) tests unitaires
├── features/transactions/
│   ├── services/transaction-libelle.service.ts   (C) HTTP + debounce + signal
│   └── components/transaction-form/
│       ├── transaction-form.ts                   (M) intégration autocomplete
│       ├── transaction-form.html                 (M) champ libellé → <app-autocomplete>
│       └── transaction-form.spec.ts              (M) +tests intégration

flutter/lib/src/features/transactions/
├── domain/repositories/transaction_repository.dart       (M) +getLibelleSuggestions(query, limit)
├── data/repositories/transaction_repository_remote.dart  (M) +impl Dio
├── data/repositories/transaction_repository_local.dart   (M) +impl Drift + normalisation Dart
├── application/libelle_suggestions_provider.dart         (C) Riverpod FutureProvider.family
└── presentation/widgets/
    ├── libelle_autocomplete_field.dart                   (C) RawAutocomplete wrapper stylé
    └── transaction_form.dart                             (M) intégration widget
flutter/test/src/features/transactions/
└── libelle_autocomplete_field_test.dart                  (C) widget test
```

**Structure Decision** : Option « Mobile + API + PWA » — trois cibles déjà en place dans le monorepo (`api/`, `app/`, `flutter/`). La feature touche les trois en parallèle, backend en premier (API-First).

---

## Approche par composant

### Backend (FR-001..FR-006, FR-013, FR-014, FR-017)

**Controller** (`TransactionController.java`) — nouveau endpoint :

```java
@Operation(summary = "Lister les libellés déjà utilisés (autocomplete)")
@GetMapping("/libelles")
public ResponseEntity<List<String>> getLibelleSuggestions(
        @RequestParam(required = false) String q,
        @RequestParam(required = false, defaultValue = "20") Integer limit,
        Authentication authentication) {
    UUID userId = (UUID) authentication.getPrincipal();
    log.info("GET /transactions/libelles user={} q={} limit={}", userId, q, limit);
    return ResponseEntity.ok(transactionService.getLibelleSuggestions(userId, q, limit));
}
```

- Path `/libelles` (voir R1 research — cohérence vocabulaire `libelle`).
- `@Operation` SpringDoc → visible Swagger (FR-014, SC-006).
- Log INFO obligatoire (FR-013, constitution #6).

**Service** (`TransactionService.java`) :

```java
public List<String> getLibelleSuggestions(UUID userId, String q, Integer limit) {
    int safeLimit = Math.min(Math.max(limit == null ? 20 : limit, 1), 50);
    return transactionRepository.findLibelleSuggestions(userId, q, safeLimit);
}
```

- Clamp `limit` ∈ [1, 50] (FR-003).
- Aucune transformation sur la donnée.

**Repository** (`TransactionRepository.java`) :

```java
@Query(value = """
    SELECT t.libelle
    FROM transactions t
    WHERE t.user_id = :userId
      AND (:q IS NULL OR LOWER(UNACCENT(t.libelle)) LIKE '%' || LOWER(UNACCENT(CAST(:q AS TEXT))) || '%')
    GROUP BY t.libelle
    ORDER BY COUNT(*) DESC, MAX(t.date) DESC
    LIMIT :limit
    """, nativeQuery = true)
List<String> findLibelleSuggestions(
    @Param("userId") UUID userId,
    @Param("q") String q,
    @Param("limit") int limit);
```

- Native query (JPQL ne supporte pas `UNACCENT`) — voir R2 research.
- Couvre FR-004 (tri fréquence + date), FR-017 (contains + accent-insensible).

**Migration Flyway** (`V27__enable_unaccent_extension.sql`) :

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
```

Numéro V27 à ajuster selon le prochain disponible au moment de l'implémentation (voir R3 research).

**Sécurité** (`SecurityConfig`) : aucune modification — la route hérite du `/api/**` déjà protégé JWT. Vérifier en test qu'elle renvoie bien 401 sans token (FR-006).

**Tests backend** :
- `TransactionRepositoryTest` : seed de données, assertions sur tri fréquence, tri date en cas d'égalité, filtre `q` contains + accents.
- `TransactionServiceTest` : clamp limit (0, négatif, > 50, null).
- `TransactionControllerTest` : 401 sans JWT, isolation cross-user (user A ne voit pas libellés user B — SC-004), réponse `List<String>` avec JSON attendu, Swagger.

### Frontend Angular (FR-007, FR-009, FR-010, FR-011, FR-012, FR-015, FR-016, FR-018)

**Composant partagé** `shared/components/autocomplete/autocomplete.ts` :

- `@Component({ selector: 'app-autocomplete', standalone: true, changeDetection: OnPush })`
- Signals API :
  - `value = model<string>('')` (two-way binding avec le formulaire parent)
  - `suggestions = input<string[]>([])`
  - `minChars = input<number>(2)` (FR-015)
  - `maxDisplay = input<number>(5)` (FR-016)
  - `placeholder = input<string>('')`
  - `selected = output<string>()`
  - `queryChange = output<string>()` (émis debouncé)
- États internes :
  - `isOpen = signal(false)`
  - `activeIndex = signal(-1)`
  - `visibleSuggestions = computed(() => suggestions().slice(0, maxDisplay()))`
- Debounce (FR-011) : `Subject<string>` → `debounceTime(200)` → `distinctUntilChanged()` → emit `queryChange`. Uniquement si `value().length >= minChars()` (sinon `isOpen=false`, aucun emit).
- Filtrage local additionnel (FR-012) : avant affichage, fonction `normalize(str) = str.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '')`, puis `includes`.
- Navigation clavier (FR-010) :
  - `keydown.arrowDown` → `activeIndex = (activeIndex + 1) % visibleSuggestions().length`, ouvre la liste
  - `keydown.arrowUp` → index - 1 avec wrap
  - `keydown.enter` → `selectAt(activeIndex)` ou laisser valider le form si aucune sélection active
  - `keydown.escape` → `isOpen = false` (FR-009 : ne modifie pas la valeur)
- Click outside via `@HostListener('document:click', ['$event'])` + test `contains`.
- ARIA (NFR-005) : `role="combobox"` sur input, `aria-autocomplete="list"`, `aria-expanded`, `aria-controls`, listbox `role="listbox"` + options `role="option"` + `aria-activedescendant`.
- Style : SCSS importe les tokens DESIGN.md, patterns `_list-patterns.scss` et `_bottom-sheet.scss` si applicables pour mobile.

**Service** `features/transactions/services/transaction-libelle.service.ts` :

- `inject(HttpClient)`
- Méthode `search(q: string, limit = 20): Observable<string[]>` → `GET /api/transactions/libelles?q=...&limit=...`
- Gestion gracieuse : erreur réseau → `of([])` (pas de blocage — edge case "latence").

**Intégration** dans `transaction-form.ts`/`.html` :

- Remplace l'input libellé par `<app-autocomplete>` + `[(value)]="libelle"` + `(queryChange)="onQueryChange($event)"` + `[suggestions]="suggestions()"` où `suggestions` est un `signal` alimenté par `toSignal(service.search(q))`.
- Formulaire existant reste inchangé sur les autres champs (NFR-008).
- Validation `Validators.required` conservée sur `libelle`.

**Tests Angular** (NFR-007) :
- `autocomplete.spec.ts` : selection clavier, selection clic, debounce (fakeAsync + tick), seuil 2 caractères, filtrage accent-insensible, fermeture escape, ARIA.
- `transaction-form.spec.ts` : intégration, saisie inédite validable (FR-009).

### Frontend Flutter (FR-008, FR-009, FR-010 clic, FR-011, FR-012, FR-015, FR-016)

**Repository abstrait** (`domain/repositories/transaction_repository.dart`) :

```dart
Future<List<String>> getLibelleSuggestions(String query, {int limit = 20});
```

**Implémentation remote** (Dio) : `GET /api/transactions/libelles?q=...&limit=...` → `List<String>`. En cas d'erreur → `[]`.

**Implémentation local** (Drift) :
```sql
SELECT libelle FROM transactions
WHERE user_id = ?
GROUP BY libelle
ORDER BY COUNT(*) DESC, MAX(date) DESC
LIMIT ?
```
Filtre `q` accent-insensible appliqué en Dart sur les résultats (SQLite n'a pas `unaccent`) : `libelle.toLowerCase().removeDiacritics().contains(query.toLowerCase().removeDiacritics())`. Si `diacritic` package pas encore présent, implémenter un `String extension` manuel minimal basé sur `Characters` + map ASCII — à confirmer en tasks.

**Provider Riverpod** (`application/libelle_suggestions_provider.dart`) :

```dart
final libelleSuggestionsProvider = FutureProvider.family<List<String>, String>(
  (ref, query) async {
    if (query.length < 2) return [];
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getLibelleSuggestions(query, limit: 20);
  },
);
```

**Widget** `libelle_autocomplete_field.dart` :

- `ConsumerStatefulWidget` avec `TextEditingController` + `Timer` (debounce 200ms).
- `RawAutocomplete<String>` :
  - `textEditingController` / `focusNode` passés
  - `optionsBuilder` : retourne `ref.read(libelleSuggestionsProvider(query).future)` en take(5)
  - `optionsViewBuilder` : `Material` custom avec `AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppShadows` (NFR-004)
  - `fieldViewBuilder` : `TextFormField` stylé comme les autres champs du formulaire
  - `displayStringForOption` : identity
- Saisie libre (FR-009) : `RawAutocomplete` laisse la main au controller — rien à bloquer.

**Tests Flutter** (NFR-007) :
- Widget test : `ProviderScope` + override repository avec fake, assert suggestions affichées après 2 caractères, sélection met à jour le champ, saisie inédite acceptée.

### Documentation (FR-014 + spec)

- `docs/api-examples.md` : exemple requête/réponse `GET /api/transactions/libelles?q=car&limit=20` → `["Carrefour", "Carte bleue"]`.
- `docs/dette-technique.md` : note sur migration future entité `Merchant` (référence KKS-099 dédup Jaro-Winkler).
- `docs/features/KKS-230/quickstart.md` : guide manuel pour valider la feature (voir fichier dédié).
- `DESIGN.md` : documenter le pattern `autocomplete` s'il n'y est pas déjà (à vérifier en implémentation).

---

## Risques & mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|:-----------:|:------:|------------|
| Extension `unaccent` non activable sur Postgres managé self-hosted | Faible | Bloquant | Vérifier en amont sur l'environnement cible ; `IF NOT EXISTS` idempotent ; fallback documenté = filtre `LOWER()` seul sans accent-insensibilité (régression UX mineure) |
| NFR-001 (< 100ms) non tenu à 10k transactions | Faible | Moyen | Index existant `(user_id)` ; plan de contingence R4 research (index composite `(user_id, libelle)` puis GIN `pg_trgm`) |
| Conflit numéro migration V27 | Faible | Bloquant | Vérifier `ls db/migration` juste avant création, prendre le prochain disponible |
| Package `diacritic` absent côté Flutter | Moyenne | Mineur | Fallback normalisation manuelle Dart (table ASCII 128 bornée) ; sinon ajout dépendance à valider avec user (constitution #7) |
| Formulaire Angular existant incompatible avec overlay (z-index, overflow hidden) | Faible | Moyen | Tester tôt sur le formulaire réel ; fallback bottom-sheet mobile |
| Fuite cross-user (SC-004) | Très faible | Critique | Test d'intégration explicite avec 2 users + assertions croisées ; code review focus `userId` dans la query |

## Hors scope (rappel)

- ❌ Entité `Merchant`/`Payee`
- ❌ Normalisation/fusion des libellés stockés
- ❌ Stats, auto-catégorisation, cross-user, recherche plein texte
- ❌ Synchronisation offline-first des suggestions Flutter (le MVP utilise remote + fallback local Drift si dataModeProvider=local)

## Artefacts complémentaires

| Fichier | Rôle |
|---------|------|
| [`research.md`](research.md) | Décisions techniques R1..R8 (naming, requête SQL, index, composants) |
| [`data-model.md`](data-model.md) | Modèle (réutilise `Transaction` existante, aucune nouvelle entité) |
| [`quickstart.md`](quickstart.md) | Guide manuel de validation de la feature |
| `contracts/` | Généré en `/devflow.contracts` (OpenAPI extract pour `GET /libelles`) |

## Complexity Tracking

*Aucune dérogation constitutionnelle → section non applicable.*
