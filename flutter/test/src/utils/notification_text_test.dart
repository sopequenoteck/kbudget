// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/domain/enums/notification_type.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/notification_text.dart';

NotificationModel _notification(
  NotificationType? type,
  Map<String, String>? params,
) =>
    NotificationModel(
      id: 'n-1',
      type: type,
      title: 'Stored title',
      message: 'Stored message',
      createdAt: DateTime(2026, 9, 30),
      params: params,
    );

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    await initializeDateFormatting('en_GB');
  });

  ({String title, String message}) build(
    NotificationType? type,
    Map<String, String>? params, {
    AppLocalizations? l10n,
    String locale = 'fr_FR',
  }) =>
      buildNotificationText(_notification(type, params), l10n ?? fr, locale);

  String eur(double value, String locale) =>
      AmountFormatter.format(value, locale: locale, currency: Currency.eur);

  group('buildNotificationText', () {
    const debtParams = {
      'person': 'Alice',
      'amount': '150.00',
      'currency': 'EUR',
    };
    const recurringParams = {
      'label': 'Loyer',
      'amount': '800',
      'currency': 'EUR',
      'dueDate': '2026-10-01',
    };

    final cases = <(
      NotificationType,
      Map<String, String>,
      (String, String) Function(),
      (String, String) Function(),
    )>[
      (
        NotificationType.subscriptionDue,
        {'name': 'Netflix'},
        () => ('Abonnement Netflix', 'Netflix — échéance demain'),
        () => ('Subscription Netflix', 'Netflix is due tomorrow'),
      ),
      (
        NotificationType.debtDue,
        {'person': 'Alice'},
        () => ('Dette Alice', 'Dette envers Alice — échéance demain'),
        () => ('Debt with Alice', 'Debt with Alice is due tomorrow'),
      ),
      (
        NotificationType.debtReminder,
        debtParams,
        () => (
              'Rappel dette - Alice',
              'Rappel : dette envers Alice — ${eur(150, 'fr_FR')} restant',
            ),
        () => (
              'Debt reminder - Alice',
              'Reminder: ${eur(150, 'en_GB')} left on the debt with Alice',
            ),
      ),
      (
        NotificationType.budgetThreshold,
        {'category': 'Courses', 'percentage': '80'},
        () => (
              'Budget Courses : 80 %',
              'Vous avez atteint 80 % du budget Courses',
            ),
        () => (
              'Budget Courses: 80%',
              'You have reached 80% of the Courses budget',
            ),
      ),
      (
        NotificationType.budgetExceeded,
        {'category': 'Courses', 'percentage': '120'},
        () => (
              'Budget Courses dépassé !',
              'Vous avez dépassé le budget Courses (120 %)',
            ),
        () => (
              'Budget Courses exceeded',
              'You have exceeded the Courses budget (120%)',
            ),
      ),
      (
        NotificationType.recurringTransactionDue,
        recurringParams,
        () => (
              'Transaction récurrente Loyer',
              'Loyer ${eur(800, 'fr_FR')} — échéance le 1 octobre 2026',
            ),
        () => (
              'Recurring transaction Loyer',
              'Loyer ${eur(800, 'en_GB')} due on 1 October 2026',
            ),
      ),
    ];

    for (final (type, params, expectedFr, expectedEn) in cases) {
      test('should_translateInFrench_when_typeIs${type.name}', () {
        final text = build(type, params);
        expect((text.title, text.message), expectedFr());
      });

      test('should_translateInEnglish_when_typeIs${type.name}', () {
        final text = build(type, params, l10n: en, locale: 'en_GB');
        expect((text.title, text.message), expectedEn());
      });
    }

    void expectFallback(({String title, String message}) text) {
      expect(text.title, 'Stored title');
      expect(text.message, 'Stored message');
    }

    test('should_fallBack_when_paramsIsNull', () {
      expectFallback(build(NotificationType.subscriptionDue, null));
    });

    test('should_fallBack_when_typeIsUnknown', () {
      expectFallback(build(null, {'name': 'Netflix'}));
    });

    test('should_fallBack_when_requiredParamIsMissing', () {
      expectFallback(build(NotificationType.debtReminder, {'person': 'Alice'}));
    });

    test('should_fallBack_when_requiredParamIsEmpty', () {
      expectFallback(build(NotificationType.subscriptionDue, {'name': ''}));
    });

    test('should_fallBack_when_debtReminderHasNoCurrency', () {
      expectFallback(
        build(
          NotificationType.debtReminder,
          {'person': 'Alice', 'amount': '150.00'},
        ),
      );
    });

    test('should_formatAmount_when_currencyIsLowerCase', () {
      final text = build(
        NotificationType.debtReminder,
        {...debtParams, 'currency': 'eur'},
      );
      expect(text.message, contains(eur(150, 'fr_FR')));
    });

    test('should_keepRawAmountAndCode_when_currencyIsUnknown', () {
      final text = build(
        NotificationType.debtReminder,
        {...debtParams, 'currency': 'JPY'},
      );
      expect(
        text.message,
        'Rappel : dette envers Alice — 150.00 JPY restant',
      );
    });

    test('should_keepRawAmount_when_recurringHasNoCurrency', () {
      final text = build(
        NotificationType.recurringTransactionDue,
        {...recurringParams}..remove('currency'),
      );
      expect(text.message, 'Loyer 800 — échéance le 1 octobre 2026');
    });

    test('should_keepRawAmount_when_amountIsUnreadable', () {
      final text = build(
        NotificationType.debtReminder,
        {...debtParams, 'amount': 'n/a'},
      );
      expect(text.message, 'Rappel : dette envers Alice — n/a restant');
    });

    test('should_keepRawDate_when_dueDateIsUnreadable', () {
      final text = build(
        NotificationType.recurringTransactionDue,
        {...recurringParams, 'dueDate': 'soon'},
      );
      expect(text.message, endsWith('— échéance le soon'));
    });

    test('should_translateCategory_when_categoryIsSystem', () {
      final text = build(
        NotificationType.budgetExceeded,
        {
          'category': 'Subscription',
          'categorySystemKey': 'SUBSCRIPTION',
          'percentage': '120',
        },
      );
      expect(text.title, 'Budget Abonnement dépassé !');
    });

    test('should_keepCategoryName_when_categoryIsUserDefined', () {
      final text = build(
        NotificationType.budgetThreshold,
        {'category': 'Subscription', 'percentage': '80'},
        l10n: en,
        locale: 'en_GB',
      );
      expect(text.title, 'Budget Subscription: 80%');
    });
  });
}
