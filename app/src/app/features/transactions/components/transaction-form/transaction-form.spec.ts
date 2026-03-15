import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';
import { signal } from '@angular/core';

import { TransactionForm } from './transaction-form';
import { TransactionService } from '../../../../core/services/transaction';
import { RecurringTransactionService } from '../../../../core/services/recurring-transaction';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { AccountService } from '../../../../core/services/account';
import { TransactionType, type Transaction } from '../../../../core/models/transaction.model';
import { Frequency } from '../../../../core/models/subscription.model';
import { type RecurringTransactionResponse } from '../../../../core/models/recurring-transaction.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const makeTransaction = (overrides: Partial<Transaction> = {}): Transaction => ({
  id: 'tx-1',
  montant: 42.5,
  libelle: 'Loyer',
  type: TransactionType.DEPENSE,
  date: '2026-03-01',
  category: null,
  note: null,
  account: null,
  transferId: null,
  ...overrides,
});

const makeRecurringResponse = (): RecurringTransactionResponse => ({
  id: 'rec-1',
  montant: 42.5,
  libelle: 'Loyer',
  type: TransactionType.DEPENSE,
  frequency: Frequency.MENSUEL,
  nextOccurrence: '2026-04-01',
  recurringActive: true,
  category: null as any,
  account: null as any,
});

describe('TransactionForm', () => {
  let transactionServiceMock: {
    create: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof signal>;
  };

  let recurringTransactionServiceMock: {
    create: ReturnType<typeof vi.fn>;
    loadActive: ReturnType<typeof vi.fn>;
    recurringTransactions: ReturnType<typeof signal>;
    loading: ReturnType<typeof signal>;
    error: ReturnType<typeof signal>;
  };

  let modalServiceMock: {
    editingEntity: ReturnType<typeof signal>;
    asRecurring: ReturnType<typeof signal>;
    activeModal: ReturnType<typeof signal>;
    modalOpen: ReturnType<typeof signal>;
    closeModal: ReturnType<typeof vi.fn>;
  };

  let toastServiceMock: {
    success: ReturnType<typeof vi.fn>;
    error: ReturnType<typeof vi.fn>;
  };

  let accountServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof signal>;
  };

  beforeEach(() => {
    transactionServiceMock = {
      create: vi.fn().mockReturnValue(of(makeTransaction())),
      update: vi.fn().mockReturnValue(of(makeTransaction())),
      delete: vi.fn().mockReturnValue(of(undefined)),
      refreshTrigger: signal(0),
    };

    recurringTransactionServiceMock = {
      create: vi.fn().mockReturnValue(of(makeRecurringResponse())),
      loadActive: vi.fn().mockResolvedValue(undefined),
      recurringTransactions: signal([]),
      loading: signal(false),
      error: signal(null),
    };

    modalServiceMock = {
      editingEntity: signal(null),
      asRecurring: signal(false),
      activeModal: signal(null),
      modalOpen: signal(false),
      closeModal: vi.fn(),
    };

    toastServiceMock = {
      success: vi.fn(),
      error: vi.fn(),
    };

    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of([])),
      refreshTrigger: signal(0),
    };
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [TransactionForm],
      providers: [
        { provide: TransactionService, useValue: transactionServiceMock },
        { provide: RecurringTransactionService, useValue: recurringTransactionServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
      ],
    });
  };

  it('should_show_recurring_toggle_in_creation_mode', () => {
    // modalService.editingEntity = null → mode création
    modalServiceMock.editingEntity = signal(null);
    modalServiceMock.asRecurring = signal(false);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const toggle = fixture.nativeElement.querySelector('.recurring-toggle');
    expect(toggle).not.toBeNull();

    const checkbox = fixture.nativeElement.querySelector('#isRecurring');
    expect(checkbox).not.toBeNull();
  });

  it('should_hide_recurring_toggle_in_edit_mode', () => {
    // modalService.editingEntity contient une entité et asRecurring = false → mode édition
    modalServiceMock.editingEntity = signal(makeTransaction());
    modalServiceMock.asRecurring = signal(false);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const toggle = fixture.nativeElement.querySelector('.recurring-toggle');
    expect(toggle).toBeNull();
  });

  it('should_call_recurring_service_create_when_recurring_enabled', async () => {
    modalServiceMock.editingEntity = signal(null);
    modalServiceMock.asRecurring = signal(false);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const today = new Date().toISOString().split('T')[0];

    // Activer isRecurring et remplir les champs obligatoires
    component.form.patchValue({
      libelle: 'Loyer mensuel',
      montant: '500',
      isRecurring: true,
      frequency: Frequency.MENSUEL,
      nextOccurrence: today,
    });
    component.form.get('frequency')!.enable();
    component.form.get('nextOccurrence')!.enable();
    fixture.detectChanges();

    await component.onSubmit();

    expect(recurringTransactionServiceMock.create).toHaveBeenCalledOnce();
    expect(transactionServiceMock.create).not.toHaveBeenCalled();

    const callArgs = recurringTransactionServiceMock.create.mock.calls[0][0];
    expect(callArgs.libelle).toBe('Loyer mensuel');
    expect(callArgs.montant).toBe(500);
    expect(callArgs.frequency).toBe(Frequency.MENSUEL);
  });

  it('should_prefill_form_when_converting_transaction', () => {
    // asRecurring = true + entité existante → pré-remplissage + isRecurring activé
    const existingTransaction = makeTransaction({
      libelle: 'Abonnement salle',
      montant: 35,
      category: null,
      account: null,
      note: 'Mensuel',
    });
    modalServiceMock.editingEntity = signal(existingTransaction);
    modalServiceMock.asRecurring = signal(true);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;

    expect(component.form.get('libelle')!.value).toBe('Abonnement salle');
    expect(component.form.get('montant')!.value).toBe('35');
    expect(component.form.get('isRecurring')!.value).toBe(true);
    // Le composant n'est pas en mode édition (asRecurring override isEditing)
    expect(component.isEditing()).toBe(false);
  });
});
