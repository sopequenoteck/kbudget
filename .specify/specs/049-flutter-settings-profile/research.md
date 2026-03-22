# Research: Settings — Profil

**Feature**: 049-flutter-settings-profile | **Date**: 2026-02-23

## Résumé

Aucun NEEDS CLARIFICATION identifié dans le Technical Context. La recherche porte sur les patterns existants et les décisions d'architecture pour cette feature.

## Décisions

### 1. State management pour entité unique

**Decision**: Utiliser `Notifier<AsyncValue<User>>` au lieu de `ListState<T>`

**Rationale**: Le profil est une entité unique (pas une liste). `AsyncValue<User>` de Riverpod fournit nativement les états `loading`, `data`, `error` sans créer un state model custom. Plus simple que créer un `UserProfileState` Freezed dédié.

**Alternatives considered**:
- `Notifier<UserProfileState>` avec Freezed custom → Surdimensionné pour un seul objet. `AsyncValue` couvre déjà `isLoading`, `error`, `data`.
- `FutureProvider<User>` → Ne permet pas le refresh ni la mutation (save). Un Notifier est nécessaire pour les actions write.

### 2. Emplacement du repository et data source

**Decision**: Repository interface dans `domain/repositories/`, data source dans `data/remote/data_sources/`, implémentation remote dans `features/user_profile/data/`

**Rationale**: Suit exactement le pattern établi par `TransactionRepository`, `AccountRepository`, etc. Le data source est dans `data/remote/` (couche partagée), l'implémentation remote dans la feature (couche feature).

**Alternatives considered**:
- Tout dans `features/user_profile/` → Casse le pattern de séparation domain/data/feature du projet.
- Réutiliser `AuthRepository` → L'auth gère les tokens, pas le profil. Responsabilités distinctes.

### 3. Emplacement des DTOs

**Decision**: DTOs dans `data/remote/dtos/user_dtos.dart` (couche data partagée)

**Rationale**: Suit le pattern des `transaction_dtos.dart`, `account_dtos.dart`, etc. Les DTOs sont liés au transport réseau, pas à la feature.

**Alternatives considered**:
- DTOs dans `features/user_profile/data/` → Casse le pattern existant où tous les DTOs remote sont dans `data/remote/dtos/`.

### 4. Pas de repository local (Drift)

**Decision**: Le profil utilisateur n'a pas de `UserRepositoryLocal`. Toujours chargé depuis le serveur.

**Rationale**: Le profil est une donnée d'identité liée à l'authentification. Il n'a pas de sens en mode local (pas de user sans serveur). De plus, `UserUpdateRequest` ne modifie que `defaultCurrency` — donnée légère sans besoin de cache.

**Alternatives considered**:
- Cache local avec Drift → Complexité non justifiée pour une seule donnée rarement modifiée. YAGNI.

### 5. Gestion du bouton de sauvegarde

**Decision**: Bouton save dans l'AppBar (trailing action), actif uniquement quand la devise a changé.

**Rationale**: Pattern cohérent avec les écrans de formulaire existants (DebtFormScreen, TransactionFormScreen). Le profil n'a qu'un seul champ éditable, donc un bouton dédié en bas serait surdimensionné.

**Alternatives considered**:
- Sauvegarde automatique à la sélection → Pas de confirmation possible, risque d'erreurs accidentelles.
- Bouton save en bas de page → Surdimensionné pour un seul champ éditable.

### 6. Feedback utilisateur

**Decision**: SnackBar pour succès et erreur, via `ScaffoldMessenger`.

**Rationale**: Pattern utilisé partout dans l'app (DebtFormScreen, TransactionFormScreen). Cohérent et non intrusif.

**Alternatives considered**:
- Dialog de confirmation → Trop intrusif pour un simple changement de devise.
- Toast custom → Pas de widget custom toast dans le projet, SnackBar suffit.
