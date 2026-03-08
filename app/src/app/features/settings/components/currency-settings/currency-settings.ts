import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  inject,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorCurrencyCircleDollar } from '@ng-icons/phosphor-icons/regular';

import { ExchangeRateService } from '../../../core/services/exchange-rate';
import { PreferenceService } from '../../../core/services/preference';
import { AccountService } from '../../../core/services/account';
import { Account } from '../../../core/models/account.model';
import { CurrencyList } from './currency-list';
import { ExchangeRateManager } from './exchange-rate-manager';
import { RateCalculator } from './rate-calculator';

@Component({
  selector: 'app-currency-settings',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [NgIcon, RouterLink, CurrencyList, ExchangeRateManager, RateCalculator],
  viewProviders: [provideIcons({ phosphorCurrencyCircleDollar })],
  template: `
    <a class="section-back" routerLink="/settings">
      <span class="section-back__arrow">&#9664;</span>
      <span>Paramètres</span>
    </a>

    <h2 class="page-title">
      <ng-icon name="phosphorCurrencyCircleDollar" size="24" />
      Devises &amp; Taux
    </h2>

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

    <app-rate-calculator [currencies]="allCurrencies" />
  `,
  styles: [
    `
      :host {
        display: block;
        padding: var(--space-4);
      }

      .section-back {
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        color: var(--text-secondary);
        text-decoration: none;
        font-size: var(--font-size-sm);
        margin-bottom: var(--space-6);

        &:hover {
          color: var(--text-primary);
        }

        &__arrow {
          font-size: var(--font-size-xs);
        }
      }

      .page-title {
        display: flex;
        align-items: center;
        gap: var(--space-2);
        font-size: var(--font-size-xl);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
        margin-bottom: var(--space-6);
      }
    `,
  ],
})
export class CurrencySettings implements OnInit {
  readonly rateService = inject(ExchangeRateService);
  private readonly prefService = inject(PreferenceService);
  private readonly accountService = inject(AccountService);

  readonly primaryCurrency = this.prefService.primaryCurrency;

  readonly currencies = signal<string[]>(['EUR']);
  readonly accounts = signal<Account[]>([]);

  readonly allCurrencies = ['EUR', 'USD', 'XOF', 'GBP', 'CHF', 'CAD', 'MAD'];

  ngOnInit(): void {
    this.rateService.loadRates();
    this.currencies.set(this.prefService.currencies());
    this.accountService.getAll(true).subscribe({
      next: (accounts) => this.accounts.set(accounts),
    });
  }

  onCurrenciesChange(currencies: string[]): void {
    this.currencies.set(currencies);
    this.prefService.update({ currencies });
  }
}
