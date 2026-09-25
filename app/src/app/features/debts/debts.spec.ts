import { TestBed } from '@angular/core/testing';
import { computed, signal } from '@angular/core';
import { provideRouter, Router } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';

import { Debts } from './debts';
import { DebtService } from '../../core/services/debt';
import { ModalService } from '../../core/services/modal.service';
import { PreferenceService } from '../../core/services/preference';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { DevLogger } from '../../core/services/dev-logger';
import { Debt, DebtType } from '../../core/models/debt.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';
import { stubIntersectionObserver } from '../../../testing/intersection-observer-stub';

// Vendredi 13 mars 2026, 10h — fige pour que le regroupement par echeance
// (en retard / aujourd'hui / cette semaine / ce mois-ci / plus tard) soit
// deterministe. Les tests tournent sous TZ=UTC (cf. consigne d'execution).
const NOW = new Date(2026, 2, 13, 10, 0, 0);

// jsdom ne fournit pas IntersectionObserver (utilise par ngAfterViewInit pour
// le sticky-sentinel).
beforeAll(() => stubIntersectionObserver());

const makeDebt = (overrides: Partial<Debt> = {}): Debt => ({
  id: 'debt-1',
  personne: 'Alice',
  montant: 100,
  montantRestant: 100,
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
  ...overrides,
});

function createDebtServiceMock() {
  return {
    getAll: vi.fn().mockReturnValue(of<Debt[]>([])),
    getById: vi.fn(),
    delete: vi.fn().mockReturnValue(of(undefined)),
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

function createDevLoggerMock() {
  return { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

describe('Debts', () => {
  let debtServiceMock: ReturnType<typeof createDebtServiceMock>;
  let preferenceServiceMock: ReturnType<typeof createPreferenceServiceMock>;
  let conversionServiceMock: ReturnType<typeof createConversionServiceMock>;
  let exchangeRateServiceMock: ReturnType<typeof createExchangeRateServiceMock>;
  let modalServiceMock: ReturnType<typeof createModalServiceMock>;
  let devLoggerMock: ReturnType<typeof createDevLoggerMock>;
  let routerMock: { navigate: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);

    debtServiceMock = createDebtServiceMock();
    preferenceServiceMock = createPreferenceServiceMock();
    conversionServiceMock = createConversionServiceMock();
    exchangeRateServiceMock = createExchangeRateServiceMock();
    modalServiceMock = createModalServiceMock();
    devLoggerMock = createDevLoggerMock();
    routerMock = { navigate: vi.fn() };
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [Debts],
      providers: [
        ...provideTranslocoTesting(),
        provideRouter([]),
        // CurrencyPillSelector injecte CurrencyService (HTTP reel) : sans
        // backend de test, jsdom emettrait de vraies requetes (CI).
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: DebtService, useValue: debtServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ConversionService, useValue: conversionServiceMock },
        { provide: ExchangeRateService, useValue: exchangeRateServiceMock },
        { provide: DevLogger, useValue: devLoggerMock },
        { provide: Router, useValue: routerMock },
      ],
    });
  };

  // La suite ne charge pas zone.js dans ce projet : `fixture.whenStable()` ne
  // suit pas la chaine de promesses de `loadData()`. On vide explicitement la
  // file de microtaches avant de forcer un rendu.
  const flushAsyncLoad = async (fixture: { detectChanges: () => void }) => {
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();
  };

  const createFixture = async (debts: Debt[] = []) => {
    debtServiceMock.getAll.mockReturnValue(of(debts));
    setupTestBed();
    const fixture = TestBed.createComponent(Debts);
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

  it('should_load_debts_on_init', async () => {
    const debt = makeDebt();
    const fixture = await createFixture([debt]);

    expect(fixture.componentInstance.debts()).toEqual([debt]);
    expect(fixture.componentInstance.loading()).toBe(false);
    expect(fixture.componentInstance.error()).toBe(false);
  });

  it('should_set_error_state_when_load_fails', async () => {
    debtServiceMock.getAll.mockReturnValue(throwError(() => new Error('network down')));
    setupTestBed();
    const fixture = TestBed.createComponent(Debts);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);

    expect(fixture.componentInstance.error()).toBe(true);
    expect(fixture.componentInstance.loading()).toBe(false);
    expect(devLoggerMock.error).toHaveBeenCalled();
  });

  it('should_reload_on_refreshTrigger_change', async () => {
    const fixture = await createFixture([]);
    debtServiceMock.getAll.mockClear();
    debtServiceMock.getAll.mockReturnValue(of([]));

    debtServiceMock.refreshTrigger.update((v: number) => v + 1);
    await flushAsyncLoad(fixture);

    expect(debtServiceMock.getAll).toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------
  // Rendu — textes statiques traduits (hero, en-tete, erreur, etat vide)
  // ---------------------------------------------------------------------

  it('should_render_french_error_state_labels_when_load_fails', async () => {
    debtServiceMock.getAll.mockReturnValue(throwError(() => new Error('network down')));
    setupTestBed();
    const fixture = TestBed.createComponent(Debts);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.state-error p')?.textContent).toBe('Erreur de chargement');
    expect(el.querySelector('.state-error .btn-outline')?.textContent).toBe('Réessayer');
  });

  it('should_render_french_empty_state_when_no_debts', async () => {
    const fixture = await createFixture([]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe('Aucune dette');
    expect(el.querySelector('.empty-state__cta')?.textContent).toBe('Ajouter une dette');
  });

  it('should_call_add_debt_when_empty_state_cta_is_clicked', async () => {
    const fixture = await createFixture([]);
    const cta = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>(
      '.empty-state__cta',
    );
    cta?.click();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('debt');
  });

  it('should_render_french_section_header_title', async () => {
    const fixture = await createFixture([makeDebt()]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.section-header__title')?.textContent).toBe('Dettes');
  });

  it('should_render_french_hero_labels_when_active_debts_exist', async () => {
    const emprunt = makeDebt({ id: 'e1', sens: DebtType.EMPRUNT, montantRestant: 50, currency: 'EUR' });
    const pret = makeDebt({ id: 'p1', sens: DebtType.PRET, montantRestant: 80, currency: 'EUR' });
    const fixture = await createFixture([emprunt, pret]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.hero__amount-label')?.textContent).toBe('Solde net');
    const metaLines = Array.from(el.querySelectorAll('.hero__meta-line')).map((n) =>
      n.textContent?.trim(),
    );
    expect(metaLines).toEqual(['1 prêt·1 emprunt', '2 en cours']);
  });

  // ---------------------------------------------------------------------
  // Rendu du sous-titre (DEBT_TYPE_LABEL_KEYS, partagee via debt.model.ts)
  // ---------------------------------------------------------------------

  it('should_render_type_only_subtitle_when_no_category', async () => {
    const fixture = await createFixture([makeDebt({ sens: DebtType.EMPRUNT, category: null })]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.list-row__subtitle')?.textContent?.trim()).toBe('Emprunt');
  });

  it('should_render_category_and_type_subtitle_when_category_present', async () => {
    const fixture = await createFixture([
      makeDebt({
        sens: DebtType.PRET,
        category: { id: 'cat-1', nom: 'Ami', icone: '👤', couleur: '#fff', isSystem: false },
      }),
    ]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.list-row__subtitle')?.textContent?.trim()).toBe('Ami · Prêt');
  });

  // ---------------------------------------------------------------------
  // getIcon / getIconBg
  // ---------------------------------------------------------------------

  it('should_return_category_icon_when_present', async () => {
    const fixture = await createFixture([]);
    const debt = makeDebt({ category: { id: 'c1', nom: 'Ami', icone: '👤', couleur: '#123456', isSystem: false } });
    expect(fixture.componentInstance.getIcon(debt)).toBe('👤');
    expect(fixture.componentInstance.getIconBg(debt)).toBe('#12345626');
  });

  it('should_return_default_icon_when_no_category', async () => {
    const fixture = await createFixture([]);
    expect(fixture.componentInstance.getIcon(makeDebt({ sens: DebtType.EMPRUNT, category: null }))).toBe('💸');
    expect(fixture.componentInstance.getIcon(makeDebt({ sens: DebtType.PRET, category: null }))).toBe('💰');
    expect(fixture.componentInstance.getIconBg(makeDebt({ category: null }))).toBeNull();
  });

  // ---------------------------------------------------------------------
  // getAmountClass / isOverdue
  // ---------------------------------------------------------------------

  it('should_return_income_class_for_pret_and_expense_class_for_emprunt', async () => {
    const fixture = await createFixture([]);
    expect(fixture.componentInstance.getAmountClass(makeDebt({ sens: DebtType.PRET }))).toBe('amount-income');
    expect(fixture.componentInstance.getAmountClass(makeDebt({ sens: DebtType.EMPRUNT }))).toBe('amount-expense');
  });

  it('should_detect_overdue_debt', async () => {
    const fixture = await createFixture([]);
    const component = fixture.componentInstance;

    expect(component.isOverdue(makeDebt({ dueDate: '2026-03-01', rembourse: false }))).toBe(true);
    expect(component.isOverdue(makeDebt({ dueDate: '2026-03-20', rembourse: false }))).toBe(false);
    expect(component.isOverdue(makeDebt({ dueDate: null }))).toBe(false);
    expect(component.isOverdue(makeDebt({ dueDate: '2026-03-01', rembourse: true }))).toBe(false);
  });

  // ---------------------------------------------------------------------
  // getRelativeDateInfo — toutes les branches
  // ---------------------------------------------------------------------

  it('should_return_null_when_no_due_date_or_repaid', async () => {
    const fixture = await createFixture([]);
    const component = fixture.componentInstance;

    expect(component.getRelativeDateInfo(makeDebt({ dueDate: null }))).toBeNull();
    expect(component.getRelativeDateInfo(makeDebt({ dueDate: '2026-03-20', rembourse: true }))).toBeNull();
  });

  it('should_return_days_overdue_key_when_due_date_in_the_past', async () => {
    const fixture = await createFixture([]);
    const result = fixture.componentInstance.getRelativeDateInfo(
      makeDebt({ dueDate: '2026-03-10', rembourse: false }),
    );
    expect(result).toEqual({ key: 'debts.list.daysOverdue', params: { count: 3 } });
  });

  it('should_return_today_key_when_due_today', async () => {
    const fixture = await createFixture([]);
    const result = fixture.componentInstance.getRelativeDateInfo(
      makeDebt({ dueDate: '2026-03-13', rembourse: false }),
    );
    expect(result).toEqual({ key: 'debts.list.today' });
  });

  it('should_return_tomorrow_key_when_due_tomorrow', async () => {
    const fixture = await createFixture([]);
    const result = fixture.componentInstance.getRelativeDateInfo(
      makeDebt({ dueDate: '2026-03-14', rembourse: false }),
    );
    expect(result).toEqual({ key: 'debts.list.tomorrow' });
  });

  it('should_return_days_until_key_when_due_within_thirty_days', async () => {
    const fixture = await createFixture([]);
    const result = fixture.componentInstance.getRelativeDateInfo(
      makeDebt({ dueDate: '2026-03-20', rembourse: false }),
    );
    expect(result).toEqual({ key: 'debts.list.daysUntil', params: { count: 7 } });
  });

  it('should_return_formatted_date_when_due_beyond_thirty_days', async () => {
    const fixture = await createFixture([]);
    const result = fixture.componentInstance.getRelativeDateInfo(
      makeDebt({ dueDate: '2026-06-01', rembourse: false }),
    );
    expect(result?.key).toBeUndefined();
    expect(result?.formatted).toBeTruthy();
  });

  it('should_render_overdue_due_date_row_class', async () => {
    const fixture = await createFixture([makeDebt({ dueDate: '2026-03-01', rembourse: false })]);
    const el: HTMLElement = fixture.nativeElement;

    const due = el.querySelector('.list-row__due');
    expect(due?.classList.contains('list-row__due--overdue')).toBe(true);
    expect(due?.textContent?.trim()).toBe('12 j. en retard');
  });

  // ---------------------------------------------------------------------
  // groupedDebts — regroupement et libelles
  // ---------------------------------------------------------------------

  it('should_group_debts_by_status_in_order', async () => {
    const overdue = makeDebt({ id: 'overdue', dueDate: '2026-03-01' });
    const today = makeDebt({ id: 'today', dueDate: '2026-03-13' });
    const thisWeek = makeDebt({ id: 'thisWeek', dueDate: '2026-03-18' });
    const thisMonth = makeDebt({ id: 'thisMonth', dueDate: '2026-03-25' });
    const later = makeDebt({ id: 'later', dueDate: '2026-04-15' });
    const noDue = makeDebt({ id: 'noDue', dueDate: null });
    const repaid = makeDebt({ id: 'repaid', rembourse: true, montantRestant: 0 });

    const fixture = await createFixture([later, thisMonth, thisWeek, today, overdue, noDue, repaid]);
    const groups = fixture.componentInstance.groupedDebts();

    expect(groups.map((g) => g.status)).toEqual([
      'overdue',
      'today',
      'default',
      'default',
      'default',
      'default',
      'repaid',
    ]);
    expect(groups.map((g) => g.items.map((d) => d.id))).toEqual([
      ['overdue'],
      ['today'],
      ['thisWeek'],
      ['thisMonth'],
      ['later'],
      ['noDue'],
      ['repaid'],
    ]);
  });

  it('should_render_french_group_labels_in_order', async () => {
    const overdue = makeDebt({ id: 'overdue', dueDate: '2026-03-01' });
    const today = makeDebt({ id: 'today', dueDate: '2026-03-13' });
    const noDue = makeDebt({ id: 'noDue', dueDate: null });
    const repaid = makeDebt({ id: 'repaid', rembourse: true, montantRestant: 0 });

    const fixture = await createFixture([overdue, today, noDue, repaid]);
    const el: HTMLElement = fixture.nativeElement;

    const headers = Array.from(el.querySelectorAll('.date-label')).map((n) => n.textContent?.trim());
    expect(headers).toEqual(["En retard", "Aujourd'hui", 'Sans échéance', 'Remboursées']);
  });

  // ---------------------------------------------------------------------
  // setActiveCurrency — persistance differee
  // ---------------------------------------------------------------------

  it('should_reorder_currencies_and_persist_after_delay', async () => {
    preferenceServiceMock.currencies.set(['EUR', 'USD']);
    const fixture = await createFixture([]);
    const component = fixture.componentInstance;

    component.setActiveCurrency('USD');
    expect(component.activeCurrency()).toBe('USD');
    expect(preferenceServiceMock.setCurrencies).toHaveBeenCalledWith(['USD', 'EUR']);

    await vi.advanceTimersByTimeAsync(2000);

    expect(preferenceServiceMock.update).toHaveBeenCalledWith({ currencies: ['USD', 'EUR'] });
    expect(exchangeRateServiceMock.loadRates).toHaveBeenCalled();
  });

  it('should_clear_previous_timeout_when_currency_changed_again', async () => {
    preferenceServiceMock.currencies.set(['EUR', 'USD']);
    const fixture = await createFixture([]);
    const component = fixture.componentInstance;

    component.setActiveCurrency('USD');
    component.setActiveCurrency('EUR');

    await vi.advanceTimersByTimeAsync(2000);

    expect(preferenceServiceMock.update).toHaveBeenCalledTimes(1);
    expect(preferenceServiceMock.update).toHaveBeenCalledWith({ currencies: ['EUR', 'USD'] });
  });

  // ---------------------------------------------------------------------
  // onDebtPressed / navigation
  // ---------------------------------------------------------------------

  it('should_navigate_to_debt_detail_when_pressed', async () => {
    const fixture = await createFixture([]);
    fixture.componentInstance.onDebtPressed(makeDebt({ id: 'debt-42' }));

    expect(routerMock.navigate).toHaveBeenCalledWith(['/debts', 'debt-42']);
  });

  // ---------------------------------------------------------------------
  // heroConverted — toutes les branches
  // ---------------------------------------------------------------------

  it('should_return_null_converted_when_net_is_zero', async () => {
    const fixture = await createFixture([]);
    expect(fixture.componentInstance.heroConverted()).toBeNull();
  });

  it('should_return_null_converted_when_only_one_currency_configured', async () => {
    const fixture = await createFixture([makeDebt({ sens: DebtType.PRET, montantRestant: 50 })]);
    expect(fixture.componentInstance.heroConverted()).toBeNull();
  });

  it('should_return_converted_amount_when_secondary_currency_available', async () => {
    preferenceServiceMock.currencies.set(['EUR', 'USD']);
    conversionServiceMock.convert.mockImplementation((amount: number, from: string, to: string) => {
      if (from === to) return amount;
      if (from === 'EUR' && to === 'USD') return amount * 1.1;
      return null;
    });
    const fixture = await createFixture([makeDebt({ sens: DebtType.PRET, montantRestant: 50, currency: 'EUR' })]);

    const converted = fixture.componentInstance.heroConverted();
    expect(converted?.currency).toBe('USD');
    expect(converted?.amount).toBeCloseTo(55, 5);
  });

  it('should_return_null_converted_when_conversion_fails', async () => {
    preferenceServiceMock.currencies.set(['EUR', 'USD']);
    conversionServiceMock.convert.mockReturnValue(null);
    const fixture = await createFixture([makeDebt({ sens: DebtType.PRET, montantRestant: 50, currency: 'EUR' })]);

    expect(fixture.componentInstance.heroConverted()).toBeNull();
  });

  // ---------------------------------------------------------------------
  // netBalanceByCurrency / activeCurrencyNet — plusieurs devises
  // ---------------------------------------------------------------------

  it('should_sum_net_balance_per_currency_with_sign_by_direction', async () => {
    const debts = [
      makeDebt({ id: 'e1', sens: DebtType.EMPRUNT, montantRestant: 30, currency: 'EUR' }),
      makeDebt({ id: 'p1', sens: DebtType.PRET, montantRestant: 50, currency: 'EUR' }),
      makeDebt({ id: 'p2', sens: DebtType.PRET, montantRestant: 20, currency: 'USD' }),
    ];
    const fixture = await createFixture(debts);
    const component = fixture.componentInstance;

    expect(component.netBalanceByCurrency()).toEqual([
      { currency: 'EUR', total: 20 },
      { currency: 'USD', total: 20 },
    ]);
    expect(component.activeCurrencyNet()).toBe(20);
  });

  it('should_convert_other_currencies_into_active_currency_net', async () => {
    conversionServiceMock.convert.mockImplementation((amount: number, from: string, to: string) => {
      if (from === to) return amount;
      if (from === 'USD' && to === 'EUR') return amount * 0.9;
      return null;
    });
    const debts = [
      makeDebt({ id: 'p1', sens: DebtType.PRET, montantRestant: 50, currency: 'EUR' }),
      makeDebt({ id: 'p2', sens: DebtType.PRET, montantRestant: 20, currency: 'USD' }),
    ];
    const fixture = await createFixture(debts);

    expect(fixture.componentInstance.activeCurrencyNet()).toBe(50 + 20 * 0.9);
  });

  it('should_ignore_unconvertible_currency_in_active_currency_net', async () => {
    conversionServiceMock.convert.mockReturnValue(null);
    const debts = [
      makeDebt({ id: 'p1', sens: DebtType.PRET, montantRestant: 50, currency: 'EUR' }),
      makeDebt({ id: 'p2', sens: DebtType.PRET, montantRestant: 20, currency: 'USD' }),
    ];
    const fixture = await createFixture(debts);

    expect(fixture.componentInstance.activeCurrencyNet()).toBe(50);
  });

  // ---------------------------------------------------------------------
  // hasDebts
  // ---------------------------------------------------------------------

  it('should_report_no_debts_when_list_is_empty', async () => {
    const fixture = await createFixture([]);
    expect(fixture.componentInstance.hasDebts()).toBe(false);
  });

  it('should_report_has_debts_when_list_is_not_empty', async () => {
    const fixture = await createFixture([makeDebt()]);
    expect(fixture.componentInstance.hasDebts()).toBe(true);
  });
});
