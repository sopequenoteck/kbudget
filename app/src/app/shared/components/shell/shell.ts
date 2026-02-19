import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  ElementRef,
  HostListener,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { filter, firstValueFrom } from 'rxjs';

import { AuthService } from '../../../core/services/auth';
import { ThemeService } from '../../../core/services/theme';
import { TransactionService } from '../../../core/services/transaction';
import { SubscriptionService } from '../../../core/services/subscription';
import { DebtService } from '../../../core/services/debt';
import { AccountService } from '../../../core/services/account';
import { ModalService, type ModalType } from '../../../core/services/modal.service';
import {
  type Transaction,
  type TransactionRequest,
  TransactionType,
} from '../../../core/models/transaction.model';
import {
  Frequency,
  type Subscription,
  type SubscriptionRequest,
} from '../../../core/models/subscription.model';
import { DebtType, type Debt, type DebtRequest } from '../../../core/models/debt.model';
import { type Account, type AccountRequest } from '../../../core/models/account.model';
import { TransactionForm } from '../../../features/transactions/components/transaction-form/transaction-form';
import { SubscriptionForm } from '../../../features/subscriptions/components/subscription-form/subscription-form';
import { DebtForm } from '../../../features/debts/components/debt-form/debt-form';
import { CategoryForm } from '../category-form/category-form';
import { AccountForm } from '../account-form/account-form';
import { TransferForm } from '../transfer-form/transfer-form';
import { Fab } from '../fab/fab';
import { Modal } from '../modal/modal';

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
    CategoryForm,
    AccountForm,
    TransferForm,
  ],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Shell {
  private readonly authService = inject(AuthService);
  private readonly themeService = inject(ThemeService);
  private readonly router = inject(Router);
  private readonly elementRef = inject(ElementRef);
  private readonly transactionService = inject(TransactionService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly debtService = inject(DebtService);
  private readonly accountService = inject(AccountService);
  readonly modalService = inject(ModalService);
  private readonly navigationEnd = toSignal(
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)),
  );

  readonly userName = this.authService.currentUser;
  readonly sidebarOpen = signal(false);
  readonly dropdownOpen = signal(false);
  readonly userInitials = computed(() => {
    const user = this.userName();
    if (!user?.name) return '?';
    return user.name
      .split(' ')
      .map((part) => part[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  });
  readonly speedDialOpen = signal(false);
  readonly transactionType = signal(TransactionType.DEPENSE);
  readonly TransactionType = TransactionType;
  readonly subscriptionFrequency = signal(Frequency.MENSUEL);
  readonly Frequency = Frequency;
  readonly debtType = signal(DebtType.EMPRUNT);
  readonly DebtType = DebtType;

  constructor() {
    effect(() => {
      this.navigationEnd();
      this.speedDialOpen.set(false);
      this.dropdownOpen.set(false);
      this.modalService.closeModal();
    });

    effect(() => {
      const modal = this.modalService.activeModal();
      if (modal === 'transaction') {
        const entity = this.modalService.editingEntity() as Transaction | null;
        this.transactionType.set(entity?.type ?? TransactionType.DEPENSE);
      }
    });

    effect(() => {
      const modal = this.modalService.activeModal();
      if (modal === 'subscription') {
        const entity = this.modalService.editingEntity() as Subscription | null;
        this.subscriptionFrequency.set(entity?.frequence ?? Frequency.MENSUEL);
      }
    });

    effect(() => {
      const modal = this.modalService.activeModal();
      if (modal === 'debt') {
        const entity = this.modalService.editingEntity() as Debt | null;
        this.debtType.set(entity?.sens ?? DebtType.EMPRUNT);
      }
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

  toggleDropdown(): void {
    this.dropdownOpen.update((open) => !open);
  }

  closeDropdown(): void {
    this.dropdownOpen.set(false);
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const menuEl = this.elementRef.nativeElement.querySelector('.shell-user-menu');
    if (menuEl && !menuEl.contains(event.target as Node)) {
      this.closeDropdown();
    }
  }

  @HostListener('document:keydown.escape')
  onEscapeKey(): void {
    this.closeDropdown();
  }

  onLogout(): void {
    this.closeDropdown();
    this.authService.logout();
  }

  onTransactionTypeChange(type: TransactionType): void {
    this.transactionType.set(type);
  }

  onFrequencyChange(freq: Frequency): void {
    this.subscriptionFrequency.set(freq);
  }

  onDebtTypeChange(type: DebtType): void {
    this.debtType.set(type);
  }

  onFabToggle(): void {
    this.speedDialOpen.update((open) => !open);
  }

  onSpeedDialAction(type: ModalType): void {
    this.speedDialOpen.set(false);
    this.modalService.openModal(type);
  }

  onModalClose(): void {
    this.modalService.closeModal();
  }

  async onTransactionSaved(request: TransactionRequest): Promise<void> {
    const editing = this.modalService.editingEntity() as Transaction | null;
    if (editing) {
      await firstValueFrom(this.transactionService.update(editing.id, request));
    } else {
      await firstValueFrom(this.transactionService.create(request));
    }
    this.modalService.closeModal();
  }

  async onSubscriptionSaved(request: SubscriptionRequest): Promise<void> {
    const editing = this.modalService.editingEntity() as Subscription | null;
    if (editing) {
      await firstValueFrom(this.subscriptionService.update(editing.id, request));
    } else {
      await firstValueFrom(this.subscriptionService.create(request));
    }
    this.modalService.closeModal();
  }

  async onDebtSaved(request: DebtRequest): Promise<void> {
    const editing = this.modalService.editingEntity() as Debt | null;
    if (editing) {
      await firstValueFrom(this.debtService.update(editing.id, request));
    } else {
      await firstValueFrom(this.debtService.create(request));
    }
    this.modalService.closeModal();
  }

  async onTransactionDeleted(id: string): Promise<void> {
    try {
      await firstValueFrom(this.transactionService.delete(id));
      this.modalService.closeModal();
    } catch (error) {
      if (isDevMode()) console.error('Failed to delete transaction:', error);
    }
  }

  async onSubscriptionDeleted(id: string): Promise<void> {
    try {
      await firstValueFrom(this.subscriptionService.delete(id));
      this.modalService.closeModal();
    } catch (error) {
      if (isDevMode()) console.error('Failed to delete subscription:', error);
    }
  }

  async onDebtDeleted(id: string): Promise<void> {
    try {
      await firstValueFrom(this.debtService.delete(id));
      this.modalService.closeModal();
    } catch (error) {
      if (isDevMode()) console.error('Failed to delete debt:', error);
    }
  }

  async onAccountSaved(request: AccountRequest): Promise<void> {
    const editing = this.modalService.editingEntity() as Account | null;
    if (editing) {
      await firstValueFrom(this.accountService.update(editing.id, request));
    } else {
      await firstValueFrom(this.accountService.create(request));
    }
    this.modalService.closeModal();
  }

  async onBalanceAdjusted(newBalance: number): Promise<void> {
    const editing = this.modalService.editingEntity() as Account | null;
    if (editing) {
      await firstValueFrom(this.accountService.adjustBalance(editing.id, newBalance));
    }
  }

  onTransferSaved(): void {
    this.transactionService.refreshTrigger.update((v) => v + 1);
    this.modalService.closeModal();
  }

  async onAccountDeleted(id: string): Promise<void> {
    try {
      await firstValueFrom(this.accountService.delete(id));
      this.modalService.closeModal();
    } catch (error) {
      if (isDevMode()) console.error('Failed to delete account:', error);
    }
  }
}
