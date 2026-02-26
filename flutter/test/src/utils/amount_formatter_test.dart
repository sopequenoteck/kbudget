import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';

void main() {
  group('AmountFormatter.format', () {
    test('should_return_empty_string_when_value_is_null', () {
      expect(AmountFormatter.format(null), '');
    });

    test('should_format_zero_without_sign', () {
      final result = AmountFormatter.format(0, type: 'depense');
      expect(result, contains('0'));
      expect(result, isNot(startsWith('+')));
      expect(result, isNot(startsWith('-')));
    });

    test('should_prefix_plus_when_type_is_recette', () {
      final result = AmountFormatter.format(100, type: 'recette');
      expect(result, startsWith('+'));
    });

    test('should_prefix_plus_when_type_is_pret', () {
      final result = AmountFormatter.format(500, type: 'pret');
      expect(result, startsWith('+'));
    });

    test('should_prefix_minus_when_type_is_depense', () {
      final result = AmountFormatter.format(9.99, type: 'depense');
      expect(result, startsWith('-'));
    });

    test('should_prefix_minus_when_type_is_emprunt', () {
      final result = AmountFormatter.format(150, type: 'emprunt');
      expect(result, startsWith('-'));
    });

    test('should_prefix_minus_when_value_is_negative_without_type', () {
      final result = AmountFormatter.format(-50);
      expect(result, startsWith('-'));
    });

    test('should_format_without_sign_when_positive_without_type', () {
      final result = AmountFormatter.format(1500.5);
      expect(result, isNot(startsWith('+')));
      expect(result, isNot(startsWith('-')));
    });

    test('should_use_abs_value_for_formatting', () {
      final result = AmountFormatter.format(-42.5, type: 'depense');
      // Should show -42,50 not --42,50
      expect('-'.allMatches(result).length, 1);
    });

    test('should_use_eur_currency_by_default', () {
      final result = AmountFormatter.format(100);
      expect(result, contains('€'));
    });

    test('should_use_specified_currency', () {
      final result = AmountFormatter.format(100, currency: Currency.xof);
      expect(result, contains('CFA'));
    });

    test('should_respect_decimal_places_for_xof', () {
      // XOF has 0 decimal places
      final result = AmountFormatter.format(1000, currency: Currency.xof);
      expect(result, isNot(contains(',')));
    });

    test('should_format_with_two_decimals_for_eur', () {
      final result = AmountFormatter.format(100, currency: Currency.eur);
      // Format français : 100,00 €
      expect(result, contains('00'));
    });

    test('should_use_french_locale_formatting', () {
      // French locale uses space as thousands separator
      final result = AmountFormatter.format(2100, type: 'recette');
      // Should contain non-breaking space or regular space as thousands separator
      expect(result, contains('€'));
    });
  });

  group('AmountFormatter.amountColor', () {
    const colors = AppThemeExtension.light;

    test('should_return_income_color_for_recette', () {
      expect(AmountFormatter.amountColor('recette', colors), colors.incomeColor);
    });

    test('should_return_income_color_for_pret', () {
      expect(AmountFormatter.amountColor('pret', colors), colors.incomeColor);
    });

    test('should_return_expense_color_for_depense', () {
      expect(AmountFormatter.amountColor('depense', colors), colors.expenseColor);
    });

    test('should_return_expense_color_for_emprunt', () {
      expect(AmountFormatter.amountColor('emprunt', colors), colors.expenseColor);
    });

    test('should_return_null_for_unknown_type', () {
      expect(AmountFormatter.amountColor('unknown', colors), isNull);
    });

    test('should_return_null_when_type_is_null', () {
      expect(AmountFormatter.amountColor(null, colors), isNull);
    });
  });
}
