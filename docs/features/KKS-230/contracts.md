# Contracts — KKS-230 Autocomplete libellé

**Date** : 2026-04-13
**Feature** : Autocomplete sur le champ libellé de saisie des transactions
**Plan** : [`plan.md`](plan.md)

## Résumé

| Type | Nombre |
|------|:------:|
| Endpoints API | 1 |
| Contrats services backend | 1 (1 méthode) |
| Contrats repositories backend | 1 (1 méthode) |
| Contrats composants Angular | 1 |
| Contrats services Angular | 1 (1 méthode) |
| Contrats repositories Flutter | 1 (1 méthode) |
| Contrats providers Riverpod | 1 |
| Contrats widgets Flutter | 1 |

Aucun DTO nouveau (réponse = `List<String>`).

---

## 1. API Endpoint — `GET /api/transactions/libelles`

**Couvre** : FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-013, FR-014, FR-017

### Requête

| Élément | Valeur |
|---------|--------|
| Méthode | `GET` |
| Path | `/api/transactions/libelles` |
| Auth | JWT obligatoire (`Authorization: Bearer <token>`) |
| Content-Type | — (pas de body) |

### Paramètres query

| Nom | Type | Obligatoire | Défaut | Contrainte | Description |
|-----|------|:-----------:|:------:|------------|-------------|
| `q` | `string` | Non | `null` | `max=255` | Filtre `contains` case-insensitive + accent-insensible |
| `limit` | `integer` | Non | `20` | `[1, 50]` (clampé) | Nombre max de libellés retournés |

### Réponse 200 OK

**Content-Type** : `application/json`
**Schema** : `List<String>` — libellés distincts triés par fréquence décroissante puis date de dernière utilisation décroissante.

Exemple :
```json
["Carrefour", "Café du coin", "Carte bleue"]
```

### Codes d'erreur

| Code | Condition | Body |
|------|-----------|------|
| `401 Unauthorized` | JWT absent, expiré ou invalide | Format erreur standard projet |
| `400 Bad Request` | `limit` non numérique (parsing Spring) | Format erreur standard |
| `500 Internal Server Error` | Extension `unaccent` absente, erreur DB | Format erreur standard |

### Observabilité

Log SLF4J niveau `INFO` à chaque appel (FR-013) :
```
GET /transactions/libelles user=<UUID> q=<q> limit=<limit>
```

### Documentation Swagger

`@Operation(summary = "Lister les libellés déjà utilisés (autocomplete)")` + `@Parameter` sur `q` et `limit`. Visible dans `/api/swagger-ui.html` (FR-014, SC-006).

---

## 2. Contrats Backend (Java/Spring)

### 2.1 `TransactionController` (modification)

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/controller/TransactionController.java`

```java
@Operation(summary = "Lister les libellés déjà utilisés (autocomplete)")
@GetMapping("/libelles")
public ResponseEntity<List<String>> getLibelleSuggestions(
        @RequestParam(required = false) @Size(max = 255) String q,
        @RequestParam(required = false, defaultValue = "20") Integer limit,
        Authentication authentication);
```

### 2.2 `TransactionService` (ajout méthode)

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java`

```java
/**
 * Retourne les libellés distincts de l'utilisateur, triés par fréquence
 * puis par date de dernière utilisation.
 *
 * @param userId utilisateur authentifié (isolation stricte — FR-005)
 * @param q      filtre contains case/accent-insensible (null = pas de filtre)
 * @param limit  clampé à [1, 50]
 */
List<String> getLibelleSuggestions(UUID userId, String q, Integer limit);
```

**Contrat comportemental** :
- `limit == null` → 20
- `limit < 1` → 1
- `limit > 50` → 50
- `q == null || q.isBlank()` → pas de filtre
- Jamais de jet d'exception métier — répond `[]` si aucun résultat
- Couvre FR-003, FR-004, FR-005, FR-017

### 2.3 `TransactionRepository` (ajout méthode)

**Fichier** : `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java`

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

**Invariants** :
- Filtre strict `user_id = :userId` (FR-005)
- Native query — dépend de l'extension PostgreSQL `unaccent`
- Retourne uniquement `libelle` (pas d'autres colonnes)

---

## 3. Contrats Frontend Angular

### 3.1 Composant `AutocompleteComponent` (nouveau, partagé)

**Couvre** : FR-007, FR-009, FR-010, FR-011, FR-012, FR-015, FR-016, FR-018, NFR-005

**Fichier** : `app/src/app/shared/components/autocomplete/autocomplete.ts`
**Selector** : `app-autocomplete`
**Standalone** : `true`
**Change detection** : `OnPush`

#### Inputs (signals)

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `value` | `model<string>` | `''` | Two-way binding de la valeur saisie |
| `suggestions` | `input<string[]>` | `[]` | Liste de suggestions fournies par le parent (après debounce + backend) |
| `minChars` | `input<number>` | `2` | Seuil minimal avant d'ouvrir la liste (FR-015) |
| `maxDisplay` | `input<number>` | `5` | Nombre max de suggestions affichées (FR-016) |
| `placeholder` | `input<string>` | `''` | Placeholder de l'input |
| `ariaLabel` | `input<string>` | `''` | Label d'accessibilité |
| `disabled` | `input<boolean>` | `false` | État désactivé |

#### Outputs

| Nom | Type | Condition d'émission |
|-----|------|----------------------|
| `selected` | `output<string>` | Utilisateur sélectionne une suggestion (clic ou Enter) |
| `queryChange` | `output<string>` | Émis après debounce 200ms si `value().length >= minChars()` |

#### Contrat comportemental

- Lorsque `value().length < minChars()` :
  - `isOpen = false`
  - Aucun `queryChange` émis (FR-015)
  - Aucun appel backend déclenché
- Debounce interne de 200ms via `Subject + debounceTime + distinctUntilChanged` (FR-011)
- Filtrage local additionnel case/accent-insensible avant affichage (FR-012) :
  - `normalize(s) = s.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '')`
  - `visibleSuggestions = suggestions.filter(s => normalize(s).includes(normalize(value))).slice(0, maxDisplay)`
- Navigation clavier (FR-010) :
  - `ArrowDown` → `activeIndex = (activeIndex + 1) % visibleSuggestions.length`, ouvre la liste
  - `ArrowUp` → décrémente avec wrap
  - `Enter` → sélectionne `activeIndex` s'il est ≥ 0, sinon laisse passer l'event (saisie libre)
  - `Escape` → `isOpen = false`, valeur inchangée (FR-009)
- Clic extérieur → fermeture de la liste
- Saisie libre toujours possible (FR-009) : aucune contrainte sur `value`
- ARIA (NFR-005) :
  - Input : `role="combobox"`, `aria-autocomplete="list"`, `aria-expanded`, `aria-controls`, `aria-activedescendant`
  - Liste : `role="listbox"`, options : `role="option"`, `id="option-{i}"`

#### Styles

- Utilisation exclusive des tokens CSS DESIGN.md (`var(--token-*)`)
- Réutilise les patterns `_list-patterns.scss` et éventuellement `_bottom-sheet.scss` pour le mobile
- Aucune valeur hex/rgba hardcodée (NFR-003)

### 3.2 Service `TransactionLibelleService` (nouveau)

**Couvre** : FR-007 (wire backend)

**Fichier** : `app/src/app/features/transactions/services/transaction-libelle.service.ts`

```typescript
@Injectable({ providedIn: 'root' })
export class TransactionLibelleService {
  private readonly http = inject(HttpClient);

  search(q: string, limit: number = 20): Observable<string[]>;
}
```

**Contrat** :
- `search('')` → appel `GET /api/transactions/libelles?limit=20` (pas de `q`)
- `search('ca', 10)` → `GET /api/transactions/libelles?q=ca&limit=10`
- Erreur HTTP → `of([])` (pas de blocage de l'UX — edge case "latence réseau")
- Ne gère pas le debounce (responsabilité du composant)

### 3.3 Intégration `TransactionFormComponent` (modification)

**Fichier** : `app/src/app/features/transactions/components/transaction-form/transaction-form.ts`

Contrat de non-régression (NFR-008) :
- Les champs autres que `libelle` restent strictement inchangés dans leur comportement
- Validation `Validators.required` sur `libelle` conservée
- Ajout :
  - `libelleSuggestions = signal<string[]>([])`
  - `onLibelleQuery(q: string)` : appelle `libelleService.search(q)` puis alimente `libelleSuggestions`
  - Template : remplace l'input libellé par `<app-autocomplete [(value)]="libelle" [suggestions]="libelleSuggestions()" (queryChange)="onLibelleQuery($event)" minChars="2" maxDisplay="5" />`

---

## 4. Contrats Frontend Flutter

### 4.1 `TransactionRepository` (interface, modification)

**Couvre** : FR-008

**Fichier** : `flutter/lib/src/features/transactions/domain/repositories/transaction_repository.dart`

```dart
abstract class TransactionRepository {
  // ... méthodes existantes ...

  /// Retourne les libellés distincts de l'utilisateur triés par fréquence
  /// puis par date de dernière utilisation.
  ///
  /// [query] filtre contains case/accent-insensible. Si < 2 caractères,
  /// implémentation libre (typiquement retourne []).
  /// [limit] clampé à [1, 50].
  Future<List<String>> getLibelleSuggestions(String query, {int limit = 20});
}
```

### 4.2 Implémentation remote (Dio)

**Fichier** : `flutter/lib/src/features/transactions/data/repositories/transaction_repository_remote.dart`

**Contrat** :
- Appelle `GET /api/transactions/libelles?q=<query>&limit=<limit>`
- `DioException` → `return <String>[]` (pas de propagation d'exception)
- Parse réponse en `List<String>`

### 4.3 Implémentation locale (Drift)

**Fichier** : `flutter/lib/src/features/transactions/data/repositories/transaction_repository_local.dart`

**Contrat** :
- Requête : `SELECT libelle FROM transactions WHERE user_id = ? GROUP BY libelle ORDER BY COUNT(*) DESC, MAX(date) DESC LIMIT ?`
- Filtre `q` appliqué en Dart sur le résultat (SQLite n'a pas `unaccent`) :
  - `_normalize(s) = s.toLowerCase().removeDiacritics()`
  - `results.where((l) => _normalize(l).contains(_normalize(query)))`
- Helper `removeDiacritics` : package `diacritic` si présent, sinon extension Dart maison basée sur une table ASCII

### 4.4 Provider Riverpod

**Couvre** : FR-008, FR-015

**Fichier** : `flutter/lib/src/features/transactions/application/libelle_suggestions_provider.dart`

```dart
final libelleSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return const [];
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getLibelleSuggestions(query, limit: 20);
});
```

**Contrat** :
- Garde `minChars=2` au niveau provider (FR-015)
- Délègue au repository actif (local ou remote selon `dataModeProvider`)
- Pas de cache inter-query : la `family` crée une entrée par query, auto-dispose via `ref.keepAlive` non activé

### 4.5 Widget `LibelleAutocompleteField` (nouveau)

**Couvre** : FR-008, FR-009, FR-011, FR-015, FR-016, NFR-002, NFR-004

**Fichier** : `flutter/lib/src/features/transactions/presentation/widgets/libelle_autocomplete_field.dart`

```dart
class LibelleAutocompleteField extends ConsumerStatefulWidget {
  const LibelleAutocompleteField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.validator,
    this.maxDisplay = 5,
    this.minChars = 2,
    this.debounce = const Duration(milliseconds: 200),
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final int maxDisplay;
  final int minChars;
  final Duration debounce;

  @override
  ConsumerState<LibelleAutocompleteField> createState() => _LibelleAutocompleteFieldState();
}
```

**Contrat comportemental** :
- Interne : `RawAutocomplete<String>` avec `optionsBuilder` async qui lit `libelleSuggestionsProvider(query)` et `take(maxDisplay)`
- Debounce 200ms via `Timer?` dans le state (FR-011)
- Aucune suggestion si `query.length < minChars` (FR-015)
- Saisie libre toujours possible (FR-009)
- `optionsViewBuilder` stylé avec tokens centralisés (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppShadows`) — NFR-004
- `fieldViewBuilder` : `TextFormField` cohérent avec les autres champs du formulaire (utilise `decoration` et `validator` fournis)
- `displayStringForOption` : identity (pas de transformation)

### 4.6 Intégration `TransactionForm` (modification)

**Fichier** : `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart`

- Remplace le `TextFormField` libellé par `LibelleAutocompleteField`
- Validation `required` conservée
- Aucune modification des autres champs (NFR-008)

---

## 5. Contrat de migration Flyway

**Fichier** : `api/src/main/resources/db/migration/V27__enable_unaccent_extension.sql` (numéro à ajuster)

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
```

**Invariants** :
- Idempotente
- Aucun `CREATE TABLE` / `ALTER TABLE` / `CREATE INDEX`
- Aucune donnée modifiée

---

## 6. Contrat de tests (résumé)

### Backend (JUnit)

| Test | FR/NFR couverts | Assertion clé |
|------|-----------------|---------------|
| `TransactionRepositoryTest.should_return_libelles_sorted_by_frequency` | FR-004 | Carrefour (x10) avant Monoprix (x2) |
| `TransactionRepositoryTest.should_order_by_last_date_when_count_equal` | FR-004 | Tie-break sur `MAX(date)` |
| `TransactionRepositoryTest.should_filter_contains_case_insensitive` | FR-017 | "market" matche "Carrefour Market" |
| `TransactionRepositoryTest.should_filter_accent_insensitive` | FR-017 | "cafe" matche "Café du coin" |
| `TransactionRepositoryTest.should_respect_limit_parameter` | FR-003 | Retourne exactement N lignes |
| `TransactionServiceTest.should_clamp_limit_between_1_and_50` | FR-003 | limit=-1 → 1, limit=100 → 50, null → 20 |
| `TransactionControllerTest.should_return_401_when_unauthenticated` | FR-006, SC-004 | 401 sans JWT |
| `TransactionControllerTest.should_isolate_libelles_by_user` | FR-005, SC-004 | User A ne voit pas les libellés de User B |
| `TransactionControllerTest.should_log_info_on_call` | FR-013 | Log capturé au niveau INFO |

### Angular (Jasmine)

| Test | FR couverts |
|------|-------------|
| `autocomplete.spec : should_not_emit_queryChange_below_minChars` | FR-015 |
| `autocomplete.spec : should_emit_queryChange_debounced_200ms` | FR-011 |
| `autocomplete.spec : should_filter_locally_accent_insensitive` | FR-012 |
| `autocomplete.spec : should_navigate_with_arrow_keys` | FR-010 |
| `autocomplete.spec : should_close_on_escape_without_changing_value` | FR-009, FR-010 |
| `autocomplete.spec : should_limit_display_to_maxDisplay` | FR-016 |
| `autocomplete.spec : should_expose_aria_attributes` | NFR-005 |
| `transaction-form.spec : should_allow_free_text_submission` | FR-009, SC-005 |

### Flutter (flutter_test)

| Test | FR couverts |
|------|-------------|
| `libelle_autocomplete_field_test : should_not_call_repository_below_2_chars` | FR-015 |
| `libelle_autocomplete_field_test : should_display_max_5_suggestions` | FR-016 |
| `libelle_autocomplete_field_test : should_fill_field_on_suggestion_selection` | FR-008 |
| `libelle_autocomplete_field_test : should_allow_novel_label_submission` | FR-009 |
| `libelle_autocomplete_field_test : should_debounce_queries` | FR-011 |

---

## 7. Ce qui n'est PAS contractualisé (hors scope)

- ❌ DTO wrapper `LabelSuggestionResponse` (YAGNI — réponse `List<String>` directe)
- ❌ Type `Merchant` / `Payee` / `LabelEntity`
- ❌ Interface spécifique de normalisation côté backend (inline dans la query)
- ❌ Hooks pour cross-user sharing (non supporté)
- ❌ Stratégie de cache backend (pas de cache — query rapide + index user_id)
