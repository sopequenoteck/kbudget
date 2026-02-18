import 'package:k_budget/src/data/remote/data_sources/debt_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/debt_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/repositories/debt_repository.dart';

class DebtRepositoryRemote implements DebtRepository {
  final DebtRemoteDataSource _dataSource;

  DebtRepositoryRemote(this._dataSource);

  @override
  Future<List<Debt>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Stream<List<Debt>> watchAll() async* {
    yield await getAll();
  }

  @override
  Future<Debt> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Debt> create(Debt debt) async {
    final request = _toRequest(debt);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Debt> update(Debt debt) async {
    final request = _toRequest(debt);
    final response = await _dataSource.update(debt.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  Debt _toDomain(DebtResponse r) => Debt(
        id: r.id,
        personne: r.personne,
        montant: r.montant,
        sens: DebtType.values.byName(r.sens.toLowerCase()),
        date: DateTime.parse(r.date),
        currency: Currency.values.byName(r.currency.toLowerCase()),
        rembourse: r.rembourse,
        categoryId: r.categoryId,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
      );

  DebtRequest _toRequest(Debt d) => DebtRequest(
        personne: d.personne,
        montant: d.montant,
        sens: d.sens.name.toUpperCase(),
        date: d.date.toIso8601String(),
        rembourse: d.rembourse,
        categoryId: d.categoryId,
      );
}
