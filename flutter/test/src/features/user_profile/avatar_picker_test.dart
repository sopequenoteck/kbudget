import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/avatar_picker.dart';
import 'package:k_budget/src/theme/app_theme.dart' show AppTheme;

void main() {
  group('AvatarPicker', () {
    testWidgets('should_showInitials_when_noAvatarUrl', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AvatarPicker(
                currentAvatarUrl: null,
                userInitials: 'KS',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('KS'), findsOneWidget);
    });

    testWidgets('should_showCameraButton_when_notLoading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AvatarPicker(
                currentAvatarUrl: null,
                userInitials: 'AB',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Modifier la photo'), findsOneWidget);
    });

    testWidgets('should_truncateInitials_when_moreThanTwoChars',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AvatarPicker(
                currentAvatarUrl: null,
                userInitials: 'ABC',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Doit afficher seulement 2 chars
      expect(find.text('AB'), findsOneWidget);
    });
  });

  group('AvatarCircle', () {
    testWidgets('should_showInitials_when_noUrl', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: const AvatarCircle(
              avatarUrl: null,
              initials: 'TS',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TS'), findsOneWidget);
    });
  });
}
