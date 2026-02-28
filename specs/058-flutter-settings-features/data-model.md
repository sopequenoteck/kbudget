# Data Model: Page Fonctionnalités (Feature Toggles) — Flutter

**Branch**: `058-flutter-settings-features` | **Date**: 2026-02-28

## Entities

### Feature (enum)

Fonctionnalité optionnelle de l'application.

| Valeur Dart | Valeur JSON (backend) | Libellé | Icône | Description courte | Défaut Flutter |
|-------------|----------------------|---------|-------|-------------------|----------------|
| `subscriptions` | `SUBSCRIPTIONS` | Abonnements | `Icons.autorenew` | Gérer vos abonnements récurrents | activé |
| `debts` | `DEBTS` | Dettes | `Icons.handshake` | Suivre vos prêts et emprunts | activé |
| `shop` | `SHOP` | Boutique | `Icons.storefront` | Gérer vos ventes de produits | désactivé |

**Règles** :
- Ensemble fermé — seules ces 3 valeurs sont valides
- Dashboard et Transactions sont le noyau permanent, jamais toggleable
- Sérialisé en UPPERCASE pour compatibilité backend (`@JsonValue`)

### FeatureConfigState (Freezed)

État du notifier de configuration des features.

| Champ | Type | Default | Description |
|-------|------|---------|-------------|
| `enabledFeatures` | `List<Feature>` | `[Feature.subscriptions, Feature.debts]` | Features actuellement activées |
| `isLoading` | `bool` | `false` | Chargement en cours (sync serveur) |
| `error` | `String?` | `null` | Message d'erreur (sync échouée) |

### UserPreferenceResponse (Freezed + json_serializable)

Réponse de l'API `GET /users/me/preferences`.

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `enabledFeatures` | `List<Feature>` | non | Features activées côté serveur |
| `navOrder` | `List<Feature>` | non | Ordre de navigation |
| `shopAccountId` | `String?` | oui | UUID du compte boutique |
| `includeShopInBalance` | `bool` | non | Inclure le solde boutique dans le total |

### UserPreferenceRequest (Freezed + json_serializable)

Requête de l'API `PUT /users/me/preferences`.

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `enabledFeatures` | `List<Feature>` | non | Features à activer |
| `navOrder` | `List<Feature>?` | oui | Ordre de navigation (null = auto-géré) |
| `shopAccountId` | `String?` | oui | UUID du compte boutique |
| `includeShopInBalance` | `bool?` | oui | Inclure le solde boutique |

## Relationships

```
AppConfig (FlutterSecureStorage)
    └── enabledFeatures: List<Feature>   ← NOUVEAU champ

FeatureConfigNotifier
    ├── lit/écrit → AppConfig (toujours)
    └── sync → PreferenceRemoteDataSource (mode serveur uniquement)

PreferenceRemoteDataSource
    ├── GET /users/me/preferences → UserPreferenceResponse
    └── PUT /users/me/preferences → UserPreferenceRequest → UserPreferenceResponse
```

## State Transitions

```
[Premier lancement]
    │
    ▼
enabledFeatures = [SUBSCRIPTIONS, DEBTS]  (défaut local Flutter)
    │
    ├── Mode local → reste tel quel
    │
    └── Mode serveur → GET /users/me/preferences
         │
         ▼
    enabledFeatures = réponse serveur  (server wins)

[Toggle une feature]
    │
    ▼
1. Update optimiste (state immédiat)
2. Persist dans AppConfig
3. Si mode serveur → PUT /users/me/preferences (navOrder = null, auto-géré)
    │
    ├── Succès → rien de plus
    └── Échec → snackbar erreur, état local conservé
```

## Persistence

| Couche | Mécanisme | Clé/Endpoint |
|--------|-----------|--------------|
| Locale | FlutterSecureStorage (JSON `AppConfig`) | `app_config` |
| Distante | API REST (Dio) | `GET/PUT /users/me/preferences` |
