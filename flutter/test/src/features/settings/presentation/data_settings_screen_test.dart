import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:k_budget/src/features/settings/presentation/data_settings_screen.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:k_budget/src/localization/app_localizations.dart';

import '../../../../helpers/display_locale.dart';

void main() {
  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/data',
      routes: [
        GoRoute(
          path: '/data',
          builder: (context, state) => const DataSettingsScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        displayLocaleOverride(),
        dataSettingsNotifierProvider.overrideWith(() {
          final notifier = DataSettingsNotifier();
          return notifier;
        }),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
        theme: app_theme.AppTheme.light,
      ),
    );
  }

  group('DataSettingsScreen', () {
    testWidgets('should_notOfferDataSourceChoice_when_screenDisplayed',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Données'), findsOneWidget);
      expect(find.text('SOURCE DE DONNÉES'), findsNothing);
      expect(find.byType(SegmentedButton<Object>), findsNothing);
      expect(find.text('Local'), findsNothing);
    });

    testWidgets('should display URL field', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('URL DU SERVEUR'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should_showRequiredError_when_savingEmptyUrl', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text("L'URL du serveur est requise"), findsOneWidget);
      expect(find.text('URL enregistrée'), findsNothing);
    });

    testWidgets('should_showHttpsError_when_savingUrlWithInvalidScheme',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ftp://example.com');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text("L'URL doit commencer par https://"), findsOneWidget);
      expect(find.text('URL enregistrée'), findsNothing);
    });

    testWidgets('should display save button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('should_confirmSave_when_validUrlSaved', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://example.com/api');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('URL enregistrée'), findsOneWidget);
    });
  });
}
