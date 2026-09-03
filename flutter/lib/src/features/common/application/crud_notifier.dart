// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/repositories/crud_repository.dart';
import 'package:flutter/foundation.dart';

/// Classe de base pour les notifiers CRUD avec pagination client-side.
///
/// Les sous-classes doivent implémenter [repo], [itemId], [sortItems]
/// et [entityLabel]. Elles peuvent optionnellement surcharger
/// [validateUpdate] et [validateDelete] pour ajouter des gardes.
abstract class CrudNotifier<T> extends Notifier<ListState<T>> {
  static const _pageSize = 20;
  @protected
  List<T> allItems = [];

  /// Le repository CRUD à utiliser.
  CrudRepository<T> get repo;

  /// Extrait l'identifiant unique d'un item.
  String itemId(T item);

  /// Trie la liste d'items en place.
  void sortItems(List<T> items);

  /// Label de l'entité pour les messages d'erreur (ex: "comptes").
  String get entityLabel;

  /// Valide avant une mise à jour. Retourne un message d'erreur ou null.
  String? validateUpdate(T item) => null;

  /// Valide avant une suppression. Retourne un message d'erreur ou null.
  String? validateDelete(String id) => null;

  @override
  ListState<T> build() => ListState<T>();

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      allItems = await repo.getAll();
      sortItems(allItems);
      refreshPage(resetPage: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les $entityLabel: $e',
      );
    }
  }

  Future<void> refresh() async => loadItems();

  void loadMore() {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    final end = (nextPage + 1) * _pageSize;
    final page = allItems.take(end).toList();
    state = state.copyWith(
      items: page,
      currentPage: nextPage,
      hasMore: end < allItems.length,
    );
  }

  Future<void> create(T item) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await repo.create(item);
      allItems.add(created);
      sortItems(allItems);
      refreshPage();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
    }
  }

  Future<void> update(T item) async {
    final error = validateUpdate(item);
    if (error != null) {
      state = state.copyWith(error: error);
      return;
    }
    final id = itemId(item);
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final updated = await repo.update(item);
      final index = allItems.indexWhere((e) => itemId(e) == id);
      if (index != -1) allItems[index] = updated;
      sortItems(allItems);
      refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors de la modification: $e',
      );
    }
  }

  Future<void> delete(String id) async {
    final error = validateDelete(id);
    if (error != null) {
      state = state.copyWith(error: error);
      return;
    }
    final index = allItems.indexWhere((e) => itemId(e) == id);
    if (index == -1) return;
    final saved = allItems[index];

    allItems.removeAt(index);
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    refreshPage();

    try {
      await repo.delete(id);
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      allItems.insert(index, saved);
      sortItems(allItems);
      refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors de la suppression: $e',
      );
    }
  }

  @protected
  void refreshPage({bool resetPage = false}) {
    final page = resetPage ? 0 : state.currentPage;
    final end = (page + 1) * _pageSize;
    final items = allItems.take(end).toList();
    state = state.copyWith(
      items: items,
      isLoading: false,
      currentPage: page,
      hasMore: end < allItems.length,
    );
  }
}
