import 'package:k_budget/src/data/remote/dtos/exchange_rate_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/repositories/exchange_rate_repository.dart';
import 'package:k_budget/src/features/exchange_rates/data/exchange_rate_remote_data_source.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final ExchangeRateRemoteDataSource _dataSource;

  ExchangeRateRepositoryImpl(this._dataSource);

  @override
  Future<List<ExchangeRate>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Future<ExchangeRate> upsert(
      Currency baseCurrency, Currency targetCurrency, double rate) async {
    final request = ExchangeRateRequest(
      baseCurrency: baseCurrency.name.toUpperCase(),
      targetCurrency: targetCurrency.name.toUpperCase(),
      rate: rate,
    );
    final response = await _dataSource.upsert(request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(Currency baseCurrency, Currency targetCurrency) {
    return _dataSource.delete(
      baseCurrency.name.toUpperCase(),
      targetCurrency.name.toUpperCase(),
    );
  }

  ExchangeRate _toDomain(ExchangeRateResponse r) => ExchangeRate(
        id: r.id,
        baseCurrency: Currency.values.byName(r.baseCurrency.toLowerCase()),
        targetCurrency: Currency.values.byName(r.targetCurrency.toLowerCase()),
        rate: r.rate,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
      );
}
