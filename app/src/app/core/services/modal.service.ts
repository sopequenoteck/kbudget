import { Injectable, computed, signal } from '@angular/core';

import { type Transaction } from '../models/transaction.model';
import { type Subscription } from '../models/subscription.model';
import { type Debt } from '../models/debt.model';
import { type Category } from '../models/category.model';

export type ModalType = 'transaction' | 'subscription' | 'debt' | 'category';

type EditableEntity = Transaction | Subscription | Debt | Category;

const CREATE_TITLES: Record<ModalType, string> = {
  transaction: 'Nouvelle transaction',
  subscription: 'Nouvel abonnement',
  debt: 'Nouvelle dette',
  category: 'Nouvelle catégorie',
};

const EDIT_TITLES: Record<ModalType, string> = {
  transaction: 'Modifier la transaction',
  subscription: "Modifier l'abonnement",
  debt: 'Modifier la dette',
  category: 'Modifier la catégorie',
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
