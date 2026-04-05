import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  DestroyRef,
  effect,
  ElementRef,
  inject,
  isDevMode,
  signal,
  viewChild,
} from '@angular/core';
import { Subscription } from 'rxjs';
import { forkJoin } from 'rxjs';
import { TransactionService } from '../../core/services/transaction';
import { PreferenceService } from '../../core/services/preference';
import { ModalService } from '../../core/services/modal.service';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { Transaction, TransactionType, MonthlySummary } from '../../core/models/transaction.model';
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
} from '@ng-icons/phosphor-icons/regular';
import { RouterLink } from '@angular/router';
import { EmptyState } from '../../shared/components/empty-state/empty-state';

@Component({
  selector: 'app-transactions',
  imports: [AmountPipe, ConvertAmountPipe, NgIcon, RouterLink, EmptyState],
  providers: [
    provideIcons({
      phosphorMagnifyingGlass,
      phosphorFunnel,
      phosphorArrowsClockwise,
      phosphorTrendUp,
      phosphorTrendDown,
      phosphorReceipt,
    }),
  ],
  templateUrl: './transactions.html',
  styleUrl: './transactions.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Transactions implements AfterViewInit {
  private readonly transactionService = inject(TransactionService);
  private readonly modalService = inject(ModalService);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);

  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly transactions = signal<Transaction[]>([]);
  readonly summaries = signal<MonthlySummary[]>([]);

  readonly skeletonItems = Array(5);

  readonly activeCurrency = signal(this.preferenceService.primaryCurrency());

  readonly secondaryCurrency = computed(() => {
    const all = this.preferenceService.currencies();
    if (all.length < 2) return null;
    const active = this.activeCurrency();
    return all.find(c => c !== active) ?? null;
  });

  readonly activeSummary = computed(() => {
    const currency = this.activeCurrency();
    return this.summaries().find(s => s.currency === currency) ?? this.summaries()[0] ?? null;
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
    return date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
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
    }).subscribe({
      next: ({ transactions, summary }) => {
        this.transactions.set(transactions);
        this.summaries.set(summary);
        this.loading.set(false);
      },
      error: (err) => {
        if (isDevMode()) {
          console.error('Failed to load transactions', err);
        }
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

}
