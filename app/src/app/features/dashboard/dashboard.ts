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
import { DecimalPipe, NgClass } from '@angular/common';
import {NavigationEnd, Router, RouterLink} from '@angular/router';
import {filter, firstValueFrom} from 'rxjs';

import { TransactionService } from '../../core/services/transaction';
import { AccountService } from '../../core/services/account';
import { ConversionService } from '../../core/services/conversion';
import { PreferenceService } from '../../core/services/preference';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { BudgetService } from '../../core/services/budget';
import { CurrencyPillSelector } from './components/currency-pill-selector';
import { BudgetSummary } from './components/budget-summary/budget-summary';
import {
  type Transaction,
  TransactionType,
  type MonthlySummary,
} from '../../core/models/transaction.model';
import { type Account } from '../../core/models/account.model';
import { type BudgetOverview } from '../../core/models/budget.model';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { RelativeDatePipe } from '../../shared/pipes/relative-date.pipe';
import {toSignal} from '@angular/core/rxjs-interop';
import {AuthService} from '../../core/services/auth';

@Component({
  selector: 'app-dashboard',
  imports: [DecimalPipe, NgClass, RouterLink, ListItem, AmountPipe, RelativeDatePipe, CurrencyPillSelector, BudgetSummary],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Dashboard {
  private readonly transactionService = inject(TransactionService);
  private readonly accountService = inject(AccountService);
  private readonly budgetService = inject(BudgetService);
  readonly conversionService = inject(ConversionService);
  readonly preferenceService = inject(PreferenceService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  private persistTimeout: ReturnType<typeof setTimeout> | null = null;
  private autoRefreshTimer: ReturnType<typeof setInterval> | null = null;

  private readonly navigationEnd = toSignal(
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)),
  );
  readonly currentRoute = computed(() => {
    const e = this.navigationEnd();
    return e instanceof NavigationEnd ? e.urlAfterRedirects : this.router.url;
  });
  readonly isOnDashboard = computed(() => {
    const url = this.currentRoute();
    return url === '/dashboard' || url === '/';
  });

  readonly userName = this.authService.currentUser;

  // -- Devise active --
  readonly activeCurrency = signal('EUR');
  readonly currencies = computed(() => this.preferenceService.currencies());
  readonly secondaryCurrency = computed(() => {
    const all = this.currencies();
    if (all.length < 2) return null;
    const active = this.activeCurrency();
    const primary = this.preferenceService.primaryCurrency();
    if (active !== primary) return primary;
    return all.find(c => c !== active) ?? null;
  });

  // -- Comptes bancaires (total balance) --
  readonly totalBalanceLoading = signal(true);
  readonly totalBalanceError = signal(false);
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

  // Solde total en devise principale (premiere devise des preferences)
  readonly primaryCurrencyBalance = computed(() => {
    const active = this.accounts().filter((a) => a.actif);
    const primaryCurrency = this.preferenceService.primaryCurrency();
    let total = 0;

    for (const a of active) {
      const cur = a.currency || 'EUR';
      if (cur === primaryCurrency) {
        total += a.solde;
      } else {
        const converted = this.conversionService.convert(a.solde, cur, primaryCurrency);
        if (converted !== null) {
          total += converted;
        }
      }
    }

    return total;
  });

  // -- Bilan mensuel (mois courant + mois precedent) --
  readonly summaryLoading = signal(true);
  readonly summaryError = signal(false);
  readonly currentSummary = signal<MonthlySummary | null>(null);
  readonly previousSummary = signal<MonthlySummary | null>(null);

  // -- Budget overview --
  readonly budgetOverview = signal<BudgetOverview | null>(null);
  readonly budgetLoading = signal(true);
  readonly budgetCurrentMonth = computed(() => {
    return new Date().toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
  });

  // -- Dernières transactions --
  readonly transactionsLoading = signal(true);
  readonly transactionsError = signal(false);
  readonly transactions = signal<Transaction[]>([]);

  readonly recentTransactions = computed(() =>
    [...this.transactions()]
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 5),
  );

  // -- Computed signals derives --

  readonly netDuMois = computed(() => {
    const summary = this.currentSummary();
    if (!summary) return 0;
    return summary.totalRecettes - summary.totalDepenses;
  });

  readonly patrimoineDebutMois = computed(() => {
    return this.primaryCurrencyBalance() - this.netDuMois();
  });

  readonly variationPatrimoinePct = computed(() => {
    const debut = this.patrimoineDebutMois();
    if (debut === 0) return null;
    return (this.netDuMois() / debut) * 100;
  });

  readonly variationRevenus = computed(() => {
    const current = this.currentSummary()?.totalRecettes ?? 0;
    const previous = this.previousSummary()?.totalRecettes ?? 0;
    return current - previous;
  });

  readonly variationDepenses = computed(() => {
    const current = this.currentSummary()?.totalDepenses ?? 0;
    const previous = this.previousSummary()?.totalDepenses ?? 0;
    return current - previous;
  });

  readonly previousMonthName = computed(() => {
    const now = new Date();
    const prev = new Date(now.getFullYear(), now.getMonth() - 1);
    return prev.toLocaleDateString('fr-FR', { month: 'short' }).replace('.', '');
  });

  readonly sortedBudgetItems = computed(() => {
    const items = this.budgetOverview()?.items ?? [];
    return [...items]
      .sort((a, b) => {
        const aExceeded = a.percentage >= 100;
        const bExceeded = b.percentage >= 100;
        if (aExceeded !== bExceeded) return aExceeded ? -1 : 1;
        return b.percentage - a.percentage;
      })
      .slice(0, 4);
  });

  constructor() {
    // Charger les taux de change et synchroniser la devise active au demarrage
    effect(() => {
      this.preferenceService.currencies();
      this.exchangeRateService.loadRates();
    });

    effect(() => {
      const primary = this.preferenceService.primaryCurrency();
      this.activeCurrency.set(primary);
    });

    // Refresh au retour sur le dashboard (via refreshTrigger)
    effect(() => {
      this.accountService.refreshTrigger();
      this.transactionService.refreshTrigger();
      this.loadAll();
    });

    this.destroyRef.onDestroy(() => {
      if (this.persistTimeout) {
        clearTimeout(this.persistTimeout);
        const currencies = this.preferenceService.currencies();
        this.preferenceService.update({ currencies });
      }
      if (this.autoRefreshTimer) {
        clearInterval(this.autoRefreshTimer);
      }
    });

    // Auto-refresh toutes les 60s
    this.autoRefreshTimer = setInterval(() => this.silentRefresh(), 60_000);
  }

  async loadAll(): Promise<void> {
    await Promise.all([
      this.loadAccounts(),
      this.loadSummaries(),
      this.loadBudgetOverview(),
      this.loadTransactions(),
      this.exchangeRateService.loadRates(),
    ]);
  }

  async silentRefresh(): Promise<void> {
    try {
      const now = new Date();
      const prev = new Date(now.getFullYear(), now.getMonth() - 1);

      await Promise.all([
        firstValueFrom(this.accountService.getAll()).then((data) => this.accounts.set(data)),
        firstValueFrom(this.transactionService.getSummary(now.getMonth() + 1, now.getFullYear())).then((data) => this.currentSummary.set(data[0] ?? null)),
        firstValueFrom(this.transactionService.getSummary(prev.getMonth() + 1, prev.getFullYear())).then((data) => this.previousSummary.set(data[0] ?? null)),
        firstValueFrom(this.budgetService.getOverview()).then((data) => this.budgetOverview.set(data)),
        firstValueFrom(this.transactionService.getAll()).then((data) => this.transactions.set(data)),
        this.exchangeRateService.loadRates(),
      ]);
    } catch {
      // Silent fail — donnees existantes restent affichees
    }
  }

  async loadAccounts(): Promise<void> {
    this.totalBalanceLoading.set(true);
    this.totalBalanceError.set(false);

    try {
      const data = await firstValueFrom(this.accountService.getAll());
      this.accounts.set(data);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load accounts', err);
      }
      this.totalBalanceError.set(true);
    } finally {
      this.totalBalanceLoading.set(false);
    }
  }

  async loadSummaries(): Promise<void> {
    this.summaryLoading.set(true);
    this.summaryError.set(false);

    try {
      const now = new Date();
      const prev = new Date(now.getFullYear(), now.getMonth() - 1);

      const [current, previous] = await Promise.all([
        firstValueFrom(this.transactionService.getSummary(now.getMonth() + 1, now.getFullYear())),
        firstValueFrom(this.transactionService.getSummary(prev.getMonth() + 1, prev.getFullYear())),
      ]);

      this.currentSummary.set(current[0] ?? null);
      this.previousSummary.set(previous[0] ?? null);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load summaries', err);
      }
      this.summaryError.set(true);
    } finally {
      this.summaryLoading.set(false);
    }
  }

  async loadBudgetOverview(): Promise<void> {
    this.budgetLoading.set(true);

    try {
      const data = await firstValueFrom(this.budgetService.getOverview());
      this.budgetOverview.set(data);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load budget overview', err);
      }
    } finally {
      this.budgetLoading.set(false);
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

  getTransactionConvertedValue(t: Transaction): string {
    const txCurrency = t.account?.currency || 'EUR';
    const target = this.activeCurrency();
    if (txCurrency === target) return '';

    const converted = this.conversionService.convert(t.montant, txCurrency, target);
    if (converted === null) return '';

    const formatted = new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: target,
    }).format(Math.abs(converted));

    return `≈ ${formatted}`;
  }
}
