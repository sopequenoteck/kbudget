import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:k_budget/src/features/user_profile/domain/models/avatar_metadata.dart';
import 'package:k_budget/src/features/user_profile/domain/models/change_password_request.dart';
import 'package:k_budget/src/features/user_profile/domain/models/delete_account_request.dart';
import 'package:k_budget/src/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:k_budget/src/features/user_profile/presentation/widgets/avatar_picker.dart';
import 'package:k_budget/src/theme/app_theme.dart' show AppTheme;
import 'package:k_budget/src/localization/app_localizations.dart';

/// Repository dont la suppression d'avatar echoue avec [error].
class _FailingAvatarRepository implements UserProfileRepository {
  _FailingAvatarRepository(this.error);
  final String error;

  @override
  Future<void> deleteAvatar() async => throw Exception(error);

  @override
  Future<AvatarMetadata> uploadAvatar(File file) => throw UnimplementedError();

  @override
  Future<AuthResponse> changePassword(ChangePasswordRequest req) =>
      throw UnimplementedError();

  @override
  Future<void> updateName(String name) => throw UnimplementedError();

  @override
  Future<File> exportJson() => throw UnimplementedError();

  @override
  Future<File> exportCsv() => throw UnimplementedError();

  @override
  Future<void> deleteAccount(DeleteAccountRequest req) =>
      throw UnimplementedError();
}

void main() {
  Widget buildWithAvatar(UserProfileRepository repo) => ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          theme: AppTheme.light,
          home: const Scaffold(
            body: AvatarPicker(
              currentAvatarUrl: 'https://example.com/avatar.jpg',
              userInitials: 'KS',
            ),
          ),
        ),
      );

  Future<void> deleteAvatarFailing(WidgetTester tester, String error) async {
    await tester.pumpWidget(buildWithAvatar(_FailingAvatarRepository(error)));
    await tester.pump();
    await tester.tap(find.text('Modifier la photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer la photo'));
    await tester.pumpAndSettle();
  }

  group('AvatarPicker menu', () {
    testWidgets('should_listPhotoActions_when_menuOpened', (tester) async {
      await tester.pumpWidget(
        buildWithAvatar(_FailingAvatarRepository('unused')),
      );
      await tester.pump();

      await tester.tap(find.text('Modifier la photo'));
      await tester.pumpAndSettle();

      expect(find.text('Changer la photo'), findsOneWidget);
      expect(find.text('Supprimer la photo'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Changer la photo'), findsNothing);
    });

    testWidgets('should_showFileTooLarge_when_apiRejectsSize', (tester) async {
      await deleteAvatarFailing(tester, 'HTTP 413 FILE_TOO_LARGE');

      expect(
        find.text('Fichier trop volumineux. La taille maximale est 2 MB.'),
        findsOneWidget,
      );
    });

    testWidgets('should_showInvalidFormat_when_apiRejectsFormat',
        (tester) async {
      await deleteAvatarFailing(tester, 'INVALID_IMAGE_FORMAT');

      expect(
        find.text('Seuls les formats JPG et PNG sont acceptés.'),
        findsOneWidget,
      );
    });

    testWidgets('should_showUploadError_when_otherFailure', (tester) async {
      await deleteAvatarFailing(tester, 'timeout');

      expect(
        find.text("Impossible d'uploader la photo. Veuillez réessayer."),
        findsOneWidget,
      );
    });
  });

  group('AvatarPicker', () {
    testWidgets('should_showInitials_when_noAvatarUrl', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            theme: AppTheme.light,
            home: const Scaffold(
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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            theme: AppTheme.light,
            home: const Scaffold(
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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            theme: AppTheme.light,
            home: const Scaffold(
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          theme: AppTheme.light,
          home: const Scaffold(
            body: AvatarCircle(
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
