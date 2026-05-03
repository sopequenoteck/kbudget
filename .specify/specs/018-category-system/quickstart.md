# Quickstart: Système de Catégories

**Feature**: 018-category-system | **Date**: 2026-02-12

## Prérequis

- Java 21 + Maven
- Node.js 20+ + npm
- PostgreSQL 15+ (local ou Docker)
- Backend et frontend existants fonctionnels

## Démarrage rapide

### 1. Backend

```bash
cd api
mvn clean compile   # Compilation avec les modifications (Category.isSystem, migration V5)
mvn spring-boot:run # Lancer le backend (profil dev — Flyway exécute V5 automatiquement)
```

### 2. Frontend

```bash
cd app
npm install         # Si nouvelles dépendances
ng serve            # Dev server http://localhost:4200
```

### 3. Vérification

1. **Register** → les catégories système "Abonnement" et "Dette" sont créées automatiquement
2. **GET /api/categories** → retourne au moins les 2 catégories système avec `isSystem: true`
3. **POST /api/categories** → créer une catégorie personnalisée (couleur de la palette)
4. **DELETE /api/categories/{id-système}** → 400 (catégorie système protégée)
5. **PUT /api/categories/{id-système}** → 400 (catégorie système non modifiable)
6. **Frontend** → formulaire Transaction → le CategoryPicker autocomplete affiche les catégories avec emojis
7. **Création à la volée** → taper un nom inexistant → "Créer X" → modal emoji picker → catégorie créée et sélectionnée
8. **Paramètres** → naviguer vers /settings → section catégories → CRUD complet

## Tests

### Backend

```bash
cd api
mvn test                                    # Tous les tests
mvn test -Dtest=CategoryServiceTest          # Tests service catégories
```

### Frontend

```bash
cd app
npx vitest run                               # Tous les tests
npx vitest run --reporter=verbose category   # Tests liés aux catégories
```

## Points de validation

| Critère | Comment vérifier |
|---------|-----------------|
| Migration V5 exécutée | Vérifier `is_system` colonne dans table `categories` |
| Catégories système créées (users existants) | `SELECT * FROM categories WHERE is_system = true` |
| Catégories système créées au register | Créer un user, GET /api/categories |
| Protection suppression système | DELETE /api/categories/{system-id} → 400 |
| Protection modification système | PUT /api/categories/{system-id} → 400 |
| Unicité case-insensitive | POST deux catégories "courses" et "Courses" → 400 sur la 2e |
| Autocomplete filtre en temps réel | Taper dans le CategoryPicker, vérifier filtrage instantané |
| Création à la volée | Taper nom inexistant → "Créer X" → modal → valider |
| Emoji dans les listes | Consulter la liste des transactions → emoji visible |
| Catégorie par défaut abonnement | POST /subscriptions sans categoryId → catégorie "Abonnement" |
| Catégorie par défaut dette | POST /debts sans categoryId → catégorie "Dette" |
| Gestion dans Paramètres | /settings → section catégories → lister, modifier, supprimer |
