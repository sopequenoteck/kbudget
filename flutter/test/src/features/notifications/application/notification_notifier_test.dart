import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/domain/repositories/notification_repository.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';

// Mock manuel — NotificationRepository n'est pas encore dans mocks.mocks.dart
class MockNotificationRepository implements NotificationRepository {
  List<NotificationModel> _items = [];
  int _unreadCount = 0;
  bool shouldThrow = false;

  void setItems(List<NotificationModel> items) {
    _items = List.of(items);
    _unreadCount = items.where((n) => !n.read).length;
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 0,
    int size = 20,
    bool? unreadOnly,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    final start = page * size;
    if (start >= _items.length) return [];
    final end = (start + size).clamp(0, _items.length);
    return List.of(_items.sublist(start, end));
  }

  @override
  Future<int> getUnreadCount() async {
    if (shouldThrow) throw Exception('Network error');
    return _unreadCount;
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    if (shouldThrow) throw Exception('Network error');
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1) throw Exception('Not found');
    _items[index] = _items[index].copyWith(read: true, readAt: DateTime.now());
    return _items[index];
  }

  @override
  Future<void> markAllAsRead() async {
    if (shouldThrow) throw Exception('Network error');
    final now = DateTime.now();
    _items = _items.map((n) => n.copyWith(read: true, readAt: now)).toList();
  }

  @override
  Future<void> deleteNotification(String id) async {
    if (shouldThrow) throw Exception('Network error');
    _items.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> deleteAll() async {
    if (shouldThrow) throw Exception('Network error');
    _items.clear();
  }
}

// Helpers de construction
NotificationModel makeNotification({
  required String id,
  bool read = false,
  DateTime? createdAt,
}) {
  return NotificationModel(
    id: id,
    type: NotificationType.subscriptionDue,
    title: 'Notification $id',
    message: 'Message pour $id',
    read: read,
    createdAt: createdAt ?? DateTime(2026, 3, 1).subtract(Duration(seconds: int.parse(id))),
  );
}

void main() {
  late MockNotificationRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockNotificationRepository();
    container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWith((ref) async => mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  NotificationNotifier notifier() =>
      container.read(notificationNotifierProvider.notifier);

  ListState<NotificationModel> state() =>
      container.read(notificationNotifierProvider);

  group('NotificationNotifier', () {
    test('should_have_empty_state_when_created', () {
      // Assert
      expect(state().items, isEmpty);
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_load_notifications_when_init', () async {
      // Arrange
      mockRepo.setItems([
        makeNotification(id: '1'),
        makeNotification(id: '2'),
      ]);

      // Act
      await notifier().loadItems();

      // Assert
      expect(state().items, hasLength(2));
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_sort_by_date_desc_when_loaded', () async {
      // Arrange — notif '2' a un createdAt plus récent (moins de secondes soustraites)
      mockRepo.setItems([
        makeNotification(id: '1'), // createdAt: 2026-03-01 - 1s
        makeNotification(id: '2'), // createdAt: 2026-03-01 - 2s → plus ancien
      ]);

      // Act
      await notifier().loadItems();

      // Assert — tri desc : id='1' en premier (plus récent)
      expect(state().items.first.id, '1');
    });

    test('should_show_error_when_load_fails', () async {
      // Arrange
      mockRepo.shouldThrow = true;

      // Act
      await notifier().loadItems();

      // Assert
      expect(state().error, contains('Impossible de charger'));
      expect(state().isLoading, false);
    });

    test('should_mark_as_read_when_called', () async {
      // Arrange
      mockRepo.setItems([
        makeNotification(id: '1', read: false),
        makeNotification(id: '2', read: false),
      ]);
      await notifier().loadItems();

      // Act
      await notifier().markAsRead('1');

      // Assert
      final updatedItem = state().items.firstWhere((n) => n.id == '1');
      expect(updatedItem.read, true);
      expect(updatedItem.readAt, isNotNull);
    });

    test('should_not_affect_other_items_when_mark_as_read', () async {
      // Arrange
      mockRepo.setItems([
        makeNotification(id: '1', read: false),
        makeNotification(id: '2', read: false),
      ]);
      await notifier().loadItems();

      // Act
      await notifier().markAsRead('1');

      // Assert — id='2' reste non lue
      final otherItem = state().items.firstWhere((n) => n.id == '2');
      expect(otherItem.read, false);
    });

    test('should_mark_all_as_read_when_called', () async {
      // Arrange
      mockRepo.setItems([
        makeNotification(id: '1', read: false),
        makeNotification(id: '2', read: false),
        makeNotification(id: '3', read: false),
      ]);
      await notifier().loadItems();

      // Act
      await notifier().markAllAsRead();

      // Assert
      expect(state().items.every((n) => n.read), true);
      expect(state().isLoading, false);
    });

    test('should_delete_notification_when_called', () async {
      // Arrange
      mockRepo.setItems([
        makeNotification(id: '1'),
        makeNotification(id: '2'),
      ]);
      await notifier().loadItems();

      // Act
      await notifier().delete('1');

      // Assert
      expect(state().items, hasLength(1));
      expect(state().items.first.id, '2');
    });

    test('should_rollback_when_delete_fails', () async {
      // Arrange
      mockRepo.setItems([makeNotification(id: '1')]);
      await notifier().loadItems();
      mockRepo.shouldThrow = true;

      // Act
      await notifier().delete('1');

      // Assert — rollback : l'item est restauré
      expect(state().items, hasLength(1));
      expect(state().error, contains('Erreur'));
    });

    test('should_load_more_when_has_more', () async {
      // Arrange — 25 items pour dépasser la page size de 20
      final items = List.generate(
        25,
        (i) => makeNotification(
          id: '${i + 1}',
          createdAt: DateTime(2026, 3, 1).subtract(Duration(seconds: i)),
        ),
      );
      mockRepo.setItems(items);

      // Act — charger la première page
      await notifier().loadItems();
      expect(state().items, hasLength(20));
      expect(state().hasMore, true);

      // Act — charger la page suivante
      await notifier().loadMore();

      // Assert
      expect(state().items, hasLength(25));
      expect(state().hasMore, false);
    });

    test('should_not_load_more_when_no_more', () async {
      // Arrange — moins de 20 items
      mockRepo.setItems(
        List.generate(5, (i) => makeNotification(id: '${i + 1}')),
      );
      await notifier().loadItems();
      expect(state().hasMore, false);

      // Act
      await notifier().loadMore();

      // Assert — rien ne change
      expect(state().items, hasLength(5));
    });

    test('should_add_notification_when_new_arrives', () async {
      // Arrange
      mockRepo.setItems([makeNotification(id: '1')]);
      await notifier().loadItems();

      // Act
      final newNotif = makeNotification(id: '99');
      notifier().addNotification(newNotif);

      // Assert — prépendé en tête
      expect(state().items, hasLength(2));
      expect(state().items.first.id, '99');
    });

    test('should_deduplicate_when_same_notification_added_twice', () async {
      // Arrange
      mockRepo.setItems([]);
      await notifier().loadItems();

      final notif = makeNotification(id: '42');

      // Act — ajouter 2x le même
      notifier().addNotification(notif);
      notifier().addNotification(notif);

      // Assert — apparaît une seule fois
      expect(state().items, hasLength(1));
    });

    test('should_delete_all_when_deleteAll_called', () async {
      // Arrange
      mockRepo.setItems([
        makeNotification(id: '1'),
        makeNotification(id: '2'),
      ]);
      await notifier().loadItems();

      // Act
      await notifier().deleteAll();

      // Assert
      expect(state().items, isEmpty);
      expect(state().isLoading, false);
    });
  });
}
