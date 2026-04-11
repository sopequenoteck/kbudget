import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  ElementRef,
  inject,
  OnDestroy,
  signal,
  viewChild,
} from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorPencilSimple,
  phosphorTrash,
  phosphorPause,
  phosphorPlay,
  phosphorTarget,
  phosphorChartPie,
  phosphorWarning,
  phosphorMagnifyingGlass,
  phosphorReceipt,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { BudgetService } from '../../../../core/services/budget';
import { TransactionService } from '../../../../core/services/transaction';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { PreferenceService } from '../../../../core/services/preference';
import { ConversionService } from '../../../../core/services/conversion';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { DevLogger } from '../../../../core/services/dev-logger';
import { APP_LOCALE } from '../../../../core/constants/locale.constants';
import {
  type BudgetOverview,
  type BudgetHistory,
  type BudgetItem,
  isOverviewItem,
  budgetAmount,
} from '../../../../core/models/budget.model';
import { type Transaction } from '../../../../core/models/transaction.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../../../shared/pipes/convert-amount.pipe';
import { EmptyState } from '../../../../shared/components/empty-state/empty-state';

interface TransactionGroup {
  label: string;
  transactions: Transaction[];
}

@Component({
  selector: 'app-budget-detail',
  standalone: true,
  imports: [AmountPipe, ConvertAmountPipe, NgIcon, EmptyState],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorPencilSimple,
      phosphorTrash,
      phosphorPause,
      phosphorPlay,
      phosphorTarget,
      phosphorChartPie,
      phosphorWarning,
      phosphorMagnifyingGlass,
      phosphorReceipt,
    }),
  ],
  templateUrl: './budget-detail.html',
  styleUrl: './budget-detail.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetDetail implements AfterViewInit, OnDestroy {
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly budgetService = inject(BudgetService);
  private readonly transactionService = inject(TransactionService);
  private readonly modalService = inject(ModalService);
  private readonly confirmService = inject(ConfirmService);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly logger = inject(DevLogger);

  readonly Math = Math;
  readonly budgetAmount = budgetAmount;
  readonly skeletonItems = Array(4);

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly loading = signal(true);
  readonly transactionsLoading = signal(true);
  readonly budgetItem = signal<BudgetItem | null>(null);
  readonly allTransactions = signal<Transaction[]>([]);

  private categoryId = '';
  private selectedMonth = new Date().getMonth() + 1;
  private selectedYear = new Date().getFullYear();

  readonly currency = computed(() => this.budgetItem()?.currency ?? 'EUR');

  readonly isCurrentMonth = computed(() => {
    const now = new Date();
    return (
      this.selectedMonth === now.getMonth() + 1 &&
      this.selectedYear === now.getFullYear()
    );
  });

  readonly overviewBudgetId = computed(() => {
    const item = this.budgetItem();
    return item && isOverviewItem(item) ? item.budgetId : null;
  });

  readonly isActive = computed(() => {
    const item = this.budgetItem();
    return item && isOverviewItem(item) ? item.actif !== false : true;
  });

  readonly remaining = computed(() => {
    const item = this.budgetItem();
    if (!item) return 0;
    return budgetAmount(item) - item.montantDepense;
  });

  readonly heroConverted = computed(() => {
    const item = this.budgetItem();
    if (!item || item.montantDepense === 0) return null;
    const from = item.currency;
    const currencies = this.preferenceService.currencies();
    if (currencies.length < 2) return null;
    const to = currencies.find((c) => c !== from);
    if (!to) return null;
    const converted = this.conversionService.convert(item.montantDepense, from, to);
    return converted !== null ? { amount: converted, currency: to } : null;
  });

  readonly categoryTransactions = computed(() => {
    const catId = this.categoryId;
    return this.allTransactions()
      .filter((tx) => tx.type === 'DEPENSE' && tx.category?.id === catId)
      .sort((a, b) => b.date.localeCompare(a.date));
  });

  readonly groupedTransactions = computed((): TransactionGroup[] => {
    const txs = this.categoryTransactions();
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);

    const groups = new Map<string, TransactionGroup>();

    const add = (key: string, label: string, tx: Transaction) => {
      if (!groups.has(key)) groups.set(key, { label, transactions: [] });
      groups.get(key)!.transactions.push(tx);
    };

    for (const tx of txs) {
      const txDate = new Date(tx.date);
      txDate.setHours(0, 0, 0, 0);

      if (txDate.getTime() === today.getTime()) {
        add('today', "Aujourd'hui", tx);
      } else if (txDate.getTime() === yesterday.getTime()) {
        add('yesterday', 'Hier', tx);
      } else {
        const label = new Intl.DateTimeFormat(APP_LOCALE, {
          day: 'numeric',
          month: 'long',
        }).format(txDate);
        add(tx.date, label, tx);
      }
    }

    return Array.from(groups.values());
  });

  constructor() {
    this.exchangeRateService.loadRates();

    const queryParams = this.route.snapshot.queryParamMap;
    this.categoryId = queryParams.get('budgetId') ?? '';

    const monthParam = queryParams.get('month');
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
      const month = `${this.selectedYear}-${String(this.selectedMonth).padStart(2, '0')}`;
      const data: BudgetOverview | BudgetHistory = this.isCurrentMonth()
        ? await firstValueFrom(this.budgetService.getOverview())
        : await firstValueFrom(this.budgetService.getHistory(month));
      let item = data.items.find((i) => i.categoryId === this.categoryId) ?? null;

      if (!item && this.isCurrentMonth()) {
        const budgets = await firstValueFrom(this.budgetService.getAll(true));
        const b = budgets.find((bg) => bg.category.id === this.categoryId);
        if (b) {
          item = {
            budgetId: b.id,
            categoryId: b.category.id,
            categoryNom: b.category.nom,
            categoryIcone: b.category.icone,
            categoryCouleur: b.category.couleur,
            montantBudget: b.montant,
            montantBudgetNormalise: b.montant,
            currency: b.currency,
            montantDepense: b.spent,
            percentage: 0,
            frequence: b.frequence,
            actif: b.actif,
          } as BudgetItem;
        }
      }

      this.budgetItem.set(item);
    } catch (err) {
      this.logger.error('Failed to load budget data', err);
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
      this.logger.error('Failed to load transactions', err);
    } finally {
      this.transactionsLoading.set(false);
    }
  }

  formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    return new Intl.DateTimeFormat(APP_LOCALE, {
      day: 'numeric',
      month: 'long',
    }).format(date);
  }

  goBack(): void {
    this.router.navigate(['/budgets']);
  }

  async onEdit(): Promise<void> {
    const budgetId = this.overviewBudgetId();
    if (!budgetId) return;
    try {
      const budget = await firstValueFrom(this.budgetService.getById(budgetId));
      this.modalService.openModal('budget', budget);
    } catch (err) {
      this.logger.error('Failed to load budget for edit', err);
    }
  }

  async onToggleActive(): Promise<void> {
    const budgetId = this.overviewBudgetId();
    if (!budgetId) return;
    try {
      const budget = await firstValueFrom(this.budgetService.getById(budgetId));
      await firstValueFrom(
        this.budgetService.update(budgetId, {
          categoryId: budget.category.id,
          montant: budget.montant,
          currency: budget.currency,
          frequence: budget.frequence,
          seuilNotification: budget.seuilNotification,
          actif: !budget.actif,
        }),
      );
      this.router.navigate(['/budgets']);
    } catch (err) {
      this.logger.error('Failed to toggle budget', err);
    }
  }

  async onDelete(): Promise<void> {
    const budgetId = this.overviewBudgetId();
    const item = this.budgetItem();
    if (!budgetId) return;
    const title = item ? `${item.categoryNom} — ${budgetAmount(item).toLocaleString(APP_LOCALE, { style: 'currency', currency: item.currency })}` : 'Ce budget';
    const ok = await this.confirmService.confirm({ title, message: 'Voulez-vous vraiment supprimer ce budget ?', confirmLabel: 'Supprimer', variant: 'danger', icon: 'phosphorChartPie' });
    if (!ok) return;
    try {
      await firstValueFrom(this.budgetService.delete(budgetId));
      this.router.navigate(['/budgets']);
    } catch (err) {
      this.logger.error('Failed to delete budget', err);
    }
  }
}
