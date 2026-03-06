import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/repositories/exchange_rate_repository.dart';

final exchangeRateListProvider =
    NotifierProvider<ExchangeRateNotifier, ListState<ExchangeRate>>(
  ExchangeRateNotifier.new,
);

class ExchangeRateNotifier extends Notifier<ListState<ExchangeRate>> {
  late ExchangeRateRepository _repository;

  @override
  ListState<ExchangeRate> build() {
    _repository = ref.watch(exchangeRateRepositoryProvider);
    return const ListState();
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rates = await _repository.getAll();
      state = state.copyWith(items: rates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> upsert(
      Currency baseCurrency, Currency targetCurrency, double rate) async {
    try {
      final result =
          await _repository.upsert(baseCurrency, targetCurrency, rate);
      final items = [...state.items];
      final index = items.indexWhere(
        (r) =>
            r.baseCurrency == baseCurrency && r.targetCurrency == targetCurrency,
      );
      if (index >= 0) {
        items[index] = result;
      } else {
        items.add(result);
      }
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> delete(Currency baseCurrency, Currency targetCurrency) async {
    try {
      await _repository.delete(baseCurrency, targetCurrency);
      state = state.copyWith(
        items: state.items
            .where((r) => !(r.baseCurrency == baseCurrency &&
                r.targetCurrency == targetCurrency))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Helper to get rate for a specific currency pair
  double? getRateFor(Currency base, Currency target) {
    if (base == target) return 1.0;
    try {
      return state.items
          .firstWhere(
              (r) => r.baseCurrency == base && r.targetCurrency == target)
          .rate;
    } catch (_) {
      return null;
    }
  }
}
