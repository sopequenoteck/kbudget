import 'package:k_budget/src/domain/models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAll();
  Future<Product> getById(String id);
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(String id);
}
