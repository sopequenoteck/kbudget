import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { signal } from '@angular/core';

import { RepayDialog } from './repay-dialog';
import { DebtService } from '../../../../core/services/debt';
import { AccountService } from '../../../../core/services/account';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Debt, DebtType } from '../../../../core/models/debt.model';
import { Account, AccountType } from '../../../../core/models/account.model';

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

  let modalServiceMock: {
    editingEntity: ReturnType<typeof signal>;
    closeModal: ReturnType<typeof vi.fn>;
  };

  let toastServiceMock: {
    success: ReturnType<typeof vi.fn>;
    error: ReturnType<typeof vi.fn>;
  };

  const setup = (debt: Debt | null) => {
    debtServiceMock = {
      repay: vi.fn().mockReturnValue(of({ ...mockDebt, montantRestant: 0, rembourse: true })),
    };
    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of(mockAccounts)),
    };
    modalServiceMock = {
      editingEntity: signal(debt),
      closeModal: vi.fn(),
    };
    toastServiceMock = {
      success: vi.fn(),
      error: vi.fn(),
    };

    TestBed.configureTestingModule({
      imports: [RepayDialog],
      providers: [
        { provide: DebtService, useValue: debtServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
      ],
    });
  };

  it('should_prefill_amount_with_remaining_when_opened', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().amount).toBe('200');
  });

  it('should_preselect_first_account_when_no_associated_account', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().accountId).toBe('acc-1');
  });

  it('should_preselect_associated_account_when_debt_has_account', async () => {
    setup(mockDebtWithAccount);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().accountId).toBe('acc-2');
  });

  it('should_validate_amount_greater_than_zero', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ amount: '0' });
    component.form.get('amount')!.markAsTouched();

    expect(component.isInvalid('amount')).toBe(true);
    expect(component.form.get('amount')!.hasError('min')).toBe(true);
  });

  it('should_validate_amount_not_exceeding_remaining', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ amount: '201' }); // > montantRestant (200)
    component.form.get('amount')!.markAsTouched();

    expect(component.form.get('amount')!.hasError('max')).toBe(true);
  });

  it('should_accept_valid_amount_within_remaining', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ amount: '100' });
    component.form.get('amount')!.markAsTouched();

    expect(component.isInvalid('amount')).toBe(false);
  });

  it('should_require_account_selection', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ accountId: '' });
    component.form.get('accountId')!.markAsTouched();

    expect(component.isInvalid('accountId')).toBe(true);
    expect(component.form.get('accountId')!.hasError('required')).toBe(true);
  });

  it('should_call_repay_and_emit_when_form_is_valid', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let savedEmitted = false;
    component.saved.subscribe(() => {
      savedEmitted = true;
    });

    await component.onSubmit();

    expect(debtServiceMock.repay).toHaveBeenCalledWith('debt-1', {
      accountId: 'acc-1',
      amount: 200,
    });
    expect(savedEmitted).toBe(true);
  });

  it('should_not_call_repay_when_form_is_invalid', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ accountId: '' });

    await component.onSubmit();

    expect(debtServiceMock.repay).not.toHaveBeenCalled();
  });

  it('should_set_error_message_when_repay_fails', async () => {
    setup(mockDebt);
    debtServiceMock.repay.mockReturnValue(throwError(() => new Error('Solde insuffisant')));
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    await component.onSubmit();

    expect(component.errorMessage()).toBe('Solde insuffisant');
  });

  it('should_emit_closed_when_cancel_clicked', async () => {
    setup(mockDebt);
    const fixture = TestBed.createComponent(RepayDialog);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let cancelledEmitted = false;
    component.cancelled.subscribe(() => {
      cancelledEmitted = true;
    });

    component.onCancel();

    expect(cancelledEmitted).toBe(true);
  });
});
