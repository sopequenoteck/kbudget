import { TestBed } from '@angular/core/testing';
import { Router, UrlTree } from '@angular/router';

import { PreferenceService } from '../services/preference';
import { featureGuard } from './feature.guard';

describe('featureGuard', () => {
  let preferenceService: {
    isLoaded: ReturnType<typeof vi.fn>;
    isEnabled: ReturnType<typeof vi.fn>;
  };
  let router: { createUrlTree: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    preferenceService = {
      isLoaded: vi.fn(),
      isEnabled: vi.fn(),
    };

    const mockUrlTree = {} as UrlTree;
    router = {
      createUrlTree: vi.fn().mockReturnValue(mockUrlTree),
    };

    TestBed.configureTestingModule({
      providers: [
        { provide: PreferenceService, useValue: preferenceService },
        { provide: Router, useValue: router },
      ],
    });
  });

  function runGuard(feature?: string): boolean | UrlTree {
    const routeData = feature ? { feature } : {};
    return TestBed.runInInjectionContext(() =>
      featureGuard({ data: routeData } as never, {} as never),
    );
  }

  it('should_allow_navigation_when_feature_enabled', () => {
    // Arrange
    preferenceService.isLoaded.mockReturnValue(true);
    preferenceService.isEnabled.mockReturnValue(true);

    // Act
    const result = runGuard('SUBSCRIPTIONS');

    // Assert
    expect(result).toBe(true);
  });

  it('should_redirect_to_dashboard_when_feature_disabled', () => {
    // Arrange
    preferenceService.isLoaded.mockReturnValue(true);
    preferenceService.isEnabled.mockReturnValue(false);

    // Act
    runGuard('SUBSCRIPTIONS');

    // Assert
    expect(router.createUrlTree).toHaveBeenCalledWith(['/dashboard']);
  });

  it('should_allow_navigation_when_preferences_not_loaded', () => {
    // Arrange
    preferenceService.isLoaded.mockReturnValue(false);

    // Act
    const result = runGuard('SUBSCRIPTIONS');

    // Assert
    expect(result).toBe(true);
  });

  it('should_allow_navigation_when_no_feature_in_route_data', () => {
    // Arrange — no setup needed, route.data has no 'feature' key

    // Act
    const result = runGuard();

    // Assert
    expect(result).toBe(true);
  });
});
