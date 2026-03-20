import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { Subscription } from 'rxjs';
import { forkJoin } from 'rxjs';
import { NgClass } from '@angular/common';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorRepeat } from '@ng-icons/phosphor-icons/regular';
import { TransactionService } from '../../core/services/transaction';
import { PreferenceService } from '../../core/services/preference';
import { ModalService } from '../../core/services/modal.service';
import { Transaction, TransactionType, MonthlySummary } from '../../core/models/transaction.model';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { RelativeDatePipe } from '../../shared/pipes/relative-date.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';

@Component({
  selector: 'app-transactions',
  imports: [NgClass, RouterLink, NgIcon, ListItem, AmountPipe, RelativeDatePipe, ConvertAmountPipe],
  providers: [provideIcons({ phosphorRepeat })],
  templateUrl: './transactions.html',
  styleUrl: './transactions.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Transactions {
  private readonly transactionService = inject(TransactionService);
  private readonly modalService = inject(ModalService);
  readonly preferenceService = inject(PreferenceService);

  readonly selectedMonth = signal(new Date().getMonth() + 1);
  readonly selectedYear = signal(new Date().getFullYear());
  readonly typeFilter = signal<'ALL' | 'DEPENSE' | 'RECETTE'>('ALL');
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly transactions = signal<Transaction[]>([]);
  readonly summaries = signal<MonthlySummary[]>([]);

  readonly selectedMonthLabel = computed(() => {
    const date = new Date(this.selectedYear(), this.selectedMonth() - 1);
    return date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
  });

  readonly filteredTransactions = computed(() => {
    const all = this.transactions();
    const month = this.selectedMonth();
    const year = this.selectedYear();
    const type = this.typeFilter();

    return all
      .filter((t) => {
        const d = new Date(t.date);
        return d.getMonth() + 1 === month && d.getFullYear() === year;
      })
      .filter((t) => type === 'ALL' || t.type === type)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  });

  private loadSub: Subscription | null = null;

  constructor() {
    effect(() => {
      this.transactionService.refreshTrigger();
      this.selectedMonth();
      this.selectedYear();
      this.loadData();
    });
  }

  loadData(): void {
    this.loadSub?.unsubscribe();
    this.loading.set(true);
    this.error.set(false);

    this.loadSub = forkJoin({
      transactions: this.transactionService.getAll(),
      summary: this.transactionService.getSummary(this.selectedMonth(), this.selectedYear()),
    }).subscribe({
      next: ({ transactions, summary }) => {
        this.transactions.set(transactions);
        this.summaries.set(summary);
        this.loading.set(false);
      },
      error: (err) => {
        if (isDevMode()) {
          console.error('Failed to load transactions', err);
        }
        this.error.set(true);
        this.loading.set(false);
      },
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

  setTypeFilter(type: 'ALL' | 'DEPENSE' | 'RECETTE'): void {
    this.typeFilter.set(type);
  }

  getIcon(transaction: Transaction): string {
    return transaction.category?.icone ?? '📝';
  }

  getValueClass(transaction: Transaction): string {
    if (transaction.type === TransactionType.AJUSTEMENT) return 'amount-adjustment';
    return transaction.type === TransactionType.RECETTE ? 'amount-income' : 'amount-expense';
  }

  onTransactionPressed(transaction: Transaction): void {
    if (transaction.type === TransactionType.AJUSTEMENT) return;
    this.modalService.openModal('transaction', transaction);
  }

  onMakeRecurring(event: Event, transaction: Transaction): void {
    event.stopPropagation();
    this.modalService.openModal('transaction', transaction, { asRecurring: true });
  }
}
