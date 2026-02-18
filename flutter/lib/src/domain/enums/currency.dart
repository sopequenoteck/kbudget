enum Currency {
  eur(symbol: '€', name: 'Euro', decimalPlaces: 2),
  xof(symbol: 'CFA', name: 'Franc CFA (BCEAO)', decimalPlaces: 0),
  usd(symbol: r'$', name: 'Dollar américain', decimalPlaces: 2),
  gbp(symbol: '£', name: 'Livre sterling', decimalPlaces: 2),
  chf(symbol: 'CHF', name: 'Franc suisse', decimalPlaces: 2),
  cad(symbol: r'CA$', name: 'Dollar canadien', decimalPlaces: 2),
  mad(symbol: 'MAD', name: 'Dirham marocain', decimalPlaces: 2);

  const Currency({
    required this.symbol,
    required this.name,
    required this.decimalPlaces,
  });

  final String symbol;
  final String name;
  final int decimalPlaces;
}
