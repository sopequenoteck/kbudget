import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { of, throwError } from 'rxjs';
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
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

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
    language: signal<string | null>(null),
    loaded: signal(false),
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
        provideTranslocoTesting(),
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

  // -------------------------------------------------------------------------
  // Libellé de date relative — branches de getRelativeDateInfo
  // -------------------------------------------------------------------------

  it('should_return_days_overdue_label_when_negative_diff_is_more_than_one_day', () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);
    const fixture = TestBed.createComponent(RecurringList);
    const component = fixture.componentInstance;

    const threeDaysAgo = new Date(today);
    threeDaysAgo.setDate(today.getDate() - 3);

    expect(component.getRelativeDateInfo(toDateStr(threeDaysAgo))).toEqual({
      key: 'recurring.list.daysOverdue',
      params: { count: 3 },
    });
  });

  it('should_return_hier_label_when_negative_diff_is_one_day', () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);
    const fixture = TestBed.createComponent(RecurringList);
    const component = fixture.componentInstance;

    expect(component.getRelativeDateInfo(toDateStr(yesterday))).toEqual({ key: 'recurring.list.yesterday' });
  });

  it('should_return_aujourdhui_label_when_diff_is_zero', () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);
    const fixture = TestBed.createComponent(RecurringList);
    const component = fixture.componentInstance;

    expect(component.getRelativeDateInfo(toDateStr(today))).toEqual({ key: 'recurring.list.today' });
  });

  it('should_return_demain_label_when_diff_is_one_day', () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);
    const fixture = TestBed.createComponent(RecurringList);
    const component = fixture.componentInstance;

    expect(component.getRelativeDateInfo(toDateStr(tomorrow))).toEqual({ key: 'recurring.list.tomorrow' });
  });

  it('should_return_days_count_label_when_diff_is_between_two_and_thirty', () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);
    const fixture = TestBed.createComponent(RecurringList);
    const component = fixture.componentInstance;

    const inTenDays = new Date(today);
    inTenDays.setDate(today.getDate() + 10);

    expect(component.getRelativeDateInfo(toDateStr(inTenDays))).toEqual({
      key: 'recurring.list.daysUntil',
      params: { count: 10 },
    });
  });

  it('should_return_short_localized_date_when_diff_is_more_than_thirty_days', () => {
    const mockService = createMockService([]);
    setupTestBed(mockService);
    const fixture = TestBed.createComponent(RecurringList);
    const component = fixture.componentInstance;

    const inFortyFiveDays = new Date(today);
    inFortyFiveDays.setDate(today.getDate() + 45);

    const result = component.getRelativeDateInfo(toDateStr(inFortyFiveDays));
    expect(result.key).toBeUndefined();
    expect(result.formatted).toBeTruthy();
  });

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

  it('should_show_error_toast_when_validate_fails', async () => {
    const mockService = createMockService([overdueItem]);
    mockService.validate = vi.fn().mockReturnValue(throwError(() => new Error('fail')));
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onValidate(overdueItem);

    expect(toastServiceMock.error).toHaveBeenCalledWith('Erreur lors de la validation');
    expect(component.actionInProgress()).toBeNull();
  });

  it('should_show_toast_after_successful_validate_all', async () => {
    const mockService = createMockService([overdueItem, upcomingItem]);
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onValidateAll([overdueItem, upcomingItem]);

    expect(toastServiceMock.success).toHaveBeenCalledWith('2 transactions validées');
    expect(component.actionInProgress()).toBeNull();
  });

  it('should_show_error_toast_when_validate_all_fails', async () => {
    const mockService = createMockService([overdueItem]);
    mockService.validate = vi.fn().mockReturnValue(throwError(() => new Error('fail')));
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onValidateAll([overdueItem]);

    expect(toastServiceMock.error).toHaveBeenCalledWith('Erreur lors de la validation');
    expect(component.actionInProgress()).toBeNull();
  });

  it('should_show_toast_after_successful_skip', async () => {
    const mockService = createMockService([overdueItem]);
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onSkip(overdueItem);

    expect(toastServiceMock.success).toHaveBeenCalledWith('Occurrence passée');
    expect(component.actionInProgress()).toBeNull();
  });

  it('should_show_error_toast_when_skip_fails', async () => {
    const mockService = createMockService([overdueItem]);
    mockService.skip = vi.fn().mockReturnValue(throwError(() => new Error('fail')));
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onSkip(overdueItem);

    expect(toastServiceMock.error).toHaveBeenCalledWith('Erreur lors du passage');
    expect(component.actionInProgress()).toBeNull();
  });

  it('should_show_toast_after_successful_deactivate', async () => {
    const mockService = createMockService([overdueItem]);
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onDeactivate(overdueItem);

    expect(toastServiceMock.success).toHaveBeenCalledWith('Récurrence désactivée');
    expect(component.actionInProgress()).toBeNull();
  });

  it('should_show_error_toast_when_deactivate_fails', async () => {
    const mockService = createMockService([overdueItem]);
    mockService.deactivate = vi.fn().mockReturnValue(throwError(() => new Error('fail')));
    setupTestBed(mockService);

    const fixture = TestBed.createComponent(RecurringList);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    await component.onDeactivate(overdueItem);

    expect(toastServiceMock.error).toHaveBeenCalledWith('Erreur lors de la désactivation');
    expect(component.actionInProgress()).toBeNull();
  });
});
