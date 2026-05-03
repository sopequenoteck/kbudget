# Research: 031-flutter-setup

**Date**: 2026-02-18
**Branch**: `031-flutter-setup`

## Decisions

### 1. Structure de projet Flutter

- **Decision**: Feature-first avec 4 couches par feature (data, domain, application, presentation)
- **Rationale**: Meilleure scalabilite, isolation des features, alignement avec les patterns Riverpod recommandes. Chaque feature contient ses data sources, repositories, notifiers et ecrans.
- **Alternatives considered**:
  - Layer-first (tous les models ensemble, tous les services ensemble) : rejete car moins scalable quand le nombre de features augmente
  - Clean Architecture stricte : rejete car trop de boilerplate pour un projet mono-utilisateur

### 2. Riverpod + go_router : Auth Guards

- **Decision**: `AuthNotifier` implemente `Listenable` et est passe comme `refreshListenable` au `GoRouter`. La fonction `redirect` du router re-evalue les conditions d'acces a chaque changement d'etat auth.
- **Rationale**: Pattern officiel recommande par les mainteneurs de go_router et Riverpod. Reactive, declaratif, testable.
- **Alternatives considered**:
  - Navigator 2.0 manuel : rejete car go_router l'abstrait deja
  - Guards middleware custom : rejete car go_router fournit `redirect` nativement

### 3. Drift multi-plateforme

- **Decision**: Utiliser `drift_flutter` (package officiel) qui gere automatiquement le backend SQLite selon la plateforme : FFI natif (iOS/Android), sql.js WASM (Web).
- **Rationale**: Un seul point d'entree (`driftDatabase()`), pas de code conditionnel par plateforme. Le Web necessite `sqlite3.wasm` + `drift_worker.dart.js` dans `web/`, avec headers COOP/COEP.
- **Alternatives considered**:
  - sqflite : rejete car pas de support Web, pas type-safe, pas de code generation
  - Hive/Isar : rejete car NoSQL, pas coherent avec le schema relationnel PostgreSQL du backend
  - Conditional imports manuels : rejete car `drift_flutter` les gere automatiquement

### 4. Repository Pattern avec Riverpod (local vs remote)

- **Decision**: Interface abstraite `XxxRepository` dans `domain/`, implementation concrete dans `data/`. Le provider Riverpod selectionne l'implementation selon le mode (local ou serveur) configure dans `AppConfig`.
- **Rationale**: Les ecrans ne connaissent que l'interface. Le changement de mode ne touche que la resolution du provider, pas le code UI.
- **Alternatives considered**:
  - Strategie pattern avec classe unique : rejete car plus complexe et moins testable
  - Deux apps separees (local et server) : rejete car duplication massive de code UI

### 5. Configuration d'environnement

- **Decision**: `--dart-define-from-file` avec fichiers JSON dans `config/` (env.dev.json, env.prod.json). Fichiers gitignores sauf env.example.json.
- **Rationale**: Variables embarquees a la compilation (pas de fichier `.env` dans le bundle). Simple, securise, pas de dependance a un package tiers.
- **Alternatives considered**:
  - flutter_dotenv : rejete car charge les variables au runtime (fichier .env dans le bundle)
  - Flavors natifs : rejete car configuration lourde (schemes iOS, productFlavors Android) pour seulement 2 envs

### 6. Structure de tests

- **Decision**: Structure miroir de `lib/` dans `test/`. Tests d'integration dans `integration_test/`. Helpers partages dans `test/helpers/`.
- **Rationale**: Convention Flutter standard. Facilite la navigation entre code source et tests. Isolation par feature.
- **Alternatives considered**:
  - Tests groupes par type (tous les unit tests ensemble) : rejete car perd la correspondance avec les features
  - BDD (Gherkin) : rejete car overhead pour un projet mono-utilisateur

### 7. Design tokens Flutter

- **Decision**: Porter les tokens SCSS existants vers des classes Dart constantes (`AppColors`, `AppTypography`, `AppSpacing`, etc.) et un `ThemeData` Flutter custom avec extension themes.
- **Rationale**: Les tokens sont stables et documentes dans le design system Angular. Le portage 1:1 garantit la coherence visuelle. `ThemeExtension` permet d'ajouter les tokens metier (income, expense, subscription colors).
- **Alternatives considered**:
  - Material 3 par defaut avec customisation : rejete car les tokens existants ne correspondent pas au Material 3 color scheme standard
  - Package design system partage (Token Studio) : rejete car overhead pour un seul projet

### 8. Packages Flutter selectionnes

| Package | Version | Usage |
|---------|---------|-------|
| flutter_riverpod | ^2.6.x | State management + DI |
| riverpod_annotation + riverpod_generator | ^2.x | Code generation pour providers |
| go_router | ^14.x | Routing declaratif + deep links |
| drift + drift_flutter | ^2.31.x | BDD locale relationnelle |
| drift_dev + build_runner | ^2.31.x | Code generation Drift |
| dio | ^5.x | Client HTTP + intercepteurs |
| flutter_secure_storage | ^9.x | Stockage securise (tokens, PIN) |
| local_auth | ^2.x | Biometrie (Touch ID, Face ID, BiometricPrompt) |
| firebase_crashlytics + firebase_core | latest | Crash reporting iOS/Android |
| uuid | ^4.x | Generation UUID v4 |
| intl + flutter_localizations | SDK | i18n infrastructure |
| json_annotation + json_serializable | ^6.x | Serialisation JSON |
| freezed + freezed_annotation | ^2.x | Immutable data classes |
| mockito + build_runner | ^5.x | Mocking pour tests |
| integration_test | SDK | Tests d'integration |
