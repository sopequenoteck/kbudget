import 'package:k_budget/src/data/remote/data_sources/product_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/product_dtos.dart';
import 'package:k_budget/src/data/remote/dtos/transaction_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/product.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/domain/repositories/product_repository.dart';
import 'package:k_budget/src/utils/enum_utils.dart';

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

  @override
  Future<Product> sell(String id) async {
    final response = await _dataSource.sell(id);
    return _toDomain(response);
  }

  @override
  Future<Product> restock(String id, int quantity) async {
    final request = RestockRequest(quantity: quantity);
    final response = await _dataSource.restock(id, request);
    return _toDomain(response);
  }

  @override
  Future<List<Transaction>> getSales(String id) async {
    final responses = await _dataSource.getSales(id);
    return responses.map(_transactionToDomain).toList();
  }

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

  Transaction _transactionToDomain(TransactionResponse r) => Transaction(
        id: r.id,
        montant: r.montant,
        libelle: r.libelle,
        type: TransactionType.values.byNameOrDefault(r.type.toLowerCase(), TransactionType.depense),
        date: DateTime.parse(r.date),
        note: r.note,
        transferId: r.transferId,
        categoryId: r.categoryId,
        accountId: r.accountId,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
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
