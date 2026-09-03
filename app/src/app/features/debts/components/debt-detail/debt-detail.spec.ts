import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { ActivatedRoute, Router } from '@angular/router';

import { DebtDetail } from './debt-detail';
import { DebtService } from '../../../../core/services/debt';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Debt, DebtType } from '../../../../core/models/debt.model';

const mockDebt: Debt = {
  id: 'debt-1',
  personne: 'Alice',
  montant: 200,
  montantRestant: 150,
  sens: DebtType.EMPRUNT,
  date: '2026-01-15',
  dueDate: null,
  rembourse: false,
  category: null,
  currency: 'EUR',
  account: null,
  includeInBalance: false,
  reminderDate: null,
  reminderTime: null,
};

const repaidDebt: Debt = {
  ...mockDebt,
  montantRestant: 0,
  rembourse: true,
};

const debtWithReminder: Debt = {
  ...mockDebt,
  reminderDate: '2026-04-01',
  reminderTime: '09:00',
};

describe('DebtDetail', () => {
  let debtServiceMock: {
    getById: ReturnType<typeof vi.fn>;
    getPayments: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof vi.fn>;
  };

  let modalServiceMock: {
    openModal: ReturnType<typeof vi.fn>;
    closeModal: ReturnType<typeof vi.fn>;
  };

  let toastServiceMock: {
    success: ReturnType<typeof vi.fn>;
    error: ReturnType<typeof vi.fn>;
  };

  let routerMock: {
    navigate: ReturnType<typeof vi.fn>;
  };

  let activatedRouteMock: {
    snapshot: { paramMap: { get: ReturnType<typeof vi.fn> } };
  };

  beforeEach(() => {
    debtServiceMock = {
      getById: vi.fn().mockReturnValue(of(mockDebt)),
      getPayments: vi.fn().mockReturnValue(of([])),
      refreshTrigger: vi.fn().mockReturnValue(0),
    };

    modalServiceMock = {
      openModal: vi.fn(),
      closeModal: vi.fn(),
    };

    toastServiceMock = {
      success: vi.fn(),
      error: vi.fn(),
    };

    routerMock = {
      navigate: vi.fn(),
    };

    activatedRouteMock = {
      snapshot: {
        paramMap: {
          get: vi.fn().mockReturnValue('debt-1'),
        },
      },
    };

    TestBed.configureTestingModule({
      imports: [DebtDetail],
      providers: [
        { provide: DebtService, useValue: debtServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: activatedRouteMock },
      ],
    });
  });

  it('should_display_remaining_amount_when_debt_loaded', async () => {
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    expect(component.debt()).toEqual(mockDebt);
    expect(component.debt()?.montantRestant).toBe(150);
  });

  it('should_compute_progress_percent_when_debt_loaded', async () => {
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    // progressPercent = (200 - 150) / 200 * 100 = 25%
    expect(component.progressPercent()).toBe(25);
  });

  it('should_show_progress_bar_percent_when_debt_loaded', async () => {
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    // progressPercent = (200 - 150) / 200 * 100 = 25%
    expect(fixture.componentInstance.progressPercent()).toBe(25);
  });

  it('should_have_rembourse_true_when_debt_is_repaid', async () => {
    debtServiceMock.getById.mockReturnValue(of(repaidDebt));
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    const debt = fixture.componentInstance.debt();
    expect(debt?.rembourse).toBe(true);
    expect(debt?.montantRestant).toBe(0);
  });

  it('should_not_show_repay_dialog_initially_when_debt_is_repaid', async () => {
    debtServiceMock.getById.mockReturnValue(of(repaidDebt));
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    // Le bouton repay ne doit pas être visible quand la dette est remboursée
    const repayButton = fixture.nativeElement.querySelector('.action-btn--primary');
    expect(repayButton).toBeNull();
    // La dette est remboursée
    expect(fixture.componentInstance.debt()?.rembourse).toBe(true);
  });

  it('should_have_rembourse_false_when_debt_is_not_repaid', async () => {
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    const debt = fixture.componentInstance.debt();
    expect(debt?.rembourse).toBe(false);
  });

  it('should_have_reminder_date_when_reminder_exists', async () => {
    debtServiceMock.getById.mockReturnValue(of(debtWithReminder));
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    const debt = fixture.componentInstance.debt();
    expect(debt?.reminderDate).toBe('2026-04-01');
    expect(debt?.reminderTime).toBe('09:00');
  });

  it('should_have_null_reminder_date_when_no_reminder', async () => {
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    const debt = fixture.componentInstance.debt();
    expect(debt?.reminderDate).toBeNull();
  });

  it('should_navigate_to_debts_when_id_is_null', () => {
    activatedRouteMock.snapshot.paramMap.get.mockReturnValue(null);
    TestBed.createComponent(DebtDetail);

    expect(routerMock.navigate).toHaveBeenCalledWith(['/debts']);
  });

  it('should_navigate_to_debts_when_debt_not_found', async () => {
    debtServiceMock.getById.mockReturnValue(throwError(() => ({ status: 404 })));
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    expect(routerMock.navigate).toHaveBeenCalledWith(['/debts']);
  });

  it('should_show_error_state_when_api_fails_with_500', async () => {
    debtServiceMock.getById.mockReturnValue(throwError(() => ({ status: 500 })));
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    const component = fixture.componentInstance;
    expect(component.error()).toBe(true);
  });

  it('should_compute_100_percent_when_debt_fully_repaid', async () => {
    debtServiceMock.getById.mockReturnValue(of({ ...mockDebt, montantRestant: 0 }));
    const fixture = TestBed.createComponent(DebtDetail);
    fixture.detectChanges();
    await fixture.whenStable();

    expect(fixture.componentInstance.progressPercent()).toBe(100);
  });
});
