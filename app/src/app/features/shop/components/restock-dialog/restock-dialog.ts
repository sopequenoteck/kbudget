import { ChangeDetectionStrategy, Component, inject, input, output } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormField } from '../../../../shared/components/form-field/form-field';
import { RestockRequest } from '../../../../core/models/product.model';

@Component({
  selector: 'app-restock-dialog',
  imports: [ReactiveFormsModule, FormField],
  templateUrl: './restock-dialog.html',
  styleUrl: './restock-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RestockDialog {
  private readonly fb = inject(FormBuilder);

  readonly visible = input<boolean>(false);
  readonly confirmed = output<RestockRequest>();
  readonly cancelled = output<void>();

  readonly form = this.fb.nonNullable.group({
    quantity: [1, [Validators.required, Validators.min(1)]],
  });

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.confirmed.emit({ quantity: this.form.getRawValue().quantity });
    this.form.reset({ quantity: 1 });
  }

  onCancel(): void {
    this.form.reset({ quantity: 1 });
    this.cancelled.emit();
  }

  isInvalid(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.touched && control.invalid;
  }
}
