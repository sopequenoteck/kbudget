# Research: Tests unitaires services Phase 4

**Branch**: `017-phase4-unit-tests` | **Date**: 2026-02-12

## R1: Pattern de test services Angular 21

**Decision**: Utiliser TestBed avec `BrowserTestingModule` + `platformBrowserTesting()` et mock de ApiService via `vi.fn()`

**Rationale**: Pattern deja etabli dans `auth.spec.ts` (17 tests passants). Angular 21 deprecie `BrowserDynamicTestingModule`. Le mock de ApiService via `vi.fn()` est le pattern le plus simple pour isoler la couche HTTP.

**Alternatives considered**:
- HttpClientTestingModule : trop lourd pour tester des services qui delegent tout a ApiService. Inutile puisque ApiService est deja un wrapper.
- Direct instantiation sans TestBed : impossible car les services utilisent `inject()` pour obtenir ApiService.

## R2: Couverture des pipes

**Decision**: Exclure AmountPipe et RelativeDatePipe du scope — deja couverts.

**Rationale**: AmountPipe a 12 tests et RelativeDatePipe a 11 tests dans leurs fichiers `.spec.ts` respectifs. La couverture est complete (cas nominaux, edge cases, null/undefined).

**Alternatives considered**: Aucune — la couverture existante est suffisante.

## R3: Verification du signal refreshTrigger

**Decision**: Lire la valeur du signal avant et apres chaque operation de mutation pour verifier l'increment.

**Rationale**: Le signal est un `WritableSignal<number>` initialise a 0. Chaque mutation appelle `this.refreshTrigger.update(v => v + 1)` via `tap()` dans le pipe RxJS. On peut donc verifier que la valeur passe de N a N+1 apres souscription.

**Alternatives considered**:
- Spy sur la methode `refresh()` : methode privee, pas accessible en test. Lire le signal public est plus fiable et teste le comportement observable.

## R4: Parametres de filtre optionnels

**Decision**: Tester 3 cas pour chaque filtre optionnel : non fourni (undefined), true, false.

**Rationale**: Les services SubscriptionService et DebtService acceptent un parametre optionnel (`actif?`, `rembourse?`) qui conditionne l'ajout d'un query parameter a l'URL. Il faut verifier que l'URL est construite correctement dans les 3 cas.

**Alternatives considered**: Aucune — les 3 cas sont necessaires pour une couverture complete.

## R5: Methode getSummary avec query params

**Decision**: Tester sans parametres et avec parametres (month + year) pour verifier la construction de l'URL.

**Rationale**: `getSummary()` accepte `month?` et `year?` optionnels. L'URL resultante est `/transactions/summary` ou `/transactions/summary?month=X&year=Y`. Les deux cas doivent etre couverts.

**Alternatives considered**: Tester chaque parametre individuellement (month seul, year seul) — juge non necessaire car l'implementation les traite toujours ensemble.
