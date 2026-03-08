import { Injectable, computed, signal } from '@angular/core';

import { type Transaction } from '../models/transaction.model';
import { type Subscription } from '../models/subscription.model';
import { type Debt } from '../models/debt.model';
import { type Category } from '../models/category.model';
import { type Account } from '../models/account.model';
import { type Product } from '../models/product.model';
import { type Budget } from '../models/budget.model';

export type ModalType =
  | 'transaction'
  | 'subscription'
  | 'debt'
  | 'category'
  | 'account'
  | 'transfer'
  | 'product'
  | 'sell'
  | 'budget';

type EditableEntity = Transaction | Subscription | Debt | Category | Account | Product | Budget;

const CREATE_TITLES: Record<ModalType, string> = {
  transaction: 'Nouvelle transaction',
  subscription: 'Nouvel abonnement',
  debt: 'Nouvelle dette',
  category: 'Nouvelle catégorie',
  account: 'Nouveau compte',
  transfer: 'Nouveau virement',
  product: 'Nouveau produit',
  sell: 'Vente rapide',
  budget: 'Nouveau budget',
};

const EDIT_TITLES: Record<ModalType, string> = {
  transaction: 'Modifier la transaction',
  subscription: "Modifier l'abonnement",
  debt: 'Modifier la dette',
  category: 'Modifier la catégorie',
  account: 'Modifier le compte',
  transfer: 'Virement',
  product: 'Modifier le produit',
  sell: 'Vente rapide',
  budget: 'Modifier le budget',
};

@Injectable({ providedIn: 'root' })
export class ModalService {
  readonly activeModal = signal<ModalType | null>(null);
  readonly editingEntity = signal<EditableEntity | null>(null);
  readonly modalOpen = computed(() => this.activeModal() !== null);
  readonly modalTitle = computed(() => {
    const type = this.activeModal();
    if (!type) return '';
    return this.editingEntity() ? EDIT_TITLES[type] : CREATE_TITLES[type];
  });

  openModal(type: ModalType, entity?: EditableEntity): void {
    this.editingEntity.set(entity ?? null);
    this.activeModal.set(type);
  }

  closeModal(): void {
    this.activeModal.set(null);
    this.editingEntity.set(null);
  }
}
