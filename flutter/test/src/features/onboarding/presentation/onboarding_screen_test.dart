import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAppConfigRepository mockRepo;

  setUp(() {
    mockRepo = MockAppConfigRepository();
  });

  Widget buildApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
        ...overrides,
      ],
      child: const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
  }

  Widget buildAppWithRouter({List<Override> overrides = const []}) {
    final router = GoRouter(
      initialLocation: RouteNames.onboarding,
      routes: [
        GoRoute(
          path: RouteNames.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
        ...overrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('OnboardingScreen', () {
    testWidgets('should_display_two_mode_cards_when_rendered',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Mode local'), findsOneWidget);
      expect(find.text('Mode serveur'), findsOneWidget);
      expect(find.text('Bienvenue sur K-Budget'), findsOneWidget);
      expect(find.text('Choisissez votre mode de données'), findsOneWidget);
    });

    testWidgets('should_display_mode_descriptions_when_rendered',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());

      expect(
          find.text('Vos données restent sur cet appareil'), findsOneWidget);
      expect(find.text('Synchronisez avec votre serveur K-Budget'),
          findsOneWidget);
    });

    testWidgets('should_have_disabled_confirm_button_when_no_mode_selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirmer'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should_enable_confirm_button_when_mode_selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Mode local'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirmer'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
        'should_complete_onboarding_when_local_mode_confirmed',
        (WidgetTester tester) async {
      when(mockRepo.setDataMode(DataMode.local)).thenAnswer((_) async {});
      when(mockRepo.setOnboardingCompleted(true)).thenAnswer((_) async {});
      when(mockRepo.getConfig()).thenAnswer((_) async => const AppConfig(
            dataMode: DataMode.local,
            onboardingCompleted: true,
          ));

      await tester.pumpWidget(buildAppWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mode local'));
      await tester.pump();

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      verify(mockRepo.setDataMode(DataMode.local)).called(1);
      verify(mockRepo.setOnboardingCompleted(true)).called(1);
      // Should navigate to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets(
        'should_navigate_to_server_setup_when_server_mode_confirmed',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Mode serveur'));
      await tester.pump();

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      // ServerSetupScreen should be pushed
      expect(find.text('Configuration serveur'), findsOneWidget);
      expect(find.text('URL du serveur'), findsOneWidget);
    });

    testWidgets('should_show_check_icon_when_mode_selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Mode local'));
      await tester.pump();

      expect(
        find.byIcon(PhosphorIconsFill.checkCircle),
        findsOneWidget,
      );
    });
  });
}
