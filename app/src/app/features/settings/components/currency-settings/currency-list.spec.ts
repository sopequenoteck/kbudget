import { TestBed } from '@angular/core/testing';

import { CurrencyList } from './currency-list';
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

describe('CurrencyList', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [CurrencyList],
      providers: [...provideTranslocoTesting()],
    });
  });

  const createFixture = (currencies: string[] = ['EUR'], accounts: Account[] = []) => {
    const fixture = TestBed.createComponent(CurrencyList);
    fixture.componentRef.setInput('currencies', currencies);
    fixture.componentRef.setInput('accounts', accounts);
    fixture.detectChanges();
    return fixture;
  };

  it('should_create_the_component', () => {
    const fixture = createFixture();
    expect(fixture.componentInstance).toBeTruthy();
  });

  // ---------------------------------------------------------------------
  // Rendu — textes traduits
  // ---------------------------------------------------------------------

  it('should_render_french_section_title', () => {
    const fixture = createFixture();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.settings-section__title')?.textContent).toBe('Mes devises');
  });

  it('should_render_french_primary_badge_on_first_currency', () => {
    const fixture = createFixture(['EUR', 'USD']);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.currency-item__badge')?.textContent).toBe('Principale');
  });

  it('should_render_french_remove_currency_aria_label_for_non_primary_currencies', () => {
    const fixture = createFixture(['EUR', 'USD']);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.btn-action--danger')?.getAttribute('aria-label')).toBe(
      'Supprimer cette devise',
    );
  });

  it('should_not_show_a_remove_button_for_the_only_currency', () => {
    const fixture = createFixture(['EUR']);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.btn-action--danger')).toBeNull();
  });

  it('should_render_french_add_currency_dialog_title', () => {
    const fixture = createFixture(['EUR']);
    fixture.componentInstance.showAddSheet.set(true);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.dialog__title')?.textContent).toBe('Ajouter une devise');
  });

  it('should_render_french_remove_warning_dialog_with_currency_name_interpolated', () => {
    const fixture = createFixture(['EUR', 'USD'], [makeAccount({ currency: 'USD', actif: true })]);
    fixture.componentInstance.removeCurrency('USD');
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.dialog__message')?.innerHTML).toContain('<strong>Dollar US</strong>');
    expect(el.querySelector('.dialog__message')?.textContent).toBe(
      'La devise Dollar US est utilisée par des comptes existants. Retirer quand même ?',
    );
  });

  it('should_escape_an_unknown_currency_code_injected_in_the_removal_message', () => {
    const fixture = createFixture(['EUR']);
    fixture.componentInstance.currencyToRemove.set('<img src=x>');
    fixture.componentInstance.showRemoveWarning.set(true);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.dialog__message img')).toBeNull();
    expect(el.querySelector('.dialog__message')?.textContent).toBe(
      'La devise <img src=x> est utilisée par des comptes existants. Retirer quand même ?',
    );
  });

  it('should_render_french_cancel_and_remove_buttons_in_warning_dialog', () => {
    const fixture = createFixture(['EUR', 'USD'], [makeAccount({ currency: 'USD', actif: true })]);
    fixture.componentInstance.removeCurrency('USD');
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;
    const buttons = Array.from(el.querySelectorAll('.dialog__actions .btn')).map((n) =>
      n.textContent?.trim(),
    );

    expect(buttons).toEqual(['Annuler', 'Retirer']);
  });

  // ---------------------------------------------------------------------
  // Ordre — glisser-deposer
  // ---------------------------------------------------------------------

  it('should_emit_reordered_currencies_on_drop', () => {
    const fixture = createFixture(['EUR', 'USD', 'GBP']);
    const emitted: string[][] = [];
    fixture.componentInstance.currenciesChange.subscribe((v) => emitted.push(v));

    fixture.componentInstance.onDrop({
      previousIndex: 0,
      currentIndex: 2,
    } as never);

    expect(emitted).toEqual([['USD', 'GBP', 'EUR']]);
  });

  // ---------------------------------------------------------------------
  // Ajout de devise
  // ---------------------------------------------------------------------

  it('should_compute_available_currencies_to_add', () => {
    const fixture = createFixture(['EUR', 'USD']);

    expect(fixture.componentInstance.availableCurrenciesToAdd()).toEqual([
      'XOF',
      'GBP',
      'CHF',
      'CAD',
      'MAD',
    ]);
  });

  it('should_emit_updated_currencies_when_adding_a_currency', () => {
    const fixture = createFixture(['EUR']);
    const emitted: string[][] = [];
    fixture.componentInstance.currenciesChange.subscribe((v) => emitted.push(v));

    fixture.componentInstance.addCurrency('USD');

    expect(emitted).toEqual([['EUR', 'USD']]);
  });

  it('should_do_nothing_when_adding_an_empty_currency', () => {
    const fixture = createFixture(['EUR']);
    const emitted: string[][] = [];
    fixture.componentInstance.currenciesChange.subscribe((v) => emitted.push(v));

    fixture.componentInstance.addCurrency('');

    expect(emitted).toEqual([]);
  });

  // ---------------------------------------------------------------------
  // Retrait de devise
  // ---------------------------------------------------------------------

  it('should_do_nothing_when_removing_the_only_currency', () => {
    const fixture = createFixture(['EUR']);
    const emitted: string[][] = [];
    fixture.componentInstance.currenciesChange.subscribe((v) => emitted.push(v));

    fixture.componentInstance.removeCurrency('EUR');

    expect(emitted).toEqual([]);
  });

  it('should_do_nothing_when_removing_the_primary_currency', () => {
    const fixture = createFixture(['EUR', 'USD']);
    const emitted: string[][] = [];
    fixture.componentInstance.currenciesChange.subscribe((v) => emitted.push(v));

    fixture.componentInstance.removeCurrency('EUR');

    expect(emitted).toEqual([]);
    expect(fixture.componentInstance.showRemoveWarning()).toBe(false);
  });

  it('should_show_warning_when_removing_a_currency_used_by_an_active_account', () => {
    const fixture = createFixture(
      ['EUR', 'USD'],
      [makeAccount({ currency: 'USD', actif: true })],
    );

    fixture.componentInstance.removeCurrency('USD');

    expect(fixture.componentInstance.showRemoveWarning()).toBe(true);
    expect(fixture.componentInstance.currencyToRemove()).toBe('USD');
  });

  it('should_remove_currency_directly_when_not_used_by_any_active_account', () => {
    const fixture = createFixture(
      ['EUR', 'USD'],
      [makeAccount({ currency: 'USD', actif: false })],
    );
    const emitted: string[][] = [];
    fixture.componentInstance.currenciesChange.subscribe((v) => emitted.push(v));

    fixture.componentInstance.removeCurrency('USD');

    expect(emitted).toEqual([['EUR']]);
    expect(fixture.componentInstance.showRemoveWarning()).toBe(false);
  });

  it('should_confirm_removal_from_the_warning_dialog', () => {
    const fixture = createFixture(
      ['EUR', 'USD'],
      [makeAccount({ currency: 'USD', actif: true })],
    );
    const emitted: string[][] = [];
    fixture.componentInstance.currenciesChange.subscribe((v) => emitted.push(v));
    fixture.componentInstance.removeCurrency('USD');

    fixture.componentInstance.doRemoveCurrency('USD');

    expect(emitted).toEqual([['EUR']]);
    expect(fixture.componentInstance.showRemoveWarning()).toBe(false);
    expect(fixture.componentInstance.currencyToRemove()).toBeNull();
  });
});
