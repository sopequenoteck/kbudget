import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { filter, firstValueFrom } from 'rxjs';

import { AuthService } from '../../../core/services/auth';
import { TransactionService } from '../../../core/services/transaction';
import { SubscriptionService } from '../../../core/services/subscription';
import { DebtService } from '../../../core/services/debt';
import { type Transaction, type TransactionRequest } from '../../../core/models/transaction.model';
import {
  type Subscription,
  type SubscriptionRequest,
} from '../../../core/models/subscription.model';
import { type Debt, type DebtRequest } from '../../../core/models/debt.model';
import { TransactionForm } from '../../../features/transactions/components/transaction-form/transaction-form';
import { SubscriptionForm } from '../../../features/subscriptions/components/subscription-form/subscription-form';
import { DebtForm } from '../../../features/debts/components/debt-form/debt-form';
import { Fab, type ModalType } from '../fab/fab';
import { Modal } from '../modal/modal';

const MODAL_TITLES: Record<ModalType, string> = {
  transaction: 'Nouvelle transaction',
  subscription: 'Nouvel abonnement',
  debt: 'Nouvelle dette',
};

@Component({
  selector: 'app-shell',
  imports: [
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    Fab,
    Modal,
    TransactionForm,
    SubscriptionForm,
    DebtForm,
  ],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Shell {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly transactionService = inject(TransactionService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly debtService = inject(DebtService);
  private readonly navigationEnd = toSignal(
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)),
  );

  readonly userName = this.authService.currentUser;
  readonly sidebarOpen = signal(false);
  readonly speedDialOpen = signal(false);
  readonly activeModal = signal<ModalType | null>(null);
  readonly editingTransaction = signal<Transaction | null>(null);
  readonly editingSubscription = signal<Subscription | null>(null);
  readonly editingDebt = signal<Debt | null>(null);
  readonly modalOpen = computed(() => this.activeModal() !== null);
  readonly modalTitle = computed(() => {
    const type = this.activeModal();
    if (!type) return '';
    if (type === 'transaction' && this.editingTransaction()) {
      return 'Modifier la transaction';
    }
    if (type === 'subscription' && this.editingSubscription()) {
      return "Modifier l'abonnement";
    }
    if (type === 'debt' && this.editingDebt()) {
      return 'Modifier la dette';
    }
    return MODAL_TITLES[type];
  });

  constructor() {
    effect(() => {
      this.navigationEnd();
      this.speedDialOpen.set(false);
      this.activeModal.set(null);
    });
  }

  toggleSidebar(): void {
    this.sidebarOpen.update((open) => !open);
  }

  closeSidebar(): void {
    this.sidebarOpen.set(false);
  }

  onNavClick(): void {
    this.closeSidebar();
  }

  onLogout(): void {
    this.authService.logout();
  }

  onFabToggle(): void {
    this.speedDialOpen.update((open) => !open);
  }

  onSpeedDialAction(type: ModalType): void {
    this.speedDialOpen.set(false);
    this.activeModal.set(type);
  }

  onModalClose(): void {
    this.activeModal.set(null);
    this.editingTransaction.set(null);
    this.editingSubscription.set(null);
    this.editingDebt.set(null);
  }

  async onTransactionSaved(request: TransactionRequest): Promise<void> {
    const editing = this.editingTransaction();
    if (editing) {
      await firstValueFrom(this.transactionService.update(editing.id, request));
    } else {
      await firstValueFrom(this.transactionService.create(request));
    }
    this.activeModal.set(null);
    this.editingTransaction.set(null);
  }

  async onSubscriptionSaved(request: SubscriptionRequest): Promise<void> {
    const editing = this.editingSubscription();
    if (editing) {
      await firstValueFrom(this.subscriptionService.update(editing.id, request));
    } else {
      await firstValueFrom(this.subscriptionService.create(request));
    }
    this.activeModal.set(null);
    this.editingSubscription.set(null);
  }

  async onDebtSaved(request: DebtRequest): Promise<void> {
    const editing = this.editingDebt();
    if (editing) {
      await firstValueFrom(this.debtService.update(editing.id, request));
    } else {
      await firstValueFrom(this.debtService.create(request));
    }
    this.activeModal.set(null);
    this.editingDebt.set(null);
  }
}
