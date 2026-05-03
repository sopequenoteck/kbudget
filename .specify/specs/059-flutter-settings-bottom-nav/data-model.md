# Data Model: Configuration de la navigation — Flutter

**Branch**: `059-flutter-settings-bottom-nav` | **Date**: 2026-02-28

## Entités modifiées

### AppConfig (Freezed model — stockage local)

**Fichier**: `flutter/lib/src/domain/models/app_config.dart`

| Champ | Type | Default | Nouveau | Description |
|-------|------|---------|---------|-------------|
| dataMode | DataMode | required | non | Mode données (local/server) |
| serverUrl | String? | null | non | URL serveur API |
| theme | AppTheme | AppTheme.light | non | Thème app |
| textScale | TextScale | TextScale.medium | non | Échelle texte |
| lockEnabled | bool | false | non | Verrouillage activé |
| lockMethod | LockMethod? | null | non | Méthode verrou |
| hashedPin | String? | null | non | PIN hashé |
| onboardingCompleted | bool | false | non | Onboarding fait |
| enabledFeatures | List\<Feature\> | [subscriptions, debts] | non | Features activées |
| **navOrder** | **List\<Feature\>** | **[subscriptions, debts, shop]** | **OUI** | **Ordre navigation** |

**Règles de validation**:
- `navOrder` contient toutes les features (activées et désactivées)
- Les identifiants inconnus dans `navOrder` (désérialisation) sont ignorés
- Si `navOrder` est vide ou absent (migration), il est initialisé à `Feature.values`

### FeatureConfigState (Freezed state — Riverpod)

**Fichier**: `flutter/lib/src/features/settings/application/feature_config_notifier.dart`

| Champ | Type | Default | Nouveau | Description |
|-------|------|---------|---------|-------------|
| enabledFeatures | List\<Feature\> | [subscriptions, debts] | non | Features activées |
| **navOrder** | **List\<Feature\>** | **Feature.values** | **OUI** | **Ordre navigation** |
| isLoading | bool | false | non | Chargement en cours |
| error | String? | null | non | Erreur dernière opération |

### Feature enum (extension)

**Fichier**: `flutter/lib/src/domain/enums/feature.dart`

| Getter | Type | Nouveau | Description |
|--------|------|---------|-------------|
| label | String | non | Libellé français |
| icon | IconData | non | Icône filled (active) |
| description | String | non | Description courte |
| defaultEnabled | bool | non | Activé par défaut |
| **outlinedIcon** | **IconData** | **OUI** | **Icône outlined (inactive)** |

Valeurs `outlinedIcon`:
- subscriptions → `Icons.autorenew_outlined`
- debts → `Icons.handshake_outlined`
- shop → `Icons.storefront_outlined`

## Interfaces modifiées

### AppConfigRepository (abstract)

**Fichier**: `flutter/lib/src/domain/repositories/app_config_repository.dart`

Nouvelles méthodes:
- `Future<List<Feature>> getNavOrder()` — Lit l'ordre depuis AppConfig
- `Future<void> setNavOrder(List<Feature> order)` — Persiste l'ordre dans AppConfig

## Flux de données

```
ReorderableListView (drag & drop)
  │ onReorder(oldIndex, newIndex)
  ▼
FeatureConfigNotifier.reorderNavigation(List<Feature>)
  │
  ├─► state = state.copyWith(navOrder: newOrder)
  │
  ├─► AppConfigRepository.setNavOrder(newOrder)  [local]
  │
  └─► PreferenceRemoteDataSource.updatePreferences(  [server, fire-and-forget]
        enabledFeatures: state.enabledFeatures,
        navOrder: newOrder,
      )
  │
  ▼
_ShellScaffold watches featureConfigNotifierProvider
  │ Filtre: navOrder.where(enabledFeatures.contains)
  ▼
BottomNavigationBar (onglets dans le bon ordre)
```

## Noyau fixe (non modélisé)

Le noyau fixe (Dashboard + Transactions) n'est **pas** modélisé dans `navOrder`. Il est hardcodé dans `_ShellScaffold` (toujours positions 0 et 1). Seules les features optionnelles sont réordonnables.

Métadonnées du noyau fixe (constante locale dans le widget) :

| Tab | Label | Icon | SelectedIcon | Route |
|-----|-------|------|-------------|-------|
| Dashboard | Accueil | Icons.home_outlined | Icons.home | /dashboard |
| Transactions | Transactions | Icons.receipt_long_outlined | Icons.receipt_long | /transactions |
