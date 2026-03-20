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
import { ActivatedRoute, Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorPencilSimple,
  phosphorBell,
  phosphorCalendar,
  phosphorBank,
  phosphorArrowCircleDown,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { DebtService } from '../../../../core/services/debt';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Debt, DebtType, DebtPaymentResponse } from '../../../../core/models/debt.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { RepayDialog } from '../repay-dialog/repay-dialog';
import { SnoozeDialog } from '../snooze-dialog/snooze-dialog';

@Component({
  selector: 'app-debt-detail',
  imports: [NgClass, AmountPipe, RepayDialog, SnoozeDialog, NgIcon],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorPencilSimple,
      phosphorBell,
      phosphorCalendar,
      phosphorBank,
      phosphorArrowCircleDown,
    }),
  ],
  templateUrl: './debt-detail.html',
  styleUrl: './debt-detail.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DebtDetail {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly debtService = inject(DebtService);
  private readonly modalService = inject(ModalService);
  private readonly toastService = inject(ToastService);

  readonly debt = signal<Debt | null>(null);
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly showRepayDialog = signal(false);
  readonly showSnoozeDialog = signal(false);
  readonly payments = signal<DebtPaymentResponse[]>([]);
  readonly paymentsLoading = signal(false);

  readonly progressPercent = computed(() => {
    const d = this.debt();
    if (!d || d.montant === 0) return 0;
    return Math.round(((d.montant - d.montantRestant) / d.montant) * 100);
  });

  readonly paymentsTotal = computed(() =>
    this.payments().reduce((acc, p) => acc + p.amount, 0),
  );

  readonly DebtType = DebtType;

  constructor() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadDebt(id);
    } else {
      this.router.navigate(['/debts']);
    }

    let initialLoad = true;
    effect(() => {
      this.debtService.refreshTrigger();
      if (initialLoad) {
        initialLoad = false;
        return;
      }
      const currentId = this.route.snapshot.paramMap.get('id');
      if (currentId) {
        this.loadDebt(currentId);
      }
    });
  }

  async loadDebt(id: string): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.debtService.getById(id));
      this.debt.set(data);
      this.loading.set(false);
      this.loadPayments(id);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to load debt', err);
      }
      const status = (err as { status?: number }).status;
      if (status === 404) {
        this.router.navigate(['/debts']);
      } else {
        this.error.set(true);
        this.loading.set(false);
      }
    }
  }

  private async loadPayments(id: string): Promise<void> {
    this.paymentsLoading.set(true);
    try {
      const data = await firstValueFrom(this.debtService.getPayments(id));
      this.payments.set(data);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to load payments', err);
      }
    } finally {
      this.paymentsLoading.set(false);
    }
  }

  onEdit(): void {
    const d = this.debt();
    if (d) {
      this.modalService.openModal('debt', d);
    }
  }

  onBack(): void {
    this.router.navigate(['/debts']);
  }

  onRepaid(updatedDebt: Debt): void {
    this.debt.set(updatedDebt);
    this.showRepayDialog.set(false);
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadPayments(id);
    }

    if (updatedDebt.montantRestant === 0) {
      this.toastService.success('Dette remboursée !');
    } else {
      const reste = updatedDebt.montantRestant;
      const currency = updatedDebt.currency || 'EUR';
      const formatter = new Intl.NumberFormat('fr-FR', { style: 'currency', currency });
      this.toastService.success(`Remboursement enregistré. Reste : ${formatter.format(reste)}`);
    }
  }

  onSnoozed(updatedDebt: Debt): void {
    this.debt.set(updatedDebt);
    this.showSnoozeDialog.set(false);
    this.toastService.success('Rappel reporté');
  }

  retry(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadDebt(id);
    }
  }

  formatDate(date: string): string {
    return new Intl.DateTimeFormat('fr-FR').format(new Date(date));
  }
}
