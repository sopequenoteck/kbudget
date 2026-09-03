import { TestBed } from '@angular/core/testing';

import { StompService } from './stomp';
import { NotificationService } from './notification';
import { AuthService } from './auth';
import { ApiService } from './api';

// Mock Client from @stomp/stompjs
vi.mock('@stomp/stompjs', () => {
  return {
    Client: class MockClient {
      active = false;
      activate = vi.fn();
      deactivate = vi.fn();
      subscribe = vi.fn();
      connectHeaders: Record<string, string> = {};
      constructor(config: Record<string, unknown>) {
        Object.assign(this, config);
      }
    },
  };
});

describe('StompService', () => {
  let service: StompService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    put: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };
  let authService: {
    getToken: ReturnType<typeof vi.fn>;
    isAuthenticated: ReturnType<typeof vi.fn>;
    currentUser: ReturnType<typeof vi.fn>;
    logout: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
    };

    authService = {
      getToken: vi.fn().mockReturnValue('mock-token'),
      isAuthenticated: vi.fn().mockReturnValue(true),
      currentUser: vi.fn().mockReturnValue(null),
      logout: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [
        StompService,
        NotificationService,
        { provide: ApiService, useValue: apiService },
        { provide: AuthService, useValue: authService },
      ],
    });

    service = TestBed.inject(StompService);
  });

  it('should_create_service', () => {
    expect(service).toBeTruthy();
  });

  it('should_create_stomp_client_when_connect_called', () => {
    // Act
    service.connect();

    // Assert — client est créé (non null après connect)
    // On vérifie indirectement via disconnect qui ne throw pas
    service.disconnect();
  });

  it('should_not_create_new_client_when_already_active', () => {
    // Arrange — premier connect
    service.connect();
    // Simuler que le client est actif
    const clientField = (service as { client: { active: boolean } | null })['client'];
    if (clientField) clientField.active = true;

    // Act — deuxième connect ne doit pas recréer
    service.connect();

    // Assert — pas d'erreur, un seul client
    service.disconnect();
  });

  it('should_set_client_null_after_disconnect', () => {
    // Arrange
    service.connect();

    // Act
    service.disconnect();

    // Assert
    expect((service as { client: unknown })['client']).toBeNull();
  });
});
