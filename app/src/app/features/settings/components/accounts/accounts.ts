import {
  ChangeDetectionStrategy,
  Component,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorStar, phosphorPencilSimple, phosphorTrash } from '@ng-icons/phosphor-icons/regular';
import { AccountService } from '../../../../core/services/account';
import { ModalService } from '../../../../core/services/modal.service';
import { Account } from '../../../../core/models/account.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';

@Component({
  selector: 'app-accounts',
  imports: [AmountPipe, RouterLink, NgIcon],
  providers: [
    provideIcons({
      phosphorStar,
      phosphorPencilSimple,
      phosphorTrash,
    }),
  ],
  templateUrl: './accounts.html',
  styleUrl: './accounts.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Accounts {
  private readonly accountService = inject(AccountService);
  private readonly modalService = inject(ModalService);

  readonly accounts = signal<Account[]>([]);
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly confirmDeleteId = signal<string | null>(null);
  readonly deleteError = signal<string | null>(null);

  constructor() {
    effect(() => {
      this.accountService.refreshTrigger();
      this.loadAccounts();
    });
  }

  async loadAccounts(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.accountService.getAll(true));
      this.accounts.set(data);
      this.loading.set(false);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load accounts', err);
      }
      this.error.set(true);
      this.loading.set(false);
    }
  }

  createAccount(): void {
    this.modalService.openModal('account');
  }

  editAccount(account: Account): void {
    this.modalService.openModal('account', account);
  }

  async setDefault(account: Account): Promise<void> {
    try {
      await firstValueFrom(this.accountService.setDefault(account.id));
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to set default account', err);
      }
    }
  }

  requestDelete(accountId: string): void {
    this.confirmDeleteId.set(accountId);
    this.deleteError.set(null);
  }

  cancelDelete(): void {
    this.confirmDeleteId.set(null);
    this.deleteError.set(null);
  }

  async confirmDelete(): Promise<void> {
    const id = this.confirmDeleteId();
    if (!id) return;

    try {
      await firstValueFrom(this.accountService.delete(id));
      this.confirmDeleteId.set(null);
      this.deleteError.set(null);
    } catch (err: unknown) {
      const httpErr = err as { error?: { message?: string } };
      const message = httpErr?.error?.message ?? 'Erreur lors de la suppression';
      this.deleteError.set(message);
      if (isDevMode()) {
        console.error('Failed to delete account', err);
      }
    }
  }
}
