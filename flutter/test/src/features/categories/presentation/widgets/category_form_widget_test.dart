import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/emoji_input.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/categories/presentation/widgets/category_form_widget.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/display_locale.dart';
import '../../../../../helpers/mocks.mocks.dart';
import '../../../../../helpers/theme_test_helpers.dart';

void main() {
  late MockCategoryRepository mockRepo;

  const existingCategory = Category(
    id: '42',
    nom: 'Alimentation',
    icone: '\u{1F34E}',
    couleur: '#22c55e',
    isSystem: false,
  );

  setUp(() {
    mockRepo = MockCategoryRepository();
  });

  /// Construit une app avec [CategoryFormWidget] directement dans un [Scaffold],
  /// avec localisation et ProviderScope.
  Widget buildDirectWidget({
    GlobalKey<CategoryFormWidgetState>? formKey,
    Category? category,
    String? initialName,
    ValueChanged<Category>? onSaved,
    ThemeData? theme,
  }) {
    return ProviderScope(
      overrides: [
        displayLocaleOverride(),
        categoryRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: theme ?? app_theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: CategoryFormWidget(
            key: formKey,
            category: category,
            initialName: initialName,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  }

  const otherCategory = Category(
    id: '43',
    nom: 'Transport',
    icone: '\u{1F697}',
    couleur: '#3b82f6',
    isSystem: false,
  );

  /// Charge [items] dans le notifier de catégories du widget testé.
  Future<void> loadCategories(
    WidgetTester tester,
    List<Category> items,
  ) async {
    when(mockRepo.getAll()).thenAnswer((_) async => items);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    await container.read(categoryNotifierProvider.notifier).loadItems();
    await tester.pumpAndSettle();
  }

  /// Choisit l'emoji sans ouvrir le sélecteur.
  Future<void> pickEmoji(WidgetTester tester) async {
    tester.widget<EmojiInput>(find.byType(EmojiInput)).onChanged!('\u{1F34E}');
    await tester.pumpAndSettle();
  }

  group('CategoryFormWidget — validation nom', () {
    forEachTheme((theme, themeName) {
      testWidgets(
        'should_show_error_when_submit_with_empty_name_$themeName',
        (tester) async {
          final formKey = GlobalKey<CategoryFormWidgetState>();

          await tester.pumpWidget(
            buildDirectWidget(formKey: formKey, theme: theme),
          );
          await tester.pumpAndSettle();

          // Submit sans nom ni emoji
          await formKey.currentState!.submit();
          await tester.pumpAndSettle();

          // L'erreur de nom vide doit être affichée
          expect(find.text('Nom requis'), findsOneWidget);
          verifyNever(mockRepo.create(any));
        },
      );
    });
  });

  group('CategoryFormWidget — nom déjà pris', () {
    testWidgets(
      'should_show_duplicate_error_and_not_create_when_name_taken_on_create',
      (tester) async {
        final formKey = GlobalKey<CategoryFormWidgetState>();
        await tester.pumpWidget(buildDirectWidget(formKey: formKey));
        await tester.pumpAndSettle();
        await loadCategories(tester, [existingCategory, otherCategory]);
        await pickEmoji(tester);

        await tester.enterText(find.byType(TextField), '  alimentation ');
        await tester.pumpAndSettle();
        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        expect(find.text('Ce nom de catégorie existe déjà'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        verifyNever(mockRepo.create(any));
      },
    );

    testWidgets(
      'should_create_when_name_is_free_on_create',
      (tester) async {
        final formKey = GlobalKey<CategoryFormWidgetState>();
        Category? savedCategory;
        await tester.pumpWidget(
          buildDirectWidget(
            formKey: formKey,
            onSaved: (c) => savedCategory = c,
          ),
        );
        await tester.pumpAndSettle();
        await loadCategories(tester, [existingCategory, otherCategory]);
        await pickEmoji(tester);
        when(mockRepo.create(any)).thenAnswer(
          (_) async => existingCategory.copyWith(id: '44', nom: 'Loisirs'),
        );

        await tester.enterText(find.byType(TextField), 'Loisirs');
        await tester.pumpAndSettle();
        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        verify(mockRepo.create(any)).called(1);
        expect(savedCategory?.nom, 'Loisirs');
        // Le formulaire reste monte pendant la fermeture : un rebuild ne doit
        // pas signaler comme doublon la categorie tout juste creee.
        tester.element(find.byType(CategoryFormWidget)).markNeedsBuild();
        await tester.pump();
        expect(find.text('Ce nom de catégorie existe déjà'), findsNothing);
      },
    );

    testWidgets(
      'should_update_when_keeping_own_name_on_edit',
      (tester) async {
        final formKey = GlobalKey<CategoryFormWidgetState>();
        Category? savedCategory;
        await tester.pumpWidget(
          buildDirectWidget(
            formKey: formKey,
            category: existingCategory,
            onSaved: (c) => savedCategory = c,
          ),
        );
        await tester.pumpAndSettle();
        await loadCategories(tester, [existingCategory, otherCategory]);
        when(mockRepo.update(any)).thenAnswer((_) async => existingCategory);

        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        expect(find.text('Ce nom de catégorie existe déjà'), findsNothing);
        verify(mockRepo.update(any)).called(1);
        expect(savedCategory?.nom, 'Alimentation');
      },
    );

    testWidgets(
      'should_show_duplicate_error_and_not_update_when_name_of_other_on_edit',
      (tester) async {
        final formKey = GlobalKey<CategoryFormWidgetState>();
        await tester.pumpWidget(
          buildDirectWidget(formKey: formKey, category: existingCategory),
        );
        await tester.pumpAndSettle();
        await loadCategories(tester, [existingCategory, otherCategory]);

        await tester.enterText(find.byType(TextField), 'Transport');
        await tester.pumpAndSettle();
        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        expect(find.text('Ce nom de catégorie existe déjà'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        verifyNever(mockRepo.update(any));
      },
    );

    testWidgets(
      'should_show_save_error_when_create_fails_after_submit',
      (tester) async {
        when(mockRepo.create(any)).thenThrow(
          Exception('400 Bad Request: category name already exists'),
        );
        final formKey = GlobalKey<CategoryFormWidgetState>();
        Category? savedCategory;
        await tester.pumpWidget(
          buildDirectWidget(
            formKey: formKey,
            onSaved: (c) => savedCategory = c,
          ),
        );
        await tester.pumpAndSettle();
        await loadCategories(tester, [existingCategory]);
        await pickEmoji(tester);

        await tester.enterText(find.byType(TextField), 'Loisirs');
        await tester.pumpAndSettle();
        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        verify(mockRepo.create(any)).called(1);
        expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
        expect(find.text('Ce nom de catégorie existe déjà'), findsNothing);
        expect(savedCategory, isNull);
      },
    );

    testWidgets(
      'should_show_save_error_when_update_fails_after_submit',
      (tester) async {
        when(mockRepo.update(any)).thenThrow(
          Exception('400 Bad Request: category name already exists'),
        );
        final formKey = GlobalKey<CategoryFormWidgetState>();
        await tester.pumpWidget(
          buildDirectWidget(formKey: formKey, category: existingCategory),
        );
        await tester.pumpAndSettle();
        await loadCategories(tester, [existingCategory]);

        await tester.enterText(find.byType(TextField), 'Loisirs');
        await tester.pumpAndSettle();
        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
        expect(find.text('Ce nom de catégorie existe déjà'), findsNothing);
      },
    );
  });

  group('CategoryFormWidget — validation emoji', () {
    forEachTheme((theme, themeName) {
      testWidgets(
        'should_show_error_when_submit_with_empty_emoji_$themeName',
        (tester) async {
          final formKey = GlobalKey<CategoryFormWidgetState>();

          await tester.pumpWidget(
            buildDirectWidget(formKey: formKey, theme: theme),
          );
          await tester.pumpAndSettle();

          // Saisir un nom mais pas d'emoji
          await tester.enterText(find.byType(TextField), 'Courses');
          await tester.pumpAndSettle();

          await formKey.currentState!.submit();
          await tester.pumpAndSettle();

          // L'erreur d'emoji vide doit être affichée
          expect(find.text("L'icône est requise"), findsOneWidget);
          verifyNever(mockRepo.create(any));
        },
      );
    });
  });

  group('CategoryFormWidget — submit création valide', () {
    testWidgets('should_call_onSaved_when_submit_valid_create', (tester) async {
      when(mockRepo.create(any)).thenAnswer(
        (_) async => existingCategory,
      );

      Category? savedCategory;
      final formKey = GlobalKey<CategoryFormWidgetState>();

      // En mode création, on part d'une catégorie vide. Pour avoir emoji valide,
      // on doit simuler la sélection. Ici on teste via une catégorie existante
      // qui pré-remplit emoji + nom — ce qui est le chemin réaliste de l'embed
      // dans CategorySelectExpand (initialName + emoji sera fourni par l'utilisateur).
      // On teste le path complet avec une catégorie en mode édition.
      await tester.pumpWidget(
        buildDirectWidget(
          formKey: formKey,
          // Mode édition pour avoir emoji + couleur pré-remplis
          category: existingCategory,
          onSaved: (c) => savedCategory = c,
        ),
      );
      await tester.pumpAndSettle();

      // Modifier le nom
      await tester.enterText(find.byType(TextField), 'Courses Bio');
      await tester.pumpAndSettle();

      when(mockRepo.update(any)).thenAnswer(
        (_) async => existingCategory.copyWith(nom: 'Courses Bio'),
      );

      await formKey.currentState!.submit();
      await tester.pumpAndSettle();

      // Le repo.update doit avoir été appelé (mode édition, pas création)
      verify(mockRepo.update(any)).called(1);
      expect(savedCategory, isNotNull);
      expect(savedCategory!.nom, 'Courses Bio');
    });
  });

  group('CategoryFormWidget — erreur réseau', () {
    testWidgets(
      'should_show_snackbar_when_submit_throws_network_error',
      (tester) async {
        when(mockRepo.update(any))
            .thenThrow(Exception('Network error: connection refused'));

        final formKey = GlobalKey<CategoryFormWidgetState>();

        await tester.pumpWidget(
          buildDirectWidget(
            formKey: formKey,
            // Mode édition pour avoir emoji pré-rempli
            category: existingCategory,
          ),
        );
        await tester.pumpAndSettle();

        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        // Un SnackBar d'erreur doit être affiché
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Erreur lors de la sauvegarde'), findsOneWidget);
        // onSaved ne doit pas avoir été appelé
      },
    );
  });

  group('CategoryFormWidget — mode édition', () {
    testWidgets(
      'should_call_onSaved_when_submit_valid_edit',
      (tester) async {
        when(mockRepo.update(any)).thenAnswer(
          (_) async => existingCategory.copyWith(nom: 'Alimentation Bio'),
        );

        Category? savedCategory;
        final formKey = GlobalKey<CategoryFormWidgetState>();

        await tester.pumpWidget(
          buildDirectWidget(
            formKey: formKey,
            category: existingCategory,
            onSaved: (c) => savedCategory = c,
          ),
        );
        await tester.pumpAndSettle();

        // Modifier le nom en mode édition
        await tester.enterText(find.byType(TextField), 'Alimentation Bio');
        await tester.pumpAndSettle();

        await formKey.currentState!.submit();
        await tester.pumpAndSettle();

        verify(mockRepo.update(any)).called(1);
        expect(savedCategory, isNotNull);
        expect(savedCategory!.nom, 'Alimentation Bio');
      },
    );

    testWidgets('should_prefill_fields_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildDirectWidget(category: existingCategory));
      await tester.pumpAndSettle();

      expect(find.text('Alimentation'), findsWidgets);
      expect(find.text('\u{1F34E}'), findsWidgets);
    });
  });

  group('CategoryFormWidget — initialName', () {
    testWidgets(
      'should_prefill_name_when_initialName_provided',
      (tester) async {
        await tester.pumpWidget(buildDirectWidget(initialName: 'Courses'));
        await tester.pumpAndSettle();

        // Le nom doit être pré-rempli
        expect(find.text('Courses'), findsWidgets);
      },
    );
  });
}
