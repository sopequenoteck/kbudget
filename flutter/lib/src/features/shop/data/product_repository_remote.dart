import 'package:k_budget/src/data/remote/data_sources/product_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/product_dtos.dart';
import 'package:k_budget/src/domain/models/product.dart';
import 'package:k_budget/src/domain/repositories/product_repository.dart';

class ProductRepositoryRemote implements ProductRepository {
  final ProductRemoteDataSource _dataSource;

  ProductRepositoryRemote(this._dataSource);

  @override
  Future<List<Product>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Future<Product> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Product> create(Product product) async {
    final request = _toRequest(product);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Product> update(Product product) async {
    final request = _toUpdateRequest(product);
    final response = await _dataSource.update(product.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  Product _toDomain(ProductResponse r) => Product(
        id: r.id,
        nom: r.nom,
        description: r.description,
        icone: r.icone,
        imageUrl: r.imageUrl,
        prixAchat: r.prixAchat,
        prixVente: r.prixVente,
        stock: r.stock,
        totalVendu: r.totalVendu,
        actif: r.actif,
        createdAt: r.createdAt != null ? DateTime.parse(r.createdAt!) : null,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
      );

  ProductRequest _toRequest(Product p) => ProductRequest(
        nom: p.nom,
        description: p.description,
        icone: p.icone,
        imageUrl: p.imageUrl,
        prixAchat: p.prixAchat,
        prixVente: p.prixVente,
        stock: p.stock,
      );

  ProductUpdateRequest _toUpdateRequest(Product p) => ProductUpdateRequest(
        nom: p.nom,
        description: p.description,
        icone: p.icone,
        imageUrl: p.imageUrl,
        prixAchat: p.prixAchat,
        prixVente: p.prixVente,
        stock: p.stock,
        actif: p.actif,
      );
}
