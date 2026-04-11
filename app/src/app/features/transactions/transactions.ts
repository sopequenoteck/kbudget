import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  DestroyRef,
  effect,
  ElementRef,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { Subscription, forkJoin } from 'rxjs';
import { TransactionService } from '../../core/services/transaction';
import { PreferenceService } from '../../core/services/preference';
import { ModalService } from '../../core/services/modal.service';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { CategoryService } from '../../core/services/category';
import { AccountService } from '../../core/services/account';
import { DevLogger } from '../../core/services/dev-logger';
import { Transaction, TransactionType, MonthlySummary } from '../../core/models/transaction.model';
import { Category } from '../../core/models/category.model';
import { Account } from '../../core/models/account.model';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorMagnifyingGlass,
  phosphorFunnel,
  phosphorArrowsClockwise,
  phosphorTrendUp,
  phosphorTrendDown,
  phosphorReceipt,
  phosphorX,
} from '@ng-icons/phosphor-icons/regular';
import { RouterLink } from '@angular/router';
import { EmptyState } from '../../shared/components/empty-state/empty-state';
import { APP_LOCALE } from '../../core/constants/locale.constants';

@Component({
  selector: 'app-transactions',
  standalone: true,
  imports: [AmountPipe, ConvertAmountPipe, NgIcon, RouterLink, EmptyState],
  providers: [
    provideIcons({
      phosphorMagnifyingGlass,
      phosphorFunnel,
      phosphorArrowsClockwise,
      phosphorTrendUp,
      phosphorTrendDown,
      phosphorReceipt,
      phosphorX,
    }),
  ],
  templateUrl: './transactions.html',
  styleUrl: './transactions.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Transactions implements AfterViewInit {
  private readonly transactionService = inject(TransactionService);
  private readonly modalService = inject(ModalService);
  private readonly categoryService = inject(CategoryService);
  private readonly accountService = inject(AccountService);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  private readonly searchInput = viewChild<ElementRef>('searchInput');
  private readonly logger = inject(DevLogger);
  readonly isStuck = signal(false);

  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly transactions = signal<Transaction[]>([]);
  readonly summaries = signal<MonthlySummary[]>([]);
  readonly categories = signal<Category[]>([]);
  readonly accounts = signal<Account[]>([]);

  readonly skeletonItems = Array(5);

  readonly activeCurrency = signal(this.preferenceService.primaryCurrency());

  // Expose enum pour le template
  readonly TransactionType = TransactionType;

  // Filtres
  readonly searchOpen = signal(false);
  readonly searchQuery = signal('');
  readonly filterOpen = signal(false);
  readonly typeFilter = signal<TransactionType | null>(null);
  readonly categoryFilter = signal<string | null>(null);
  readonly accountFilter = signal<string | null>(null);

  readonly hasActiveFilters = computed(() =>
    this.typeFilter() !== null ||
    this.categoryFilter() !== null ||
    this.accountFilter() !== null
  );

  readonly secondaryCurrency = computed(() => {
    const all = this.preferenceService.currencies();
    if (all.length < 2) return null;
    const active = this.activeCurrency();
    return all.find(c => c !== active) ?? null;
  });

  readonly activeSummary = computed((): MonthlySummary | null => {
    const summaries = this.summaries();
    if (summaries.length === 0) return null;
    const currency = this.activeCurrency();
    return summaries.find(s => s.currency === currency) ?? summaries[0];
  });

  readonly convertedRecettes = computed(() => {
    const summary = this.activeSummary();
    const sec = this.secondaryCurrency();
    if (!summary || !sec) return null;
    return this.conversionService.convert(summary.totalRecettes, summary.currency, sec);
  });

  readonly convertedDepenses = computed(() => {
    const summary = this.activeSummary();
    const sec = this.secondaryCurrency();
    if (!summary || !sec) return null;
    return this.conversionService.convert(summary.totalDepenses, summary.currency, sec);
  });

  readonly selectedMonthLabel = computed(() => {
    const date = new Date(this.selectedYear(), this.selectedMonth() - 1);
    return date.toLocaleDateString(APP_LOCALE, { month: 'long', year: 'numeric' });
  });

  readonly filteredTransactions = computed(() => {
    const all = this.transactions();
    const month = this.selectedMonth();
    const year = this.selectedYear();

    return all
      .filter((t) => {
        const d = new Date(t.date);
        return d.getMonth() + 1 === month && d.getFullYear() === year;
      })
      .filter(t => {
        const type = this.typeFilter();
        return type === null || t.type === type;
      })
      .filter(t => {
        const catId = this.categoryFilter();
        return catId === null || t.category?.id === catId;
      })
      .filter(t => {
        const accId = this.accountFilter();
        return accId === null || t.account?.id === accId;
      })
      .filter(t => {
        const q = this.searchQuery().trim().toLowerCase();
        if (!q) return true;
        return t.libelle.toLowerCase().includes(q)
          || (t.category?.nom?.toLowerCase().includes(q) ?? false)
          || (t.note?.toLowerCase().includes(q) ?? false);
      })
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  });

  readonly groupedTransactions = computed(() => {
    const transactions = this.filteredTransactions();
    if (transactions.length === 0) return [];

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today.getTime() - 86400000);
    const weekStart = new Date(today.getTime() - today.getDay() * 86400000 + 86400000); // lundi
    const lastWeekStart = new Date(weekStart.getTime() - 7 * 86400000);

    const groups = new Map<string, { label: string; total: number; transactions: Transaction[] }>();
    const order = ["Aujourd'hui", 'Hier', 'Cette semaine', 'Semaine dernière', 'Plus ancien'];
    for (const label of order) {
      groups.set(label, { label, total: 0, transactions: [] });
    }

    for (const t of transactions) {
      const d = new Date(t.date + 'T00:00:00');
      let label: string;
      if (d.getTime() >= today.getTime()) {
        label = "Aujourd'hui";
      } else if (d.getTime() >= yesterday.getTime()) {
        label = 'Hier';
      } else if (d.getTime() >= weekStart.getTime()) {
        label = 'Cette semaine';
      } else if (d.getTime() >= lastWeekStart.getTime()) {
        label = 'Semaine dernière';
      } else {
        label = 'Plus ancien';
      }
      const group = groups.get(label)!;
      group.transactions.push(t);
      group.total += t.type === TransactionType.RECETTE ? t.montant : -t.montant;
    }

    return order.map((label) => groups.get(label)!).filter((g) => g.transactions.length > 0);
  });

  readonly monthCategories = computed(() => {
    const all = this.transactions();
    const month = this.selectedMonth();
    const year = this.selectedYear();

    const monthTransactions = all.filter(t => {
      const d = new Date(t.date);
      return d.getMonth() + 1 === month && d.getFullYear() === year;
    });

    const countMap = new Map<string, { category: Category; count: number }>();
    for (const t of monthTransactions) {
      if (!t.category) continue;
      const existing = countMap.get(t.category.id);
      if (existing) {
        existing.count++;
      } else {
        countMap.set(t.category.id, { category: t.category, count: 1 });
      }
    }

    return [...countMap.values()]
      .sort((a, b) => b.count - a.count)
      .map(v => v.category);
  });

  readonly emptyStateConfig = computed(() => {
    if (this.searchQuery().trim()) {
      return { icon: 'phosphorMagnifyingGlass', message: 'Aucune transaction trouvée', ctaLabel: undefined };
    }
    if (this.hasActiveFilters()) {
      const type = this.typeFilter();
      const label = type === TransactionType.DEPENSE ? 'dépense'
        : type === TransactionType.RECETTE ? 'recette'
        : 'transaction';
      return { icon: 'phosphorFunnel', message: `Aucune ${label} en ${this.selectedMonthLabel()}`, ctaLabel: 'Réinitialiser les filtres' };
    }
    return { icon: 'phosphorReceipt', message: `Aucune transaction en ${this.selectedMonthLabel()}`, ctaLabel: 'Ajouter une transaction' };
  });

  private loadSub: Subscription | null = null;

  constructor() {
    effect(() => {
      this.transactionService.refreshTrigger();
      this.selectedMonth();
      this.selectedYear();
      this.loadData();
    });
  }

  ngAfterViewInit(): void {
    const sentinel = this.stickySentinel()?.nativeElement;
    if (!sentinel) return;

    const observer = new IntersectionObserver(
      ([entry]) => this.isStuck.set(!entry.isIntersecting),
      { threshold: 0 },
    );
    observer.observe(sentinel);
    this.destroyRef.onDestroy(() => observer.disconnect());
  }

  loadData(): void {
    this.loadSub?.unsubscribe();
    this.loading.set(true);
    this.error.set(false);
    this.exchangeRateService.loadRates();

    this.loadSub = forkJoin({
      transactions: this.transactionService.getAll(),
      summary: this.transactionService.getSummary(this.selectedMonth(), this.selectedYear()),
      categories: this.categoryService.getAll(),
      accounts: this.accountService.getAll(),
    }).subscribe({
      next: ({ transactions, summary, categories, accounts }) => {
        this.transactions.set(transactions);
        this.summaries.set(summary);
        this.categories.set(categories);
        this.accounts.set(accounts);
        this.loading.set(false);
      },
      error: (err) => {
        this.logger.error('Failed to load transactions', err);
        this.error.set(true);
        this.loading.set(false);
      },
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

  setActiveCurrency(currency: string): void {
    this.activeCurrency.set(currency);
  }

  getIcon(transaction: Transaction): string {
    return transaction.category?.icone ?? '📝';
  }

  getValueClass(transaction: Transaction): string {
    if (transaction.type === TransactionType.AJUSTEMENT) return 'amount-adjustment';
    return transaction.type === TransactionType.RECETTE ? 'amount-income' : 'amount-expense';
  }

  onTransactionPressed(transaction: Transaction): void {
    if (transaction.type === TransactionType.AJUSTEMENT) return;
    this.modalService.openModal('transaction', transaction);
  }

  onAddTransaction(): void {
    this.modalService.openModal('transaction');
  }

  toggleSearch(): void {
    const opening = !this.searchOpen();
    this.searchOpen.set(opening);
    if (opening) {
      setTimeout(() => this.searchInput()?.nativeElement.focus());
    } else {
      this.searchQuery.set('');
    }
    if (opening && this.filterOpen()) {
      this.filterOpen.set(false);
    }
  }

  toggleFilter(): void {
    const opening = !this.filterOpen();
    this.filterOpen.set(opening);
    if (opening && this.searchOpen()) {
      this.searchOpen.set(false);
      this.searchQuery.set('');
    }
  }

  setTypeFilter(type: TransactionType | null): void {
    this.typeFilter.set(this.typeFilter() === type ? null : type);
  }

  setCategoryFilter(categoryId: string): void {
    this.categoryFilter.set(this.categoryFilter() === categoryId ? null : categoryId);
  }

  setAccountFilter(accountId: string): void {
    this.accountFilter.set(this.accountFilter() === accountId ? null : accountId);
  }

  resetFilters(): void {
    this.typeFilter.set(null);
    this.categoryFilter.set(null);
    this.accountFilter.set(null);
  }
}
