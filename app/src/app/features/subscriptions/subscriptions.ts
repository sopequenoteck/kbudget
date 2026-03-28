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
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { SubscriptionService } from '../../core/services/subscription';
import { PreferenceService } from '../../core/services/preference';
import { ModalService } from '../../core/services/modal.service';
import { Subscription, Frequency } from '../../core/models/subscription.model';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';
import { ConversionService } from '../../core/services/conversion';
import { ExchangeRateService } from '../../core/services/exchange-rate';

interface SubscriptionGroup {
  label: string;
  status: string;
  items: Subscription[];
}

@Component({
  selector: 'app-subscriptions',
  imports: [AmountPipe, ConvertAmountPipe],
  templateUrl: './subscriptions.html',
  styleUrl: './subscriptions.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Subscriptions implements AfterViewInit, OnDestroy {
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly modalService = inject(ModalService);
  private readonly router = inject(Router);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly loading = signal(true);
  readonly error = signal(false);
  readonly subscriptions = signal<Subscription[]>([]);
  readonly activeCurrency = signal('EUR');

  // -- Hero computeds --

  readonly monthlyTotalsByCurrency = computed(() => {
    const byCurrency = new Map<string, number>();
    for (const s of this.subscriptions().filter((s) => s.actif)) {
      const cur = s.currency || 'EUR';
      const monthly = s.frequence === Frequency.ANNUEL ? s.montant / 12 : s.montant;
      byCurrency.set(cur, (byCurrency.get(cur) ?? 0) + monthly);
    }
    return Array.from(byCurrency.entries())
      .map(([currency, total]) => ({ currency, total }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  });

  readonly hasActiveSubscriptions = computed(() => this.subscriptions().some((s) => s.actif));
  readonly activeCount = computed(() => this.subscriptions().filter((s) => s.actif).length);

  readonly activeCurrencyTotal = computed(() => {
    const totals = this.monthlyTotalsByCurrency();
    const currency = this.activeCurrency();
    return totals.find((t) => t.currency === currency)?.total ?? 0;
  });

  readonly heroConverted = computed(() => {
    const total = this.activeCurrencyTotal();
    if (total === 0) return null;
    const from = this.activeCurrency();
    const currencies = this.preferenceService.currencies();
    if (currencies.length < 2) return null;
    const to = currencies.find((c) => c !== from);
    if (!to) return null;
    const converted = this.conversionService.convert(total, from, to);
    return converted !== null ? { amount: converted, currency: to } : null;
  });

  readonly activeCurrencyAnnual = computed(() => this.activeCurrencyTotal() * 12);

  // -- Grouped subscriptions --

  readonly groupedSubscriptions = computed((): SubscriptionGroup[] => {
    const subs = this.subscriptions();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(today);
    endOfWeek.setDate(today.getDate() + 7);

    const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
    const endOfNextMonth = new Date(today.getFullYear(), today.getMonth() + 2, 0);

    const buckets = new Map<string, SubscriptionGroup>();

    const add = (key: string, label: string, status: string, sub: Subscription) => {
      if (!buckets.has(key)) buckets.set(key, { label, status, items: [] });
      buckets.get(key)!.items.push(sub);
    };

    // Sort active subs by next renewal date, inactive at end
    const sorted = [...subs].sort((a, b) => {
      if (!a.actif && b.actif) return 1;
      if (a.actif && !b.actif) return -1;
      if (!a.actif) return a.nom.localeCompare(b.nom, 'fr-FR');
      return this.getNextRenewalRaw(a).getTime() - this.getNextRenewalRaw(b).getTime();
    });

    for (const sub of sorted) {
      if (!sub.actif) {
        add('inactive', 'Inactifs', 'inactive', sub);
        continue;
      }

      const nextDate = this.getNextRenewalRaw(sub);
      const diffDays = Math.round(
        (nextDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24),
      );

      if (diffDays === 0) {
        add('today', "Aujourd'hui", 'today', sub);
      } else if (diffDays <= 7) {
        add('thisWeek', 'Cette semaine', 'default', sub);
      } else if (nextDate <= endOfMonth) {
        add('thisMonth', 'Ce mois-ci', 'default', sub);
      } else if (nextDate <= endOfNextMonth) {
        add('nextMonth', 'Mois prochain', 'default', sub);
      } else {
        add('later', 'Plus tard', 'default', sub);
      }
    }

    const order = ['today', 'thisWeek', 'thisMonth', 'nextMonth', 'later', 'inactive'];
    return order.filter((key) => buckets.has(key)).map((key) => buckets.get(key)!);
  });

  constructor() {
    this.activeCurrency.set(this.preferenceService.primaryCurrency());

    this.exchangeRateService.loadRates();

    effect(() => {
      this.subscriptionService.refreshTrigger();
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
      const data = await firstValueFrom(this.subscriptionService.getAll());
      this.subscriptions.set(data);
      this.loading.set(false);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load subscriptions', err);
      }
      this.error.set(true);
      this.loading.set(false);
    }
  }

  setActiveCurrency(currency: string): void {
    this.activeCurrency.set(currency);
  }

  getNextRenewalRaw(subscription: Subscription): Date {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const nextDate = new Date(subscription.dateDebut);

    while (nextDate <= today) {
      if (subscription.frequence === Frequency.MENSUEL) {
        nextDate.setMonth(nextDate.getMonth() + 1);
      } else {
        nextDate.setFullYear(nextDate.getFullYear() + 1);
      }
    }

    return nextDate;
  }

  getRelativeDate(subscription: Subscription): string {
    if (!subscription.actif) return 'Inactif';

    const nextDate = this.getNextRenewalRaw(subscription);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diffDays = Math.round(
      (nextDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24),
    );

    if (diffDays === 0) return "aujourd'hui";
    if (diffDays === 1) return 'demain';
    if (diffDays <= 30) return `dans ${diffDays} j.`;

    return new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short' }).format(nextDate);
  }

  formatAmount(subscription: Subscription): string {
    const formatted = new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: subscription.currency || 'EUR',
    }).format(subscription.montant);

    return subscription.frequence === Frequency.MENSUEL ? `${formatted}/mois` : `${formatted}/an`;
  }

  onSubscriptionPressed(subscription: Subscription): void {
    this.router.navigate(['/subscriptions', subscription.id]);
  }
}
