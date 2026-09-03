// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

abstract class ExchangeRateRepository {
  Future<List<ExchangeRate>> getAll();
  Future<ExchangeRate> upsert(Currency baseCurrency, Currency targetCurrency, double rate);
  Future<void> delete(Currency baseCurrency, Currency targetCurrency);
}
