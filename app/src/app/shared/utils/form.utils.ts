import { FormGroup } from '@angular/forms';

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
