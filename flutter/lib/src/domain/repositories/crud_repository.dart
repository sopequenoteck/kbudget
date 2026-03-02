/// Interface CRUD de base pour les repositories.
abstract class CrudRepository<T> {
  Future<List<T>> getAll();
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> delete(String id);
}
