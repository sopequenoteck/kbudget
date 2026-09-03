// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/repositories/crud_repository.dart';

abstract class CategoryRepository extends CrudRepository<Category> {
  Stream<List<Category>> watchAll();
  Future<Category> getById(String id);
}
