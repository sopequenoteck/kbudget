import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { NgClass } from '@angular/common';
import { DebtService } from '../../core/services/debt';
import { ModalService } from '../../core/services/modal.service';
import { Debt, DebtType } from '../../core/models/debt.model';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { RelativeDatePipe } from '../../shared/pipes/relative-date.pipe';

type StatusFilter = 'ALL' | 'EN_COURS' | 'REMBOURSE';
type SensFilter = 'ALL' | 'JE_DOIS' | 'ON_ME_DOIT';

@Component({
  selector: 'app-debts',
  imports: [ListItem, AmountPipe, RelativeDatePipe, NgClass],
  templateUrl: './debts.html',
  styleUrl: './debts.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Debts {
  private readonly debtService = inject(DebtService);
  private readonly modalService = inject(ModalService);

  readonly loading = signal(true);
  readonly error = signal(false);
  readonly debts = signal<Debt[]>([]);
  readonly statusFilter = signal<StatusFilter>('ALL');
  readonly sensFilter = signal<SensFilter>('ALL');

  readonly filteredDebts = computed(() => {
    const sens = this.sensFilter();
    const filtered = sens === 'ALL' ? this.debts() : this.debts().filter((d) => d.sens === sens);
    return [...filtered].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  });

  readonly totalJeDois = computed(() =>
    this.filteredDebts()
      .filter((d) => d.sens === DebtType.JE_DOIS)
      .reduce((sum, d) => sum + d.montant, 0),
  );

  readonly totalOnMeDoit = computed(() =>
    this.filteredDebts()
      .filter((d) => d.sens === DebtType.ON_ME_DOIT)
      .reduce((sum, d) => sum + d.montant, 0),
  );

  readonly netBalance = computed(() => this.totalOnMeDoit() - this.totalJeDois());

  readonly hasDebts = computed(() => this.debts().length > 0);

  constructor() {
    effect(() => {
      this.debtService.refreshTrigger();
      this.statusFilter();
      this.loadData();
    });
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    const filter = this.statusFilter();
    const rembourse = filter === 'ALL' ? undefined : filter === 'REMBOURSE';

    try {
      const data = await firstValueFrom(this.debtService.getAll(rembourse));
      this.debts.set(data);
      this.loading.set(false);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load debts', err);
      }
      this.error.set(true);
      this.loading.set(false);
    }
  }

  setStatusFilter(filter: StatusFilter): void {
    this.statusFilter.set(filter);
  }

  setSensFilter(filter: SensFilter): void {
    this.sensFilter.set(filter);
  }

  getIcon(debt: Debt): string {
    return debt.sens === DebtType.JE_DOIS ? '\u{1F4B8}' : '\u{1F4B0}';
  }

  getValueClass(debt: Debt): string {
    return debt.sens === DebtType.JE_DOIS ? 'debt-owe' : 'debt-owed';
  }

  onDebtPressed(debt: Debt): void {
    this.modalService.openModal('debt', debt);
  }
}
