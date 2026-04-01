import {
  ChangeDetectionStrategy,
  Component,
  effect,
  inject,
  signal,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorCaretLeft } from '@ng-icons/phosphor-icons/regular';

import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { PreferenceService } from '../../../../core/services/preference';
import { AccountService } from '../../../../core/services/account';
import { Account } from '../../../../core/models/account.model';
import { CurrencyList } from './currency-list';
import { ExchangeRateManager } from './exchange-rate-manager';

@Component({
  selector: 'app-currency-settings',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [NgIcon, RouterLink, CurrencyList, ExchangeRateManager],
  viewProviders: [provideIcons({ phosphorCaretLeft })],
  template: `
    <div class="page-header">
      <button class="page-header__back" routerLink="/settings" aria-label="Retour">
        <ng-icon name="phosphorCaretLeft" size="20" />
      </button>
      <h1 class="page-header__title">Devises &amp; Taux</h1>
    </div>

    <app-currency-list
      [currencies]="currencies()"
      [accounts]="accounts()"
      (currenciesChange)="onCurrenciesChange($event)"
    />

    <app-exchange-rate-manager
      [primaryCurrency]="primaryCurrency()"
      [rates]="rateService.rates()"
      [loading]="rateService.loading()"
      (rateSaved)="rateService.loadRates()"
      (rateDeleted)="rateService.loadRates()"
    />

  `,
  styles: [
    `
      :host {
        display: flex;
        flex-direction: column;
        gap: var(--space-5);
        padding: var(--space-4);
      }

      .page-header {
        display: flex;
        align-items: center;
      }

      .page-header__back {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 36px;
        height: 36px;
        padding: 0;
        border: none;
        border-radius: var(--radius-round);
        background: transparent;
        color: var(--text-primary);
        cursor: pointer;
        flex-shrink: 0;
      }

      .page-header__back ::ng-deep ng-icon {
        min-width: 20px;
      }

      .page-header__title {
        flex: 1;
        font-size: var(--font-size-lg);
        font-weight: var(--font-weight-bold);
        color: var(--text-primary);
        margin: 0;
        text-align: right;
      }
    `,
  ],
})
export class CurrencySettings {
  readonly rateService = inject(ExchangeRateService);
  private readonly prefService = inject(PreferenceService);
  private readonly accountService = inject(AccountService);

  readonly primaryCurrency = this.prefService.primaryCurrency;

  readonly currencies = signal<string[]>(['EUR']);
  readonly accounts = signal<Account[]>([]);

  readonly allCurrencies = ['EUR', 'USD', 'XOF', 'GBP', 'CHF', 'CAD', 'MAD'];

  constructor() {
    this.rateService.loadRates();
    this.loadAccounts();
    effect(() => {
      const c = this.prefService.currencies();
      if (c.length > 0) {
        this.currencies.set(c);
      }
    });
  }

  private async loadAccounts(): Promise<void> {
    const accounts = await firstValueFrom(this.accountService.getAll(true));
    this.accounts.set(accounts);
  }

  onCurrenciesChange(currencies: string[]): void {
    this.currencies.set(currencies);
    this.prefService.update({ currencies });
  }
}
