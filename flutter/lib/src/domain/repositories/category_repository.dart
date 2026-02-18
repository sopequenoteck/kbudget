import 'package:k_budget/src/domain/models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Stream<List<Category>> watchAll();
  Future<Category> getById(String id);
  Future<Category> create(Category category);
  Future<Category> update(Category category);
  Future<void> delete(String id);
}
