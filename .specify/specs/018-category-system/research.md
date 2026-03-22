# Research: Système de Catégories

**Feature**: 018-category-system | **Date**: 2026-02-12

## R1 — Champ `isSystem` sur Category

**Decision**: Ajouter `is_system BOOLEAN DEFAULT FALSE NOT NULL` sur la table `categories`. Les catégories système appartiennent à un utilisateur (pas globales) et sont créées au register.

**Rationale**: Même table, même FK user — requêtes simples (pas de logique hybride `WHERE user_id = ? OR is_system = true`). Le flag `isSystem` suffit pour la protection (interdire delete/update si true).

**Alternatives considered**:
- Catégories globales (user_id NULL) : complexifie les requêtes JPA, nécessite un OR dans toutes les queries
- Table séparée `system_categories` : sur-ingénierie, duplication de structure
- Enum dans le code : pas extensible, pas de FK possible

## R2 — Seeding catégories système : Flyway + code

**Decision**: Approche hybride — Flyway pour utilisateurs existants, code Java pour les nouveaux.

**Rationale**:
- **Migration V5 (Flyway)** : Ajoute la colonne `is_system`, puis insère les 2 catégories système pour chaque utilisateur existant via `INSERT INTO categories ... SELECT id FROM users`.
- **AuthService.register()** : Après `userRepository.save(user)`, appel à `categoryService.seedSystemCategories(user)` qui crée les 2 catégories système.

Deux catégories système : "Abonnement" (🔄, #6366f1) et "Dette" (💰, #ef4444).

**Alternatives considered**:
- Seed uniquement via code (ApplicationRunner) : ne couvre pas les users existants en prod
- Seed uniquement Flyway + trigger SQL : trop couplé à la DB, difficilement testable
- Lazy creation : complexe, risque de race conditions

## R3 — Protection des catégories système

**Decision**: Dans `CategoryService`, vérifier `category.isSystem()` avant update et delete. Lever une `IllegalArgumentException` si tentative de modification/suppression. Le `GlobalExceptionHandler` existant mappe `IllegalArgumentException` → 400.

**Rationale**: Logique dans le service (pas le controller) pour que la protection s'applique partout. Simple et testable.

**Alternatives considered**:
- Annotation custom : sur-ingénierie
- Vérification dans le repository : pas de logique métier dans les repos

## R4 — Composant CategoryPicker : filtrage côté client

**Decision**: Composant standalone `CategoryPicker` implémentant `ControlValueAccessor`. Filtrage côté client via `signal()` + `computed()`. Dropdown positionné en `absolute` sous le champ (pas de CDK Overlay).

**Rationale**: ~50-100 catégories max → filtrage instantané en mémoire. `ControlValueAccessor` pour intégration native avec `formControlName`. Dropdown simple sans overlay car le picker est toujours dans une modal avec positionnement prévisible.

**Alternatives considered**:
- Filtrage serveur (debounce + HTTP) : latence inutile pour <100 items
- CDK Overlay : disproportionné pour ce use case
- Bibliothèque tierce (ng-select) : dépendance externe inutile (YAGNI)

## R5 — Grille d'emojis prédéfinis

**Decision**: ~35 emojis budget-pertinents, grille 6 colonnes, pas de bibliothèque externe.

**Emojis**: 🛒 🍽️ 🏠 🚗 🚌 ⛽ 🏥 💊 🎬 🎮 📚 🎓 👕 👟 💻 📱 ✈️ 🏖️ 🎵 🏋️ 💇 🐾 👶 🎁 💼 📦 🔧 🏦 💰 🔄 ⚡ 💧 📡 🛡️ ❓

**Rationale**: Emoji picker complet (~3600 emojis) est overkill. Grille curatée couvrant les domaines budget : alimentation, transport, logement, loisirs, santé, éducation, shopping, technologie, voyages, épargne, etc.

**Alternatives considered**:
- `emoji-mart` / `ngx-emoji-mart` : dépendance lourde (~200KB) pour un besoin simple
- Input texte libre pour coller un emoji : mauvaise UX mobile
- Pas d'emoji : perd l'identification visuelle rapide

## R6 — Palette de 12 couleurs harmonieuses

**Decision**: 12 couleurs hex prédéfinies, constante partagée backend + frontend. Attribution aléatoire à la création.

**Palette**:
| Nom | Hex |
|-----|-----|
| Red | #ef4444 |
| Orange | #f97316 |
| Amber | #f59e0b |
| Lime | #84cc16 |
| Emerald | #22c55e |
| Teal | #14b8a6 |
| Cyan | #06b6d4 |
| Blue | #3b82f6 |
| Indigo | #6366f1 |
| Violet | #8b5cf6 |
| Rose | #ec4899 |
| Stone | #78716c |

**Rationale**: Palette Tailwind-inspired, assurant bon contraste sur fond clair et sombre. Couleurs suffisamment distinctes pour identification visuelle.

**Alternatives considered**:
- Random RGB : risque de couleurs moches ou trop proches
- Sélecteur de couleur complet : complexité UI inutile pour V1

## R7 — Attribution catégorie par défaut (abonnements/dettes)

**Decision**: Attribution côté backend dans le service. Si `categoryId` est null dans la requête de création d'un abonnement/dette, le service résout la catégorie système correspondante.

**Rationale**: Garantit la cohérence même si l'API est appelée sans frontend. Logique métier dans le service, pas le controller.

**Alternatives considered**:
- Attribution côté frontend uniquement : risque d'inconsistance
- Attribution dans le controller : viole le pattern Service contient la logique métier

## R8 — Unicité nom case-insensitive

**Decision**: Index unique fonctionnel `UNIQUE (LOWER(nom), user_id)` en base. Contrainte existante `(nom, user_id)` remplacée. Vérification Java `equalsIgnoreCase` dans le service.

**Rationale**: La spec exige unicité insensible à la casse. L'index fonctionnel garantit l'unicité au niveau DB (pas de race condition). Le check Java donne un message d'erreur clair.

**Alternatives considered**:
- Normaliser en lowercase avant stockage : perd la casse originale
- Vérification Java seule : risque de race condition sans index

## R9 — Migration V5 : contenu

**Decision**: Migration `V5__add_is_system_and_seed.sql` contenant :
1. `ALTER TABLE categories ADD COLUMN is_system BOOLEAN DEFAULT FALSE NOT NULL`
2. `ALTER TABLE categories DROP CONSTRAINT uq_categories_nom_user`
3. `CREATE UNIQUE INDEX uq_categories_nom_user ON categories (LOWER(nom), user_id)`
4. `ALTER TABLE categories ALTER COLUMN nom TYPE VARCHAR(30)` (max 30 chars)
5. `INSERT INTO categories (id, nom, icone, couleur, is_system, user_id) SELECT gen_random_uuid(), 'Abonnement', '🔄', '#6366f1', true, id FROM users`
6. `INSERT INTO categories (id, nom, icone, couleur, is_system, user_id) SELECT gen_random_uuid(), 'Dette', '💰', '#ef4444', true, id FROM users`

**Rationale**: Un seul fichier de migration couvrant tous les changements schema + data pour cette feature.
