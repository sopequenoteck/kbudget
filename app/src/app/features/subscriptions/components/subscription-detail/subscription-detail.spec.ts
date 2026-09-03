import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { ActivatedRoute, Router } from '@angular/router';

import { SubscriptionDetail } from './subscription-detail';
import { SubscriptionService } from '../../../../core/services/subscription';
import { ModalService } from '../../../../core/services/modal.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Subscription, Frequency } from '../../../../core/models/subscription.model';
import { SubscriptionPaymentResponse } from '../../../../core/models/subscription-payment.model';

const flushAsync = () => new Promise((r) => setTimeout(r, 0));

const mockSubscription: Subscription = {
  id: 'sub-1',
  nom: 'Netflix',
  montant: 13.99,
  frequence: Frequency.MENSUEL,
  dateDebut: '2026-01-01',
  actif: true,
  category: null,
  account: null,
  currency: 'EUR',
};

const mockPayments: SubscriptionPaymentResponse[] = [
  {
    id: 'pay-1',
    montant: 13.99,
    date: '2026-03-15',
    subscriptionName: 'Netflix',
    accountName: 'Compte courant',
  },
  {
    id: 'pay-2',
    montant: 13.99,
    date: '2026-02-15',
    subscriptionName: 'Netflix',
    accountName: 'Compte courant',
  },
];

const mockTotal = { totalPaid: 27.98, paymentCount: 2 };

describe('SubscriptionDetail', () => {
  let subscriptionServiceMock: {
    getById: ReturnType<typeof vi.fn>;
    getPayments: ReturnType<typeof vi.fn>;
    getTotalPaid: ReturnType<typeof vi.fn>;
    pay: ReturnType<typeof vi.fn>;
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
    subscriptionServiceMock = {
      getById: vi.fn().mockReturnValue(of(mockSubscription)),
      getPayments: vi.fn().mockReturnValue(of(mockPayments)),
      getTotalPaid: vi.fn().mockReturnValue(of(mockTotal)),
      pay: vi.fn().mockReturnValue(of(mockPayments[0])),
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
          get: vi.fn().mockReturnValue('sub-1'),
        },
      },
    };

    TestBed.configureTestingModule({
      imports: [SubscriptionDetail],
      providers: [
        { provide: SubscriptionService, useValue: subscriptionServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: activatedRouteMock },
      ],
    });
  });

  it('should_load_subscription_and_payments_on_init', async () => {
    // Arrange & Act
    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();

    // Assert
    const component = fixture.componentInstance;
    expect(subscriptionServiceMock.getById).toHaveBeenCalledWith('sub-1');
    expect(subscriptionServiceMock.getPayments).toHaveBeenCalledWith('sub-1');
    expect(subscriptionServiceMock.getTotalPaid).toHaveBeenCalledWith('sub-1');
    expect(component.subscription()).toEqual(mockSubscription);
    expect(component.payments()).toEqual(mockPayments);
    expect(component.totalPaid()).toEqual(mockTotal);
    expect(component.loading()).toBe(false);
  });

  it('should_display_subscription_info', async () => {
    // Arrange & Act
    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();
    fixture.detectChanges();

    // Assert
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Netflix');
    expect(compiled.querySelector('.badge-status')?.textContent?.trim()).toBe('Actif');
    expect(compiled.querySelector('.hero__amount')?.textContent).toContain('13,99');
  });

  it('should_display_total_paid', async () => {
    // Arrange & Act
    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();
    fixture.detectChanges();

    // Assert
    const compiled = fixture.nativeElement as HTMLElement;
    const heroTotal = compiled.querySelector('.hero__total')?.textContent ?? '';
    expect(heroTotal).toContain('2 paiement');
    expect(heroTotal).toContain('27,98');
  });

  it('should_display_payment_history', async () => {
    // Arrange & Act
    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();
    fixture.detectChanges();

    // Assert
    const component = fixture.componentInstance;
    // sortedPayments trie par date décroissante : pay-1 (mars) avant pay-2 (février)
    expect(component.sortedPayments().length).toBe(2);
    expect(component.sortedPayments()[0].id).toBe('pay-1');
    expect(component.sortedPayments()[1].id).toBe('pay-2');

    const compiled = fixture.nativeElement as HTMLElement;
    const items = compiled.querySelectorAll('.payment-item');
    expect(items.length).toBe(2);
  });

  it('should_display_empty_state_when_no_payments', async () => {
    // Arrange
    subscriptionServiceMock.getPayments.mockReturnValue(of([]));
    subscriptionServiceMock.getTotalPaid.mockReturnValue(of({ total: 0, count: 0 }));

    // Act
    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();
    fixture.detectChanges();

    // Assert
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('.payments-empty')?.textContent?.trim()).toBe('Aucun paiement enregistré');
    expect(compiled.querySelectorAll('.payment-item').length).toBe(0);
  });

  it('should_call_pay_and_refresh_when_pay_clicked', async () => {
    // Arrange
    const newPayment: SubscriptionPaymentResponse = {
      id: 'pay-3',
      montant: 13.99,
      date: '2026-03-15',
      subscriptionName: 'Netflix',
      accountName: 'Compte courant',
    };
    subscriptionServiceMock.pay.mockReturnValue(of(newPayment));

    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();

    // Act
    await fixture.componentInstance.onPay();
    await fixture.whenStable();

    // Assert
    expect(subscriptionServiceMock.pay).toHaveBeenCalledWith('sub-1');
    expect(toastServiceMock.success).toHaveBeenCalledWith('Paiement enregistré');
    // getPayments et getTotalPaid sont rappelés après le paiement (1 initial + 1 après pay)
    expect(subscriptionServiceMock.getPayments).toHaveBeenCalledTimes(2);
    expect(subscriptionServiceMock.getTotalPaid).toHaveBeenCalledTimes(2);
    expect(fixture.componentInstance.payInProgress()).toBe(false);
  });

  it('should_navigate_to_subscriptions_when_id_is_null', () => {
    // Arrange
    activatedRouteMock.snapshot.paramMap.get.mockReturnValue(null);

    // Act
    TestBed.createComponent(SubscriptionDetail);

    // Assert
    expect(routerMock.navigate).toHaveBeenCalledWith(['/subscriptions']);
  });

  it('should_navigate_to_subscriptions_when_subscription_not_found', async () => {
    // Arrange
    subscriptionServiceMock.getById.mockReturnValue(throwError(() => ({ status: 404 })));

    // Act
    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();

    // Assert
    expect(routerMock.navigate).toHaveBeenCalledWith(['/subscriptions']);
  });

  it('should_show_error_state_when_api_fails_with_500', async () => {
    // Arrange
    subscriptionServiceMock.getById.mockReturnValue(throwError(() => ({ status: 500 })));

    // Act
    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();

    // Assert
    expect(fixture.componentInstance.error()).toBe(true);
    expect(fixture.componentInstance.loading()).toBe(false);
  });

  it('should_show_error_toast_when_pay_fails', async () => {
    // Arrange
    subscriptionServiceMock.pay.mockReturnValue(throwError(() => ({ status: 500 })));

    const fixture = TestBed.createComponent(SubscriptionDetail);
    fixture.detectChanges();
    await fixture.whenStable();
    await flushAsync();

    // Act
    await fixture.componentInstance.onPay();
    await fixture.whenStable();

    // Assert
    expect(toastServiceMock.error).toHaveBeenCalledWith('Échec du paiement');
    expect(fixture.componentInstance.payInProgress()).toBe(false);
  });
});
