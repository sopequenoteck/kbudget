# Feature Specification : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

**Issue Linear** : [KKS-235](https://linear.app/kksdev/issue/KKS-235/page-mon-compte-profil-securite-donnees-suppression-fix-bouton)
**Feature Branch** : `feature/KKS-235`
**Créée** : 2026-04-30
**Statut** : Draft
**Priorité** : Medium (P3 Linear)
**Labels** : Feature, Bug
**Input** : Issue Linear KKS-235

---

## Contexte

L'application k-budget dispose d'une page Settings dont le bloc identité est partiellement décoratif :

- L'avatar est affiché avec les initiales générées et un bouton caméra non fonctionnel (upload non implémenté côté backend).
- Le bouton **Déconnexion** existe visuellement mais **n'a aucun handler côté Angular** (bug introduit en phase design).
- Aucune page ne permet à l'utilisateur de gérer son compte (changer son mot de passe, supprimer son compte, exporter ses données).

Cette feature crée une page **Mon compte** dédiée et corrige le bug du bouton déconnexion.

Décisions techniques validées en phase sparring (audits backend + frontend) :

- **Email non éditable** par l'utilisateur (risque de privilege escalation via `ADMIN_EMAILS` + JWT stale).
- **Suppression de compte en soft-delete** (auditabilité, contraintes FK `RESTRICT` sur invitations).
- Page dédiée `/settings/account` (alignement Flutter qui possède déjà `ProfileSettingsScreen`).
- Politique de mot de passe harmonisée à **min 12 caractères** (actuel 8 chars dans `FirstLoginResetRequest`).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Accéder à la page Mon compte et se déconnecter (Priorité : P1)

En tant qu'utilisateur authentifié, je veux pouvoir accéder à une page dédiée à la gestion de mon compte depuis les paramètres et me déconnecter de l'application en un geste.

**Why this priority** : Bloquant. La page Mon compte est la fondation de toutes les autres user stories (sans elle, aucune autre fonctionnalité n'est accessible). Le bouton de déconnexion est un bug actuel : un utilisateur ne peut pas se déconnecter via l'UI Angular, ce qui constitue une régression critique sur une action de base de toute application multi-user.

**Independent Test** : Naviguer depuis Settings vers Mon compte, vérifier l'affichage du bloc identité, cliquer sur Déconnexion et vérifier la redirection vers `/login` ainsi que la révocation du refresh token côté backend.

**Acceptance Scenarios** :

1. **Étant donné** un utilisateur authentifié sur la page Settings, **quand** il tape sur l'item "Mon compte", **alors** il est redirigé vers `/settings/account` qui affiche son identité (avatar, nom, email read-only).
2. **Étant donné** un utilisateur authentifié sur `/settings/account`, **quand** il tape sur "Déconnexion", **alors** son refresh token est révoqué côté backend, le JWT est purgé du stockage local, et il est redirigé vers `/login`.
3. **Étant donné** un utilisateur déconnecté, **quand** il tente d'accéder à `/settings/account` avec un JWT révoqué, **alors** il est redirigé vers `/login` avec un message d'erreur explicite.

---

### User Story 2 — Modifier son identité (nom + avatar) (Priorité : P1)

En tant qu'utilisateur authentifié, je veux pouvoir modifier mon nom affiché et personnaliser ma photo de profil pour me reconnaître facilement dans l'application.

**Why this priority** : Identité visuelle et personnalisation utilisateur. Le backend supporte déjà la modification du nom via `PUT /users/me` mais aucune UI ne l'expose. L'avatar est affiché avec un bouton caméra non fonctionnel — promesse non tenue. Sans cette US, l'utilisateur reste sur ses initiales générées sans pouvoir personnaliser.

**Independent Test** : Modifier le nom inline et vérifier la persistance après refresh. Uploader une image (JPG ou PNG) et vérifier qu'elle remplace les initiales sur toutes les pages où l'avatar est affiché.

**Acceptance Scenarios** :

1. **Étant donné** un utilisateur sur `/settings/account`, **quand** il modifie son nom et valide, **alors** le nom est persisté en base et reflété dans l'UI sans rechargement.
2. **Étant donné** un utilisateur sur `/settings/account`, **quand** il tape sur son avatar et sélectionne une image JPG ou PNG de taille ≤ 2 MB, **alors** l'image est uploadée, redimensionnée côté serveur en 256x256 (sortie JPEG ~85% qualité), stockée et affichée immédiatement.
3. **Étant donné** un utilisateur ayant un avatar custom, **quand** il choisit "Supprimer la photo", **alors** l'avatar revient aux initiales générées et le fichier est purgé côté backend.
4. **Étant donné** un utilisateur sur `/settings/account`, **quand** il consulte son email, **alors** le champ est en lecture seule avec la mention "Géré par l'admin".

---

### User Story 3 — Changer son mot de passe (Priorité : P1)

En tant qu'utilisateur authentifié, je veux pouvoir changer mon mot de passe directement depuis l'application en fournissant mon mot de passe actuel et un nouveau mot de passe respectant la politique de sécurité.

**Why this priority** : Sécurité fondamentale. Aujourd'hui, un utilisateur ne peut changer son mot de passe que lors du first-login-reset (`KKS-233`). En dehors de ce flow initial, aucun moyen de changer son MDP — anomalie de sécurité critique pour une application multi-user manipulant des données financières.

**Independent Test** : Saisir mot de passe actuel + nouveau mot de passe (≥ 12 chars) et vérifier que le login avec l'ancien échoue et que le login avec le nouveau réussit.

**Acceptance Scenarios** :

1. **Étant donné** un utilisateur sur `/settings/account`, **quand** il saisit son MDP actuel correct et un nouveau MDP de min 12 chars, **alors** le MDP est mis à jour côté backend (BCrypt hash) et un message de confirmation s'affiche.
2. **Étant donné** un utilisateur saisissant un MDP actuel incorrect, **quand** il valide le formulaire, **alors** une erreur 401 est renvoyée et le MDP n'est pas modifié.
3. **Étant donné** un utilisateur saisissant un nouveau MDP < 12 chars ou identique à l'ancien, **quand** il valide le formulaire, **alors** une erreur de validation est renvoyée avant tout appel backend.
4. **Étant donné** un utilisateur ayant changé son MDP, **quand** il tente un login avec l'ancien MDP, **alors** le login échoue avec 401.

---

### User Story 4 — Exporter ses données (Priorité : P2)

En tant qu'utilisateur authentifié, je veux pouvoir exporter l'ensemble de mes données dans un format réutilisable pour les sauvegarder ou les analyser hors application.

**Why this priority** : Transparence et autonomie utilisateur. Conformité RGPD (droit à la portabilité). Self-hosted = utilisateur maître de ses données. Non-bloquant pour l'usage quotidien, mais attendu sur une app financière sérieuse.

**Independent Test** : Déclencher l'export JSON et vérifier que toutes les entités du user sont présentes (transactions, comptes, catégories, budgets, abonnements, etc.) avec les bonnes relations. Idem pour le CSV transactions.

**Acceptance Scenarios** :

1. **Étant donné** un utilisateur sur `/settings/account`, **quand** il choisit "Exporter mes données (JSON)", **alors** un fichier `kbudget-export-{user_id}-{date}.json` est téléchargé contenant l'intégralité des entités liées à son compte, structuré par entité (groupé) avec une clé `schemaVersion` SemVer top-level (initial : `"1.0.0"`).
2. **Étant donné** un utilisateur sur `/settings/account`, **quand** il choisit "Exporter mes transactions (CSV)", **alors** un fichier `kbudget-transactions-{user_id}-{date}.csv` est téléchargé avec entêtes en français (date, libellé, montant, devise, compte, catégorie, type).
3. **Étant donné** un utilisateur ayant 0 transaction, **quand** il déclenche l'export CSV, **alors** un fichier vide avec entêtes seulement est téléchargé sans erreur.

---

### User Story 5 — Supprimer son compte (Priorité : P3)

En tant qu'utilisateur authentifié, je veux pouvoir supprimer mon compte de manière définitive après confirmation explicite, pour cesser toute utilisation de l'application et respecter mon droit à l'oubli.

**Why this priority** : Action rare mais nécessaire (RGPD, autonomie). Implémentée en soft-delete pour préserver la traçabilité (invitations en `RESTRICT`, auditabilité). Faible fréquence d'usage (16 users self-hosted, action quasi-jamais utilisée), donc P3 dans le scope mais essentielle à l'arsenal.

**Independent Test** : Déclencher la suppression avec confirmation par mot de passe, vérifier que `users.disabled_at` est positionné, que le login échoue ensuite, et que les données restent en DB (soft, pas hard).

**Acceptance Scenarios** :

1. **Étant donné** un utilisateur sur `/settings/account`, **quand** il déclenche "Supprimer mon compte" et saisit son MDP correct dans la modale de confirmation (saisie MDP + checkbox "Je comprends que cette action est définitive"), **alors** `users.disabled_at` est positionné à `now()` et il est immédiatement déconnecté.
2. **Étant donné** un utilisateur ayant supprimé son compte, **quand** il tente un login, **alors** la connexion est rejetée avec un message indiquant que le compte est désactivé.
3. **Étant donné** un utilisateur saisissant un MDP incorrect dans la modale de confirmation, **quand** il valide, **alors** la suppression n'est pas effectuée et une erreur 401 est affichée.
4. **Étant donné** les données d'un utilisateur supprimé, **quand** un admin consulte la base, **alors** toutes les entités liées (transactions, comptes, etc.) sont conservées (soft-delete, pas de cascade).

---

### Edge Cases

- **Upload avatar échoue (taille > limite, format non supporté)** : afficher une erreur claire, ne pas modifier l'avatar existant.
- **Connexion réseau perdue pendant un upload avatar ou un export** : afficher une erreur, permettre à l'utilisateur de réessayer sans état corrompu.
- **Utilisateur clique sur "Déconnexion" alors que son refresh token est déjà expiré** : la déconnexion locale doit fonctionner même si l'appel `/auth/logout` échoue.
- **Utilisateur change son MDP puis ferme l'app sans recharger** : son JWT actuel sur le device courant reste valide (un nouveau JWT est émis dans la réponse de change-password). Sur les autres devices, le JWT reste valide jusqu'à expiration naturelle (≤ 15 min) mais leurs refresh tokens sont révoqués — impossible de renouveler la session.
- **Suppression de compte alors que l'utilisateur a invité d'autres users (`Invitation.invited_by_user_id`)** : la contrainte FK `RESTRICT` ne doit pas bloquer la suppression grâce au soft-delete (le user reste en base).
- **Export demandé sur un compte avec plusieurs milliers de transactions** : l'export sync doit rester sous une limite de temps acceptable (ex: 5s pour 10 000 transactions) sinon prévoir une pagination ou un mode async.
- **Utilisateur supprime son avatar puis recharge la page** : les initiales doivent réapparaître correctement.
- **Admin se supprime lui-même** : le soft-delete doit-il être autorisé pour un admin ? Si oui, l'instance peut se retrouver sans admin actif. À traiter en règle métier (refus si seul admin actif).

---

## Requirements *(mandatory)*

### Functional Requirements

**Navigation & Page**

- **FR-001** : Le système DOIT exposer une route lazy-loaded `/settings/account` accessible depuis le Settings hub (Angular et Flutter).
- **FR-002** : La page Mon compte DOIT afficher 4 sections distinctes : Identité, Sécurité, Données, Zone de danger.

**Identité**

- **FR-003** : L'utilisateur DOIT pouvoir modifier son nom inline ; la persistance utilise `PUT /users/me` existant.
- **FR-004** : L'utilisateur DOIT pouvoir uploader une image avatar via `POST /users/me/avatar`.
- **FR-005** : Le système DOIT servir l'avatar via `GET /users/me/avatar` avec en-têtes de cache appropriés.
- **FR-006** : L'utilisateur DOIT pouvoir supprimer son avatar via `DELETE /users/me/avatar` ; le système revient aux initiales générées.
- **FR-007** : Le système DOIT afficher l'email en lecture seule avec la mention "Géré par l'admin" — aucun endpoint de modification self-service de l'email ne doit exister.

**Sécurité**

- **FR-008** : L'utilisateur DOIT pouvoir changer son mot de passe via `POST /users/me/password` avec `currentPassword` et `newPassword`.
- **FR-009** : Le système DOIT vérifier le `currentPassword` via BCrypt avant toute mise à jour ; échec = 401.
- **FR-010** : Le système DOIT exiger un `newPassword` de min 12 caractères, différent du `currentPassword` ; échec = 400.
- **FR-011** : Le système DOIT aligner la politique de mot de passe à 12 caractères dans `FirstLoginResetRequest` (mise à jour de l'existant).

**Déconnexion**

- **FR-012** : Le bouton Déconnexion sur Angular DOIT être branché à `authService.logout()` qui appelle `POST /auth/logout` (révocation refresh token), purge le JWT local et redirige vers `/login`.
- **FR-013** : Le système DOIT exécuter la déconnexion locale même si l'appel backend échoue (résilience).

**Données**

- **FR-014** : L'utilisateur DOIT pouvoir exporter l'intégralité de ses données via `GET /users/me/export?format=json` (téléchargement direct synchrone).
- **FR-015** : L'utilisateur DOIT pouvoir exporter ses transactions via `GET /users/me/export?format=csv` (téléchargement direct synchrone).
- **FR-016** : L'export JSON DOIT inclure toutes les entités liées au user : transactions, comptes, catégories, budgets, abonnements, dettes, préférences, règles d'import, profils d'import, historique d'import.
- **FR-017** : L'export CSV DOIT contenir les transactions avec entêtes en français : `Date`, `Libellé`, `Montant`, `Devise`, `Compte`, `Catégorie`, `Type`. La colonne `Type` expose l'enum `TransactionType` traduit ("Revenu" / "Dépense" / "Transfert"). Encodage UTF-8 avec BOM pour compatibilité Excel.

- **FR-017a** : L'export JSON DOIT respecter la structure groupée par entité avec metadata top-level :
  ```json
  {
    "schemaVersion": "1.0.0",
    "exportedAt": "<ISO-8601>",
    "user": { ... },
    "preferences": { ... },
    "accounts": [...],
    "categories": [...],
    "transactions": [...],
    "budgets": [...],
    "budgetSnapshots": [...],
    "subscriptions": [...],
    "debts": [...],
    "categoryRules": [...],
    "importProfiles": [...],
    "importHistory": [...]
  }
  ```
  Le champ `schemaVersion` suit SemVer ; toute évolution future du schéma DOIT incrémenter cette version (PATCH = correction, MINOR = ajout d'entité, MAJOR = breaking change de structure).

**Suppression**

- **FR-018** : L'utilisateur DOIT pouvoir supprimer son compte via `DELETE /users/me` avec confirmation par mot de passe.
- **FR-019** : La suppression DOIT être implémentée en soft-delete : positionnement de `users.disabled_at = now()` sans suppression physique des données.
- **FR-020** : Le système DOIT bloquer le login d'un utilisateur dont `users.disabled_at IS NOT NULL` (filtre dans `findByEmail`).
- **FR-021** : Le système DOIT empêcher la suppression du dernier admin actif (refus avec erreur claire).

**Audit & Logs**

- **FR-022** : Le système DOIT logger en INFO via SLF4J les actions sensibles : changement de mot de passe, suppression de compte, upload/suppression avatar.

**Continuité de session après changement de mot de passe**

- **FR-023** : Lors d'un changement de mot de passe via `POST /users/me/password`, le système DOIT révoquer immédiatement tous les `RefreshToken` du user concerné (cascade DB).
- **FR-024** : Lors d'un changement de mot de passe, le système DOIT émettre un nouveau couple JWT + refresh token pour le device courant (continuité UX) dans la réponse de l'endpoint.
- **FR-025** : Le JWT actuel sur les autres devices reste valide jusqu'à son expiration naturelle (TTL court ≤ 15 minutes). Aucune blocklist JWT n'est introduite (cohérence avec stateless JWT et constitution YAGNI). Les autres devices ne pourront pas renouveler leur session car leurs refresh tokens sont révoqués.

### Non-Functional Requirements

- **NFR-001 (Sécurité)** : Toutes les routes `/users/me/*` DOIVENT être protégées par JWT (filtrage par user authentifié — principe constitutionnel #2).
- **NFR-002 (Sécurité)** : L'upload avatar DOIT valider le type MIME côté serveur via les magic numbers (pas seulement l'extension), accepter exclusivement `image/jpeg` et `image/png`, et limiter la taille à 2 MB.
- **NFR-003 (Sécurité)** : Aucun endpoint ne doit permettre à un utilisateur non-admin de modifier l'email (privilege escalation via `ADMIN_EMAILS`).
- **NFR-004 (Performance)** : L'export JSON synchrone DOIT répondre en moins de 5 secondes pour un compte avec 10 000 transactions.
- **NFR-005 (Cohérence)** : La parité Angular ↔ Flutter DOIT être à 100% sur la page Mon compte (toutes les sections présentes des deux côtés).
- **NFR-006 (UX)** : L'avatar uploadé DOIT être redimensionné côté serveur en 256x256 pixels (sortie JPEG ~85% qualité) pour limiter le poids des requêtes et homogénéiser le rendu.
- **NFR-007 (Observabilité)** : Toutes les erreurs sur les nouveaux endpoints DOIVENT être tracées en ERROR via SLF4J avec corrélation user_id (principe constitutionnel #6).
- **NFR-008 (Self-Hosted Ready)** : Le stockage des avatars DOIT utiliser le disque local (chemin configurable via property), pas de dépendance externe (principe constitutionnel #7).
- **NFR-009 (Design)** : Le design DOIT réutiliser les patterns existants (`.settings-row`, `.settings-section`, `app-empty-state`, `SettingsItem`) — `DESIGN.md` reste inchangé.

### Key Entities

- **User (existant)** : Représente le compte utilisateur. Nouveaux champs : `disabled_at` (timestamp nullable, soft-delete) et `avatar_path` (varchar nullable, chemin disque). Champ `password_hash` BCrypt déjà présent.
- **Avatar (nouvel artefact)** : Représente l'image de profil. Stocké sur disque local (path en DB). Servi via endpoint dédié avec cache. Pas d'entité JPA — fichier binaire référencé par `users.avatar_path`.
- **AuditLog (logique, pas d'entité)** : Trace des actions sensibles via SLF4J INFO (changement MDP, suppression compte, upload/suppression avatar). Pas de table dédiée — logs applicatifs uniquement.
- **Export (artefact transient)** : Fichier généré à la volée à la demande (JSON ou CSV). Pas de persistance.

### Migrations DB

- **MIG-001** : Ajout colonne `users.disabled_at TIMESTAMP NULL`.
- **MIG-002** : Ajout colonne `users.avatar_path VARCHAR(512) NULL`.
- **MIG-003** : Patch `budgets.user_id` FK → ajout `ON DELETE CASCADE` (filet de sécurité, audit isolation a révélé l'absence).
- **MIG-004** : Patch `budget_snapshots.user_id` FK → ajout `ON DELETE CASCADE` (idem).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (US1)** : 100% des utilisateurs Angular peuvent se déconnecter en un clic depuis la page Mon compte (vérification : test E2E sur le flow login → settings → account → logout → redirect login).
- **SC-002 (US1)** : La page `/settings/account` est accessible depuis Settings en moins de 2 taps sur mobile (Settings hub → tap sur "Mon compte").
- **SC-003 (US2)** : Un utilisateur peut modifier son nom et le voir refleté dans toute l'application en moins de 3 secondes (vérification : test d'intégration UI).
- **SC-004 (US2)** : Un avatar uploadé est servi en moins de 200 ms après upload (incluant redimensionnement) pour une image de 2 MB.
- **SC-005 (US3)** : Le changement de mot de passe est rejeté en moins de 100 ms si la politique n'est pas respectée (validation côté backend ou frontend).
- **SC-006 (US3)** : Aucun utilisateur ne peut changer son mot de passe sans fournir le mot de passe actuel correct (vérification : test d'intégration backend).
- **SC-007 (US4)** : L'export JSON contient 100% des entités liées au user (vérification : test backend comparant l'export à un dump direct DB).
- **SC-008 (US4)** : L'export CSV pour 10 000 transactions répond en moins de 5 secondes (vérification : test de charge).
- **SC-009 (US5)** : Un utilisateur ayant supprimé son compte ne peut plus se connecter (vérification : test d'intégration login après soft-delete).
- **SC-010 (US5)** : Aucune donnée n'est physiquement supprimée lors d'une suppression de compte (vérification : comparaison DB avant/après).
- **SC-011 (Bug fix)** : Le bouton Déconnexion Angular passe de "non fonctionnel" à "fonctionnel" — vérifié par test E2E ciblé.
- **SC-012 (Parité)** : 100% des sections (Identité, Sécurité, Données, Zone de danger) présentes côté Angular ET Flutter (vérification : checklist de parité dans review).
- **SC-013 (Sécurité)** : 0 endpoint permet à un utilisateur non-admin de modifier son email (vérification : audit endpoints).
- **SC-014 (Politique MDP)** : 100% des flows de changement/reset de MDP exigent min 12 caractères (vérification : test d'intégration sur `FirstLoginResetRequest` ET `ChangePasswordRequest`).

---

## Assumptions

- **A-001** : L'audit isolation effectué en phase sparring (17/19 entités propres) est représentatif de l'état au moment de l'implémentation. Si de nouvelles entités sont ajoutées entre temps, elles devront respecter le principe d'isolation #2 de la constitution. **Impact si fausse** : risque de données orphelines lors du soft-delete.
- **A-002** : Le `BCryptPasswordEncoder` injecté actuellement reste utilisé pour le change-password ; aucun changement d'algorithme prévu. **Impact si fausse** : refactoring du flow first-login-reset à prévoir.
- **A-003** : Les 16 utilisateurs cibles n'ont pas plus de quelques milliers de transactions chacun ; l'export sync direct est viable. **Impact si fausse** : nécessité d'un export async avec queue (hors scope actuel).
- **A-004** : Le stockage disque local pour les avatars est conforme à l'environnement self-hosted ; aucune contrainte de scale horizontal. **Impact si fausse** : migration vers S3-compatible nécessaire.
- **A-005** : L'admin gère l'email des utilisateurs via une UI ou un script, hors scope de cette feature. **Impact si fausse** : utilisateurs non-autonomes pour changer leur email — à clarifier avec une feature complémentaire.
- **A-006** : Le bug du bouton déconnexion sans handler est confirmé par audit ; l'implémentation se fera dans la même feature. **Impact si fausse** : retravail si le bouton avait déjà un handler caché.
- **A-007** : La suppression d'un user en soft-delete n'impacte pas les rapports financiers existants (budgets, snapshots) car ces entités restent en DB. **Impact si fausse** : adapter les requêtes pour filtrer les users disabled.

---

## Dépendances et Contraintes

### Dépendances internes

- **KKS-233** (Bootstrap premier admin) : la politique de promotion admin (`ADMIN_EMAILS` au boot) doit rester intacte. Aucune modification de l'email self-service ne doit interférer.
- **Endpoints existants réutilisés** : `GET /users/me`, `PUT /users/me` (extension nom only), `POST /auth/logout`, `POST /auth/refresh`.
- **Composants UI réutilisés (Angular)** : `.settings-row`, `.settings-section`, `app-empty-state`, segmented controls.
- **Composants UI réutilisés (Flutter)** : `SettingsItem`, `_ReadOnlyField`, pattern `bottom-sheet` pour confirmations.

### Contraintes techniques

- **Constitution #2** (Sécurité par défaut) : JWT obligatoire sur toutes les nouvelles routes, filtrage par user authentifié.
- **Constitution #6** (Observabilité) : SLF4J/Logback uniquement. INFO pour actions sensibles, ERROR pour erreurs.
- **Constitution #7** (Self-Hosted Ready) : pas de dépendance infra hors PostgreSQL et disque local.
- **Stack Angular signals-first** : les nouveaux composants utilisent `signal()`, `computed()`, `input()`, `output()`, `inject()` (pas de `@Input/@Output` legacy).
- **Stack Flutter Riverpod-first** : nouveaux états via `Notifier` + `NotifierProvider`, modèles immutables via Freezed.
- **Tests obligatoires** : nommage `should_[résultat]_when_[condition]` (constitution #5).

### Contraintes de design

- **DESIGN.md** : aucune nouvelle règle de design — utilisation exclusive des tokens existants (`var(--token-*)`).
- **Mobile-First** (constitution #4) : saisie en 2-3 interactions, parité Angular/Flutter.
- **Quiet utility dark-first** : pas de couleur rouge sur le bouton Déconnexion (réversible) — réservée à la suppression de compte.

---

## Questions ouvertes

> Toutes les questions identifiées en spec ont été résolues lors de `/devflow.clarify` (cf. [`clarify-log.md`](./clarify-log.md)). Cette section est conservée pour traçabilité historique.

| # | Question | Statut | Résolution |
|---|----------|--------|------------|
| Q1 | Confirmation suppression compte : MDP seul ou MDP + email (pattern GitHub) ? | ✅ Résolu | MDP seul + checkbox de confirmation explicite (cf. CL-002) |
| Q2 | Format avatar : taille, formats, redimensionnement | ✅ Résolu | JPG/PNG only, max 2 MB, redim serveur 256x256 JPEG ~85% (cf. CL-001) |
| Q3 | Export JSON : structure et versionning | ✅ Résolu | Groupé par entité, clé `schemaVersion` SemVer top-level "1.0.0" (cf. CL-003) |
| Q4 | JWT après changement MDP : révocation ou expiration naturelle ? | ✅ Résolu | Révocation refresh tokens + nouveau JWT device courant + JWT autres devices expire naturellement (cf. CL-004) |
| Q5 | Format CSV entête `Type` : valeur brute enum ou traduit ? | ✅ Résolu | Traduction française "Revenu" / "Dépense" / "Transfert" + UTF-8 BOM (cf. CL-005) |

---

## Notes de traçabilité

- **Sparring** : décisions tranchées le 2026-04-30 sur la base de 4 audits parallèles (isolation données, bootstrap admin, endpoints existants, frontend Settings).
- **Audits clés** :
  - 17/19 entités JPA isolées proprement par user_id ; 2 patchs CASCADE à appliquer.
  - Email = identité JWT subject + clé lookup ; non éditable confirmé.
  - Pattern sous-pages lazy-loaded déjà établi côté Angular (`/settings/accounts`, `/settings/categories`, etc.).
  - Bouton déconnexion Angular sans handler — bug confirmé, à fixer dans la feature.
- **Issue Linear** : [KKS-235](https://linear.app/kksdev/issue/KKS-235/page-mon-compte-profil-securite-donnees-suppression-fix-bouton)
