import { FormGroup, AbstractControl, ValidatorFn } from '@angular/forms';

/**
 * Normalise une saisie décimale : remplace la virgule par un point.
 * Gère le cas iPhone où inputmode="decimal" produit une virgule.
 */
export function normalizeDecimal(value: string | number): number {
  if (typeof value === 'number') return value;
  return parseFloat(String(value).replace(',', '.'));
}

/**
 * Validateur custom pour montant qui accepte virgule ou point.
 */
export function decimalMin(min: number): ValidatorFn {
  return (control: AbstractControl) => {
    if (!control.value && control.value !== 0) return null;
    const parsed = normalizeDecimal(control.value);
    return isNaN(parsed) || parsed < min ? { min: { min, actual: parsed } } : null;
  };
}

export function isFieldInvalid(form: FormGroup, controlName: string): boolean {
  const control = form.get(controlName);
  return !!control && control.touched && control.invalid;
}

export function validateForm(form: FormGroup): boolean {
  if (form.invalid) {
    form.markAllAsTouched();
    return false;
  }
  return true;
}
