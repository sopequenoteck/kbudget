import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { SubscriptionService } from '../../core/services/subscription';
import { PreferenceService } from '../../core/services/preference';
import { ModalService } from '../../core/services/modal.service';
import { Subscription, Frequency } from '../../core/models/subscription.model';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';

type StatusFilter = 'ALL' | 'ACTIF' | 'INACTIF';

@Component({
  selector: 'app-subscriptions',
  imports: [ListItem, AmountPipe, ConvertAmountPipe],
  templateUrl: './subscriptions.html',
  styleUrl: './subscriptions.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Subscriptions {
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly modalService = inject(ModalService);
  readonly preferenceService = inject(PreferenceService);

  readonly statusFilter = signal<StatusFilter>('ALL');
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly subscriptions = signal<Subscription[]>([]);

  readonly sortedSubscriptions = computed(() =>
    [...this.subscriptions()].sort((a, b) => a.nom.localeCompare(b.nom, 'fr-FR')),
  );

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

  constructor() {
    effect(() => {
      this.subscriptionService.refreshTrigger();
      this.statusFilter();
      this.loadData();
    });
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    const filter = this.statusFilter();
    const actif = filter === 'ALL' ? undefined : filter === 'ACTIF';

    try {
      const data = await firstValueFrom(this.subscriptionService.getAll(actif));
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

  setStatusFilter(filter: StatusFilter): void {
    this.statusFilter.set(filter);
  }

  getNextRenewalDate(subscription: Subscription): string {
    if (!subscription.actif) {
      return 'Inactif';
    }

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

    return new Intl.DateTimeFormat('fr-FR', {
      day: 'numeric',
      month: 'long',
    }).format(nextDate);
  }

  formatAmount(subscription: Subscription): string {
    const formatted = new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: subscription.currency || 'EUR',
    }).format(subscription.montant);

    return subscription.frequence === Frequency.MENSUEL ? `${formatted}/mois` : `${formatted}/an`;
  }

  onSubscriptionPressed(subscription: Subscription): void {
    this.modalService.openModal('subscription', subscription);
  }
}
