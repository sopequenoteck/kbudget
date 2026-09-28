import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/localization/app_localizations_fr.dart';
import 'package:k_budget/src/utils/form_validators.dart';

void main() {
  final l10n = AppLocalizationsFr();

  group('FormValidators.requiredText', () {
    for (final (label, value, expected) in [
      ('null', null, l10n.commonValidationRequired),
      ('empty', '', l10n.commonValidationRequired),
      ('blank', '   ', l10n.commonValidationRequired),
      ('over_max_length', 'a' * 11, l10n.commonValidationMaxLength(10)),
      ('at_max_length_with_spaces', ' ${'a' * 10} ', null),
      ('filled', '  Courses  ', null),
    ]) {
      test('should_return_expected_message_when_value_is_$label', () {
        expect(
          FormValidators.requiredText(value, l10n, maxLength: 10),
          expected,
        );
      });
    }
  });

  group('FormValidators.positiveAmount', () {
    for (final (label, value, expected) in [
      ('null', null, l10n.commonValidationRequired),
      ('empty', '', l10n.commonValidationRequired),
      ('blank', '  ', l10n.commonValidationRequired),
      ('not_a_number', 'abc', l10n.commonValidationRequired),
      ('zero', '0', l10n.commonValidationAmountPositive),
      ('negative', '-5', l10n.commonValidationAmountPositive),
      ('decimal_comma', '12,50', null),
      ('decimal_point_with_spaces', ' 3.2 ', null),
    ]) {
      test('should_return_expected_message_when_value_is_$label', () {
        expect(FormValidators.positiveAmount(value, l10n), expected);
      });
    }
  });

  group('FormValidators.email', () {
    for (final (label, value, expected) in [
      ('null', null, l10n.authFormEmailRequired),
      ('empty', '', l10n.authFormEmailRequired),
      ('blank', '  ', l10n.authFormEmailRequired),
      ('without_at_sign', 'alex', l10n.authFormEmailInvalid),
      ('valid', 'alex@example.com', null),
    ]) {
      test('should_return_expected_message_when_value_is_$label', () {
        expect(FormValidators.email(value, l10n), expected);
      });
    }
  });

  group('FormValidators.displayName', () {
    for (final (label, value, expected) in [
      ('null', null, l10n.authFormDisplayNameRequired),
      ('blank', '  ', l10n.authFormDisplayNameRequired),
      ('over_100_chars', 'a' * 101, l10n.authFormDisplayNameRequired),
      ('at_100_chars_with_spaces', ' ${'a' * 100} ', null),
      ('filled', 'Alex Morgan', null),
    ]) {
      test('should_return_expected_message_when_value_is_$label', () {
        expect(FormValidators.displayName(value, l10n), expected);
      });
    }
  });
}
