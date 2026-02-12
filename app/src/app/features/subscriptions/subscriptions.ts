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
import { ModalService } from '../../core/services/modal.service';
import { Subscription, Frequency } from '../../core/models/subscription.model';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';

type StatusFilter = 'ALL' | 'ACTIF' | 'INACTIF';

@Component({
  selector: 'app-subscriptions',
  imports: [ListItem, AmountPipe],
  templateUrl: './subscriptions.html',
  styleUrl: './subscriptions.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Subscriptions {
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly modalService = inject(ModalService);

  readonly statusFilter = signal<StatusFilter>('ALL');
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly subscriptions = signal<Subscription[]>([]);

  readonly sortedSubscriptions = computed(() =>
    [...this.subscriptions()].sort((a, b) => a.nom.localeCompare(b.nom, 'fr-FR')),
  );

  readonly monthlyTotal = computed(() =>
    this.subscriptions()
      .filter((s) => s.actif)
      .reduce((sum, s) => sum + (s.frequence === Frequency.ANNUEL ? s.montant / 12 : s.montant), 0),
  );

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
      currency: 'EUR',
    }).format(subscription.montant);

    return subscription.frequence === Frequency.MENSUEL ? `${formatted}/mois` : `${formatted}/an`;
  }

  onSubscriptionPressed(subscription: Subscription): void {
    this.modalService.openModal('subscription', subscription);
  }
}
