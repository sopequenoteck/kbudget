import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  inject,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowsLeftRight,
  phosphorBank,
  phosphorCaretLeft,
  phosphorEnvelope,
  phosphorGearSix,
  phosphorHandCoins,
  phosphorRepeat,
  phosphorTag,
  phosphorTimer,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom, forkJoin } from 'rxjs';
import packageJson from '../../../../../../package.json';
import { HealthService, HealthCheckResult } from '../../../../core/services/health';
import { TransactionService } from '../../../../core/services/transaction';
import { AccountService } from '../../../../core/services/account';
import { SubscriptionService } from '../../../../core/services/subscription';
import { DebtService } from '../../../../core/services/debt';

@Component({
  selector: 'app-about',
  imports: [RouterLink, NgIcon],
  viewProviders: [
    provideIcons({
      phosphorArrowsLeftRight,
      phosphorBank,
      phosphorCaretLeft,
      phosphorEnvelope,
      phosphorGearSix,
      phosphorHandCoins,
      phosphorRepeat,
      phosphorTag,
      phosphorTimer,
    }),
  ],
  templateUrl: './about.html',
  styleUrl: './about.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class About implements OnInit {
  private readonly healthService = inject(HealthService);
  private readonly transactionService = inject(TransactionService);
  private readonly accountService = inject(AccountService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly debtService = inject(DebtService);

  readonly appName = 'K-Budget';
  readonly version = packageJson.version;
  readonly author = 'Kelly SOSSOE - KKSDEV';
  readonly authorEmail = 'kelly.sossoe@kksdev.fr';

  readonly serverInfo = this.healthService.getServerInfo();

  readonly healthResult = signal<HealthCheckResult>({
    status: 'checking' as const,
    responseTimeMs: null,
    error: null,
    checkedAt: null,
  });

  readonly stats = signal<{
    transactions: number | null;
    accounts: number | null;
    subscriptions: number | null;
    debts: number | null;
  }>({
    transactions: null,
    accounts: null,
    subscriptions: null,
    debts: null,
  });

  async ngOnInit(): Promise<void> {
    try {
      const result = await firstValueFrom(this.healthService.checkHealth());
      this.healthResult.set(result);
    } catch {
      this.healthResult.set({
        status: 'offline' as const,
        responseTimeMs: null,
        error: 'Erreur inconnue',
        checkedAt: null,
      });
    }

    try {
      const data = await firstValueFrom(
        forkJoin({
          transactions: this.transactionService.getAll(),
          accounts: this.accountService.getAll(),
          subscriptions: this.subscriptionService.getAll(),
          debts: this.debtService.getAll(),
        }),
      );
      this.stats.set({
        transactions: data.transactions.length,
        accounts: data.accounts.length,
        subscriptions: data.subscriptions.length,
        debts: data.debts.length,
      });
    } catch {
      this.stats.set({
        transactions: null,
        accounts: null,
        subscriptions: null,
        debts: null,
      });
    }
  }
}
