import 'package:k_budget/src/domain/models/product.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

abstract class ProductRepository {
  Future<List<Product>> getAll();
  Future<Product> getById(String id);
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(String id);
  Future<Product> sell(String id);
  Future<Product> restock(String id, int quantity);
  Future<List<Transaction>> getSales(String id);
}
