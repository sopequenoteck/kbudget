# Quickstart: Settings — Profil

**Feature**: 049-flutter-settings-profile | **Date**: 2026-02-23

## Prérequis

- Flutter >= 3.27 installé
- Backend API lancé (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Compte utilisateur créé (via `/auth/register`)
- KKS-96 (SelectPicker) mergé
- KKS-110 (Settings hub refonte) mergé

## Lancer le projet

```bash
cd flutter
flutter run
```

## Tester la feature

1. Se connecter avec un compte existant
2. Naviguer vers Paramètres (icône engrenage)
3. Taper sur "Profil"
4. Vérifier : nom, email, devise affichés
5. Taper sur le champ devise → picker s'ouvre
6. Sélectionner une autre devise
7. Taper "Enregistrer" dans l'AppBar
8. Vérifier le SnackBar de confirmation

## Lancer les tests

```bash
cd flutter

# Tests unitaires du notifier
flutter test test/src/features/user_profile/

# Tous les tests
flutter test
```

## Code generation (si modification des DTOs/models)

```bash
cd flutter
dart run build_runner build --delete-conflicting-outputs
```

## Fichiers créés par cette feature

| Fichier | Rôle |
|---------|------|
| `lib/src/data/remote/data_sources/user_remote_data_source.dart` | Appels HTTP GET/PUT /users/me |
| `lib/src/data/remote/dtos/user_dtos.dart` | DTOs Freezed (request/response) |
| `lib/src/domain/repositories/user_repository.dart` | Interface abstraite |
| `lib/src/features/user_profile/application/user_profile_notifier.dart` | State management |
| `lib/src/features/user_profile/application/user_profile_providers.dart` | Déclaration providers |
| `lib/src/features/user_profile/data/user_repository_remote.dart` | Implémentation remote |
| `lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` | Écran UI |
| `lib/src/features/user_profile/presentation/widgets/profile_settings_skeleton.dart` | Skeleton loading |
