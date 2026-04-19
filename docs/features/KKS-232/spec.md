# Spec — KKS-232 : Onboarding contrôlé : flux d'invitation admin (remplace inscription publique)

> Date : 2026-04-19
> Issue : KKS-232
> Priorité : High
> Labels : Frontend, Security, Backend, Feature

<!-- Convention : Utiliser le marqueur [NEEDS CLARIFICATION: description] pour signaler
     les points nécessitant une clarification. Maximum 3 marqueurs par spec.
     Format : [NEEDS CLARIFICATION: description courte du point à clarifier]
     Ces marqueurs seront résolus à l'étape /devflow.clarify. -->

---

## Contexte

L'inscription publique actuelle (`POST /api/auth/register`) viole la constitution v2.1.2 (principe VII + Contexte d'usage) : l'onboarding doit se faire via création de compte contrôlée par l'administrateur du serveur. Le projet est self-hosted, multi-user restreint (~16 comptes), sans inscription publique.

Cette feature remplace le flux ouvert par un mécanisme d'**invitation par lien** contrôlé par un user admin :
- L'admin génère un lien d'invitation pour un email donné.
- Il transmet le lien via un canal externe (Signal, SMS, etc.) — pas d'envoi d'email par l'app (principe VII, pas de SMTP en v1).
- Le user destinataire clique, remplit ses infos, et son compte est créé (User + Account par défaut + Preferences, réutilise la logique de la feature `100-register-currency-timezone`).
- L'admin peut révoquer une invitation ou désactiver un user existant (soft-disable).

**Décisions actées (session sparring)** :
- Rôle admin désigné par `app.admin-emails` (env var `ADMIN_EMAILS`). Pas de colonne `role` sur `User` (YAGNI tant qu'il n'y a qu'un niveau).
- Entité `Invitation` avec token UUID v4 stocké en DB (révocable, traçable). Usage unique. TTL 7 jours. Email pré-rempli et verrouillé à l'acceptation.
- Désactivation user via colonne `disabled_at` (soft-disable). `JwtAuthenticationFilter` renvoie 401 si non-null. Garde-fou : un admin ne peut pas se désactiver s'il est le dernier admin actif.
- `POST /api/auth/register` supprimé. `RegisterRequest` renommé / remplacé par `AcceptInviteRequest`.
- Comparables self-hosted : Gitea, Forgejo, Vaultwarden.

**Hors scope** (tickets séparés) :
- Bootstrap du tout premier admin sur DB vide (pour autres self-hosters).
- Envoi d'email automatique des invitations (SMTP).
- Rotation / multi-admin management UI avancée.

## User Stories

### P1 — Critiques

- **US-001** : En tant qu'**admin**, je veux **inviter un nouveau user en saisissant son email**, afin de **générer un lien d'invitation à lui transmettre manuellement**.
  - **Why this priority** : Sans ce flux, aucun nouveau user ne peut rejoindre l'instance après la suppression de `POST /auth/register` — bloquant pour l'onboarding.
  - **Given** je suis authentifié et mon email figure dans `ADMIN_EMAILS`
  - **When** j'appelle `POST /api/admin/invitations` avec `{ email: "new@example.com" }`
  - **Then** le serveur crée une entrée `Invitation` (token UUID v4, `expiresAt = now + 7j`) et me renvoie `{ token, expiresAt }` que j'intègre dans un lien `/accept-invite/:token` à copier.
  - **Independent Test** : Créer une invitation via admin, vérifier le retour JSON et la présence de l'entrée en base avec les champs attendus.

- **US-002** : En tant qu'**invité**, je veux **accepter une invitation via son lien**, afin de **créer mon compte et être connecté automatiquement**.
  - **Why this priority** : C'est l'unique point d'entrée pour un nouveau user après la suppression de l'inscription publique.
  - **Given** je dispose d'un token d'invitation valide (non expiré, non utilisé, non révoqué)
  - **When** j'ouvre la page `/accept-invite/:token`, je vois mon email pré-rempli et verrouillé, et je soumets `{ password, displayName, currency, timezone }` via `POST /api/auth/accept-invite`
  - **Then** le serveur crée `User` + `Account` par défaut + `Preferences`, marque l'invitation comme `usedAt = now`, et me retourne un JWT (auto-login).
  - **Independent Test** : Créer une invitation fixture, POSTer `accept-invite` avec des données valides, vérifier la création des 3 entités + token JWT retourné.

- **US-003** : En tant qu'**admin**, je veux **révoquer une invitation non-utilisée**, afin d'**annuler l'accès avant son expiration naturelle**.
  - **Why this priority** : Besoin opérationnel si l'admin change d'avis ou si le lien est suspecté compromis.
  - **Given** une invitation active existe
  - **When** j'appelle `DELETE /api/admin/invitations/:id`
  - **Then** l'invitation est marquée `revokedAt = now` (pas de hard delete) et `GET /api/auth/invitations/:token` retourne 404 sur ce token.
  - **Independent Test** : Créer une invitation, appeler `DELETE`, vérifier que `GET /api/auth/invitations/:token` renvoie 404.

- **US-004** : En tant qu'**admin**, je veux **désactiver un user existant**, afin de **lui couper l'accès sans supprimer ses données**.
  - **Why this priority** : Principe de sécurité — révoquer l'accès d'un user qui ne doit plus utiliser l'instance (départ, compromission).
  - **Given** un user `U` est actif (`disabled_at IS NULL`) et je suis admin
  - **When** j'appelle `PATCH /api/admin/users/:id/disable`
  - **Then** le user `U` reçoit `disabled_at = now`. Toute requête authentifiée avec son JWT renvoie 401. Ses données restent en base.
  - **Independent Test** : Désactiver un user fixture, tenter un appel authentifié avec son JWT → attendu 401.

- **US-005** : En tant qu'**admin**, je veux **réactiver un user désactivé**, afin de **restaurer son accès**.
  - **Why this priority** : Symétrie opérationnelle de US-004 (désactivation temporaire, erreur admin).
  - **Given** un user `U` est désactivé (`disabled_at` non null)
  - **When** j'appelle `PATCH /api/admin/users/:id/enable`
  - **Then** le user `U` a `disabled_at = NULL` et peut à nouveau se connecter (login émet un nouveau JWT utilisable).
  - **Independent Test** : Désactiver puis réactiver un user, tenter une connexion post-réactivation → JWT valide.

- **US-006** : En tant que **user non-admin**, je ne **dois pas pouvoir accéder aux endpoints `/api/admin/*`**, afin de **préserver la séparation des privilèges**.
  - **Why this priority** : Contrôle d'accès fondamental — sans ce garde-fou, n'importe quel user peut inviter / désactiver.
  - **Given** je suis authentifié et mon email ne figure pas dans `ADMIN_EMAILS`
  - **When** j'appelle n'importe quel endpoint `/api/admin/*`
  - **Then** le serveur renvoie 403 Forbidden sans exposer d'info interne.
  - **Independent Test** : Fixture user non-admin, tenter chaque endpoint admin, attendre 403 à chaque fois.

- **US-007** : En tant qu'**admin**, je ne **dois pas pouvoir me désactiver moi-même si je suis le dernier admin actif**, afin de **garantir qu'il reste toujours au moins un admin opérationnel**.
  - **Why this priority** : Garde-fou critique — sinon l'instance peut se retrouver sans admin et aucune invitation ne pourra plus être émise.
  - **Given** je suis admin et je suis le seul admin dont l'email figure dans `ADMIN_EMAILS` et dont le user est actif
  - **When** j'appelle `PATCH /api/admin/users/:id/disable` avec mon propre id
  - **Then** le serveur refuse l'opération avec HTTP 409 Conflict et un body `{ error: "LAST_ADMIN_CANNOT_BE_DISABLED", message: "Impossible de désactiver le dernier admin actif." }` — conforme au pattern `ConflictException` existant.
  - **Independent Test** : Fixture mono-admin, tenter self-disable, attendre refus avec message clair.

- **US-008** : En tant qu'**admin**, je veux **consulter la liste des invitations**, afin de **suivre l'état du flux d'onboarding**.
  - **Why this priority** : Observabilité opérationnelle — sans cette liste, impossible de retrouver un lien émis ou de savoir qui a été invité.
  - **Given** plusieurs invitations existent (actives, expirées, révoquées, utilisées)
  - **When** j'appelle `GET /api/admin/invitations`
  - **Then** je reçois la liste complète triée par `createdAt DESC`, chaque entrée incluant : id, email, invitedByEmail, createdAt, expiresAt, usedAt, revokedAt, et un champ `status` dérivé côté serveur (`ACTIVE` / `EXPIRED` / `USED` / `REVOKED`). Pas de pagination ni de filtres serveur en v1 (YAGNI, volume attendu faible) — filtrage par statut assuré côté client.
  - **Independent Test** : Créer 4 invitations dans des états différents, appeler `GET`, vérifier que toutes sont listées avec leur statut correct.

- **US-009** : En tant qu'**admin**, je veux **consulter la liste des users avec leur état**, afin de **gérer le groupe (qui est actif / désactivé)**.
  - **Why this priority** : Prérequis UI pour la page Settings > Utilisateurs (US-004, US-005) — on ne peut pas désactiver sans voir la liste.
  - **Given** l'instance contient plusieurs users (actifs et désactivés)
  - **When** j'appelle `GET /api/admin/users`
  - **Then** je reçois la liste complète avec : id, email, displayName, createdAt, disabledAt, isAdmin (booléen dérivé de `ADMIN_EMAILS`).
  - **Independent Test** : Appeler `GET /api/admin/users` avec fixtures, vérifier présence des users actifs et désactivés.

- **US-010** : En tant qu'**user authentifié**, je veux **savoir si je suis admin**, afin que **le frontend affiche ou masque l'accès à Settings > Utilisateurs**.
  - **Why this priority** : Prérequis pour que l'UI Angular / Flutter cache la section aux non-admins (défense en profondeur, sans remplacer le check backend).
  - **Given** je suis authentifié
  - **When** j'appelle `GET /api/users/me`
  - **Then** la réponse inclut un champ `isAdmin: boolean` dérivé de la comparaison de mon email avec `ADMIN_EMAILS`.
  - **Independent Test** : Requête `GET /api/users/me` avec fixture admin et non-admin, vérifier la valeur du flag.

### P2 — Importantes

- **US-011** : En tant qu'**admin**, je veux **une UI dédiée Settings > Utilisateurs sur Angular**, afin de **gérer invitations et users sans utiliser curl**.
  - **Why this priority** : UX — indispensable à l'usage quotidien, mais l'API seule permet déjà le flux complet en cas de pinch.
  - **Given** je suis admin authentifié dans l'app Angular
  - **When** j'accède à `Settings > Utilisateurs`
  - **Then** je vois deux sections (Invitations, Utilisateurs) avec les actions : Inviter (+), Copier lien, Révoquer, Désactiver, Réactiver.
  - **Independent Test** : Parcours manuel Angular sur toutes les actions avec fixtures backend.

- **US-012** : En tant qu'**admin**, je veux **la même UI sur Flutter**, afin de **garder la parité fonctionnelle entre les deux fronts**.
  - **Why this priority** : Parité produit (convention du projet — cf. migrations Angular / Flutter coordonnées dans les features précédentes).
  - **Given** je suis admin authentifié dans l'app Flutter
  - **When** j'accède à `Settings > Utilisateurs`
  - **Then** je dispose des mêmes sections et actions que sur Angular.
  - **Independent Test** : Parcours manuel Flutter sur toutes les actions avec fixtures backend.

- **US-013** : En tant qu'**invité**, je veux **une page publique `/accept-invite/:token`**, afin de **finaliser mon onboarding sans authentification préalable**.
  - **Why this priority** : Point d'entrée UX de US-002. Peut être approximé en v1 par un simple POST via curl, mais l'UX reste critique.
  - **Given** je clique sur un lien d'invitation valide
  - **When** la page se charge
  - **Then** elle affiche mon email (lecture seule) et un formulaire `password / displayName / currency / timezone`. Soumission → auto-login + redirection dashboard.
  - **Independent Test** : Parcours E2E : création invitation admin → clic lien → acceptation → arrivée dashboard connecté.

### P3 — Nice to have

_Aucune US P3 identifiée en v1 (les nice-to-have audit log, invitations bulk, resend manuel sont volontairement hors scope pour respecter YAGNI)._

## Requirements fonctionnels

| ID | Description | Priorité | User Story |
|----|-------------|----------|------------|
| FR-001 | Créer l'entité JPA `Invitation(id, token, email, invitedByUserId, expiresAt, usedAt, revokedAt, createdAt)` avec migration Flyway. Contraintes DDL : `token UUID UNIQUE NOT NULL + INDEX(token)`, `email VARCHAR NOT NULL`, FK `invited_by_user_id` vers `user(id)` | P1 | US-001 |
| FR-002 | Ajouter colonne `disabled_at TIMESTAMP NULL` sur table `user` via migration Flyway | P1 | US-004 |
| FR-003 | Endpoint `POST /api/admin/invitations` (body `{ email }`) → renvoie `{ token, expiresAt }` | P1 | US-001 |
| FR-004 | Endpoint `GET /api/admin/invitations` → liste complète des invitations triée `createdAt DESC` avec statut dérivé (`ACTIVE`/`EXPIRED`/`USED`/`REVOKED`). Pas de pagination ni de filtres serveur en v1 | P1 | US-008 |
| FR-005 | Endpoint `DELETE /api/admin/invitations/:id` → positionne `revokedAt` | P1 | US-003 |
| FR-006 | Endpoint `GET /api/admin/users` → liste des users avec `isAdmin` et `disabledAt` | P1 | US-009 |
| FR-007 | Endpoint `PATCH /api/admin/users/:id/disable` → soft-disable avec garde-fou dernier admin | P1 | US-004, US-007 |
| FR-008 | Endpoint `PATCH /api/admin/users/:id/enable` → positionne `disabled_at = NULL` | P1 | US-005 |
| FR-009 | Endpoint public `GET /api/auth/invitations/:token` → renvoie `{ email }` si valide, 404 sinon (invitation inconnue, expirée, utilisée ou révoquée) | P1 | US-002, US-003 |
| FR-010 | Endpoint public `POST /api/auth/accept-invite` (body `{ token, password, displayName, currency, timezone }`) → crée User + Account + Preferences, marque `usedAt`, retourne JWT | P1 | US-002 |
| FR-011 | Supprimer `POST /api/auth/register` + controller + DTO `RegisterRequest` (remplacé par `AcceptInviteRequest`) | P1 | US-002 |
| FR-012 | Property `app.admin-emails` (env var `ADMIN_EMAILS`) lue par un service `AdminEmailResolver` — liste normalisée (trim, lowercase) | P1 | US-001, US-006 |
| FR-013 | Enforcer TTL = 7 jours à la création d'invitation (`expiresAt = now + 7 days`) | P1 | US-001, US-002 |
| FR-014 | Refuser l'acceptation d'une invitation déjà `usedAt`, `revokedAt`, ou `expiresAt < now` | P1 | US-002 |
| FR-015 | Côté backend et frontend, l'email de l'invitation est non modifiable dans le formulaire d'acceptation (affichage lecture seule + ignorer toute valeur reçue dans le body) | P1 | US-002 |
| FR-016 | `JwtAuthenticationFilter` : renvoyer 401 si `user.disabled_at IS NOT NULL` (avant d'autoriser la requête) | P1 | US-004 |
| FR-017 | Garde-fou `AdminService.canDisable(userId)` : refuser la désactivation si le user est le seul admin actif (email ∈ `ADMIN_EMAILS` ET `disabled_at IS NULL`). Lancer `ConflictException` → 409 avec payload `{ error: "LAST_ADMIN_CANNOT_BE_DISABLED", message: "..." }` | P1 | US-007 |
| FR-018 | Enrichir `GET /api/users/me` avec `isAdmin: boolean` dérivé de `ADMIN_EMAILS` | P1 | US-010 |
| FR-019 | Protéger tous les endpoints `/api/admin/*` via `Filter` ou `@PreAuthorize` custom basé sur `AdminEmailResolver` → 403 si non-admin | P1 | US-006 |
| FR-020 | UI Angular : page `Settings > Utilisateurs` avec sections Invitations + Users + actions (Inviter, Copier lien, Révoquer, Désactiver, Réactiver) | P2 | US-011 |
| FR-021 | UI Flutter : page `Settings > Utilisateurs` parité fonctionnelle avec Angular | P2 | US-012 |
| FR-022 | Page publique Angular `/accept-invite/:token` — hors guard d'auth, email affiché en lecture seule | P2 | US-013 |
| FR-023 | Page publique Flutter `/accept-invite/:token` — même contrat | P2 | US-013 |
| FR-024 | Dans l'UI (Angular + Flutter), la section `Settings > Utilisateurs` est masquée si `isAdmin = false` (défense en profondeur, pas substitution au check backend) | P2 | US-010, US-011, US-012 |

## Requirements non-fonctionnels

| ID | Description | Catégorie |
|----|-------------|-----------|
| NFR-001 | Token invitation = UUID v4 généré côté serveur (`UUID.randomUUID()`), stocké en DB, jamais régénéré ni rééxposé après création hors liste admin | Sécurité |
| NFR-002 | Logs SLF4J INFO au format `"Admin action: <action> by <adminEmail> target=<resource>:<id>"` pour : création / révocation / acceptation d'invitation + disable / enable user + refus garde-fou dernier admin (principe VI). Pas de table d'audit dédiée en v1. | Observabilité |
| NFR-003 | Isolation des données user maintenue : après acceptation, le nouvel user ne voit que ses propres données (principe II) | Sécurité |
| NFR-004 | Validation d'input Bean Validation : `@Email` sur email invitation, `@NotBlank` + longueur min sur password / displayName, `@Valid` sur DTOs (principe II) | Sécurité |
| NFR-005 | Hash password via BCrypt (pattern existant `AuthService`), jamais de stockage clair | Sécurité |
| NFR-006 | Tests d'intégration couvrant les endpoints (nominaux + cas limites : token expiré, token utilisé, token révoqué, double-use, email non match, user désactivé), tests unitaires sur `AdminService`, `InvitationService`, garde-fou dernier admin (principe V) | Testabilité |
| NFR-007 | Pas de dépendance infra nouvelle (principe VII) — UUID, email, BCrypt déjà en place | Self-Hosted Ready |
| NFR-008 | `AdminEmailResolver` lit la property via `Environment.getProperty("app.admin-emails")` (déjà en mémoire Spring, pas d'I/O externe) au boot + à chaque check — coût négligeable. Au boot, émettre un WARN si `ADMIN_EMAILS` est vide OU si aucun user actif ne matche. | Maintenabilité |

## Contraintes et dépendances

- **Contraintes techniques** :
  - Pas de colonne `role` sur `User` (YAGNI, conformité principe III) — l'admin check reste par email via property.
  - Pas d'envoi SMTP par l'app (conformité principe VII) — le lien est transmis manuellement hors bande.
  - Soft-disable uniquement : pas de hard delete pour préserver l'historique transactionnel / rapports.
  - Comportement `JwtAuthenticationFilter` : refuser l'utilisateur désactivé avec 401 (pas 403) pour réutiliser le flow de réauth côté front.
- **Dépendances externes** :
  - Aucune (pas de SMTP, pas de SaaS).
- **Dépendances internes** :
  - Feature `100-register-currency-timezone` : logique eager de création `User + Account + Preferences` à réutiliser dans `AcceptInviteService` (factoriser si non factorisée).
  - `AuthService` + `JwtAuthenticationFilter` existants : modifier pour intégrer le check `disabled_at`.
  - Constitution v2.1.2 : principe VII + contexte d'usage (self-hosted, pas d'inscription publique).

## Questions ouvertes

| # | Question | Statut | Réponse |
|---|----------|--------|---------|
| Q1 | Code HTTP pour refus garde-fou dernier admin : 409 Conflict, 400 Bad Request, 422 Unprocessable Entity ? Impact sur le message UI côté front. | Résolu | **409 Conflict** via `ConflictException` existante. Body : `{ error: "LAST_ADMIN_CANNOT_BE_DISABLED", message: "Impossible de désactiver le dernier admin actif." }`. |
| Q2 | Filtres et pagination à exposer sur `GET /api/admin/invitations` : par statut, par email, par invitedBy ? Pagination par page ou offset / limit ? | Résolu | **Pas de pagination ni de filtres serveur en v1** (YAGNI, volume ~dizaines max). Tri serveur `createdAt DESC`. Statut dérivé (`ACTIVE` / `EXPIRED` / `USED` / `REVOKED`) calculé côté serveur dans le DTO. Filtrage par statut assuré côté client Angular / Flutter. |
| Q3 | Audit log des actions admin : faut-il écrire des événements INFO dédiés (création / révocation invitation, disable / enable user) pour faciliter la traçabilité self-hosted ? Ou se limiter aux logs SLF4J standards des services ? | Résolu | Logs SLF4J INFO standards (NFR-002). Format : `"Admin action: <action> by <adminEmail> target=<resource>:<id>"`. Pas de table d'audit dédiée en v1 (YAGNI, principe III). |
| Q4 | Layout exact de la page publique `/accept-invite/:token` (branding, contenu avant le formulaire, message après soumission). | Résolu | **Reporté à la phase `/devflow.plan` + `design-coherence`**. Le contrat fonctionnel (email lecture seule, formulaire 4 champs, auto-login après soumission) est figé dans US-002 / US-013 / FR-022-023 ; le wireframe sera produit à la phase plan. |
| Q5 | Comportement si `ADMIN_EMAILS` est vide ou ne matche aucun user actif : faut-il alerter dans les logs au boot ? | Résolu | **WARN SLF4J au boot** dans `AdminEmailResolver` si `ADMIN_EMAILS` est vide OU si aucun user actif (non `disabled_at`) ne correspond : `"ADMIN_EMAILS not configured or no matching active user — invitations cannot be issued until an admin is configured."`. Rien de plus en runtime (les endpoints `/api/admin/*` renvoient 403 de toute façon). |

## Success Criteria

| ID | Description | Méthode de vérification | User Story |
|----|-------------|------------------------|------------|
| SC-001 | `POST /api/auth/register` n'existe plus (route retournant 404 ou 405) | Test d'intégration auto | US-002 |
| SC-002 | Un user non-admin reçoit 403 sur chaque endpoint `/api/admin/*` | Test d'intégration auto (matrice endpoints × rôles) | US-006 |
| SC-003 | Un token créé il y a plus de 7 jours est refusé par `GET /api/auth/invitations/:token` et `POST /api/auth/accept-invite` | Test d'intégration auto avec clock injecté | US-001, US-002 |
| SC-004 | Un token déjà utilisé (`usedAt` non null) est refusé au deuxième `POST /api/auth/accept-invite` | Test d'intégration auto | US-002 |
| SC-005 | Un token révoqué retourne 404 sur `GET /api/auth/invitations/:token` | Test d'intégration auto | US-003 |
| SC-006 | L'email est verrouillé côté formulaire (champ disabled, soumission ne change pas l'email même si altérée dans le body) | Test d'intégration backend (auto) + manuel Angular + manuel Flutter | US-002 |
| SC-007 | Un user dont `disabled_at` est non null reçoit 401 sur toute route authentifiée | Test d'intégration auto (filter) | US-004 |
| SC-008 | Un admin seul reçoit HTTP 409 avec `error=LAST_ADMIN_CANNOT_BE_DISABLED` en tentant de se désactiver | Test d'intégration auto | US-007 |
| SC-009 | La page `Settings > Utilisateurs` Angular + Flutter affiche invitations + users, actions fonctionnelles | Manuel (plan de test) | US-011, US-012 |
| SC-010 | Un parcours E2E invitation → clic lien → acceptation → dashboard fonctionne de bout en bout | Manuel (plan de test) | US-013 |
| SC-011 | `GET /api/users/me` renvoie `isAdmin: true` pour un email dans `ADMIN_EMAILS`, `false` sinon | Test d'intégration auto | US-010 |
| SC-012 | Après acceptation, le nouveau user ne voit aucune donnée des autres users (isolation respectée) | Test d'intégration auto | US-002 |
| SC-013 | Après réactivation d'un user désactivé, celui-ci peut se (re)connecter et ses requêtes authentifiées ne renvoient plus 401 | Test d'intégration auto | US-005 |

## Key Entities

| Entité | Description | Relations principales |
|--------|-------------|----------------------|
| `Invitation` | Lien d'invitation émis par un admin. Champs : `id` (long), `token` (UUID v4, unique, indexé), `email` (string, normalisé lowercase), `invitedByUserId` (FK User), `expiresAt`, `usedAt` (nullable), `revokedAt` (nullable), `createdAt`. Statut dérivé (actif / expiré / révoqué / utilisé). | `ManyToOne` vers `User` (invitedBy) |
| `User` (modifié) | Ajout colonne `disabled_at TIMESTAMP NULL`. Reste du schéma inchangé. | Relations existantes conservées |
| `AcceptInviteRequest` (DTO) | Remplace `RegisterRequest`. Champs : `token`, `password`, `displayName`, `currency`, `timezone`. | N/A |
| `InvitationResponse` (DTO) | Retour liste admin. Champs : `id`, `email`, `invitedByEmail` (projeté depuis FK `invitedByUserId` via lookup `UserRepository` dans `AdminService`), `status` (enum `ACTIVE`/`EXPIRED`/`USED`/`REVOKED`, calculé côté serveur), `createdAt`, `expiresAt`, `usedAt`, `revokedAt`. | N/A |
| `AdminUserResponse` (DTO) | Retour `GET /api/admin/users`. Champs : `id`, `email`, `displayName`, `createdAt`, `disabledAt`, `isAdmin`. | N/A |

## Assumptions

| # | Hypothèse | Impact si fausse | Validation prévue |
|---|-----------|-----------------|-------------------|
| A-001 | L'admin transmet le lien d'invitation via un canal out-of-band raisonnablement sécurisé (Signal, SMS chiffré, face-à-face). | Si faux : un adversaire interceptant le lien peut créer un compte à la place de l'invité (l'email est verrouillé côté serveur mais l'attaquant contrôlerait le mot de passe). Mitigation : TTL 7j + révocation manuelle possible. | Documenter dans le README self-host + onboarding admin |
| A-002 | `ADMIN_EMAILS` est configuré dans l'env avant le premier boot de l'instance, OU au moins un user avec un de ces emails existe déjà (cas Kelly sur instance actuelle). | Si faux : aucun admin ne peut émettre d'invitation (deadlock), car le bootstrap admin sur DB vide est hors scope. | Logger un WARN au boot si `ADMIN_EMAILS` vide ou si aucun user actif n'y correspond |
| A-003 | La feature `100-register-currency-timezone` est déployée en prod et la logique eager de création User + Account + Preferences est factorisable (ou déjà extraite d'un service). | Si faux : devoir refactorer / dupliquer la logique dans `AcceptInviteService`. | Lecture du code existant à la phase `/devflow.plan` |
| A-004 | Un seul niveau d'admin suffit pour v1 (pas de rôles multiples `owner/admin/moderator`). | Si faux : refactor futur nécessitant une colonne `role` — traitable comme une migration standard. | Confirmé par décision sparring session |
| A-005 | Le frontend peut afficher / cacher dynamiquement la section `Settings > Utilisateurs` sur la base d'un flag `isAdmin` retourné par `GET /api/users/me` appelé au boot / login. | Si faux : section accessible visuellement aux non-admins mais endpoints backend renvoient quand même 403 (défense en profondeur). UX dégradée non bloquante. | Revue UI design phase `/devflow.plan` |
| A-006 | Les invitations ne nécessitent pas d'envoi d'email automatique en v1 (principe VII, pas de SMTP). L'admin copie manuellement le lien. | Si faux : ajouter SMTP violerait la constitution → ticket séparé avec amendement. | Confirmé par issue (hors scope explicite) |
