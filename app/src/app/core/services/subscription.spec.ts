import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';

import { SubscriptionService } from './subscription';
import { ApiService } from './api';
import { Subscription, SubscriptionRequest, Frequency } from '../models/subscription.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockSubscription: Subscription = {
  id: 'uuid-1',
  nom: 'Netflix',
  montant: 13.99,
  frequence: Frequency.MENSUEL,
  dateDebut: '2026-01-01',
  actif: true,
  category: null,
  account: null,
};

const mockRequest: SubscriptionRequest = {
  nom: 'Netflix',
  montant: 13.99,
  frequence: Frequency.MENSUEL,
  dateDebut: '2026-01-01',
};

describe('SubscriptionService', () => {
  let service: SubscriptionService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    post: ReturnType<typeof vi.fn>;
    put: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [SubscriptionService, { provide: ApiService, useValue: apiService }],
    });

    service = TestBed.inject(SubscriptionService);
  });

  it('should_return_subscriptions_when_getAll_called_without_filter', () => {
    // Arrange
    const subscriptions = [mockSubscription];
    apiService.get.mockReturnValue(of(subscriptions));

    // Act
    service.getAll().subscribe((result) => {
      // Assert
      expect(result).toEqual(subscriptions);
    });

    expect(apiService.get).toHaveBeenCalledWith('/subscriptions');
  });

  it('should_return_active_subscriptions_when_getAll_called_with_actif_true', () => {
    // Arrange
    const subscriptions = [mockSubscription];
    apiService.get.mockReturnValue(of(subscriptions));

    // Act
    service.getAll(true).subscribe((result) => {
      // Assert
      expect(result).toEqual(subscriptions);
    });

    expect(apiService.get).toHaveBeenCalledWith('/subscriptions?actif=true');
  });

  it('should_return_inactive_subscriptions_when_getAll_called_with_actif_false', () => {
    // Arrange
    const subscriptions: Subscription[] = [];
    apiService.get.mockReturnValue(of(subscriptions));

    // Act
    service.getAll(false).subscribe((result) => {
      // Assert
      expect(result).toEqual(subscriptions);
    });

    expect(apiService.get).toHaveBeenCalledWith('/subscriptions?actif=false');
  });

  it('should_return_subscription_when_getById_called', () => {
    // Arrange
    apiService.get.mockReturnValue(of(mockSubscription));

    // Act
    service.getById('uuid-1').subscribe((result) => {
      // Assert
      expect(result).toEqual(mockSubscription);
    });

    expect(apiService.get).toHaveBeenCalledWith('/subscriptions/uuid-1');
  });

  it('should_create_and_refresh_when_create_called', () => {
    // Arrange
    apiService.post.mockReturnValue(of(mockSubscription));
    const before = service.refreshTrigger();

    // Act
    service.create(mockRequest).subscribe((result) => {
      // Assert
      expect(result).toEqual(mockSubscription);
    });

    expect(apiService.post).toHaveBeenCalledWith('/subscriptions', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_update_and_refresh_when_update_called', () => {
    // Arrange
    apiService.put.mockReturnValue(of(mockSubscription));
    const before = service.refreshTrigger();

    // Act
    service.update('uuid-1', mockRequest).subscribe((result) => {
      // Assert
      expect(result).toEqual(mockSubscription);
    });

    expect(apiService.put).toHaveBeenCalledWith('/subscriptions/uuid-1', mockRequest);
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_delete_and_refresh_when_delete_called', () => {
    // Arrange
    apiService.delete.mockReturnValue(of(undefined));
    const before = service.refreshTrigger();

    // Act
    service.delete('uuid-1').subscribe();

    expect(apiService.delete).toHaveBeenCalledWith('/subscriptions/uuid-1');
    expect(service.refreshTrigger()).toBe(before + 1);
  });

  it('should_increment_refreshTrigger_on_successive_mutations', () => {
    // Arrange
    apiService.post.mockReturnValue(of(mockSubscription));
    expect(service.refreshTrigger()).toBe(0);

    // Act
    service.create(mockRequest).subscribe();
    service.create(mockRequest).subscribe();
    service.create(mockRequest).subscribe();

    // Assert
    expect(service.refreshTrigger()).toBe(3);
  });
});
