// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/repositories/crud_repository.dart';
import 'package:k_budget/src/features/common/application/crud_notifier.dart';

final categoryNotifierProvider =
    NotifierProvider<CategoryNotifier, ListState<Category>>(
  CategoryNotifier.new,
);

class CategoryNotifier extends CrudNotifier<Category> {
  @override
  CrudRepository<Category> get repo => ref.read(categoryRepositoryProvider);

  @override
  String itemId(Category item) => item.id;

  @override
  void sortItems(List<Category> items) =>
      items.sort((a, b) => a.nom.compareTo(b.nom));

  @override
  String get entityLabel => 'catégories';

  @override
  String? validateUpdate(Category item) {
    final existing = allItems.where((e) => e.id == item.id).firstOrNull;
    if (existing != null && existing.isSystem) {
      return 'Les catégories système ne peuvent pas être modifiées';
    }
    return null;
  }

  @override
  String? validateDelete(String id) {
    final existing = allItems.where((e) => e.id == id).firstOrNull;
    if (existing != null && existing.isSystem) {
      return 'Les catégories système ne peuvent pas être supprimées';
    }
    return null;
  }
}
