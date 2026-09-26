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
import { firstValueFrom } from 'rxjs';
import { Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { DebtService } from '../../core/services/debt';
import { ModalService } from '../../core/services/modal.service';
import { PreferenceService } from '../../core/services/preference';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { DevLogger } from '../../core/services/dev-logger';
import { Debt, DebtType, DEBT_TYPE_LABEL_KEYS } from '../../core/models/debt.model';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorHandCoins, phosphorHandshake, phosphorClock } from '@ng-icons/phosphor-icons/regular';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';
import { CategoryNamePipe } from '../../shared/pipes/category-name.pipe';
import { EmptyState } from '../../shared/components/empty-state/empty-state';
import { CurrencyPillSelector } from '../dashboard/components/currency-pill-selector';
import { LanguageService } from '../../core/services/language';
import { getRelativeDueDateInfo, RelativeDateInfo, RelativeDueDateKeys } from '../../shared/utils/relative-due-date.utils';

interface DebtGroup {
  labelKey: string;
  status: string;
  items: Debt[];
}

const DEBT_DUE_DATE_KEYS: RelativeDueDateKeys = {
  today: 'debts.list.today',
  tomorrow: 'debts.list.tomorrow',
  daysUntil: 'debts.list.daysUntil',
  daysOverdue: 'debts.list.daysOverdue',
};

const DEBT_GROUP_LABEL_KEYS: Record<string, string> = {
  overdue: 'debts.list.overdue',
  today: 'common.value.today',
  thisWeek: 'debts.list.thisWeek',
  thisMonth: 'debts.list.thisMonth',
  later: 'debts.list.later',
  noDue: 'debts.list.noDueDate',
  repaid: 'debts.list.repaid',
};

@Component({
  selector: 'app-debts',
  standalone: true,
  imports: [AmountPipe, ConvertAmountPipe, CategoryNamePipe, NgIcon, EmptyState, CurrencyPillSelector, TranslocoPipe],
  providers: [provideIcons({ phosphorHandCoins, phosphorHandshake, phosphorClock })],
  templateUrl: './debts.html',
  styleUrl: './debts.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Debts implements AfterViewInit, OnDestroy {
  private readonly debtService = inject(DebtService);
  private readonly modalService = inject(ModalService);
  private readonly router = inject(Router);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly logger = inject(DevLogger);
  private readonly languageService = inject(LanguageService);

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly skeletonItems = Array(5);
  readonly DEBT_TYPE_LABEL_KEYS = DEBT_TYPE_LABEL_KEYS;

  readonly loading = signal(true);
  readonly error = signal(false);
  readonly debts = signal<Debt[]>([]);
  readonly activeCurrency = signal('EUR');
  private persistTimeout: ReturnType<typeof setTimeout> | null = null;

  // -- Hero computeds --

  readonly activeDebts = computed(() => this.debts().filter((d) => !d.rembourse));
  readonly activeCount = computed(() => this.activeDebts().length);

  readonly pretsCount = computed(
    () => this.activeDebts().filter((d) => d.sens === DebtType.PRET).length,
  );
  readonly empruntsCount = computed(
    () => this.activeDebts().filter((d) => d.sens === DebtType.EMPRUNT).length,
  );

  /** Net balance per currency: positive = on me doit plus, negative = je dois plus */
  readonly netBalanceByCurrency = computed(() => {
    const byCurrency = new Map<string, number>();
    for (const d of this.activeDebts()) {
      const cur = d.currency || 'EUR';
      const sign = d.sens === DebtType.PRET ? 1 : -1;
      byCurrency.set(cur, (byCurrency.get(cur) ?? 0) + d.montantRestant * sign);
    }
    return Array.from(byCurrency.entries())
      .map(([currency, total]) => ({ currency, total }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  });

  readonly activeCurrencyNet = computed(() => {
    const nets = this.netBalanceByCurrency();
    const target = this.activeCurrency();
    let total = 0;
    for (const entry of nets) {
      if (entry.currency === target) {
        total += entry.total;
      } else {
        const converted = this.conversionService.convert(entry.total, entry.currency, target);
        if (converted !== null) total += converted;
      }
    }
    return total;
  });

  readonly heroConverted = computed(() => {
    const total = this.activeCurrencyNet();
    if (total === 0) return null;
    const from = this.activeCurrency();
    const currencies = this.preferenceService.currencies();
    if (currencies.length < 2) return null;
    const to = currencies.find((c) => c !== from);
    if (!to) return null;
    const converted = this.conversionService.convert(Math.abs(total), from, to);
    return converted !== null ? { amount: converted, currency: to } : null;
  });

  readonly hasDebts = computed(() => this.debts().length > 0);

  // -- Grouped debts by due date / status --

  readonly groupedDebts = computed((): DebtGroup[] => {
    const allDebts = this.debts();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(today);
    endOfWeek.setDate(today.getDate() + 7);

    const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);

    const buckets = new Map<string, DebtGroup>();

    const add = (key: string, status: string, debt: Debt) => {
      if (!buckets.has(key)) buckets.set(key, { labelKey: DEBT_GROUP_LABEL_KEYS[key], status, items: [] });
      buckets.get(key)!.items.push(debt);
    };

    // Sort: overdue first, then by dueDate asc, no dueDate after, repaid last
    const sorted = [...allDebts].sort((a, b) => {
      if (a.rembourse !== b.rembourse) return a.rembourse ? 1 : -1;

      const dueDateA = a.dueDate ? new Date(a.dueDate).getTime() : Infinity;
      const dueDateB = b.dueDate ? new Date(b.dueDate).getTime() : Infinity;
      if (dueDateA !== dueDateB) return dueDateA - dueDateB;

      return new Date(b.date).getTime() - new Date(a.date).getTime();
    });

    for (const debt of sorted) {
      if (debt.rembourse) {
        add('repaid', 'repaid', debt);
        continue;
      }

      if (!debt.dueDate) {
        add('noDue', 'default', debt);
        continue;
      }

      const dueDate = new Date(debt.dueDate);
      dueDate.setHours(0, 0, 0, 0);
      const diffDays = Math.round(
        (dueDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24),
      );

      if (diffDays < 0) {
        add('overdue', 'overdue', debt);
      } else if (diffDays === 0) {
        add('today', 'today', debt);
      } else if (dueDate <= endOfWeek) {
        add('thisWeek', 'default', debt);
      } else if (dueDate <= endOfMonth) {
        add('thisMonth', 'default', debt);
      } else {
        add('later', 'default', debt);
      }
    }

    const order = ['overdue', 'today', 'thisWeek', 'thisMonth', 'later', 'noDue', 'repaid'];
    return order.filter((key) => buckets.has(key)).map((key) => buckets.get(key)!);
  });

  constructor() {
    this.activeCurrency.set(this.preferenceService.primaryCurrency());
    this.exchangeRateService.loadRates();

    effect(() => {
      this.debtService.refreshTrigger();
      this.loadData();
    });
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

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.debtService.getAll());
      this.debts.set(data);
      this.loading.set(false);
    } catch (err) {
      this.logger.error('Failed to load debts', err);
      this.error.set(true);
      this.loading.set(false);
    }
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

  getIcon(debt: Debt): string {
    return debt.category?.icone ?? (debt.sens === DebtType.EMPRUNT ? '💸' : '💰');
  }

  getIconBg(debt: Debt): string | null {
    return debt.category?.couleur ? debt.category.couleur + '26' : null;
  }

  isOverdue(debt: Debt): boolean {
    if (!debt.dueDate || debt.rembourse) return false;
    const dueDate = new Date(debt.dueDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    dueDate.setHours(0, 0, 0, 0);
    return dueDate < today;
  }

  getRelativeDateInfo(debt: Debt): RelativeDateInfo | null {
    if (!debt.dueDate || debt.rembourse) return null;
    return getRelativeDueDateInfo(new Date(debt.dueDate), new Date(), this.languageService.displayLocale(), DEBT_DUE_DATE_KEYS);
  }

  getAmountClass(debt: Debt): string {
    return debt.sens === DebtType.PRET ? 'amount-income' : 'amount-expense';
  }

  onAddDebt(): void {
    this.modalService.openModal('debt');
  }

  onDebtPressed(debt: Debt): void {
    this.router.navigate(['/debts', debt.id]);
  }
}
