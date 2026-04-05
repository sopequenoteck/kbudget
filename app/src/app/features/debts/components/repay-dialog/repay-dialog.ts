import {
  ChangeDetectionStrategy,
  Component,
  Signal,
  computed,
  effect,
  inject,
  output,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorArrowCircleDown, phosphorWallet } from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { ModalService } from '../../../../core/services/modal.service';
import { DebtService } from '../../../../core/services/debt';
import { AccountService } from '../../../../core/services/account';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Debt, DebtRepayRequest } from '../../../../core/models/debt.model';
import { Account } from '../../../../core/models/account.model';
import { SelectPickerItem } from '../../../../shared/components/select-picker/select-picker.model';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';
import { isFieldInvalid, validateForm, normalizeDecimal } from '../../../../shared/utils/form.utils';
import { createAmountWidth } from '../../../../shared/utils/amount-width.utils';
import { expandCollapse } from '../../../../shared/animations/expand-collapse';

type ExpandableSection = 'account' | null;

@Component({
  selector: 'app-repay-dialog',
  imports: [ReactiveFormsModule, NgIcon, AmountPipe, SelectPicker],
  providers: [provideIcons({ phosphorArrowCircleDown, phosphorWallet })],
  templateUrl: './repay-dialog.html',
  styleUrl: './repay-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [expandCollapse],
})
export class RepayDialog {
  private readonly fb = inject(FormBuilder);
  private readonly debtService = inject(DebtService);
  private readonly accountService = inject(AccountService);
  private readonly toastService = inject(ToastService);
  private readonly modalService = inject(ModalService);

  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly expandedSection = signal<ExpandableSection>(null);
  readonly amountWidth: Signal<string>;

  private readonly debt = computed(() => this.modalService.editingEntity() as Debt | null);
  readonly debtPersonne = computed(() => this.debt()?.personne ?? '');
  readonly debtMontantRestant = computed(() => this.debt()?.montantRestant ?? 0);
  readonly debtCurrency = computed(() => this.debt()?.currency || 'EUR');

  private readonly allAccounts = toSignal(this.accountService.getAll(), {
    initialValue: [] as Account[],
  });

  readonly activeAccounts = computed(() => this.allAccounts().filter((a) => a.actif));

  readonly accountItems = computed<SelectPickerItem[]>(() =>
    this.activeAccounts().map((a) => ({
      id: a.id,
      label: a.nom,
      icon: a.icone,
      secondaryText: `${a.solde.toFixed(2)} ${a.currency}`,
      color: a.couleur,
      iconUrl: a.bankLogoUrl ?? a.bankCustomLogo ?? null,
    })),
  );

  readonly form = this.fb.nonNullable.group({
    amount: ['', [Validators.required]],
    accountId: ['', [Validators.required]],
  });

  private readonly accountIdSignal = toSignal(
    this.form.get('accountId')!.valueChanges,
    { initialValue: this.form.get('accountId')!.value }
  );

  readonly selectedAccount = computed(() => {
    const accountId = this.accountIdSignal();
    if (!accountId) return null;
    return this.activeAccounts().find((a) => a.id === accountId) ?? null;
  });

  readonly selectedAccountName = computed(() => this.selectedAccount()?.nom ?? null);
  readonly selectedAccountColor = computed(() => this.selectedAccount()?.couleur ?? null);

  readonly activeCurrency = computed(() => this.selectedAccount()?.currency || this.debtCurrency());

  readonly currencySymbol = computed(() => {
    const currency = this.activeCurrency();
    return (0)
      .toLocaleString('fr-FR', { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 })
      .replace('0', '')
      .trim();
  });

  constructor() {
    this.amountWidth = createAmountWidth(this.form.get('amount')!, 22);

    effect(() => {
      const d = this.debt();
      if (!d) return;
      const maxAmount = d.montantRestant;
      const formatted = maxAmount % 1 === 0 ? String(maxAmount) : maxAmount.toFixed(2);
      this.form.patchValue({ amount: formatted });
      this.form.get('amount')!.setValidators([
        Validators.required,
        Validators.min(0.01),
        Validators.max(maxAmount),
      ]);
      this.form.get('amount')!.updateValueAndValidity();
    }, { allowSignalWrites: true });

    effect(() => {
      const accounts = this.activeAccounts();
      if (accounts.length === 0) return;
      const d = this.debt();
      const debtAccountId = d?.account?.id;
      const preselect = debtAccountId
        ? (accounts.find((a) => a.id === debtAccountId)?.id ?? accounts[0]?.id ?? '')
        : (accounts[0]?.id ?? '');
      this.form.patchValue({ accountId: preselect });
    }, { allowSignalWrites: true });
  }

  toggleSection(section: ExpandableSection): void {
    this.expandedSection.update((current) => (current === section ? null : section));
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const amount = normalizeDecimal(raw.amount);

    if (isNaN(amount) || amount < 0.01) {
      this.errorMessage.set('Montant invalide');
      this.submitting.set(false);
      return;
    }

    const d = this.debt();
    if (!d) return;

    const request: DebtRepayRequest = {
      accountId: raw.accountId,
      amount,
    };

    try {
      const updatedDebt = await firstValueFrom(this.debtService.repay(d.id, request));
      this.modalService.closeModal();
      this.saved.emit();
      if (updatedDebt.montantRestant === 0) {
        this.toastService.success('Dette remboursée !');
      } else {
        const reste = updatedDebt.montantRestant;
        const currency = updatedDebt.currency || 'EUR';
        const formatter = new Intl.NumberFormat('fr-FR', { style: 'currency', currency });
        this.toastService.success(`Remboursement enregistré. Reste : ${formatter.format(reste)}`);
      }
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors du remboursement');
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
    this.cancelled.emit();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
