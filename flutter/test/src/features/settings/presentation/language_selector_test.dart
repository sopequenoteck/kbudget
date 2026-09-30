// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/features/settings/presentation/settings_hub_screen.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../application/feature_config_notifier_reorder_test.dart' as reorder;
import '../application/language_notifier_test.dart';

/// Device configuration that also stores the language.
class _Config extends reorder.MockAppConfigRepository {
  String? language;

  @override
  Future<String?> getLanguage() async => language;

  @override
  Future<void> setLanguage(String? language) async {
    this.language = language;
  }
}

class _FakeUserProfile extends UserProfileNotifier {
  @override
  Future<User> build() async => const User(id: 'u1', email: 'u@local.test');
}

void main() {
  late FakePreferenceDataSource remote;

  setUp(() {
    remote = FakePreferenceDataSource();
  });

  /// The settings screen inside an app whose locale follows
  /// [displayLocaleProvider], as `KBudgetApp` does.
  Future<void> pumpSettings(
    WidgetTester tester, {
    DataMode mode = DataMode.server,
  }) async {
    tester.view.physicalSize = const Size(2400, 12000);
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsHubScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...languageOverrides(config: _Config(), remote: remote, mode: mode),
          userProfileNotifierProvider.overrideWith(_FakeUserProfile.new),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: ref.watch(displayLocaleProvider),
            routerConfig: router,
            theme: app_theme.AppTheme.light,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tile(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(GestureDetector),
      );

  bool isSelected(WidgetTester tester, String label) =>
      find
          .descendant(
            of: tile(label).first,
            matching: find.byIcon(PhosphorIconsFill.checkCircle),
          )
          .evaluate()
          .isNotEmpty;

  group('Language selector', () {
    testWidgets('should_showThreeTiles_when_rendered', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.globe), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.translate), findsNWidgets(2));
    });

    testWidgets('should_selectAuto_when_preferenceIsNull', (tester) async {
      await pumpSettings(tester);

      final auto = find.ancestor(
        of: find.byIcon(PhosphorIconsRegular.globe),
        matching: find.byType(GestureDetector),
      );
      expect(
        find.descendant(
          of: auto.first,
          matching: find.byIcon(PhosphorIconsFill.checkCircle),
        ),
        findsOneWidget,
      );
      expect(isSelected(tester, 'English'), isFalse);
      expect(isSelected(tester, 'Français'), isFalse);
    });

    testWidgets('should_selectPreferenceTile_when_preferenceIsSet',
        (tester) async {
      remote.language = 'fr';

      await pumpSettings(tester);

      expect(isSelected(tester, 'Français'), isTrue);
      expect(isSelected(tester, 'English'), isFalse);
    });

    testWidgets('should_switchWithoutRestart_when_frenchSelected',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('Language'), findsOneWidget);

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(find.text('Langue'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Language'), findsNothing);
      expect(remote.updates.single.language, 'fr');
      expect(isSelected(tester, 'Français'), isTrue);
    });

    testWidgets('should_deleteLanguage_when_autoTapped', (tester) async {
      remote.language = 'fr';
      await pumpSettings(tester);
      expect(find.text('Langue'), findsOneWidget);

      await tester.tap(find.byIcon(PhosphorIconsRegular.globe));
      await tester.pumpAndSettle();

      expect(remote.clears, 1);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('should_restorePreviousTile_when_serverWriteFails',
        (tester) async {
      await pumpSettings(tester);
      remote.failWrites = true;

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(isSelected(tester, 'Français'), isFalse);
    });
  });
}
