# Data Model — KKS-233 : Bootstrap du premier admin sur DB vide

> Annexe du [plan.md](./plan.md)
> Date : 2026-04-22

---

## Vue d'ensemble

Ce ticket modifie **une seule entité existante** (`User`) en y ajoutant deux colonnes. Aucune nouvelle entité, aucune nouvelle table, aucune relation modifiée. Deux migrations Flyway dédiées.

---

## Entité `User` — modifications

### Champs ajoutés

| Colonne DB | Type Java | Contraintes DB | Valeur par défaut | Description |
|------------|-----------|----------------|-------------------|-------------|
| `is_admin` | `boolean` | `NOT NULL` | `FALSE` | Statut administrateur autoritaire en base. Remplace la résolution dynamique via `ADMIN_EMAILS`. Mis à `TRUE` au seed bootstrap et par `AdminSyncRunner` pour les users dont l'email figure dans `ADMIN_EMAILS`. Jamais rétrogradé (pas de passage `TRUE → FALSE` automatique). |
| `password_reset_required` | `boolean` | `NOT NULL` | `FALSE` | Flag imposant le reset des credentials à la première connexion. Mis à `TRUE` au seed bootstrap uniquement. Remis à `FALSE` après succès de l'endpoint `POST /api/auth/first-login-reset`. |

### Schéma complet de `users` après migration V31

```
users
├── id                        UUID        PRIMARY KEY
├── email                     VARCHAR     NOT NULL UNIQUE
├── password                  VARCHAR     NOT NULL
├── name                      VARCHAR
├── created_at                TIMESTAMP   NOT NULL (default now)
├── disabled_at               TIMESTAMP   nullable
├── is_admin                  BOOLEAN     NOT NULL DEFAULT FALSE    ← NOUVEAU (V30)
└── password_reset_required   BOOLEAN     NOT NULL DEFAULT FALSE    ← NOUVEAU (V31)
```

### Mapping JPA (entité `User.java`)

```java
@Entity
@Table(name = "users")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class User {

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String name;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "disabled_at")
    private LocalDateTime disabledAt;

    @Column(name = "is_admin", nullable = false)
    private boolean isAdmin;                    // NOUVEAU

    @Column(name = "password_reset_required", nullable = false)
    private boolean passwordResetRequired;      // NOUVEAU
}
```

Lombok `@Data` génère les accesseurs `isAdmin()`, `setAdmin(boolean)`, `isPasswordResetRequired()`, `setPasswordResetRequired(boolean)`.

---

## Migrations Flyway

### `V30__add_user_is_admin.sql`

```sql
ALTER TABLE users
  ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE;
```

**Rationale** :
- `NOT NULL` car le champ est autoritaire et toujours défini (pas de tri-valeur).
- `DEFAULT FALSE` : tous les users existants en production partent en non-admin. La promotion des admins est ensuite effectuée par `AdminSyncRunner` au prochain démarrage (FR-012b) — pas par la migration (FR-012a).
- Zéro opération data dans la migration (conforme FR-012a).

### `V31__add_user_password_reset_required.sql`

```sql
ALTER TABLE users
  ADD COLUMN password_reset_required BOOLEAN NOT NULL DEFAULT FALSE;
```

**Rationale** :
- `NOT NULL DEFAULT FALSE` : aucun user existant ne doit se retrouver avec un reset forcé. Seul le user seedé par `BootstrapSeedRunner` aura ce flag à `TRUE`.
- Migration distincte de V30 pour séparer les concepts orthogonaux (rôle admin vs exigence de reset).

---

## Invariants post-migration

1. **Unicité admin seed** : après le premier démarrage sur DB vide, la table `users` contient exactement **un** enregistrement avec `is_admin = TRUE AND password_reset_required = TRUE`.
2. **Cohérence post-reset** : après un appel réussi à `POST /api/auth/first-login-reset`, aucun user en DB ne doit conserver `password_reset_required = TRUE` pour le user concerné.
3. **Non-rétrogradation** : `AdminSyncRunner` ne doit jamais exécuter `UPDATE users SET is_admin = FALSE`. Seul un `UPDATE users SET is_admin = TRUE WHERE ...` est permis.
4. **Idempotence du seed** : la condition `SELECT COUNT(*) FROM users = 0` garantit qu'aucun `INSERT` seed n'a lieu après le premier démarrage.

---

## Relations et dépendances

Aucune modification des relations existantes. Les associations `User → Account`, `User → Preferences`, `User → Invitation`, etc. restent inchangées.

Le `UserOnboardingService.provisionUser` crée le user **et** les entités satellites dans la même transaction (`@Transactional`) :

- `User` (via `UserRepository.save`)
- `Categories` (système, via `CategoryService.seedSystemCategories`)
- `Account` (défaut, via `AccountService.createDefaultAccount`)
- `Preferences` (initiales, via `PreferenceService.createInitialPreference`)

En cas d'échec partiel (ex : exception dans `PreferenceService`), la transaction rollback l'ensemble : pas de user orphelin sans categories / account / preferences.

---

## Impact sur les entités existantes

| Entité | Impact |
|--------|--------|
| `User` | Ajout 2 colonnes (cf. supra) |
| `Account` | Aucun changement |
| `Preferences` | Aucun changement |
| `Invitation` | Aucun changement |
| `Category` | Aucun changement |
| `RefreshToken` | Aucun changement |
| Autres (Transaction, Budget, Debt, etc.) | Aucun changement |

---

## Numérotation Flyway — prochaine disponible

Après ce ticket, la prochaine migration doit utiliser `V32`.
