import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

abstract class ExchangeRateRepository {
  Future<List<ExchangeRate>> getAll();
  Future<ExchangeRate> upsert(Currency baseCurrency, Currency targetCurrency, double rate);
  Future<void> delete(Currency baseCurrency, Currency targetCurrency);
}
