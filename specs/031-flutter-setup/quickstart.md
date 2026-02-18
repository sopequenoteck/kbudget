# Quickstart: 031-flutter-setup

**Date**: 2026-02-18
**Branch**: `031-flutter-setup`

## Prerequisites

- Flutter SDK >= 3.27.x (stable channel)
- Dart SDK >= 3.6.x (inclus avec Flutter)
- Xcode >= 15 (pour iOS)
- Android Studio / Android SDK API 24+
- Chrome (pour web dev)

## Setup initial

```bash
# Depuis la racine du monorepo
cd flutter/

# Installer les dependances
flutter pub get

# Generer le code (Drift, freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs

# Verifier que tout compile
flutter analyze
```

## Lancer l'application

### Mode dev (mobile)

```bash
# iOS
flutter run --dart-define-from-file=config/env.dev.json -d ios

# Android
flutter run --dart-define-from-file=config/env.dev.json -d android
```

### Mode dev (web)

```bash
# Headers COOP/COEP necessaires pour Drift (SQLite WASM)
flutter run -d chrome \
  --dart-define-from-file=config/env.dev.json \
  --web-header=Cross-Origin-Opener-Policy=same-origin \
  --web-header=Cross-Origin-Embedder-Policy=require-corp
```

### Mode prod (build)

```bash
# Android APK
flutter build apk --dart-define-from-file=config/env.prod.json

# iOS
flutter build ios --dart-define-from-file=config/env.prod.json

# Web
flutter build web --dart-define-from-file=config/env.prod.json
```

## Configuration d'environnement

Creer les fichiers a partir du template :

```bash
cp config/env.example.json config/env.dev.json
cp config/env.example.json config/env.prod.json
```

Editer `config/env.dev.json` :
```json
{
  "API_BASE_URL": "http://localhost:8080/api",
  "ENV": "dev"
}
```

Editer `config/env.prod.json` :
```json
{
  "API_BASE_URL": "https://budget.kksdev.fr/api",
  "ENV": "prod"
}
```

## Tests

```bash
# Unit + Widget tests
flutter test

# Test specifique
flutter test test/src/features/auth/application/auth_notifier_test.dart

# Integration tests
flutter test integration_test/

# Coverage
flutter test --coverage
```

## Code generation (watch mode)

```bash
# Regenerer automatiquement a chaque modification
dart run build_runner watch --delete-conflicting-outputs
```

## Structure du projet

```
flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   └── src/
│       ├── common_widgets/
│       ├── constants/
│       ├── routing/
│       ├── localization/
│       ├── theme/
│       ├── utils/
│       └── features/
│           ├── auth/
│           ├── onboarding/
│           ├── dashboard/
│           ├── transactions/
│           ├── subscriptions/
│           ├── debts/
│           └── settings/
├── test/
│   ├── src/ (miroir de lib/src/)
│   ├── helpers/
│   └── widget_test.dart
├── integration_test/
├── config/
│   ├── env.example.json
│   ├── env.dev.json (gitignored)
│   └── env.prod.json (gitignored)
├── web/
│   ├── sqlite3.wasm
│   └── drift_worker.dart.js
├── assets/
│   └── fonts/
│       └── Inter/
├── pubspec.yaml
└── analysis_options.yaml
```

## VS Code

Le fichier `.vscode/launch.json` dans `flutter/` contient les configurations de lancement pre-configurees pour dev et prod.
