import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  signal,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorPencilSimple,
  phosphorCreditCard,
  phosphorPause,
  phosphorPlay,
  phosphorTrash,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { SubscriptionService } from '../../../../core/services/subscription';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { Subscription, Frequency } from '../../../../core/models/subscription.model';
import { SubscriptionPaymentResponse } from '../../../../core/models/subscription-payment.model';
import { AccountSummary } from '../../../../core/models/account.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../../../shared/pipes/convert-amount.pipe';
import { PreferenceService } from '../../../../core/services/preference';
import { DevLogger } from '../../../../core/services/dev-logger';
import { APP_LOCALE } from '../../../../core/constants/locale.constants';

@Component({
  selector: 'app-subscription-detail',
  standalone: true,
  imports: [AmountPipe, ConvertAmountPipe, NgIcon],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorPencilSimple,
      phosphorCreditCard,
      phosphorPause,
      phosphorPlay,
      phosphorTrash,
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
  private readonly confirmService = inject(ConfirmService);
  readonly preferenceService = inject(PreferenceService);
  private readonly logger = inject(DevLogger);

  readonly subscription = signal<Subscription | null>(null);
  readonly payments = signal<SubscriptionPaymentResponse[]>([]);
  readonly totalPaid = signal<{ totalPaid: number; paymentCount: number } | null>(null);
  readonly loading = signal(true);
  readonly paymentsLoading = signal(true);
  readonly payInProgress = signal(false);
  readonly error = signal(false);

  readonly skeletonItems = Array(4);

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
      this.logger.error('Failed to load subscription', err);
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
      this.logger.error('Failed to load payments', err);
    } finally {
      this.paymentsLoading.set(false);
    }
  }

  private async loadTotalPaid(id: string): Promise<void> {
    try {
      const data = await firstValueFrom(this.subscriptionService.getTotalPaid(id));
      this.totalPaid.set(data);
    } catch (err: unknown) {
      this.logger.error('Failed to load total paid', err);
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

  async onToggleActive(): Promise<void> {
    const sub = this.subscription();
    if (!sub) return;

    try {
      const updated = await firstValueFrom(
        this.subscriptionService.update(sub.id, {
          nom: sub.nom,
          montant: sub.montant,
          frequence: sub.frequence,
          dateDebut: sub.dateDebut,
          actif: !sub.actif,
          categoryId: sub.category?.id,
          accountId: sub.account?.id,
          currency: sub.currency,
        }),
      );
      this.subscription.set(updated);
      this.toastService.success(updated.actif ? 'Abonnement activé' : 'Abonnement désactivé');
    } catch {
      this.toastService.error('Échec de la mise à jour');
    }
  }

  async onDelete(): Promise<void> {
    const sub = this.subscription();
    if (!sub) return;

    const freq = sub.frequence === 'ANNUEL' ? '/an' : sub.frequence === 'HEBDOMADAIRE' ? '/sem' : '/mois';
    const amount = sub.montant.toLocaleString(APP_LOCALE, { style: 'currency', currency: sub.currency });
    const ok = await this.confirmService.confirm({ title: `${sub.nom} — ${amount}${freq}`, message: 'Voulez-vous vraiment supprimer cet abonnement ?', confirmLabel: 'Supprimer', variant: 'danger', icon: 'phosphorRepeat' });
    if (!ok) return;

    try {
      await firstValueFrom(this.subscriptionService.delete(sub.id));
      this.toastService.success('Abonnement supprimé');
      this.router.navigate(['/subscriptions']);
    } catch {
      this.toastService.error('Échec de la suppression');
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

  getAccountLogo(account: AccountSummary): string | null {
    return account.bankCustomLogo || account.bankLogoUrl || null;
  }

  formatDate(date: string): string {
    return new Intl.DateTimeFormat(APP_LOCALE).format(new Date(date));
  }
}
