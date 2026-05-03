# Research — 034-flutter-settings-hub

**Date**: 2026-02-21

## R1 — URL serveur : EnvConfig vs AppConfig

**Problème** : `apiClientProvider` utilise `EnvConfig.apiBaseUrl` (constante compile-time) au lieu de `AppConfig.serverUrl` (stocké dans FlutterSecureStorage). Le switch de source de données à runtime nécessite que Dio utilise l'URL stockée dynamiquement.

**Decision** : Modifier `apiClientProvider` pour lire `AppConfig.serverUrl` au lieu de `EnvConfig.apiBaseUrl`. Comme l'app redémarre après le switch, les providers seront re-initialisés avec la nouvelle URL. Le provider doit devenir un `FutureProvider<Dio>` ou être initialisé dans un bootstrap avant `runApp()`.

**Rationale** : Le redémarrage de l'app garantit que tous les providers sont recréés. Il suffit que `apiClientProvider` lise l'URL depuis `AppConfigRepository` au démarrage. `EnvConfig.apiBaseUrl` reste le fallback si aucune URL n'est configurée.

**Alternatives considered** :
- Provider synchrone avec URL injectée au bootstrap → plus complexe, même résultat
- Hot-reload des providers sans restart → risque d'état incohérent, rejeté

## R2 — Mécanisme de redémarrage de l'app Flutter

**Problème** : Le spec exige un redémarrage de l'app après changement de source de données. Flutter n'a pas de mécanisme natif de restart.

**Decision** : Utiliser un `RestartWidget` wrapper qui reconstruit l'arbre widget complet via une `Key` changée. Pattern classique Flutter :
1. Sauvegarder le nouveau `DataMode` + `serverUrl` dans `AppConfigRepository`
2. Invalider le `ProviderContainer` et recréer `ProviderScope`
3. Le `GoRouter` redirect redirigera vers login (server mode) ou dashboard (local mode)

**Rationale** : Plus fiable que `SystemNavigator.pop()` (qui ferme l'app) et compatible multi-plateforme. Le `RestartWidget` avec `UniqueKey()` force la reconstruction de tout l'arbre.

**Alternatives considered** :
- `SystemNavigator.pop()` → ferme l'app sans garantie de redémarrage automatique
- Phoenix / restart_app packages → dépendance externe inutile pour ce cas simple
- Invalidation manuelle de chaque provider → fragile, risque d'oubli

## R3 — Widget d'item de settings : ListItem existant vs nouveau widget

**Problème** : Le `ListItem` existant utilise un `String icon` (emoji texte) et a un layout orienté données financières (titre + valeur monétaire). Le hub settings nécessite une `IconData` Material Icon dans un cercle coloré, un titre, une description, et optionnellement un badge "À venir" + chevron.

**Decision** : Créer un widget `SettingsItem` dédié au hub settings. Ne pas modifier `ListItem` qui est optimisé pour les données financières et utilisé dans 4 contextes métier. Le `SettingsItem` aura :
- `IconData icon` + `Color iconColor` (cercle coloré)
- `String title` + `String description`
- `bool isPlaceholder` (contrôle le badge "À venir" et l'opacité)
- `VoidCallback? onTap`

**Rationale** : Le layout est suffisamment différent (icône Material vs emoji, description vs montant, badge vs rightSubtitle) pour justifier un widget séparé. Pas de surcharge de `ListItem` avec des cas conditionnels qui le complexifieraient.

**Alternatives considered** :
- Étendre `ListItem` avec un mode `settings` → violerait SRP, ajouterait de la complexité conditionnelle
- Utiliser `ListTile` Material → moins de contrôle sur le design (cercle coloré, badge)

## R4 — Structure des routes settings

**Problème** : Actuellement `/settings` est une route standalone hors du `ShellRoute`. Les sous-pages (profile, appearance, accounts, categories, data) doivent être des sous-routes.

**Decision** : Ajouter les sous-routes sous la route `/settings` existante :
```
GoRoute(
  path: '/settings',
  builder: ... → SettingsHubScreen,
  routes: [
    GoRoute(path: 'profile', ...),
    GoRoute(path: 'appearance', ...),
    GoRoute(path: 'accounts', ...),
    GoRoute(path: 'categories', ...),
    GoRoute(path: 'data', ...),
  ],
)
```

Les sous-pages non implémentées dans cette feature (profile, appearance, accounts, categories) seront des stubs avec un titre et un bouton retour.

**Rationale** : Conserve la structure de navigation existante. Les sous-routes héritent du `parentNavigatorKey` (root navigator) pour un affichage plein écran.

**Alternatives considered** :
- Routes flat (`/settings-profile`, `/settings-data`) → moins organisé, pas de relation parent-enfant
- `ShellRoute` séparé pour settings → over-engineering pour une liste simple

## R5 — Validation d'URL et test de connectivité

**Problème** : FR-014 exige la validation du format URL (https:// requis) et le edge case mentionne un test de connectivité avant le switch vers serveur.

**Decision** : Validation en 2 temps :
1. **Validation format** (synchrone) : regex simple vérifiant le schéma `https://` (ou `http://` en dev)
2. **Test de connectivité** (asynchrone) : appel HEAD sur l'URL avant le switch, réutiliser le pattern `checkServerConnectivity()` existant dans `OnboardingNotifier`

**Rationale** : Réutilise l'infrastructure existante de `OnboardingNotifier.checkServerConnectivity()`. Le test de connectivité est déjà implémenté avec timeout de 10s.

**Alternatives considered** :
- Validation URL stricte avec Uri.parse → trop permissif (accepte tout schéma)
- Pas de test de connectivité → mauvaise UX si le serveur est injoignable
