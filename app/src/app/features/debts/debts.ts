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
import { DebtService } from '../../core/services/debt';
import { ModalService } from '../../core/services/modal.service';
import { PreferenceService } from '../../core/services/preference';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { DevLogger } from '../../core/services/dev-logger';
import { Debt, DebtType } from '../../core/models/debt.model';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorHandCoins, phosphorHandshake, phosphorClock } from '@ng-icons/phosphor-icons/regular';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';
import { EmptyState } from '../../shared/components/empty-state/empty-state';
import { CurrencyPillSelector } from '../dashboard/components/currency-pill-selector';
import { APP_LOCALE } from '../../core/constants/locale.constants';

interface DebtGroup {
  label: string;
  status: string;
  items: Debt[];
}

@Component({
  selector: 'app-debts',
  standalone: true,
  imports: [AmountPipe, ConvertAmountPipe, NgIcon, EmptyState, CurrencyPillSelector],
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

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly skeletonItems = Array(5);

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

    const add = (key: string, label: string, status: string, debt: Debt) => {
      if (!buckets.has(key)) buckets.set(key, { label, status, items: [] });
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
        add('repaid', 'Remboursées', 'repaid', debt);
        continue;
      }

      if (!debt.dueDate) {
        add('noDue', 'Sans échéance', 'default', debt);
        continue;
      }

      const dueDate = new Date(debt.dueDate);
      dueDate.setHours(0, 0, 0, 0);
      const diffDays = Math.round(
        (dueDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24),
      );

      if (diffDays < 0) {
        add('overdue', 'En retard', 'overdue', debt);
      } else if (diffDays === 0) {
        add('today', "Aujourd'hui", 'today', debt);
      } else if (dueDate <= endOfWeek) {
        add('thisWeek', 'Cette semaine', 'default', debt);
      } else if (dueDate <= endOfMonth) {
        add('thisMonth', 'Ce mois-ci', 'default', debt);
      } else {
        add('later', 'Plus tard', 'default', debt);
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

  getSubtitle(debt: Debt): string {
    const type = debt.sens === DebtType.EMPRUNT ? 'Emprunt' : 'Prêt';
    const category = debt.category?.nom;
    return category ? `${category} · ${type}` : type;
  }

  isOverdue(debt: Debt): boolean {
    if (!debt.dueDate || debt.rembourse) return false;
    const dueDate = new Date(debt.dueDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    dueDate.setHours(0, 0, 0, 0);
    return dueDate < today;
  }

  getRelativeDate(debt: Debt): string {
    if (!debt.dueDate || debt.rembourse) return '';
    const dueDate = new Date(debt.dueDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    dueDate.setHours(0, 0, 0, 0);

    const diffDays = Math.round(
      (dueDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24),
    );

    if (diffDays < 0) return `${Math.abs(diffDays)} j. en retard`;
    if (diffDays === 0) return "aujourd'hui";
    if (diffDays === 1) return 'demain';
    if (diffDays <= 30) return `dans ${diffDays} j.`;

    return new Intl.DateTimeFormat(APP_LOCALE, { day: 'numeric', month: 'short' }).format(dueDate);
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
