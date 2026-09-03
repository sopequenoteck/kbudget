import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';

import { SnoozeDialog } from './snooze-dialog';
import { DebtService } from '../../../../core/services/debt';
import { Debt, DebtType } from '../../../../core/models/debt.model';

const mockDebt: Debt = {
  id: 'debt-1',
  personne: 'Alice',
  montant: 100,
  montantRestant: 100,
  sens: DebtType.EMPRUNT,
  date: '2026-01-01',
  dueDate: null,
  rembourse: false,
  category: null,
  currency: 'EUR',
  account: null,
  includeInBalance: false,
  reminderDate: null,
  reminderTime: null,
};

const mockDebtWithReminder: Debt = {
  ...mockDebt,
  reminderDate: '2026-04-10',
  reminderTime: '08:30',
};

const updatedDebt: Debt = {
  ...mockDebt,
  reminderDate: '2026-05-01',
  reminderTime: '10:00',
};

// Date future garantie pour les tests (au moins +1 an)
const futureDateStr = '2027-12-31';

describe('SnoozeDialog', () => {
  let debtServiceMock: {
    snooze: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    debtServiceMock = {
      snooze: vi.fn().mockReturnValue(of(updatedDebt)),
    };

    TestBed.configureTestingModule({
      imports: [SnoozeDialog],
      providers: [
        { provide: DebtService, useValue: debtServiceMock },
      ],
    });
  });

  it('should_require_date_field', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ reminderDate: '' });
    component.form.get('reminderDate')!.markAsTouched();

    expect(component.form.get('reminderDate')!.hasError('required')).toBe(true);
    expect(component.isInvalid('reminderDate')).toBe(true);
  });

  it('should_require_time_field', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ reminderTime: '' });
    component.form.get('reminderTime')!.markAsTouched();

    expect(component.form.get('reminderTime')!.hasError('required')).toBe(true);
    expect(component.isInvalid('reminderTime')).toBe(true);
  });

  it('should_reject_past_date', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ reminderDate: '2020-01-01' });
    component.form.get('reminderDate')!.markAsTouched();

    expect(component.form.get('reminderDate')!.hasError('pastDate')).toBe(true);
  });

  it('should_accept_future_date', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ reminderDate: futureDateStr });
    component.form.get('reminderDate')!.markAsTouched();

    expect(component.form.get('reminderDate')!.hasError('pastDate')).toBeFalsy();
  });

  it('should_return_date_error_message_when_required_and_touched', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ reminderDate: '' });
    component.form.get('reminderDate')!.markAsTouched();

    expect(component.getDateError()).toBe('La date est requise');
  });

  it('should_return_past_date_error_message_when_past_date_and_touched', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ reminderDate: '2020-01-01' });
    component.form.get('reminderDate')!.markAsTouched();

    expect(component.getDateError()).toBe('La date ne peut pas être dans le passé');
  });

  it('should_prefill_fields_when_debt_has_existing_reminder', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebtWithReminder);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().reminderDate).toBe('2026-04-10');
    expect(component.form.getRawValue().reminderTime).toBe('08:30');
  });

  it('should_submit_when_valid', async () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let snoozedEmitted = false;
    component.snoozed.subscribe(() => {
      snoozedEmitted = true;
    });

    component.form.patchValue({
      reminderDate: futureDateStr,
      reminderTime: '10:00',
    });

    await component.onSubmit();

    expect(debtServiceMock.snooze).toHaveBeenCalledWith('debt-1', {
      reminderDate: futureDateStr,
      reminderTime: '10:00',
    });
    expect(snoozedEmitted).toBe(true);
  });

  it('should_not_submit_when_form_is_invalid', async () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    // Laisser les champs vides (invalides)

    await component.onSubmit();

    expect(debtServiceMock.snooze).not.toHaveBeenCalled();
  });

  it('should_set_error_message_when_snooze_fails', async () => {
    debtServiceMock.snooze.mockReturnValue(throwError(() => new Error('Erreur réseau')));
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({
      reminderDate: futureDateStr,
      reminderTime: '10:00',
    });

    await component.onSubmit();

    expect(component.errorMessage()).toBe('Erreur réseau');
  });

  it('should_emit_closed_when_cancel_called', () => {
    const fixture = TestBed.createComponent(SnoozeDialog);
    fixture.componentRef.setInput('debt', mockDebt);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let closedEmitted = false;
    component.closed.subscribe(() => {
      closedEmitted = true;
    });

    component.onCancel();

    expect(closedEmitted).toBe(true);
  });
});
