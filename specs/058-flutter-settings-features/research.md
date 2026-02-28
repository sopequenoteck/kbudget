# Research: Page Fonctionnalités (Feature Toggles) — Flutter

**Branch**: `058-flutter-settings-features` | **Date**: 2026-02-28

## R1. Persistance locale des feature toggles

**Decision**: Ajouter un champ `enabledFeatures` (List\<Feature\>) dans `AppConfig` (Freezed + FlutterSecureStorage).

**Rationale**: Le pattern AppConfig est déjà en place pour `theme`, `textScale`, `dataMode`. Ajouter un champ Freezed avec `@Default` assure la rétrocompatibilité JSON automatique (migration zéro). Le pattern setter `read → copyWith → save` est identique pour tous les champs.

**Alternatives considered**:
- SharedPreferences séparé → rejeté, fragmenterait la persistance (tout est dans un seul JSON SecureStorage)
- Provider séparé avec fichier dédié → rejeté, ajoute de la complexité inutile pour 3 booleans

## R2. Sérialisation de l'enum Feature (Flutter ↔ Backend)

**Decision**: Créer un enum Dart `Feature` avec `@JsonValue('SUBSCRIPTIONS')` etc. pour correspondre aux valeurs UPPERCASE du backend.

**Rationale**: Le backend sérialise l'enum Java en UPPERCASE (`"SUBSCRIPTIONS"`, `"DEBTS"`, `"SHOP"`). Côté Dart, convention camelCase (`Feature.subscriptions`). Le `@JsonValue` de `json_serializable` assure la correspondance automatique.

**Alternatives considered**:
- String brut → rejeté, perte de type-safety
- Custom JsonConverter → rejeté, `@JsonValue` est plus simple et suffisant

## R3. Architecture du Notifier

**Decision**: Créer un `FeatureConfigNotifier` (Notifier\<FeatureConfigState\>) qui gère la liste des features activées. Le state est une classe Freezed avec `enabledFeatures`, `isLoading`, `error`.

**Rationale**: Suit le pattern existant (`ThemeNotifier`, `TextScaleNotifier`). `build()` retourne la valeur par défaut synchrone, puis charge depuis AppConfig. En mode serveur, le notifier fait aussi le sync via `PreferenceRemoteDataSource`.

**Alternatives considered**:
- `FutureProvider` → rejeté, les notifiers existants utilisent le pattern synchrone + fire-and-forget
- Provider séparé pour local vs remote → rejeté, le notifier gère le strategy pattern en interne

## R4. Navigation dynamique (ShellRoute + AdaptiveScaffold)

**Decision**: Transformer `_paths` et `_destinations` de `static const` en données réactives pilotées par `featureConfigNotifierProvider`. Le `_ShellScaffold` watch le provider et reconstruit la liste des destinations/paths dynamiquement.

**Rationale**: Actuellement hardcodé avec 4 items. Il faut que la liste soit réactive pour refléter les toggles. Le noyau permanent (Dashboard, Transactions) est toujours présent ; les features optionnelles sont ajoutées/retirées dynamiquement.

**Alternatives considered**:
- Conserver les routes mais masquer visuellement les destinations → rejeté, les routes existeraient encore et seraient accessibles par deep link
- Reconstruire tout le GoRouter → rejeté, trop invasif ; seul le ShellRoute et AdaptiveScaffold doivent changer

## R5. Sync serveur des préférences

**Decision**: Créer `PreferenceRemoteDataSource` avec `GET /users/me/preferences` et `PUT /users/me/preferences`. Le `FeatureConfigNotifier` appelle la datasource en mode serveur uniquement (via `dataModeProvider`).

**Rationale**: Le backend KKS-117 expose déjà les endpoints. Le pattern Dio est établi (`AccountRemoteDataSource` comme référence). L'approche optimiste (update local immédiat, sync serveur en arrière-plan) offre une UX réactive.

**Alternatives considered**:
- Repository abstrait local/remote → rejeté, la persistance locale (AppConfig) est toujours présente, le remote est une synchronisation additionnelle, pas un remplacement via strategy pattern

## R6. Dialogue de confirmation (données existantes)

**Decision**: Vérifier l'existence de données via les providers existants (`subscriptionListNotifier`, `debtListNotifier`). Pour SHOP, vérifier via le compteur de produits (provider à créer ou endpoint à appeler).

**Rationale**: Les listes de données sont déjà chargées en mémoire via les notifiers existants. Vérifier `items.isNotEmpty` est immédiat et ne nécessite pas d'appel réseau supplémentaire.

**Alternatives considered**:
- Endpoint dédié `/features/{feature}/has-data` → rejeté, over-engineering pour 3 features
- Toujours afficher la confirmation → rejeté, UX inutilement lourde pour les features sans données

## R7. FabMenu — filtrage par features

**Decision**: Le `FabMenu` doit filtrer ses items selon les features activées. "Abonnement" masqué si SUBSCRIPTIONS est OFF, "Dette" si DEBTS est OFF. Le FabMenu watch `featureConfigNotifierProvider`.

**Rationale**: Cohérence UX — si une feature est désactivée, elle ne doit être accessible nulle part (ni nav, ni FAB, ni routes).

**Alternatives considered**:
- Garder tous les items FAB → rejeté, crée une incohérence avec la barre de navigation
