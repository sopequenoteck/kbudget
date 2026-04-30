import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/delete_account_sheet.dart';
import 'package:k_budget/src/theme/app_theme.dart' show AppTheme;

void main() {
  group('DeleteAccountSheet', () {
    Widget buildTestApp() {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => DeleteAccountSheet.show(context),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('should_showFormFields_when_rendered', (tester) async {
      await openSheet(tester);

      // Titre + bouton ont le même texte : au moins 2 widgets
      expect(find.text('Supprimer mon compte'), findsAtLeast(1));
      expect(find.text('Mot de passe actuel'), findsOneWidget);
      expect(
        find.text('Je comprends que cette action est définitive'),
        findsOneWidget,
      );
    });

    testWidgets(
        'should_disableSubmitButton_when_passwordEmptyAndCheckboxUnchecked',
        (tester) async {
      await openSheet(tester);

      // Le bouton "Supprimer mon compte" doit être désactivé initialement
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Supprimer mon compte'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should_disableSubmitButton_when_passwordFilledButCheckboxUnchecked',
        (tester) async {
      await openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe actuel'),
        'mon_mot_de_passe',
      );
      await tester.pump();

      // Checkbox toujours décochée → bouton désactivé
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Supprimer mon compte'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should_disableSubmitButton_when_checkboxCheckedButPasswordEmpty',
        (tester) async {
      await openSheet(tester);

      // Cocher la checkbox uniquement
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Mot de passe vide → bouton désactivé
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Supprimer mon compte'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'should_enableSubmitButton_when_passwordFilledAndCheckboxChecked',
        (tester) async {
      await openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe actuel'),
        'mon_mot_de_passe',
      );
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Supprimer mon compte'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should_dismissSheet_when_cancelTapped', (tester) async {
      await openSheet(tester);

      // Titre + bouton : vérifier la présence de la sheet via le champ mot de passe
      expect(find.text('Mot de passe actuel'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe actuel'), findsNothing);
    });

    testWidgets('should_showPasswordField_when_rendered', (tester) async {
      await openSheet(tester);

      // Le champ est en mode obscure par défaut
      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Mot de passe actuel'),
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('should_togglePasswordVisibility_when_iconTapped',
        (tester) async {
      await openSheet(tester);

      // Vérifier obscureText = true initialement
      final textFieldBefore = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Mot de passe actuel'),
          matching: find.byType(TextField),
        ),
      );
      expect(textFieldBefore.obscureText, isTrue);

      // Taper sur l'icone de visibilité
      await tester.tap(find.byType(IconButton).first);
      await tester.pump();

      final textFieldAfter = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Mot de passe actuel'),
          matching: find.byType(TextField),
        ),
      );
      expect(textFieldAfter.obscureText, isFalse);
    });
  });
}
