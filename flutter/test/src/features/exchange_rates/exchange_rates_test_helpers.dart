import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';

import '../../../helpers/fixtures/test_fixtures.dart';

/// Taux EUR -> [target] de valeur [rate].
ExchangeRate rateOf(Currency target, double rate) => ExchangeRate(
  id: 'rate-${target.name}',
  baseCurrency: Currency.eur,
  targetCurrency: target,
  rate: rate,
);

/// Compte actif dans [currency].
Account accountIn(Currency currency, {bool actif = true}) =>
    TestFixtures.testAccount.copyWith(currency: currency, actif: actif);

/// Notifier de taux dont l'etat est fixe : aucun appel reseau.
class FakeExchangeRateNotifier extends ExchangeRateNotifier {
  /// Cree un notifier qui demarre sur [initial].
  FakeExchangeRateNotifier(this.initial, {this.upsertError});

  /// Etat initial.
  final ListState<ExchangeRate> initial;

  /// Erreur levee par [upsert] si renseignee.
  final Exception? upsertError;

  /// Taux enregistres via [upsert].
  final upserted = <(Currency, Currency, double)>[];

  /// Paires supprimees via [delete].
  final deleted = <(Currency, Currency)>[];

  @override
  ListState<ExchangeRate> build() => initial;

  @override
  Future<void> loadItems() async {}

  @override
  Future<void> upsert(
    Currency baseCurrency,
    Currency targetCurrency,
    double rate,
  ) async {
    if (upsertError != null) throw upsertError!;
    upserted.add((baseCurrency, targetCurrency, rate));
  }

  @override
  Future<void> delete(Currency baseCurrency, Currency targetCurrency) async {
    deleted.add((baseCurrency, targetCurrency));
  }
}

/// Notifier de devises dont l'etat est fixe : aucun appel reseau.
class FakeCurrencyConfigNotifier extends CurrencyConfigNotifier {
  /// Cree un notifier qui demarre sur [initial].
  FakeCurrencyConfigNotifier(this.initial);

  /// Devises initiales, la premiere etant la principale.
  final List<Currency> initial;

  /// Devises ajoutees via [addCurrency].
  final added = <Currency>[];

  /// Devises retirees via [removeCurrency].
  final removed = <Currency>[];

  @override
  List<Currency> build() => initial;

  @override
  Future<void> loadCurrencies() async {}

  @override
  Future<void> addCurrency(Currency currency) async => added.add(currency);

  @override
  Future<void> removeCurrency(Currency currency) async => removed.add(currency);
}

/// Notifier de comptes dont l'etat est fixe : aucun appel reseau.
class FakeAccountNotifier extends AccountNotifier {
  /// Cree un notifier qui demarre avec [accounts].
  FakeAccountNotifier(this.accounts);

  /// Comptes exposes.
  final List<Account> accounts;

  @override
  ListState<Account> build() => ListState(items: accounts);
}
