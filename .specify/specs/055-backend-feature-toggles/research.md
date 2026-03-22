# Research: Système de Feature Toggles — Backend

**Branch**: `055-backend-feature-toggles` | **Date**: 2026-02-27

## R1 — Stockage des listes d'enums en JPA

**Decision**: Colonnes `VARCHAR` avec `AttributeConverter` personnalisé pour convertir `List<Feature>` ↔ chaîne séparée par virgules.

**Rationale**: Avec seulement 3 valeurs possibles (SUBSCRIPTIONS, DEBTS, SHOP), une table de jointure (`@ElementCollection`) serait sur-dimensionnée. Un converter simple sur une colonne string est plus lisible, plus facile à débugger en BDD, et ne nécessite aucune table supplémentaire.

**Alternatives considered**:
- `@ElementCollection` + `@CollectionTable` : crée 2 tables de jointure pour 3 valeurs max — complexité disproportionnée
- Colonnes booléennes individuelles (`subscriptionsEnabled`, `debtsEnabled`, `shopEnabled`) : simple mais nécessite une migration pour chaque nouvelle feature
- Colonne PostgreSQL `text[]` (array natif) : non portable, dépendance Hibernate spécifique
- Colonne JSON (`jsonb`) : flexible mais complexifie les requêtes et la validation

## R2 — Relation UserPreference ↔ User

**Decision**: Table séparée `user_preferences` avec relation `@OneToOne` vers `users`. Clé étrangère `user_id` unique et non-nullable.

**Rationale**: Sépare les préférences de personnalisation du profil utilisateur. Permet d'ajouter de nouvelles préférences sans modifier la table `users`. Le spec définit explicitement UserPreference comme entité distincte.

**Alternatives considered**:
- Enrichir la table `users` avec des colonnes supplémentaires : plus simple mais mélange profil et préférences, complexifie la table principale à long terme
- Table de configuration key-value : trop générique, perd le typage

## R3 — Gestion du navOrder optionnel dans le PUT

**Decision**: Le champ `navOrder` est nullable dans le request DTO. Le service applique la logique :
- Si `navOrder` fourni : valider la cohérence avec `enabledFeatures` (doit contenir exactement les features activées, sans doublons)
- Si `navOrder` absent (null) : auto-gérer (retirer les features désactivées, ajouter les nouvelles en dernière position)

**Rationale**: Clarifié lors de la session de clarification spec (Option A). Simplifie le contrat client pour les cas d'activation/désactivation simples.

**Alternatives considered**:
- navOrder toujours requis (Option B) : impose au client de gérer l'ordre même pour un simple toggle
- navOrder auto-corrigé (Option C) : le client envoie un navOrder potentiellement incohérent que le backend corrige — comportement imprévisible

## R4 — Initialisation des préférences pour les utilisateurs existants

**Decision**: Migration Flyway insère un enregistrement `user_preferences` pour chaque utilisateur existant avec les valeurs par défaut (toutes features activées, ordre standard). Le service gère le cas "lazy init" avec un `getOrCreate` pour les futurs utilisateurs créés avant que le register flow ne soit mis à jour.

**Rationale**: Garantit la cohérence des données. Tous les utilisateurs ont des préférences dès le déploiement de la migration. Le fallback lazy init est un filet de sécurité supplémentaire.

**Alternatives considered**:
- Lazy init uniquement (créer à la première consultation) : risque de NPE si un autre service interroge les préférences avant la première consultation
- Modifier le flow register pour créer les préférences : nécessaire mais insuffisant pour les utilisateurs existants

## R5 — Placement des endpoints

**Decision**: Nouveau `PreferenceController` mappé sur `/users/me/preferences`. Ne pas ajouter au `UserController` existant.

**Rationale**: Le `UserController` gère le profil utilisateur (nom, email, mot de passe, devise). Les préférences de fonctionnalités sont un domaine distinct. Un controller séparé respecte le principe de responsabilité unique et garde chaque controller focalisé.

**Alternatives considered**:
- Ajouter au `UserController` : plus de méthodes dans un controller déjà existant, mélange profil et préférences
