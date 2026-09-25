import { TestBed } from '@angular/core/testing';
import { computed, signal } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';

import { Transactions } from './transactions';
import { TransactionService } from '../../core/services/transaction';
import { PreferenceService } from '../../core/services/preference';
import { ModalService } from '../../core/services/modal.service';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { CategoryService } from '../../core/services/category';
import { AccountService } from '../../core/services/account';
import { Transaction, TransactionType } from '../../core/models/transaction.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';
import { stubIntersectionObserver } from '../../../testing/intersection-observer-stub';

// Vendredi 13 mars 2026, 10h — figé pour que le regroupement par date
// (aujourd'hui / hier / cette semaine / semaine dernière / plus ancien) soit
// déterministe. Les tests tournent sous TZ=UTC (cf. consigne d'exécution).
const NOW = new Date(2026, 2, 13, 10, 0, 0);

// jsdom ne fournit pas IntersectionObserver (utilisé par ngAfterViewInit pour
// le sticky-sentinel).
beforeAll(() => stubIntersectionObserver());

const makeTransaction = (overrides: Partial<Transaction> = {}): Transaction => ({
  id: 'tx-1',
  montant: 10,
  libelle: 'Achat',
  type: TransactionType.DEPENSE,
  date: '2026-03-13',
  category: null,
  note: null,
  account: null,
  transferId: null,
  ...overrides,
});

function createTransactionServiceMock() {
  return {
    getAll: vi.fn().mockReturnValue(of<Transaction[]>([])),
    getSummary: vi.fn().mockReturnValue(of([])),
    refreshTrigger: signal(0),
  };
}

function createPreferenceServiceMock() {
  const currencies = signal(['EUR']);
  return {
    currencies,
    primaryCurrency: computed(() => currencies()[0] ?? 'EUR'),
    language: signal<string | null>(null),
    setCurrencies: vi.fn(),
    update: vi.fn(),
  };
}

function createConversionServiceMock() {
  return {
    convert: vi.fn((amount: number, from: string, to: string) => (from === to ? amount : null)),
  };
}

function createExchangeRateServiceMock() {
  return {
    loadRates: vi.fn().mockResolvedValue(undefined),
    rates: signal([]),
  };
}

function createModalServiceMock() {
  return { openModal: vi.fn() };
}

function createCategoryServiceMock() {
  return { getAll: vi.fn().mockReturnValue(of([])) };
}

function createAccountServiceMock() {
  return { getAll: vi.fn().mockReturnValue(of([])) };
}

describe('Transactions', () => {
  let transactionServiceMock: ReturnType<typeof createTransactionServiceMock>;
  let preferenceServiceMock: ReturnType<typeof createPreferenceServiceMock>;
  let conversionServiceMock: ReturnType<typeof createConversionServiceMock>;
  let exchangeRateServiceMock: ReturnType<typeof createExchangeRateServiceMock>;
  let modalServiceMock: ReturnType<typeof createModalServiceMock>;
  let categoryServiceMock: ReturnType<typeof createCategoryServiceMock>;
  let accountServiceMock: ReturnType<typeof createAccountServiceMock>;

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);

    transactionServiceMock = createTransactionServiceMock();
    preferenceServiceMock = createPreferenceServiceMock();
    conversionServiceMock = createConversionServiceMock();
    exchangeRateServiceMock = createExchangeRateServiceMock();
    modalServiceMock = createModalServiceMock();
    categoryServiceMock = createCategoryServiceMock();
    accountServiceMock = createAccountServiceMock();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [Transactions],
      providers: [
        ...provideTranslocoTesting(),
        provideRouter([]),
        // Les enfants (currency-pill-selector, pipes) injectent des services
        // HTTP reels : sans backend de test, jsdom emettrait de vraies
        // requetes (CI).
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: TransactionService, useValue: transactionServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ConversionService, useValue: conversionServiceMock },
        { provide: ExchangeRateService, useValue: exchangeRateServiceMock },
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
      ],
    });
  };

  // La suite ne charge pas zone.js dans ce projet : `fixture.whenStable()` ne
  // suit pas la chaine de promesses de `loadData()` (un `Promise.all` de
  // `firstValueFrom`). On vide explicitement la file de microtaches avant de
  // forcer un rendu, plutot que de compter sur la stabilisation de NgZone.
  const flushAsyncLoad = async (fixture: { detectChanges: () => void }) => {
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();
  };

  const createFixture = async (transactions: Transaction[] = []) => {
    transactionServiceMock.getAll.mockReturnValue(of(transactions));
    setupTestBed();
    const fixture = TestBed.createComponent(Transactions);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    return fixture;
  };

  it('should_create_the_component', async () => {
    const fixture = await createFixture();

    expect(fixture.componentInstance).toBeTruthy();
  });

  // ---------------------------------------------------------------------
  // Rendu — textes statiques francais (hero, en-tete, filtres, erreur)
  // ---------------------------------------------------------------------

  it('should_render_french_static_hero_and_header_labels', async () => {
    const fixture = await createFixture([]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.hero__amount-label')?.textContent).toBe('Solde');
    expect(el.querySelector('.section-header__title')?.textContent).toBe('Transactions');
    expect(el.querySelector('button.hero__nav-btn[aria-label="Mois précédent"]')).not.toBeNull();
    expect(el.querySelector('button.hero__nav-btn[aria-label="Mois suivant"]')).not.toBeNull();
    expect(el.querySelector('[aria-label="Rechercher"]')).not.toBeNull();
    expect(el.querySelector('[aria-label="Filtrer"]')).not.toBeNull();
    expect(el.querySelector('a[aria-label="Récurrences"]')).not.toBeNull();

    const metaLines = Array.from(el.querySelectorAll('.hero__meta-line')).map((n) =>
      n.textContent?.trim(),
    );
    expect(metaLines).toEqual(['0 recettes', '0 dépenses']);
  });

  it('should_render_french_search_labels_when_search_open', async () => {
    const fixture = await createFixture([]);
    fixture.componentInstance.toggleSearch();
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    const input = el.querySelector<HTMLInputElement>('.section-header__search-input');
    expect(input?.getAttribute('placeholder')).toBe('Rechercher...');
    expect(el.querySelector('[aria-label="Fermer"]')).not.toBeNull();
    // Le bouton "Rechercher" disparait pendant que la recherche est ouverte.
    expect(el.querySelector('[aria-label="Rechercher"]')).toBeNull();
  });

  it('should_render_french_filter_panel_labels_when_filter_open_and_filters_active', async () => {
    const fixture = await createFixture([]);
    const component = fixture.componentInstance;
    component.toggleFilter();
    component.setTypeFilter(TransactionType.DEPENSE);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    const chipLabels = Array.from(el.querySelectorAll('.filter-chip')).map((n) =>
      n.textContent?.trim(),
    );
    expect(chipLabels).toEqual(['Tout', 'Dépenses', 'Recettes']);
    expect(el.querySelector('.filter-panel__reset')?.textContent?.trim()).toBe('Réinitialiser');
  });

  it('should_render_french_error_state_labels_when_load_fails', async () => {
    transactionServiceMock.getAll.mockReturnValue(throwError(() => new Error('network down')));
    setupTestBed();
    const fixture = TestBed.createComponent(Transactions);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.state-error p')?.textContent).toBe('Erreur de chargement');
    expect(el.querySelector('.state-error .btn-outline')?.textContent).toBe('Réessayer');
  });

  // ---------------------------------------------------------------------
  // emptyStateConfig — les trois branches et leurs variantes
  // ---------------------------------------------------------------------

  it('should_set_no_results_message_when_search_query_is_active', async () => {
    const fixture = await createFixture([]);
    fixture.componentInstance.searchQuery.set('introuvable');
    fixture.detectChanges();

    expect(fixture.componentInstance.emptyStateConfig()).toEqual({
      icon: 'phosphorMagnifyingGlass',
      messageKey: 'transactions.empty.noResults',
      isResetCta: false,
    });
  });

  it('should_set_no_expense_message_when_type_filter_is_depense', async () => {
    const fixture = await createFixture([]);
    fixture.componentInstance.setTypeFilter(TransactionType.DEPENSE);
    fixture.detectChanges();

    expect(fixture.componentInstance.emptyStateConfig()).toEqual({
      icon: 'phosphorFunnel',
      messageKey: 'transactions.empty.noExpenseInMonth',
      messageParams: { month: fixture.componentInstance.selectedMonthLabel() },
      ctaLabelKey: 'common.action.resetFilters',
      isResetCta: true,
    });
  });

  it('should_set_no_income_message_when_type_filter_is_recette', async () => {
    const fixture = await createFixture([]);
    fixture.componentInstance.setTypeFilter(TransactionType.RECETTE);
    fixture.detectChanges();

    expect(fixture.componentInstance.emptyStateConfig()).toEqual({
      icon: 'phosphorFunnel',
      messageKey: 'transactions.empty.noIncomeInMonth',
      messageParams: { month: fixture.componentInstance.selectedMonthLabel() },
      ctaLabelKey: 'common.action.resetFilters',
      isResetCta: true,
    });
  });

  it('should_set_generic_no_transaction_message_when_a_non_type_filter_is_active', async () => {
    const fixture = await createFixture([]);
    // typeFilter reste null, mais un autre filtre (categorie) est actif.
    fixture.componentInstance.setCategoryFilter('cat-1');
    fixture.detectChanges();

    expect(fixture.componentInstance.emptyStateConfig()).toEqual({
      icon: 'phosphorFunnel',
      messageKey: 'transactions.empty.noneInMonth',
      messageParams: { month: fixture.componentInstance.selectedMonthLabel() },
      ctaLabelKey: 'common.action.resetFilters',
      isResetCta: true,
    });
  });

  it('should_set_add_transaction_cta_when_no_filter_is_active', async () => {
    const fixture = await createFixture([]);

    expect(fixture.componentInstance.emptyStateConfig()).toEqual({
      icon: 'phosphorReceipt',
      messageKey: 'transactions.empty.noneInMonth',
      messageParams: { month: fixture.componentInstance.selectedMonthLabel() },
      ctaLabelKey: 'transactions.action.add',
      isResetCta: false,
    });
  });

  // ---------------------------------------------------------------------
  // Rendu de l'etat vide (app-empty-state) — francais + interactions CTA
  // ---------------------------------------------------------------------

  it('should_render_no_results_message_and_hide_cta_when_searching', async () => {
    const fixture = await createFixture([]);
    fixture.componentInstance.searchQuery.set('introuvable');
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe(
      'Aucune transaction trouvée',
    );
    expect(el.querySelector('.empty-state__cta')).toBeNull();
  });

  it('should_render_no_expense_message_and_reset_cta_when_depense_filter_active', async () => {
    const fixture = await createFixture([]);
    fixture.componentInstance.setTypeFilter(TransactionType.DEPENSE);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe(
      'Aucune dépense en mars 2026',
    );
    expect(el.querySelector('.empty-state__cta')?.textContent).toBe('Réinitialiser les filtres');
  });

  it('should_render_add_transaction_message_and_cta_when_no_filter_active', async () => {
    const fixture = await createFixture([]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe(
      'Aucune transaction en mars 2026',
    );
    expect(el.querySelector('.empty-state__cta')?.textContent).toBe('Ajouter une transaction');
  });

  it('should_call_reset_filters_when_reset_cta_is_clicked', async () => {
    const fixture = await createFixture([]);
    const component = fixture.componentInstance;
    component.setTypeFilter(TransactionType.DEPENSE);
    fixture.detectChanges();

    const cta = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>(
      '.empty-state__cta',
    );
    cta?.click();
    fixture.detectChanges();

    expect(component.typeFilter()).toBeNull();
    expect(component.hasActiveFilters()).toBe(false);
    expect(modalServiceMock.openModal).not.toHaveBeenCalled();
  });

  it('should_call_add_transaction_when_default_cta_is_clicked', async () => {
    const fixture = await createFixture([]);

    const cta = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>(
      '.empty-state__cta',
    );
    cta?.click();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('transaction');
  });

  // ---------------------------------------------------------------------
  // groupedTransactions — regroupement par DateGroupKey
  // ---------------------------------------------------------------------

  it('should_group_transactions_by_date_group_key_in_order', async () => {
    const todayTx = makeTransaction({ id: 'today', date: '2026-03-13', libelle: 'Café' });
    const yesterdayTx = makeTransaction({ id: 'yesterday', date: '2026-03-12', libelle: 'Métro' });
    const thisWeekTx = makeTransaction({
      id: 'thisWeek',
      date: '2026-03-10',
      libelle: 'Remboursement',
      type: TransactionType.RECETTE,
    });
    const lastWeekTx = makeTransaction({ id: 'lastWeek', date: '2026-03-05', libelle: 'Courses' });
    const olderTx = makeTransaction({ id: 'older', date: '2026-03-01', libelle: 'Loyer' });

    const fixture = await createFixture([olderTx, lastWeekTx, thisWeekTx, yesterdayTx, todayTx]);

    const groups = fixture.componentInstance.groupedTransactions();

    expect(groups.map((g) => g.key)).toEqual([
      'today',
      'yesterday',
      'thisWeek',
      'lastWeek',
      'older',
    ]);
    expect(groups.map((g) => g.transactions.map((t) => t.id))).toEqual([
      ['today'],
      ['yesterday'],
      ['thisWeek'],
      ['lastWeek'],
      ['older'],
    ]);
  });

  it('should_omit_empty_date_groups', async () => {
    const todayTx = makeTransaction({ id: 'today', date: '2026-03-13' });
    const lastWeekTx = makeTransaction({ id: 'lastWeek', date: '2026-03-05' });

    const fixture = await createFixture([todayTx, lastWeekTx]);

    const groups = fixture.componentInstance.groupedTransactions();

    expect(groups.map((g) => g.key)).toEqual(['today', 'lastWeek']);
  });

  it('should_render_french_date_group_headers_in_order', async () => {
    const todayTx = makeTransaction({ id: 'today', date: '2026-03-13' });
    const yesterdayTx = makeTransaction({ id: 'yesterday', date: '2026-03-12' });
    const thisWeekTx = makeTransaction({ id: 'thisWeek', date: '2026-03-10' });
    const lastWeekTx = makeTransaction({ id: 'lastWeek', date: '2026-03-05' });
    const olderTx = makeTransaction({ id: 'older', date: '2026-03-01' });

    const fixture = await createFixture([olderTx, lastWeekTx, thisWeekTx, yesterdayTx, todayTx]);
    const el: HTMLElement = fixture.nativeElement;

    const headers = Array.from(el.querySelectorAll('.date-label')).map((n) =>
      n.textContent?.trim(),
    );
    expect(headers).toEqual([
      "Aujourd'hui",
      'Hier',
      'Cette semaine',
      'Semaine dernière',
      'Plus ancien',
    ]);
  });
});
