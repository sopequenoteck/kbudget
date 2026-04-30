# Data Model — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-04-30
> Issue : KKS-235
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

---

## Entités

### User (modifié — ajout 1 champ)

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| id | `UUID` | PK | Identifiant unique (existant) |
| email | `String` | NOT NULL, UNIQUE, max 255 | Email unique. **Immuable côté self-service** (cf. KKS-235 §FR-007) |
| name | `String` | NOT NULL, max 100 | Nom affiché (modifiable via `PUT /users/me`) |
| password | `String` | NOT NULL | Hash BCrypt (modifiable via `POST /users/me/password`) |
| isAdmin | `boolean` | NOT NULL, default false | Rôle admin (KKS-233, immuable côté self-service) |
| passwordResetRequired | `boolean` | NOT NULL, default false | Flag first-login-reset (KKS-233) |
| disabledAt | `LocalDateTime` | NULL | **Soft-delete** : si non-null, le user est désactivé (existant V29) |
| **avatarPath** | `String` | NULL, max 512 | **NOUVEAU (V32)** : chemin disque vers l'avatar (relatif à `app.storage.avatars.path`). NULL si user utilise les initiales générées. |
| createdAt | `LocalDateTime` | NOT NULL | Existant |
| updatedAt | `LocalDateTime` | NOT NULL | Existant |

**Invariants** :
- Si `disabledAt IS NOT NULL` → le user ne peut pas se connecter (filtre dans `AuthService.login` + `JwtFilter`).
- `avatarPath` doit pointer vers un fichier `.jpg` redimensionné 256x256 (RES-001 + RES-003).
- Email immuable côté API self-service (validé par DTO `UpdateProfileRequest` qui ne contient PAS de champ email — RES-007).
- Au moins 1 admin actif (`is_admin = true AND disabled_at IS NULL`) doit exister à tout instant (FR-021).

---

### Avatar (artefact — pas d'entité JPA)

L'avatar **n'est pas une entité JPA** : c'est un fichier binaire stocké sur disque, référencé par `User.avatarPath`. Pas de table dédiée.

| Caractéristique | Valeur |
|---|---|
| Format de sortie | JPEG ~85% qualité |
| Dimensions | 256 × 256 pixels |
| Nom de fichier | `{user_id}.jpg` |
| Chemin de stockage | `${app.storage.avatars.path}/{user_id}.jpg` |
| Taille typique | 30-60 KB |
| Cache HTTP | ETag SHA-256 (8 premiers chars) + `Cache-Control: private, must-revalidate, max-age=0` |

**Invariants** :
- Le fichier `${user.avatarPath}` doit exister sur disque tant que `User.avatarPath IS NOT NULL`.
- À la suppression d'un user (soft-delete) : le fichier reste sur disque (auditabilité). À une éventuelle hard-delete future : suppression du fichier dans la même transaction.

---

### UserExportResponse (DTO export — pas d'entité JPA)

Structure du payload JSON export utilisateur (FR-017a).

| Champ top-level | Type | Description |
|---|---|---|
| schemaVersion | `String` | SemVer du format export. Initial : `"1.0.0"` |
| exportedAt | `String` (ISO-8601) | Timestamp de génération de l'export |
| user | `UserDto` | Profil user (sans `password` — exclu via `@JsonIgnore` ou DTO dédié) |
| preferences | `UserPreferenceDto` | Préférences user |
| accounts | `List<AccountDto>` | Tous les comptes du user |
| categories | `List<CategoryDto>` | Toutes les catégories du user |
| transactions | `List<TransactionDto>` | Toutes les transactions |
| budgets | `List<BudgetDto>` | Tous les budgets |
| budgetSnapshots | `List<BudgetSnapshotDto>` | Snapshots historiques |
| subscriptions | `List<SubscriptionDto>` | Abonnements |
| debts | `List<DebtDto>` | Dettes |
| categoryRules | `List<CategoryRuleDto>` | Règles d'auto-catégorisation |
| importProfiles | `List<ImportProfileDto>` | Profils d'import CSV |
| importHistory | `List<ImportHistoryDto>` | Historique d'imports |
| invitations | `List<InvitationDto>` | Invitations envoyées (résolution I-004 review-spec) |

**Invariants** :
- `user.password` JAMAIS exposé (sécurité — voir R-007 du plan).
- Toutes les `List<>` sont vides (pas null) si aucune donnée.
- L'ordre des entités top-level dans le JSON est stable (lisibilité diff).

---

## Relations

```
User --1:N--> RefreshToken          (existant, +CASCADE V35)
User --1:N--> Account               (existant)
User --1:N--> Category              (existant)
User --1:N--> Transaction           (existant)
User --1:N--> Budget                (existant, +CASCADE V33)
User --1:N--> BudgetSnapshot        (existant, +CASCADE V34)
User --1:N--> Subscription          (existant)
User --1:N--> Debt                  (existant)
User --1:N--> Notification          (existant, CASCADE)
User --1:1--> UserPreference        (existant, CASCADE)
User --1:N--> Invitation            (existant invited_by_user_id, RESTRICT)
User --1:N--> CategoryRule          (existant, CASCADE)
User --1:N--> ExchangeRate          (existant, CASCADE)
User --1:N--> ImportDraft           (existant, CASCADE)
User --1:N--> ImportHistory         (existant, CASCADE)
User --1:N--> ImportProfile         (existant, CASCADE)
User --1:0..1--> Avatar (file)      (NOUVEAU, fichier disque référencé par avatar_path)
```

| Relation | Type | Cardinalité | Contrainte |
|----------|------|-------------|------------|
| User → RefreshToken | FK `user_id` | 1:N | **NEW V35** : `ON DELETE CASCADE` (cohérence soft/hard delete) |
| User → Budget | FK `user_id` | 1:N | **NEW V33** : `ON DELETE CASCADE` (filet de sécurité audit isolation) |
| User → BudgetSnapshot | FK `user_id` | 1:N | **NEW V34** : `ON DELETE CASCADE` (idem) |
| User → Avatar (file) | Référence par path string | 1:0..1 | Pas de FK DB. Cohérence applicative gérée par `AvatarStorageService`. |

---

## Contraintes globales

| # | Contrainte | Type | Entités concernées |
|---|-----------|------|-------------------|
| DC-001 | `User.email` UNIQUE (existant) | Unicité | User |
| DC-002 | `User.disabledAt IS NULL` requis pour authentification (filter applicatif) | Business | User, Auth |
| DC-003 | Au moins 1 user avec `is_admin = true AND disabled_at IS NULL` à tout instant | Business | User |
| DC-004 | Email immuable côté self-service (DTO `UpdateProfileRequest` n'expose pas le champ email) | Business / API | User |
| DC-005 | Avatar fichier disque cohérent avec `User.avatarPath` (existence) | Filesystem | User, Avatar |
| DC-006 | Refresh tokens du user révoqués au change-password (FR-023) | Business | User, RefreshToken |
| DC-007 | Refresh tokens du user révoqués au soft-delete (FR-019) | Business | User, RefreshToken |

---

## Migrations

### V32 — Add `users.avatar_path`

```sql
-- UP
ALTER TABLE users
  ADD COLUMN avatar_path VARCHAR(512) NULL;

COMMENT ON COLUMN users.avatar_path IS
  'Chemin relatif vers l''avatar du user (référence au fichier disque). NULL = initiales générées.';

-- DOWN
-- ALTER TABLE users DROP COLUMN avatar_path;
```

### V33 — Patch `budgets.user_id` → `ON DELETE CASCADE`

```sql
-- UP
-- Drop existing FK (nom à vérifier au moment du dev — Spring/Hibernate génère des noms standardisés)
ALTER TABLE budgets
  DROP CONSTRAINT IF EXISTS fk_budgets_user;

ALTER TABLE budgets
  ADD CONSTRAINT fk_budgets_user
  FOREIGN KEY (user_id) REFERENCES users(id)
  ON DELETE CASCADE;

-- DOWN
-- ALTER TABLE budgets DROP CONSTRAINT fk_budgets_user;
-- ALTER TABLE budgets ADD CONSTRAINT fk_budgets_user FOREIGN KEY (user_id) REFERENCES users(id);
```

### V34 — Patch `budget_snapshots.user_id` → `ON DELETE CASCADE`

```sql
-- UP
ALTER TABLE budget_snapshots
  DROP CONSTRAINT IF EXISTS fk_budget_snapshots_user;

ALTER TABLE budget_snapshots
  ADD CONSTRAINT fk_budget_snapshots_user
  FOREIGN KEY (user_id) REFERENCES users(id)
  ON DELETE CASCADE;

-- DOWN
-- ALTER TABLE budget_snapshots DROP CONSTRAINT fk_budget_snapshots_user;
-- ALTER TABLE budget_snapshots ADD CONSTRAINT fk_budget_snapshots_user FOREIGN KEY (user_id) REFERENCES users(id);
```

### V35 — Patch `refresh_tokens.user_id` → `ON DELETE CASCADE`

```sql
-- UP
-- Vérifier d'abord si la cascade existe déjà (audit RES-008 a indiqué absente)
ALTER TABLE refresh_tokens
  DROP CONSTRAINT IF EXISTS fk_refresh_tokens_user;

ALTER TABLE refresh_tokens
  ADD CONSTRAINT fk_refresh_tokens_user
  FOREIGN KEY (user_id) REFERENCES users(id)
  ON DELETE CASCADE;

-- DOWN
-- ALTER TABLE refresh_tokens DROP CONSTRAINT fk_refresh_tokens_user;
-- ALTER TABLE refresh_tokens ADD CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id);
```

---

## Index

Aucun nouvel index nécessaire. L'ajout de `users.avatar_path` ne requiert pas d'index (lookup par `user_id` qui est déjà PK indexée).

| Table | Colonnes | Type | Justification |
|-------|----------|------|---------------|
| (aucun) | — | — | — |

---

## Notes complémentaires

### Migration MIG-001 (`users.disabled_at`) supprimée du scope

Audit RES-009 a révélé que `users.disabled_at` est **déjà appliqué** via `V29__add_user_disabled_at.sql`. La spec listait initialement 4 migrations + 1 alignement MDP, en réalité 4 nouvelles migrations sont à créer (V32 à V35) avec une migration en plus par rapport à la spec (V35 cascade refresh tokens, découverte audit RES-008).

### Sérialisation Jackson — exclusion du password

Pour respecter le risque R-007 du plan (export ne doit pas exposer le hash password) :
- Solution préférée : DTO `UserExportResponse.UserDto` qui ne contient QUE les champs publics (id, email, name, isAdmin, createdAt, etc.). Pas de mapping direct de l'entité JPA.
- Solution alternative : annoter `User.password` avec `@JsonIgnore` (mais nécessite vigilance sur tous les futurs champs sensibles).

### Cohérence filesystem ↔ DB

`User.avatarPath` peut théoriquement diverger du filesystem (ex: fichier supprimé manuellement par admin). Stratégie de résilience :
- `GET /users/me/avatar` : si fichier absent, retourner `404 AVATAR_NOT_FOUND` et laisser le frontend afficher les initiales.
- Pas de tentative de "réparer" automatiquement la DB (principe YAGNI). Un script de maintenance admin pourra corriger les divergences si besoin futur.
