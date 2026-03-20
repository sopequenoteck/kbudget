import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';

import { RepayDialog } from './repay-dialog';
import { DebtService } from '../../../../core/services/debt';
import { AccountService } from '../../../../core/services/account';
import { Debt, DebtType } from '../../../../core/models/debt.model';
import { Account, AccountType } from '../../../../core/models/account.model';

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
    currency: 'EUR',
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
    currency: 'EUR',
  },
];

const mockDebt: Debt = {
  id: 'debt-1',
  personne: 'Bob',
  montant: 300,
  montantRestant: 200,
  sens: DebtType.EMPRUNT,
  date: '2026-01-01',
  dueDate: null,
  rembourse: false,
  category: null,
  currency: 'EUR',
  account: null,
  includeInBalance: false,
  reminderDate: null,
  reminderTime: null,
};

const mockDebtWithAccount: Debt = {
  ...mockDebt,
  id: 'debt-2',
  account: {
    id: 'acc-2',
    nom: 'Épargne',
    icone: '💰',
    couleur: '#10b981',
    currency: 'EUR',
  },
};

describe('RepayDialog', () => {
  let debtServiceMock: {
    repay: ReturnType<typeof vi.fn>;
  };

  let accountServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    debtServiceMock = {
      repay: vi.fn().mockReturnValue(of({ ...mockDebt, montantRestant: 0, rembourse: true })),
    };

    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of(mockAccounts)),
    };

    TestBed.configureTestingModule({
      imports: [RepayDialog],
      providers: [
        { provide: DebtService, useValue: debtServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
      ],
    });
  });

  it('should_prefill_amount_with_remaining_when_opened', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().amount).toBe(200);
  });

  it('should_preselect_first_account_when_no_associated_account', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().accountId).toBe('acc-1');
  });

  it('should_preselect_associated_account_when_debt_has_account', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebtWithAccount);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().accountId).toBe('acc-2');
  });

  it('should_validate_amount_greater_than_zero', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ amount: 0 });
    component.form.get('amount')!.markAsTouched();

    expect(component.isInvalid('amount')).toBe(true);
    expect(component.form.get('amount')!.hasError('min')).toBe(true);
  });

  it('should_validate_amount_not_exceeding_remaining', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ amount: 201 }); // > montantRestant (200)
    component.form.get('amount')!.markAsTouched();

    expect(component.form.get('amount')!.hasError('max')).toBe(true);
  });

  it('should_accept_valid_amount_within_remaining', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ amount: 100 });
    component.form.get('amount')!.markAsTouched();

    expect(component.isInvalid('amount')).toBe(false);
  });

  it('should_require_account_selection', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ accountId: '' });
    component.form.get('accountId')!.markAsTouched();

    expect(component.isInvalid('accountId')).toBe(true);
    expect(component.form.get('accountId')!.hasError('required')).toBe(true);
  });

  it('should_call_repay_and_emit_when_form_is_valid', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    let repaidEmitted = false;
    component.repaid.subscribe(() => {
      repaidEmitted = true;
    });

    await component.onSubmit();

    expect(debtServiceMock.repay).toHaveBeenCalledWith('debt-1', {
      accountId: 'acc-1',
      amount: 200,
    });
    expect(repaidEmitted).toBe(true);
  });

  it('should_not_call_repay_when_form_is_invalid', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ accountId: '' });

    await component.onSubmit();

    expect(debtServiceMock.repay).not.toHaveBeenCalled();
  });

  it('should_set_error_message_when_repay_fails', async () => {
    debtServiceMock.repay.mockReturnValue(throwError(() => new Error('Solde insuffisant')));
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onSubmit();

    expect(component.errorMessage()).toBe('Solde insuffisant');
  });

  it('should_emit_closed_when_cancel_clicked', async () => {
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let closedEmitted = false;
    component.closed.subscribe(() => {
      closedEmitted = true;
    });

    component.onCancel();

    expect(closedEmitted).toBe(true);
  });
});
