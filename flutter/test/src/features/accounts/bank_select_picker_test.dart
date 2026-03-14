import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/bank_select_picker.dart';
import 'package:k_budget/src/domain/models/bank.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  final testBanks = [
    const Bank(code: 'SG', name: 'Société Générale', country: 'FR', brandColor: '#e2001a'),
    const Bank(code: 'ECOBANK', name: 'Ecobank', country: 'TG', brandColor: '#003b71'),
    const Bank(code: 'WISE', name: 'Wise', country: null, brandColor: '#9fe870'),
  ];

  Widget buildApp({
    String? selectedBankCode,
    required ValueChanged<String> onChanged,
    required AsyncValue<List<Bank>> banks,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BankSelectPicker(
            selectedBankCode: selectedBankCode,
            onChanged: onChanged,
            banks: banks,
          ),
        ),
      ),
    );
  }

  group('BankSelectPicker', () {
    testWidgets('should_show_grouped_banks_when_opened', (tester) async {
      await tester.pumpWidget(buildApp(
        onChanged: (_) {},
        banks: AsyncValue.data(testBanks),
      ));
      await tester.pumpAndSettle();

      // Ouvrir le modal en tapant sur le trigger
      await tester.tap(find.text('Sélectionner une banque'));
      await tester.pumpAndSettle();

      expect(find.text('France'), findsOneWidget);
      expect(find.text('Afrique de l\'Ouest'), findsOneWidget);
      expect(find.text('International'), findsOneWidget);
    });

    testWidgets('should_filter_banks_when_searching', (tester) async {
      await tester.pumpWidget(buildApp(
        onChanged: (_) {},
        banks: AsyncValue.data(testBanks),
      ));
      await tester.pumpAndSettle();

      // Ouvrir le modal
      await tester.tap(find.text('Sélectionner une banque'));
      await tester.pumpAndSettle();

      // Saisir un terme de recherche
      await tester.enterText(find.byType(TextField), 'soc');
      await tester.pumpAndSettle();

      expect(find.text('Société Générale'), findsOneWidget);
      expect(find.text('Ecobank'), findsNothing);
      expect(find.text('Wise'), findsNothing);
    });

    testWidgets('should_always_show_other_option_when_filtering', (tester) async {
      await tester.pumpWidget(buildApp(
        onChanged: (_) {},
        banks: AsyncValue.data(testBanks),
      ));
      await tester.pumpAndSettle();

      // Ouvrir le modal
      await tester.tap(find.text('Sélectionner une banque'));
      await tester.pumpAndSettle();

      // Saisir un terme sans correspondance
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      // "Autre / Personnalisé" doit toujours être visible
      expect(find.text('Autre / Personnalisé'), findsOneWidget);
    });

    testWidgets('should_call_onChanged_when_bank_selected', (tester) async {
      String? capturedCode;

      await tester.pumpWidget(buildApp(
        onChanged: (code) => capturedCode = code,
        banks: AsyncValue.data(testBanks),
      ));
      await tester.pumpAndSettle();

      // Ouvrir le modal
      await tester.tap(find.text('Sélectionner une banque'));
      await tester.pumpAndSettle();

      // Taper sur Société Générale
      await tester.tap(find.text('Société Générale'));
      await tester.pumpAndSettle();

      expect(capturedCode, 'SG');
    });

    testWidgets('should_show_empty_message_when_no_results', (tester) async {
      await tester.pumpWidget(buildApp(
        onChanged: (_) {},
        banks: AsyncValue.data(testBanks),
      ));
      await tester.pumpAndSettle();

      // Ouvrir le modal
      await tester.tap(find.text('Sélectionner une banque'));
      await tester.pumpAndSettle();

      // Saisir un terme sans correspondance
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Aucune banque trouvée'), findsOneWidget);
    });
  });
}
