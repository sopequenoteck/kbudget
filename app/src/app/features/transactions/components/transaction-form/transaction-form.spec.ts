import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { signal } from '@angular/core';

import { TransactionForm } from './transaction-form';
import { TransactionService } from '../../../../core/services/transaction';
import { RecurringTransactionService } from '../../../../core/services/recurring-transaction';
import { TransactionLibelleService } from '../../services/transaction-libelle.service';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { AccountService } from '../../../../core/services/account';
import { TransactionType, type Transaction } from '../../../../core/models/transaction.model';
import { Frequency } from '../../../../core/models/subscription.model';
import { type RecurringTransactionResponse } from '../../../../core/models/recurring-transaction.model';
import { type Category } from '../../../../core/models/category.model';
import { type AccountSummary } from '../../../../core/models/account.model';
import { CategoryService } from '../../../../core/services/category';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

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
  category: null as unknown as Category,
  account: null as unknown as AccountSummary,
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

  let libelleServiceMock: {
    search: ReturnType<typeof vi.fn>;
  };

  let categoryServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof signal>;
  };

  let confirmServiceMock: {
    confirm: ReturnType<typeof vi.fn>;
    confirmDelete: ReturnType<typeof vi.fn>;
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

    libelleServiceMock = {
      search: vi.fn().mockReturnValue(of([])),
    };

    categoryServiceMock = {
      getAll: vi.fn().mockReturnValue(of([])),
      refreshTrigger: signal(0),
    };

    confirmServiceMock = {
      confirm: vi.fn().mockResolvedValue(false),
      confirmDelete: vi.fn().mockResolvedValue(false),
    };
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [TransactionForm],
      providers: [
        provideTranslocoTesting(),
        { provide: TransactionService, useValue: transactionServiceMock },
        { provide: RecurringTransactionService, useValue: recurringTransactionServiceMock },
        { provide: TransactionLibelleService, useValue: libelleServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: ConfirmService, useValue: confirmServiceMock },
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

    // Le bouton de récurrence est rendu en mode création (aria-label="Récurrence")
    const toggle = fixture.nativeElement.querySelector('button[aria-label="Récurrence"]');
    expect(toggle).not.toBeNull();
  });

  it('should_hide_recurring_toggle_in_edit_mode', () => {
    // modalService.editingEntity contient une entité et asRecurring = false → mode édition
    modalServiceMock.editingEntity = signal(makeTransaction());
    modalServiceMock.asRecurring = signal(false);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const toggle = fixture.nativeElement.querySelector('button[aria-label="Récurrence"]');
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

  it('should_allow_submission_of_novel_libelle', async () => {
    // T-035 : un libellé inédit (non présent dans les suggestions) doit être accepté
    // et permettre la soumission du formulaire (saisie libre — FR-009, SC-005)
    modalServiceMock.editingEntity = signal(null);
    modalServiceMock.asRecurring = signal(false);
    // Le service de suggestions ne retourne rien pour ce libellé
    libelleServiceMock.search = vi.fn().mockReturnValue(of([]));

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const today = new Date().toISOString().split('T')[0];

    // Saisie d'un libellé inédit, non présent dans les suggestions
    component.form.patchValue({
      libelle: 'Nouveau libellé inédit',
      montant: '25',
      date: today,
    });
    fixture.detectChanges();

    // Le formulaire doit être valide (libellé renseigné, montant valide)
    expect(component.form.get('libelle')!.valid).toBe(true);
    expect(component.form.valid).toBe(true);

    // La soumission doit déclencher la création de la transaction
    await component.onSubmit();

    expect(transactionServiceMock.create).toHaveBeenCalledOnce();
    const callArgs = transactionServiceMock.create.mock.calls[0][0];
    expect(callArgs.libelle).toBe('Nouveau libellé inédit');
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
    expect(component.form.get('montant')!.value).toBe('35.00');
    expect(component.form.get('isRecurring')!.value).toBe(true);
    // Le composant n'est pas en mode édition (asRecurring override isEditing)
    expect(component.isEditing()).toBe(false);
  });

  it('should_insert_created_category_sorted_by_name', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const nouvelle: Category = { id: 'cat-2', nom: 'Alimentation', icone: '🍔', couleur: '#000' };
    component.onCategoryCreated(nouvelle);

    expect(component.categories().map((c) => c.nom)).toContain('Alimentation');
  });

  it('should_delete_transaction_when_confirmed', async () => {
    const existingTransaction = makeTransaction();
    modalServiceMock.editingEntity = signal(existingTransaction);
    confirmServiceMock.confirmDelete.mockResolvedValue(true);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    await fixture.componentInstance.onDelete();

    expect(confirmServiceMock.confirmDelete).toHaveBeenCalled();
    expect(transactionServiceMock.delete).toHaveBeenCalledWith('tx-1');
    expect(modalServiceMock.closeModal).toHaveBeenCalled();
  });

  it('should_not_delete_transaction_when_not_confirmed', async () => {
    const existingTransaction = makeTransaction();
    modalServiceMock.editingEntity = signal(existingTransaction);
    confirmServiceMock.confirmDelete.mockResolvedValue(false);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    await fixture.componentInstance.onDelete();

    expect(transactionServiceMock.delete).not.toHaveBeenCalled();
  });

  it('should_reject_submit_when_amount_is_invalid_despite_form_validity', async () => {
    // Garde-fou defensif de onSubmit (deja present avant KKS-377) : on
    // desactive le controle montant pour l'exclure de la validite du
    // formulaire tout en lui laissant une valeur non numerique.
    modalServiceMock.editingEntity = signal(null);
    modalServiceMock.asRecurring = signal(false);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ libelle: 'Test' });
    component.form.get('montant')!.disable();
    component.form.get('montant')!.setValue('abc');
    fixture.detectChanges();

    await component.onSubmit();

    expect(component.errorMessage()).toBe('Montant invalide');
    expect(transactionServiceMock.create).not.toHaveBeenCalled();
  });

  it('should_set_error_message_when_submit_fails', async () => {
    modalServiceMock.editingEntity = signal(null);
    modalServiceMock.asRecurring = signal(false);
    transactionServiceMock.create = vi.fn().mockReturnValue(throwError(() => 'network down'));

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ libelle: 'Test', montant: '10' });
    fixture.detectChanges();

    await component.onSubmit();

    expect(component.errorMessage()).toBe('Erreur lors de la sauvegarde');
    expect(component.submitting()).toBe(false);
  });

  it('should_include_transfer_counterpart_message_when_deleting_transfer_transaction', async () => {
    const existingTransaction = makeTransaction({ transferId: 'transfer-1' });
    modalServiceMock.editingEntity = signal(existingTransaction);
    confirmServiceMock.confirmDelete.mockResolvedValue(false);

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    await fixture.componentInstance.onDelete();

    const confirmArgs = confirmServiceMock.confirmDelete.mock.calls[0][0];
    expect(confirmArgs.message).toContain('La contrepartie du virement sera aussi supprimée.');
  });

  it('should_set_error_message_when_delete_fails', async () => {
    const existingTransaction = makeTransaction();
    modalServiceMock.editingEntity = signal(existingTransaction);
    confirmServiceMock.confirmDelete.mockResolvedValue(true);
    transactionServiceMock.delete = vi.fn().mockReturnValue(throwError(() => 'server error'));

    setupTestBed();
    const fixture = TestBed.createComponent(TransactionForm);
    fixture.detectChanges();

    await fixture.componentInstance.onDelete();

    expect(fixture.componentInstance.errorMessage()).toBe('Erreur lors de la suppression');
  });
});
