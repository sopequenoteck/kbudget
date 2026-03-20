import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_list_tile.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  const defaultAccount = Account(
    id: '1',
    nom: 'Courant',
    type: AccountType.courant,
    soldeInitial: 1000.0,
    solde: 1250.50,
    icone: '\u{1F3E6}',
    couleur: '#3b82f6',
    isDefault: true,
    actif: true,
  );

  const inactiveAccount = Account(
    id: '2',
    nom: 'Ancien',
    type: AccountType.epargne,
    soldeInitial: 0,
    solde: 0,
    icone: '\u{1F437}',
    couleur: '#22c55e',
    isDefault: false,
    actif: false,
  );

  const normalAccount = Account(
    id: '3',
    nom: 'Especes',
    type: AccountType.especes,
    soldeInitial: 100.0,
    solde: 100.0,
    icone: '\u{1F4B5}',
    couleur: '#f59e0b',
    isDefault: false,
    actif: true,
  );

  Widget buildApp(Account account, {VoidCallback? onTap}) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AccountListTile(
            account: account,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('AccountListTile', () {
    testWidgets('should_showAccountInfo_when_rendered', (tester) async {
      await tester.pumpWidget(buildApp(defaultAccount));
      await tester.pumpAndSettle();

      expect(find.text('Courant'), findsWidgets);
    });

    testWidgets('should_showDefaultBadge_when_isDefault', (tester) async {
      await tester.pumpWidget(buildApp(defaultAccount));
      await tester.pumpAndSettle();

      expect(find.text('Défaut'), findsOneWidget);
    });

    testWidgets('should_showInactiveBadge_when_inactive', (tester) async {
      await tester.pumpWidget(buildApp(inactiveAccount));
      await tester.pumpAndSettle();

      expect(find.text('Inactif'), findsOneWidget);
    });

    testWidgets('should_applyReducedOpacity_when_inactive', (tester) async {
      await tester.pumpWidget(buildApp(inactiveAccount));
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });

    testWidgets('should_showPopupMenu_when_menuTapped', (tester) async {
      await tester.pumpWidget(buildApp(normalAccount));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsRegular.dotsThreeVertical));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('should_hideSetDefaultOption_when_alreadyDefault',
        (tester) async {
      await tester.pumpWidget(buildApp(defaultAccount));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsRegular.dotsThreeVertical));
      await tester.pumpAndSettle();

      expect(find.text('Définir par défaut'), findsNothing);
      expect(find.text('Supprimer'), findsOneWidget);
    });

    testWidgets('should_showSetDefaultOption_when_notDefault',
        (tester) async {
      await tester.pumpWidget(buildApp(normalAccount));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsRegular.dotsThreeVertical));
      await tester.pumpAndSettle();

      expect(find.text('Définir par défaut'), findsOneWidget);
    });
  });
}
