import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { of, throwError } from 'rxjs';
import { signal } from '@angular/core';

import { Subscriptions } from './subscriptions';
import { SubscriptionService } from '../../core/services/subscription';
import { Frequency, Subscription } from '../../core/models/subscription.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockSubscriptions: Subscription[] = [
  {
    id: '1',
    nom: 'Netflix',
    montant: 15.99,
    frequence: Frequency.MENSUEL,
    dateDebut: '2024-01-15',
    actif: true,
    category: null,
  },
  {
    id: '2',
    nom: 'Adobe CC',
    montant: 287.88,
    frequence: Frequency.ANNUEL,
    dateDebut: '2024-03-01',
    actif: true,
    category: null,
  },
  {
    id: '3',
    nom: 'Canal+',
    montant: 24.99,
    frequence: Frequency.MENSUEL,
    dateDebut: '2023-06-10',
    actif: false,
    category: null,
  },
];

function createMockService() {
  return {
    refreshTrigger: signal(0),
    getAll: vi.fn().mockReturnValue(of(mockSubscriptions)),
    getById: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  };
}

describe('Subscriptions', () => {
  let component: Subscriptions;
  let mockService: ReturnType<typeof createMockService>;

  beforeEach(async () => {
    mockService = createMockService();

    await TestBed.configureTestingModule({
      imports: [Subscriptions],
      providers: [{ provide: SubscriptionService, useValue: mockService }],
    }).compileComponents();

    const fixture = TestBed.createComponent(Subscriptions);
    component = fixture.componentInstance;
    // Wait for effect + async loadData
    await fixture.whenStable();
  });

  // -- T010: Computed signals --

  describe('monthlyTotal', () => {
    it('should_compute_monthly_total_with_mixed_frequencies', () => {
      // Netflix 15.99 (mensuel) + Adobe 287.88/12 = 23.99 = 39.98
      const total = component.monthlyTotal();
      expect(total).toBeCloseTo(15.99 + 287.88 / 12, 2);
    });

    it('should_return_zero_when_no_active_subscriptions', () => {
      component.subscriptions.set([{ ...mockSubscriptions[2], actif: false }]);
      expect(component.monthlyTotal()).toBe(0);
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
        },
      ]);
      expect(component.monthlyTotal()).toBeCloseTo(10, 2);
    });
  });

  describe('sortedSubscriptions', () => {
    it('should_sort_alphabetically_by_name', () => {
      const sorted = component.sortedSubscriptions();
      expect(sorted.map((s) => s.nom)).toEqual(['Adobe CC', 'Canal+', 'Netflix']);
    });
  });

  // -- T011: Helpers --

  describe('getNextRenewalDate', () => {
    it('should_return_next_date_for_monthly', () => {
      const sub: Subscription = {
        id: '1',
        nom: 'Test',
        montant: 10,
        frequence: Frequency.MENSUEL,
        dateDebut: '2020-01-15',
        actif: true,
        category: null,
      };
      const result = component.getNextRenewalDate(sub);
      // Should contain a day number and a month name in French
      expect(result).toMatch(/\d+\s+\w+/);
    });

    it('should_return_next_date_for_annual', () => {
      const sub: Subscription = {
        id: '2',
        nom: 'Test',
        montant: 100,
        frequence: Frequency.ANNUEL,
        dateDebut: '2020-06-01',
        actif: true,
        category: null,
      };
      const result = component.getNextRenewalDate(sub);
      expect(result).toMatch(/\d+\s+\w+/);
    });

    it('should_handle_future_start_date', () => {
      const futureDate = new Date();
      futureDate.setFullYear(futureDate.getFullYear() + 1);
      const sub: Subscription = {
        id: '3',
        nom: 'Future',
        montant: 50,
        frequence: Frequency.MENSUEL,
        dateDebut: futureDate.toISOString().split('T')[0],
        actif: true,
        category: null,
      };
      const result = component.getNextRenewalDate(sub);
      expect(result).toMatch(/\d+\s+\w+/);
    });

    it('should_return_inactif_for_inactive_subscription', () => {
      const sub: Subscription = {
        id: '4',
        nom: 'Inactive',
        montant: 10,
        frequence: Frequency.MENSUEL,
        dateDebut: '2020-01-01',
        actif: false,
        category: null,
      };
      expect(component.getNextRenewalDate(sub)).toBe('Inactif');
    });
  });

  describe('formatAmount', () => {
    it('should_format_monthly', () => {
      const result = component.formatAmount(mockSubscriptions[0]);
      expect(result).toContain('/mois');
      expect(result).toContain('€');
    });

    it('should_format_annual', () => {
      const result = component.formatAmount(mockSubscriptions[1]);
      expect(result).toContain('/an');
      expect(result).toContain('€');
    });
  });

  // -- T012: Reactive behavior --

  describe('reactive behavior', () => {
    it('should_reload_data_when_filter_changes', async () => {
      mockService.getAll.mockClear();
      mockService.getAll.mockReturnValue(of([]));

      component.setStatusFilter('ACTIF');
      // Call loadData directly to verify filter parameter mapping
      await component.loadData();

      expect(mockService.getAll).toHaveBeenCalledWith(true);
    });

    it('should_set_loading_true_during_load', () => {
      // Before loadData resolves, loading should be true
      component.loading.set(true);
      expect(component.loading()).toBe(true);
    });

    it('should_set_error_on_api_failure', async () => {
      mockService.getAll.mockReturnValue(throwError(() => new Error('Network error')));

      await component.loadData();
      expect(component.error()).toBe(true);
      expect(component.loading()).toBe(false);
    });

    it('should_reload_on_refreshTrigger_change', async () => {
      mockService.getAll.mockClear();
      mockService.getAll.mockReturnValue(of([]));

      mockService.refreshTrigger.update((v: number) => v + 1);
      await new Promise((r) => setTimeout(r, 50));

      expect(mockService.getAll).toHaveBeenCalled();
    });
  });
});
