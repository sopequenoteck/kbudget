// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

enum Currency {
  /// Euro.
  eur(symbol: '€', decimalPlaces: 2),
  /// Franc CFA (BCEAO).
  xof(symbol: 'CFA', decimalPlaces: 0),
  /// Dollar US.
  usd(symbol: r'$', decimalPlaces: 2),
  /// Livre sterling.
  gbp(symbol: '£', decimalPlaces: 2),
  /// Franc suisse.
  chf(symbol: 'CHF', decimalPlaces: 2),
  /// Dollar canadien.
  cad(symbol: r'CA$', decimalPlaces: 2),
  /// Dirham marocain.
  mad(symbol: 'MAD', decimalPlaces: 2);

  const Currency({
    required this.symbol,
    required this.decimalPlaces,
  });

  final String symbol;
  final int decimalPlaces;
}
