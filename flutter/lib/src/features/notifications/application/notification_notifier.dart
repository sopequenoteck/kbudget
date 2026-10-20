// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/domain/repositories/notification_repository.dart';
import 'package:k_budget/src/features/common/application/session_guard.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/services/stomp_service.dart';

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, ListState<NotificationModel>>(
  NotificationNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  return state.items.where((n) => !n.read).length;
});

/// Notifications du compte, paginees cote serveur.
class NotificationNotifier extends Notifier<ListState<NotificationModel>>
    with SessionGuard {
  static const _pageSize = 20;

  @override
  ListState<NotificationModel> build() {
    // L'etat appartient a la session : reconstruit a chaque connexion et
    // deconnexion, sinon B heriterait des donnees de A (KKS-546).
    watchSession(ref);
    return const ListState<NotificationModel>();
  }

  Future<NotificationRepository> get _repo => ref.read(notificationRepositoryProvider.future);

  Future<void> loadItems() async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await (await _repo).getNotifications(page: 0, size: _pageSize);
      if (isStale(token)) {
        return;
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        items: items,
        isLoading: false,
        currentPage: 0,
        hasMore: items.length >= _pageSize,
      );
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackLoadError,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    final token = session;
    try {
      final newItems = await (await _repo).getNotifications(page: nextPage, size: _pageSize);
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        items: [...state.items, ...newItems],
        currentPage: nextPage,
        hasMore: newItems.length >= _pageSize,
      );
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        error: ref.read(appLocalizationsProvider).commonFeedbackLoadError,
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final token = session;
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      await (await _repo).markAsRead(id);
      if (isStale(token)) {
        return;
      }
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
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: ref.read(appLocalizationsProvider).commonFeedbackSaveError,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await (await _repo).markAllAsRead();
      if (isStale(token)) {
        return;
      }
      final now = DateTime.now();
      state = state.copyWith(
        items: state.items.map((n) => n.copyWith(read: true, readAt: now)).toList(),
        isLoading: false,
      );
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackSaveError,
      );
    }
  }

  Future<void> delete(String id) async {
    final index = state.items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final saved = state.items[index];
    final token = session;

    final updated = List<NotificationModel>.of(state.items)..removeAt(index);
    state = state.copyWith(items: updated, mutatingIds: {...state.mutatingIds, id});

    try {
      await (await _repo).deleteNotification(id);
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(mutatingIds: {...state.mutatingIds}..remove(id));
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      final restored = List<NotificationModel>.of(state.items)..insert(index, saved);
      restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        items: restored,
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: ref.read(appLocalizationsProvider).commonFeedbackDeleteError,
      );
    }
  }

  Future<void> deleteAll() async {
    final token = session;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await (await _repo).deleteAll();
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(items: [], isLoading: false, currentPage: 0, hasMore: false);
    } on Exception catch (_) {
      if (isStale(token)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: ref.read(appLocalizationsProvider).commonFeedbackDeleteError,
      );
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
