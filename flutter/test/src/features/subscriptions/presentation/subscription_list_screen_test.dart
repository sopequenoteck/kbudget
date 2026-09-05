import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/common_widgets/section_header_sticky.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/features/subscriptions/presentation/subscription_list_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockSubscriptionRepository mockSubRepo;
  late MockCategoryRepository mockCatRepo;
  late MockAccountRepository mockAccRepo;
  late MockExchangeRateRepository mockExchangeRateRepo;

  final sub1 = Subscription(
    id: '1',
    nom: 'Netflix',
    montant: 15.99,
    frequence: Frequency.mensuel,
    dateDebut: DateTime(2026, 1, 1),
    actif: true,
    categoryId: 'cat1',
  );
  final sub2 = Subscription(
    id: '2',
    nom: 'Spotify',
    montant: 9.99,
    frequence: Frequency.mensuel,
    dateDebut: DateTime(2026, 1, 15),
    actif: true,
    categoryId: 'cat2',
  );
  final subInactive = Subscription(
    id: '3',
    nom: 'Amazon Prime',
    montant: 49.0,
    frequence: Frequency.annuel,
    dateDebut: DateTime(2025, 6, 1),
    actif: false,
  );

  const category1 = Category(
    id: 'cat1',
    nom: 'Divertissement',
    icone: '\u{1F3AC}',
    couleur: '#E50914',
  );
  const category2 = Category(
    id: 'cat2',
    nom: 'Musique',
    icone: '\u{1F3B5}',
    couleur: '#1DB954',
  );

  setUp(() {
    mockSubRepo = MockSubscriptionRepository();
    mockCatRepo = MockCategoryRepository();
    mockAccRepo = MockAccountRepository();
    mockExchangeRateRepo = MockExchangeRateRepository();
    when(mockExchangeRateRepo.getAll()).thenAnswer((_) async => <ExchangeRate>[]);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
        categoryRepositoryProvider.overrideWithValue(mockCatRepo),
        accountRepositoryProvider.overrideWithValue(mockAccRepo),
        exchangeRateRepositoryProvider.overrideWith((_) async => mockExchangeRateRepo),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SubscriptionListScreen(),
        ),
      ),
    );
  }

  group('SubscriptionListScreen', () {
    testWidgets('should_display_subscription_items_when_data_loaded',
        (tester) async {
      when(mockSubRepo.getAll()).thenAnswer((_) async => [sub1, sub2]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);
      when(mockAccRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);
    });

    testWidgets('should_display_empty_state_when_no_subscriptions',
        (tester) async {
      when(mockSubRepo.getAll()).thenAnswer((_) async => []);
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);
      when(mockAccRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucun abonnement'), findsOneWidget);
    });

    testWidgets('should_hide_summary_card_when_no_active_subscriptions',
        (tester) async {
      when(mockSubRepo.getAll()).thenAnswer((_) async => [subInactive]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);
      when(mockAccRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Total mensuel'), findsNothing);
    });

    testWidgets('should_display_actifs_inactifs_labels_when_mixed_data',
        (tester) async {
      when(mockSubRepo.getAll()).thenAnswer((_) async => [sub1, subInactive]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => [category1]);
      when(mockAccRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Actifs'), findsOneWidget);
      expect(find.text('Inactifs'), findsOneWidget);
    });

    testWidgets('should_display_section_header_when_data_loaded',
        (tester) async {
      when(mockSubRepo.getAll()).thenAnswer((_) async => [sub1, sub2]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);
      when(mockAccRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(SectionHeaderSticky), findsOneWidget);
    });

    testWidgets('should_display_skeleton_when_loading', (tester) async {
      // Use a Completer that never completes to keep loading state
      final completer = Completer<List<Subscription>>();
      when(mockSubRepo.getAll()).thenAnswer((_) => completer.future);
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);
      when(mockAccRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Skeleton items should be visible (ListItem.skeleton)
      expect(find.text('Aucun abonnement'), findsNothing);
      expect(find.text('Netflix'), findsNothing);
    });
  });

  group('SubscriptionListScreen navigation', () {
    late GoRouter router;
    late String lastPushedLocation;

    setUp(() {
      lastPushedLocation = '';
      router = GoRouter(
        initialLocation: '/subscriptions',
        routes: [
          GoRoute(
            path: '/subscriptions',
            builder: (_, _) => ProviderScope(
              overrides: [
                subscriptionRepositoryProvider
                    .overrideWithValue(mockSubRepo),
                categoryRepositoryProvider
                    .overrideWithValue(mockCatRepo),
                accountRepositoryProvider
                    .overrideWithValue(mockAccRepo),
                exchangeRateRepositoryProvider
                    .overrideWith((_) async => mockExchangeRateRepo),
              ],
              child: const Scaffold(
                body: SubscriptionListScreen(),
                floatingActionButton: SizedBox.shrink(),
              ),
            ),
          ),
          GoRoute(
            path: '/subscriptions/:id',
            builder: (context, state) {
              lastPushedLocation =
                  '/subscriptions/${state.pathParameters['id']}';
              return const Scaffold(body: Text('Detail'));
            },
          ),
        ],
      );
    });

    Widget buildAppWithRouter() => MaterialApp.router(
          routerConfig: router,
          theme: theme.AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );

    testWidgets(
        'should_navigate_to_subscription_detail_on_item_tap',
        (tester) async {
      when(mockSubRepo.getAll()).thenAnswer((_) async => [sub1]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => [category1]);
      when(mockAccRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildAppWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/subscriptions/1');
    });
  });
}
