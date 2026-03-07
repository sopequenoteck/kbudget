import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';

import { NotificationService } from './notification';
import { ApiService } from './api';
import { type NotificationModel, type NotificationPage } from '../models/notification.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const makeNotification = (overrides: Partial<NotificationModel> = {}): NotificationModel => ({
  id: 'notif-1',
  type: 'SUBSCRIPTION_DUE',
  title: 'Échéance abonnement',
  message: 'Votre abonnement arrive à échéance demain',
  entityType: 'SUBSCRIPTION',
  entityId: 'sub-1',
  read: false,
  readAt: null,
  createdAt: '2026-03-01T10:00:00Z',
  ...overrides,
});

const makeNotificationPage = (
  content: NotificationModel[],
  overrides: Partial<NotificationPage> = {},
): NotificationPage => ({
  content,
  number: 0,
  size: 20,
  totalElements: content.length,
  totalPages: 1,
  ...overrides,
});

describe('NotificationService', () => {
  let service: NotificationService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    put: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [NotificationService, { provide: ApiService, useValue: apiService }],
    });

    service = TestBed.inject(NotificationService);
  });

  describe('loadNotifications()', () => {
    it('should_load_notifications_when_called', async () => {
      // Arrange
      const notif1 = makeNotification({ id: 'notif-1' });
      const notif2 = makeNotification({ id: 'notif-2', title: 'Échéance dette', type: 'DEBT_DUE' });
      const page = makeNotificationPage([notif1, notif2]);
      apiService.get.mockReturnValue(of(page));

      // Act
      await service.loadNotifications();

      // Assert
      expect(apiService.get).toHaveBeenCalledWith('/notifications?page=0&size=20');
      expect(service.notifications()).toHaveLength(2);
      expect(service.notifications()[0].id).toBe('notif-1');
      expect(service.isLoading()).toBe(false);
    });

    it('should_set_hasMore_true_when_multiple_pages', async () => {
      // Arrange
      const page = makeNotificationPage([makeNotification()], {
        number: 0,
        totalPages: 3,
      });
      apiService.get.mockReturnValue(of(page));

      // Act
      await service.loadNotifications();

      // Assert
      expect(service.hasMore()).toBe(true);
      expect(service.currentPage()).toBe(0);
    });

    it('should_set_hasMore_false_when_single_page', async () => {
      // Arrange
      const page = makeNotificationPage([makeNotification()], {
        number: 0,
        totalPages: 1,
      });
      apiService.get.mockReturnValue(of(page));

      // Act
      await service.loadNotifications();

      // Assert
      expect(service.hasMore()).toBe(false);
    });

    it('should_not_throw_when_api_fails', async () => {
      // Arrange
      apiService.get.mockReturnValue(throwError(() => new Error('Network error')));

      // Act & Assert (no exception)
      await expect(service.loadNotifications()).resolves.toBeUndefined();
      expect(service.isLoading()).toBe(false);
    });
  });

  describe('loadUnreadCount()', () => {
    it('should_return_unread_count_when_has_unread', async () => {
      // Arrange
      apiService.get.mockReturnValue(of({ count: 5 }));

      // Act
      await service.loadUnreadCount();

      // Assert
      expect(apiService.get).toHaveBeenCalledWith('/notifications/unread-count');
      expect(service.unreadCount()).toBe(5);
      expect(service.hasUnread()).toBe(true);
    });

    it('should_return_zero_unread_when_all_read', async () => {
      // Arrange
      apiService.get.mockReturnValue(of({ count: 0 }));

      // Act
      await service.loadUnreadCount();

      // Assert
      expect(service.unreadCount()).toBe(0);
      expect(service.hasUnread()).toBe(false);
    });
  });

  describe('markAsRead()', () => {
    it('should_mark_as_read_when_valid_id', async () => {
      // Arrange — charger une notification non lue
      const notif = makeNotification({ id: 'notif-1', read: false });
      const page = makeNotificationPage([notif]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(1);

      const updated = { ...notif, read: true, readAt: '2026-03-07T00:00:00Z' };
      apiService.put.mockReturnValue(of(updated));

      // Act
      await service.markAsRead('notif-1');

      // Assert — optimistic update avant la réponse API
      expect(service.notifications()[0].read).toBe(true);
      expect(service.notifications()[0].readAt).not.toBeNull();
      expect(service.unreadCount()).toBe(0);
      expect(apiService.put).toHaveBeenCalledWith('/notifications/notif-1/read', {});
    });

    it('should_not_decrement_unread_count_below_zero', async () => {
      // Arrange
      const notif = makeNotification({ id: 'notif-1', read: false });
      const page = makeNotificationPage([notif]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(0); // déjà à 0

      apiService.put.mockReturnValue(of({ ...notif, read: true }));

      // Act
      await service.markAsRead('notif-1');

      // Assert
      expect(service.unreadCount()).toBe(0);
    });
  });

  describe('markAllAsRead()', () => {
    it('should_mark_all_as_read_when_called', async () => {
      // Arrange
      const notif1 = makeNotification({ id: 'notif-1', read: false });
      const notif2 = makeNotification({ id: 'notif-2', read: false });
      const page = makeNotificationPage([notif1, notif2]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(2);

      apiService.put.mockReturnValue(of(undefined));

      // Act
      await service.markAllAsRead();

      // Assert
      expect(service.notifications().every((n) => n.read)).toBe(true);
      expect(service.unreadCount()).toBe(0);
      expect(apiService.put).toHaveBeenCalledWith('/notifications/read-all', {});
    });
  });

  describe('deleteNotification()', () => {
    it('should_delete_notification_when_valid_id', async () => {
      // Arrange
      const notif1 = makeNotification({ id: 'notif-1', read: false });
      const notif2 = makeNotification({ id: 'notif-2', read: true });
      const page = makeNotificationPage([notif1, notif2]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(1);

      apiService.delete.mockReturnValue(of(undefined));

      // Act
      await service.deleteNotification('notif-1');

      // Assert
      expect(service.notifications()).toHaveLength(1);
      expect(service.notifications()[0].id).toBe('notif-2');
      expect(service.unreadCount()).toBe(0); // notif-1 était non lue
      expect(apiService.delete).toHaveBeenCalledWith('/notifications/notif-1');
    });

    it('should_not_decrement_unread_when_deleting_read_notification', async () => {
      // Arrange
      const readNotif = makeNotification({ id: 'notif-1', read: true });
      const page = makeNotificationPage([readNotif]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(2);

      apiService.delete.mockReturnValue(of(undefined));

      // Act
      await service.deleteNotification('notif-1');

      // Assert
      expect(service.unreadCount()).toBe(2); // inchangé
    });
  });

  describe('addNotification()', () => {
    it('should_add_notification_with_deduplication', () => {
      // Arrange
      const notif = makeNotification({ id: 'notif-1', read: false });

      // Act — appeler 2x avec le même ID
      service.addNotification(notif);
      service.addNotification(notif);

      // Assert — apparaît une seule fois
      expect(service.notifications()).toHaveLength(1);
      expect(service.unreadCount()).toBe(1);
    });

    it('should_increment_unread_count_when_adding_unread_notification', () => {
      // Arrange
      const unreadNotif = makeNotification({ id: 'notif-1', read: false });
      service.unreadCount.set(3);

      // Act
      service.addNotification(unreadNotif);

      // Assert
      expect(service.unreadCount()).toBe(4);
    });

    it('should_not_increment_unread_count_when_adding_read_notification', () => {
      // Arrange
      const readNotif = makeNotification({ id: 'notif-1', read: true });
      service.unreadCount.set(2);

      // Act
      service.addNotification(readNotif);

      // Assert
      expect(service.unreadCount()).toBe(2);
    });

    it('should_prepend_notification_to_list', () => {
      // Arrange
      const existing = makeNotification({ id: 'existing', title: 'Existant' });
      const newNotif = makeNotification({ id: 'new', title: 'Nouveau' });

      service.addNotification(existing);
      service.addNotification(newNotif);

      // Assert — le plus récent en tête
      expect(service.notifications()[0].id).toBe('new');
      expect(service.notifications()[1].id).toBe('existing');
    });
  });

  describe('hasUnread computed', () => {
    it('should_return_true_when_unread_count_positive', () => {
      // Arrange
      service.unreadCount.set(1);

      // Assert
      expect(service.hasUnread()).toBe(true);
    });

    it('should_return_false_when_unread_count_zero', () => {
      // Arrange
      service.unreadCount.set(0);

      // Assert
      expect(service.hasUnread()).toBe(false);
    });
  });

  describe('deleteAll()', () => {
    it('should_clear_all_notifications_when_called', async () => {
      // Arrange
      const notif1 = makeNotification({ id: 'notif-1', read: false });
      const notif2 = makeNotification({ id: 'notif-2', read: true });
      const page = makeNotificationPage([notif1, notif2]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(1);

      apiService.delete.mockReturnValue(of(undefined));

      // Act
      await service.deleteAll();

      // Assert
      expect(service.notifications()).toHaveLength(0);
      expect(service.unreadCount()).toBe(0);
      expect(apiService.delete).toHaveBeenCalledWith('/notifications');
    });

    it('should_rollback_when_deleteAll_fails', async () => {
      // Arrange
      const notif1 = makeNotification({ id: 'notif-1', read: false });
      const notif2 = makeNotification({ id: 'notif-2', read: true });
      const page = makeNotificationPage([notif1, notif2]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(1);

      apiService.delete.mockReturnValue(throwError(() => new Error('Network error')));

      // Act
      await service.deleteAll();

      // Assert — restauration de l'état précédent
      expect(service.notifications()).toHaveLength(2);
      expect(service.unreadCount()).toBe(1);
    });
  });

  describe('loadMore()', () => {
    it('should_append_notifications_when_loading_more', async () => {
      // Arrange — charger la page 0
      const notif1 = makeNotification({ id: 'notif-1' });
      const page0 = makeNotificationPage([notif1], { number: 0, totalPages: 2 });
      apiService.get.mockReturnValue(of(page0));
      await service.loadNotifications();

      // Mock page 1
      const notif2 = makeNotification({ id: 'notif-2' });
      const page1 = makeNotificationPage([notif2], { number: 1, totalPages: 2 });
      apiService.get.mockReturnValue(of(page1));

      // Act
      await service.loadMore();

      // Assert — les notifications sont concaténées
      expect(service.notifications()).toHaveLength(2);
      expect(service.notifications()[0].id).toBe('notif-1');
      expect(service.notifications()[1].id).toBe('notif-2');
      expect(apiService.get).toHaveBeenCalledWith('/notifications?page=1&size=20');
    });

    it('should_not_load_when_no_more_pages', async () => {
      // Arrange
      service.hasMore.set(false);
      apiService.get.mockReturnValue(of(makeNotificationPage([])));

      // Act
      await service.loadMore();

      // Assert — l'API n'est pas appelée
      expect(apiService.get).not.toHaveBeenCalled();
    });

    it('should_not_load_when_already_loading', async () => {
      // Arrange
      service.isLoading.set(true);
      apiService.get.mockReturnValue(of(makeNotificationPage([])));

      // Act
      await service.loadMore();

      // Assert — l'API n'est pas appelée
      expect(apiService.get).not.toHaveBeenCalled();
    });

    it('should_use_server_page_number', async () => {
      // Arrange — charger la page 0 pour initialiser
      const page0 = makeNotificationPage([makeNotification({ id: 'notif-1' })], {
        number: 0,
        totalPages: 3,
      });
      apiService.get.mockReturnValue(of(page0));
      await service.loadNotifications();

      // Mock page 1 avec number: 1 retourné par le serveur
      const page1 = makeNotificationPage([makeNotification({ id: 'notif-2' })], {
        number: 1,
        totalPages: 3,
      });
      apiService.get.mockReturnValue(of(page1));

      // Act
      await service.loadMore();

      // Assert — currentPage vaut le number retourné par le serveur (1)
      expect(service.currentPage()).toBe(1);
    });
  });

  describe('startPolling() / stopPolling()', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should_load_unread_count_immediately_when_polling_starts', async () => {
      // Arrange
      apiService.get.mockReturnValue(of({ count: 3 }));
      const spy = vi.spyOn(service, 'loadUnreadCount');

      // Act
      service.startPolling();
      await Promise.resolve(); // flush la micro-task async

      // Assert — appelé immédiatement au démarrage
      expect(spy).toHaveBeenCalledTimes(1);

      service.stopPolling();
    });

    it('should_stop_polling_when_stopPolling_called', async () => {
      // Arrange
      apiService.get.mockReturnValue(of({ count: 0 }));
      const spy = vi.spyOn(service, 'loadUnreadCount');

      // Act
      service.startPolling();
      await Promise.resolve(); // flush l'appel immédiat
      service.stopPolling();

      // Avancer le timer de 60s (2x l'intervalle de 30s)
      vi.advanceTimersByTime(60000);

      // Assert — loadUnreadCount n'a été appelé qu'une fois (au startPolling)
      expect(spy).toHaveBeenCalledTimes(1);
    });
  });

  describe('markAsRead() rollback', () => {
    it('should_rollback_when_markAsRead_fails', async () => {
      // Arrange
      const notif = makeNotification({ id: 'notif-1', read: false });
      const page = makeNotificationPage([notif]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(1);

      apiService.put.mockReturnValue(throwError(() => new Error('Network error')));

      // Act
      await service.markAsRead('notif-1');

      // Assert — rollback : la notification redevient non lue
      expect(service.notifications()[0].read).toBe(false);
      expect(service.unreadCount()).toBe(1);
    });
  });

  describe('markAllAsRead() rollback', () => {
    it('should_rollback_when_markAllAsRead_fails', async () => {
      // Arrange
      const notif1 = makeNotification({ id: 'notif-1', read: false });
      const notif2 = makeNotification({ id: 'notif-2', read: false });
      const page = makeNotificationPage([notif1, notif2]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(2);

      apiService.put.mockReturnValue(throwError(() => new Error('Network error')));

      // Act
      await service.markAllAsRead();

      // Assert — rollback : les notifications redeviennent non lues
      expect(service.notifications().every((n) => !n.read)).toBe(true);
      expect(service.unreadCount()).toBe(2);
    });
  });

  describe('deleteNotification() rollback', () => {
    it('should_rollback_when_deleteNotification_fails', async () => {
      // Arrange
      const notif = makeNotification({ id: 'notif-1', read: false });
      const page = makeNotificationPage([notif]);
      apiService.get.mockReturnValue(of(page));
      await service.loadNotifications();
      service.unreadCount.set(1);

      apiService.delete.mockReturnValue(throwError(() => new Error('Network error')));

      // Act
      await service.deleteNotification('notif-1');

      // Assert — rollback : la notification est restaurée
      expect(service.notifications()).toHaveLength(1);
      expect(service.notifications()[0].id).toBe('notif-1');
      expect(service.unreadCount()).toBe(1);
    });
  });
});
