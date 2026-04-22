# Feature Specification: Bootstrap du premier admin sur DB vide (pattern password généré au premier boot)

**Feature Branch**: `sopequenotech/kks-233-bootstrap-du-premier-admin-sur-db-vide-pattern-password`
**Created**: 2026-04-22
**Status**: Draft
**Input**: Linear KKS-233 — priorité Low — labels Security, Backend, Feature

## Contexte

KKS-232 a supprimé l'inscription publique (`POST /api/auth/register`) au profit d'un flux d'invitation par admin. Conséquence : sur une instance vierge (DB vide), aucun mécanisme ne permet de créer le tout premier compte admin. L'app devient inutilisable pour un self-hoster tiers.

Décision de session sparring : pattern **password généré au premier boot + affichage dans les logs + reset forcé à la première connexion**, inspiré de Jenkins (`initialAdminPassword`) et GitLab (`root_password`). Critère dominant : `docker compose up -d` doit suffire, aucune commande CLI ni configuration supplémentaire.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Premier démarrage sur DB vide (Priority: P1)

Un self-hoster clone le repo, configure son `.env` minimal (DB, JWT secret) et lance `docker compose up -d`. L'app démarre, seed un compte admin initial, et écrit le mot de passe temporaire dans les logs avec une bannière visible.

**Why this priority**: C'est l'unique porte d'entrée pour une instance neuve. Sans cette étape, tout le reste est inaccessible. Bloquant par définition.

**Independent Test**: Démarrer un container sur une DB PostgreSQL vide. Vérifier que (a) un user `admin@localhost` existe en DB avec `passwordResetRequired = true` et `isAdmin = true`, (b) les logs contiennent une bannière encadrée avec le mot de passe généré, (c) un `Account` et des `Preferences` associés ont été créés.

**Acceptance Scenarios**:

1. **Given** une instance avec DB PostgreSQL vide et aucun `BOOTSTRAP_EMAIL` défini, **When** le container Spring Boot démarre, **Then** un `User` admin est créé avec email `admin@localhost`, password aléatoire 32 chars, `isAdmin = true`, `passwordResetRequired = true`, et `Account` + `Preferences` associés.
2. **Given** une instance avec DB vide et `BOOTSTRAP_EMAIL=kelly@exemple.com`, **When** le container démarre, **Then** le user seed est créé avec cet email au lieu du défaut.
3. **Given** le seed vient d'avoir lieu, **When** on consulte `docker compose logs api`, **Then** une bannière encadrée multi-lignes en niveau WARN affiche l'email, le mot de passe généré, et un avertissement de changement immédiat.

---

### User Story 2 — Reset forcé à la première connexion (Priority: P1)

Le self-hoster se connecte à l'UI Angular avec `admin@localhost` + le mdp récupéré dans les logs. L'app le redirige automatiquement vers un écran dédié où il doit définir son email définitif, un nouveau mot de passe, et un nom d'affichage. Après validation, il accède à l'app normalement.

**Why this priority**: Sans le reset, les credentials initiaux loggés restent valides — risque de compromission élevé. Le flag force l'action et débloque l'accès complet.

**Independent Test**: Effectuer un login avec les credentials initiaux. Vérifier que la réponse indique `mustResetCredentials: true`, que le JWT ne donne accès qu'à l'endpoint de reset, et qu'après appel de `POST /api/auth/first-login-reset` avec des credentials valides, un nouveau JWT est retourné donnant accès complet.

**Acceptance Scenarios**:

1. **Given** un user seed avec `passwordResetRequired = true`, **When** il appelle `POST /api/auth/login` avec les credentials initiaux, **Then** la réponse contient un `accessToken` et `mustResetCredentials: true`.
2. **Given** un JWT émis avec flag actif, **When** il est utilisé pour appeler un endpoint protégé autre que `first-login-reset`, **Then** la réponse est `403 Forbidden`.
3. **Given** un JWT émis avec flag actif, **When** il est utilisé pour appeler `POST /api/auth/first-login-reset` avec `email`, `password`, `displayName` valides, **Then** le user est mis à jour, `passwordResetRequired` passe à `false`, et un nouveau JWT est retourné.
4. **Given** un user avec `passwordResetRequired = false`, **When** il appelle `POST /api/auth/first-login-reset`, **Then** la réponse est `403 Forbidden`.
5. **Given** l'utilisateur est sur l'UI Angular et son JWT indique `mustResetCredentials: true`, **When** il tente de naviguer vers `/dashboard`, **Then** le router guard le redirige vers `/first-login-reset`.

---

### User Story 3 — Redémarrage du container avant le reset (Priority: P2)

Le self-hoster démarre l'instance, voit le mdp dans les logs, mais n'a pas eu le temps de se connecter. Le container redémarre (crash, reboot serveur, update). Les logs du premier démarrage peuvent avoir été perdus selon la stratégie de logs, mais le même mot de passe reste valide en DB — aucune régénération n'a lieu.

**Why this priority**: Robustesse opérationnelle. Régénérer à chaque boot créerait une confusion (plusieurs mdp dans les logs) et un risque de désynchro. Ce scénario n'est pas bloquant mais doit être prédictible.

**Independent Test**: Démarrer une instance (seed créé, mdp loggé), arrêter le container, redémarrer. Vérifier que (a) aucun nouveau seed n'a lieu, (b) aucune nouvelle bannière WARN dans les logs du second démarrage, (c) les credentials initiaux loggés au premier démarrage restent valides pour se connecter.

**Acceptance Scenarios**:

1. **Given** une instance avec un user seed existant (`count() == 1`), **When** le container redémarre, **Then** aucun nouveau user n'est créé et aucune bannière n'est loggée.
2. **Given** les credentials initiaux du premier boot, **When** on tente un login après redémarrage du container, **Then** le login réussit avec les mêmes credentials.

---

### User Story 4 — Préservation du rôle admin après reset (Priority: P2)

Après le reset, le self-hoster change son email vers son adresse personnelle (`kelly@exemple.com`). Son `.env` contient peut-être `ADMIN_EMAILS=autre@exemple.com` (ancienne valeur) ou est vide. Au prochain redémarrage, son statut admin (`isAdmin = true`) stocké en DB est préservé : il ne perd pas son accès administrateur.

**Why this priority**: Évite une situation où le self-hoster se trouve verrouillé hors du mode admin après son propre reset. Cohérence avec la décision "ADMIN_EMAILS = source de promotion au boot uniquement, jamais de rétrogradation".

**Independent Test**: Créer un user avec `isAdmin = true` en DB et un email absent de `ADMIN_EMAILS`. Redémarrer l'app. Vérifier que le user conserve `isAdmin = true` et accède aux endpoints `/admin/*`.

**Acceptance Scenarios**:

1. **Given** un user avec `isAdmin = true` en DB et son email absent de `ADMIN_EMAILS`, **When** l'app redémarre, **Then** le user conserve `isAdmin = true` et passe le filtre d'autorisation admin.
2. **Given** un user avec `isAdmin = false` en DB et son email listé dans `ADMIN_EMAILS`, **When** l'app démarre, **Then** le user est promu à `isAdmin = true` par le synchroniseur au démarrage (comportement d'ajout conservé).
3. **Given** un user avec `isAdmin = true` en DB et son email absent de `ADMIN_EMAILS`, **When** l'app démarre, **Then** aucune modification n'est faite sur son champ `isAdmin` (pas de rétrogradation).

---

### User Story 5 — Seed inopérant si DB déjà peuplée (Priority: P3)

Une instance existante (avec des users déjà créés via KKS-232 ou via ce bootstrap) est redémarrée ou mise à jour. Le mécanisme de seed ne doit jamais créer de nouveau user admin dans ce cas, pour éviter toute création incontrôlée.

**Why this priority**: Garde-fou de non-régression. Kelly, principal utilisateur actuel, ne doit jamais voir un `admin@localhost` apparaître en DB après une mise à jour.

**Independent Test**: Démarrer une instance avec au moins un user existant en DB. Vérifier qu'aucun seed n'a lieu et qu'aucune bannière n'apparaît dans les logs.

**Acceptance Scenarios**:

1. **Given** une DB contenant au moins un user, **When** l'app démarre, **Then** aucun nouveau user n'est créé et aucune bannière de bootstrap n'est loggée.

---

### Edge Cases

- **Reset avec email déjà utilisé** : si le self-hoster choisit un email qui est déjà dans `ADMIN_EMAILS` mais correspond à un user inexistant, pas d'impact. Si l'email correspond à un user existant (scénario non prévu sur DB vide mais théorique après reset sur DB multi-user), refuser le reset en `409 Conflict` (géré par FR-010).
- **Accès concurrent avec credentials initiaux** : plusieurs sessions simultanées depuis des IP différentes avec les mêmes credentials temporaires avant reset. Résolution (cf. FR-008) : le JWT émis avec flag actif contient un claim `mustResetCredentials: true` vérifié à chaque requête, doublé d'une vérification DB sur `user.passwordResetRequired`. Après qu'une session ait reset, le flag DB passe à `false` : l'autre JWT encore valide conserve son claim `true` mais se voit refuser l'accès à `/first-login-reset` (incohérence DB) et reste bloqué sur tous les autres endpoints par son claim. Pas de blocklist en mémoire nécessaire.
- **Rotation des logs** : si un système externe (Datadog, Loki) capture les logs, le mdp persiste hors de l'instance. Documenté dans `deployment.md` mais hors scope technique.
- **Reset avec mot de passe identique à l'initial** : refus `400 Bad Request` pour forcer un vrai changement.
- **Crash pendant le reset** : si le `first-login-reset` échoue après mise à jour du password mais avant clear du flag (transaction partielle), le user doit pouvoir se reconnecter et compléter le reset. La transaction DB doit être atomique.
- **`BOOTSTRAP_EMAIL` invalide** (format non-email) : échec du démarrage de l'application avec message d'erreur explicite (fail-fast). Cohérent avec les conventions de validation de configuration Spring Boot et évite la création silencieuse d'un user avec un email non-ressaisissable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT, au démarrage de l'application et après les migrations Flyway, détecter si la table `users` est vide (`count() == 0`).
- **FR-002**: Si la table est vide, le système DOIT créer un `User` unique avec : `email` = valeur de la variable d'environnement `BOOTSTRAP_EMAIL` si définie, sinon `admin@localhost` ; `password` hashé via BCrypt ; le mot de passe en clair généré aléatoirement sur 32 caractères alphanumériques via `SecureRandom` ; `isAdmin = true` ; `passwordResetRequired = true`.
- **FR-003**: Le système DOIT créer, simultanément au User seed, un `Account` et les `Preferences` associés, en réutilisant la logique partagée avec le flux `accept-invite` de KKS-232.
- **FR-004**: Le système DOIT journaliser au niveau `WARN` une bannière encadrée multi-lignes contenant l'email, le mot de passe généré en clair, et un avertissement de changement immédiat, une seule fois au moment du seed.
- **FR-005**: Le système NE DOIT PAS créer de user ni journaliser de bannière si la table `users` contient déjà au moins un enregistrement au démarrage.
- **FR-006**: Le système NE DOIT PAS régénérer un nouveau mot de passe ou recréer un user si le container redémarre après un seed réussi : la condition `count() == 0` garantit l'unicité.
- **FR-007**: L'endpoint `POST /api/auth/login` DOIT accepter les credentials initiaux comme tout login normal et renvoyer, dans la réponse, un champ `mustResetCredentials: true` si le user authentifié a `passwordResetRequired = true`.
- **FR-008**: Un JWT émis pour un user avec `passwordResetRequired = true` DOIT contenir un claim dédié (ex. `mustResetCredentials: true`). Le filtre d'autorisation DOIT, pour toute requête portant ce claim : (a) autoriser uniquement `POST /api/auth/first-login-reset` **et les endpoints d'ouverture/fermeture de session non-protégés** (ex. `POST /api/auth/logout` s'il existe côté serveur, afin de permettre à l'utilisateur d'abandonner sans être verrouillé) ; (b) répondre `403 Forbidden` sur tout autre endpoint protégé. L'endpoint `first-login-reset` DOIT lui-même vérifier en complément que `user.passwordResetRequired == true` en base (sinon `403`) afin d'invalider les anciens JWT lorsque le flag a déjà été levé. Aucune blocklist JWT ni rotation de secret n'est requise.
- **FR-009**: Le système DOIT exposer un endpoint `POST /api/auth/first-login-reset` protégé par JWT, acceptant un body JSON avec `email` (format email, non-null), `password` (`@Size(min = 8, max = 100)`, aligné sur `AcceptInviteRequest` de KKS-232), `displayName` (`@Size(min = 1, max = 100)`, non-null) validés par Bean Validation.
- **FR-010**: L'endpoint `first-login-reset` DOIT : valider que le user authentifié a `passwordResetRequired = true` (sinon `403`) ; mettre à jour `email`, `password` (re-hashé via BCrypt), `displayName` ; passer `passwordResetRequired` à `false` ; émettre un nouveau JWT à accès complet (sans le claim `mustResetCredentials`) ; exécuter l'ensemble dans une transaction atomique (`@Transactional`).
- **FR-011**: L'endpoint `first-login-reset` DOIT refuser un nouveau password identique à celui actuellement en base via `BCryptPasswordEncoder.matches(newPlaintext, oldHash)` — code `400` avec payload `{ error: "PASSWORD_UNCHANGED", message: "Le nouveau mot de passe doit être différent de l'actuel." }`.
- **FR-012**: Le système DOIT stocker le statut admin sous forme d'un champ `isAdmin` (boolean, non-null, défaut `false`) sur l'entité `User`. Refactor obligatoire : `AdminAuthorizationFilter` DOIT résoudre le statut admin via `user.isAdmin()` et non plus via `AdminEmailResolver.isAdminEmail(email)`. Le DTO `UserResponse` produit par `UserService.toResponse()` DOIT de la même façon alimenter son champ `isAdmin` depuis `user.isAdmin()` (et non plus depuis `adminEmailResolver.isAdminEmail(...)`), afin que le front reçoive une valeur cohérente avec la source autoritaire en base. `AdminEmailResolver` DOIT être conservé pour ses autres usages (validation des emails cibles dans le flux d'invitation KKS-232) mais ne DOIT plus être consulté dans la chaîne d'autorisation.
- **FR-012a**: La migration Flyway SQL associée DOIT UNIQUEMENT ajouter la colonne `is_admin BOOLEAN NOT NULL DEFAULT FALSE` à la table `users`. Elle NE DOIT PAS tenter de lire `ADMIN_EMAILS` ni d'effectuer la promotion initiale (la variable n'est pas accessible dans le contexte SQL Flyway).
- **FR-012b**: Un synchroniseur au démarrage (`ApplicationRunner` ou équivalent, exécuté après Flyway) DOIT assurer la promotion initiale et continue : pour chaque email listé dans `ADMIN_EMAILS`, si un user correspondant existe avec `isAdmin = false`, le synchroniseur DOIT le passer à `isAdmin = true`. Ce mécanisme DOIT s'exécuter à chaque démarrage (idempotent). Il NE DOIT JAMAIS rétrograder (pas de passage `true → false`).
- **FR-013**: L'UI Angular DOIT inclure une route `/first-login-reset` avec un composant dédié (formulaire email + password + confirmation + displayName).
- **FR-014**: L'UI Angular DOIT inclure un router guard qui redirige toute tentative de navigation vers une autre route que `/first-login-reset` ou `/login` lorsque l'état d'authentification indique `mustResetCredentials = true`.
- **FR-015**: Après succès de `first-login-reset`, l'UI Angular DOIT remplacer le JWT en stockage local par celui retourné et rediriger vers la route racine `/`.
- **FR-016**: Le client Flutter NE DOIT PAS recevoir de modifications liées à ce bootstrap : il reste indépendant du serveur Spring et se connecte uniquement à une instance déjà bootstrappée. Vérification opérationnelle : le diff de la branche `feature/KKS-233` NE DOIT contenir aucune modification sous `flutter/` (hors fichiers partagés éventuels dûment justifiés).
- **FR-017**: Si la variable `BOOTSTRAP_EMAIL` est définie avec une valeur ne respectant pas le format email standard, l'application DOIT échouer à démarrer (fail-fast) avec un message d'erreur clair mentionnant la variable fautive et la valeur observée. Aucun fallback silencieux sur `admin@localhost` n'est autorisé dans ce cas.
- **FR-018**: `docs/deployment.md` DOIT être mis à jour dans le cadre de ce ticket avec la procédure complète de premier démarrage : (1) exécution de `docker compose up -d`, (2) commande exacte pour récupérer la bannière dans les logs, (3) étape de connexion sur l'UI Angular avec les credentials initiaux, (4) étape de reset forcé avec les trois champs à remplir, (5) recommandation de purge des logs persistés externe le cas échéant.

### Key Entities

- **User** (entité existante, modifiée) : ajout de deux champs : `passwordResetRequired` (boolean, non-null, défaut `false`) représentant l'exigence de changement de credentials à la première connexion, et `isAdmin` (boolean, non-null, défaut `false`) représentant le statut administrateur stocké de manière autoritaire en base (nouveau — remplace la résolution dynamique via `AdminEmailResolver.isAdminEmail(email)` dans le filtre d'autorisation admin).
- **Account** (inchangée) : créée au seed par la logique partagée avec `accept-invite`.
- **Preferences** (inchangée) : créée au seed par la logique partagée avec `accept-invite`.
- **Variable d'environnement** : `BOOTSTRAP_EMAIL` optionnelle — valeur de l'email du user seed (fail-fast si format invalide, cf. FR-017). `ADMIN_EMAILS` conservée avec sémantique redéfinie : source de promotion au démarrage uniquement, jamais de rétrogradation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un self-hoster tiers, partant d'un repo cloné et d'une DB PostgreSQL vierge, peut accéder à l'application et compléter son reset en moins de **5 minutes** en suivant uniquement les étapes documentées dans la version mise à jour de `docs/deployment.md` (cf. FR-018). *(Vérification : chronométrage manuel du parcours bout en bout, réalisé par l'auteur du ticket lors de la validation de la phase `/devflow.checklist`.)*
- **SC-002**: Sur une DB vierge, **100 %** des démarrages de l'app créent exactement **un seul** user avec `isAdmin = true`, un `Account` associé et des `Preferences` associées. *(Vérification : test d'intégration backend.)*
- **SC-003**: Sur une DB déjà peuplée, **0 %** des démarrages créent un nouveau user ou journalisent une bannière de bootstrap. *(Vérification : test d'intégration backend avec DB pré-peuplée.)*
- **SC-004**: Avec un JWT émis pour un user ayant `passwordResetRequired = true`, **100 %** des endpoints protégés autres que `POST /api/auth/first-login-reset` renvoient `403 Forbidden`. *(Vérification : test d'intégration backend couvrant un échantillon représentatif d'endpoints : `/api/users/me`, `/api/accounts`, `/api/transactions`, `/api/categories`.)*
- **SC-005**: Après un reset réussi, le user conserve `isAdmin = true` en base et accède sans erreur aux endpoints `/admin/*`, y compris après redémarrage de l'app et même si son nouvel email n'apparaît pas dans `ADMIN_EMAILS`. *(Vérification : test d'intégration backend couvrant le scénario complet reset + restart + appel `/admin/*`.)*
- **SC-006**: Aucune configuration de variable d'environnement autre que celles déjà requises pour le fonctionnement général (DB, JWT secret) n'est **obligatoire** pour réaliser le bootstrap. `BOOTSTRAP_EMAIL` est strictement optionnelle. *(Vérification : checklist de déploiement sur instance vierge avec `.env` minimal.)*
- **SC-007**: Le mot de passe généré au premier boot est composé de 32 caractères alphanumériques `[A-Za-z0-9]` produits par `SecureRandom`. *(Vérification : test unitaire sur le service de génération.)*

## Constraints & Dependencies

### Dépendances

- **KKS-232** (mergé) : fournit la logique de création User + Account + Preferences appelée par `accept-invite`. Ce ticket réutilise cette logique lors du seed. Vérifier que cette logique est exposée comme un service réutilisable (pas uniquement inline dans le controller `accept-invite`).
- **Flyway** : le seed applicatif s'exécute après les migrations. Deux migrations Flyway sont dans le scope de ce ticket et DOIVENT être listées comme livrables explicites lors de la génération des tâches :
  - **Migration 1** — ajout du champ `is_admin BOOLEAN NOT NULL DEFAULT FALSE` sur la table `users` (ALTER TABLE uniquement, cf. FR-012a).
  - **Migration 2** — ajout du champ `password_reset_required BOOLEAN NOT NULL DEFAULT FALSE` sur la table `users`.
  - La promotion initiale des users existants via `ADMIN_EMAILS` n'est PAS portée par une migration mais par le synchroniseur applicatif au démarrage (cf. FR-012b).

### Contraintes

- **Principe II (Sécurité par défaut)** : aucun endpoint public supplémentaire, password aléatoire par instance, force reset obligatoire.
- **Principe III (YAGNI)** : pas de wizard multi-étapes, pas de CLI dédiée, pas de notification externe, pas de régénération automatique.
- **Principe VII (Self-Hosted Ready)** : `docker compose up -d` doit suffire. Aucune commande manuelle additionnelle ne doit être requise pour bootstrapper.
- **Surface logs** : le mot de passe initial apparaît dans `docker compose logs`. Responsabilité documentée du self-hoster de purger si logs persistés externes.

## Assumptions

- La logique de création `User + Account + Preferences` de KKS-232 est exposée sous forme d'un service réutilisable (`UserBootstrapService` ou équivalent). **Impact si faux** : refactoring préalable de KKS-232 pour extraire la logique, sinon duplication.
- Le système de logs actuel par défaut est `stdout` Docker (pas d'agent externe persistant automatiquement). **Impact si faux** : l'avertissement de purge doit être renforcé dans `deployment.md`.
- Le self-hoster cible a un accès shell au serveur hôte pour exécuter `docker compose logs`. **Impact si faux** : un canal alternatif de récupération du mdp initial devrait être prévu (hors scope actuel).
- Le refactor de `AdminAuthorizationFilter` et de `UserService.toResponse()` (passage de `adminEmailResolver.isAdminEmail(email)` à `user.isAdmin()`) n'introduit pas de régression sur l'ensemble des endpoints `/admin/*` existants — toutes versions confondues, pas uniquement ceux livrés par KKS-232 — ni sur les consommateurs front du champ `UserResponse.isAdmin`. **Impact si faux** : la couverture de tests d'intégration admin et de tests front devra être renforcée dans ce ticket.

## Questions ouvertes

Points différés à la phase `/devflow.plan` (impact design bas, à trancher lors du cadrage technique) :

- **Q-DIFF-01 — Contrat de réponse `POST /api/auth/login`** : le champ `mustResetCredentials` doit-il être toujours présent dans la réponse (même à `false`) pour faciliter le parsing côté front, ou uniquement lorsqu'il est à `true` ? *(Catégorie : UX/Interaction ; Score : BAS.)*
- **Q-DIFF-02 — Véhicule du JWT post-reset** : le nouveau JWT retourné par `first-login-reset` doit-il être dans le body JSON ou dans un cookie HttpOnly, en cohérence avec la convention actuelle du flux `login` et `accept-invite` ? *(Catégorie : Intégrations ; Score : BAS — à aligner en phase plan.)*
- **Q-DIFF-03 — Format exact de la bannière WARN** : largeur du cadre (48/64/80 caractères), caractère d'encadrement (`=`, `#`, autre), alignement des labels. *(Catégorie : Placeholders ; Score : BAS.)*
- **Q-DIFF-04 — `displayName` dans `first-login-reset`** : strictement obligatoire (aligné sur `AcceptInviteRequest` KKS-232) ou optionnel avec fallback sur la valeur actuelle du user seed ? *(Catégorie : Modèle de données ; Score : BAS.)*
- **Q-DIFF-05 — Périmètre du seed pour le compte admin initial** : la logique `accept-invite` de KKS-232 (`AcceptInviteService.acceptInvite()`) appelle aussi `categoryService.seedSystemCategories(user)`. Le seed admin initial doit-il inclure les catégories système, pour que l'admin dispose immédiatement d'un compte fonctionnel, ou les omettre pour rester minimal ? *(Catégorie : Scope fonctionnel ; Score : BAS.)*
