# Quickstart: Tests unitaires services Phase 4

**Branch**: `017-phase4-unit-tests`

## Commandes

```bash
# Lancer tous les tests
cd app && npx vitest run

# Lancer un fichier de test specifique
cd app && npx vitest run src/app/core/services/transaction.spec.ts

# Mode watch
cd app && npx vitest

# Build (verification compilation)
cd app && ng build

# Lint
cd app && ng lint
```

## Fichiers a creer

| Fichier | Service teste |
|---------|---------------|
| `app/src/app/core/services/transaction.spec.ts` | TransactionService |
| `app/src/app/core/services/subscription.spec.ts` | SubscriptionService |
| `app/src/app/core/services/debt.spec.ts` | DebtService |

## Pattern de test (reference : auth.spec.ts)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';
// + imports service et ApiService

describe('NomService', () => {
  let service: NomService;
  let apiService: { get: ReturnType<typeof vi.fn>; post: ReturnType<typeof vi.fn>; put: ReturnType<typeof vi.fn>; delete: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    if (!getTestBed().platform) {
      getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
    }
    apiService = { get: vi.fn(), post: vi.fn(), put: vi.fn(), delete: vi.fn() };
    TestBed.configureTestingModule({
      providers: [NomService, { provide: ApiService, useValue: apiService }],
    });
    service = TestBed.inject(NomService);
  });

  it('should_return_list_when_getAll_called', () => {
    apiService.get.mockReturnValue(of([/* mock data */]));
    service.getAll().subscribe((result) => {
      expect(result).toEqual([/* mock data */]);
    });
    expect(apiService.get).toHaveBeenCalledWith('/endpoint');
  });
});
```

## Verification finale

1. `cd app && npx vitest run` — tous les tests passent
2. `cd app && ng build` — compilation OK
3. `cd app && ng lint` — aucun warning
