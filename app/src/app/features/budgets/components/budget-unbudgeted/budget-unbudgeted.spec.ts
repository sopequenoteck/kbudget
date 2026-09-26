import { TestBed } from '@angular/core/testing';
import { signal, computed } from '@angular/core';
import { ActivatedRoute, convertToParamMap, Router } from '@angular/router';
import { of } from 'rxjs';

import { BudgetUnbudgeted } from './budget-unbudgeted';
import { BudgetService } from '../../../../core/services/budget';
import { TransactionService } from '../../../../core/services/transaction';
import { ModalService } from '../../../../core/services/modal.service';
import { PreferenceService } from '../../../../core/services/preference';
import { ConversionService } from '../../../../core/services/conversion';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { DevLogger } from '../../../../core/services/dev-logger';
import { type BudgetOverview, type UnbudgetedItem } from '../../../../core/models/budget.model';
import { type Transaction, TransactionType } from '../../../../core/models/transaction.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';
import { stubIntersectionObserver } from '../../../../../testing/intersection-observer-stub';

// Mardi 17 mars 2026 — fige pour que "le mois courant" soit deterministe.
const NOW = new Date(2026, 2, 17, 10, 0, 0);

beforeAll(() => stubIntersectionObserver());

function unbudgetedItem(overrides: Partial<UnbudgetedItem> = {}): UnbudgetedItem {
  return {
    categoryId: 'divers',
    categoryNom: 'Divers',
    categoryIcone: '📦',
    categoryCouleur: '#f97316',
    montantDepense: 40,
    ...overrides,
  };
}

function overview(overrides: Partial<BudgetOverview> = {}): BudgetOverview {
  return {
    month: '2026-03',
    totalBudget: 200,
    totalSpent: 240,
    percentage: 120,
    currency: 'EUR',
    items: [],
    unbudgetedItems: [],
    unbudgetedTotal: 0,
    ...overrides,
  };
}

function makeTransaction(overrides: Partial<Transaction> = {}): Transaction {
  return {
    id: 'tx-1',
    type: TransactionType.DEPENSE,
    montant: 20,
    date: '2026-03-05',
    libelle: 'Achat divers',
    category: { id: 'divers', nom: 'Divers', icone: '📦', couleur: '#f97316', isSystem: false },
    account: {
      id: 'acc-1',
      nom: 'Courant',
      icone: '🏦',
      couleur: '#3b82f6',
      currency: 'EUR',
      bankLogoUrl: null,
      bankCustomLogo: null,
    },
    note: null,
    transferId: null,
    ...overrides,
  };
}

describe('BudgetUnbudgeted', () => {
  let budgetServiceMock: { getOverview: ReturnType<typeof vi.fn>; getHistory: ReturnType<typeof vi.fn> };
  let transactionServiceMock: { getByMonth: ReturnType<typeof vi.fn> };
  let modalServiceMock: { openModal: ReturnType<typeof vi.fn> };
  let exchangeRateServiceMock: { loadRates: ReturnType<typeof vi.fn> };
  let devLoggerMock: { error: ReturnType<typeof vi.fn> };
  let routerMock: { navigate: ReturnType<typeof vi.fn> };

  const setupTestBed = (queryParams: Record<string, string> = {}) => {
    budgetServiceMock = {
      getOverview: vi.fn().mockReturnValue(of(overview())),
      getHistory: vi.fn().mockReturnValue(of(overview())),
    };
    transactionServiceMock = { getByMonth: vi.fn().mockReturnValue(of([])) };
    modalServiceMock = { openModal: vi.fn() };
    exchangeRateServiceMock = { loadRates: vi.fn().mockResolvedValue(undefined) };
    devLoggerMock = { error: vi.fn() };
    routerMock = { navigate: vi.fn() };

    const currencies = signal(['EUR']);

    TestBed.configureTestingModule({
      imports: [BudgetUnbudgeted],
      providers: [
        ...provideTranslocoTesting(),
        { provide: BudgetService, useValue: budgetServiceMock },
        { provide: TransactionService, useValue: transactionServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        {
          provide: PreferenceService,
          useValue: {
            currencies,
            primaryCurrency: computed(() => currencies()[0] ?? 'EUR'),
            language: signal<string | null>(null),
            loaded: signal(false),
          },
        },
        { provide: ConversionService, useValue: { convert: vi.fn(() => null) } },
        { provide: ExchangeRateService, useValue: exchangeRateServiceMock },
        { provide: DevLogger, useValue: devLoggerMock },
        { provide: Router, useValue: routerMock },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { queryParamMap: convertToParamMap(queryParams) } },
        },
      ],
    });
  };

  const flushAsyncLoad = async (fixture: { detectChanges: () => void }) => {
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();
  };

  // `configure` s'execute apres `setupTestBed()` : les mocks n'existent qu'a
  // partir de cet appel, tout reglage plus tot serait ecrase.
  const createFixture = async (
    queryParams?: Record<string, string>,
    configure?: () => void,
  ) => {
    setupTestBed(queryParams);
    configure?.();
    const fixture = TestBed.createComponent(BudgetUnbudgeted);
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

  it('should_render_the_translated_page_title', async () => {
    const fixture = await createFixture();

    const title: HTMLElement = fixture.nativeElement.querySelector('.page-header__title');
    expect(title.textContent?.trim()).toBe('Non budgété');
  });

  it('should_render_the_french_empty_state_when_everything_is_budgeted', async () => {
    const fixture = await createFixture();

    const empty: HTMLElement = fixture.nativeElement.querySelector('.empty-state__message');
    expect(empty.textContent?.trim()).toBe('Toutes vos catégories ont un budget');
  });

  it('should_render_the_translated_hero_and_category_count_when_singular', async () => {
    const fixture = await createFixture(undefined, () => {
      budgetServiceMock.getOverview.mockReturnValue(
        of(overview({ unbudgetedItems: [unbudgetedItem()], unbudgetedTotal: 40 })),
      );
    });

    const label: HTMLElement = fixture.nativeElement.querySelector('.hero__label');
    expect(label.textContent?.trim()).toBe('Dépensé');
    expect(fixture.nativeElement.textContent).toContain('1 catégorie sans budget');
  });

  it('should_pluralize_the_category_count_in_french_when_several_categories_are_unbudgeted', async () => {
    const fixture = await createFixture(undefined, () => {
      budgetServiceMock.getOverview.mockReturnValue(
        of(
          overview({
            unbudgetedItems: [unbudgetedItem(), unbudgetedItem({ categoryId: 'sante', categoryNom: 'Santé' })],
            unbudgetedTotal: 80,
          }),
        ),
      );
    });

    expect(fixture.nativeElement.textContent).toContain('2 catégories sans budget');
  });

  it('should_render_the_translated_by_category_title_and_transaction_count', async () => {
    const fixture = await createFixture(undefined, () => {
      transactionServiceMock.getByMonth.mockReturnValue(of([makeTransaction()]));
      budgetServiceMock.getOverview.mockReturnValue(
        of(overview({ unbudgetedItems: [unbudgetedItem()], unbudgetedTotal: 40 })),
      );
    });

    const title: HTMLElement = fixture.nativeElement.querySelector('.section-header__title');
    const count: HTMLElement = fixture.nativeElement.querySelector('.section-header__count');
    expect(title.textContent?.trim()).toBe('Par catégorie');
    expect(count.textContent?.trim()).toBe('1 transaction');
  });

  it('should_group_transactions_by_category', async () => {
    const fixture = await createFixture(undefined, () => {
      transactionServiceMock.getByMonth.mockReturnValue(
        of([makeTransaction({ id: 'tx-1' }), makeTransaction({ id: 'tx-2' })]),
      );
      budgetServiceMock.getOverview.mockReturnValue(
        of(overview({ unbudgetedItems: [unbudgetedItem()], unbudgetedTotal: 40 })),
      );
    });

    const groups = fixture.componentInstance.categoryGroups();
    expect(groups).toHaveLength(1);
    expect(groups[0].transactions.map((t) => t.id)).toEqual(['tx-1', 'tx-2']);
  });

  it('should_load_history_when_a_past_month_is_requested', async () => {
    const fixture = await createFixture({ month: '2026-01' });

    expect(budgetServiceMock.getHistory).toHaveBeenCalledWith('2026-01');
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_navigate_back_to_budgets_on_go_back', async () => {
    const fixture = await createFixture();

    fixture.componentInstance.goBack();

    expect(routerMock.navigate).toHaveBeenCalledWith(['/budgets']);
  });

  it('should_open_the_create_budget_modal', async () => {
    const fixture = await createFixture();

    fixture.componentInstance.onCreateBudget();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('budget');
  });
});
