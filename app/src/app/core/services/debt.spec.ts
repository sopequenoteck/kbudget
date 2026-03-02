import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';

import { DebtService } from './debt';
import { ApiService } from './api';
import { Debt, DebtRequest, DebtType } from '../models/debt.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockDebt: Debt = {
  id: 'uuid-1',
  personne: 'Alice',
  montant: 100,
  sens: DebtType.EMPRUNT,
  date: '2026-02-01',
  rembourse: false,
  category: null,
};

const mockRequest: DebtRequest = {
  personne: 'Alice',
  montant: 100,
  sens: DebtType.EMPRUNT,
  date: '2026-02-01',
};

describe('DebtService', () => {
  let service: DebtService;
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
      providers: [DebtService, { provide: ApiService, useValue: apiService }],
    });

    service = TestBed.inject(DebtService);
  });

  it('should_return_debts_when_getAll_called_without_filter', () => {
    // Arrange
    const debts = [mockDebt];
    apiService.get.mockReturnValue(of(debts));

    // Act
    service.getAll().subscribe((result) => {
      // Assert
      expect(result).toEqual(debts);
    });

    expect(apiService.get).toHaveBeenCalledWith('/debts');
  });

  it('should_return_repaid_debts_when_getAll_called_with_rembourse_true', () => {
    // Arrange
    const debts = [{ ...mockDebt, rembourse: true }];
    apiService.get.mockReturnValue(of(debts));

    // Act
    service.getAll(true).subscribe((result) => {
      // Assert
      expect(result).toEqual(debts);
    });

    expect(apiService.get).toHaveBeenCalledWith('/debts?rembourse=true');
  });

  it('should_return_unpaid_debts_when_getAll_called_with_rembourse_false', () => {
    // Arrange
    const debts = [mockDebt];
    apiService.get.mockReturnValue(of(debts));

    // Act
    service.getAll(false).subscribe((result) => {
      // Assert
      expect(result).toEqual(debts);
    });

    expect(apiService.get).toHaveBeenCalledWith('/debts?rembourse=false');
  });

  it('should_return_debt_when_getById_called', () => {
    // Arrange
    apiService.get.mockReturnValue(of(mockDebt));

    // Act
    service.getById('uuid-1').subscribe((result) => {
      // Assert
      expect(result).toEqual(mockDebt);
    });

    expect(apiService.get).toHaveBeenCalledWith('/debts/uuid-1');
  });

  it('should_create_and_refresh_when_create_called', () => {
    // Arrange
    apiService.post.mockReturnValue(of(mockDebt));
    const before = service.refreshTrigger();

    // Act
    service.create(mockRequest).subscribe((result) => {
      // Assert
      expect(result).toEqual(mockDebt);
    });

    expect(apiService.post).toHaveBeenCalledWith('/debts', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_update_and_refresh_when_update_called', () => {
    // Arrange
    apiService.put.mockReturnValue(of(mockDebt));
    const before = service.refreshTrigger();

    // Act
    service.update('uuid-1', mockRequest).subscribe((result) => {
      // Assert
      expect(result).toEqual(mockDebt);
    });

    expect(apiService.put).toHaveBeenCalledWith('/debts/uuid-1', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_delete_and_refresh_when_delete_called', () => {
    // Arrange
    apiService.delete.mockReturnValue(of(undefined));
    const before = service.refreshTrigger();

    // Act
    service.delete('uuid-1').subscribe();

    expect(apiService.delete).toHaveBeenCalledWith('/debts/uuid-1');
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_increment_refreshTrigger_on_successive_mutations', () => {
    // Arrange
    apiService.post.mockReturnValue(of(mockDebt));
    expect(service.refreshTrigger()).toBe(0);

    // Act
    service.create(mockRequest).subscribe();
    service.create(mockRequest).subscribe();
    service.create(mockRequest).subscribe();

    // Assert
    expect(service.refreshTrigger()).toBe(3);
  });
});
