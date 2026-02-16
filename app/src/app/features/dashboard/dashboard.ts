import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { NgClass } from '@angular/common';
import { RouterLink } from '@angular/router';
import { Subscription as RxSub } from 'rxjs';

import { TransactionService } from '../../core/services/transaction';
import { SubscriptionService } from '../../core/services/subscription';
import { DebtService } from '../../core/services/debt';
import { AccountService } from '../../core/services/account';
import {
  type Transaction,
  TransactionType,
  type MonthlySummary,
} from '../../core/models/transaction.model';
import { type Subscription, Frequency } from '../../core/models/subscription.model';
import { type Debt, DebtType } from '../../core/models/debt.model';
import { type Account } from '../../core/models/account.model';
import { ModalService } from '../../core/services/modal.service';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { RelativeDatePipe } from '../../shared/pipes/relative-date.pipe';

@Component({
  selector: 'app-dashboard',
  imports: [NgClass, RouterLink, ListItem, AmountPipe, RelativeDatePipe],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Dashboard {
  private readonly transactionService = inject(TransactionService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly debtService = inject(DebtService);
  private readonly accountService = inject(AccountService);
  private readonly modalService = inject(ModalService);

  // -- Comptes bancaires --
  readonly accountsLoading = signal(true);
  readonly accountsError = signal(false);
  readonly accounts = signal<Account[]>([]);

  readonly totalSolde = computed(() =>
    this.accounts()
      .filter((a) => a.actif)
      .reduce((sum, a) => sum + a.solde, 0),
  );

  private accountsSub: RxSub | null = null;

  // -- Bilan mensuel (US1) --
  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly summaryLoading = signal(true);
  readonly summaryError = signal(false);
  readonly summary = signal<MonthlySummary | null>(null);

  readonly selectedMonthLabel = computed(() => {
    const date = new Date(this.selectedYear(), this.selectedMonth() - 1);
    return date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
  });

  // -- Dernières transactions (US2) --
  readonly transactionsLoading = signal(true);
  readonly transactionsError = signal(false);
  readonly transactions = signal<Transaction[]>([]);

  readonly recentTransactions = computed(() =>
    [...this.transactions()]
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 5),
  );

  // -- Abonnements actifs (US3) --
  readonly subscriptionsLoading = signal(true);
  readonly subscriptionsError = signal(false);
  readonly subscriptions = signal<Subscription[]>([]);

  readonly activeSubscriptions = computed(() =>
    [...this.subscriptions()].sort((a, b) => a.nom.localeCompare(b.nom)).slice(0, 3),
  );

  readonly monthlySubTotal = computed(() =>
    this.subscriptions().reduce((sum, s) => {
      return sum + (s.frequence === Frequency.ANNUEL ? s.montant / 12 : s.montant);
    }, 0),
  );

  // -- Dettes en cours (US4) --
  readonly debtsLoading = signal(true);
  readonly debtsError = signal(false);
  readonly debts = signal<Debt[]>([]);

  readonly activeDebts = computed(() =>
    [...this.debts()]
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 3),
  );

  readonly totalJeDois = computed(() =>
    this.debts()
      .filter((d) => d.sens === DebtType.EMPRUNT)
      .reduce((sum, d) => sum + d.montant, 0),
  );

  readonly totalOnMeDoit = computed(() =>
    this.debts()
      .filter((d) => d.sens === DebtType.PRET)
      .reduce((sum, d) => sum + d.montant, 0),
  );

  readonly miniCardsLoading = computed(
    () => this.subscriptionsLoading() || this.debtsLoading(),
  );

  private summarySub: RxSub | null = null;
  private transactionsSub: RxSub | null = null;
  private subscriptionsSub: RxSub | null = null;
  private debtsSub: RxSub | null = null;

  constructor() {
    effect(() => {
      this.accountService.refreshTrigger();
      this.transactionService.refreshTrigger();
      this.loadAccounts();
    });

    effect(() => {
      this.transactionService.refreshTrigger();
      this.selectedMonth();
      this.selectedYear();
      this.loadSummary();
    });

    effect(() => {
      this.transactionService.refreshTrigger();
      this.loadTransactions();
    });

    effect(() => {
      this.subscriptionService.refreshTrigger();
      this.loadSubscriptions();
    });

    effect(() => {
      this.debtService.refreshTrigger();
      this.loadDebts();
    });
  }

  prevMonth(): void {
    if (this.selectedMonth() === 1) {
      this.selectedMonth.set(12);
      this.selectedYear.update((y) => y - 1);
    } else {
      this.selectedMonth.update((m) => m - 1);
    }
  }

  nextMonth(): void {
    if (this.selectedMonth() === 12) {
      this.selectedMonth.set(1);
      this.selectedYear.update((y) => y + 1);
    } else {
      this.selectedMonth.update((m) => m + 1);
    }
  }

  loadAccounts(): void {
    this.accountsSub?.unsubscribe();
    this.accountsLoading.set(true);
    this.accountsError.set(false);

    this.accountsSub = this.accountService.getAll().subscribe({
      next: (data) => {
        this.accounts.set(data);
        this.accountsLoading.set(false);
      },
      error: (err) => {
        if (isDevMode()) {
          console.error('Failed to load accounts', err);
        }
        this.accountsError.set(true);
        this.accountsLoading.set(false);
      },
    });
  }

  loadSummary(): void {
    this.summarySub?.unsubscribe();
    this.summaryLoading.set(true);
    this.summaryError.set(false);

    this.summarySub = this.transactionService
      .getSummary(this.selectedMonth(), this.selectedYear())
      .subscribe({
        next: (data) => {
          this.summary.set(data);
          this.summaryLoading.set(false);
        },
        error: (err) => {
          if (isDevMode()) {
            console.error('Failed to load summary', err);
          }
          this.summaryError.set(true);
          this.summaryLoading.set(false);
        },
      });
  }

  loadTransactions(): void {
    this.transactionsSub?.unsubscribe();
    this.transactionsLoading.set(true);
    this.transactionsError.set(false);

    this.transactionsSub = this.transactionService.getAll().subscribe({
      next: (data) => {
        this.transactions.set(data);
        this.transactionsLoading.set(false);
      },
      error: (err) => {
        if (isDevMode()) {
          console.error('Failed to load transactions', err);
        }
        this.transactionsError.set(true);
        this.transactionsLoading.set(false);
      },
    });
  }

  loadSubscriptions(): void {
    this.subscriptionsSub?.unsubscribe();
    this.subscriptionsLoading.set(true);
    this.subscriptionsError.set(false);

    this.subscriptionsSub = this.subscriptionService.getAll(true).subscribe({
      next: (data) => {
        this.subscriptions.set(data);
        this.subscriptionsLoading.set(false);
      },
      error: (err) => {
        if (isDevMode()) {
          console.error('Failed to load subscriptions', err);
        }
        this.subscriptionsError.set(true);
        this.subscriptionsLoading.set(false);
      },
    });
  }

  loadDebts(): void {
    this.debtsSub?.unsubscribe();
    this.debtsLoading.set(true);
    this.debtsError.set(false);

    this.debtsSub = this.debtService.getAll(false).subscribe({
      next: (data) => {
        this.debts.set(data);
        this.debtsLoading.set(false);
      },
      error: (err) => {
        if (isDevMode()) {
          console.error('Failed to load debts', err);
        }
        this.debtsError.set(true);
        this.debtsLoading.set(false);
      },
    });
  }

  getTransactionIcon(t: Transaction): string {
    return t.category?.icone ?? '📝';
  }

  getTransactionValueClass(t: Transaction): string {
    return t.type === TransactionType.RECETTE ? 'amount-income' : 'amount-expense';
  }

  getDebtIcon(d: Debt): string {
    return d.category?.icone ?? (d.sens === DebtType.EMPRUNT ? '📤' : '📥');
  }

  getDebtValueClass(d: Debt): string {
    return d.sens === DebtType.EMPRUNT ? 'amount-expense' : 'amount-income';
  }

  onTransactionClick(t: Transaction): void {
    this.modalService.openModal('transaction', t);
  }

  onSubscriptionClick(s: Subscription): void {
    this.modalService.openModal('subscription', s);
  }

  onDebtClick(d: Debt): void {
    this.modalService.openModal('debt', d);
  }
}
