import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/utils/currency_converter.dart';

void main() {
  final rates = [
    const ExchangeRate(
      id: '1',
      baseCurrency: Currency.eur,
      targetCurrency: Currency.xof,
      rate: 655.957,
    ),
    const ExchangeRate(
      id: '2',
      baseCurrency: Currency.eur,
      targetCurrency: Currency.usd,
      rate: 1.08,
    ),
  ];

  group('CurrencyConverter', () {
    test('should_convertAmount_when_rateExists', () {
      final result = CurrencyConverter.convert(
        amount: 100,
        fromCurrency: Currency.eur,
        toCurrency: Currency.xof,
        rates: rates,
      );
      expect(result, equals(65596.0)); // XOF has 0 decimal places
    });

    test('should_returnNull_when_noRate', () {
      final result = CurrencyConverter.convert(
        amount: 100,
        fromCurrency: Currency.eur,
        toCurrency: Currency.gbp,
        rates: rates,
      );
      expect(result, isNull);
    });

    test('should_roundToDecimalPlaces_when_converting', () {
      // XOF = 0 decimal places
      final xofResult = CurrencyConverter.convert(
        amount: 1,
        fromCurrency: Currency.eur,
        toCurrency: Currency.xof,
        rates: rates,
      );
      expect(xofResult, equals(656.0)); // 655.957 rounded to 0 decimals

      // EUR = 2 decimal places (inverse conversion)
      final eurResult = CurrencyConverter.convert(
        amount: 50000,
        fromCurrency: Currency.xof,
        toCurrency: Currency.eur,
        rates: rates,
      );
      expect(eurResult, isNotNull);
      // invertRate(655.957) arrondi à 6 décimales = 0.001524
      // 50000 * 0.001524 = 76.2 (arrondi à 2 décimales EUR)
      expect(eurResult, closeTo(76.2, 0.1));
    });

    test('should_invertRate_when_called', () {
      final inverted = CurrencyConverter.invertRate(2.0);
      expect(inverted, equals(0.5));
    });

    test('should_preservePrecision_when_invertHighRate', () {
      // 655.957 → 1/655.957 = 0.001524...
      final inverted = CurrencyConverter.invertRate(655.957);
      expect(inverted, closeTo(0.001524, 0.000001));
    });

    test('should_returnAmount_when_sameCurrency', () {
      final result = CurrencyConverter.convert(
        amount: 100,
        fromCurrency: Currency.eur,
        toCurrency: Currency.eur,
        rates: rates,
      );
      expect(result, equals(100.0));
    });

    test('should_useInverseRate_when_directNotFound', () {
      // XOF → EUR should use inverse of EUR → XOF
      final result = CurrencyConverter.convert(
        amount: 65596,
        fromCurrency: Currency.xof,
        toCurrency: Currency.eur,
        rates: rates,
      );
      expect(result, isNotNull);
      expect(result, closeTo(100.0, 0.1));
    });
  });
}
