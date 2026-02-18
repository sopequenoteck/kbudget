import 'package:k_budget/src/data/remote/data_sources/category_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/category_dtos.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/repositories/category_repository.dart';

class CategoryRepositoryRemote implements CategoryRepository {
  final CategoryRemoteDataSource _dataSource;

  CategoryRepositoryRemote(this._dataSource);

  @override
  Future<List<Category>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Stream<List<Category>> watchAll() async* {
    yield await getAll();
  }

  @override
  Future<Category> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Category> create(Category category) async {
    final request = _toRequest(category);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Category> update(Category category) async {
    final request = _toRequest(category);
    final response = await _dataSource.update(category.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  Category _toDomain(CategoryResponse r) => Category(
        id: r.id,
        nom: r.nom,
        icone: r.icone,
        couleur: r.couleur,
        isSystem: r.isSystem,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
      );

  CategoryRequest _toRequest(Category c) => CategoryRequest(
        nom: c.nom,
        icone: c.icone,
        couleur: c.couleur,
      );
}
