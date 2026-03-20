import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';

import { RecurringTransactionService } from './recurring-transaction';
import { ApiService } from './api';
import { RecurringTransactionResponse } from '../models/recurring-transaction.model';
import { Transaction, TransactionType } from '../models/transaction.model';
import { Frequency } from '../models/subscription.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockCategory = { id: 'cat-1', nom: 'Alimentation', icone: '🛒', couleur: '#f59e0b' };
const mockAccount = { id: 'acc-1', nom: 'Compte courant', icone: '🏦', couleur: '#4f46e5' };

const mockRecurring: RecurringTransactionResponse = {
  id: 'rt-1',
  montant: 50,
  libelle: 'Loyer',
  type: TransactionType.DEPENSE,
  frequency: Frequency.MENSUEL,
  nextOccurrence: '2026-03-15',
  recurringActive: true,
  category: mockCategory,
  account: mockAccount,
};

const mockRecurring2: RecurringTransactionResponse = {
  id: 'rt-2',
  montant: 120,
  libelle: 'Abonnement salle',
  type: TransactionType.DEPENSE,
  frequency: Frequency.MENSUEL,
  nextOccurrence: '2026-03-20',
  recurringActive: true,
  category: mockCategory,
  account: mockAccount,
};

const mockTransaction: Transaction = {
  id: 'tx-1',
  montant: 50,
  libelle: 'Loyer',
  type: TransactionType.DEPENSE,
  date: '2026-03-15',
  category: mockCategory,
  note: null,
  account: mockAccount,
  transferId: null,
};

describe('RecurringTransactionService', () => {
  let service: RecurringTransactionService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    post: ReturnType<typeof vi.fn>;
    patch: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      post: vi.fn(),
      patch: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [RecurringTransactionService, { provide: ApiService, useValue: apiService }],
    });

    service = TestBed.inject(RecurringTransactionService);
  });

  it('should_load_active_recurring_transactions_when_loadActive_called', async () => {
    // Arrange
    apiService.get.mockReturnValue(of([mockRecurring, mockRecurring2]));

    // Act
    await service.loadActive();

    // Assert
    expect(apiService.get).toHaveBeenCalledWith('/transactions/recurring');
    expect(service.recurringTransactions()).toEqual([mockRecurring, mockRecurring2]);
  });

  it('should_set_loading_to_true_then_false_when_loadActive', async () => {
    // Arrange
    const loadingStates: boolean[] = [];
    apiService.get.mockReturnValue(of([mockRecurring]));

    // On observe l'état loading avant le await — il est true pendant l'exécution
    // puis false après. On capture l'état final après résolution.
    const promise = service.loadActive();
    loadingStates.push(service.loading());

    await promise;
    loadingStates.push(service.loading());

    // Assert : pendant le chargement loading était true, après false
    expect(loadingStates[0]).toBe(true);
    expect(loadingStates[1]).toBe(false);
  });

  it('should_set_error_when_loadActive_fails', async () => {
    // Arrange
    apiService.get.mockReturnValue(throwError(() => new Error('Network error')));

    // Act
    await service.loadActive();

    // Assert
    expect(service.error()).toBe('Impossible de charger les transactions récurrentes');
    expect(service.loading()).toBe(false);
    expect(service.recurringTransactions()).toEqual([]);
  });

  it('should_call_validate_endpoint_when_validate_called', () => {
    // Arrange
    apiService.get.mockReturnValue(of([]));
    apiService.post.mockReturnValue(of(mockTransaction));

    // Act
    service.validate('rt-1').subscribe((result) => {
      // Assert
      expect(result).toEqual(mockTransaction);
    });

    expect(apiService.post).toHaveBeenCalledWith('/transactions/recurring/rt-1/validate', {});
  });

  it('should_refresh_list_after_validate', async () => {
    // Arrange
    apiService.get.mockReturnValue(of([mockRecurring2]));
    apiService.post.mockReturnValue(of(mockTransaction));

    // Act
    await new Promise<void>((resolve) => {
      service.validate('rt-1').subscribe(() => resolve());
    });

    // Assert : loadActive a été rappelé après le validate
    expect(apiService.get).toHaveBeenCalledWith('/transactions/recurring');
    expect(service.recurringTransactions()).toEqual([mockRecurring2]);
  });

  it('should_call_skip_endpoint_when_skip_called', () => {
    // Arrange
    apiService.get.mockReturnValue(of([]));
    apiService.patch.mockReturnValue(of(mockRecurring));

    // Act
    service.skip('rt-1').subscribe((result) => {
      // Assert
      expect(result).toEqual(mockRecurring);
    });

    expect(apiService.patch).toHaveBeenCalledWith('/transactions/recurring/rt-1/skip', {});
  });

  it('should_call_deactivate_endpoint_when_deactivate_called', () => {
    // Arrange
    apiService.get.mockReturnValue(of([]));
    apiService.patch.mockReturnValue(of({ ...mockRecurring, recurringActive: false }));

    // Act
    service.deactivate('rt-1').subscribe((result) => {
      // Assert
      expect(result).toMatchObject({ recurringActive: false });
    });

    expect(apiService.patch).toHaveBeenCalledWith('/transactions/recurring/rt-1/deactivate', {});
  });
});
