import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  ElementRef,
  inject,
  isDevMode,
  OnDestroy,
  signal,
  viewChild,
} from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorArrowLeft, phosphorCheckCircle, phosphorPlus, phosphorSquaresFour } from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { BudgetService } from '../../../../core/services/budget';
import { TransactionService } from '../../../../core/services/transaction';
import { ModalService } from '../../../../core/services/modal.service';
import { PreferenceService } from '../../../../core/services/preference';
import { ConversionService } from '../../../../core/services/conversion';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import {
  type BudgetOverview,
  type BudgetHistory,
  type UnbudgetedItem,
} from '../../../../core/models/budget.model';
import { type Transaction } from '../../../../core/models/transaction.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../../../shared/pipes/convert-amount.pipe';
import { DoughnutMini } from '../doughnut-mini/doughnut-mini';
import { EmptyState } from '../../../../shared/components/empty-state/empty-state';

interface CategoryGroup {
  categoryId: string;
  categoryNom: string;
  categoryIcone: string;
  categoryCouleur: string;
  montantDepense: number;
  transactions: Transaction[];
}

@Component({
  selector: 'app-budget-unbudgeted',
  standalone: true,
  imports: [AmountPipe, ConvertAmountPipe, NgIcon, DoughnutMini, EmptyState],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorPlus,
      phosphorSquaresFour,
      phosphorCheckCircle,
    }),
  ],
  templateUrl: './budget-unbudgeted.html',
  styleUrl: './budget-unbudgeted.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetUnbudgeted implements AfterViewInit, OnDestroy {
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly budgetService = inject(BudgetService);
  private readonly transactionService = inject(TransactionService);
  private readonly modalService = inject(ModalService);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly loading = signal(true);
  readonly transactionsLoading = signal(true);
  readonly unbudgetedItems = signal<UnbudgetedItem[]>([]);
  readonly allTransactions = signal<Transaction[]>([]);
  readonly currency = signal('EUR');

  private selectedMonth = new Date().getMonth() + 1;
  private selectedYear = new Date().getFullYear();

  readonly unbudgetedTotal = computed(() =>
    this.unbudgetedItems().reduce((sum, item) => sum + item.montantDepense, 0),
  );

  readonly heroConverted = computed(() => {
    const total = this.unbudgetedTotal();
    if (total === 0) return null;
    const from = this.currency();
    const currencies = this.preferenceService.currencies();
    if (currencies.length < 2) return null;
    const to = currencies.find((c) => c !== from);
    if (!to) return null;
    const converted = this.conversionService.convert(total, from, to);
    return converted !== null ? { amount: converted, currency: to } : null;
  });

  readonly categoryGroups = computed((): CategoryGroup[] => {
    const items = this.unbudgetedItems();
    const txs = this.allTransactions();
    const catIds = new Set(items.map((i) => i.categoryId));
    const depenses = txs.filter(
      (tx) => tx.type === 'DEPENSE' && tx.category && catIds.has(tx.category.id),
    );

    return items
      .map((item) => ({
        ...item,
        transactions: depenses
          .filter((tx) => tx.category!.id === item.categoryId)
          .sort((a, b) => b.date.localeCompare(a.date)),
      }))
      .sort((a, b) => b.montantDepense - a.montantDepense);
  });

  readonly totalTransactions = computed(() =>
    this.categoryGroups().reduce((sum, g) => sum + g.transactions.length, 0),
  );

  readonly doughnutSegments = computed(() =>
    this.unbudgetedItems()
      .filter((item) => item.montantDepense > 0)
      .map((item) => ({ value: item.montantDepense, color: item.categoryCouleur })),
  );

  constructor() {
    this.exchangeRateService.loadRates();

    const monthParam = this.route.snapshot.queryParamMap.get('month');
    if (monthParam) {
      const parts = monthParam.split('-');
      if (parts.length === 2) {
        const year = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10);
        if (!isNaN(year) && !isNaN(month) && month >= 1 && month <= 12) {
          this.selectedYear = year;
          this.selectedMonth = month;
        }
      }
    }

    this.loadData();
    this.loadTransactions();
  }

  ngAfterViewInit(): void {
    const sentinel = this.stickySentinel();
    if (sentinel) {
      this.observer = new IntersectionObserver(
        ([entry]) => this.isStuck.set(!entry.isIntersecting),
        { threshold: 0 },
      );
      this.observer.observe(sentinel.nativeElement);
    }
  }

  ngOnDestroy(): void {
    this.observer?.disconnect();
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    try {
      const now = new Date();
      const isCurrentMonth =
        this.selectedMonth === now.getMonth() + 1 && this.selectedYear === now.getFullYear();
      const month = `${this.selectedYear}-${String(this.selectedMonth).padStart(2, '0')}`;
      const data: BudgetOverview | BudgetHistory = isCurrentMonth
        ? await firstValueFrom(this.budgetService.getOverview())
        : await firstValueFrom(this.budgetService.getHistory(month));
      this.unbudgetedItems.set(data.unbudgetedItems);
      this.currency.set(data.currency);
    } catch (err) {
      if (isDevMode()) console.error('Failed to load unbudgeted data', err);
    } finally {
      this.loading.set(false);
    }
  }

  async loadTransactions(): Promise<void> {
    this.transactionsLoading.set(true);
    try {
      const data = await firstValueFrom(
        this.transactionService.getByMonth(this.selectedMonth, this.selectedYear),
      );
      this.allTransactions.set(data);
    } catch (err) {
      if (isDevMode()) console.error('Failed to load transactions', err);
    } finally {
      this.transactionsLoading.set(false);
    }
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    return new Intl.DateTimeFormat('fr-FR', {
      day: 'numeric',
      month: 'long',
    }).format(date);
  }

  goBack(): void {
    this.router.navigate(['/budgets']);
  }

  onCreateBudget(): void {
    this.modalService.openModal('budget');
  }
}
