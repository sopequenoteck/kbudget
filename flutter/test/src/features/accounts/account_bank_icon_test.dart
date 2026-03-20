import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  Widget buildApp(Account account) {
    return MaterialApp(
      theme: theme.AppTheme.light,
      home: Scaffold(
        body: AccountBankIcon(account: account, size: 24),
      ),
    );
  }

  group('AccountBankIcon', () {
    testWidgets('should_show_svg_when_bankCode_is_known', (tester) async {
      const account = Account(
        id: '1',
        nom: 'Test',
        type: AccountType.courant,
        soldeInitial: 0,
        icone: '🏦',
        couleur: '#000000',
        isDefault: false,
        currency: Currency.eur,
        bankCode: 'SG',
      );

      await tester.pumpWidget(buildApp(account));
      await tester.pump();

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets(
        'should_show_custom_logo_when_bankCode_is_other_with_custom_logo',
        (tester) async {
      const account = Account(
        id: '1',
        nom: 'Test',
        type: AccountType.courant,
        soldeInitial: 0,
        icone: '🏦',
        couleur: '#000000',
        isDefault: false,
        currency: Currency.eur,
        bankCode: 'OTHER',
        bankCustomLogo:
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );

      await tester.pumpWidget(buildApp(account));
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should_show_emoji_when_bankCode_is_other_without_logo',
        (tester) async {
      const account = Account(
        id: '1',
        nom: 'Test',
        type: AccountType.courant,
        soldeInitial: 0,
        icone: '🏦',
        couleur: '#000000',
        isDefault: false,
        currency: Currency.eur,
        bankCode: 'OTHER',
        bankCustomLogo: null,
      );

      await tester.pumpWidget(buildApp(account));
      await tester.pump();

      expect(find.text('🏦'), findsOneWidget);
    });

    testWidgets('should_use_brand_color_background_when_available',
        (tester) async {
      const account = Account(
        id: '1',
        nom: 'Test',
        type: AccountType.courant,
        soldeInitial: 0,
        icone: '🏦',
        couleur: '#000000',
        isDefault: false,
        currency: Currency.eur,
        bankCode: 'OTHER',
        bankBrandColor: '#e2001a',
      );

      await tester.pumpWidget(buildApp(account));
      await tester.pump();

      // Vérifier qu'un Container est rendu (le widget racine d'AccountBankIcon)
      final containers = tester.widgetList<Container>(find.byType(Container));
      // La couleur de fond doit être basée sur bankBrandColor (#e2001a)
      // Le Container extérieur est le premier rendu avec la couleur
      expect(containers, isNotEmpty);

      // Chercher le container avec la couleur issue de bankBrandColor
      final expectedColor = const Color(0xffe2001a).withValues(alpha: 0.1);
      final matchingContainer = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == expectedColor;
        }
        return false;
      });
      expect(matchingContainer, isTrue);
    });
  });
}
