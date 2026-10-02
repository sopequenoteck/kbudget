import { Injectable, computed, signal } from '@angular/core';

import { type Transaction } from '../models/transaction.model';
import { type Subscription } from '../models/subscription.model';
import { type Debt } from '../models/debt.model';
import { type Category } from '../models/category.model';
import { type Account } from '../models/account.model';
import { type Budget } from '../models/budget.model';

export type ModalType =
  | 'transaction'
  | 'subscription'
  | 'debt'
  | 'category'
  | 'account'
  | 'transfer'
  | 'budget'
  | 'repay';

type EditableEntity = Transaction | Subscription | Debt | Category | Account | Budget;

const CREATE_TITLE_KEYS: Record<ModalType, string> = {
  transaction: 'transactions.dialog.createTitle',
  subscription: 'subscriptions.dialog.createTitle',
  debt: 'debts.dialog.createTitle',
  category: 'categories.dialog.createTitle',
  account: 'accounts.dialog.createTitle',
  transfer: 'transactions.dialog.transferCreateTitle',
  budget: 'budgets.dialog.createTitle',
  repay: 'debts.dialog.repayTitle',
};

const EDIT_TITLE_KEYS: Record<ModalType, string> = {
  transaction: 'transactions.dialog.editTitle',
  subscription: 'subscriptions.dialog.editTitle',
  debt: 'debts.dialog.editTitle',
  category: 'categories.dialog.editTitle',
  account: 'accounts.dialog.editTitle',
  transfer: 'transactions.dialog.transferEditTitle',
  budget: 'budgets.dialog.editTitle',
  repay: 'debts.dialog.repayTitle',
};

const CLOSE_DURATION = 200;

@Injectable({ providedIn: 'root' })
export class ModalService {
  readonly activeModal = signal<ModalType | null>(null);
  readonly editingEntity = signal<EditableEntity | null>(null);
  readonly asRecurring = signal(false);
  readonly isClosing = signal(false);
  readonly modalOpen = computed(() => this.activeModal() !== null);
  readonly modalTitleKey = computed(() => {
    const type = this.activeModal();
    if (!type) return null;
    return this.editingEntity() ? EDIT_TITLE_KEYS[type] : CREATE_TITLE_KEYS[type];
  });

  private closeTimer: ReturnType<typeof setTimeout> | null = null;

  openModal(type: ModalType, entity?: EditableEntity, options?: { asRecurring?: boolean }): void {
    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
      this.closeTimer = null;
    }
    this.editingEntity.set(entity ?? null);
    this.asRecurring.set(options?.asRecurring ?? false);
    this.isClosing.set(false);
    this.activeModal.set(type);
  }

  closeModal(): void {
    if (this.isClosing() || !this.activeModal()) return;
    this.isClosing.set(true);
    this.closeTimer = setTimeout(() => {
      this.closeTimer = null;
      this.activeModal.set(null);
      this.editingEntity.set(null);
      this.asRecurring.set(false);
      this.isClosing.set(false);
    }, CLOSE_DURATION);
  }

  resetModal(): void {
    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
      this.closeTimer = null;
    }
    this.activeModal.set(null);
    this.editingEntity.set(null);
    this.asRecurring.set(false);
    this.isClosing.set(false);
  }
}
