import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  ElementRef,
  inject,
  isDevMode,
  OnDestroy,
  signal,
  viewChild,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { Router } from '@angular/router';
import { DebtService } from '../../core/services/debt';
import { PreferenceService } from '../../core/services/preference';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';
import { Debt, DebtType } from '../../core/models/debt.model';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorHandCoins, phosphorHandshake, phosphorClock } from '@ng-icons/phosphor-icons/regular';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';

interface DebtGroup {
  label: string;
  status: string;
  items: Debt[];
}

@Component({
  selector: 'app-debts',
  imports: [AmountPipe, ConvertAmountPipe, NgIcon],
  providers: [provideIcons({ phosphorHandCoins, phosphorHandshake, phosphorClock })],
  templateUrl: './debts.html',
  styleUrl: './debts.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Debts implements AfterViewInit, OnDestroy {
  private readonly debtService = inject(DebtService);
  private readonly router = inject(Router);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly loading = signal(true);
  readonly error = signal(false);
  readonly debts = signal<Debt[]>([]);
  readonly activeCurrency = signal('EUR');

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
    const currency = this.activeCurrency();
    return nets.find((n) => n.currency === currency)?.total ?? 0;
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
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.debtService.getAll());
      this.debts.set(data);
      this.loading.set(false);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load debts', err);
      }
      this.error.set(true);
      this.loading.set(false);
    }
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

    return new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short' }).format(dueDate);
  }

  getAmountClass(debt: Debt): string {
    return debt.sens === DebtType.PRET ? 'amount-income' : 'amount-expense';
  }

  onDebtPressed(debt: Debt): void {
    this.router.navigate(['/debts', debt.id]);
  }
}
