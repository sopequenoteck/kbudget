# Research: 056-backend-product-crud

**Date**: 2026-02-27

## R1: Feature Toggle Backend Enforcement

**Decision**: Vérification au niveau du service via `PreferenceService.isFeatureEnabled(userId, Feature)`.

**Rationale**: La spec FR-013 exige que les endpoints Product soient protégés par le toggle `SHOP`. Actuellement, le toggle est uniquement vérifié côté frontend. L'approche la plus simple est une méthode dans `PreferenceService` appelée par `ProductService`, conformément au principe YAGNI (pas d'AOP/annotation pour un seul cas d'usage). Si nécessaire, on pourra évoluer vers une annotation `@RequiresFeature` ultérieurement.

**Alternatives considered**:
- Annotation AOP `@RequiresFeature` sur le controller : plus élégant mais sur-ingénierie pour un seul feature toggle côté backend.
- Filter HTTP dédié : trop couplé à la couche web, nécessite accès au contexte utilisateur.
- Check dans le controller : possible mais viole la séparation des responsabilités (validation métier dans le controller).

## R2: Mécanisme de vérification du toggle

**Decision**: Ajouter `isFeatureEnabled(UUID userId, Feature feature)` dans `PreferenceService`. Lever `FeatureDisabledException` (nouvelle exception) mappée vers 403 FORBIDDEN dans le `GlobalExceptionHandler`.

**Rationale**: Cohérent avec le pattern existant d'exceptions métier (`EntityNotFoundException` → 404, `AccessDeniedException` → 403). Une exception dédiée permet un message d'erreur clair ("Fonctionnalité SHOP désactivée").

**Alternatives considered**:
- `AccessDeniedException` générique : confond le manque d'autorisation avec la désactivation d'une feature.
- Code HTTP 404 : sémantiquement incorrect, la ressource existe mais la fonctionnalité est désactivée.

## R3: Flyway Migration Version

**Decision**: `V10__add_products.sql` — prochaine version disponible après V9.

**Rationale**: Migrations existantes V1-V9. V10 est le prochain numéro séquentiel.

## R4: Feature Enum — Valeur SHOP

**Decision**: `SHOP` existe déjà dans l'enum `Feature`. Aucune modification nécessaire.

**Rationale**: Ajouté lors de KKS-117 (feature toggles). Les valeurs par défaut de `UserPreference` incluent déjà `SHOP`.

## R5: Pattern Entity — Timestamps

**Decision**: Utiliser `@UpdateTimestamp` (Hibernate) pour `updatedAt` et `@CreationTimestamp @Column(nullable = false, updatable = false)` pour `createdAt`.

**Rationale**: Pattern cohérent avec les entités existantes (User, RefreshToken pour `createdAt` ; Transaction, Account, etc. pour `updatedAt`). Les deux annotations sont gérées automatiquement par Hibernate.

## R6: imageUrl — Type et Validation

**Decision**: `VARCHAR(500)` sans validation de format URL côté backend. Validation de longueur uniquement (`@Size(max = 500)`).

**Rationale**: Champ optionnel, pas de téléversement d'image pour cette phase. La validation de format URL est fragile et mieux gérée côté frontend. Longueur max cohérente avec le champ description.
