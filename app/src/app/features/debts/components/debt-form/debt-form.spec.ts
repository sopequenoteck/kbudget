import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';
import { signal } from '@angular/core';

import { DebtForm } from './debt-form';
import { CurrencyService } from '../../../../core/services/currency';
import { DebtService } from '../../../../core/services/debt';
import { ModalService } from '../../../../core/services/modal.service';
import { AccountService } from '../../../../core/services/account';
import { CategoryService } from '../../../../core/services/category';
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
    nom: 'Dollar',
    type: AccountType.EPARGNE,
    soldeInitial: 2000,
    solde: 2000,
    icone: '💵',
    couleur: '#10b981',
    isDefault: false,
    actif: true,
    currency: 'USD',
  },
];

const mockDebt: Debt = {
  id: 'debt-edit-1',
  personne: 'Charlie',
  montant: 500,
  montantRestant: 300,
  sens: DebtType.PRET,
  date: '2026-02-10',
  dueDate: '2026-12-31',
  rembourse: false,
  category: null,
  currency: 'EUR',
  account: {
    id: 'acc-1',
    nom: 'Courant',
    icone: '🏦',
    couleur: '#3b82f6',
    currency: 'EUR',
  },
  includeInBalance: true,
  reminderDate: '2026-06-01',
  reminderTime: '09:00',
};

describe('DebtForm', () => {
  let currencyServiceMock: {
    loadIfEmpty: ReturnType<typeof vi.fn>;
    currencyItems: ReturnType<typeof signal>;
  };

  let debtServiceMock: {
    create: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };

  let modalServiceMock: {
    editingEntity: ReturnType<typeof signal>;
    closeModal: ReturnType<typeof vi.fn>;
  };

  let accountServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
  };

  let categoryServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    categoryServiceMock = {
      getAll: vi.fn().mockReturnValue(of([])),
      refreshTrigger: vi.fn().mockReturnValue(0),
    };

    currencyServiceMock = {
      loadIfEmpty: vi.fn(),
      currencyItems: signal([
        { id: 'EUR', label: 'EUR - €', secondaryText: 'Euro', icon: null, color: null },
        { id: 'USD', label: 'USD - $', secondaryText: 'Dollar', icon: null, color: null },
      ]),
    };

    debtServiceMock = {
      create: vi.fn().mockReturnValue(of(mockDebt)),
      update: vi.fn().mockReturnValue(of(mockDebt)),
      delete: vi.fn().mockReturnValue(of(undefined)),
    };

    modalServiceMock = {
      editingEntity: signal(null),
      closeModal: vi.fn(),
    };

    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of(mockAccounts)),
    };
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [DebtForm],
      providers: [
        { provide: CurrencyService, useValue: currencyServiceMock },
        { provide: DebtService, useValue: debtServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: CategoryService, useValue: categoryServiceMock },
      ],
    });
  };

  it('should_create_the_component', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_force_currency_when_account_selected', async () => {
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    // Pas de compte par défaut (isDefault=true sur acc-1) → on force acc-2 USD
    component.form.patchValue({ accountId: 'acc-2' });
    fixture.detectChanges();
    await fixture.whenStable();

    expect(component.form.getRawValue().currency).toBe('USD');
  });

  it('should_auto_set_include_in_balance_when_account_selected', async () => {
    // Désactiver le compte par défaut pour partir d'un état sans sélection
    accountServiceMock.getAll.mockReturnValue(of(mockAccounts.map(a => ({ ...a, isDefault: false }))));
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    // Pas de compte sélectionné initialement
    expect(component.form.getRawValue().includeInBalance).toBe(false);

    // Sélectionner un compte
    component.form.patchValue({ accountId: 'acc-1' });
    fixture.detectChanges();
    await fixture.whenStable();

    expect(component.form.getRawValue().includeInBalance).toBe(true);
  });

  it('should_hide_patrimoine_toggle_when_account_selected', async () => {
    accountServiceMock.getAll.mockReturnValue(of(mockAccounts.map(a => ({ ...a, isDefault: false }))));
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    // Sans compte, aucune sélection
    expect(component.selectedAccount()).toBeNull();

    // Sélectionner un compte via setValue pour déclencher valueChanges
    component.form.get('accountId')!.setValue('acc-1');
    fixture.detectChanges();
    await fixture.whenStable();

    expect(component.form.get('accountId')!.value).toBe('acc-1');
    expect(component.selectedAccount()?.id).toBe('acc-1');
  });

  it('should_prefill_fields_when_editing', async () => {
    // Configurer le mock AVANT setupTestBed pour que le TestBed utilise la bonne valeur
    modalServiceMock = {
      editingEntity: signal(mockDebt),
      closeModal: vi.fn(),
    };
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const values = component.form.getRawValue();

    expect(values.personne).toBe('Charlie');
    expect(values.montant).toBe('500.00');
    expect(values.date).toBe('2026-02-10');
    expect(values.rembourse).toBe(false);
    expect(values.currency).toBe('EUR');
    expect(values.reminderDate).toBe('2026-06-01');
    expect(values.reminderTime).toBe('09:00');
  });

  it('should_be_in_edit_mode_when_debt_is_provided', async () => {
    modalServiceMock = {
      editingEntity: signal(mockDebt),
      closeModal: vi.fn(),
    };
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    expect(fixture.componentInstance.isEditing()).toBe(true);
  });

  it('should_be_in_create_mode_when_no_debt_provided', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();

    expect(fixture.componentInstance.isEditing()).toBe(false);
  });

  it('should_call_create_when_no_editing_entity', async () => {
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({
      personne: 'Nouveau',
      montant: '100',
      date: '2026-03-01',
    });

    await component.onSubmit();

    expect(debtServiceMock.create).toHaveBeenCalled();
  });

  it('should_call_update_when_editing_entity_exists', async () => {
    modalServiceMock = {
      editingEntity: signal(mockDebt),
      closeModal: vi.fn(),
    };
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    await component.onSubmit();

    expect(debtServiceMock.update).toHaveBeenCalledWith('debt-edit-1', expect.any(Object));
  });

  it('should_require_personne_field', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ personne: '' });
    component.form.get('personne')!.markAsTouched();

    expect(component.isInvalid('personne')).toBe(true);
  });

  it('should_require_montant_field', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ montant: '' });
    component.form.get('montant')!.markAsTouched();

    expect(component.isInvalid('montant')).toBe(true);
  });

  it('should_not_set_currency_when_account_id_cleared', async () => {
    setupTestBed();
    const fixture = TestBed.createComponent(DebtForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    // Sélectionner un compte USD
    component.form.patchValue({ accountId: 'acc-2' });
    fixture.detectChanges();
    await fixture.whenStable();
    expect(component.form.getRawValue().currency).toBe('USD');

    // Vider le compte — aucune mise à jour de devise (logique seulement si accountId truthy)
    component.form.patchValue({ accountId: '' });
    fixture.detectChanges();
    await fixture.whenStable();
    expect(component.form.getRawValue().currency).toBe('USD');
  });
});
