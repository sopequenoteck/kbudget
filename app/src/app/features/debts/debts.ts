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
import { Router } from '@angular/router';
import { DebtService } from '../../core/services/debt';
import { PreferenceService } from '../../core/services/preference';
import { Debt, DebtType } from '../../core/models/debt.model';
import { ListItem } from '../../shared/components/list-item/list-item';
import { AmountPipe } from '../../shared/pipes/amount.pipe';
import { RelativeDatePipe } from '../../shared/pipes/relative-date.pipe';
import { ConvertAmountPipe } from '../../shared/pipes/convert-amount.pipe';

type StatusFilter = 'ALL' | 'EN_COURS' | 'REMBOURSE';

@Component({
  selector: 'app-debts',
  imports: [ListItem, AmountPipe, RelativeDatePipe, NgClass, ConvertAmountPipe],
  templateUrl: './debts.html',
  styleUrl: './debts.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Debts {
  private readonly debtService = inject(DebtService);
  private readonly router = inject(Router);
  readonly preferenceService = inject(PreferenceService);

  readonly loading = signal(true);
  readonly error = signal(false);
  readonly debts = signal<Debt[]>([]);
  readonly statusFilter = signal<StatusFilter>('ALL');

  readonly activeDebts = computed(() => this.debts().filter((d) => !d.rembourse));

  readonly filteredDebts = computed(() => {
    const status = this.statusFilter();
    if (status === 'ALL') return this.debts();
    if (status === 'EN_COURS') return this.debts().filter((d) => !d.rembourse);
    return this.debts().filter((d) => d.rembourse);
  });

  readonly totalJeDoisByCurrency = computed(() =>
    this.groupByCurrency(this.activeDebts().filter((d) => d.sens === DebtType.EMPRUNT)),
  );

  readonly totalOnMeDoitByCurrency = computed(() =>
    this.groupByCurrency(this.activeDebts().filter((d) => d.sens === DebtType.PRET)),
  );

  readonly netBalanceByCurrency = computed(() => {
    const currencies = new Set([
      ...this.totalJeDoisByCurrency().map((c) => c.currency),
      ...this.totalOnMeDoitByCurrency().map((c) => c.currency),
    ]);
    return Array.from(currencies)
      .map((currency) => ({
        currency,
        total:
          (this.totalOnMeDoitByCurrency().find((c) => c.currency === currency)?.total ?? 0) -
          (this.totalJeDoisByCurrency().find((c) => c.currency === currency)?.total ?? 0),
      }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  });

  readonly hasDebts = computed(() => this.debts().length > 0);

  readonly debtsOnMeDoit = computed(() =>
    this.filteredDebts()
      .filter((d) => d.sens === DebtType.PRET)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()),
  );

  readonly debtsJeDois = computed(() =>
    this.filteredDebts()
      .filter((d) => d.sens === DebtType.EMPRUNT)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()),
  );

  readonly sectionTotalOnMeDoitByCurrency = computed(() =>
    this.groupByCurrency(this.debtsOnMeDoit()),
  );

  readonly sectionTotalJeDoisByCurrency = computed(() => this.groupByCurrency(this.debtsJeDois()));

  private groupByCurrency(debts: Debt[]): { currency: string; total: number }[] {
    const byCurrency = new Map<string, number>();
    for (const d of debts) {
      const cur = d.currency || 'EUR';
      byCurrency.set(cur, (byCurrency.get(cur) ?? 0) + d.montant);
    }
    return Array.from(byCurrency.entries())
      .map(([currency, total]) => ({ currency, total }))
      .sort((a, b) => a.currency.localeCompare(b.currency));
  }

  constructor() {
    effect(() => {
      this.debtService.refreshTrigger();
      this.loadData();
    });
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.debtService.getAll());
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

  getIcon(debt: Debt): string {
    return debt.category?.icone ?? (debt.sens === DebtType.EMPRUNT ? '\u{1F4B8}' : '\u{1F4B0}');
  }

  getSubtitle(debt: Debt): string {
    const base = debt.category?.nom ?? (debt.sens === DebtType.EMPRUNT ? 'Emprunt' : 'Prêt');
    return debt.rembourse ? `${base} \u00B7 Rembours\u00E9` : base;
  }

  getValueClass(debt: Debt): string {
    return debt.sens === DebtType.EMPRUNT ? 'amount-expense' : 'amount-income';
  }

  onDebtPressed(debt: Debt): void {
    this.router.navigate(['/debts', debt.id]);
  }
}
