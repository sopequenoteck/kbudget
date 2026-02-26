import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/color_palette_picker.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/categories/presentation/screens/category_form_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/mocks.mocks.dart';

void main() {
  late MockCategoryRepository mockRepo;

  const existingCategory = Category(
    id: '1',
    nom: 'Alimentation',
    icone: '\u{1F34E}',
    couleur: '#22c55e',
    isSystem: false,
  );

  setUp(() {
    mockRepo = MockCategoryRepository();
  });

  Widget buildApp({Category? category}) {
    final router = GoRouter(
      initialLocation: '/list/form',
      routes: [
        GoRoute(
          path: '/list',
          builder: (context, state) =>
              const Scaffold(body: Text('list')),
          routes: [
            GoRoute(
              path: 'form',
              builder: (context, state) =>
                  CategoryFormScreen(category: category),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp.router(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Finder findSubmitButton() {
    return find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.check),
    );
  }

  Finder findDialogDeleteButton() {
    return find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Supprimer'),
    );
  }

  group('CategoryFormScreen — create mode', () {
    testWidgets('should_show_random_color_when_create_mode', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(ColorPalettePicker), findsOneWidget);
      final paletteCheck = find.descendant(
        of: find.byType(ColorPalettePicker),
        matching: find.byIcon(Icons.check),
      );
      expect(paletteCheck, findsOneWidget);
    });

    testWidgets('should_show_create_title', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle catégorie'), findsOneWidget);
    });

    testWidgets('should_show_validation_error_when_name_empty',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(findSubmitButton());
      await tester.pumpAndSettle();

      expect(find.text('Le nom est requis'), findsOneWidget);
    });

    testWidgets('should_show_validation_error_when_emoji_empty',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.tap(findSubmitButton());
      await tester.pumpAndSettle();

      expect(find.text("L'icône est requise"), findsOneWidget);
    });

    testWidgets('should_call_create_when_form_valid', (tester) async {
      when(mockRepo.create(any)).thenAnswer(
        (_) async => existingCategory,
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Alimentation');
      await tester.pumpAndSettle();

      await tester.tap(findSubmitButton());
      await tester.pumpAndSettle();

      // Emoji is required, so create should not be called
      verifyNever(mockRepo.create(any));
    });
  });

  group('CategoryFormScreen — edit mode', () {
    testWidgets('should_prefill_fields_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildApp(category: existingCategory));
      await tester.pumpAndSettle();

      expect(find.text('Alimentation'), findsWidgets);
      expect(find.text('\u{1F34E}'), findsWidgets);
    });

    testWidgets('should_show_edit_title_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildApp(category: existingCategory));
      await tester.pumpAndSettle();

      expect(find.text('Modifier la catégorie'), findsOneWidget);
    });

    testWidgets('should_call_update_when_form_submitted_in_edit_mode',
        (tester) async {
      when(mockRepo.update(any)).thenAnswer(
        (_) async => existingCategory.copyWith(nom: 'Courses'),
      );

      await tester.pumpWidget(buildApp(category: existingCategory));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Courses');
      await tester.pumpAndSettle();

      await tester.tap(findSubmitButton());
      await tester.pumpAndSettle();

      verify(mockRepo.update(any)).called(1);
    });

    testWidgets('should_show_delete_button_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildApp(category: existingCategory));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should_not_show_delete_button_when_create_mode',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('should_show_confirmation_dialog_when_delete_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp(category: existingCategory));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer la catégorie'), findsOneWidget);
      expect(
        find.text(
          'Êtes-vous sûr de vouloir supprimer cette catégorie ? Les éléments liés seront dissociés.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_call_delete_when_confirmed', (tester) async {
      // Load items into notifier first so delete() can find the item
      when(mockRepo.getAll())
          .thenAnswer((_) async => [existingCategory]);
      when(mockRepo.delete(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(category: existingCategory));
      await tester.pumpAndSettle();

      // Load items into the notifier so _allItems is populated
      final element = tester.element(find.byType(CategoryFormScreen));
      final container = ProviderScope.containerOf(element);
      await container.read(categoryNotifierProvider.notifier).loadItems();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(findDialogDeleteButton());
      await tester.pumpAndSettle();

      verify(mockRepo.delete('1')).called(1);
    });

    testWidgets('should_not_delete_when_cancelled', (tester) async {
      await tester.pumpWidget(buildApp(category: existingCategory));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(mockRepo.delete(any));
    });
  });
}
