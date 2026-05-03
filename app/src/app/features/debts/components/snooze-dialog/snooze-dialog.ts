import {
  ChangeDetectionStrategy,
  Component,
  inject,
  input,
  OnInit,
  output,
  signal,
} from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  ReactiveFormsModule,
  ValidationErrors,
  Validators,
} from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { DebtService } from '../../../../core/services/debt';
import { Debt, DebtSnoozeRequest } from '../../../../core/models/debt.model';
import { FormField } from '../../../../shared/components/form-field/form-field';
import { isFieldInvalid, validateForm } from '../../../../shared/utils/form.utils';

function futureDateValidator(control: AbstractControl): ValidationErrors | null {
  const value = control.value as string;
  if (!value) return null;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const selected = new Date(value);
  selected.setHours(0, 0, 0, 0);
  return selected < today ? { pastDate: true } : null;
}

@Component({
  selector: 'app-snooze-dialog',
  standalone: true,
  imports: [ReactiveFormsModule, FormField],
  templateUrl: './snooze-dialog.html',
  styleUrl: './snooze-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SnoozeDialog implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly debtService = inject(DebtService);

  readonly debt = input.required<Debt>();

  readonly closed = output<void>();
  readonly snoozed = output<Debt>();

  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  readonly form = this.fb.nonNullable.group({
    reminderDate: ['', [Validators.required, futureDateValidator]],
    reminderTime: ['', [Validators.required]],
  });

  ngOnInit(): void {
    const d = this.debt();
    if (d.reminderDate) {
      this.form.get('reminderDate')!.setValue(d.reminderDate);
    }
    if (d.reminderTime) {
      this.form.get('reminderTime')!.setValue(d.reminderTime);
    }
  }

  async onSubmit(): Promise<void> {
    if (!validateForm(this.form)) return;

    const raw = this.form.getRawValue();
    const request: DebtSnoozeRequest = {
      reminderDate: raw.reminderDate,
      reminderTime: raw.reminderTime,
    };

    this.submitting.set(true);
    this.errorMessage.set('');

    try {
      const updated = await firstValueFrom(this.debtService.snooze(this.debt().id, request));
      this.snoozed.emit(updated);
    } catch (err: unknown) {
      this.errorMessage.set(
        err instanceof Error ? err.message : 'Erreur lors du report du rappel',
      );
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.closed.emit();
  }

  isInvalid(controlName: string): boolean {
    return isFieldInvalid(this.form, controlName);
  }

  getDateError(): string {
    const control = this.form.get('reminderDate');
    if (!control || !control.touched || !control.invalid) return '';
    if (control.hasError('required')) return 'La date est requise';
    if (control.hasError('pastDate')) return 'La date ne peut pas être dans le passé';
    return '';
  }
}
