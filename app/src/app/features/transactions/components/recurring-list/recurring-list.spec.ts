import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { signal } from '@angular/core';
import { of } from 'rxjs';
import { Router } from '@angular/router';

import { RecurringList } from './recurring-list';
import { RecurringTransactionService } from '../../../../core/services/recurring-transaction';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { ConversionService } from '../../../../core/services/conversion';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { PreferenceService } from '../../../../core/services/preference';
import { RecurringTransactionResponse } from '../../../../core/models/recurring-transaction.model';
import { TransactionType } from '../../../../core/models/transaction.model';
import { Frequency } from '../../../../core/models/subscription.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

// ---------------------------------------------------------------------------
// Données de test
// ---------------------------------------------------------------------------

const today = new Date();
today.setHours(0, 0, 0, 0);

const yesterday = new Date(today);
yesterday.setDate(today.getDate() - 1);

const tomorrow = new Date(today);
tomorrow.setDate(today.getDate() + 1);

const toDateStr = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

const mockCategory = { id: 'cat-1', nom: 'Alimentation', icone: '🛒', couleur: '#f59e0b' };
const mockAccount = { id: 'acc-1', nom: 'Compte courant', icone: '🏦', couleur: '#4f46e5' };

const overdueItem: RecurringTransactionResponse = {
  id: 'rt-overdue',
  montant: 50,
  libelle: 'Loyer en retard',
  type: TransactionType.DEPENSE,
  frequency: Frequency.MENSUEL,
  nextOccurrence: toDateStr(yesterday),
  recurringActive: true,
  category: mockCategory,
  account: mockAccount,
};

const todayItem: RecurringTransactionResponse = {
  id: 'rt-today',
  montant: 30,
  libelle: "Abonnement d'aujourd'hui",
  type: TransactionType.DEPENSE,
  frequency: Frequency.MENSUEL,
  nextOccurrence: toDateStr(today),
  recurringActive: true,
  category: mockCategory,
  account: mockAccount,
};

const upcomingItem: RecurringTransactionResponse = {
  id: 'rt-upcoming',
  montant: 120,
  libelle: 'Salle de sport',
  type: TransactionType.DEPENSE,
  frequency: Frequency.ANNUEL,
  nextOccurrence: toDateStr(tomorrow),
  recurringActive: true,
  category: mockCategory,
  account: mockAccount,
};

// ---------------------------------------------------------------------------
// Factory mock service
// ---------------------------------------------------------------------------

function createMockService(
  items: RecurringTransactionResponse[] = [],
  opts: { loading?: boolean; error?: string | null } = {},
) {
  return {
    recurringTransactions: signal(items),
    loading: signal(opts.loading ?? false),
    error: signal(opts.error ?? null),
    loadActive: vi.fn().mockResolvedValue(undefined),
    validate: vi.fn().mockReturnValue(of({ id: 'tx-new' })),
    skip: vi.fn().mockReturnValue(of(items[0] ?? overdueItem)),
    deactivate: vi.fn().mockReturnValue(of(items[0] ?? overdueItem)),
  };
}

function createMockConversionService() {
  return {
    convert: vi.fn().mockReturnValue(null),
    canConvert: vi.fn().mockReturnValue(false),
    availableRates: signal([]),
    get primaryCurrency() {
      return 'EUR';
    },
  };
}

function createMockExchangeRateService() {
  return {
    rates: signal([]),
    loading: signal(false),
    error: signal(null),
    loadRates: vi.fn().mockResolvedValue(undefined),
  };
}

function createMockPreferenceService() {
  return {
    primaryCurrency: signal('EUR'),
    currencies: signal(['EUR']),
    enabledFeatures: signal([]),
  };
}

// ---------------------------------------------------------------------------
// Suite
// ---------------------------------------------------------------------------

describe('RecurringList', () => {
  let toastServiceMock: {
    success: ReturnType<typeof vi.fn>;
    error: ReturnType<typeof vi.fn>;
  };

  let routerMock: {
    navigate: ReturnType<typeof vi.fn>;
  };

  let conversionServiceMock: ReturnType<typeof createMockConversionService>;
  let exchangeRateServiceMock: ReturnType<typeof createMockExchangeRateService>;
  let preferenceServiceMock: ReturnType<typeof createMockPreferenceService>;

  beforeEach(() => {
    toastServiceMock = {
      success: vi.fn(),
      error: vi.fn(),
    };

    routerMock = {
      navigate: vi.fn(),
    };

    conversionServiceMock = createMockConversionService();
    exchangeRateServiceMock = createMockExchangeRateService();
    preferenceServiceMock = createMockPreferenceService();
  });

  const setupTestBed = (mockService: ReturnType<typeof createMockService>) => {
    TestBed.configureTestingModule({
      imports: [RecurringList],
      providers: [
        { provide: RecurringTransactionService, useValue: mockService },
        { provide: ToastService, useValue: toastServiceMock },
        { provide: Router, useValue: routerMock },
        { provide: ConversionService, useValue: conversionServiceMock },
        { provide: ExchangeRateService, useValue: exchangeRateServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
      ],
    });
  };

  // -------------------------------------------------------------------------
  // T012-1 : affichage de la liste
  // -------------------------------------------------------------------------

  it('should_display_recurring_transactions_list', async () => {
    const mockService = createMockService([overdueItem, upcomingItem]);
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    expect(component.sortedRecurringTransactions().length).toBe(2);
    expect(component.sortedRecurringTransactions().map((i) => i.id)).toContain('rt-overdue');
    expect(component.sortedRecurringTransactions().map((i) => i.id)).toContain('rt-upcoming');
  });

  // -------------------------------------------------------------------------
  // T012-2 : tri — overdue d'abord
  // -------------------------------------------------------------------------

  it('should_sort_by_status_overdue_first', async () => {
    // On fournit les items dans l'ordre inverse pour vérifier le tri
    const mockService = createMockService([upcomingItem, todayItem, overdueItem]);
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const sorted = fixture.componentInstance.sortedRecurringTransactions();
    expect(sorted[0].id).toBe('rt-overdue');
    expect(sorted[1].id).toBe('rt-today');
    expect(sorted[2].id).toBe('rt-upcoming');
  });

  // -------------------------------------------------------------------------
  // T012-3 : badge correct par statut
  // -------------------------------------------------------------------------

  it('should_display_correct_badge_for_each_status', () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    const component = fixture.componentInstance;

    expect(component.getStatus(toDateStr(yesterday))).toBe('overdue');
    expect(component.getStatus(toDateStr(today))).toBe('today');
    expect(component.getStatus(toDateStr(tomorrow))).toBe('upcoming');
  });

  // -------------------------------------------------------------------------
  // T012-4 : état vide
  // -------------------------------------------------------------------------

  it('should_display_empty_state_when_no_transactions', async () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    expect(component.sortedRecurringTransactions().length).toBe(0);

    const nativeEl: HTMLElement = fixture.nativeElement;
    const emptyState = nativeEl.querySelector('app-empty-state');
    expect(emptyState).not.toBeNull();
  });

  // -------------------------------------------------------------------------
  // T012-5 : boutons désactivés pendant une action
  // -------------------------------------------------------------------------

  it('should_disable_buttons_during_action', async () => {
    const mockService = createMockService([overdueItem]);
    // validate ne résout jamais pendant ce test (Promise pendante)
    mockService.validate = vi.fn().mockReturnValue(
      new (await import('rxjs')).Observable(() => {
        /* ne complète pas */
      }),
    );
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;

    // Lancer l'action sans await → actionInProgress devient l'id de l'item
    component.onValidate(overdueItem);

    expect(component.actionInProgress()).toBe('rt-overdue');
  });

  // -------------------------------------------------------------------------
  // T012-6 : toast succès après validate
  // -------------------------------------------------------------------------

  it('should_show_toast_after_successful_validate', async () => {
    const mockService = createMockService([overdueItem]);
    mockService.validate = vi.fn().mockReturnValue(of({ id: 'tx-new' }));
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onValidate(overdueItem);

    expect(toastServiceMock.success).toHaveBeenCalledWith('Transaction validée');
    expect(component.actionInProgress()).toBeNull();
  });
});
