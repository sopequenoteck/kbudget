import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';

import { TransactionService } from './transaction';
import { ApiService } from './api';
import {
  Transaction,
  TransactionRequest,
  TransactionType,
  MonthlySummary,
} from '../models/transaction.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockTransaction: Transaction = {
  id: 'uuid-1',
  montant: 50,
  libelle: 'Courses',
  type: TransactionType.DEPENSE,
  date: '2026-02-01',
  category: null,
  note: null,
  account: null,
  transferId: null,
};

const mockRequest: TransactionRequest = {
  montant: 50,
  libelle: 'Courses',
  type: TransactionType.DEPENSE,
  date: '2026-02-01',
};

const mockSummary: MonthlySummary = {
  month: 2,
  year: 2026,
  totalRecettes: 3000,
  totalDepenses: 1500,
  solde: 1500,
  currency: 'EUR',
};

describe('TransactionService', () => {
  let service: TransactionService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    post: ReturnType<typeof vi.fn>;
    put: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [TransactionService, { provide: ApiService, useValue: apiService }],
    });

    service = TestBed.inject(TransactionService);
  });

  it('should_return_transactions_when_getAll_called', () => {
    // Arrange
    const transactions = [mockTransaction];
    apiService.get.mockReturnValue(of(transactions));

    // Act
    service.getAll().subscribe((result) => {
      // Assert
      expect(result).toEqual(transactions);
    });

    expect(apiService.get).toHaveBeenCalledWith('/transactions');
  });

  it('should_return_transaction_when_getById_called', () => {
    // Arrange
    apiService.get.mockReturnValue(of(mockTransaction));

    // Act
    service.getById('uuid-1').subscribe((result) => {
      // Assert
      expect(result).toEqual(mockTransaction);
    });

    expect(apiService.get).toHaveBeenCalledWith('/transactions/uuid-1');
  });

  it('should_create_and_refresh_when_create_called', () => {
    // Arrange
    apiService.post.mockReturnValue(of(mockTransaction));
    const before = service.refreshTrigger();

    // Act
    service.create(mockRequest).subscribe((result) => {
      // Assert
      expect(result).toEqual(mockTransaction);
    });

    expect(apiService.post).toHaveBeenCalledWith('/transactions', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_update_and_refresh_when_update_called', () => {
    // Arrange
    apiService.put.mockReturnValue(of(mockTransaction));
    const before = service.refreshTrigger();

    // Act
    service.update('uuid-1', mockRequest).subscribe((result) => {
      // Assert
      expect(result).toEqual(mockTransaction);
    });

    expect(apiService.put).toHaveBeenCalledWith('/transactions/uuid-1', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_delete_and_refresh_when_delete_called', () => {
    // Arrange
    apiService.delete.mockReturnValue(of(undefined));
    const before = service.refreshTrigger();

    // Act
    service.delete('uuid-1').subscribe();

    expect(apiService.delete).toHaveBeenCalledWith('/transactions/uuid-1');
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_return_summary_when_getSummary_called_without_params', () => {
    // Arrange
    apiService.get.mockReturnValue(of(mockSummary));

    // Act
    service.getSummary().subscribe((result) => {
      // Assert
      expect(result).toEqual(mockSummary);
    });

    expect(apiService.get).toHaveBeenCalledWith('/transactions/summary');
  });

  it('should_return_summary_when_getSummary_called_with_month_and_year', () => {
    // Arrange
    apiService.get.mockReturnValue(of(mockSummary));

    // Act
    service.getSummary(1, 2026).subscribe((result) => {
      // Assert
      expect(result).toEqual(mockSummary);
    });

    expect(apiService.get).toHaveBeenCalledWith('/transactions/summary?month=1&year=2026');
  });

  it('should_increment_refreshTrigger_on_successive_mutations', () => {
    // Arrange
    apiService.post.mockReturnValue(of(mockTransaction));
    expect(service.refreshTrigger()).toBe(0);

    // Act
    service.create(mockRequest).subscribe();
    service.create(mockRequest).subscribe();
    service.create(mockRequest).subscribe();

    // Assert
    expect(service.refreshTrigger()).toBe(3);
  });
});
