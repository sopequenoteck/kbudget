import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { TransferForm } from './transfer-form';
import { AccountService } from '../../../core/services/account';
import { TransactionService } from '../../../core/services/transaction';
import { ModalService } from '../../../core/services/modal.service';
import { PreferenceService } from '../../../core/services/preference';
import { Account, AccountType } from '../../../core/models/account.model';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

async function flushMicrotasks(): Promise<void> {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
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

  let transactionServiceMock: {
    refreshTrigger: { update: ReturnType<typeof vi.fn> };
  };

  let modalServiceMock: {
    closeModal: ReturnType<typeof vi.fn>;
    editingEntity: ReturnType<typeof vi.fn>;
    activeModal: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of(mockAccounts)),
      transfer: vi.fn(),
      refreshTrigger: vi.fn().mockReturnValue(0),
    };

    transactionServiceMock = {
      refreshTrigger: { update: vi.fn() },
    };

    modalServiceMock = {
      closeModal: vi.fn(),
      editingEntity: vi.fn().mockReturnValue(null),
      activeModal: vi.fn().mockReturnValue(null),
    };

    TestBed.configureTestingModule({
      imports: [TransferForm],
      providers: [
        provideTranslocoTesting(),
        { provide: AccountService, useValue: accountServiceMock },
        { provide: TransactionService, useValue: transactionServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
      ],
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

  it('should_compose_transfer_labels_with_account_names_when_submitted', async () => {
    accountServiceMock.transfer.mockReturnValue(of({}));

    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-2',
      montant: '100',
    });

    await component.onSubmit();

    expect(accountServiceMock.transfer).toHaveBeenCalledWith({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-2',
      montant: 100,
      note: undefined,
      libelleDebit: 'Virement vers Épargne',
      libelleCredit: 'Virement depuis Courant',
    });
  });

  it('should_translate_transfer_labels_when_language_switches_to_en', async () => {
    accountServiceMock.transfer.mockReturnValue(of({}));

    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const preferenceService = TestBed.inject(PreferenceService);
    preferenceService.language.set('en');
    fixture.detectChanges();
    await flushMicrotasks();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-2',
      montant: '100',
    });

    await component.onSubmit();

    expect(accountServiceMock.transfer).toHaveBeenCalledWith({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-2',
      montant: 100,
      note: undefined,
      libelleDebit: 'Transfer to Épargne',
      libelleCredit: 'Transfer from Courant',
    });
  });

  it('should_omit_debit_label_when_destination_account_is_no_longer_active', async () => {
    accountServiceMock.transfer.mockReturnValue(of({}));

    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    // acc-stale n'existe plus dans activeAccounts() (compte desactive ou
    // supprime entre le chargement du formulaire et la soumission) :
    // `toAccount` reste `undefined`, branche `: undefined` du ternaire.
    component.form.patchValue({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-stale',
      montant: '100',
    });

    await component.onSubmit();

    expect(accountServiceMock.transfer).toHaveBeenCalledWith({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-stale',
      montant: 100,
      note: undefined,
      libelleDebit: undefined,
      libelleCredit: 'Virement depuis Courant',
    });
  });

  it('should_omit_credit_label_when_source_account_is_no_longer_active', async () => {
    accountServiceMock.transfer.mockReturnValue(of({}));

    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    // Symetrique au cas precedent, sur le compte source : `fromAccount`
    // reste `undefined`, branche `: undefined` de l'autre ternaire.
    component.form.patchValue({
      fromAccountId: 'acc-stale',
      toAccountId: 'acc-2',
      montant: '100',
    });

    await component.onSubmit();

    expect(accountServiceMock.transfer).toHaveBeenCalledWith({
      fromAccountId: 'acc-stale',
      toAccountId: 'acc-2',
      montant: 100,
      note: undefined,
      libelleDebit: 'Virement vers Épargne',
      libelleCredit: undefined,
    });
  });

  it('should_show_french_fallback_message_when_transfer_fails_without_known_code', async () => {
    const { throwError } = await import('rxjs');
    accountServiceMock.transfer = vi.fn().mockReturnValue(throwError(() => new Error('Network error')));

    const fixture = TestBed.createComponent(TransferForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({
      fromAccountId: 'acc-1',
      toAccountId: 'acc-2',
      montant: '100',
    });

    await component.onSubmit();

    expect(component.errorMessage()).toBe('Erreur lors du virement');
  });
});
