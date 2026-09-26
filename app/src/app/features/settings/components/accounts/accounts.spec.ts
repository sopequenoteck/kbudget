import { TestBed } from '@angular/core/testing';
import { computed, signal } from '@angular/core';
import { provideRouter, Router } from '@angular/router';
import { of, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

import { Accounts } from './accounts';
import { AccountService } from '../../../../core/services/account';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { PreferenceService } from '../../../../core/services/preference';
import { ModalService } from '../../../../core/services/modal.service';
import { DevLogger } from '../../../../core/services/dev-logger';
import { ApiErrorService } from '../../../../core/services/api-error';
import { Account, AccountType } from '../../../../core/models/account.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

const makeAccount = (overrides: Partial<Account> = {}): Account => ({
  id: 'acc-1',
  nom: 'Compte courant',
  type: AccountType.COURANT,
  soldeInitial: 0,
  solde: 100,
  icone: '🏦',
  couleur: '#000000',
  isDefault: false,
  actif: true,
  currency: 'EUR',
  bankCode: 'OTHER',
  bankName: null,
  bankCountry: null,
  bankBrandColor: null,
  bankLogoUrl: null,
  bankCustomName: null,
  bankCustomLogo: null,
  ...overrides,
});

function createAccountServiceMock() {
  return {
    getAll: vi.fn().mockReturnValue(of<Account[]>([])),
    delete: vi.fn().mockReturnValue(of(undefined)),
    setDefault: vi.fn().mockReturnValue(of(makeAccount())),
    refreshTrigger: signal(0),
  };
}

function createPreferenceServiceMock() {
  const currencies = signal(['EUR']);
  return {
    currencies,
    primaryCurrency: computed(() => currencies()[0] ?? 'EUR'),
    language: signal<string | null>(null),
    update: vi.fn(),
  };
}

function createExchangeRateServiceMock() {
  return {
    loadRates: vi.fn().mockResolvedValue(undefined),
    rates: signal([]),
    loading: signal(false),
  };
}

function createModalServiceMock() {
  return { openModal: vi.fn() };
}

function createDevLoggerMock() {
  return { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

function createApiErrorServiceMock() {
  return { label: vi.fn().mockReturnValue('Erreur lors de la suppression') };
}

describe('Accounts', () => {
  let accountServiceMock: ReturnType<typeof createAccountServiceMock>;
  let preferenceServiceMock: ReturnType<typeof createPreferenceServiceMock>;
  let exchangeRateServiceMock: ReturnType<typeof createExchangeRateServiceMock>;
  let modalServiceMock: ReturnType<typeof createModalServiceMock>;
  let devLoggerMock: ReturnType<typeof createDevLoggerMock>;
  let apiErrorServiceMock: ReturnType<typeof createApiErrorServiceMock>;
  let routerMock: { navigate: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    accountServiceMock = createAccountServiceMock();
    preferenceServiceMock = createPreferenceServiceMock();
    exchangeRateServiceMock = createExchangeRateServiceMock();
    modalServiceMock = createModalServiceMock();
    devLoggerMock = createDevLoggerMock();
    apiErrorServiceMock = createApiErrorServiceMock();
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [Accounts],
      providers: [
        ...provideTranslocoTesting(),
        provideRouter([]),
        { provide: AccountService, useValue: accountServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
        { provide: ExchangeRateService, useValue: exchangeRateServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: DevLogger, useValue: devLoggerMock },
        { provide: ApiErrorService, useValue: apiErrorServiceMock },
      ],
    });
    routerMock = { navigate: vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true) };
  };

  const flushAsyncLoad = async (fixture: { detectChanges: () => void }) => {
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();
  };

  const createFixture = async (accounts: Account[] = []) => {
    accountServiceMock.getAll.mockReturnValue(of(accounts));
    setupTestBed();
    const fixture = TestBed.createComponent(Accounts);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    return fixture;
  };

  it('should_create_the_component', async () => {
    const fixture = await createFixture();

    expect(fixture.componentInstance).toBeTruthy();
  });

  // ---------------------------------------------------------------------
  // Chargement — succes / erreur
  // ---------------------------------------------------------------------

  it('should_load_accounts_on_init', async () => {
    const account = makeAccount();
    const fixture = await createFixture([account]);

    expect(fixture.componentInstance.accounts()).toEqual([account]);
    expect(fixture.componentInstance.loading()).toBe(false);
    expect(fixture.componentInstance.error()).toBe(false);
  });

  it('should_set_error_state_when_load_fails', async () => {
    accountServiceMock.getAll.mockReturnValue(throwError(() => new Error('network down')));
    setupTestBed();
    const fixture = TestBed.createComponent(Accounts);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);

    expect(fixture.componentInstance.error()).toBe(true);
    expect(fixture.componentInstance.loading()).toBe(false);
    expect(devLoggerMock.error).toHaveBeenCalled();
  });

  it('should_reload_on_refreshTrigger_change', async () => {
    const fixture = await createFixture([]);
    accountServiceMock.getAll.mockClear();
    accountServiceMock.getAll.mockReturnValue(of([]));

    accountServiceMock.refreshTrigger.update((v: number) => v + 1);
    await flushAsyncLoad(fixture);

    expect(accountServiceMock.getAll).toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------
  // Rendu — textes traduits (en-tete, erreur, etat vide)
  // ---------------------------------------------------------------------

  it('should_render_french_page_title', async () => {
    const fixture = await createFixture([]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.page-header__title')?.textContent?.trim()).toBe('Comptes & Devises');
  });

  it('should_render_french_error_state_labels_when_load_fails', async () => {
    accountServiceMock.getAll.mockReturnValue(throwError(() => new Error('network down')));
    setupTestBed();
    const fixture = TestBed.createComponent(Accounts);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe('Erreur de chargement');
    expect(el.querySelector('.empty-state__cta')?.textContent).toBe('Réessayer');
  });

  it('should_render_french_empty_state_when_no_accounts', async () => {
    const fixture = await createFixture([]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe('Aucun compte');
    expect(el.querySelector('.empty-state__hint')?.textContent).toBe(
      'Créez votre premier compte pour commencer',
    );
    expect(el.querySelector('.empty-state__cta')?.textContent).toBe('Créer un compte');
  });

  it('should_call_create_account_when_empty_state_cta_is_clicked', async () => {
    const fixture = await createFixture([]);
    const cta = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>(
      '.empty-state__cta',
    );
    cta?.click();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('account');
  });

  it('should_render_french_section_count_with_plural', async () => {
    const fixture = await createFixture([makeAccount({ id: 'a1' })]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.accounts-section__label')?.textContent?.trim()).toBe('1 compte');
  });

  it('should_render_french_section_count_plural_for_multiple_accounts', async () => {
    const fixture = await createFixture([
      makeAccount({ id: 'a1' }),
      makeAccount({ id: 'a2' }),
    ]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.accounts-section__label')?.textContent?.trim()).toBe('2 comptes');
  });

  it('should_render_french_default_and_inactive_badges', async () => {
    const fixture = await createFixture([
      makeAccount({ id: 'a1', isDefault: true, actif: true }),
      makeAccount({ id: 'a2', isDefault: false, actif: false }),
    ]);
    const el: HTMLElement = fixture.nativeElement;
    const badges = Array.from(el.querySelectorAll('.account-row__badge')).map((n) =>
      n.textContent?.trim(),
    );

    expect(badges).toEqual(['Défaut', 'Inactif']);
  });

  it('should_render_french_account_type_label_in_subtitle', async () => {
    const fixture = await createFixture([
      makeAccount({ id: 'a1', type: AccountType.COURANT, bankName: null }),
      makeAccount({ id: 'a2', type: AccountType.EPARGNE, bankName: null }),
      makeAccount({ id: 'a3', type: AccountType.ESPECES, bankName: null }),
    ]);
    const el: HTMLElement = fixture.nativeElement;
    const subtitles = Array.from(el.querySelectorAll('.account-row__subtitle')).map((n) =>
      n.textContent?.trim(),
    );

    expect(subtitles).toEqual(['Courant', 'Épargne', 'Espèces']);
  });

  it('should_render_french_account_type_label_with_bank_name_prefix', async () => {
    const fixture = await createFixture([
      makeAccount({ type: AccountType.COURANT, bankName: 'Ma banque' }),
    ]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.account-row__subtitle')?.textContent?.trim()).toBe(
      'Ma banque ·  Courant',
    );
  });

  // ---------------------------------------------------------------------
  // Actions — creation, edition, suppression, defaut, import
  // ---------------------------------------------------------------------

  it('should_open_modal_to_edit_account', async () => {
    const account = makeAccount();
    const fixture = await createFixture([account]);

    fixture.componentInstance.editAccount(account);

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('account', account);
  });

  it('should_set_default_account', async () => {
    const account = makeAccount();
    const fixture = await createFixture([account]);

    await fixture.componentInstance.setDefault(account);

    expect(accountServiceMock.setDefault).toHaveBeenCalledWith(account.id);
  });

  it('should_log_error_when_set_default_fails', async () => {
    accountServiceMock.setDefault.mockReturnValue(throwError(() => new Error('boom')));
    const account = makeAccount();
    const fixture = await createFixture([account]);

    await fixture.componentInstance.setDefault(account);

    expect(devLoggerMock.error).toHaveBeenCalled();
  });

  it('should_show_inline_delete_confirmation_in_french', async () => {
    const account = makeAccount();
    const fixture = await createFixture([account]);

    fixture.componentInstance.requestDelete(account.id);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.account-row__confirm p')?.textContent).toBe('Supprimer ce compte ?');
    expect(el.querySelector('.btn-cancel')?.textContent).toBe('Annuler');
    expect(el.querySelector('.btn-delete')?.textContent).toBe('Supprimer');
  });

  it('should_cancel_delete_confirmation', async () => {
    const account = makeAccount();
    const fixture = await createFixture([account]);

    fixture.componentInstance.requestDelete(account.id);
    fixture.componentInstance.cancelDelete();

    expect(fixture.componentInstance.confirmDeleteId()).toBeNull();
    expect(fixture.componentInstance.deleteError()).toBeNull();
  });

  it('should_delete_account_when_confirmed', async () => {
    const account = makeAccount();
    const fixture = await createFixture([account]);

    fixture.componentInstance.requestDelete(account.id);
    await fixture.componentInstance.confirmDelete();

    expect(accountServiceMock.delete).toHaveBeenCalledWith(account.id);
    expect(fixture.componentInstance.confirmDeleteId()).toBeNull();
  });

  it('should_do_nothing_when_confirming_delete_without_a_pending_id', async () => {
    const fixture = await createFixture([]);

    await fixture.componentInstance.confirmDelete();

    expect(accountServiceMock.delete).not.toHaveBeenCalled();
  });

  it('should_set_translated_delete_error_when_delete_fails', async () => {
    const httpError = new HttpErrorResponse({ status: 500 });
    accountServiceMock.delete.mockReturnValue(throwError(() => httpError));
    apiErrorServiceMock.label.mockReturnValue('Erreur lors de la suppression');
    const account = makeAccount();
    const fixture = await createFixture([account]);

    fixture.componentInstance.requestDelete(account.id);
    await fixture.componentInstance.confirmDelete();

    expect(apiErrorServiceMock.label).toHaveBeenCalledWith(httpError, 'Erreur lors de la suppression');
    expect(fixture.componentInstance.deleteError()).toBe('Erreur lors de la suppression');
    expect(devLoggerMock.error).toHaveBeenCalled();
  });

  it('should_navigate_to_import_with_account_id', async () => {
    const account = makeAccount();
    const fixture = await createFixture([account]);

    fixture.componentInstance.triggerImport(account.id);

    expect(routerMock.navigate).toHaveBeenCalledWith(['/settings/import'], {
      queryParams: { accountId: account.id },
    });
  });

  // ---------------------------------------------------------------------
  // Devises — synchronisation avec les preferences
  // ---------------------------------------------------------------------

  it('should_sync_currencies_from_preferences', async () => {
    preferenceServiceMock.currencies.set(['EUR', 'USD']);
    const fixture = await createFixture([]);

    expect(fixture.componentInstance.currencies()).toEqual(['EUR', 'USD']);
  });

  it('should_update_currencies_and_persist_preferences', async () => {
    const fixture = await createFixture([]);

    fixture.componentInstance.onCurrenciesChange(['EUR', 'GBP']);

    expect(fixture.componentInstance.currencies()).toEqual(['EUR', 'GBP']);
    expect(preferenceServiceMock.update).toHaveBeenCalledWith({ currencies: ['EUR', 'GBP'] });
  });
});
