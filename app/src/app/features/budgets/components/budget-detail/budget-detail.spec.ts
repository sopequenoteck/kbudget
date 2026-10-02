import { TestBed } from '@angular/core/testing';
import { signal, computed } from '@angular/core';
import { ActivatedRoute, convertToParamMap, Router } from '@angular/router';
import { of } from 'rxjs';

import { BudgetDetail } from './budget-detail';
import { BudgetService } from '../../../../core/services/budget';
import { TransactionService } from '../../../../core/services/transaction';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { PreferenceService } from '../../../../core/services/preference';
import { ConversionService } from '../../../../core/services/conversion';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { DevLogger } from '../../../../core/services/dev-logger';
import { type BudgetOverview, type BudgetOverviewItem } from '../../../../core/models/budget.model';
import { type Transaction, TransactionType } from '../../../../core/models/transaction.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';
import { stubIntersectionObserver } from '../../../../../testing/intersection-observer-stub';

// Mardi 17 mars 2026, 10h — fige pour que le regroupement des transactions
// (aujourd'hui / hier / date formatee) soit deterministe.
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

function overview(items: BudgetOverviewItem[]): BudgetOverview {
  return {
    month: '2026-03',
    totalBudget: 200,
    totalSpent: 100,
    percentage: 50,
    currency: 'EUR',
    items,
    unbudgetedItems: [],
    unbudgetedTotal: 0,
  };
}

function makeTransaction(overrides: Partial<Transaction> = {}): Transaction {
  return {
    id: 'tx-1',
    type: TransactionType.DEPENSE,
    montant: 20,
    date: '2026-03-17',
    libelle: 'Supermarché',
    category: { id: 'courses', nom: 'Courses', icone: '🛒', couleur: '#3b82f6', isSystem: false },
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

describe('BudgetDetail', () => {
  let budgetServiceMock: {
    getOverview: ReturnType<typeof vi.fn>;
    getHistory: ReturnType<typeof vi.fn>;
    getAll: ReturnType<typeof vi.fn>;
    getById: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };
  let transactionServiceMock: { getByMonth: ReturnType<typeof vi.fn> };
  let modalServiceMock: { openModal: ReturnType<typeof vi.fn> };
  let confirmServiceMock: { confirmDelete: ReturnType<typeof vi.fn> };
  let exchangeRateServiceMock: { loadRates: ReturnType<typeof vi.fn> };
  let devLoggerMock: { error: ReturnType<typeof vi.fn> };
  let routerMock: { navigate: ReturnType<typeof vi.fn> };

  const setupTestBed = (queryParams: Record<string, string> = { budgetId: 'courses' }) => {
    budgetServiceMock = {
      getOverview: vi.fn().mockReturnValue(of(overview([overviewItem()]))),
      getHistory: vi.fn().mockReturnValue(of(overview([overviewItem()]))),
      getAll: vi.fn().mockReturnValue(of([])),
      getById: vi.fn(),
      update: vi.fn().mockReturnValue(of(undefined)),
      delete: vi.fn().mockReturnValue(of(undefined)),
    };
    transactionServiceMock = { getByMonth: vi.fn().mockReturnValue(of([])) };
    modalServiceMock = { openModal: vi.fn() };
    confirmServiceMock = { confirmDelete: vi.fn().mockResolvedValue(true) };
    exchangeRateServiceMock = { loadRates: vi.fn().mockResolvedValue(undefined) };
    devLoggerMock = { error: vi.fn() };
    routerMock = { navigate: vi.fn() };

    const currencies = signal(['EUR']);

    TestBed.configureTestingModule({
      imports: [BudgetDetail],
      providers: [
        ...provideTranslocoTesting(),
        { provide: BudgetService, useValue: budgetServiceMock },
        { provide: TransactionService, useValue: transactionServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ConfirmService, useValue: confirmServiceMock },
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
    const fixture = TestBed.createComponent(BudgetDetail);
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

  it('should_load_the_current_month_overview_by_default', async () => {
    const fixture = await createFixture();

    expect(budgetServiceMock.getOverview).toHaveBeenCalled();
    expect(fixture.componentInstance.budgetItem()?.categoryNom).toBe('Courses');
  });

  it('should_load_history_when_a_past_month_is_requested', async () => {
    const fixture = await createFixture({ budgetId: 'courses', month: '2026-01' });

    expect(budgetServiceMock.getHistory).toHaveBeenCalledWith('2026-01');
    expect(fixture.componentInstance.budgetItem()?.categoryNom).toBe('Courses');
  });

  it('should_render_the_french_not_found_message_when_no_budget_item_matches', async () => {
    const fixture = await createFixture({ budgetId: 'inconnu' }, () => {
      budgetServiceMock.getOverview.mockReturnValue(of(overview([])));
    });

    const empty: HTMLElement = fixture.nativeElement.querySelector('.empty-state__message');
    expect(empty?.textContent?.trim()).toBe('Budget introuvable');
  });

  it('should_render_the_french_fallback_title_while_the_budget_is_not_found', async () => {
    const fixture = await createFixture({ budgetId: 'inconnu' }, () => {
      budgetServiceMock.getOverview.mockReturnValue(of(overview([])));
    });

    const title: HTMLElement = fixture.nativeElement.querySelector('.page-header__title');
    expect(title.textContent?.trim()).toBe('Budget');
  });

  it('should_group_transactions_by_today_yesterday_and_formatted_date', async () => {
    const fixture = await createFixture(undefined, () => {
      transactionServiceMock.getByMonth.mockReturnValue(
        of([
          makeTransaction({ id: 'tx-today', date: '2026-03-17' }),
          makeTransaction({ id: 'tx-yesterday', date: '2026-03-16' }),
          makeTransaction({ id: 'tx-older', date: '2026-03-10' }),
        ]),
      );
    });

    const groups = fixture.componentInstance.groupedTransactions();

    expect(groups.map((g) => g.key)).toEqual(['today', 'yesterday', '2026-03-10']);
    expect(groups[0]).toMatchObject({ labelKey: 'common.value.today', label: null });
    expect(groups[1]).toMatchObject({ labelKey: 'common.value.yesterday', label: null });
    expect(groups[2].labelKey).toBeNull();
    expect(groups[2].label).toBe('10 mars');
  });

  it('should_render_the_translated_today_and_yesterday_labels', async () => {
    const fixture = await createFixture(undefined, () => {
      transactionServiceMock.getByMonth.mockReturnValue(
        of([
          makeTransaction({ id: 'tx-today', date: '2026-03-17' }),
          makeTransaction({ id: 'tx-yesterday', date: '2026-03-16' }),
        ]),
      );
    });

    const labels = Array.from(fixture.nativeElement.querySelectorAll('.date-label')).map((el) =>
      (el as HTMLElement).textContent?.trim(),
    );
    expect(labels).toEqual(["Aujourd'hui", 'Hier']);
  });

  it('should_render_the_french_empty_transactions_message', async () => {
    const fixture = await createFixture();

    const empty: HTMLElement = fixture.nativeElement.querySelector('.empty-state__message');
    expect(empty?.textContent?.trim()).toBe('Aucune transaction ce mois');
  });

  it('should_navigate_back_to_budgets_on_go_back', async () => {
    const fixture = await createFixture();

    fixture.componentInstance.goBack();

    expect(routerMock.navigate).toHaveBeenCalledWith(['/budgets']);
  });

  it('should_open_the_edit_modal_with_the_loaded_budget', async () => {
    const fixture = await createFixture(undefined, () => {
      budgetServiceMock.getById.mockReturnValue(
        of({ id: 'budget-1', category: { id: 'courses', nom: 'Courses', icone: '🛒', couleur: '#3b82f6' } }),
      );
    });

    await fixture.componentInstance.onEdit();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('budget', expect.objectContaining({ id: 'budget-1' }));
  });

  it('should_toggle_active_and_navigate_back_to_budgets', async () => {
    const fixture = await createFixture(undefined, () => {
      budgetServiceMock.getById.mockReturnValue(
        of({
          id: 'budget-1',
          category: { id: 'courses' },
          montant: 200,
          currency: 'EUR',
          frequence: 'MENSUEL',
          seuilNotification: 80,
          actif: true,
        }),
      );
    });

    await fixture.componentInstance.onToggleActive();

    expect(budgetServiceMock.update).toHaveBeenCalledWith('budget-1', expect.objectContaining({ actif: false }));
    expect(routerMock.navigate).toHaveBeenCalledWith(['/budgets']);
  });

  it('should_delete_the_budget_with_a_french_confirmation_title_when_confirmed', async () => {
    const fixture = await createFixture();

    await fixture.componentInstance.onDelete();

    const call = confirmServiceMock.confirmDelete.mock.calls[0][0];
    expect(call.title).toContain('Courses');
    expect(call.message).toBe('Voulez-vous vraiment supprimer ce budget ?');
    expect(budgetServiceMock.delete).toHaveBeenCalledWith('budget-1');
    expect(routerMock.navigate).toHaveBeenCalledWith(['/budgets']);
  });

  it('should_not_delete_the_budget_when_not_confirmed', async () => {
    const fixture = await createFixture(undefined, () => {
      confirmServiceMock.confirmDelete.mockResolvedValue(false);
    });

    await fixture.componentInstance.onDelete();

    expect(budgetServiceMock.delete).not.toHaveBeenCalled();
  });
});
