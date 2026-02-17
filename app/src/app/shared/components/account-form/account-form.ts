import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { FormField } from '../form-field/form-field';
import { EmojiInput } from '../emoji-input/emoji-input';
import { Account, AccountRequest, AccountType } from '../../../core/models/account.model';

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
  [AccountType.COURANT]: '#3b82f6',
  [AccountType.EPARGNE]: '#10b981',
  [AccountType.ESPECES]: '#f59e0b',
};

const ACCOUNT_COLORS: string[] = [
  '#3b82f6', '#10b981', '#f59e0b',
  '#ef4444', '#f97316', '#84cc16',
  '#22c55e', '#06b6d4', '#6366f1',
  '#8b5cf6', '#ec4899', '#78716c',
];

@Component({
  selector: 'app-account-form',
  imports: [ReactiveFormsModule, FormField, EmojiInput],
  templateUrl: './account-form.html',
  styleUrl: './account-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AccountForm {
  private readonly fb = inject(FormBuilder);

  readonly account = input<Account | null>(null);
  readonly saved = output<AccountRequest>();
  readonly cancelled = output<void>();
  readonly deleted = output<string>();

  readonly isEditMode = computed(() => this.account() !== null);
  readonly selectedEmoji = signal('🏦');
  readonly selectedColor = signal('#3b82f6');
  readonly accountTypes = Object.values(AccountType);
  readonly AccountType = AccountType;
  readonly typeLabels = ACCOUNT_TYPE_LABELS;
  readonly defaultIcons = DEFAULT_ICONS;
  readonly accountColors = ACCOUNT_COLORS;

  readonly canDeactivate = computed(() => {
    const acc = this.account();
    return acc ? !acc.isDefault : true;
  });

  readonly selectedType = signal<AccountType>(AccountType.COURANT);

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(50)]],
    type: [AccountType.COURANT as AccountType, [Validators.required]],
    soldeInitial: ['0'],
    couleur: ['#3b82f6'],
    actif: [true],
  });

  constructor() {
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
        this.form.get('type')!.disable();
      } else {
        this.form.get('type')!.enable();
      }
    });
  }

  onEmojiSelected(emoji: string): void {
    this.selectedEmoji.set(emoji);
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

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const raw = this.form.getRawValue();
    const request: AccountRequest = {
      nom: raw.nom,
      type: raw.type,
      icone: this.selectedEmoji(),
      couleur: raw.couleur,
      actif: raw.actif,
    };

    if (!this.isEditMode()) {
      request.soldeInitial = Number(raw.soldeInitial) || 0;
    }

    this.saved.emit(request);
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  onDelete(): void {
    this.deleted.emit(this.account()!.id);
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
