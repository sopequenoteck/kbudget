// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/data/local/daos/category_dao.dart';
import 'package:k_budget/src/data/local/mappers.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/repositories/category_repository.dart';

class CategoryRepositoryLocal implements CategoryRepository {
  final CategoryDao _dao;

  CategoryRepositoryLocal(this._dao);

  @override
  Future<List<Category>> getAll() async {
    final rows = await _dao.getAllCategories();
    return rows.map(categoryFromDb).toList();
  }

  @override
  Stream<List<Category>> watchAll() {
    return _dao.watchAllCategories().map(
          (rows) => rows.map(categoryFromDb).toList(),
        );
  }

  @override
  Future<Category> getById(String id) async {
    final row = await _dao.getCategoryById(id);
    return categoryFromDb(row);
  }

  @override
  Future<Category> create(Category category) async {
    await _dao.insertCategory(categoryToDb(category));
    return category;
  }

  @override
  Future<Category> update(Category category) async {
    await _dao.updateCategory(categoryToDb(category));
    return category;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteCategory(id);
  }
}
