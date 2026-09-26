import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { provideRouter, Router } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';

import { BudgetList } from './budget-list';
import { BudgetService } from '../../../../core/services/budget';
import { ModalService } from '../../../../core/services/modal.service';
import { CategoryService } from '../../../../core/services/category';
import { PreferenceService } from '../../../../core/services/preference';
import { ConversionService } from '../../../../core/services/conversion';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { DevLogger } from '../../../../core/services/dev-logger';
import { type Budget, type BudgetOverview, type BudgetOverviewItem } from '../../../../core/models/budget.model';
import { type Category } from '../../../../core/models/category.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';
import { stubIntersectionObserver } from '../../../../../testing/intersection-observer-stub';

// Mardi 17 mars 2026 — fige pour que "le mois courant" soit deterministe.
const NOW = new Date(2026, 2, 17, 10, 0, 0);

beforeAll(() => stubIntersectionObserver());

function overviewItem(overrides: Partial<BudgetOverviewItem> = {}): BudgetOverviewItem {
  return {
    budgetId: 'budget-1',
    categoryId: 'courses',
    categoryNom: 'Courses',
    categoryIcone: '🛒',
    categoryCouleur: '#3b82f6',
    montantBudget: 200,
    montantBudgetNormalise: 200,
    currency: 'EUR',
    montantDepense: 100,
    percentage: 50,
    frequence: 'MENSUEL',
    actif: true,
    ...overrides,
  };
}

function overview(items: BudgetOverviewItem[], overrides: Partial<BudgetOverview> = {}): BudgetOverview {
  return {
    month: '2026-03',
    totalBudget: 200,
    totalSpent: 100,
    percentage: 50,
    currency: 'EUR',
    items,
    unbudgetedItems: [],
    unbudgetedTotal: 0,
    ...overrides,
  };
}

function budgetOn(id: string, categoryId: string, actif = true): Budget {
  return {
    id,
    montant: 100,
    currency: 'EUR',
    frequence: 'MENSUEL',
    seuilNotification: 80,
    actif,
    category: { id: categoryId, nom: categoryId, icone: '🏷', couleur: '#000000' },
    spent: 0,
    updatedAt: '2026-03-01T00:00:00',
  };
}

function category(id: string, isSystem = false): Category {
  return { id, nom: id, icone: '🏷', couleur: '#000000', isSystem };
}

describe('BudgetList', () => {
  let budgetServiceMock: {
    getOverview: ReturnType<typeof vi.fn>;
    getHistory: ReturnType<typeof vi.fn>;
    getAll: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof signal>;
  };
  let modalServiceMock: { openModal: ReturnType<typeof vi.fn> };
  let categoryServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let preferenceServiceMock: {
    currencies: ReturnType<typeof signal>;
    primaryCurrency: ReturnType<typeof vi.fn>;
    setCurrencies: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
    language: ReturnType<typeof signal>;
    loaded: ReturnType<typeof signal>;
  };
  let conversionServiceMock: { convert: ReturnType<typeof vi.fn> };
  let exchangeRateServiceMock: { loadRates: ReturnType<typeof vi.fn> };
  let devLoggerMock: { error: ReturnType<typeof vi.fn> };
  let routerMock: { navigate: ReturnType<typeof vi.fn> };

  const setupTestBed = () => {
    budgetServiceMock = {
      getOverview: vi.fn().mockReturnValue(of(overview([overviewItem()]))),
      getHistory: vi.fn().mockReturnValue(of(overview([overviewItem()]))),
      getAll: vi.fn().mockReturnValue(of([])),
      refreshTrigger: signal(0),
    };
    modalServiceMock = { openModal: vi.fn() };
    categoryServiceMock = { getAll: vi.fn().mockReturnValue(of([])) };
    preferenceServiceMock = {
      currencies: signal(['EUR']),
      primaryCurrency: vi.fn().mockReturnValue('EUR'),
      setCurrencies: vi.fn(),
      update: vi.fn(),
      language: signal<string | null>(null),
      loaded: signal(false),
    };
    conversionServiceMock = { convert: vi.fn((amount: number) => amount) };
    exchangeRateServiceMock = { loadRates: vi.fn().mockResolvedValue(undefined) };
    devLoggerMock = { error: vi.fn() };
    routerMock = { navigate: vi.fn() };

    TestBed.configureTestingModule({
      imports: [BudgetList],
      providers: [
        ...provideTranslocoTesting(),
        provideRouter([]),
        // CurrencyPillSelector injecte CurrencyService (HTTP reel) : sans
        // backend de test, jsdom emettrait de vraies requetes (CI).
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: BudgetService, useValue: budgetServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
        { provide: ConversionService, useValue: conversionServiceMock },
        { provide: ExchangeRateService, useValue: exchangeRateServiceMock },
        { provide: DevLogger, useValue: devLoggerMock },
        { provide: Router, useValue: routerMock },
      ],
    });
  };

  const flushAsyncLoad = async (fixture: { detectChanges: () => void }) => {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();
  };

  // `configure` s'execute apres `setupTestBed()` : les mocks n'existent qu'a
  // partir de cet appel, tout reglage plus tot serait ecrase.
  const createFixture = async (configure?: () => void) => {
    setupTestBed();
    configure?.();
    const fixture = TestBed.createComponent(BudgetList);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    return fixture;
  };

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('should_create_the_component', async () => {
    const fixture = await createFixture();

    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_render_the_translated_section_title_and_active_count', async () => {
    const fixture = await createFixture();

    const title: HTMLElement = fixture.nativeElement.querySelector('.section-header__title');
    const count: HTMLElement = fixture.nativeElement.querySelector('.section-header__count');
    expect(title.textContent?.trim()).toBe('Budgets');
    expect(count.textContent?.trim()).toBe('1 actif');
  });

  it('should_pluralize_the_active_count_in_french_when_several_budgets_are_active', async () => {
    const fixture = await createFixture(() => {
      budgetServiceMock.getOverview.mockReturnValue(
        of(overview([overviewItem(), overviewItem({ categoryId: 'loisirs', categoryNom: 'Loisirs' })])),
      );
    });

    const count: HTMLElement = fixture.nativeElement.querySelector('.section-header__count');
    expect(count.textContent?.trim()).toBe('2 actifs');
  });

  it('should_render_the_translated_spent_label_and_over_budget_count', async () => {
    const fixture = await createFixture(() => {
      budgetServiceMock.getOverview.mockReturnValue(of(overview([overviewItem({ percentage: 120 })])));
    });

    const label: HTMLElement = fixture.nativeElement.querySelector('.hero__amount-label');
    expect(label.textContent?.trim()).toBe('Dépensé');
    expect(fixture.nativeElement.textContent).toContain('1 en dépassement');
  });

  it('should_render_the_translated_unbudgeted_amount_in_the_hero', async () => {
    const fixture = await createFixture(() => {
      budgetServiceMock.getOverview.mockReturnValue(of(overview([overviewItem()], { unbudgetedTotal: 42 })));
    });

    expect(fixture.nativeElement.textContent).toContain('non budgété');
  });

  it('should_render_the_french_error_state_and_retry', async () => {
    const fixture = await createFixture(() => {
      budgetServiceMock.getOverview.mockReturnValue(throwError(() => new Error('boom')));
    });

    const message: HTMLElement = fixture.nativeElement.querySelector('.state-error p');
    const retry: HTMLElement = fixture.nativeElement.querySelector('.state-error button');
    expect(message.textContent?.trim()).toBe('Erreur de chargement');
    expect(retry.textContent?.trim()).toBe('Réessayer');
  });

  it('should_render_the_french_empty_state_with_a_create_cta', async () => {
    const fixture = await createFixture(() => {
      budgetServiceMock.getOverview.mockReturnValue(of(overview([])));
    });

    const empty: HTMLElement = fixture.nativeElement.querySelector('.empty-state__message');
    const cta: HTMLElement = fixture.nativeElement.querySelector('.empty-state__cta');
    expect(empty.textContent?.trim()).toBe('Aucun budget pour cette période');
    expect(cta.textContent?.trim()).toBe('Créer un budget');
  });

  it('should_render_the_translated_inactive_group_label', async () => {
    const fixture = await createFixture(() => {
      budgetServiceMock.getOverview.mockReturnValue(of(overview([overviewItem({ actif: false })])));
    });

    const label: HTMLElement = fixture.nativeElement.querySelector('.date-label');
    expect(label.textContent?.trim()).toBe('Inactifs');
  });

  it('should_navigate_to_unbudgeted_when_shown', async () => {
    const fixture = await createFixture(() => {
      budgetServiceMock.getOverview.mockReturnValue(of(overview([overviewItem()], { unbudgetedTotal: 10 })));
    });

    fixture.componentInstance.onShowUnbudgeted();

    expect(routerMock.navigate).toHaveBeenCalledWith(['/budgets/unbudgeted'], {
      queryParams: { month: '2026-03' },
    });
  });

  it('should_open_the_create_modal', async () => {
    const fixture = await createFixture();

    fixture.componentInstance.onCreate();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('budget');
  });

  it('should_navigate_to_budget_details_when_pressed', async () => {
    const fixture = await createFixture();

    fixture.componentInstance.onBudgetPressed(overviewItem());

    expect(routerMock.navigate).toHaveBeenCalledWith(['/budgets/details'], {
      queryParams: { budgetId: 'courses', month: '2026-03' },
    });
  });

  it('should_move_to_the_previous_month_and_load_history', async () => {
    const fixture = await createFixture();

    fixture.componentInstance.prevMonth();
    await flushAsyncLoad(fixture);

    expect(budgetServiceMock.getHistory).toHaveBeenCalledWith('2026-02');
  });

  it('should_move_to_the_next_month_and_load_history', async () => {
    const fixture = await createFixture();

    fixture.componentInstance.nextMonth();
    await flushAsyncLoad(fixture);

    expect(budgetServiceMock.getHistory).toHaveBeenCalledWith('2026-04');
  });

  it('should_disable_the_create_button_when_every_category_already_has_a_budget', async () => {
    const fixture = await createFixture(() => {
      categoryServiceMock.getAll.mockReturnValue(of([category('courses')]));
      budgetServiceMock.getAll.mockReturnValue(of([budgetOn('b1', 'courses')]));
    });

    expect(fixture.componentInstance.allCategoriesHaveBudget()).toBe(true);
  });
});
