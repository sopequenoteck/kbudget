import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { of } from 'rxjs';

import { AccountForm } from './account-form';
import { AccountService } from '../../../core/services/account';
import { BankService } from '../../../core/services/bank';
import { CurrencyService } from '../../../core/services/currency';
import { ExchangeRateService } from '../../../core/services/exchange-rate';
import { PreferenceService } from '../../../core/services/preference';
import { ModalService } from '../../../core/services/modal.service';
import { Account, AccountType } from '../../../core/models/account.model';
import { BankResponse } from '../../../core/models/bank.model';

const MOCK_BANKS: BankResponse[] = [
  { code: 'SG', name: 'Société Générale', country: 'FR', brandColor: '#e2001a', logoUrl: '/api/bank-logos/sg.svg' },
  { code: 'OTHER', name: 'Autre', country: null, brandColor: null, logoUrl: null },
];

const mockAccount: Account = {
  id: '1',
  nom: 'Test',
  type: AccountType.COURANT,
  soldeInitial: 0,
  solde: 100,
  icone: '🏦',
  couleur: '#e2001a',
  isDefault: false,
  actif: true,
  currency: 'EUR',
  bankCode: 'SG',
  bankName: 'Société Générale',
  bankCountry: 'FR',
  bankBrandColor: '#e2001a',
  bankLogoUrl: '/api/bank-logos/sg.svg',
  bankCustomName: null,
  bankCustomLogo: null,
};

describe('AccountForm', () => {
  let accountServiceMock: {
    create: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
    adjustBalance: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof signal<number>>;
  };

  let bankServiceMock: {
    banks: ReturnType<typeof signal<BankResponse[]>>;
    error: ReturnType<typeof signal<string | null>>;
    loadBanks: ReturnType<typeof vi.fn>;
    getBankByCode: ReturnType<typeof vi.fn>;
    getBankLogoUrl: ReturnType<typeof vi.fn>;
  };

  let currencyServiceMock: {
    currencyItems: ReturnType<typeof signal<unknown[]>>;
    loadIfEmpty: ReturnType<typeof vi.fn>;
  };

  let exchangeRateServiceMock: {
    rates: ReturnType<typeof signal<unknown[]>>;
    upsert: ReturnType<typeof vi.fn>;
  };

  let preferenceServiceMock: {
    primaryCurrency: ReturnType<typeof signal<string>>;
  };

  let modalServiceMock: {
    editingEntity: ReturnType<typeof signal<Account | null>>;
    closeModal: ReturnType<typeof vi.fn>;
    openModal: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    accountServiceMock = {
      create: vi.fn().mockReturnValue(of({ id: '1' })),
      update: vi.fn().mockReturnValue(of({ id: '1' })),
      adjustBalance: vi.fn().mockReturnValue(of({})),
      delete: vi.fn().mockReturnValue(of({})),
      refreshTrigger: signal(0),
    };

    bankServiceMock = {
      banks: signal(MOCK_BANKS),
      error: signal(null),
      loadBanks: vi.fn().mockResolvedValue(undefined),
      getBankByCode: vi.fn((code: string) => MOCK_BANKS.find((b) => b.code === code)),
      getBankLogoUrl: vi.fn((code: string) => MOCK_BANKS.find((b) => b.code === code)?.logoUrl ?? null),
    };

    currencyServiceMock = {
      currencyItems: signal([]),
      loadIfEmpty: vi.fn(),
    };

    exchangeRateServiceMock = {
      rates: signal([]),
      upsert: vi.fn().mockReturnValue(of({})),
    };

    preferenceServiceMock = {
      primaryCurrency: signal('EUR'),
    };

    modalServiceMock = {
      editingEntity: signal<Account | null>(null),
      closeModal: vi.fn(),
      openModal: vi.fn(),
    };

    TestBed.configureTestingModule({
      imports: [AccountForm],
      providers: [
        { provide: AccountService, useValue: accountServiceMock },
        { provide: BankService, useValue: bankServiceMock },
        { provide: CurrencyService, useValue: currencyServiceMock },
        { provide: ExchangeRateService, useValue: exchangeRateServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
      ],
    });
  });

  it('should_create_the_component', () => {
    const fixture = TestBed.createComponent(AccountForm);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_hide_icon_color_when_known_bank_selected', async () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;

    // Sync both the child CVA (so its isKnownBank signal fires) and the parent handler
    const bankSelectRef = component.bankSelectRef();
    expect(bankSelectRef).toBeTruthy();
    bankSelectRef!.writeValue('SG');
    component.onBankCodeChange('SG');

    fixture.detectChanges();
    await fixture.whenStable();

    // isKnownBank on the form is derived from bankSelectRef().isKnownBank()
    expect(component.isKnownBank()).toBe(true);

    // The personalisation section (emoji/color) must be absent from the DOM
    const allLegends: HTMLElement[] = Array.from(
      fixture.nativeElement.querySelectorAll('.account-form__section legend'),
    );
    const personnalisationLegend = allLegends.find((el) => el.textContent?.includes('Personnalisation'));
    expect(personnalisationLegend).toBeFalsy();
  });

  it('should_show_icon_color_when_other_selected', async () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const bankSelectRef = component.bankSelectRef();
    expect(bankSelectRef).toBeTruthy();

    // Ensure OTHER is selected (default)
    bankSelectRef!.writeValue('OTHER');
    fixture.detectChanges();
    await fixture.whenStable();

    expect(component.isKnownBank()).toBe(false);

    // The personalisation section (emoji/color) must be present in the DOM
    const allLegends: HTMLElement[] = Array.from(
      fixture.nativeElement.querySelectorAll('.account-form__section legend'),
    );
    const personnalisationLegend = allLegends.find((el) => el.textContent?.includes('Personnalisation'));
    expect(personnalisationLegend).toBeTruthy();
  });

  it('should_populate_bank_select_in_edit_mode', async () => {
    // Set editing entity BEFORE creating the component so the effect fires on init
    modalServiceMock.editingEntity.set(mockAccount);

    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;

    // The effect should have called selectedBankCode.set('SG')
    expect(component.selectedBankCode()).toBe('SG');

    // The form fields should also be pre-filled
    expect(component.form.getRawValue().nom).toBe('Test');
    expect(component.isEditMode()).toBe(true);
  });

  it('should_include_bank_fields_in_request_when_known_bank', async () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;

    // Select a known bank via onBankCodeChange (mimicking user selecting SG)
    component.onBankCodeChange('SG');

    // Fill required form fields
    component.form.patchValue({ nom: 'Mon Compte SG' });

    await component.onSubmit();

    expect(accountServiceMock.create).toHaveBeenCalledTimes(1);

    const [request] = accountServiceMock.create.mock.calls[0] as [Parameters<typeof accountServiceMock.create>[0]];
    expect(request.bankCode).toBe('SG');
    // When a known bank is selected, bankCustomName and bankCustomLogo must not be set
    expect(request.bankCustomName).toBeUndefined();
    expect(request.bankCustomLogo).toBeUndefined();
  });

  it('should_include_bank_fields_in_request_when_other_with_custom_name', async () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;

    // OTHER is the default; set a custom bank name
    component.onBankCodeChange('OTHER');
    component.onBankCustomNameChange('Ma banque perso');
    component.form.patchValue({ nom: 'Compte perso' });

    await component.onSubmit();

    expect(accountServiceMock.create).toHaveBeenCalledTimes(1);

    const [request] = accountServiceMock.create.mock.calls[0] as [Parameters<typeof accountServiceMock.create>[0]];
    expect(request.bankCode).toBe('OTHER');
    expect(request.bankCustomName).toBe('Ma banque perso');
    expect(request.bankCustomLogo).toBeUndefined();
  });

  it('should_not_submit_when_nom_is_empty', async () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: '' });

    await component.onSubmit();

    expect(accountServiceMock.create).not.toHaveBeenCalled();
    expect(component.form.get('nom')?.touched).toBe(true);
  });

  it('should_call_update_with_bank_fields_in_edit_mode', async () => {
    modalServiceMock.editingEntity.set(mockAccount);

    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const component = fixture.componentInstance;

    await component.onSubmit();

    expect(accountServiceMock.update).toHaveBeenCalledTimes(1);

    const [, request] = accountServiceMock.update.mock.calls[0] as [
      string,
      Parameters<typeof accountServiceMock.update>[1],
    ];
    expect(request.bankCode).toBe('SG');
    expect(request.bankCustomName).toBeUndefined();
    expect(request.bankCustomLogo).toBeUndefined();
  });

  it('should_set_selected_bank_code_to_OTHER_by_default', () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    expect(fixture.componentInstance.selectedBankCode()).toBe('OTHER');
  });

  it('should_update_color_when_known_bank_selected', () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.onBankCodeChange('SG');

    // BankService.getBankByCode('SG') returns brandColor '#e2001a'
    expect(component.selectedColor()).toBe('#e2001a');
    expect(component.form.getRawValue().couleur).toBe('#e2001a');
  });

  it('should_close_modal_after_successful_create', async () => {
    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: 'Nouveau compte' });

    await component.onSubmit();

    expect(modalServiceMock.closeModal).toHaveBeenCalledTimes(1);
  });

  it('should_display_error_message_on_save_failure', async () => {
    accountServiceMock.create.mockReturnValue({
      subscribe: (obs: { error: (e: Error) => void }) => obs.error(new Error('Erreur réseau')),
    });

    const fixture = TestBed.createComponent(AccountForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: 'Compte' });

    await component.onSubmit();

    expect(component.errorMessage()).toBeTruthy();
  });
});
