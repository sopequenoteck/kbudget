// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_state.dart';
import 'package:k_budget/src/features/onboarding/presentation/server_setup_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/display_locale.dart';
import '../../../../helpers/mocks.mocks.dart';

/// Etat de depart fixe : la verification reseau (`/api/meta`) est hors sujet,
/// seule la suite du parcours est testee.
class _PresetOnboardingNotifier extends OnboardingNotifier {
  _PresetOnboardingNotifier(this._initial);
  final OnboardingState _initial;

  @override
  OnboardingState build() => _initial;
}

void main() {
  const serverUrl = 'https://budget.example.com/api';

  late MockAppConfigRepository mockRepo;

  setUp(() {
    mockRepo = MockAppConfigRepository();
  });

  Widget buildApp({OnboardingState initial = const OnboardingState()}) {
    final router = GoRouter(
      initialLocation: RouteNames.onboarding,
      routes: [
        GoRoute(
          path: RouteNames.onboarding,
          builder: (context, state) => const ServerSetupScreen(),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        displayLocaleOverride(),
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
        onboardingNotifierProvider.overrideWith(
          () => _PresetOnboardingNotifier(initial),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    );
  }

  Finder confirmButton() => find.widgetWithText(ElevatedButton, 'Confirmer');

  group('ServerSetupScreen as onboarding entry', () {
    testWidgets('should_showServerUrlFormWithoutModeChoice_when_rendered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Configuration serveur'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Mode local'), findsNothing);
      expect(find.text('Mode serveur'), findsNothing);
    });

    testWidgets('should_disableConfirm_when_serverNotChecked', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(tester.widget<ElevatedButton>(confirmButton()).onPressed, isNull);
    });

    testWidgets('should_completeOnboardingAndOpenDashboard_when_confirmed', (
      WidgetTester tester,
    ) async {
      when(mockRepo.setServerUrl(serverUrl)).thenAnswer((_) async {});
      when(mockRepo.setOnboardingCompleted(true)).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildApp(
          initial: const OnboardingState(
            serverUrl: serverUrl,
            isServerReachable: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(confirmButton());
      await tester.pumpAndSettle();

      verify(mockRepo.setServerUrl(serverUrl)).called(1);
      verify(mockRepo.setOnboardingCompleted(true)).called(1);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('should_stayOnScreenAndShowError_when_saveFails', (
      WidgetTester tester,
    ) async {
      when(
        mockRepo.setServerUrl(serverUrl),
      ).thenThrow(Exception('Storage error'));

      await tester.pumpWidget(
        buildApp(
          initial: const OnboardingState(
            serverUrl: serverUrl,
            isServerReachable: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(confirmButton());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Configuration serveur'), findsOneWidget);
      expect(find.textContaining('Erreur'), findsOneWidget);
    });
  });
}
