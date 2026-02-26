import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_type_selector.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  Widget buildApp({
    AccountType selectedType = AccountType.courant,
    required ValueChanged<AccountType> onChanged,
    bool disabled = false,
  }) {
    return MaterialApp(
      theme: theme.AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AccountTypeSelector(
          selectedType: selectedType,
          onChanged: onChanged,
          disabled: disabled,
        ),
      ),
    );
  }

  group('AccountTypeSelector', () {
    testWidgets('should_showThreeTypes_when_rendered', (tester) async {
      await tester.pumpWidget(buildApp(onChanged: (_) {}));
      await tester.pumpAndSettle();

      expect(find.text('Courant'), findsOneWidget);
      expect(find.text('Épargne'), findsOneWidget);
    });

    testWidgets('should_highlightSelected_when_typeTapped', (tester) async {
      AccountType? selected;

      await tester.pumpWidget(buildApp(
        onChanged: (type) => selected = type,
      ));
      await tester.pumpAndSettle();

      // Tap Épargne card
      await tester.tap(find.text('Épargne'));
      await tester.pumpAndSettle();

      expect(selected, AccountType.epargne);
    });

    testWidgets('should_beDisabled_when_disabledTrue', (tester) async {
      AccountType? selected;

      await tester.pumpWidget(buildApp(
        onChanged: (type) => selected = type,
        disabled: true,
      ));
      await tester.pumpAndSettle();

      // Tap should not trigger callback
      await tester.tap(find.text('Courant'));
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
