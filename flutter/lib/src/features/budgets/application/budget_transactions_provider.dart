// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

final budgetTransactionsProvider =
    FutureProvider.family<List<Transaction>, ({int month, int year})>(
  (ref, params) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getByMonth(params.month, params.year);
  },
);
