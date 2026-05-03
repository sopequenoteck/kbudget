import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  computed,
  effect,
  inject,
  signal,
} from '@angular/core';
import { DecimalPipe, NgClass } from '@angular/common';
import {NavigationEnd, Router, RouterLink} from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorWarningCircle, phosphorTrendUp, phosphorTrendDown, phosphorReceipt } from '@ng-icons/phosphor-icons/regular';
import {filter, firstValueFrom} from 'rxjs';

import { TransactionService } from '../../core/services/transaction';
import { AccountService } from '../../core/services/account';
import { ConversionService } from '../../core/services/conversion';
import { PreferenceService } from '../../core/services/preference';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { BudgetService } from '../../core/services/budget';
import { RecurringTransactionService } from '../../core/services/recurring-transaction';
import { DevLogger } from '../../core/services/dev-logger';
import { APP_LOCALE } from '../../core/constants/locale.constants';
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
import { EmptyState } from '../../shared/components/empty-state/empty-state';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [DecimalPipe, NgClass, RouterLink, NgIcon, ListItem, AmountPipe, RelativeDatePipe, CurrencyPillSelector, BudgetSummary, EmptyState],
  providers: [provideIcons({ phosphorWarningCircle, phosphorTrendUp, phosphorTrendDown, phosphorReceipt })],
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
  private readonly recurringService = inject(RecurringTransactionService);
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);
  private readonly logger = inject(DevLogger);

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
    return new Date().toLocaleDateString(APP_LOCALE, { month: 'long', year: 'numeric' });
  });

  // -- Dernières transactions --
  readonly transactionsLoading = signal(true);
  readonly transactionsError = signal(false);
  readonly transactions = signal<Transaction[]>([]);

  readonly skeletonItems = Array(3);

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

  // -- Montants summary convertis dans activeCurrency --
  readonly convertedRecettes = computed(() => {
    const summary = this.currentSummary();
    if (!summary || summary.totalRecettes === 0) return 0;
    const from = summary.currency || 'EUR';
    const to = this.activeCurrency();
    return this.conversionService.convert(summary.totalRecettes, from, to) ?? summary.totalRecettes;
  });

  readonly convertedDepenses = computed(() => {
    const summary = this.currentSummary();
    if (!summary || summary.totalDepenses === 0) return 0;
    const from = summary.currency || 'EUR';
    const to = this.activeCurrency();
    return this.conversionService.convert(summary.totalDepenses, from, to) ?? summary.totalDepenses;
  });

  readonly convertedNet = computed(() => {
    return this.convertedRecettes() - this.convertedDepenses();
  });

  readonly convertedPatrimoineDebutMois = computed(() => {
    return this.convertedTotalBalance().total - this.convertedNet();
  });

  readonly convertedVariationPct = computed(() => {
    const debut = this.convertedPatrimoineDebutMois();
    if (debut === 0) return null;
    return (this.convertedNet() / debut) * 100;
  });

  // -- Budget overview converti dans activeCurrency --
  readonly convertedBudgetOverview = computed<BudgetOverview | null>(() => {
    const ov = this.budgetOverview();
    if (!ov) return null;
    const from = ov.currency || 'EUR';
    const to = this.activeCurrency();
    if (from === to) return ov;

    const convert = (amount: number): number =>
      this.conversionService.convert(amount, from, to) ?? amount;

    return {
      ...ov,
      totalBudget: convert(ov.totalBudget),
      totalSpent: convert(ov.totalSpent),
      currency: to,
      unbudgetedTotal: convert(ov.unbudgetedTotal),
      unbudgetedItems: ov.unbudgetedItems.map(item => ({
        ...item,
        montantDepense: convert(item.montantDepense),
      })),
      items: ov.items.map(item => ({
        ...item,
        montantBudget: convert(item.montantBudget),
        montantBudgetNormalise: convert(item.montantBudgetNormalise),
        montantDepense: convert(item.montantDepense),
        currency: to,
      })),
    };
  });

  readonly convertedSortedBudgetItems = computed(() => {
    const items = this.convertedBudgetOverview()?.items ?? [];
    return [...items]
      .sort((a, b) => {
        const aExceeded = a.percentage >= 100;
        const bExceeded = b.percentage >= 100;
        if (aExceeded !== bExceeded) return aExceeded ? -1 : 1;
        return b.percentage - a.percentage;
      })
      .slice(0, 4);
  });

  readonly previousMonthName = computed(() => {
    const now = new Date();
    const prev = new Date(now.getFullYear(), now.getMonth() - 1);
    return prev.toLocaleDateString(APP_LOCALE, { month: 'short' }).replace('.', '');
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

  readonly overdueCount = computed(() => {
    const today = new Date().toISOString().split('T')[0];
    return this.recurringService.recurringTransactions()
      .filter(r => r.recurringActive && r.nextOccurrence < today)
      .length;
  });

  readonly exceededBudgetCount = computed(() => {
    return (this.budgetOverview()?.items ?? []).filter(b => b.percentage > 100).length;
  });

  readonly greeting = computed(() => {
    const hour = new Date().getHours();
    const name = this.userName()?.name;
    const salut = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    const prefix = name ? `${salut} ${name}` : salut;

    const overdue = this.overdueCount();
    if (overdue > 0) return `${prefix} · ${overdue} charge${overdue > 1 ? 's' : ''} en retard`;

    const exceeded = this.exceededBudgetCount();
    if (exceeded > 0) return `${prefix} · ${exceeded} budget${exceeded > 1 ? 's' : ''} dépassé${exceeded > 1 ? 's' : ''}`;

    const net = this.netDuMois();
    const hasTransactions = (this.currentSummary()?.totalRecettes ?? 0) > 0 || (this.currentSummary()?.totalDepenses ?? 0) > 0;
    if (hasTransactions) return `${prefix} · Mois ${net >= 0 ? 'positif' : 'négatif'}`;

    return `${prefix} · Mois calme`;
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
      this.recurringService.loadActive(),
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
        this.recurringService.loadActive(),
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
      this.logger.error('Failed to load accounts', err);
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
      this.logger.error('Failed to load summaries', err);
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
      this.logger.error('Failed to load budget overview', err);
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
      this.logger.error('Failed to load transactions', err);
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

    // Debounce persistance 2s + re-fetch summary/budget avec nouvelle devise principale
    if (this.persistTimeout) clearTimeout(this.persistTimeout);
    this.persistTimeout = setTimeout(async () => {
      this.persistTimeout = null;
      this.preferenceService.update({ currencies: reordered });
      await this.exchangeRateService.loadRates();
      this.loadSummaries();
      this.loadBudgetOverview();
    }, 2000);
  }

  goToAccounts(): void {
    this.router.navigate(['/settings/accounts']);
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

    const formatted = new Intl.NumberFormat(APP_LOCALE, {
      style: 'currency',
      currency: target,
    }).format(Math.abs(converted));

    return `≈ ${formatted}`;
  }
}
