import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/presentation/screens/category_list_screen.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_list_skeleton.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/mocks.mocks.dart';

void main() {
  late MockCategoryRepository mockRepo;

  const cat1 = Category(
    id: '1',
    nom: 'Alimentation',
    icone: '\u{1F34E}',
    couleur: '#22c55e',
    isSystem: false,
  );
  const cat2 = Category(
    id: '2',
    nom: 'Transport',
    icone: '\u{1F697}',
    couleur: '#3b82f6',
    isSystem: false,
  );
  const catSystem = Category(
    id: '3',
    nom: 'Abonnement',
    icone: '\u{1F501}',
    couleur: '#6366f1',
    isSystem: true,
  );

  setUp(() {
    mockRepo = MockCategoryRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CategoryListScreen(),
      ),
    );
  }

  group('CategoryListScreen', () {
    testWidgets('should_show_skeleton_when_loading', (tester) async {
      final completer = Completer<List<Category>>();
      when(mockRepo.getAll()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(CategoryListSkeleton), findsOneWidget);

      completer.complete([cat1]);
      await tester.pumpAndSettle();
    });

    testWidgets('should_show_error_with_retry_when_error', (tester) async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger les catégories'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should_show_empty_state_when_no_categories', (tester) async {
      when(mockRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucune catégorie'), findsOneWidget);
      expect(find.byIcon(Icons.label_outlined), findsOneWidget);
    });

    testWidgets('should_show_list_when_categories_exist', (tester) async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat1, cat2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Alimentation'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('should_hide_system_categories', (tester) async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat1, catSystem]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Alimentation'), findsOneWidget);
      expect(find.text('Abonnement'), findsNothing);
    });

    testWidgets('should_retry_load_when_retry_tapped', (tester) async {
      int callCount = 0;
      when(mockRepo.getAll()).thenAnswer((_) {
        callCount++;
        if (callCount == 1) throw Exception('Network error');
        return Future.value([cat1]);
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger les catégories'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Alimentation'), findsOneWidget);
    });
  });
}
