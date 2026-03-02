import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';

import { AccountService } from './account';
import { ApiService } from './api';
import {
  Account,
  AccountRequest,
  AccountType,
  TransferRequest,
  TransferResponse,
  TransactionRef,
} from '../models/account.model';
import { TransactionType } from '../models/transaction.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockAccount: Account = {
  id: 'acc-1',
  nom: 'Compte courant',
  type: AccountType.COURANT,
  soldeInitial: 1000,
  solde: 1500,
  icone: '🏦',
  couleur: '#3b82f6',
  isDefault: true,
  actif: true,
};

const mockRequest: AccountRequest = {
  nom: 'Compte courant',
  type: AccountType.COURANT,
  soldeInitial: 1000,
};

const mockTransferRequest: TransferRequest = {
  fromAccountId: 'acc-1',
  toAccountId: 'acc-2',
  montant: 100,
};

const mockTransactionRef: TransactionRef = {
  id: 'tx-1',
  montant: 100,
  libelle: 'Virement vers Épargne',
  type: TransactionType.DEPENSE,
  date: '2026-02-16',
  accountId: 'acc-1',
  accountNom: 'Compte courant',
};

const mockTransferResponse: TransferResponse = {
  transferId: 'transfer-1',
  debitTransaction: mockTransactionRef,
  creditTransaction: {
    ...mockTransactionRef,
    id: 'tx-2',
    type: TransactionType.RECETTE,
    accountId: 'acc-2',
    accountNom: 'Épargne',
  },
};

describe('AccountService', () => {
  let service: AccountService;
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
      providers: [AccountService, { provide: ApiService, useValue: apiService }],
    });

    service = TestBed.inject(AccountService);
  });

  it('should_return_accounts_when_getAll_called', () => {
    const accounts = [mockAccount];
    apiService.get.mockReturnValue(of(accounts));

    service.getAll().subscribe((result) => {
      expect(result).toEqual(accounts);
    });

    expect(apiService.get).toHaveBeenCalledWith('/accounts');
  });

  it('should_return_accounts_with_inactive_when_getAll_called_with_includeInactive', () => {
    apiService.get.mockReturnValue(of([mockAccount]));

    service.getAll(true).subscribe();

    expect(apiService.get).toHaveBeenCalledWith('/accounts?includeInactive=true');
  });

  it('should_return_account_when_getById_called', () => {
    apiService.get.mockReturnValue(of(mockAccount));

    service.getById('acc-1').subscribe((result) => {
      expect(result).toEqual(mockAccount);
    });

    expect(apiService.get).toHaveBeenCalledWith('/accounts/acc-1');
  });

  it('should_create_and_refresh_when_create_called', () => {
    apiService.post.mockReturnValue(of(mockAccount));
    const before = service.refreshTrigger();

    service.create(mockRequest).subscribe((result) => {
      expect(result).toEqual(mockAccount);
    });

    expect(apiService.post).toHaveBeenCalledWith('/accounts', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_update_and_refresh_when_update_called', () => {
    apiService.put.mockReturnValue(of(mockAccount));
    const before = service.refreshTrigger();

    service.update('acc-1', mockRequest).subscribe((result) => {
      expect(result).toEqual(mockAccount);
    });

    expect(apiService.put).toHaveBeenCalledWith('/accounts/acc-1', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_delete_and_refresh_when_delete_called', () => {
    apiService.delete.mockReturnValue(of(undefined));
    const before = service.refreshTrigger();

    service.delete('acc-1').subscribe();

    expect(apiService.delete).toHaveBeenCalledWith('/accounts/acc-1');
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_set_default_and_refresh_when_setDefault_called', () => {
    apiService.put.mockReturnValue(of(mockAccount));
    const before = service.refreshTrigger();

    service.setDefault('acc-1').subscribe((result) => {
      expect(result).toEqual(mockAccount);
    });

    expect(apiService.put).toHaveBeenCalledWith('/accounts/acc-1/default', {});
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_transfer_and_refresh_when_transfer_called', () => {
    apiService.post.mockReturnValue(of(mockTransferResponse));
    const before = service.refreshTrigger();

    service.transfer(mockTransferRequest).subscribe((result) => {
      expect(result).toEqual(mockTransferResponse);
    });

    expect(apiService.post).toHaveBeenCalledWith('/accounts/transfer', mockTransferRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_increment_refreshTrigger_on_successive_mutations', () => {
    apiService.post.mockReturnValue(of(mockAccount));
    apiService.put.mockReturnValue(of(mockAccount));
    apiService.delete.mockReturnValue(of(undefined));
    expect(service.refreshTrigger()).toBe(0);

    service.create(mockRequest).subscribe();
    service.update('acc-1', mockRequest).subscribe();
    service.delete('acc-1').subscribe();

    expect(service.refreshTrigger()).toBe(3);
  });
});
