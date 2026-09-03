// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/repositories/account_repository.dart';
import 'package:k_budget/src/domain/repositories/crud_repository.dart';
import 'package:k_budget/src/features/common/application/crud_notifier.dart';

final accountNotifierProvider =
    NotifierProvider<AccountNotifier, ListState<Account>>(
  AccountNotifier.new,
);

class AccountNotifier extends CrudNotifier<Account> {
  @override
  CrudRepository<Account> get repo => ref.read(accountRepositoryProvider);

  AccountRepository get _typedRepo => ref.read(accountRepositoryProvider);

  @override
  String itemId(Account item) => item.id;

  @override
  void sortItems(List<Account> items) =>
      items.sort((a, b) => a.nom.compareTo(b.nom));

  @override
  String get entityLabel => 'comptes';

  Future<void> setDefault(String id) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final updated = await _typedRepo.setDefault(id);
      for (var i = 0; i < allItems.length; i++) {
        if (allItems[i].id == id) {
          allItems[i] = updated;
        } else if (allItems[i].isDefault) {
          allItems[i] = allItems[i].copyWith(isDefault: false);
        }
      }
      refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors du changement de compte par défaut: $e',
      );
    }
  }

  Future<void> adjustBalance(String id, double newBalance) async {
    state = state.copyWith(
      mutatingIds: {...state.mutatingIds, id},
      error: null,
    );
    try {
      final updated = await _typedRepo.adjustBalance(id, newBalance);
      final index = allItems.indexWhere((e) => e.id == id);
      if (index != -1) allItems[index] = updated;
      refreshPage();
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        mutatingIds: {...state.mutatingIds}..remove(id),
        error: 'Erreur lors de l\'ajustement du solde: $e',
      );
    }
  }
}
