import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/settings/presentation/settings_hub_screen.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_list_state.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

class _FakeUserProfile extends UserProfileNotifier {
  _FakeUserProfile({required this.isAdmin});
  final bool isAdmin;

  @override
  Future<User> build() async =>
      User(id: 'u1', email: 'admin@local.test', isAdmin: isAdmin);
}

class _FakeDataSettings extends DataSettingsNotifier {
  _FakeDataSettings(this.serverUrl);
  final String? serverUrl;

  @override
  DataSettingsState build() =>
      DataSettingsState(serverUrl: serverUrl);
}

class _FakeFeatureConfig extends FeatureConfigNotifier {
  final toggled = <Feature>[];

  @override
  FeatureConfigState build() => const FeatureConfigState();

  @override
  Future<void> toggleFeature(Feature feature) async => toggled.add(feature);
}

class _FakeSubscriptions extends SubscriptionNotifier {
  @override
  SubscriptionListState build() => SubscriptionListState(
        items: [
          Subscription(
            id: 's1',
            nom: 'Netflix',
            montant: 10,
            frequence: Frequency.mensuel,
            dateDebut: DateTime(2026),
          ),
        ],
      );
}

void main() {
  late GoRouter router;
  late String lastPushedLocation;

  setUp(() {
    lastPushedLocation = '';
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsHubScreen(),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) {
                lastPushedLocation = '/settings/profile';
                return const Scaffold(body: Text('Profile'));
              },
            ),
            GoRoute(
              path: 'accounts',
              builder: (context, state) {
                lastPushedLocation = '/settings/accounts';
                return const Scaffold(body: Text('Accounts'));
              },
            ),
            GoRoute(
              path: 'categories',
              builder: (context, state) {
                lastPushedLocation = '/settings/categories';
                return const Scaffold(body: Text('Categories'));
              },
            ),
            GoRoute(
              path: 'data',
              builder: (context, state) {
                lastPushedLocation = '/settings/data';
                return const Scaffold(body: Text('Data'));
              },
            ),
          ],
        ),
      ],
    );
  });

  Widget buildApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
        theme: app_theme.AppTheme.light,
      ),
    );
  }

  group('SettingsHubScreen', () {
    testWidgets('should_display_management_items_when_rendered',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Items visibles sans scroll dans la section Gestion
      expect(find.text('Mon compte'), findsOneWidget);
      expect(find.text('Comptes & Devises'), findsOneWidget);
      expect(find.text('Catégories'), findsOneWidget);
    });

    testWidgets('should_display_section_labels_when_rendered', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Sections visibles
      expect(find.text('GESTION'), findsOneWidget);
      expect(find.text('APPARENCE'), findsOneWidget);
    });

    testWidgets('should_display_Parametres_in_AppBar_when_rendered',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgets('should_navigate_to_settings_accounts_when_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comptes & Devises'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/accounts');
    });

    testWidgets('should_navigate_to_settings_profile_when_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mon compte'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/profile');
    });

    testWidgets('should_navigate_to_settings_categories_when_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Catégories'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/categories');
    });

    Future<void> pumpTall(WidgetTester tester, Widget app) async {
      // Surface haute : toutes les sections du hub sont construites
      tester.view.physicalSize = const Size(2400, 12000);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    }

    testWidgets('should_showAdministrationSection_when_userIsAdmin',
        (tester) async {
      await pumpTall(
        tester,
        buildApp(overrides: [
          userProfileNotifierProvider
              .overrideWith(() => _FakeUserProfile(isAdmin: true)),
        ]),
      );

      expect(find.text('ADMINISTRATION'), findsOneWidget);
      expect(find.text('Utilisateurs'), findsOneWidget);
      expect(find.text('Invitations et gestion des accès'), findsOneWidget);
    });

    testWidgets('should_showServerSection_when_rendered', (tester) async {
      await pumpTall(tester, buildApp());

      expect(find.text('SERVEUR'), findsOneWidget);
      expect(find.text('Serveur'), findsOneWidget);
      expect(find.text('URL de votre instance'), findsOneWidget);
      expect(find.text('Comptes & Devises'), findsOneWidget);
    });

    testWidgets('should_navigate_to_settings_data_when_serverRowTapped',
        (tester) async {
      await pumpTall(tester, buildApp());

      await tester.tap(find.text('Serveur'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/settings/data');
    });

    testWidgets('should_showOfflineFooter_when_serverUrlMissing',
        (tester) async {
      await pumpTall(
        tester,
        buildApp(overrides: [
          dataSettingsNotifierProvider
              .overrideWith(() => _FakeDataSettings(null)),
        ]),
      );

      expect(find.textContaining(' · Hors ligne'), findsOneWidget);
    });

    testWidgets('should_showCheckingFooter_when_healthCheckPending',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 12000);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        buildApp(overrides: [
          dataSettingsNotifierProvider
              .overrideWith(() => _FakeDataSettings('https://k.test/api')),
        ]),
      );
      await tester.pump();

      expect(find.textContaining(' · Vérification…'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('should_confirmBeforeDisabling_when_featureHasData',
        (tester) async {
      final featureConfig = _FakeFeatureConfig();
      await pumpTall(
        tester,
        buildApp(overrides: [
          featureConfigNotifierProvider.overrideWith(() => featureConfig),
          subscriptionNotifierProvider.overrideWith(_FakeSubscriptions.new),
        ]),
      );

      final subscriptionsTile = find.ancestor(
        of: find.text('Abonnements'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(of: subscriptionsTile, matching: find.byType(Switch)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Désactiver Abonnements ?'), findsOneWidget);
      expect(
        find.text('Vos données seront masquées mais pas supprimées.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Désactiver'));
      await tester.pumpAndSettle();

      expect(featureConfig.toggled, [Feature.subscriptions]);
    });

    testWidgets('should_showLocalizedPreferences_when_rendered',
        (tester) async {
      await pumpTall(tester, buildApp());

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Dettes'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Petit'), findsOneWidget);
      expect(find.text('Grand'), findsOneWidget);
      expect(find.text('Échéance abonnement'), findsOneWidget);
      expect(find.text('Budget dépassé'), findsOneWidget);
      expect(find.text('FUSEAU HORAIRE'), findsOneWidget);
      expect(find.text('Pour le calcul des rappels J-1'), findsOneWidget);
    });
  });
}
