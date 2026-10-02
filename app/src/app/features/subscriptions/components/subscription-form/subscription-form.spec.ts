import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { signal } from '@angular/core';

import { SubscriptionForm } from './subscription-form';
import { CurrencyService } from '../../../../core/services/currency';
import { SubscriptionService } from '../../../../core/services/subscription';
import { ModalService } from '../../../../core/services/modal.service';
import { AccountService } from '../../../../core/services/account';
import { CategoryService } from '../../../../core/services/category';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { Frequency, Subscription } from '../../../../core/models/subscription.model';
import { Category } from '../../../../core/models/category.model';
import { Account, AccountType } from '../../../../core/models/account.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

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

const mockSubscription: Subscription = {
  id: 'sub-edit-1',
  nom: 'Netflix',
  montant: 15.99,
  frequence: Frequency.ANNUEL,
  dateDebut: '2026-02-10',
  actif: true,
  category: null,
  account: {
    id: 'acc-1',
    nom: 'Courant',
    icone: '🏦',
    couleur: '#3b82f6',
    currency: 'EUR',
  },
  currency: 'EUR',
};

describe('SubscriptionForm', () => {
  let currencyServiceMock: {
    loadIfEmpty: ReturnType<typeof vi.fn>;
    currencyItems: ReturnType<typeof signal>;
  };

  let subscriptionServiceMock: {
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

  let confirmServiceMock: {
    confirm: ReturnType<typeof vi.fn>;
    confirmDelete: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    confirmServiceMock = {
      confirm: vi.fn().mockResolvedValue(true),
      confirmDelete: vi.fn().mockResolvedValue(true),
    };

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

    subscriptionServiceMock = {
      create: vi.fn().mockReturnValue(of(mockSubscription)),
      update: vi.fn().mockReturnValue(of(mockSubscription)),
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
      imports: [SubscriptionForm],
      providers: [
        provideTranslocoTesting(),
        { provide: CurrencyService, useValue: currencyServiceMock },
        { provide: SubscriptionService, useValue: subscriptionServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: ConfirmService, useValue: confirmServiceMock },
      ],
    });
  };

  it('should_create_the_component', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_display_the_translated_name_when_selected_category_is_a_system_category', () => {
    // Assert — `nom` volontairement different de la traduction pour prouver
    // que l'affichage ne depend plus du `nom` brut cote serveur (KKS-395).
    const systemCategory: Category = {
      id: 'sys-1',
      nom: 'Abonnement-legacy',
      icone: '🔄',
      couleur: '#000000',
      isSystem: true,
      systemKey: 'SUBSCRIPTION',
    };
    categoryServiceMock.getAll.mockReturnValue(of([systemCategory]));

    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    fixture.componentInstance.form.patchValue({ categoryId: 'sys-1' });
    fixture.detectChanges();

    const pill = fixture.nativeElement.querySelector('button[aria-label="Catégorie"] span');
    expect(pill.textContent.trim()).toBe('Abonnement');
  });

  it('should_force_currency_when_account_selected', async () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ accountId: 'acc-2' });
    fixture.detectChanges();
    await fixture.whenStable();

    expect(component.selectedAccount()?.currency).toBe('USD');
  });

  it('should_prefill_fields_when_editing', async () => {
    modalServiceMock = {
      editingEntity: signal(mockSubscription),
      closeModal: vi.fn(),
    };
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const values = component.form.getRawValue();

    expect(values.nom).toBe('Netflix');
    expect(values.montant).toBe('15.99');
    expect(values.dateDebut).toBe('2026-02-10');
    expect(values.actif).toBe(true);
    expect(values.accountId).toBe('acc-1');
  });

  it('should_be_in_edit_mode_when_subscription_is_provided', async () => {
    modalServiceMock = {
      editingEntity: signal(mockSubscription),
      closeModal: vi.fn(),
    };
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    expect(fixture.componentInstance.isEditing()).toBe(true);
  });

  it('should_be_in_create_mode_when_no_subscription_provided', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();

    expect(fixture.componentInstance.isEditing()).toBe(false);
  });

  it('should_call_create_when_no_editing_entity', async () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({
      nom: 'Spotify',
      montant: '9.99',
      dateDebut: '2026-03-01',
    });

    await component.onSubmit();

    expect(subscriptionServiceMock.create).toHaveBeenCalled();
  });

  it('should_call_update_when_editing_entity_exists', async () => {
    modalServiceMock = {
      editingEntity: signal(mockSubscription),
      closeModal: vi.fn(),
    };
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;
    await component.onSubmit();

    expect(subscriptionServiceMock.update).toHaveBeenCalledWith('sub-edit-1', expect.any(Object));
  });

  it('should_require_nom_field', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: '' });
    component.form.get('nom')!.markAsTouched();

    expect(component.isInvalid('nom')).toBe(true);
  });

  it('should_require_montant_field', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ montant: '' });
    component.form.get('montant')!.markAsTouched();

    expect(component.isInvalid('montant')).toBe(true);
  });

  it('should_insert_created_category_sorted_by_name', async () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    const nouvelle: Category = { id: 'cat-2', nom: 'Loisirs', icone: '🎮', couleur: '#000', isSystem: false };
    component.onCategoryCreated(nouvelle);

    expect(component.categories().map((c) => c.nom)).toContain('Loisirs');
  });

  it('should_delete_subscription_when_confirmed', async () => {
    modalServiceMock = {
      editingEntity: signal(mockSubscription),
      closeModal: vi.fn(),
    };
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    await fixture.componentInstance.onDelete();

    expect(confirmServiceMock.confirmDelete).toHaveBeenCalled();
    expect(subscriptionServiceMock.delete).toHaveBeenCalledWith('sub-edit-1');
    expect(modalServiceMock.closeModal).toHaveBeenCalled();
  });

  it('should_not_delete_subscription_when_not_confirmed', async () => {
    modalServiceMock = {
      editingEntity: signal(mockSubscription),
      closeModal: vi.fn(),
    };
    confirmServiceMock.confirmDelete.mockResolvedValue(false);
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    await fixture.componentInstance.onDelete();

    expect(subscriptionServiceMock.delete).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------
  // Traduction — montant invalide + repli sur erreur non standard
  // ---------------------------------------------------------------------

  it('should_set_translated_invalid_amount_message_when_amount_parses_to_nan', async () => {
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: 'Spotify', dateDebut: '2026-03-01' });
    // Le montant desactive echappe a decimalMin (exclu de form.invalid) mais
    // reste dans getRawValue(), ce qui declenche la verification manuelle.
    component.form.get('montant')!.disable();
    component.form.get('montant')!.setValue('abc');

    await component.onSubmit();

    expect(component.errorMessage()).toBe('Montant invalide');
    expect(subscriptionServiceMock.create).not.toHaveBeenCalled();
  });

  it('should_fallback_to_translated_save_error_when_thrown_value_is_not_an_error', async () => {
    subscriptionServiceMock.create.mockReturnValue(throwError(() => 'boom'));
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: 'Spotify', montant: '9.99', dateDebut: '2026-03-01' });

    await component.onSubmit();

    expect(component.errorMessage()).toBe('Erreur lors de la sauvegarde');
  });

  it('should_fallback_to_translated_delete_error_when_thrown_value_is_not_an_error', async () => {
    modalServiceMock = {
      editingEntity: signal(mockSubscription),
      closeModal: vi.fn(),
    };
    subscriptionServiceMock.delete.mockReturnValue(throwError(() => 'boom'));
    setupTestBed();
    const fixture = TestBed.createComponent(SubscriptionForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    await fixture.componentInstance.onDelete();

    expect(fixture.componentInstance.errorMessage()).toBe('Erreur lors de la suppression');
  });
});
