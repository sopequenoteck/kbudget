import {
  ChangeDetectionStrategy,
  Component,
  effect,
  inject,
  signal,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { Router, RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorBank,
  phosphorCaretLeft,
  phosphorPencilSimple,
  phosphorPlus,
  phosphorStar,
  phosphorTrash,
  phosphorUploadSimple,
  phosphorWarning,
} from '@ng-icons/phosphor-icons/regular';
import { AccountService } from '../../../../core/services/account';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { PreferenceService } from '../../../../core/services/preference';
import { ModalService } from '../../../../core/services/modal.service';
import { DevLogger } from '../../../../core/services/dev-logger';
import { ApiErrorService } from '../../../../core/services/api-error';
import { Account } from '../../../../core/models/account.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { AccountBankIcon } from '../../../../shared/components/account-bank-icon/account-bank-icon';
import { CurrencyList } from '../currency-settings/currency-list';
import { ExchangeRateManager } from '../currency-settings/exchange-rate-manager';
import { EmptyState } from '../../../../shared/components/empty-state/empty-state';

@Component({
  selector: 'app-accounts',
  standalone: true,
  imports: [AmountPipe, RouterLink, NgIcon, AccountBankIcon, CurrencyList, ExchangeRateManager, EmptyState],
  providers: [
    provideIcons({
      phosphorBank,
      phosphorCaretLeft,
      phosphorPencilSimple,
      phosphorPlus,
      phosphorStar,
      phosphorTrash,
      phosphorUploadSimple,
      phosphorWarning,
    }),
  ],
  templateUrl: './accounts.html',
  styleUrl: './accounts.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Accounts {
  private readonly accountService = inject(AccountService);
  private readonly modalService = inject(ModalService);
  private readonly router = inject(Router);
  private readonly logger = inject(DevLogger);
  private readonly apiError = inject(ApiErrorService);
  readonly rateService = inject(ExchangeRateService);
  private readonly prefService = inject(PreferenceService);

  readonly skeletonItems = Array(3);

  readonly accounts = signal<Account[]>([]);
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly confirmDeleteId = signal<string | null>(null);
  readonly deleteError = signal<string | null>(null);
  readonly currencies = signal<string[]>(['EUR']);
  readonly primaryCurrency = this.prefService.primaryCurrency;

  constructor() {
    effect(() => {
      this.accountService.refreshTrigger();
      this.loadAccounts();
    });
    this.rateService.loadRates();
    effect(() => {
      const c = this.prefService.currencies();
      if (c.length > 0) {
        this.currencies.set(c);
      }
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
      this.logger.error('Failed to load accounts', err);
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
      this.logger.error('Failed to set default account', err);
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
      const message = this.apiError.label(httpErr, 'Erreur lors de la suppression');
      this.deleteError.set(message);
      this.logger.error('Failed to delete account', err);
    }
  }

  triggerImport(accountId: string): void {
    this.router.navigate(['/settings/import'], { queryParams: { accountId } });
  }

  onCurrenciesChange(currencies: string[]): void {
    this.currencies.set(currencies);
    this.prefService.update({ currencies });
  }
}
