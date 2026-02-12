# Implementation Plan: Tests unitaires services Phase 4

**Branch**: `017-phase4-unit-tests` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/017-phase4-unit-tests/spec.md`

## Summary

Ecrire les tests unitaires pour les 3 services CRUD de la Phase 4 : TransactionService, SubscriptionService et DebtService. Les tests utilisent Vitest avec le pattern TestBed Angular 21 etabli dans auth.spec.ts. ApiService est mocke via `vi.fn()`. Chaque test verifie l'appel correct a l'endpoint et l'increment du signal `refreshTrigger` pour les mutations. Les pipes (AmountPipe, RelativeDatePipe) sont exclus car deja couverts.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/core/testing`, `@angular/platform-browser/testing`, Vitest 4.x, RxJS
**Storage**: N/A (tests uniquement, pas de persistance)
**Testing**: Vitest 4.x via `npx vitest run`, config `app/vitest.config.ts` avec `@analogjs/vite-plugin-angular`
**Target Platform**: Node.js (jsdom environment pour tests)
**Project Type**: Web application (frontend Angular)
**Performance Goals**: N/A (tests unitaires)
**Constraints**: Tests < 10s pour la suite complete, nommage `should_[resultat]_when_[condition]`
**Scale/Scope**: 3 fichiers de test, 24 tests au total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature de test uniquement, pas de nouvel endpoint |
| II. Securite par defaut | N/A | Pas de modification de securite |
| III. Simplicite & YAGNI | PASS | Tests simples, pas d'abstraction de test framework. Mock direct de ApiService |
| IV. Mobile-First UX | N/A | Pas de modification UI |
| V. Testabilite | PASS | Nommage `should_X_when_Y`, pattern AAA, couverture des cas limites, mocks pour isolation |
| VI. Observabilite | N/A | Pas de modification de logging |
| VII. Self-Hosted Ready | N/A | Pas de dependance infra |

**Pre-research gate**: PASS (aucune violation)
**Post-design gate**: PASS (aucune violation)

## Project Structure

### Documentation (this feature)

```text
specs/017-phase4-unit-tests/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/core/services/
├── transaction.ts           # Service existant
├── transaction.spec.ts      # A CREER
├── subscription.ts          # Service existant
├── subscription.spec.ts     # A CREER
├── debt.ts                  # Service existant
├── debt.spec.ts             # A CREER
├── api.ts                   # Dependance mockee
├── auth.ts                  # Reference pattern (auth.spec.ts)
└── auth.spec.ts             # Reference pattern existant
```

**Structure Decision**: Les fichiers de test sont colocalises avec les services dans `app/src/app/core/services/`, suivant le pattern Angular standard et le precedent de `auth.spec.ts`.

## Design

### Mock Strategy

ApiService est mocke comme objet avec les 4 methodes HTTP en `vi.fn()` :

```
apiService = {
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  delete: vi.fn()
}
```

Inject via TestBed : `{ provide: ApiService, useValue: apiService }`

### Test Matrix

#### TransactionService (8 tests)

| Test | Methode | Endpoint verifie | refreshTrigger |
|------|---------|-----------------|----------------|
| should_return_transactions_when_getAll_called | getAll() | GET /transactions | Non |
| should_return_transaction_when_getById_called | getById(id) | GET /transactions/{id} | Non |
| should_create_and_refresh_when_create_called | create(req) | POST /transactions | Oui (+1) |
| should_update_and_refresh_when_update_called | update(id, req) | PUT /transactions/{id} | Oui (+1) |
| should_delete_and_refresh_when_delete_called | delete(id) | DELETE /transactions/{id} | Oui (+1) |
| should_return_summary_when_getSummary_called_without_params | getSummary() | GET /transactions/summary | Non |
| should_return_summary_when_getSummary_called_with_month_and_year | getSummary(1, 2026) | GET /transactions/summary?month=1&year=2026 | Non |
| should_increment_refreshTrigger_on_successive_mutations | create x3 | N/A | Oui (0→3) |

#### SubscriptionService (8 tests)

| Test | Methode | Endpoint verifie | refreshTrigger |
|------|---------|-----------------|----------------|
| should_return_subscriptions_when_getAll_called_without_filter | getAll() | GET /subscriptions | Non |
| should_return_active_subscriptions_when_getAll_called_with_actif_true | getAll(true) | GET /subscriptions?actif=true | Non |
| should_return_inactive_subscriptions_when_getAll_called_with_actif_false | getAll(false) | GET /subscriptions?actif=false | Non |
| should_return_subscription_when_getById_called | getById(id) | GET /subscriptions/{id} | Non |
| should_create_and_refresh_when_create_called | create(req) | POST /subscriptions | Oui (+1) |
| should_update_and_refresh_when_update_called | update(id, req) | PUT /subscriptions/{id} | Oui (+1) |
| should_delete_and_refresh_when_delete_called | delete(id) | DELETE /subscriptions/{id} | Oui (+1) |
| should_increment_refreshTrigger_on_successive_mutations | create x3 | N/A | Oui (0→3) |

#### DebtService (8 tests)

| Test | Methode | Endpoint verifie | refreshTrigger |
|------|---------|-----------------|----------------|
| should_return_debts_when_getAll_called_without_filter | getAll() | GET /debts | Non |
| should_return_repaid_debts_when_getAll_called_with_rembourse_true | getAll(true) | GET /debts?rembourse=true | Non |
| should_return_unpaid_debts_when_getAll_called_with_rembourse_false | getAll(false) | GET /debts?rembourse=false | Non |
| should_return_debt_when_getById_called | getById(id) | GET /debts/{id} | Non |
| should_create_and_refresh_when_create_called | create(req) | POST /debts | Oui (+1) |
| should_update_and_refresh_when_update_called | update(id, req) | PUT /debts/{id} | Oui (+1) |
| should_delete_and_refresh_when_delete_called | delete(id) | DELETE /debts/{id} | Oui (+1) |
| should_increment_refreshTrigger_on_successive_mutations | create x3 | N/A | Oui (0→3) |

**Total : 24 tests**

### Donnees de test

Chaque service utilise des objets mock minimaux :

- **Transaction** : `{ id: 'uuid-1', montant: 50, libelle: 'Courses', type: 'DEPENSE', date: '2026-02-01', category: null, note: null }`
- **Subscription** : `{ id: 'uuid-1', nom: 'Netflix', montant: 13.99, frequence: 'MENSUEL', dateDebut: '2026-01-01', actif: true, category: null }`
- **Debt** : `{ id: 'uuid-1', personne: 'Alice', montant: 100, sens: 'JE_DOIS', date: '2026-02-01', rembourse: false, category: null }`

## Artifacts

| Artifact | Statut | Description |
|----------|--------|-------------|
| research.md | Genere | 5 decisions documentees |
| quickstart.md | Genere | Commandes et pattern de reference |
| data-model.md | N/A | Pas de modification de modele |
| contracts/ | N/A | Pas de nouvel endpoint API |
