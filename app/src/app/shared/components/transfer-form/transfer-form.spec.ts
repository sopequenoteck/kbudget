import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';

import { TransferForm } from './transfer-form';
import { AccountService } from '../../../core/services/account';
import { Account, AccountType } from '../../../core/models/account.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockAccounts: Account[] = [
  {
    id: 'acc-1',
    nom: 'Courant',
    type: AccountType.COURANT,
    soldeInitial: 1000,
    solde: 1500,
    icone: '🏦',
    couleur: '#3b82f6',
    isDefault: true,
    actif: true,
  },
  {
    id: 'acc-2',
    nom: 'Épargne',
    type: AccountType.EPARGNE,
    soldeInitial: 5000,
    solde: 5000,
    icone: '💰',
    couleur: '#10b981',
    isDefault: false,
    actif: true,
  },
];

const singleAccount: Account[] = [mockAccounts[0]];

describe('TransferForm', () => {
  let accountServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
    transfer: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of(mockAccounts)),
      transfer: vi.fn(),
      refreshTrigger: vi.fn().mockReturnValue(0),
    };

    TestBed.configureTestingModule({
      imports: [TransferForm],
      providers: [{ provide: AccountService, useValue: accountServiceMock }],
    });
  });

  it('should_create_the_component', () => {
    const fixture = TestBed.createComponent(TransferForm);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_show_message_when_less_than_2_active_accounts', () => {
    accountServiceMock.getAll.mockReturnValue(of(singleAccount));

    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const noAccounts = fixture.nativeElement.querySelector('.transfer-form__no-accounts');
    expect(noAccounts).toBeTruthy();
  });

  it('should_show_form_when_2_or_more_active_accounts', () => {
    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const form = fixture.nativeElement.querySelector('.transfer-form');
    expect(form).toBeTruthy();
  });

  it('should_validate_same_account_error', () => {
    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-1',
      montant: '100',
    });

    expect(component.form.hasError('sameAccount')).toBe(true);
  });

  it('should_not_have_same_account_error_when_different_accounts', () => {
    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-2',
      montant: '100',
    });

    expect(component.form.hasError('sameAccount')).toBe(false);
  });

  it('should_require_montant_greater_than_zero', () => {
    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ montant: '0' });
    component.form.get('montant')!.markAsTouched();

    expect(component.isInvalid('montant')).toBe(true);
  });

  it('should_accept_valid_montant', () => {
    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ montant: '0.01' });
    component.form.get('montant')!.markAsTouched();

    expect(component.isInvalid('montant')).toBe(false);
  });
});
