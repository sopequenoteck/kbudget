import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  signal,
} from '@angular/core';
import { DatePipe } from '@angular/common';
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

import { RecurringTransactionService } from '../../../../core/services/recurring-transaction';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { RecurringTransactionResponse } from '../../../../core/models/recurring-transaction.model';
import { Frequency } from '../../../../core/models/subscription.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';

type RecurringStatus = 'overdue' | 'today' | 'upcoming';

const STATUS_ORDER: Record<RecurringStatus, number> = {
  overdue: 0,
  today: 1,
  upcoming: 2,
};

@Component({
  selector: 'app-recurring-list',
  imports: [DatePipe, NgIcon, AmountPipe],
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

  readonly loading = this.service.loading;
  readonly error = this.service.error;
  readonly recurringTransactions = this.service.recurringTransactions;

  readonly actionInProgress = signal<string | null>(null);

  readonly sortedRecurringTransactions = computed(() => {
    return [...this.recurringTransactions()].sort((a, b) => {
      const statusA = STATUS_ORDER[this.getStatus(a.nextOccurrence)];
      const statusB = STATUS_ORDER[this.getStatus(b.nextOccurrence)];
      if (statusA !== statusB) return statusA - statusB;
      return new Date(a.nextOccurrence).getTime() - new Date(b.nextOccurrence).getTime();
    });
  });

  constructor() {
    this.service.loadActive();
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

  getFrequencyLabel(frequency: Frequency): string {
    switch (frequency) {
      case Frequency.MENSUEL:
        return 'Mensuel';
      case Frequency.ANNUEL:
        return 'Annuel';
      case Frequency.HEBDOMADAIRE:
        return 'Hebdomadaire';
    }
  }

  async onValidate(item: RecurringTransactionResponse): Promise<void> {
    this.actionInProgress.set(item.id);
    try {
      await firstValueFrom(this.service.validate(item.id));
      this.toastService.success('Transaction validée');
    } catch {
      this.toastService.error('Erreur lors de la validation');
    } finally {
      this.actionInProgress.set(null);
    }
  }

  async onSkip(item: RecurringTransactionResponse): Promise<void> {
    this.actionInProgress.set(item.id);
    try {
      await firstValueFrom(this.service.skip(item.id));
      this.toastService.success('Occurrence passée');
    } catch {
      this.toastService.error('Erreur lors du passage');
    } finally {
      this.actionInProgress.set(null);
    }
  }

  async onDeactivate(item: RecurringTransactionResponse): Promise<void> {
    if (!window.confirm(`Désactiver la récurrence "${item.libelle}" ?`)) return;
    this.actionInProgress.set(item.id);
    try {
      await firstValueFrom(this.service.deactivate(item.id));
      this.toastService.success('Récurrence désactivée');
    } catch {
      this.toastService.error('Erreur lors de la désactivation');
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
}
