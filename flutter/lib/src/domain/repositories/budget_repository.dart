// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/budget_history.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getAll({bool includeInactive = false});
  Future<Budget> getById(String id);
  Future<Budget> create(Budget budget);
  Future<Budget> update(Budget budget);
  Future<void> delete(String id);
  Future<BudgetOverview> getOverview();
  Future<BudgetHistory> getHistory(String month);
}
