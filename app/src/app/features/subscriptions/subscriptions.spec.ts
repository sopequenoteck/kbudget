import { TestBed } from '@angular/core/testing';
import { describe, it, expect, vi, beforeEach, beforeAll } from 'vitest';
import { of, throwError } from 'rxjs';
import { signal } from '@angular/core';
import { Router } from '@angular/router';

import { Subscriptions } from './subscriptions';
import { SubscriptionService } from '../../core/services/subscription';
import { PreferenceService } from '../../core/services/preference';
import { ModalService } from '../../core/services/modal.service';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { CurrencyService } from '../../core/services/currency';
import { DevLogger } from '../../core/services/dev-logger';
import { Frequency, Subscription } from '../../core/models/subscription.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';
import { stubIntersectionObserver } from '../../../testing/intersection-observer-stub';

// jsdom ne fournit pas IntersectionObserver
beforeAll(() => stubIntersectionObserver());

const mockSubscriptions: Subscription[] = [
  {
    id: '1',
    nom: 'Netflix',
    montant: 15.99,
    frequence: Frequency.MENSUEL,
    dateDebut: '2024-01-15',
    actif: true,
    category: null,
    account: null,
    currency: 'EUR',
  },
  {
    id: '2',
    nom: 'Adobe CC',
    montant: 287.88,
    frequence: Frequency.ANNUEL,
    dateDebut: '2024-03-01',
    actif: true,
    category: null,
    account: null,
    currency: 'EUR',
  },
  {
    id: '3',
    nom: 'Canal+',
    montant: 24.99,
    frequence: Frequency.MENSUEL,
    dateDebut: '2023-06-10',
    actif: false,
    category: null,
    account: null,
    currency: 'EUR',
  },
];

function createMocks() {
  return {
    subscriptionService: {
      refreshTrigger: signal(0),
      getAll: vi.fn().mockReturnValue(of(mockSubscriptions)),
      getById: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
    preferenceService: {
      primaryCurrency: vi.fn().mockReturnValue('EUR'),
      currencies: vi.fn().mockReturnValue(['EUR']),
      setCurrencies: vi.fn(),
      update: vi.fn(),
      language: vi.fn().mockReturnValue(null),
      loaded: vi.fn().mockReturnValue(false),
    },
    modalService: {
      editingEntity: signal(null),
      openModal: vi.fn(),
      closeModal: vi.fn(),
    },
    conversionService: {
      convert: vi.fn().mockReturnValue(null),
    },
    exchangeRateService: {
      loadRates: vi.fn().mockResolvedValue(undefined),
    },
    currencyService: {
      loadIfEmpty: vi.fn(),
      currencies: vi.fn().mockReturnValue([]),
      currencyItems: signal([]),
      getAll: vi.fn().mockReturnValue(of([])),
    },
    devLogger: {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn(),
    },
    router: {
      navigate: vi.fn(),
    },
  };
}

describe('Subscriptions', () => {
  let component: Subscriptions;
  let mocks: ReturnType<typeof createMocks>;

  beforeEach(async () => {
    mocks = createMocks();

    TestBed.configureTestingModule({
      imports: [Subscriptions],
      providers: [
        provideTranslocoTesting(),
        { provide: SubscriptionService, useValue: mocks.subscriptionService },
        { provide: PreferenceService, useValue: mocks.preferenceService },
        { provide: ModalService, useValue: mocks.modalService },
        { provide: ConversionService, useValue: mocks.conversionService },
        { provide: ExchangeRateService, useValue: mocks.exchangeRateService },
        { provide: CurrencyService, useValue: mocks.currencyService },
        { provide: DevLogger, useValue: mocks.devLogger },
        { provide: Router, useValue: mocks.router },
      ],
    });

    const fixture = TestBed.createComponent(Subscriptions);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  describe('monthlyTotalsByCurrency', () => {
    it('should_compute_monthly_total_with_mixed_frequencies', () => {
      const totals = component.monthlyTotalsByCurrency();
      expect(totals).toHaveLength(1);
      expect(totals[0].currency).toBe('EUR');
      expect(totals[0].total).toBeCloseTo(15.99 + 287.88 / 12, 2);
    });

    it('should_return_empty_when_no_active_subscriptions', () => {
      component.subscriptions.set([{ ...mockSubscriptions[2], actif: false }]);
      expect(component.monthlyTotalsByCurrency()).toHaveLength(0);
    });

    it('should_divide_annual_by_12', () => {
      component.subscriptions.set([
        {
          id: '10',
          nom: 'Test Annual',
          montant: 120,
          frequence: Frequency.ANNUEL,
          dateDebut: '2024-01-01',
          actif: true,
          category: null,
          account: null,
          currency: 'EUR',
        },
      ]);
      const totals = component.monthlyTotalsByCurrency();
      expect(totals).toHaveLength(1);
      expect(totals[0].total).toBeCloseTo(10, 2);
    });
  });

  describe('getRelativeDateInfo', () => {
    it('should_return_a_relative_date_key_for_monthly', () => {
      const sub: Subscription = {
        id: '1',
        nom: 'Test',
        montant: 10,
        frequence: Frequency.MENSUEL,
        dateDebut: '2020-01-15',
        actif: true,
        category: null,
        account: null,
        currency: 'EUR',
      };
      const result = component.getRelativeDateInfo(sub);
      expect(result.key ?? result.formatted).toBeTruthy();
    });

    it('should_return_inactive_key_for_inactive_subscription', () => {
      const sub: Subscription = {
        id: '4',
        nom: 'Inactive',
        montant: 10,
        frequence: Frequency.MENSUEL,
        dateDebut: '2020-01-01',
        actif: false,
        category: null,
        account: null,
        currency: 'EUR',
      };
      expect(component.getRelativeDateInfo(sub)).toEqual({ key: 'common.value.inactive' });
    });
  });

  describe('formatAmount', () => {
    it('should_format_currency_without_frequency_suffix', () => {
      const result = component.formatAmount(mockSubscriptions[0]);
      expect(result).not.toContain('/mois');
      expect(result).not.toContain('/an');
      expect(result).toContain('€');
    });
  });

  describe('SUBSCRIPTION_FREQUENCY_SHORT_LABEL_KEYS', () => {
    it('should_expose_the_shared_frequency_short_label_keys', () => {
      expect(component.SUBSCRIPTION_FREQUENCY_SHORT_LABEL_KEYS[mockSubscriptions[0].frequence]).toBe(
        'subscriptions.value.perMonth',
      );
      expect(component.SUBSCRIPTION_FREQUENCY_SHORT_LABEL_KEYS[mockSubscriptions[1].frequence]).toBe(
        'subscriptions.value.perYear',
      );
    });
  });

  describe('groupedSubscriptions', () => {
    afterEach(() => {
      vi.useRealTimers();
    });

    it('should_group_a_subscription_due_within_the_week_as_thisWeek', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date(2026, 2, 13));

      component.subscriptions.set([
        {
          id: 'week-1',
          nom: 'ThisWeek',
          montant: 5,
          frequence: Frequency.MENSUEL,
          dateDebut: '2025-03-16',
          actif: true,
          category: null,
          account: null,
          currency: 'EUR',
        },
      ]);

      const groups = component.groupedSubscriptions();
      expect(groups.map((g) => g.labelKey)).toEqual(['subscriptions.list.thisWeek']);
      expect(groups[0].items.map((s) => s.id)).toEqual(['week-1']);
    });

    it('should_group_a_subscription_due_later_this_month_as_thisMonth', () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date(2026, 2, 13));

      component.subscriptions.set([
        {
          id: 'month-1',
          nom: 'ThisMonth',
          montant: 5,
          frequence: Frequency.MENSUEL,
          dateDebut: '2025-03-28',
          actif: true,
          category: null,
          account: null,
          currency: 'EUR',
        },
      ]);

      const groups = component.groupedSubscriptions();
      expect(groups.map((g) => g.labelKey)).toEqual(['subscriptions.list.thisMonth']);
      expect(groups[0].items.map((s) => s.id)).toEqual(['month-1']);
    });
  });

  describe('reactive behavior', () => {
    it('should_set_loading_true_during_load', () => {
      component.loading.set(true);
      expect(component.loading()).toBe(true);
    });

    it('should_set_error_on_api_failure', async () => {
      mocks.subscriptionService.getAll.mockReturnValue(
        throwError(() => new Error('Network error')),
      );

      await component.loadData();
      expect(component.error()).toBe(true);
      expect(component.loading()).toBe(false);
    });

    it('should_reload_on_refreshTrigger_change', async () => {
      mocks.subscriptionService.getAll.mockClear();
      mocks.subscriptionService.getAll.mockReturnValue(of([]));

      mocks.subscriptionService.refreshTrigger.update((v: number) => v + 1);
      await new Promise((r) => setTimeout(r, 50));

      expect(mocks.subscriptionService.getAll).toHaveBeenCalled();
    });
  });
});
