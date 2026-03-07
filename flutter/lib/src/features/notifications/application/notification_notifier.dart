import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/domain/repositories/notification_repository.dart';
import 'package:k_budget/src/services/stomp_service.dart';

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, ListState<NotificationModel>>(
  NotificationNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  return state.items.where((n) => !n.read).length;
});

class NotificationNotifier extends Notifier<ListState<NotificationModel>> {
  static const _pageSize = 20;

  @override
  ListState<NotificationModel> build() => const ListState<NotificationModel>();

  Future<NotificationRepository> get _repo => ref.read(notificationRepositoryProvider.future);

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await (await _repo).getNotifications(page: 0, size: _pageSize);
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        items: items,
        isLoading: false,
        currentPage: 0,
        hasMore: items.length >= _pageSize,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les notifications: $e',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    try {
      final newItems = await (await _repo).getNotifications(page: nextPage, size: _pageSize);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        currentPage: nextPage,
        hasMore: newItems.length >= _pageSize,
      );
    } on Exception catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      await (await _repo).markAsRead(id);
      final index = state.items.indexWhere((e) => e.id == id);
      if (index != -1 && !state.items[index].read) {
        final updated = List<NotificationModel>.of(state.items);
        updated[index] = updated[index].copyWith(read: true, readAt: DateTime.now());
        state = state.copyWith(
          items: updated,
          mutatingIds: {...state.mutatingIds}..remove(id),
        );
      } else {
        state = state.copyWith(
          mutatingIds: {...state.mutatingIds}..remove(id),
        );
      }
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur: $e',
      );
    }
  }

  Future<void> markAllAsRead() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await (await _repo).markAllAsRead();
      final now = DateTime.now();
      state = state.copyWith(
        items: state.items.map((n) => n.copyWith(read: true, readAt: now)).toList(),
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur: $e');
    }
  }

  Future<void> delete(String id) async {
    final index = state.items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final saved = state.items[index];

    final updated = List<NotificationModel>.of(state.items)..removeAt(index);
    state = state.copyWith(items: updated, mutatingIds: {...state.mutatingIds, id});

    try {
      await (await _repo).deleteNotification(id);
      state = state.copyWith(mutatingIds: {...state.mutatingIds}..remove(id));
    } on Exception catch (e) {
      final restored = List<NotificationModel>.of(state.items)..insert(index, saved);
      restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        items: restored,
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur: $e',
      );
    }
  }

  Future<void> deleteAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await (await _repo).deleteAll();
      state = state.copyWith(items: [], isLoading: false, currentPage: 0, hasMore: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur: $e');
    }
  }

  void addNotification(NotificationModel notification) {
    if (state.items.any((n) => n.id == notification.id)) return;
    state = state.copyWith(items: [notification, ...state.items]);
  }
}

final notificationStompListenerProvider = Provider<void>((ref) {
  final stompService = ref.watch(stompServiceProvider);
  final notifier = ref.watch(notificationNotifierProvider.notifier);

  final StreamSubscription<NotificationModel> subscription =
      stompService.notifications.listen((notification) {
    notifier.addNotification(notification);
  });

  ref.onDispose(() => subscription.cancel());
});
