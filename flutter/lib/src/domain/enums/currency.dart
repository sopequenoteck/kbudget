// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

enum Currency {
  eur(symbol: '€', displayName: 'Euro', decimalPlaces: 2),
  xof(symbol: 'CFA', displayName: 'Franc CFA (BCEAO)', decimalPlaces: 0),
  usd(symbol: r'$', displayName: 'Dollar américain', decimalPlaces: 2),
  gbp(symbol: '£', displayName: 'Livre sterling', decimalPlaces: 2),
  chf(symbol: 'CHF', displayName: 'Franc suisse', decimalPlaces: 2),
  cad(symbol: r'CA$', displayName: 'Dollar canadien', decimalPlaces: 2),
  mad(symbol: 'MAD', displayName: 'Dirham marocain', decimalPlaces: 2);

  const Currency({
    required this.symbol,
    required this.displayName,
    required this.decimalPlaces,
  });

  final String symbol;
  final String displayName;
  final int decimalPlaces;
}
