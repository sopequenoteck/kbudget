# Review Log — KKS-233

> Issue : KKS-233 — Bootstrap du premier admin sur DB vide (pattern password généré au premier boot)

---

## Review Spec — 2026-04-22 (itération 1)

**Mode** : review-spec
**Agent** : devflow-review
**Verdict** : **PASS**

### Grille d'évaluation

| Passe | Critère | Statut |
|-------|---------|--------|
| Complétude | Toutes les sections remplies | OK |
| Complétude | Au moins 1 US P1 | OK (US-001, US-002) |
| Complétude | Au moins 1 FR | OK (17 FR) |
| Complétude | SC définis et mesurables | OK (SC-001 à SC-007) |
| Complétude | Key Entities identifiées | OK |
| Complétude | Assumptions documentées | OK |
| Clarté | Pas de termes ambigus | OK |
| Clarté | Format Given/When/Then respecté | OK |
| Clarté | Chaque US a "Why this priority" + "Independent Test" | OK |
| Testabilité | Chaque FR a des critères mesurables | Partiel — cf. MAJEUR-01 |
| Testabilité | SC avec méthode de vérification | OK |
| Cohérence spec / clarify-log | Résolutions reflétées dans spec | OK (CL-002/3/4/5), Partiel (CL-001) |
| Cohérence | Pas de contradiction entre requirements | Partiel — cf. MAJEUR-02 |
| Cohérence | US/FR alignés | OK |
| Cohérence | Key Entities cohérentes avec US | Partiel — cf. MAJEUR-03 |
| Clarification | Tous les `[NEEDS CLARIFICATION]` retirés | OK (0 restant) |
| Clarification | Questions ouvertes résolues ou légitimement différées | OK |

### Constats

#### BLOQUANT

Aucun.

#### MAJEUR

- **MAJEUR-01 — FR-012 : mécanisme Flyway ambigu pour la promotion initiale via `ADMIN_EMAILS`**
  `ADMIN_EMAILS` est une variable d'environnement résolue dans le contexte Spring, non disponible dans une migration SQL standard. La spec ne tranche pas entre `BaseJavaMigration` et promotion via `ApplicationRunner` (synchroniseur au démarrage). À préciser dans `plan.md`.

- **MAJEUR-02 — Refactor `AdminAuthorizationFilter` incomplet : `UserService.toResponse()` non mentionné**
  `UserService.toResponse()` ligne 53 appelle encore `adminEmailResolver.isAdminEmail(user.getEmail())` pour alimenter le champ `isAdmin` du DTO `UserResponse`. Si non refactoré, le front verra un statut admin incohérent avec la source autoritaire `user.isAdmin()`. À ajouter au scope du refactor FR-012.

- **MAJEUR-03 — Migrations Flyway absentes de la liste des livrables explicites**
  Deux migrations sont dans le scope (ajout `isAdmin` + seed, ajout `passwordResetRequired`) mais ne sont pas listées comme artefacts techniques dans les Constraints & Dependencies. Risque d'oubli au passage `/devflow.tasks`.

#### WARNING

- **WARNING-01 — FR-003** : la logique `accept-invite` de KKS-232 seed aussi les catégories système via `categoryService.seedSystemCategories(user)`. La spec ne précise pas si le seed admin doit les inclure. À trancher en phase plan.

- **WARNING-02 — FR-008** : un JWT avec claim `mustResetCredentials` bloque tous les endpoints sauf `first-login-reset`. Impact non couvert sur `/api/auth/logout` ou endpoints de refresh token si existants.

- **WARNING-03 — SC-001** : critère de 5 minutes basé sur un chronométrage manuel. Pas de lien explicite avec `docs/deployment.md` ni de précision sur l'exécutant du test.

- **WARNING-04 — FR-016** : exclusion Flutter formulée en exigence négative sans critère de vérification automatique (pas de garde-fou contre une modification accidentelle).

#### INFO

- **INFO-01** : Q-DIFF-01 / Q-DIFF-02 différés mais impact sur SC-004 et scénarios US-002. À surveiller en review-tasks.
- **INFO-02** : Edge Case "Reset avec email déjà utilisé" renvoie à FR-008 incorrectement — devrait renvoyer à FR-010.
- **INFO-03** : Assumption sur refactor `AdminAuthorizationFilter` mentionne seulement « endpoints `/admin/*` livrés par KKS-232 » — trop restrictif, devrait couvrir l'ensemble des endpoints admin existants.
- **INFO-04** : asymétrie potentielle claim JWT `mustResetCredentials` (conditionnel si `true`) vs champ DTO `LoginResponse.mustResetCredentials` (Q-DIFF-01 pas encore tranché). À expliciter au plan.
- **INFO-05** : fail-fast `BOOTSTRAP_EMAIL` via `@PostConstruct` (clarify-log CL-005) à préférer probablement avec `@ConfigurationProperties + @Validated` pour un message d'erreur structuré. À préciser au plan.

### Justification du verdict

La spec est complète, structurée et cohérente. Toutes les résolutions du clarify-log sont reflétées, aucun marqueur `[NEEDS CLARIFICATION]` ne subsiste. Les 5 US couvrent les scénarios critiques, les 17 FR sont mesurables pour la plupart, les 7 SC ont des méthodes de vérification.

Les 3 constats MAJEUR portent sur des points d'implémentation qui relèvent légitimement de `plan.md` (mécanisme Flyway précis, surface du refactor admin, liste explicite des migrations). Ils ne bloquent pas la transition vers research/plan mais doivent être adressés dans ces phases pour éviter l'ambiguïté d'implémentation.

---

## Review Spec — 2026-04-22 (itération 2, post-corrections)

**Mode** : review-spec
**Agent** : devflow-review
**Verdict** : **PASS**

### Contexte

Itération déclenchée par l'utilisateur après application de pré-corrections ciblées sur les 3 MAJEUR et 4 WARNING de l'itération 1.

### Grille d'évaluation — points clés

| Constat initial | Statut itération 2 |
|-----------------|--------------------|
| MAJEUR-01 — FR-012 mécanisme Flyway ambigu | **RÉSOLU** (FR-012 + FR-012a + FR-012b) |
| MAJEUR-02 — `UserService.toResponse()` hors scope | **RÉSOLU** (FR-012 enrichi) |
| MAJEUR-03 — migrations Flyway non listées | **RÉSOLU** (section Dépendances enrichie) |
| WARNING-01 — seed catégories système | **ADRESSÉ** (Q-DIFF-05 ajouté) |
| WARNING-02 — logout bloqué avec flag actif | **RÉSOLU** (FR-008 enrichi) |
| WARNING-03 — SC-001 chronométrage non contextualisé | **RÉSOLU** (FR-018 + exécutant) |
| WARNING-04 — FR-016 non vérifiable | **RÉSOLU** (critère diff git) |
| INFO-02 — edge case référence FR-008 | **RÉSOLU** (renvoie à FR-010) |
| INFO-03 — assumption trop restrictive | **RÉSOLU** (toutes versions endpoints `/admin/*`) |

### Nouveaux constats itération 2

#### BLOQUANT

Aucun.

#### WARNING

- **WARNING-ITER2-01** — Q-DIFF-05 présent dans `spec.md` mais initialement absent de la table "Points différés" du `clarify-log.md`. **Corrigé post-review** : ligne Q-DIFF-05 ajoutée au clarify-log, synthèse mise à jour.
- **WARNING-ITER2-02** — Contradiction ponctuelle entre la résolution détaillée CL-001 point 2 dans le clarify-log (« la même migration doit passer `isAdmin = true`… ») et FR-012a (interdiction de lire `ADMIN_EMAILS` dans la migration). **Corrigé post-review** : résolution CL-001 réécrite pour s'aligner sur la séparation FR-012 / FR-012a / FR-012b.

#### INFO

- **INFO-ITER2-01** — Incohérence mineure dans la synthèse clarify-log : texte listait 6 catégories mais annonçait "4/11". **Corrigé post-review** : compteur mis à "6/11".
- **INFO-ITER2-02** — SC-001 vérification auto-chronométrée par l'auteur du ticket. Acceptable dans le contexte self-hosted à groupe restreint. Observation sans action.
- **INFO-ITER2-03** — FR-018 ne précise pas inline l'exécutant. Information présente par renvoi. Observation mineure, non corrigée.

### Verdict

**PASS.** Les 3 MAJEUR sont résolus, les 4 WARNING sont adressés, les 2 INFO corrigeables sont corrigées. La spec peut avancer vers `/devflow.research`.

---

## Review Tasks — 2026-04-22 (itération 1)

**Mode** : review-tasks
**Agent** : devflow-review
**Verdict** : **PASS**

### Grille d'évaluation

| Passe | Statut |
|-------|--------|
| 1. Couverture FR → Tâches | OK (écart mineur sur mapping FR-012a) |
| 2. Couverture SC → Tâches | OK (mapping SC-002 imprécis corrigé) |
| 3. Cohérence plan ↔ tasks | OK (omissions mineures signalées) |
| 4. Cohérence contracts ↔ tasks | OK (cas 409 `EMAIL_ALREADY_EXISTS` clarifié dans T-032) |
| 5. Ordonnancement et dépendances | OK (DAG sans cycle) |
| 6. Granularité | OK (T-039 large, mais scope préservé + tests dédiés ajoutés) |
| 7. MVP First / Incremental Delivery | OK (stratégie cohérente) |
| 8. Marqueurs [P] | OK (pas de dépendance cachée) |

### Constats

#### BLOQUANT

Aucun.

#### WARNING

- **W-01** — C16 (émission claim login) absent nommément : absorbé par T-029, verdict accepté.
- **W-02** — Redirection post-login `LoginComponent` non testée. **Corrigé** : ajout T-048.
- **W-03** — Mapping SC-002 imprécis. **Corrigé** : mapping → T-023 uniquement.
- **W-04** — Cas `409 EMAIL_ALREADY_EXISTS` non explicitement dans T-032. **Corrigé** : enrichissement de l'intitulé de T-032.
- **W-05** — T-039 large (4 modifications dans `auth.ts`). **Corrigé partiellement** : ajout T-049 pour tests dédiés de persistance localStorage.
- **W-06** — Incohérence mineure Livraison 2 / US5. Verdict accepté (tâche T-060 non critique au MVP).

#### INFO

- **I-01** — Mapping FR-012a → T-010, T-011 incorrect. **Corrigé** : mapping → T-010 uniquement.
- **I-02** — Mapping SC-002 → T-021, T-023 incorrect. **Corrigé** (identique à W-03).
- **I-03** — `UserOnboardingServiceTest` absent des tâches. Accepté : couverture par tests d'intégration (T-023, T-036).
- **I-04** — `AcceptInviteServiceTest` adaptation non mentionnée. Accepté : T-037 absorbe cette adaptation.
- **I-05** — Intitulé T-032 manque unicité email. **Corrigé** (identique à W-04).
- **I-06** — Parallélisation T-010/T-011. Observation sans action, ordre Flyway déterministe par numérotation V30/V31.
- **I-07** — DAG `T-001 → T-002` fausse dépendance. Observation mineure, sans impact pratique.

### Corrections post-review appliquées

- **T-032** : intitulé enrichi avec la vérification d'unicité email et les codes d'erreur attendus.
- **T-048** (nouveau) : test `LoginComponent` redirection post-login si `mustResetCredentials`.
- **T-049** (nouveau) : tests `AuthService` Angular — persistance et restauration du flag depuis localStorage.
- Table Requirements → Tasks : mappings FR-012a et SC-002 corrigés.
- Table Requirements → Tasks : FR-014 et FR-015 enrichis des nouvelles tâches T-048 et T-049.
- Résumé tâches : total passé de 53 à 55, P1 passé de 28 à 30, parallélisables de 22 à 24.

### Justification du verdict

Aucun BLOQUANT détecté. Les 18 FR sont couverts, les 7 SC ont des tâches de test associées, les 21 composants du plan sont représentés dans les tâches, le DAG est sans cycle, les marqueurs `[P]` sont cohérents. Les corrections documentaires appliquées post-review éliminent les imprécisions de traçabilité. La stratégie MVP (US1 + US2 + US4) est justifiée. Les tâches peuvent être exécutées via `/devflow.implement`.

---

## Implement Gate — 2026-04-22

**Mode** : gate préalable à `/devflow.implement`

### Vérifications cross-artefacts

| Item | Statut |
|------|--------|
| `spec.md` présent, 0 marqueur `[NEEDS CLARIFICATION]` | PASS |
| `clarify-log.md` présent | PASS |
| `research.md` présent | PASS |
| `plan.md` présent, Constitution Check PASS | PASS |
| `contracts.md` présent | PASS |
| `data-model.md` présent | PASS |
| `quickstart.md` présent | PASS |
| `tasks.md` présent, 55 tâches, mapping FR→Tasks complet | PASS |
| Reviews passées : `review-spec` (2 itérations, PASS) + `review-tasks` (1 itération, PASS) | PASS |
| Branche `feature/KKS-233` active | PASS |
| `.gitignore` : `target/`, `.env`, `node_modules/` couverts | PASS |

### Résultat gate : **PASS**

Aucun item FAILED en cross-artefacts. Implémentation autorisée.

---

## Implement — 2026-04-22

**Mode** : exécution des 55 tâches via agents délégués (`spring-boot-dev`, `angular-dev`, `pre-commit-review`, `frontend-design-review`).

### Livraisons successives

| Livraison | Périmètre | Tâches | Résultat |
|-----------|-----------|--------|----------|
| L1 — Fondations backend | Migrations Flyway V30/V31, `User` étendue, `PasswordGenerator`, `JwtUtil` (surcharge + extractClaim), `AuthResponse` (+mustResetCredentials), `BootstrapProperties` (@ConfigurationProperties @Validated), `UserOnboardingService` (extraction depuis accept-invite), propagation `false` dans consommateurs existants | T-001 à T-018 | PASS — `mvn test` 504→504 (pas de régression, +0 nouveaux) |
| L2 — Seed MVP + refactor admin | `BootstrapSeedRunner` (@Order 1), `AdminSyncRunner` (@Order 2), refactor `AdminAuthorizationFilter` + `UserService.toResponse` vers `user.isAdmin()`, tests `PasswordGenerator`, `BootstrapProperties`, `BootstrapSeedRunner`, `AdminSyncRunner`, adaptation tests admin existants | T-020 à T-024, T-050, T-051 à T-055, T-060 | PASS — 520 tests (+16 nouveaux) |
| L3 — Reset endpoint backend | `FirstLoginResetRequest` DTO, `PasswordUnchangedException` + handler, `PasswordResetRequiredFilter`, enregistrement dans `SecurityConfig`, `AuthService.firstLoginReset`, endpoint `POST /api/auth/first-login-reset`, modifications `AuthService.login` / `RefreshTokenService` / `AcceptInviteService` pour propager le claim et le champ `mustResetCredentials`, tests `JwtUtil`, `PasswordResetRequiredFilter`, `AuthControllerFirstLoginResetIT` | T-025 à T-037 | PASS — 541 tests (+21 nouveaux). Timeout agent final sur le rapport ; validation a posteriori via `git status` + `mvn test` confirme la complétude |
| L4 — Frontend Angular | Modèles `AuthResponse` / `UserInfo` / `FirstLoginResetRequest`, `AuthService` Angular (computed `mustResetCredentials`, `saveAuth` enrichi, `restoreSession` rétro-compat, méthode `firstLoginReset`), guards `passwordResetGuard` + `notPasswordResetGuard`, composant `FirstLoginResetComponent`, route `/first-login-reset`, redirection post-login, tests composant + guards + `AuthService` persistance | T-038 à T-049 | PASS — `ng build` OK, 449 tests Angular (+16 nouveaux) |
| T-056 — Test E2E préservation admin | Scénario bout-en-bout : seed bootstrap → login → reset vers email hors `ADMIN_EMAILS` → accès `/admin/*` préservé → simulation redémarrage via `AdminSyncRunner.run()` → re-login → accès admin toujours fonctionnel | T-056 | PASS — AuthControllerFirstLoginResetIT 11/11 verts |
| Polish | `docs/deployment.md` enrichi (section "Premier démarrage sur instance vierge"), `BOOTSTRAP_EMAIL` documenté dans les variables d'env, vérification diff Flutter vide, mvn test + ng test verts | T-070, T-071, T-072 | PASS |

### Reviews finales

**T-074 — Pre-commit review** (`pre-commit-review`) : **PASS** (0 CRITIQUE, 0 WARNING). 44 fichiers analysés (27 modifiés + 17 nouveaux). Bannière `BootstrapSeedRunner` et alphabet `PasswordGenerator` reconnus comme intentionnels (FR-004). Aucun secret hardcodé, aucun code mort, aucun TODO/FIXME, aucun `console.log` / `System.out.println`.

**T-075 — Frontend design review** (`frontend-design-review`) : **PASS avec réserves MAJEUR**.
- Constats :
  - **CRITIQUE mineur** — `!important` sur `.input-error` avec token `--color-expense` au lieu de `--text-error` → **corrigé** post-review dans `first-login-reset.component.scss`.
  - **MAJEUR** — duplication structurelle `.flr-page` / `.flr-card` / `.flr-header` / `.btn-primary` / `.btn-block` avec `auth.scss` et `accept-invite.scss` → accepté comme dette pré-existante dans le projet (même pattern dans `accept-invite.scss`). Non corrigé dans ce ticket, candidat à un ticket de mutualisation SCSS auth ultérieur.
  - **MAJEUR** — `max-width: 480px` vs 400px dans les autres pages auth → accepté (4 champs vs 2-3, légère justification).
  - **INFO** — absence `aria-live` sur `.flr-error`, ordre email→displayName→password→passwordConfirm → acceptés.
- Aucune valeur hex/rgba hardcodée. Tous les tokens via `var(--...)`. Signals-first + standalone + OnPush respectés.

### Dette consignée pour tickets futurs

- Mutualisation SCSS des layouts auth (`auth.scss` / `accept-invite.scss` / `first-login-reset.component.scss`) — duplication structurelle identifiée.
- Extraction d'un fichier `_buttons.scss` partagé.
- Attribut `aria-live="polite"` sur les blocs d'erreur des formulaires auth.

### Non exécuté dans cette session

- **T-073** (test manuel quickstart.md chronométré sur DB vierge, SC-001 < 5 min) : requiert exécution manuelle par l'auteur du ticket. À faire lors de la phase `/devflow.checklist` par Kelly. Une seule tâche non cochée sur les 55.

### Bilan

- **54/55 tâches cochées** (T-073 renvoyée à la checklist manuelle).
- **541 tests backend** verts, **449 tests Angular** verts.
- **0 modification** sous `flutter/` (conformité FR-016 vérifiée via `git diff develop...HEAD --name-only | grep ^flutter/` → vide).
- **Aucune nouvelle dépendance** Maven ou npm.
- **Constitution Check** : conforme aux 7 principes (déjà validé en phase plan, non remis en cause par l'implémentation).

---

## Review Impl — 2026-04-22 (itération 1)

**Mode** : review-impl
**Agent** : devflow-review
**Verdict** : **PASS**

### Grille d'évaluation

| Axe | Statut |
|-----|--------|
| Conformité constitution (7 principes) | PASS |
| Conformité spec (FR-001 à FR-018) | PASS avec 1 WARNING (W-01) |
| Conformité plan (21 composants) | PASS |
| Conformité contrats | PASS post-corrections |
| Sécurité (SecureRandom, BCrypt, JWT claim, allowlist, anti-rétrogradation) | PASS |
| Complétude tâches (54/55 cochées) | PASS |
| Qualité (code mort, secrets, console.log) | PASS |
| FR-016 (zéro modif Flutter) | PASS |

### Constats

#### BLOQUANT
Aucun.

#### WARNING

- **W-01** — Écart payload 403 `PASSWORD_RESET_NOT_REQUIRED` entre contrat et implémentation. **Corrigé post-review** : création de `PasswordResetNotRequiredException` + handler dédié dans `GlobalExceptionHandler` retournant `ErrorResponse { error: "PASSWORD_RESET_NOT_REQUIRED", message: ... }`. Remplacement de `AccessDeniedException` dans `AuthService.firstLoginReset`. Test TC-6 (`AuthControllerFirstLoginResetIT`) renforcé pour vérifier le payload structuré. Test unitaire `AuthServiceTest.should_throw_PasswordResetNotRequiredException_when_flag_already_false` mis à jour.
- **W-02** — Bootstrap ne se déclenche pas en profil `dev` à cause de `R__dev_seed.sql`. Comportement conforme à FR-005/SC-003 mais piège pour le test manuel. **Corrigé post-review** : `quickstart.md` enrichi d'une note "Important — profil Spring" expliquant la nécessité d'utiliser le profil `prod` + procédure mise à jour (`mvn spring-boot:run` sans `-Dspring-boot.run.profiles=dev`).

#### INFO

- **I-01** — `PasswordResetRequiredFilter.isAllowedPath` utilisait `endsWith` au lieu d'un exact-match. **Corrigé post-review** : remplacement par `ALLOWED_PATHS.contains(path)` + commentaire mis à jour.
- **I-02** — `UserInfo` localStorage Angular n'inclut pas `isAdmin`. Comportement pré-existant hérité de KKS-232, pas une régression KKS-233. Observation consignée pour ticket futur.
- **I-03** — Import `spring.boot.webmvc.test` dans `AuthControllerFirstLoginResetIT` — cohérent avec Spring Boot 4, pas d'action requise.
- **I-04** — `BootstrapSeedRunner.run` sans `@Transactional` explicite (transactionnalité portée par `UserOnboardingService`). Asymétrie mineure avec `AdminSyncRunner`. Pas d'impact fonctionnel, observation consignée.
- **I-05** — T-073 non exécuté automatiquement (test manuel obligatoire avant merge).

### Corrections appliquées post-review (avant acter le PASS)

| Correction | Fichiers |
|------------|----------|
| W-01 — Exception dédiée `PasswordResetNotRequiredException` + handler structuré | `exception/PasswordResetNotRequiredException.java` (nouveau), `config/GlobalExceptionHandler.java`, `service/AuthService.java`, `controller/AuthControllerFirstLoginResetIT.java`, `service/AuthServiceTest.java` |
| I-01 — `isAllowedPath` en exact-match | `config/PasswordResetRequiredFilter.java` |
| W-02 — Note sur profil `prod` dans la procédure de test | `docs/features/KKS-233/quickstart.md` |

### Vérification post-corrections

`mvn test` : **541 tests verts, 0 échec**.

### Verdict

**PASS.** L'implémentation est conforme à la spec, au plan et aux contrats. Toutes les corrections post-review sont appliquées. La feature est prête à passer en phase `/devflow.docs` et merge après validation manuelle de T-073.
