# Data Model: 054-flutter-settings-categories

**Date**: 2026-02-26

## Entités

### Category (existante — aucune modification)

| Attribut | Type | Contraintes | Description |
|----------|------|-------------|-------------|
| id | String (UUID) | PK, auto-generated | Identifiant unique |
| nom | String | NotBlank, max 30, unique par user (case-insensitive) | Nom de la catégorie |
| icone | String | NotBlank, max 50 | Emoji unicode |
| couleur | String | NotBlank, max 7, pattern `^#[0-9A-Fa-f]{6}$` | Code couleur hexadécimal |
| isSystem | bool | default false | Protection contre modification/suppression |
| updatedAt | DateTime? | auto-updated | Timestamp dernière modification |

### Relations

```
User 1───* Category
Category 1───* Transaction (FK nullable — dissociation à la suppression)
Category 1───* Subscription (FK nullable)
Category 1───* Debt (FK nullable)
```

### Catégories système (auto-créées)

| Nom | Icône | Couleur | Création |
|-----|-------|---------|----------|
| Abonnement | :repeat: | #6366f1 | À l'inscription |
| Dette | :moneybag: | #ef4444 | À l'inscription |
| Virement | :repeat: | #8b5cf6 | À l'inscription |
| Ajustement | :balance_scale: | #6b7280 | Au premier ajustement de solde |

### Règles métier

- **Unicité nom** : Deux catégories du même utilisateur ne peuvent pas avoir le même nom (comparaison case-insensitive)
- **Protection système** : Les catégories avec `isSystem=true` ne peuvent être ni modifiées ni supprimées
- **Suppression** : La suppression disssocie les éléments liés (transactions, abonnements, dettes) — gérée côté API
- **Tri** : Liste triée par nom alphabétique ascendant

## Modèles Flutter (existants)

### Domain Model — `Category` (Freezed)

```dart
@freezed
class Category {
  const factory Category({
    required String id,
    required String nom,
    required String icone,
    required String couleur,
    @Default(false) bool isSystem,
    DateTime? updatedAt,
  }) = _Category;
}
```

### Remote DTOs (Freezed + json_serializable)

```dart
@freezed
class CategoryRequest {
  const factory CategoryRequest({
    required String nom,
    required String icone,
    required String couleur,
  }) = _CategoryRequest;
}

@freezed
class CategoryResponse {
  const factory CategoryResponse({
    required String id,
    required String nom,
    required String icone,
    required String couleur,
    required bool isSystem,
    String? updatedAt,
  }) = _CategoryResponse;
}
```

## État de la couche données

| Composant | Fichier | Statut |
|-----------|---------|--------|
| Domain model | `domain/models/category.dart` | Existant |
| Repository interface | `domain/repositories/category_repository.dart` | Existant |
| Remote repository | `features/categories/data/category_repository_remote.dart` | Existant |
| Local repository | `features/categories/data/category_repository_local.dart` | Existant |
| Remote DTOs | `data/remote/dtos/category_dtos.dart` | Existant |
| Notifier | `features/categories/application/category_notifier.dart` | Existant |
| Data mode provider | `data/data_mode_provider.dart` (categoryRepositoryProvider) | Existant |

Aucune modification de la couche données n'est nécessaire.
