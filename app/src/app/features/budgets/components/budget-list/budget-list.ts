import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  ElementRef,
  inject,
  OnDestroy,
  signal,
  viewChild,
} from '@angular/core';
import { Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorTray,
  phosphorWarning,
  phosphorChartPie,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { BudgetService } from '../../../../core/services/budget';
import { ModalService } from '../../../../core/services/modal.service';
import { CategoryService } from '../../../../core/services/category';
import { PreferenceService } from '../../../../core/services/preference';
import { ConversionService } from '../../../../core/services/conversion';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { DevLogger } from '../../../../core/services/dev-logger';
import { APP_LOCALE } from '../../../../core/constants/locale.constants';
import {
  type Budget,
  type BudgetOverview,
  type BudgetHistory,
  type BudgetItem,
  isOverviewItem,
  budgetAmount,
} from '../../../../core/models/budget.model';
import { type Category } from '../../../../core/models/category.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { DoughnutMini } from '../doughnut-mini/doughnut-mini';
import { EmptyState } from '../../../../shared/components/empty-state/empty-state';
import { CurrencyPillSelector } from '../../../dashboard/components/currency-pill-selector';

@Component({
  selector: 'app-budget-list',
  standalone: true,
  imports: [AmountPipe, NgIcon, DoughnutMini, EmptyState, CurrencyPillSelector],
  providers: [provideIcons({ phosphorTray, phosphorWarning, phosphorChartPie })],
  templateUrl: './budget-list.html',
  styleUrl: './budget-list.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetList implements AfterViewInit, OnDestroy {
  private readonly router = inject(Router);
  private readonly budgetService = inject(BudgetService);
  private readonly modalService = inject(ModalService);
  private readonly categoryService = inject(CategoryService);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly logger = inject(DevLogger);

  readonly Math = Math;
  readonly isOverviewItem = isOverviewItem;
  readonly budgetAmount = budgetAmount;
  readonly skeletonItems = Array(5);

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly monthData = signal<BudgetOverview | BudgetHistory | null>(null);
  readonly loading = signal(true);
  readonly error = signal<string | null>(null);
  readonly allBudgets = signal<Budget[]>([]);
  readonly allCategories = signal<Category[]>([]);
  readonly activeCurrency = signal('EUR');
  private persistTimeout: ReturnType<typeof setTimeout> | null = null;

  private loadVersion = 0;

  readonly isCurrentMonth = computed(() => {
    const now = new Date();
    return (
      this.selectedMonth() === now.getMonth() + 1 &&
      this.selectedYear() === now.getFullYear()
    );
  });

  readonly selectedMonthLabel = computed(() =>
    new Date(this.selectedYear(), this.selectedMonth() - 1).toLocaleDateString(APP_LOCALE, {
      month: 'long',
      year: 'numeric',
    }),
  );

  readonly activeItems = computed(() =>
    this.convertedItems().filter((item) => !isOverviewItem(item) || item.actif !== false),
  );

  readonly inactiveItems = computed(() =>
    this.convertedItems().filter((item) => isOverviewItem(item) && item.actif === false),
  );

  readonly activeCount = computed(() => this.activeItems().length);

  readonly overBudgetCount = computed(() =>
    this.activeItems().filter((item) => item.percentage > 100).length,
  );

  readonly unbudgetedTotal = computed(() => this.monthData()?.unbudgetedTotal ?? 0);

  readonly allCategoriesHaveBudget = computed(() => {
    const userCategories = this.allCategories().filter((c) => !c.isSystem);
    if (userCategories.length === 0) return false;
    const budgetedCategoryIds = new Set(this.allBudgets().map((b) => b.category.id));
    return userCategories.every((c) => budgetedCategoryIds.has(c.id));
  });

  readonly budgetedSpent = computed(() => {
    const data = this.monthData();
    if (!data) return 0;
    const raw = data.totalSpent - (data.unbudgetedTotal ?? 0);
    const from = data.currency || 'EUR';
    const to = this.activeCurrency();
    if (from === to) return raw;
    return this.conversionService.convert(raw, from, to) ?? raw;
  });

  readonly convertedUnbudgetedTotal = computed(() => {
    const data = this.monthData();
    if (!data) return 0;
    const raw = data.unbudgetedTotal ?? 0;
    const from = data.currency || 'EUR';
    const to = this.activeCurrency();
    if (from === to) return raw;
    return this.conversionService.convert(raw, from, to) ?? raw;
  });

  readonly heroConverted = computed(() => {
    const spent = this.budgetedSpent();
    if (spent === 0) return null;
    const currencies = this.preferenceService.currencies();
    if (currencies.length < 2) return null;
    const from = this.activeCurrency();
    const to = currencies.find((c) => c !== from);
    if (!to) return null;
    const converted = this.conversionService.convert(spent, from, to);
    return converted !== null ? { amount: converted, currency: to } : null;
  });

  readonly convertedItems = computed<BudgetItem[]>(() => {
    const data = this.monthData();
    if (!data) return [];
    const from = data.currency || 'EUR';
    const to = this.activeCurrency();
    if (from === to) return data.items;

    const convert = (amount: number): number =>
      this.conversionService.convert(amount, from, to) ?? amount;

    return data.items.map(item => {
      if (isOverviewItem(item)) {
        return {
          ...item,
          montantDepense: convert(item.montantDepense),
          montantBudget: convert(item.montantBudgetNormalise),
          montantBudgetNormalise: convert(item.montantBudgetNormalise),
          currency: to,
        };
      }
      return {
        ...item,
        montantDepense: convert(item.montantDepense),
        montantBudget: convert(item.montantBudget),
        currency: to,
      };
    });
  });

  readonly doughnutSegments = computed(() =>
    this.activeItems()
      .filter((item) => item.montantDepense > 0)
      .map((item) => ({ value: item.montantDepense, color: item.categoryCouleur })),
  );

  constructor() {
    this.activeCurrency.set(this.preferenceService.primaryCurrency());
    this.exchangeRateService.loadRates();

    effect(() => {
      this.selectedMonth();
      this.selectedYear();
      this.budgetService.refreshTrigger();
      this.loadData();
    });

    effect(() => {
      this.budgetService.refreshTrigger();
      this.loadAllBudgets();
    });

    this.loadAllCategories();
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
    if (this.persistTimeout) clearTimeout(this.persistTimeout);
  }

  prevMonth(): void {
    let month = this.selectedMonth();
    let year = this.selectedYear();
    if (month === 1) {
      month = 12;
      year -= 1;
    } else {
      month -= 1;
    }
    this.selectedMonth.set(month);
    this.selectedYear.set(year);
  }

  nextMonth(): void {
    let month = this.selectedMonth();
    let year = this.selectedYear();
    if (month === 12) {
      month = 1;
      year += 1;
    } else {
      month += 1;
    }
    this.selectedMonth.set(month);
    this.selectedYear.set(year);
  }

  setActiveCurrency(currency: string): void {
    this.activeCurrency.set(currency);

    const current = this.preferenceService.currencies();
    const reordered = [currency, ...current.filter(c => c !== currency)];
    this.preferenceService.setCurrencies(reordered);

    if (this.persistTimeout) clearTimeout(this.persistTimeout);
    this.persistTimeout = setTimeout(async () => {
      this.persistTimeout = null;
      this.preferenceService.update({ currencies: reordered });
      await this.exchangeRateService.loadRates();
      this.loadData();
    }, 2000);
  }

  async loadData(): Promise<void> {
    const version = ++this.loadVersion;
    this.loading.set(true);
    this.error.set(null);
    try {
      let data: BudgetOverview | BudgetHistory;
      if (this.isCurrentMonth()) {
        const [overview, budgets] = await Promise.all([
          firstValueFrom(this.budgetService.getOverview()),
          firstValueFrom(this.budgetService.getAll(true)),
        ]);
        const inactiveItems = budgets
          .filter((b) => !b.actif)
          .map((b) => ({
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
            actif: false,
          })) as unknown as BudgetItem[];
        data = {
          ...overview,
          items: [...overview.items, ...inactiveItems] as BudgetOverview['items'],
        };
      } else {
        const month = `${this.selectedYear()}-${String(this.selectedMonth()).padStart(2, '0')}`;
        data = await firstValueFrom(this.budgetService.getHistory(month));
      }
      if (version !== this.loadVersion) return;
      this.monthData.set(data);
    } catch (err) {
      if (version !== this.loadVersion) return;
      this.logger.error('Failed to load budget data', err);
      this.error.set('Impossible de charger les budgets');
    } finally {
      if (version === this.loadVersion) {
        this.loading.set(false);
      }
    }
  }

  private async loadAllBudgets(): Promise<void> {
    try {
      const data = await firstValueFrom(this.budgetService.getAll());
      this.allBudgets.set(data);
    } catch (err) {
      this.logger.error('Failed to load all budgets', err);
    }
  }

  private async loadAllCategories(): Promise<void> {
    try {
      const data = await firstValueFrom(this.categoryService.getAll());
      this.allCategories.set(data);
    } catch (err) {
      this.logger.error('Failed to load categories', err);
    }
  }

  onShowUnbudgeted(): void {
    const month = `${this.selectedYear()}-${String(this.selectedMonth()).padStart(2, '0')}`;
    this.router.navigate(['/budgets/unbudgeted'], {
      queryParams: { month },
    });
  }

  onCreate(): void {
    this.modalService.openModal('budget');
  }

  onBudgetPressed(item: BudgetItem): void {
    const month = `${this.selectedYear()}-${String(this.selectedMonth()).padStart(2, '0')}`;
    this.router.navigate(['/budgets/details'], {
      queryParams: { budgetId: item.categoryId, month },
    });
  }
}
