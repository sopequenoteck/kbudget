import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { FormField } from '../form-field/form-field';
import { EmojiInput } from '../emoji-input/emoji-input';
import { SelectPicker } from '../select-picker/select-picker';
import { BankSelect } from '../bank-select/bank-select';
import { Account, AccountRequest, AccountType } from '../../../core/models/account.model';
import { AccountService } from '../../../core/services/account';
import { BankService } from '../../../core/services/bank';
import { CurrencyService } from '../../../core/services/currency';
import { ExchangeRateService } from '../../../core/services/exchange-rate';
import { PreferenceService } from '../../../core/services/preference';
import { ModalService } from '../../../core/services/modal.service';
import { PALETTE_COLORS } from '../../../core/constants/palette.constants';
import { isFieldInvalid, validateForm } from '../../utils/form.utils';
import { compressImage } from '../../utils/image.utils';

const FIXED_RATES: Record<string, number> = {
  EUR_XOF: 655.957,
  XOF_EUR: 1 / 655.957,
};

const ACCOUNT_TYPE_LABELS: Record<AccountType, string> = {
  [AccountType.COURANT]: 'Courant',
  [AccountType.EPARGNE]: 'Épargne',
  [AccountType.ESPECES]: 'Espèces',
};

const DEFAULT_ICONS: Record<AccountType, string> = {
  [AccountType.COURANT]: '🏦',
  [AccountType.EPARGNE]: '💰',
  [AccountType.ESPECES]: '💵',
};

const DEFAULT_COLORS: Record<AccountType, string> = {
  [AccountType.COURANT]: PALETTE_COLORS[8],  // bleu
  [AccountType.EPARGNE]: PALETTE_COLORS[5],  // vert
  [AccountType.ESPECES]: PALETTE_COLORS[2],  // ambre
};


@Component({
  selector: 'app-account-form',
  standalone: true,
  imports: [ReactiveFormsModule, FormsModule, FormField, EmojiInput, SelectPicker, BankSelect],
  templateUrl: './account-form.html',
  styleUrl: './account-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AccountForm {
  private readonly fb = inject(FormBuilder);
  private readonly accountService = inject(AccountService);
  private readonly bankService = inject(BankService);
  private readonly currencyService = inject(CurrencyService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly preferenceService = inject(PreferenceService);
  private readonly modalService = inject(ModalService);

  readonly bankSelectRef = viewChild(BankSelect);

  readonly account = computed(() => this.modalService.editingEntity() as Account | null);
  readonly saved = output<void>();
  readonly cancelled = output<void>();

  readonly isEditMode = computed(() => this.account() !== null);
  readonly submitting = signal(false);
  readonly errorMessage = signal('');
  readonly selectedEmoji = signal('🏦');
  readonly selectedColor = signal(DEFAULT_COLORS[AccountType.COURANT]);
  readonly selectedBankCode = signal('OTHER');
  readonly bankCustomName = signal('');
  readonly bankCustomLogo = signal<string | null>(null);

  readonly isKnownBank = computed(() => this.bankSelectRef()?.isKnownBank() ?? false);
  readonly accountTypes = Object.values(AccountType);
  readonly AccountType = AccountType;
  readonly typeLabels = ACCOUNT_TYPE_LABELS;
  readonly defaultIcons = DEFAULT_ICONS;
  readonly accountColors = PALETTE_COLORS;
  readonly currencyItems = this.currencyService.currencyItems;

  readonly canDeactivate = computed(() => {
    const acc = this.account();
    return acc ? !acc.isDefault : true;
  });

  readonly selectedType = signal<AccountType>(AccountType.COURANT);

  readonly showRateProposal = signal(false);
  readonly proposedCurrency = signal<string | null>(null);
  readonly proposedRate = signal<string>('');

  readonly primaryCurrency = this.preferenceService.primaryCurrency;

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(50)]],
    type: [AccountType.COURANT as AccountType, [Validators.required]],
    soldeInitial: ['0'],
    couleur: [DEFAULT_COLORS[AccountType.COURANT]],
    actif: [true],
    currency: [''],
    newBalance: [''],
  });

  readonly selectedCurrency = computed(() => {
    const acc = this.account();
    return acc ? acc.currency : this.form.get('currency')?.value || 'EUR';
  });

  constructor() {
    this.currencyService.loadIfEmpty();

    effect(() => {
      const acc = this.account();
      if (acc) {
        this.form.patchValue({
          nom: acc.nom,
          type: acc.type,
          soldeInitial: String(acc.soldeInitial),
          couleur: acc.couleur,
          actif: acc.actif,
        });
        this.selectedType.set(acc.type);
        this.selectedEmoji.set(acc.icone);
        this.selectedColor.set(acc.couleur);
        this.selectedBankCode.set(acc.bankCode ?? 'OTHER');
        this.bankCustomName.set(acc.bankCustomName ?? '');
        this.bankCustomLogo.set(acc.bankCustomLogo ?? null);
        this.form.patchValue({ newBalance: String(acc.solde) });
        this.form.get('type')!.disable();
      } else {
        this.form.get('type')!.enable();
      }
    });
  }

  onEmojiSelected(emoji: string): void {
    this.selectedEmoji.set(emoji);
  }

  onBankCodeChange(code: string): void {
    this.selectedBankCode.set(code);
    if (code !== 'OTHER') {
      const bank = this.bankService.getBankByCode(code);
      if (bank?.brandColor) {
        this.selectedColor.set(bank.brandColor);
        this.form.patchValue({ couleur: bank.brandColor });
      }
    }
  }

  onBankCustomNameChange(value: string): void {
    this.bankCustomName.set(value);
  }

  onBankLogoUpload(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    compressImage(file, 512, 0.8).then(dataUri => {
      this.bankCustomLogo.set(dataUri);
    });
  }

  removeBankLogo(): void {
    this.bankCustomLogo.set(null);
  }

  selectType(type: AccountType): void {
    if (this.isEditMode()) return;
    this.form.patchValue({ type, couleur: DEFAULT_COLORS[type] });
    this.selectedType.set(type);
    this.selectedEmoji.set(DEFAULT_ICONS[type]);
    this.selectedColor.set(DEFAULT_COLORS[type]);
  }

  selectColor(color: string): void {
    this.form.patchValue({ couleur: color });
    this.selectedColor.set(color);
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    this.submitting.set(true);
    this.errorMessage.set('');

    const raw = this.form.getRawValue();
    const request: AccountRequest = {
      nom: raw.nom,
      type: raw.type,
      icone: this.selectedEmoji(),
      couleur: raw.couleur,
      actif: raw.actif,
      bankCode: this.selectedBankCode(),
      bankCustomName: this.selectedBankCode() === 'OTHER' ? this.bankCustomName() || undefined : undefined,
      bankCustomLogo: this.selectedBankCode() === 'OTHER' ? this.bankCustomLogo() || undefined : undefined,
    };

    if (!this.isEditMode()) {
      request.soldeInitial = Number(raw.soldeInitial) || 0;
      if (raw.currency) {
        request.currency = raw.currency;
      }
    }

    try {
      const acc = this.account();
      if (acc) {
        await firstValueFrom(this.accountService.update(acc.id, request));

        // Adjust balance if changed
        const newBalance = Number(raw.newBalance);
        if (!isNaN(newBalance) && newBalance !== acc.solde) {
          await firstValueFrom(this.accountService.adjustBalance(acc.id, newBalance));
        }
      } else {
        await firstValueFrom(this.accountService.create(request));
        this.checkRateProposal(request.currency);
      }
      this.modalService.closeModal();
      this.saved.emit();
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la sauvegarde');
    } finally {
      this.submitting.set(false);
    }
  }

  private checkRateProposal(accountCurrency: string | undefined): void {
    if (!accountCurrency) return;

    const primary = this.preferenceService.primaryCurrency();
    if (accountCurrency === primary) return;

    const rates = this.exchangeRateService.rates();
    const hasRate = rates.some(
      (r) =>
        (r.baseCurrency === primary && r.targetCurrency === accountCurrency) ||
        (r.baseCurrency === accountCurrency && r.targetCurrency === primary),
    );

    if (!hasRate) {
      const key = `${primary}_${accountCurrency}`;
      const fixedRate = FIXED_RATES[key];
      this.proposedRate.set(fixedRate ? String(fixedRate) : '');
      this.proposedCurrency.set(accountCurrency);
      this.showRateProposal.set(true);
    }
  }

  async saveProposedRate(): Promise<void> {
    const rate = parseFloat(this.proposedRate());
    if (isNaN(rate) || rate <= 0) return;

    const primary = this.preferenceService.primaryCurrency();
    const target = this.proposedCurrency();
    if (!target) return;

    await firstValueFrom(this.exchangeRateService.upsert(primary, target, rate));
    this.showRateProposal.set(false);
  }

  async onDelete(): Promise<void> {
    const acc = this.account();
    if (!acc) return;
    try {
      await firstValueFrom(this.accountService.delete(acc.id));
      this.modalService.closeModal();
    } catch (err: unknown) {
      this.errorMessage.set(err instanceof Error ? err.message : 'Erreur lors de la suppression');
    }
  }

  onCancel(): void {
    this.modalService.closeModal();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }
}
