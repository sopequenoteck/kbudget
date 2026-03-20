import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorPencilSimple,
  phosphorCreditCard,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { SubscriptionService } from '../../../../core/services/subscription';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Subscription, Frequency } from '../../../../core/models/subscription.model';
import { SubscriptionPaymentResponse } from '../../../../core/models/subscription-payment.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';

@Component({
  selector: 'app-subscription-detail',
  imports: [AmountPipe, NgIcon],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorPencilSimple,
      phosphorCreditCard,
    }),
  ],
  templateUrl: './subscription-detail.html',
  styleUrl: './subscription-detail.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SubscriptionDetail {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly modalService = inject(ModalService);
  private readonly toastService = inject(ToastService);

  readonly subscription = signal<Subscription | null>(null);
  readonly payments = signal<SubscriptionPaymentResponse[]>([]);
  readonly totalPaid = signal<{ total: number; count: number } | null>(null);
  readonly loading = signal(true);
  readonly paymentsLoading = signal(true);
  readonly payInProgress = signal(false);
  readonly error = signal(false);

  readonly sortedPayments = computed(() =>
    [...this.payments()].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()),
  );

  constructor() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadSubscription(id);
    } else {
      this.router.navigate(['/subscriptions']);
    }
  }

  async loadSubscription(id: string): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.subscriptionService.getById(id));
      this.subscription.set(data);
      this.loading.set(false);
      this.loadPayments(id);
      this.loadTotalPaid(id);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to load subscription', err);
      }
      const status = (err as { status?: number }).status;
      if (status === 404) {
        this.router.navigate(['/subscriptions']);
      } else {
        this.error.set(true);
        this.loading.set(false);
      }
    }
  }

  private async loadPayments(id: string): Promise<void> {
    this.paymentsLoading.set(true);
    try {
      const data = await firstValueFrom(this.subscriptionService.getPayments(id));
      this.payments.set(data);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to load payments', err);
      }
    } finally {
      this.paymentsLoading.set(false);
    }
  }

  private async loadTotalPaid(id: string): Promise<void> {
    try {
      const data = await firstValueFrom(this.subscriptionService.getTotalPaid(id));
      this.totalPaid.set(data);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to load total paid', err);
      }
    }
  }

  async onPay(): Promise<void> {
    const sub = this.subscription();
    if (!sub || this.payInProgress()) return;

    this.payInProgress.set(true);
    try {
      await firstValueFrom(this.subscriptionService.pay(sub.id));
      this.toastService.success('Paiement enregistré');
      await Promise.all([this.loadPayments(sub.id), this.loadTotalPaid(sub.id)]);
    } catch {
      this.toastService.error('Échec du paiement');
    } finally {
      this.payInProgress.set(false);
    }
  }

  onEdit(): void {
    const sub = this.subscription();
    if (sub) {
      this.modalService.openModal('subscription', sub);
    }
  }

  goBack(): void {
    this.router.navigate(['/subscriptions']);
  }

  retry(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadSubscription(id);
    }
  }

  getFrequencyLabel(freq: Frequency): string {
    switch (freq) {
      case Frequency.HEBDOMADAIRE: return 'Hebdomadaire';
      case Frequency.MENSUEL: return 'Mensuel';
      case Frequency.ANNUEL: return 'Annuel';
    }
  }

  formatDate(date: string): string {
    return new Intl.DateTimeFormat('fr-FR').format(new Date(date));
  }
}
