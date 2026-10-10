import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:k_budget/src/features/settings/presentation/data_settings_screen.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:k_budget/src/localization/app_localizations.dart';

import '../../../../helpers/display_locale.dart';

class _FakeDataSettings extends DataSettingsNotifier {
  _FakeDataSettings({this.serverUrl, this.succeeds = true, this.initialError});

  final String? serverUrl;
  final bool succeeds;
  final String? initialError;
  final changedUrls = <String>[];

  @override
  DataSettingsState build() =>
      DataSettingsState(serverUrl: serverUrl, error: initialError);

  @override
  Future<bool> changeServerUrl(String url) async {
    changedUrls.add(url);
    if (!succeeds) {
      state = state.copyWith(error: 'Serveur injoignable');
    }
    return succeeds;
  }
}

void main() {
  Widget buildApp({DataSettingsNotifier? notifier}) {
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
        dataSettingsNotifierProvider.overrideWith(
          () => notifier ?? DataSettingsNotifier(),
        ),
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

      expect(find.text('Serveur'), findsOneWidget);
      expect(find.text('Données'), findsNothing);
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

    testWidgets('should_showSavedSnackbarOnly_when_urlUnchanged', (tester) async {
      final fake = _FakeDataSettings(serverUrl: 'https://current.example.com');
      await tester.pumpWidget(buildApp(notifier: fake));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('URL enregistrée'), findsOneWidget);
      expect(find.text('Changer de serveur ?'), findsNothing);
      expect(fake.changedUrls, isEmpty);
    });

    testWidgets('should_notAskConfirmation_when_onlyTrailingSlashDiffers',
        (tester) async {
      final fake = _FakeDataSettings(serverUrl: 'https://current.example.com');
      await tester.pumpWidget(buildApp(notifier: fake));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'https://current.example.com/',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Changer de serveur ?'), findsNothing);
      expect(find.text('URL enregistrée'), findsOneWidget);
      expect(fake.changedUrls, isEmpty);
    });

    testWidgets('should_askConfirmation_when_urlChanged', (tester) async {
      final fake = _FakeDataSettings(serverUrl: 'https://current.example.com');
      await tester.pumpWidget(buildApp(notifier: fake));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://other.example.com');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Changer de serveur ?'), findsOneWidget);
      expect(
        find.text(
          'Vous serez déconnecté et devrez vous reconnecter sur le nouveau '
          'serveur. Vos données restent sur le serveur actuel.',
        ),
        findsOneWidget,
      );
      expect(fake.changedUrls, isEmpty);
    });

    testWidgets('should_notChangeServer_when_confirmationCancelled',
        (tester) async {
      final fake = _FakeDataSettings(serverUrl: 'https://current.example.com');
      await tester.pumpWidget(buildApp(notifier: fake));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://other.example.com');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Changer de serveur ?'), findsNothing);
      expect(fake.changedUrls, isEmpty);
    });

    testWidgets('should_changeServerWithTrimmedUrl_when_confirmed',
        (tester) async {
      final fake = _FakeDataSettings(serverUrl: 'https://current.example.com');
      await tester.pumpWidget(buildApp(notifier: fake));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '  https://other.example.com/api  ',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(fake.changedUrls, ['https://other.example.com/api']);
      expect(find.text('URL enregistrée'), findsNothing);
      expect(find.text('Serveur injoignable'), findsNothing);
    });

    testWidgets('should_showErrorUnderField_when_changeFails', (tester) async {
      final fake = _FakeDataSettings(
        serverUrl: 'https://current.example.com',
        succeeds: false,
      );
      await tester.pumpWidget(buildApp(notifier: fake));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://other.example.com');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(fake.changedUrls, ['https://other.example.com']);
      expect(find.text('Serveur injoignable'), findsOneWidget);
    });

    testWidgets('should_allowThreeLineError_when_fieldDisplayed',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.errorMaxLines, 3);
    });

    testWidgets('should_clearPreviousError_when_screenReopened',
        (tester) async {
      final fake = _FakeDataSettings(
        serverUrl: 'https://current.example.com',
        initialError: 'Serveur injoignable',
      );
      await tester.pumpWidget(buildApp(notifier: fake));
      await tester.pumpAndSettle();

      expect(find.text('Serveur injoignable'), findsNothing);
      expect(find.text('https://current.example.com'), findsOneWidget);
    });
  });
}
