# Documentation feature — KKS-233 : Bootstrap du premier admin sur DB vide

> Date : 2026-04-22
> Issue : KKS-233
> Branche : `feature/KKS-233`
> Statut : prêt à merger (test manuel T-073 à exécuter avant)

---

## Résumé

Cette feature permet à un self-hoster tiers de démarrer une instance budget sur une base PostgreSQL vierge via `docker compose up -d` sans aucune commande additionnelle : l'application détecte automatiquement l'absence d'utilisateurs et crée un compte administrateur initial dont le mot de passe aléatoire est affiché dans les logs avec une bannière visible. Le nouvel admin est ensuite forcé de choisir ses credentials définitifs lors de sa première connexion via un écran Angular dédié. En parallèle, l'architecture du statut admin est refactorée : le rôle est désormais stocké directement en base (`users.is_admin`) plutôt que dérivé dynamiquement de la variable d'environnement `ADMIN_EMAILS`, qui devient une simple source de promotion au démarrage.

---

## Guide utilisateur

### Pour le self-hoster — premier démarrage

1. Cloner le repo et configurer `.env` (DB, JWT secret).
2. `docker compose up -d`
3. Récupérer le mot de passe initial :
   ```bash
   docker compose logs api | grep -A 5 "FIRST BOOT"
   ```
   Une bannière WARN multi-lignes affiche l'email (`admin@localhost` par défaut) et le mot de passe 32 chars.
4. Se connecter sur l'UI Angular avec ces credentials. Redirection automatique vers `/first-login-reset`.
5. Remplir le formulaire : email définitif, nouveau mot de passe, nom d'affichage. Redirection vers la racine, accès complet.

Variable d'env optionnelle : `BOOTSTRAP_EMAIL=votre@email.com` (avant le premier boot) pour personnaliser l'email initial. Format invalide → l'app échoue à démarrer avec un message clair.

### Pour un utilisateur ordinaire

Aucun impact. L'onboarding des autres utilisateurs reste le flux d'invitation admin (KKS-232) via `POST /auth/accept-invite`.

### Exemple de flux API

**Login avec credentials initiaux** :
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@localhost","password":"xQ9mK3vP7nR2wL8t5sH4jD8fG1bN6cY3"}'
```

Réponse 200 :
```json
{
  "token": "eyJ...",
  "refreshToken": "...",
  "email": "admin@localhost",
  "name": "Admin",
  "mustResetCredentials": true
}
```

**Reset forcé** :
```bash
curl -X POST http://localhost:8080/api/auth/first-login-reset \
  -H "Authorization: Bearer <token>" \
  -H 'Content-Type: application/json' \
  -d '{"email":"kelly@exemple.com","password":"NouveauPass123!","displayName":"Kelly"}'
```

Réponse 200 :
```json
{
  "token": "eyJ... (nouveau JWT sans claim mustResetCredentials)",
  "refreshToken": "...",
  "email": "kelly@exemple.com",
  "name": "Kelly",
  "mustResetCredentials": false
}
```

---

## Changements techniques

### Backend

**Nouveaux fichiers (10)**

| Fichier | Rôle |
|---------|------|
| `util/PasswordGenerator.java` | Générateur aléatoire 32 chars alphanumériques via `SecureRandom` |
| `config/BootstrapProperties.java` | `@ConfigurationProperties` + `@Validated` + `@Email` — fail-fast au démarrage si `BOOTSTRAP_EMAIL` invalide |
| `config/PasswordResetRequiredFilter.java` | Filtre HTTP dédié : bloque tout endpoint sauf `/auth/first-login-reset` + `/auth/logout` si le JWT porte le claim `mustResetCredentials` |
| `service/UserOnboardingService.java` | Factorise la séquence `User + Categories + Account + Preferences` — réutilisé par `AcceptInviteService` et `BootstrapSeedRunner` |
| `runner/BootstrapSeedRunner.java` | `ApplicationRunner @Order(1)` — seed le premier admin si DB vide |
| `runner/AdminSyncRunner.java` | `ApplicationRunner @Order(2)` — promeut les users listés dans `ADMIN_EMAILS` à `isAdmin=true`, jamais rétrogradation |
| `dto/request/FirstLoginResetRequest.java` | DTO record avec Bean Validation |
| `exception/PasswordUnchangedException.java` | Exception `400 PASSWORD_UNCHANGED` |
| `exception/PasswordResetNotRequiredException.java` | Exception `403 PASSWORD_RESET_NOT_REQUIRED` |
| `db/migration/V30__add_user_is_admin.sql` + `V31__add_user_password_reset_required.sql` | Migrations Flyway — 2 colonnes boolean sur `users` |

**Fichiers modifiés**

- `model/User.java` — ajout `isAdmin` et `passwordResetRequired`
- `config/JwtUtil.java` — surcharge `generateToken(email, extraClaims)` + `extractClaim`
- `config/AdminAuthorizationFilter.java` — refactor : lit `user.isAdmin()` au lieu de `adminEmailResolver.isAdminEmail(email)`
- `config/SecurityConfig.java` — enregistrement de `PasswordResetRequiredFilter` dans la chaîne (après `JwtFilter`, avant `AdminAuthorizationFilter`)
- `config/GlobalExceptionHandler.java` — handlers pour les deux nouvelles exceptions
- `controller/AuthController.java` — endpoint `POST /auth/first-login-reset`
- `dto/response/AuthResponse.java` — champ `mustResetCredentials`
- `service/UserService.java` — `toResponse` lit `user.isAdmin()`
- `service/AuthService.java` — méthode `firstLoginReset` + émission conditionnelle du claim JWT au login
- `service/AcceptInviteService.java` — délègue à `UserOnboardingService`, propage `mustResetCredentials=false`
- `service/RefreshTokenService.java` — propagation du claim et du champ
- `resources/application.yaml` — clé `app.bootstrap.email`

### Frontend Angular

**Nouveaux fichiers (7)**

| Fichier | Rôle |
|---------|------|
| `core/guards/password-reset.guard.ts` | Redirige vers `/first-login-reset` si flag actif |
| `core/guards/not-password-reset.guard.ts` | Redirige vers `/` si flag inactif — protège la route de reset |
| `features/auth/first-login-reset/first-login-reset.component.{ts,html,scss}` | Écran formulaire de reset forcé (4 champs) |
| Tests : `password-reset.guard.spec.ts`, `not-password-reset.guard.spec.ts`, `first-login-reset.component.spec.ts`, `features/auth/auth.spec.ts` |

**Fichiers modifiés**

- `core/models/auth.model.ts` — `AuthResponse.mustResetCredentials` + interface `FirstLoginResetRequest`
- `core/models/user.model.ts` — `UserInfo.mustResetCredentials`
- `core/services/auth.ts` — computed signal, persistance localStorage, méthode `firstLoginReset`
- `app.routes.ts` — route `/first-login-reset` + application du `passwordResetGuard` sur routes protégées
- `features/auth/auth.ts` — redirection post-login si `mustResetCredentials`

### Flutter

**Aucun impact.** Le client Flutter est indépendant du serveur Spring (mode auto-hébergé optionnel). Conformité FR-016 vérifiée : `git diff develop...HEAD -- flutter/` renvoie vide.

### Dépendances

**Aucune nouvelle dépendance** Maven ni npm. Conformité principe VII (Self-Hosted Ready).

---

## Configuration

### Variables d'environnement

| Variable | Obligatoire | Défaut | Description |
|----------|-------------|--------|-------------|
| `BOOTSTRAP_EMAIL` | Non | `admin@localhost` | Email du compte admin créé au premier boot sur DB vide. Format email requis, sinon fail-fast au démarrage. N'a d'effet que sur une instance vierge (après le premier seed, la variable est ignorée). |
| `ADMIN_EMAILS` | Non | vide | Liste d'emails séparés par virgules. Au démarrage, `AdminSyncRunner` promeut en admin les users correspondants (ajout uniquement, jamais de retrait). |

### Architecture admin

Le statut administrateur est désormais **autoritaire en base** (`users.is_admin`, boolean). `ADMIN_EMAILS` ne sert plus qu'à promouvoir au démarrage — un admin en base n'est jamais rétrogradé automatiquement. Conséquence pratique : un self-hoster qui change son email lors du reset conserve son accès admin même si son nouvel email n'apparaît pas dans `ADMIN_EMAILS`.

### Flow du JWT

- Login d'un user avec `password_reset_required=true` → JWT porte un claim `mustResetCredentials: true`.
- Requêtes avec ce JWT : `PasswordResetRequiredFilter` bloque tous les endpoints sauf `/auth/first-login-reset` et `/auth/logout` avec `403 PASSWORD_RESET_REQUIRED`.
- Succès du reset → nouveau JWT émis sans claim. L'ancien JWT devient inutile : le filtre continue à le reconnaître comme « reset required » et l'endpoint reset lui-même refuse car le flag DB est désormais à `false`.

### Sécurité

- Mot de passe initial : aléatoire 32 chars via `java.security.SecureRandom`, BCrypt pour le hash.
- Pas de default credentials dans le repo : chaque instance génère son propre password.
- Affichage unique dans les logs stdout au premier boot. En cas de redémarrage avant reset, le même mot de passe reste valide (pas de régénération, condition `userRepository.count() == 0`).
- Le self-hoster est responsable de purger les logs si persistés externe (Datadog, Loki).

---

## Tests et validation

### Tests automatisés

| Suite | Tests | Statut |
|-------|------:|--------|
| Backend — `mvn test` | 541 (dont ~37 nouveaux) | PASS |
| Frontend — `ng test` | 449 (dont ~16 nouveaux) | PASS |

**Nouveaux tests backend (par fichier)** :
- `PasswordGeneratorTest` (3) — longueur, alphabet, unicité
- `BootstrapPropertiesTest` (2) — fail-fast email invalide + succès email valide
- `BootstrapSeedRunnerTest` (7) — seed nominal, DB peuplée, BOOTSTRAP_EMAIL custom, idempotence, bannière WARN
- `AdminSyncRunnerTest` (4) — promotion, non-rétrogradation, idempotence, user inexistant
- `PasswordResetRequiredFilterTest` (6) — allowlist, 403 structuré, claim absent
- `AuthControllerFirstLoginResetIT` (11) — nominal, 400/403/409 structurés, blocage endpoints avec ancien JWT, E2E préservation admin post-reset
- `JwtUtilTest` (extension) — claims custom, extraction

**Nouveaux tests Angular** :
- Guards (`password-reset`, `not-password-reset`) — 4 tests
- `FirstLoginResetComponent` — 7 tests (rendu, submit, erreur, validateur égalité)
- `AuthService` — 3 tests (persistance localStorage, redirection post-login)

### Validation manuelle requise avant merge

**T-073 (SC-001)** : chronométrer le parcours complet sur DB vierge en profil `prod` — doit tenir en moins de 5 minutes. Procédure détaillée dans [`quickstart.md`](./quickstart.md). Attention : **ne pas utiliser le profil `dev`** car la migration repeatable `R__dev_seed.sql` crée un user `dev@local.test` qui empêche le déclenchement du `BootstrapSeedRunner`.

### Reviews passées

- `review-spec` : 2 itérations, PASS
- `review-tasks` : 1 itération, PASS
- `pre-commit-review` : PASS (0 critique, 0 warning)
- `frontend-design-review` : PASS (dette SCSS mutualisable consignée pour ticket futur)
- `review-impl` : 1 itération, PASS (corrections W-01/W-02/I-01 appliquées post-review)

---

## Points d'attention opérationnels

- **Profil dev** : le `BootstrapSeedRunner` ne se déclenche jamais car `R__dev_seed.sql` pré-crée un user. Pour tester le bootstrap, utiliser le profil `prod` (défaut).
- **Rollback migrations Flyway** : V30 et V31 ajoutent des colonnes `NOT NULL DEFAULT FALSE`. En cas de rollback, prévoir deux migrations inverses `DROP COLUMN` (non fournies ici, standard Flyway).
- **Logs persistés externes** : le mot de passe initial apparaît dans les logs stdout au premier boot. Curseur accepté par Kelly lors de la session sparring. Documenté dans `docs/deployment.md`.

---

## Dette technique consignée pour tickets futurs

- Mutualisation SCSS des layouts auth (`auth.scss` / `accept-invite.scss` / `first-login-reset.component.scss`) — duplication identifiée par `frontend-design-review`.
- Extraction d'un fichier `_buttons.scss` partagé.
- Attribut `aria-live="polite"` sur les blocs d'erreur des formulaires auth.
- `UserInfo` localStorage Angular n'inclut pas `isAdmin` — pré-existant KKS-232, à normaliser.
- Commande CLI de reset admin en cas de perte du mot de passe après le first-login-reset (hors scope ce ticket).
