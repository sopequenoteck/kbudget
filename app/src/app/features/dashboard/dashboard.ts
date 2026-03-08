import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { NgClass } from '@angular/common';
import { RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { TransactionService } from '../../core/services/transaction';
import { SubscriptionService } from '../../core/services/subscription';
import { DebtService } from '../../core/services/debt';
import { AccountService } from '../../core/services/account';
import { ConversionService } from '../../core/services/conversion';
import { PreferenceService } from '../../core/services/preference';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { CurrencyPillSelector } from './components/currency-pill-selector';
import { BudgetSummary } from './components/budget-summary/budget-summary';
import {
  type Transaction,
  TransactionType,
  type MonthlySummary,
} from '../../core/models/transaction.model';
import { type Subscription, Frequency } from '../../core/models/subscription.model';
import { type Debt, DebtType } from '../../core/models/debt.model';
import { type Account } from '../../core/models/account.model';

interface CurrencyTotal {
  currency: string;
  total: number;
}
import { ModalService } from '../../core/services/modal.service';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { RelativeDatePipe } from '../../shared/pipes/relative-date.pipe';

@Component({
  selector: 'app-dashboard',
  imports: [NgClass, RouterLink, ListItem, AmountPipe, RelativeDatePipe, CurrencyPillSelector, BudgetSummary],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Dashboard {
  private readonly transactionService = inject(TransactionService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly debtService = inject(DebtService);
  private readonly accountService = inject(AccountService);
  private readonly modalService = inject(ModalService);
  private readonly conversionService = inject(ConversionService);
  readonly preferenceService = inject(PreferenceService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly destroyRef = inject(DestroyRef);

  private persistTimeout: ReturnType<typeof setTimeout> | null = null;

  // -- Devise active --
  readonly activeCurrency = signal('EUR');
  readonly currencies = computed(() => this.preferenceService.currencies());

  // -- Comptes bancaires --
  readonly accountsLoading = signal(true);
  readonly accountsError = signal(false);
  readonly accounts = signal<Account[]>([]);

  readonly convertedTotalBalance = computed(() => {
    const active = this.accounts().filter((a) => a.actif);
    const targetCurrency = this.activeCurrency();
    let total = 0;
    let hasMissingRate = false;

    for (const a of active) {
      const cur = a.currency || 'EUR';
      if (cur === targetCurrency) {
        total += a.solde;
      } else {
        const converted = this.conversionService.convert(a.solde, cur, targetCurrency);
        if (converted !== null) {
          total += converted;
        } else {
          hasMissingRate = true;
        }
      }
    }

    return { total, hasMissingRate };
  });

  readonly accountTotalsByCurrency = computed<CurrencyTotal[]>(() => {
    const active = this.accounts().filter((a) => a.actif);
    const byCurrency = new Map<string, number>();
    for (const a of active) {
      const cur = a.currency || 'EUR';
      byCurrency.set(cur, (byCurrency.get(cur) ?? 0) + a.solde);
    }
    return Array.from(byCurrency.entries())
      .map(([currency, total]) => ({ currency, total }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  });

  // -- Bilan mensuel (US1) --
  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly summaryLoading = signal(true);
  readonly summaryError = signal(false);
  readonly summaries = signal<MonthlySummary[]>([]);

  readonly selectedMonthLabel = computed(() => {
    const date = new Date(this.selectedYear(), this.selectedMonth() - 1);
    return date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
  });

  // -- Dernières transactions (US2) --
  readonly transactionsLoading = signal(true);
  readonly transactionsError = signal(false);
  readonly transactions = signal<Transaction[]>([]);

  readonly recentTransactions = computed(() =>
    [...this.transactions()]
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 5),
  );

  // -- Abonnements actifs (US3) --
  readonly subscriptionsLoading = signal(true);
  readonly subscriptionsError = signal(false);
  readonly subscriptions = signal<Subscription[]>([]);

  readonly activeSubscriptions = computed(() =>
    [...this.subscriptions()].sort((a, b) => a.nom.localeCompare(b.nom)).slice(0, 3),
  );

  readonly monthlySubTotalsByCurrency = computed<CurrencyTotal[]>(() => {
    const byCurrency = new Map<string, number>();
    for (const s of this.subscriptions()) {
      const cur = s.currency || 'EUR';
      const monthly = s.frequence === Frequency.ANNUEL ? s.montant / 12 : s.montant;
      byCurrency.set(cur, (byCurrency.get(cur) ?? 0) + monthly);
    }
    return Array.from(byCurrency.entries())
      .map(([currency, total]) => ({ currency, total }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  });

  // -- Dettes en cours (US4) --
  readonly debtsLoading = signal(true);
  readonly debtsError = signal(false);
  readonly debts = signal<Debt[]>([]);

  readonly activeDebts = computed(() =>
    [...this.debts()]
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 3),
  );

  readonly totalJeDoisByCurrency = computed<CurrencyTotal[]>(() => {
    const byCurrency = new Map<string, number>();
    for (const d of this.debts().filter((d) => d.sens === DebtType.EMPRUNT)) {
      const cur = d.currency || 'EUR';
      byCurrency.set(cur, (byCurrency.get(cur) ?? 0) + d.montant);
    }
    return Array.from(byCurrency.entries())
      .map(([currency, total]) => ({ currency, total }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  });

  readonly totalOnMeDoitByCurrency = computed<CurrencyTotal[]>(() => {
    const byCurrency = new Map<string, number>();
    for (const d of this.debts().filter((d) => d.sens === DebtType.PRET)) {
      const cur = d.currency || 'EUR';
      byCurrency.set(cur, (byCurrency.get(cur) ?? 0) + d.montant);
    }
    return Array.from(byCurrency.entries())
      .map(([currency, total]) => ({ currency, total }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  });

  readonly miniCardsLoading = computed(() => this.subscriptionsLoading() || this.debtsLoading());

  constructor() {
    // Charger les taux de change et synchroniser la devise active au démarrage
    effect(() => {
      this.preferenceService.currencies();
      this.exchangeRateService.loadRates();
    });

    effect(() => {
      const primary = this.preferenceService.primaryCurrency();
      this.activeCurrency.set(primary);
    });

    effect(() => {
      this.accountService.refreshTrigger();
      this.transactionService.refreshTrigger();
      this.loadAccounts();
    });

    effect(() => {
      this.transactionService.refreshTrigger();
      this.selectedMonth();
      this.selectedYear();
      this.loadSummary();
    });

    effect(() => {
      this.transactionService.refreshTrigger();
      this.loadTransactions();
    });

    effect(() => {
      this.subscriptionService.refreshTrigger();
      this.loadSubscriptions();
    });

    effect(() => {
      this.debtService.refreshTrigger();
      this.loadDebts();
    });

    this.destroyRef.onDestroy(() => {
      if (this.persistTimeout) {
        clearTimeout(this.persistTimeout);
        const currencies = this.preferenceService.currencies();
        this.preferenceService.update({ currencies });
      }
    });
  }

  prevMonth(): void {
    if (this.selectedMonth() === 1) {
      this.selectedMonth.set(12);
      this.selectedYear.update((y) => y - 1);
    } else {
      this.selectedMonth.update((m) => m - 1);
    }
  }

  nextMonth(): void {
    if (this.selectedMonth() === 12) {
      this.selectedMonth.set(1);
      this.selectedYear.update((y) => y + 1);
    } else {
      this.selectedMonth.update((m) => m + 1);
    }
  }

  async loadAccounts(): Promise<void> {
    this.accountsLoading.set(true);
    this.accountsError.set(false);

    try {
      const data = await firstValueFrom(this.accountService.getAll());
      this.accounts.set(data);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load accounts', err);
      }
      this.accountsError.set(true);
    } finally {
      this.accountsLoading.set(false);
    }
  }

  async loadSummary(): Promise<void> {
    this.summaryLoading.set(true);
    this.summaryError.set(false);

    try {
      const data = await firstValueFrom(
        this.transactionService.getSummary(this.selectedMonth(), this.selectedYear()),
      );
      this.summaries.set(data);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load summary', err);
      }
      this.summaryError.set(true);
    } finally {
      this.summaryLoading.set(false);
    }
  }

  async loadTransactions(): Promise<void> {
    this.transactionsLoading.set(true);
    this.transactionsError.set(false);

    try {
      const data = await firstValueFrom(this.transactionService.getAll());
      this.transactions.set(data);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load transactions', err);
      }
      this.transactionsError.set(true);
    } finally {
      this.transactionsLoading.set(false);
    }
  }

  async loadSubscriptions(): Promise<void> {
    this.subscriptionsLoading.set(true);
    this.subscriptionsError.set(false);

    try {
      const data = await firstValueFrom(this.subscriptionService.getAll(true));
      this.subscriptions.set(data);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load subscriptions', err);
      }
      this.subscriptionsError.set(true);
    } finally {
      this.subscriptionsLoading.set(false);
    }
  }

  async loadDebts(): Promise<void> {
    this.debtsLoading.set(true);
    this.debtsError.set(false);

    try {
      const data = await firstValueFrom(this.debtService.getAll(false));
      this.debts.set(data);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load debts', err);
      }
      this.debtsError.set(true);
    } finally {
      this.debtsLoading.set(false);
    }
  }

  onCurrencyChange(currency: string): void {
    this.activeCurrency.set(currency);

    // Reorder currencies : la devise sélectionnée en premier
    const current = this.currencies();
    const reordered = [currency, ...current.filter((c) => c !== currency)];
    this.preferenceService.setCurrencies(reordered);

    // Debounce persistance 2s
    if (this.persistTimeout) clearTimeout(this.persistTimeout);
    this.persistTimeout = setTimeout(() => {
      this.persistTimeout = null;
      this.preferenceService.update({ currencies: reordered });
      this.exchangeRateService.loadRates();
    }, 2000);
  }

  getTransactionIcon(t: Transaction): string {
    return t.category?.icone ?? '📝';
  }

  getTransactionValueClass(t: Transaction): string {
    return t.type === TransactionType.RECETTE ? 'amount-income' : 'amount-expense';
  }

  getDebtIcon(d: Debt): string {
    return d.category?.icone ?? (d.sens === DebtType.EMPRUNT ? '📤' : '📥');
  }

  getDebtValueClass(d: Debt): string {
    return d.sens === DebtType.EMPRUNT ? 'amount-expense' : 'amount-income';
  }

  onTransactionClick(t: Transaction): void {
    this.modalService.openModal('transaction', t);
  }

  onSubscriptionClick(s: Subscription): void {
    this.modalService.openModal('subscription', s);
  }

  onDebtClick(d: Debt): void {
    this.modalService.openModal('debt', d);
  }
}
