import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorPencilSimple,
  phosphorBell,
  phosphorCalendar,
  phosphorArrowCircleDown,
  phosphorTrash,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { DebtService } from '../../../../core/services/debt';
import { PreferenceService } from '../../../../core/services/preference';
import { ConversionService } from '../../../../core/services/conversion';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { Debt, DebtType, DebtPaymentResponse } from '../../../../core/models/debt.model';
import { AccountSummary } from '../../../../core/models/account.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { ConvertAmountPipe } from '../../../../shared/pipes/convert-amount.pipe';
import { RepayDialog } from '../repay-dialog/repay-dialog';
import { SnoozeDialog } from '../snooze-dialog/snooze-dialog';

@Component({
  selector: 'app-debt-detail',
  imports: [AmountPipe, ConvertAmountPipe, RepayDialog, SnoozeDialog, NgIcon],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorPencilSimple,
      phosphorBell,
      phosphorCalendar,
      phosphorArrowCircleDown,
      phosphorTrash,
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
  private readonly confirmService = inject(ConfirmService);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);

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

  async onDelete(): Promise<void> {
    const d = this.debt();
    if (!d) return;

    const amount = d.montantRestant.toLocaleString('fr-FR', { style: 'currency', currency: d.currency });
    const ok = await this.confirmService.confirm({ title: `${d.personne} — ${amount} restants`, message: 'Voulez-vous vraiment supprimer cette dette ?\nLes remboursements enregistrés seront conservés.', confirmLabel: 'Supprimer', variant: 'danger', icon: 'phosphorHandCoins' });
    if (!ok) return;

    try {
      await firstValueFrom(this.debtService.delete(d.id));
      this.toastService.success('Dette supprimée');
      this.router.navigate(['/debts']);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to delete debt', err);
      }
      this.toastService.error('Erreur lors de la suppression');
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

  isOverdue(): boolean {
    const d = this.debt();
    if (!d?.dueDate || d.rembourse) return false;
    const dueDate = new Date(d.dueDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    dueDate.setHours(0, 0, 0, 0);
    return dueDate < today;
  }

  getAccountLogo(account: AccountSummary): string | null {
    return account.bankCustomLogo || account.bankLogoUrl || null;
  }

  formatDate(date: string): string {
    return new Intl.DateTimeFormat('fr-FR').format(new Date(date));
  }
}
