import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  signal,
} from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorRepeat,
  phosphorCheck,
  phosphorSkipForward,
  phosphorPause,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';

import { RecurringTransactionService } from '../../../../core/services/recurring-transaction';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { RecurringTransactionResponse } from '../../../../core/models/recurring-transaction.model';
import { Frequency } from '../../../../core/models/subscription.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../../../shared/pipes/convert-amount.pipe';
import { TransactionType } from '../../../../core/models/transaction.model';
import { Modal } from '../../../../shared/components/modal/modal';
import { ConversionService } from '../../../../core/services/conversion';
import { PreferenceService } from '../../../../core/services/preference';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { EmptyState } from '../../../../shared/components/empty-state/empty-state';
import { LanguageService } from '../../../../core/services/language';

type RecurringStatus = 'overdue' | 'today' | 'upcoming';

interface RecurringGroup {
  labelKey: string;
  status: RecurringStatus;
  items: RecurringTransactionResponse[];
}

interface MonthlySummary {
  totalExpenses: number;
  totalIncome: number;
  net: number;
  expenseCount: number;
}

/** Soit une clé de traduction (avec parametres ICU), soit une date deja
 * formatee pour la locale d'affichage (au-dela de 30 jours). */
interface RelativeDateInfo {
  readonly key?: string;
  readonly params?: { count: number };
  readonly formatted?: string;
}

const STATUS_ORDER: Record<RecurringStatus, number> = {
  overdue: 0,
  today: 1,
  upcoming: 2,
};

const STATUS_LABEL_KEYS: Record<RecurringStatus, string> = {
  overdue: 'recurring.value.overdue',
  today: 'common.value.today',
  upcoming: 'recurring.value.upcoming',
};

const FREQUENCY_LABEL_KEYS: Record<Frequency, string> = {
  [Frequency.MENSUEL]: 'recurring.value.monthly',
  [Frequency.ANNUEL]: 'recurring.value.yearly',
  [Frequency.HEBDOMADAIRE]: 'recurring.value.weekly',
};

@Component({
  selector: 'app-recurring-list',
  standalone: true,
  imports: [NgIcon, AmountPipe, ConvertAmountPipe, Modal, DecimalPipe, EmptyState, TranslocoPipe],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorRepeat,
      phosphorCheck,
      phosphorSkipForward,
      phosphorPause,
    }),
  ],
  templateUrl: './recurring-list.html',
  styleUrl: './recurring-list.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RecurringList {
  private readonly service = inject(RecurringTransactionService);
  private readonly toastService = inject(ToastService);
  private readonly router = inject(Router);
  private readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  readonly preferenceService = inject(PreferenceService);
  private readonly languageService = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);

  readonly skeletonItems = Array(5);

  readonly loading = this.service.loading;
  readonly error = this.service.error;
  readonly recurringTransactions = this.service.recurringTransactions;

  readonly actionInProgress = signal<string | null>(null);
  readonly selectedItem = signal<RecurringTransactionResponse | null>(null);

  readonly sortedRecurringTransactions = computed(() => {
    return [...this.recurringTransactions()].sort((a, b) => {
      const statusA = STATUS_ORDER[this.getStatus(a.nextOccurrence)];
      const statusB = STATUS_ORDER[this.getStatus(b.nextOccurrence)];
      if (statusA !== statusB) return statusA - statusB;
      return new Date(a.nextOccurrence).getTime() - new Date(b.nextOccurrence).getTime();
    });
  });

  readonly groupedByStatus = computed(() => {
    const sorted = this.sortedRecurringTransactions();
    const groups = new Map<RecurringStatus, RecurringTransactionResponse[]>();

    for (const item of sorted) {
      const status = this.getStatus(item.nextOccurrence);
      if (!groups.has(status)) groups.set(status, []);
      groups.get(status)!.push(item);
    }

    const result: RecurringGroup[] = [];
    for (const [status, items] of groups) {
      result.push({ labelKey: STATUS_LABEL_KEYS[status], status, items });
    }
    return result;
  });

  readonly monthlySummary = computed<MonthlySummary>(() => {
    const items = this.recurringTransactions();
    const primary = this.preferenceService.primaryCurrency();
    let totalExpenses = 0;
    let totalIncome = 0;
    let expenseCount = 0;

    for (const item of items) {
      const monthly = this.toMonthlyAmount(item.montant, item.frequency);
      const currency = item.account?.currency ?? primary;
      const converted = currency === primary
        ? monthly
        : (this.conversionService.convert(monthly, currency, primary) ?? monthly);

      if (item.type === TransactionType.DEPENSE) {
        totalExpenses += converted;
        expenseCount++;
      } else {
        totalIncome += converted;
      }
    }

    return { totalExpenses, totalIncome, net: totalIncome - totalExpenses, expenseCount };
  });

  constructor() {
    this.service.loadActive();
    this.exchangeRateService.loadRates();
  }

  getStatus(nextOccurrence: string): RecurringStatus {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const next = new Date(nextOccurrence);
    next.setHours(0, 0, 0, 0);
    const diff = next.getTime() - today.getTime();
    if (diff < 0) return 'overdue';
    if (diff === 0) return 'today';
    return 'upcoming';
  }

  getFrequencyLabelKey(frequency: Frequency): string {
    return FREQUENCY_LABEL_KEYS[frequency];
  }

  getRelativeDateInfo(nextOccurrence: string): RelativeDateInfo {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const next = new Date(nextOccurrence);
    next.setHours(0, 0, 0, 0);
    const diffMs = next.getTime() - today.getTime();
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays < 0) {
      const absDays = Math.abs(diffDays);
      if (absDays === 1) return { key: 'recurring.list.yesterday' };
      return { key: 'recurring.list.daysOverdue', params: { count: absDays } };
    }
    if (diffDays === 0) return { key: 'recurring.list.today' };
    if (diffDays === 1) return { key: 'recurring.list.tomorrow' };
    if (diffDays <= 30) return { key: 'recurring.list.daysUntil', params: { count: diffDays } };
    return {
      formatted: next.toLocaleDateString(this.languageService.displayLocale(), { day: '2-digit', month: 'short' }),
    };
  }

  getValueClass(item: RecurringTransactionResponse): string {
    return item.type === TransactionType.RECETTE ? 'amount-income' : 'amount-expense';
  }

  onItemPressed(item: RecurringTransactionResponse): void {
    this.selectedItem.set(item);
  }

  async onValidateAll(items: RecurringTransactionResponse[]): Promise<void> {
    this.actionInProgress.set('all');
    try {
      for (const item of items) {
        await firstValueFrom(this.service.validate(item.id));
      }
      this.toastService.success(this.transloco.translate('recurring.feedback.validatedCount', { count: items.length }));
    } catch {
      this.toastService.error(this.transloco.translate('recurring.feedback.validationError'));
    } finally {
      this.actionInProgress.set(null);
    }
  }

  async onValidate(item: RecurringTransactionResponse): Promise<void> {
    this.actionInProgress.set(item.id);
    try {
      await firstValueFrom(this.service.validate(item.id));
      this.selectedItem.set(null);
      this.toastService.success(this.transloco.translate('recurring.feedback.validatedOne'));
    } catch {
      this.toastService.error(this.transloco.translate('recurring.feedback.validationError'));
    } finally {
      this.actionInProgress.set(null);
    }
  }

  async onSkip(item: RecurringTransactionResponse): Promise<void> {
    this.actionInProgress.set(item.id);
    try {
      await firstValueFrom(this.service.skip(item.id));
      this.selectedItem.set(null);
      this.toastService.success(this.transloco.translate('recurring.feedback.skipped'));
    } catch {
      this.toastService.error(this.transloco.translate('recurring.feedback.skipFailed'));
    } finally {
      this.actionInProgress.set(null);
    }
  }

  async onDeactivate(item: RecurringTransactionResponse): Promise<void> {
    this.actionInProgress.set(item.id);
    try {
      await firstValueFrom(this.service.deactivate(item.id));
      this.selectedItem.set(null);
      this.toastService.success(this.transloco.translate('recurring.feedback.deactivated'));
    } catch {
      this.toastService.error(this.transloco.translate('recurring.feedback.deactivateError'));
    } finally {
      this.actionInProgress.set(null);
    }
  }

  reload(): void {
    this.service.loadActive();
  }

  goBack(): void {
    this.router.navigate(['/transactions']);
  }

  private toMonthlyAmount(amount: number, frequency: Frequency): number {
    switch (frequency) {
      case Frequency.HEBDOMADAIRE:
        return amount * 4.33;
      case Frequency.ANNUEL:
        return amount / 12;
      case Frequency.MENSUEL:
      default:
        return amount;
    }
  }
}
