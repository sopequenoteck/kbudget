// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';

class CurrencyConverter {
  CurrencyConverter._();

  /// Fixed parity rates (immutable monetary agreements)
  static const Map<(Currency, Currency), double> fixedParityRates = {
    (Currency.eur, Currency.xof): 655.957,
  };

  /// Convert an amount from one currency to another.
  /// Returns null if no rate is available.
  static double? convert({
    required double amount,
    required Currency fromCurrency,
    required Currency toCurrency,
    required List<ExchangeRate> rates,
  }) {
    if (fromCurrency == toCurrency) return amount;

    final rate = _findRate(fromCurrency, toCurrency, rates);
    if (rate == null) return null;

    final converted = amount * rate;
    return _roundToDecimalPlaces(converted, toCurrency.decimalPlaces);
  }

  /// Invert a rate (1/rate), rounded to 6 decimal places.
  static double invertRate(double rate) {
    if (rate == 0) return 0;
    final inverted = 1.0 / rate;
    return _roundToDecimalPlaces(inverted, 6);
  }

  /// Find rate from base to target, checking direct and inverse.
  static double? _findRate(
    Currency from,
    Currency to,
    List<ExchangeRate> rates,
  ) {
    // Direct rate
    for (final r in rates) {
      if (r.baseCurrency == from && r.targetCurrency == to) return r.rate;
    }
    // Inverse rate
    for (final r in rates) {
      if (r.baseCurrency == to && r.targetCurrency == from) {
        return invertRate(r.rate);
      }
    }
    return null;
  }

  /// Round to N decimal places.
  static double _roundToDecimalPlaces(double value, int places) {
    if (places <= 0) return value.roundToDouble();
    final factor = _pow10(places);
    return (value * factor).roundToDouble() / factor;
  }

  static double _pow10(int n) {
    double result = 1;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}
