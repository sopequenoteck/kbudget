# Clarify Log — KKS-233 : Bootstrap du premier admin sur DB vide (pattern password généré au premier boot)

> Date : 2026-04-22
> Issue : KKS-233
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md §Q3 + inspection code `AdminAuthorizationFilter` | Architecture du statut admin : champ en DB (`isAdmin`) ou dérivation dynamique via `ADMIN_EMAILS` ? | 11 Sécurité | H | H | CRITIQUE | Ajouter `isAdmin` sur `User` + refactor `AdminAuthorizationFilter` + promotion au démarrage via `ADMIN_EMAILS` (ajout only) + migration Flyway de seed initial | Interactif |
| CL-002 | spec.md §Q1 + Edge Case "Accès concurrent" | Mécanisme d'invalidation des JWT émis avec `passwordResetRequired = true` au moment du reset | 11 Sécurité | M | H | HAUT | Claim JWT `mustResetCredentials` + double vérification (claim côté filtre + flag DB côté endpoint reset). Pas de blocklist, pas de rotation de secret | Auto |
| CL-003 | spec.md §FR-009 + §FR-011 | Contraintes de longueur et de validation du nouveau password | 11 Sécurité | B | B | BAS | `@Size(min = 8, max = 100)` aligné sur `AcceptInviteRequest` (KKS-232) | Auto |
| CL-004 | spec.md §FR-011 | Méthode exacte de comparaison pour refuser un password identique à l'actuel | 11 Sécurité | M | B | BAS | `BCryptPasswordEncoder.matches(newPlaintext, oldHash)` → si `true`, renvoyer `400` avec payload `{ error: "PASSWORD_UNCHANGED" }` | Auto |
| CL-005 | spec.md §Q2 + Edge Case "BOOTSTRAP_EMAIL invalide" | Comportement si `BOOTSTRAP_EMAIL` est défini avec une valeur non conforme au format email | 7 Contraintes | B | B | BAS | Fail-fast au démarrage avec message clair identifiant la variable et la valeur observée. Pas de fallback silencieux | Auto |

## Points différés

| # | Point identifié | Catégorie | Score | Raison du report |
|---|-----------------|-----------|-------|------------------|
| Q-DIFF-01 | Présence du champ `mustResetCredentials` (toujours vs conditionnel) dans la réponse `POST /api/auth/login` | 3 UX/Interaction | BAS | Décision de contrat API à aligner avec les conventions du DTO `LoginResponse` existant en phase `/devflow.plan` |
| Q-DIFF-02 | Véhicule du JWT post-reset (body JSON vs cookie HttpOnly) | 5 Intégrations | BAS | À aligner sur la convention déjà retenue pour `login` et `accept-invite` en phase `/devflow.plan` |
| Q-DIFF-03 | Format exact de la bannière WARN (largeur, caractère d'encadrement, alignement) | 10 Placeholders | BAS | Détail cosmétique non bloquant — à traiter au moment de l'implémentation |
| Q-DIFF-04 | `displayName` obligatoire ou optionnel dans `first-login-reset` | 2 Modèle de données | BAS | Impact faible, à trancher en phase `/devflow.plan` lors de la définition du DTO `FirstLoginResetRequest` |
| Q-DIFF-05 | Périmètre du seed pour le compte admin initial — inclure ou non `categoryService.seedSystemCategories(user)` | 1 Scope fonctionnel | BAS | Ajouté suite à la review-spec itération 1 (WARNING-01). Dépend de la décision de réutilisation complète vs partielle de la logique `accept-invite` de KKS-232 — à trancher en phase `/devflow.plan` |

---

## Résolutions détaillées

### CL-001 — Architecture du statut admin : DB vs `ADMIN_EMAILS`

- **Catégorie** : 11 Sécurité
- **Score** : CRITIQUE (Impact H × Incertitude H)
- **Contexte** : La spec initiale (FR-002, FR-012, US-004, SC-005) mentionnait `role = ADMIN` stocké en DB et une règle "`ADMIN_EMAILS` = source d'ajout uniquement". Inspection du code actuel (`api/src/main/java/fr/kksdev/budget/api/config/AdminEmailResolver.java` et `AdminAuthorizationFilter.java`) : le statut admin est **résolu dynamiquement à chaque requête** via `adminEmailResolver.isAdminEmail(user.getEmail())`. Aucun champ `role` ou `isAdmin` n'existe sur l'entité `User`. Conséquence : sans modification, après un reset vers un email absent de `ADMIN_EMAILS`, le self-hoster perdrait immédiatement son accès administrateur, contredisant la promesse "docker compose up -d et c'est parti, pas de config à toucher".
- **Analyse des options** :
  - **Option A (retenue)** : ajouter un champ `isAdmin` en DB, refactorer `AdminAuthorizationFilter` pour lire ce champ, transformer `ADMIN_EMAILS` en source de promotion au démarrage uniquement (ajout `false → true`, jamais retrait). Coût modéré (migration + refactor filter + service de sync au boot + seed Flyway initial depuis `ADMIN_EMAILS`). Bénéfice : architecture cohérente avec la promesse UX et découplage `role / env var`.
  - **Option B** : garder l'architecture actuelle et documenter "après reset, mettez à jour `ADMIN_EMAILS` et redémarrez". Moins coûteux mais casse la promesse UX.
  - **Option C** : hybride (`isAdmin OR isAdminEmail(email)`). Dette technique immédiate, double source de vérité.
- **Décision** (session sparring — option retenue par Kelly) : **Option A**.
- **Spécifications détaillées de la résolution** (alignées post-review-spec itération 2 avec FR-012 / FR-012a / FR-012b) :
  1. Ajouter un champ `isAdmin` (boolean, non-null, défaut `false`) sur l'entité `User` via migration Flyway (cf. FR-012a). La migration exécute un `ALTER TABLE` uniquement et NE DOIT PAS lire `ADMIN_EMAILS` (la variable n'est pas accessible dans le contexte SQL Flyway).
  2. La promotion initiale des users existants dont l'email figure dans `ADMIN_EMAILS` est réalisée par le synchroniseur applicatif au démarrage (cf. FR-012b), pas par la migration. Ce synchroniseur est idempotent et s'exécute à chaque démarrage.
  3. Modifier `AdminAuthorizationFilter` pour résoudre le statut admin via `user.isAdmin()` au lieu de `adminEmailResolver.isAdminEmail(email)` (cf. FR-012).
  4. Modifier `UserService.toResponse()` pour alimenter `UserResponse.isAdmin` depuis `user.isAdmin()` et non plus depuis `adminEmailResolver.isAdminEmail(email)` (cf. FR-012). Ce point est critique pour éviter une désynchronisation entre la source autoritaire en base et l'affichage front.
  5. Conserver `AdminEmailResolver` pour ses autres usages (ex. validation d'email cible dans le flux d'invitation KKS-232), mais ne plus s'en servir dans le filtre d'autorisation ni dans le mapping `UserResponse`.
- **Impact sur spec.md** :
  - FR-002 : `role = ADMIN` → `isAdmin = true`.
  - FR-012 : reformulé — passage à champ DB + sémantique `ADMIN_EMAILS` = promotion au boot + migration Flyway.
  - US-001 Independent Test + Scenario 1 : `role = ADMIN` → `isAdmin = true`.
  - US-004 : reformulée intégralement autour de `isAdmin` (+ nouveau scénario pour pas-de-rétrogradation).
  - SC-002, SC-005 : ajustés.
  - Key Entities `User` : mention explicite du nouveau champ.
  - Assumptions : retrait de l'hypothèse sur logique `ADMIN_EMAILS` actuelle (remplacée par une assumption sur l'absence de régression du refactor).

### CL-002 — Invalidation JWT au reset

- **Catégorie** : 11 Sécurité
- **Score** : HAUT (Impact M × Incertitude H)
- **Contexte** : Question ouverte Q1 de la spec + edge case "accès concurrent avec credentials initiaux". Plusieurs sessions simultanées avec les mêmes credentials initiaux peuvent émettre plusieurs JWT avec `passwordResetRequired = true`. Au moment du reset par l'une d'elles, les autres JWT doivent devenir inutiles.
- **Analyse** :
  - Les JWT sont stateless : le changement de password ou du flag DB ne les invalide pas automatiquement côté serveur.
  - Options envisagées : (a) blocklist JWT en mémoire, (b) rotation du secret, (c) claim JWT + double-check DB.
  - (a) et (b) sont coûteux et superflus pour un scénario extrêmement rare (fenêtre de quelques minutes entre premier boot et reset).
  - (c) est suffisant : un JWT émis avec `mustResetCredentials: true` porte ce claim jusqu'à expiration. Après reset, le flag DB passe à `false` : l'ancien JWT conserve son claim `true` et reste bloqué sur tous les endpoints protégés par le filtre (qui impose claim=true → seul `first-login-reset` autorisé). L'endpoint `first-login-reset` lui-même vérifie `user.passwordResetRequired == true` côté DB : pour un JWT encore marqué `mustResetCredentials=true` mais dont le user en DB a `passwordResetRequired=false`, l'endpoint répond `403`. L'ancien JWT est neutralisé sans blocklist.
- **Décision** : implémentation (c) — claim JWT + double-check DB.
- **Impact sur spec.md** :
  - FR-008 : précisé (claim JWT + double vérification).
  - Edge Case "Accès concurrent" : résolution documentée, marqueur `[NEEDS CLARIFICATION]` retiré.

### CL-003 — Contraintes de longueur du password dans `first-login-reset`

- **Catégorie** : 11 Sécurité
- **Score** : BAS (Impact B × Incertitude B)
- **Contexte** : FR-009 mentionnait "Bean Validation (format email, password min length)" sans précision.
- **Analyse** : inspection de `api/src/main/java/fr/kksdev/budget/api/dto/request/AcceptInviteRequest.java` : `@NotBlank @Size(min = 8, max = 100) String password`. Le flux `accept-invite` de KKS-232 est le point de référence naturel puisque `first-login-reset` partage la même logique métier (création ou mise à jour de credentials via input utilisateur).
- **Décision** : aligner sur `AcceptInviteRequest` → `@NotBlank @Size(min = 8, max = 100)` pour `password`. `@Email @NotBlank @Size(max = 255)` pour `email`. `@NotBlank @Size(min = 1, max = 100)` pour `displayName`.
- **Impact sur spec.md** :
  - FR-009 : contraintes Bean Validation explicitées avec références à `AcceptInviteRequest`.

### CL-004 — Méthode de comparaison pour refuser un password identique

- **Catégorie** : 11 Sécurité
- **Score** : BAS (Impact M × Incertitude B)
- **Contexte** : FR-011 proposait "comparaison post-BCrypt ou comparaison des plaintexts avant hash" sans trancher.
- **Analyse** : les hashes BCrypt ne sont pas comparables directement entre eux (chaque hash intègre un salt aléatoire). La méthode canonique est `BCryptPasswordEncoder.matches(rawPassword, encodedPassword)` qui recalcule le hash du plaintext avec le salt de l'ancien hash et compare. Cohérent avec toute la base de code Spring Security du projet.
- **Décision** : utiliser `BCryptPasswordEncoder.matches(newPlaintext, user.getPassword())`. Si `true`, retourner `400 Bad Request` avec payload `{ error: "PASSWORD_UNCHANGED", message: "Le nouveau mot de passe doit être différent de l'actuel." }`.
- **Impact sur spec.md** :
  - FR-011 : méthode précisée + payload d'erreur normalisé.

### CL-005 — Comportement sur `BOOTSTRAP_EMAIL` invalide

- **Catégorie** : 7 Contraintes
- **Score** : BAS (Impact B × Incertitude B)
- **Contexte** : Edge case "BOOTSTRAP_EMAIL invalide" (format non-email) laissait en suspens entre fail-fast et fallback silencieux.
- **Analyse** :
  - Convention Spring Boot standard : valider la configuration au démarrage (`@ConfigurationProperties` + JSR-303 Bean Validation) et faire échouer le démarrage sur configuration invalide.
  - Un fallback silencieux créerait un user admin avec un email non-ressaisissable si l'utilisateur voulait précisément personnaliser l'email — bug silencieux inacceptable.
  - Le coût d'implémentation du fail-fast est trivial : validation `@Email` sur la property au PostConstruct du service de bootstrap.
- **Décision** : fail-fast au démarrage avec message identifiant la variable (`BOOTSTRAP_EMAIL`) et la valeur observée. Pas de fallback.
- **Impact sur spec.md** :
  - Nouveau FR-017 ajouté.
  - Edge Case "BOOTSTRAP_EMAIL invalide" : résolution documentée.

---

## Synthèse

- **Points identifiés** : 10 (5 résolus dans cette session + 5 différés, dont Q-DIFF-05 ajouté post-review-spec itération 1).
- **Catégories couvertes** : 6/11 (Scope fonctionnel, Modèle de données, UX/Interaction, Intégrations, Contraintes, Placeholders, Sécurité).
- **Résolutions automatiques** : 4/5 (CL-002, CL-003, CL-004, CL-005).
- **Résolutions interactives** : 1/5 (CL-001, validé avec Kelly — Option A retenue).
- **Points différés à `/devflow.plan`** : 5 (Q-DIFF-01 à Q-DIFF-05).
- **Modifications appliquées à `spec.md`** (incluant pré-corrections post-review-spec itération 1) : FR-002, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-016 reformulés ; FR-012a, FR-012b, FR-017, FR-018 ajoutés ; US-001 et US-004 ajustés ; Edge Cases mis à jour (2 marqueurs `[NEEDS CLARIFICATION]` retirés, renvois internes corrigés) ; Key Entities `User` précisée ; SC-001, SC-002, SC-005 ajustés ; Assumptions mises à jour (scope refactor couvrant toutes versions d'endpoints admin + impact front) ; Dépendances enrichies avec la liste explicite des deux migrations Flyway ; section "Questions ouvertes" complétée avec Q-DIFF-05.
- **Marqueurs `[NEEDS CLARIFICATION]` restants dans `spec.md`** : 0.
