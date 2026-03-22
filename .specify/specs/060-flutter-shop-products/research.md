# Research: 060-flutter-shop-products

**Date**: 2026-03-01
**Branch**: `060-flutter-shop-products`

## R1: Pattern CRUD Notifier pour liste produits

**Decision**: Réutiliser le pattern CRUD Notifier existant (`NotifierProvider<XxxNotifier, XxxListState>`) identique aux features subscriptions et debts.

**Rationale**: Le pattern est mature, cohérent dans le codebase, et couvre tous les besoins (loading/empty/error states, pagination client-side, optimistic updates, pull-to-refresh). La feature Shop n'a pas de logique supplémentaire nécessitant un pattern différent.

**Alternatives considered**:
- `AsyncNotifier` — rejeté : le pattern synchrone `Notifier` + `_allItems` internes est le standard du projet et gère mieux les mutations optimistes.
- `StateNotifier` — rejeté : déprécié au profit de `Notifier` dans Riverpod 2+.

## R2: Strategy pattern data mode (server-only)

**Decision**: Créer un `productRepositoryProvider` server-only sans implémentation Drift locale. Utiliser un `Provider<ProductRepository>` qui dépend de `authenticatedDioProvider`.

**Rationale**: La Boutique est une feature serveur-uniquement (pas de mode offline). Créer une table Drift + DAO serait du YAGNI — le backend est la source de vérité pour les stocks et ventes. Le pattern est identique à `PreferenceRemoteDataSource` (server-only).

**Alternatives considered**:
- Full strategy pattern (local + remote) — rejeté : aucune table Drift existante pour products, pas de besoin offline. Ajouterait du code mort.
- `FutureProvider<ProductRepository>` — rejeté : `Provider` synchrone reste préféré pour la compatibilité avec le pattern `ref.read(repo)` dans les notifiers.

## R3: Widget ListItem pour affichage produit

**Decision**: Réutiliser `ListItem` existant pour chaque produit. Mapper les champs : `icon` → emoji produit, `title` → nom, `value` → prix de vente formaté, `subtitle` → "Stock: X", `rightSubtitle` → "X ventes".

**Rationale**: `ListItem` est le composant standard pour toutes les listes du projet (transactions, subscriptions, debts). Il supporte déjà : icône emoji, titre tronqué, sous-titre, valeur formatée, couleur dynamique, squelette shimmer, callback onPressed.

**Alternatives considered**:
- Widget custom `ProductListTile` — rejeté : violerait le principe de réutilisation et la cohérence visuelle du projet.

## R4: Routing et navigation

**Decision**: Remplacer le placeholder existant dans `app_router.dart` (lignes 181-187) par le `ProductListScreen`. Aucun changement nécessaire à `_ShellScaffold`, `FabMenu`, `RouteNames`, ou `Feature` enum — tout est déjà configuré.

**Rationale**: La route `/shop` est déjà enregistrée avec un placeholder `Text('Boutique — À venir')`. L'enum `Feature.shop` est défini avec `defaultEnabled: false`. Le `_ShellScaffold` gère déjà le cas `Feature.shop` dans son switch pour la bottom nav.

**Alternatives considered**: Aucune — l'infrastructure de navigation est complète.

## R5: Rupture de stock — traitement visuel

**Decision**: Utiliser l'opacité réduite (`Opacity(0.5)`) sur l'item `ListItem` entier pour les produits en rupture de stock (stock = 0), avec le `rightSubtitle` "Rupture" en couleur d'erreur.

**Rationale**: L'opacité est un signal visuel universel pour "indisponible" sans ajouter de complexité (pas de badge custom). Le `rightSubtitle` du `ListItem` est déjà utilisé pour les statuts (ex: "Inactif" pour les subscriptions).

**Alternatives considered**:
- Badge overlay "Rupture" — rejeté : nécessiterait un widget custom non existant dans le design system.
- Couleur de fond différente — rejeté : inconsistant avec les patterns existants.

## R6: DTOs Freezed pour Product

**Decision**: Créer `ProductRequest`, `ProductUpdateRequest`, et `ProductResponse` comme Freezed DTOs dans `data/remote/dtos/product_dtos.dart`, alignés exactement sur le contrat backend.

**Rationale**: Pattern identique aux autres features (subscription_dtos.dart, debt_dtos.dart). Freezed + json_serializable génère automatiquement `fromJson`/`toJson`.

**Champs ProductResponse** (JSON camelCase):
- `id` (String), `nom`, `description?`, `icone?`, `imageUrl?`
- `prixAchat` (double), `prixVente` (double)
- `stock` (int), `totalVendu` (int), `actif` (bool)
- `createdAt?` (String), `updatedAt?` (String)

**Alternatives considered**: Aucune — le pattern est standard dans le projet.
