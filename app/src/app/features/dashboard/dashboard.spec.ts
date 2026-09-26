import { TestBed } from '@angular/core/testing';
import { signal, computed } from '@angular/core';
import { provideRouter } from '@angular/router';
import { of, throwError } from 'rxjs';

import { Dashboard } from './dashboard';
import { TransactionService } from '../../core/services/transaction';
import { AccountService } from '../../core/services/account';
import { BudgetService } from '../../core/services/budget';
import { ConversionService } from '../../core/services/conversion';
import { PreferenceService } from '../../core/services/preference';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { RecurringTransactionService } from '../../core/services/recurring-transaction';
import { DevLogger } from '../../core/services/dev-logger';
import { LanguageService } from '../../core/services/language';
import { AuthService } from '../../core/services/auth';
import { type Account, AccountType } from '../../core/models/account.model';
import { type MonthlySummary } from '../../core/models/transaction.model';
import { type BudgetOverview, type BudgetOverviewItem } from '../../core/models/budget.model';
import { type RecurringTransactionResponse } from '../../core/models/recurring-transaction.model';
import { type UserInfo } from '../../core/models/user.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

// Vendredi 13 mars 2026 — fige pour que la salutation (matin/apres-midi/soir)
// et le filtre "en retard" (`overdueCount`, base sur la date du jour) soient
// deterministes. Les tests tournent sous TZ=UTC (cf. consigne d'execution).
const MORNING = new Date(2026, 2, 13, 8, 0, 0);
const AFTERNOON = new Date(2026, 2, 13, 14, 0, 0);
const EVENING = new Date(2026, 2, 13, 21, 0, 0);

function makeAccount(overrides: Partial<Account> = {}): Account {
  return {
    id: 'acc-1',
    nom: 'Compte courant',
    type: AccountType.COURANT,
    soldeInitial: 0,
    solde: 1000,
    icone: '💰',
    couleur: '#000000',
    isDefault: true,
    actif: true,
    currency: 'EUR',
    bankCode: 'CUSTOM',
    bankName: null,
    bankCountry: null,
    bankBrandColor: null,
    bankLogoUrl: null,
    bankCustomName: null,
    bankCustomLogo: null,
    ...overrides,
  };
}

function makeSummary(overrides: Partial<MonthlySummary> = {}): MonthlySummary {
  return {
    month: 3,
    year: 2026,
    totalRecettes: 0,
    totalDepenses: 0,
    solde: 0,
    currency: 'EUR',
    ...overrides,
  };
}

const EMPTY_OVERVIEW: BudgetOverview = {
  month: '2026-03',
  totalBudget: 0,
  totalSpent: 0,
  percentage: 0,
  currency: 'EUR',
  items: [],
  unbudgetedItems: [],
  unbudgetedTotal: 0,
};

function makeBudgetItem(overrides: Partial<BudgetOverviewItem> = {}): BudgetOverviewItem {
  return {
    budgetId: 'budget-1',
    categoryId: 'cat-1',
    categoryNom: 'Loisirs',
    categoryIcone: '🎮',
    categoryCouleur: '#ff0000',
    montantBudget: 100,
    montantBudgetNormalise: 100,
    currency: 'EUR',
    montantDepense: 50,
    percentage: 50,
    frequence: 'MONTHLY',
    ...overrides,
  };
}

function makeRecurring(overrides: Partial<RecurringTransactionResponse> = {}): RecurringTransactionResponse {
  return {
    recurringActive: true,
    nextOccurrence: '2020-01-01',
    ...overrides,
  } as RecurringTransactionResponse;
}

interface RenderOptions {
  accounts?: Account[];
  accountsError?: boolean;
  currentSummary?: MonthlySummary | null;
  previousSummary?: MonthlySummary | null;
  budgetOverview?: BudgetOverview;
  budgetsEnabled?: boolean;
  recurringTransactions?: RecurringTransactionResponse[];
  userName?: UserInfo | null;
  now?: Date;
}

describe('Dashboard', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  async function render(options: RenderOptions = {}) {
    const {
      accounts = [makeAccount()],
      accountsError = false,
      currentSummary = null,
      previousSummary = null,
      budgetOverview = EMPTY_OVERVIEW,
      budgetsEnabled = false,
      recurringTransactions = [],
      userName = null,
      now = MORNING,
    } = options;

    vi.useFakeTimers();
    vi.setSystemTime(now);

    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();
    const prevDate = new Date(now.getFullYear(), now.getMonth() - 1);
    const prevMonth = prevDate.getMonth() + 1;
    const prevYear = prevDate.getFullYear();
    const currencies = signal(['EUR']);

    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      imports: [Dashboard],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        {
          provide: TransactionService,
          useValue: {
            getSummary: vi.fn((month: number, year: number) => {
              if (month === currentMonth && year === currentYear) {
                return of(currentSummary ? [currentSummary] : []);
              }
              if (month === prevMonth && year === prevYear) {
                return of(previousSummary ? [previousSummary] : []);
              }
              return of([]);
            }),
            getAll: vi.fn().mockReturnValue(of([])),
            refreshTrigger: signal(0),
          },
        },
        {
          provide: AccountService,
          useValue: {
            getAll: vi.fn(() =>
              accountsError ? throwError(() => new Error('network down')) : of(accounts),
            ),
            refreshTrigger: signal(0),
          },
        },
        { provide: BudgetService, useValue: { getOverview: vi.fn().mockReturnValue(of(budgetOverview)) } },
        {
          provide: ConversionService,
          useValue: { convert: vi.fn((amount: number, from: string, to: string) => (from === to ? amount : null)) },
        },
        {
          provide: PreferenceService,
          useValue: {
            currencies,
            primaryCurrency: computed(() => currencies()[0] ?? 'EUR'),
            isEnabled: vi.fn().mockReturnValue(budgetsEnabled),
            setCurrencies: vi.fn(),
            update: vi.fn(),
          },
        },
        { provide: ExchangeRateService, useValue: { loadRates: vi.fn().mockResolvedValue(undefined) } },
        {
          provide: RecurringTransactionService,
          useValue: {
            recurringTransactions: signal(recurringTransactions),
            loadActive: vi.fn().mockResolvedValue(undefined),
          },
        },
        { provide: DevLogger, useValue: { error: vi.fn(), log: vi.fn(), warn: vi.fn() } },
        {
          provide: LanguageService,
          useValue: {
            displayLocale: vi.fn().mockReturnValue('fr-FR'),
            activeLanguage: vi.fn().mockReturnValue('fr'),
          },
        },
        { provide: AuthService, useValue: { currentUser: signal<UserInfo | null>(userName) } },
      ],
    });

    const fixture = TestBed.createComponent(Dashboard);
    fixture.detectChanges();
    // L'effet du constructeur declenche `loadAll()`, une chaine de Promise.all
    // sur plusieurs appels async — plusieurs tours de microtaches sont
    // necessaires pour que tout se stabilise avant d'inspecter le DOM.
    for (let i = 0; i < 6; i++) {
      await Promise.resolve();
    }
    fixture.detectChanges();
    return fixture;
  }

  function text(fixture: { nativeElement: HTMLElement }): string {
    return fixture.nativeElement.textContent ?? '';
  }

  it('should_create_the_component', async () => {
    const fixture = await render();

    expect(fixture.componentInstance).toBeTruthy();
  });

  // ---------------------------------------------------------------------
  // Salutation (dashboard.summary.greeting*)
  // ---------------------------------------------------------------------

  it('should_render_morning_salutation_without_name', async () => {
    const fixture = await render({ now: MORNING, userName: null });

    expect(text(fixture)).toContain('Bonjour');
  });

  it('should_render_salutation_with_user_name_when_signed_in', async () => {
    const fixture = await render({
      now: MORNING,
      userName: { name: 'Kelly', email: 'kelly@test.com', mustResetCredentials: false },
    });

    expect(text(fixture)).toContain('Bonjour Kelly');
  });

  it('should_render_afternoon_salutation', async () => {
    const fixture = await render({ now: AFTERNOON });

    expect(text(fixture)).toContain('Bon après-midi');
  });

  it('should_render_evening_salutation', async () => {
    const fixture = await render({ now: EVENING });

    expect(text(fixture)).toContain('Bonsoir');
  });

  // ---------------------------------------------------------------------
  // Statut du mois (dashboard.summary.greetingStatus)
  // ---------------------------------------------------------------------

  it('should_render_quiet_month_status_and_zero_amounts_by_default', async () => {
    const fixture = await render();
    const content = text(fixture);

    expect(content).toContain('Mois calme');
    expect(content).toContain('0 recettes');
    expect(content).toContain('0 dépenses');
  });

  it('should_render_positive_month_status_when_net_is_positive', async () => {
    const fixture = await render({
      currentSummary: makeSummary({ totalRecettes: 200, totalDepenses: 50 }),
    });

    expect(text(fixture)).toContain('Mois positif');
  });

  it('should_render_negative_month_status_when_net_is_negative', async () => {
    const fixture = await render({
      currentSummary: makeSummary({ totalRecettes: 50, totalDepenses: 200 }),
    });

    expect(text(fixture)).toContain('Mois négatif');
  });

  it('should_render_overdue_recurring_status_with_correct_plural', async () => {
    const singular = await render({ recurringTransactions: [makeRecurring()] });
    expect(text(singular)).toContain('1 charge en retard');

    const plural = await render({ recurringTransactions: [makeRecurring(), makeRecurring({ id: 'r2' })] });
    expect(text(plural)).toContain('2 charges en retard');
  });

  it('should_render_exceeded_budget_status_with_correct_plural', async () => {
    const singular = await render({
      budgetOverview: { ...EMPTY_OVERVIEW, items: [makeBudgetItem({ percentage: 150 })] },
    });
    expect(text(singular)).toContain('1 budget dépassé');

    const plural = await render({
      budgetOverview: {
        ...EMPTY_OVERVIEW,
        items: [makeBudgetItem({ percentage: 150 }), makeBudgetItem({ budgetId: 'budget-2', percentage: 120 })],
      },
    });
    expect(text(plural)).toContain('2 budgets dépassés');
  });

  it('should_prioritise_overdue_recurring_over_exceeded_budget', async () => {
    // greetingStatus() : la charge en retard passe avant le budget depasse.
    const fixture = await render({
      recurringTransactions: [makeRecurring()],
      budgetOverview: { ...EMPTY_OVERVIEW, items: [makeBudgetItem({ percentage: 150 })] },
    });

    const content = text(fixture);
    expect(content).toContain('charge en retard');
    expect(content).not.toContain('budget dépassé');
  });

  // ---------------------------------------------------------------------
  // Patrimoine / variation mensuelle
  // ---------------------------------------------------------------------

  it('should_render_net_worth_label', async () => {
    const fixture = await render();
    const label = fixture.nativeElement.querySelector('.hero__amount-label');

    expect(label?.textContent?.trim()).toBe('Patrimoine total');
  });

  it('should_render_month_variation_amount', async () => {
    const fixture = await render({
      currentSummary: makeSummary({ totalRecettes: 200, totalDepenses: 50 }),
    });
    const badge = fixture.nativeElement.querySelector('.variation-badge');

    expect(badge?.textContent).toContain('ce mois');
    expect(badge?.textContent).toContain('150');
  });

  it('should_render_missing_rate_conversion_hint_when_a_currency_cannot_be_converted', async () => {
    const fixture = await render({
      accounts: [makeAccount({ currency: 'EUR' }), makeAccount({ id: 'acc-2', currency: 'USD', solde: 50 })],
    });
    const icon = fixture.nativeElement.querySelector('.missing-rate-icon');

    expect(icon?.getAttribute('title')).toBe('Certains montants n\'ont pas pu être convertis');
  });

  // ---------------------------------------------------------------------
  // Etats des comptes
  // ---------------------------------------------------------------------

  it('should_render_accounts_error_state', async () => {
    const fixture = await render({ accountsError: true });
    const stateError = fixture.nativeElement.querySelector('.state-error');

    expect(stateError?.querySelector('p')?.textContent).toBe('Erreur de chargement des comptes');
    expect(stateError?.querySelector('button')?.textContent?.trim()).toBe('Réessayer');
  });

  it('should_render_accounts_empty_state', async () => {
    const fixture = await render({ accounts: [] });

    expect(text(fixture)).toContain('Aucun compte');
    expect(text(fixture)).toContain('Créer mon premier compte');
  });

  // ---------------------------------------------------------------------
  // En-tetes de section
  // ---------------------------------------------------------------------

  it('should_render_budgets_and_recent_transactions_section_headers', async () => {
    const fixture = await render({
      budgetsEnabled: true,
      budgetOverview: { ...EMPTY_OVERVIEW, items: [makeBudgetItem()] },
    });
    const root = fixture.nativeElement as HTMLElement;
    const titles = Array.from(root.querySelectorAll('.dashboard-section__title')).map((el) =>
      el.textContent?.trim(),
    );
    const links = Array.from(root.querySelectorAll('.dashboard-section__link')).map((el) =>
      el.textContent?.trim(),
    );

    expect(titles.some((title) => title?.startsWith('Budgets ·'))).toBe(true);
    expect(titles).toContain('Dernières opérations');
    expect(links).toEqual(['Voir tout', 'Voir tout']);
  });

  it('should_render_transactions_empty_state', async () => {
    const fixture = await render();

    expect(text(fixture)).toContain('Aucune transaction');
  });
});
