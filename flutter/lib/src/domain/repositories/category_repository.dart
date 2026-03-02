import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/repositories/crud_repository.dart';

abstract class CategoryRepository extends CrudRepository<Category> {
  Stream<List<Category>> watchAll();
  Future<Category> getById(String id);
}
