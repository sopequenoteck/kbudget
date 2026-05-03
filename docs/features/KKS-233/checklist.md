# Checklist qualité — KKS-233 : Bootstrap du premier admin sur DB vide

> Date : 2026-04-22
> Issue : KKS-233
> Étape courante : `review-impl`
> Évaluation : automatique, basée sur les artefacts présents

---

## Section 1 — Spec & Clarify

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-001 | `spec.md` présent et complet (contexte, US, FR, SC, Key Entities, Assumptions) | PASS | `spec.md` — toutes sections renseignées |
| CHK-002 | Au moins 1 User Story P1 définie | PASS | US-001 (P1), US-002 (P1) |
| CHK-003 | Chaque US a un "Why this priority" + "Independent Test" | PASS | 5 US conformes |
| CHK-004 | Acceptance Scenarios au format Given/When/Then | PASS | 5 US couvertes |
| CHK-005 | Functional Requirements numérotés (FR-001, FR-002, …) | PASS | FR-001 à FR-018 (incluant FR-012a/b) |
| CHK-006 | Aucun marqueur `[NEEDS CLARIFICATION]` résiduel dans `spec.md` | PASS | 0 occurrence détectée |
| CHK-007 | Success Criteria avec méthode de vérification explicite | PASS | SC-001 à SC-007 avec "Vérification" |
| CHK-008 | Edge Cases documentés | PASS | Section "Edge Cases" présente |
| CHK-009 | `clarify-log.md` présent avec top 5 points résolus | PASS | CL-001 à CL-005 + 5 Q-DIFF |
| CHK-010 | Taxonomie des catégories utilisée (11 catégories) | PASS | Catégories 1/2/3/5/7/10/11 couvertes |
| CHK-011 | Points différés au plan documentés avec justification | PASS | Q-DIFF-01 à Q-DIFF-05 documentés |

**Sous-total** : 11 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 2 — Constitution & Research

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-020 | Constitution v2.1.2 lue et référencée en phase plan | PASS | `plan.md` section Constitution Check |
| CHK-021 | Principe I (API-First) vérifié | PASS | Endpoint `POST /api/auth/first-login-reset`, DTOs records, pas d'entité JPA exposée |
| CHK-022 | Principe II (Sécurité par défaut) vérifié | PASS | BCrypt, Bean Validation, JWT claim, filter dédié, password aléatoire `SecureRandom` |
| CHK-023 | Principe III (YAGNI) respecté | PASS | Pas de wizard, pas de CLI, pas d'endpoint bootstrap, pattern Jenkins/GitLab |
| CHK-024 | Principe IV (Mobile-First UX) respecté ou justifié N/A | PASS | N/A motivé — bootstrap est instance-level, pas mobile daily use |
| CHK-025 | Principe V (Testabilité) respecté | PASS | 541 tests backend + 449 tests Angular, nommage `should_[résultat]_when_[condition]` |
| CHK-026 | Principe VI (Observabilité) respecté | PASS | Log WARN bannière, INFO promotion admin, INFO reset, SLF4J uniquement |
| CHK-027 | Principe VII (Self-Hosted Ready) respecté | PASS | 0 nouvelle dépendance, `BOOTSTRAP_EMAIL` optionnel, `docker compose up -d` suffit |
| CHK-028 | `research.md` présent avec décisions RES-XXX | PASS | RES-001 à RES-012 documentés |
| CHK-029 | Chaque décision a rationale + alternatives rejetées | PASS | Tableau options + score dans chaque RES |
| CHK-030 | Patterns nouveaux justifiés dans Complexity Tracking | PASS | CX-001 à CX-005 dans `plan.md` |

**Sous-total** : 11 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 3 — Plan & Contracts

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-040 | `plan.md` présent avec Constitution Check | PASS | Section en tête du plan |
| CHK-041 | Aucune dérogation non justifiée | PASS | Tableau Dérogations vide |
| CHK-042 | Architecture décomposée en composants nommés (C1, C2, …) | PASS | C1 à C21 |
| CHK-043 | Chaque composant référence les FR couverts | PASS | Table "Couverture FR / SC" en fin de plan |
| CHK-044 | Risques identifiés avec mitigations | PASS | R-01 à R-07 |
| CHK-045 | Éléments hors scope explicitement documentés | PASS | Section "Hors scope" |
| CHK-046 | `data-model.md` présent avec entités et migrations | PASS | `User` + migrations V30/V31 détaillées |
| CHK-047 | `quickstart.md` présent avec procédure test local | PASS | 8 scénarios documentés |
| CHK-048 | `contracts.md` présent avec interfaces & endpoints | PASS | 9 sections, synthèse finale |
| CHK-049 | Chaque endpoint décrit avec codes d'erreur | PASS | §2.1 `first-login-reset` : 200/400/401/403/409 |
| CHK-050 | DTOs avec Bean Validation annotée | PASS | §1.2 `FirstLoginResetRequest` — `@NotBlank @Email @Size` |
| CHK-051 | Contrats services avec signatures typées | PASS | §3.1, §3.2 — signatures Java complètes |
| CHK-052 | Contrats frontend (interfaces TS, guards, composant) | PASS | §1.7-9, §8.1-7 |

**Sous-total** : 13 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 4 — Tasks

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-060 | `tasks.md` présent avec 5 phases | PASS | Phase 1 Setup → Phase 4 Polish + Phase 5 Dependencies |
| CHK-061 | Chaque FR couvert par au moins une tâche | PASS | Table "Requirements → Tasks" — FR-001 à FR-018 tous mappés |
| CHK-062 | Chaque SC couvert par au moins une tâche de test | PASS | SC-001 à SC-007 tous mappés |
| CHK-063 | Tâches parallélisables marquées `[P]` | PASS | 24 tâches `[P]` identifiées |
| CHK-064 | DAG de dépendances sans cycle | PASS | Section Phase 5 validée par review-tasks |
| CHK-065 | Stratégie MVP First + Incremental Delivery documentée | PASS | 5 livraisons décrites |
| CHK-066 | `review-tasks` passé avec PASS | PASS | 1 itération, verdict PASS (cf. review-log) |
| CHK-067 | Corrections post-review-tasks appliquées | PASS | T-032 enrichi, T-048/T-049 ajoutés, mappings FR-012a/SC-002 corrigés |

**Sous-total** : 8 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 5 — Implémentation Backend

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-080 | Migrations Flyway V30 et V31 créées | PASS | `api/src/main/resources/db/migration/V30__add_user_is_admin.sql` + `V31__add_user_password_reset_required.sql` |
| CHK-081 | Entité `User` étendue avec `isAdmin` et `passwordResetRequired` | PASS | `User.java` (+2 champs) |
| CHK-082 | `PasswordGenerator` util avec `SecureRandom` + alphabet `[A-Za-z0-9]` | PASS | `util/PasswordGenerator.java` |
| CHK-083 | `JwtUtil` étendu : `generateToken(email, extraClaims)` + `extractClaim` | PASS | `config/JwtUtil.java` |
| CHK-084 | `AuthResponse` enrichi de `mustResetCredentials` | PASS | `dto/response/AuthResponse.java` |
| CHK-085 | `BootstrapProperties` avec `@ConfigurationProperties + @Validated + @Email` | PASS | `config/BootstrapProperties.java` |
| CHK-086 | `UserOnboardingService` extrait (mutualisation accept-invite / bootstrap) | PASS | `service/UserOnboardingService.java` |
| CHK-087 | `BootstrapSeedRunner` (@Order 1) avec condition `count() == 0` | PASS | `runner/BootstrapSeedRunner.java` |
| CHK-088 | `AdminSyncRunner` (@Order 2) — promotion sans rétrogradation | PASS | `runner/AdminSyncRunner.java` |
| CHK-089 | Refactor `AdminAuthorizationFilter` → `user.isAdmin()` | PASS | `config/AdminAuthorizationFilter.java` |
| CHK-090 | Refactor `UserService.toResponse` → `user.isAdmin()` | PASS | `service/UserService.java` |
| CHK-091 | `FirstLoginResetRequest` DTO avec Bean Validation | PASS | `dto/request/FirstLoginResetRequest.java` |
| CHK-092 | `PasswordUnchangedException` + handler `400 PASSWORD_UNCHANGED` | PASS | `exception/PasswordUnchangedException.java` + handler |
| CHK-093 | `PasswordResetRequiredFilter` avec allowlist + claim check | PASS | `config/PasswordResetRequiredFilter.java` |
| CHK-094 | Filtre enregistré dans `SecurityConfig` après `JwtFilter` | PASS | `config/SecurityConfig.java` |
| CHK-095 | Endpoint `POST /api/auth/first-login-reset` exposé | PASS | `controller/AuthController.java` |
| CHK-096 | `AuthService.firstLoginReset` avec vérif unicité email + password inchangé | PASS | `service/AuthService.java` |
| CHK-097 | `AuthService.login` propage claim + champ `mustResetCredentials` | PASS | Emission conditionnelle du claim |
| CHK-098 | `RefreshTokenService.refreshAccessToken` propage claim + champ | PASS | Idem login |
| CHK-099 | `AcceptInviteService.acceptInvite` délègue à `UserOnboardingService` | PASS | Refactor appliqué, dépendances inutiles retirées |

**Sous-total** : 20 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 6 — Implémentation Frontend Angular

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-110 | `AuthResponse` TS enrichi de `mustResetCredentials` | PASS | `core/models/auth.model.ts` |
| CHK-111 | `UserInfo` TS enrichi de `mustResetCredentials` | PASS | `core/models/user.model.ts` |
| CHK-112 | Interface `FirstLoginResetRequest` TS créée | PASS | `core/models/auth.model.ts` |
| CHK-113 | `AuthService` expose computed signal `mustResetCredentials` | PASS | `core/services/auth.ts` |
| CHK-114 | `AuthService.saveAuth` persiste `mustResetCredentials` en localStorage | PASS | `core/services/auth.ts` |
| CHK-115 | `AuthService.restoreSession` relit `mustResetCredentials` (rétro-compat) | PASS | `core/services/auth.ts` |
| CHK-116 | `AuthService.firstLoginReset` méthode nouvelle | PASS | `core/services/auth.ts` |
| CHK-117 | `passwordResetGuard` créé | PASS | `core/guards/password-reset.guard.ts` |
| CHK-118 | `notPasswordResetGuard` créé | PASS | `core/guards/not-password-reset.guard.ts` |
| CHK-119 | `FirstLoginResetComponent` standalone + OnPush | PASS | `features/auth/first-login-reset/` |
| CHK-120 | Formulaire : 4 champs + validateur égalité password | PASS | Component spec 7 tests, validation `passwordMatch` |
| CHK-121 | Route `/first-login-reset` avec guards composés | PASS | `app.routes.ts` |
| CHK-122 | `passwordResetGuard` appliqué sur routes protégées | PASS | `app.routes.ts` |
| CHK-123 | Login redirige vers `/first-login-reset` si flag true | PASS | `features/auth/auth.ts` |
| CHK-124 | Design tokens respectés (pas de hex/rgba hardcodé) | PASS | `first-login-reset.component.scss` audité par `frontend-design-review` |
| CHK-125 | Signals-first (pas de `@Input()`, `@Output()` classiques) | PASS | Composant utilise `signal()`, computed |

**Sous-total** : 16 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 7 — Tests

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-140 | Tests unitaires `PasswordGenerator` (SC-007) | PASS | `PasswordGeneratorTest` — 3 tests |
| CHK-141 | Tests `BootstrapProperties` fail-fast (FR-017) | PASS | `BootstrapPropertiesTest` — 2 tests |
| CHK-142 | Tests `BootstrapSeedRunner` : seed + DB peuplée + custom email | PASS | `BootstrapSeedRunnerTest` — 7 tests |
| CHK-143 | Tests `AdminSyncRunner` : promotion + non-rétrogradation + idempotence | PASS | `AdminSyncRunnerTest` — 4 tests |
| CHK-144 | Tests `AdminAuthorizationFilter` refactor | PASS | `AdminAuthorizationFilterTest` — 7 tests (refactor) |
| CHK-145 | Tests `JwtUtil` : claims custom + extraction | PASS | `JwtUtilTest` enrichi |
| CHK-146 | Tests `PasswordResetRequiredFilter` (SC-004) | PASS | `PasswordResetRequiredFilterTest` |
| CHK-147 | Tests intégration `AuthControllerFirstLoginResetIT` | PASS | 11 tests (nominal + 400/403/409 + E2E admin preservation) |
| CHK-148 | Tests Angular guards (passwordReset + notPasswordReset) | PASS | 2 fichiers `.spec.ts` |
| CHK-149 | Tests Angular `FirstLoginResetComponent` | PASS | 7 tests dans `first-login-reset.component.spec.ts` |
| CHK-150 | Tests Angular `AuthService` persistance mustResetCredentials | PASS | 3 nouveaux tests dans `auth.spec.ts` |
| CHK-151 | Tests Angular redirection post-login | PASS | `features/auth/auth.spec.ts` |
| CHK-152 | `mvn test` backend vert | PASS | 541 tests, 0 échec |
| CHK-153 | `ng test` frontend vert | PASS | 449 tests, 0 échec |

**Sous-total** : 14 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 8 — Sécurité (FR-008, FR-012, FR-017, FR-011)

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-170 | Password initial généré via `SecureRandom`, 32 chars alphanumériques | PASS | `PasswordGenerator` + test SC-007 |
| CHK-171 | Password hashé via BCrypt avant persistance | PASS | `UserOnboardingService.provisionUser` + `AuthService.firstLoginReset` |
| CHK-172 | Pas de default credentials publics dans le repo | PASS | Password généré à l'exécution, jamais en DB par défaut |
| CHK-173 | JWT claim `mustResetCredentials` émis seulement si flag actif | PASS | `AuthService.login` conditionnel |
| CHK-174 | Filtre HTTP bloque tous endpoints sauf allowlist si claim actif | PASS | `PasswordResetRequiredFilter` + tests SC-004 |
| CHK-175 | Endpoint reset vérifie flag DB (double-check anti JWT orphelin) | PASS | `AuthService.firstLoginReset` — `AccessDeniedException` si flag false |
| CHK-176 | Refus password identique via `BCryptPasswordEncoder.matches` | PASS | `AuthService.firstLoginReset` + `PasswordUnchangedException` |
| CHK-177 | Refus email déjà utilisé via `userRepository.existsByEmail` | PASS | `AuthService.firstLoginReset` + `ConflictException` |
| CHK-178 | Statut admin autoritaire en DB (pas de dérivation via env var au runtime) | PASS | `User.isAdmin` + refactor `AdminAuthorizationFilter` |
| CHK-179 | `ADMIN_EMAILS` ne rétrograde jamais un admin existant | PASS | `AdminSyncRunner` filtre `!user.isAdmin()` + test dédié |
| CHK-180 | `BOOTSTRAP_EMAIL` invalide → fail-fast démarrage | PASS | `@ConfigurationProperties @Validated @Email` + test `BootstrapPropertiesTest` |
| CHK-181 | Bean Validation sur tous les DTOs Request | PASS | `FirstLoginResetRequest`, `AcceptInviteRequest`, `LoginRequest` |

**Sous-total** : 12 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 9 — Self-Hosted Ready (principe VII critique)

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-200 | Aucune nouvelle dépendance Maven | PASS | Research confirme 0 dépendance ajoutée |
| CHK-201 | Aucune nouvelle dépendance npm | PASS | Frontend ne charge que lib déjà présentes |
| CHK-202 | `BOOTSTRAP_EMAIL` optionnelle (défaut `admin@localhost`) | PASS | `application.yaml` + `BootstrapProperties` |
| CHK-203 | `docker compose up -d` suffit pour démarrer instance vierge | PASS | `BootstrapSeedRunner` exécuté auto post-Flyway |
| CHK-204 | Procédure bootstrap documentée dans `docs/deployment.md` | PASS | Section "Premier démarrage sur instance vierge" ajoutée |
| CHK-205 | Récupération password via `docker compose logs` documentée | PASS | Commande `grep -A 5 "FIRST BOOT"` présente |
| CHK-206 | Recommandation purge logs pour logs persistés externes | PASS | Étape 5 de la procédure |
| CHK-207 | Aucun service externe requis (SMTP, cloud) | PASS | Pas de notification mail, pas de SaaS |
| CHK-208 | PostgreSQL reste la seule dépendance infra | PASS | Aucune autre DB / cache / MQ |

**Sous-total** : 9 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 10 — Qualité & Review

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-220 | `review-spec` passé (au moins une itération PASS) | PASS | 2 itérations, toutes deux PASS |
| CHK-221 | `review-tasks` passé | PASS | 1 itération PASS |
| CHK-222 | Pre-commit review passé (T-074) | PASS | 0 CRITIQUE, 0 WARNING |
| CHK-223 | Frontend design review passé (T-075) | PASS | PASS avec dette SCSS consignée |
| CHK-224 | Diff Flutter vide (FR-016) | PASS | `git diff develop...HEAD --name-only | grep ^flutter/` → vide |
| CHK-225 | Aucun `console.log` / `System.out.println` introduit | PASS | Vérifié par pre-commit-review |
| CHK-226 | Aucun secret hardcodé (apiKey, JWT secret, password fixe) | PASS | Vérifié par pre-commit-review |
| CHK-227 | Aucun code mort détecté | PASS | Vérifié par pre-commit-review |
| CHK-228 | Aucun code commenté > 3 lignes | PASS | Vérifié par pre-commit-review |
| CHK-229 | Aucun TODO / FIXME introduit | PASS | Vérifié par pre-commit-review |

**Sous-total** : 10 PASS / 0 FAIL / 0 N/A — **100 %**

---

## Section 11 — Tâches résiduelles

| ID | Critère | Statut | Evidence |
|----|---------|--------|----------|
| CHK-240 | 54/55 tâches cochées dans `tasks.md` | PASS | `grep -c "^- \[x\]"` → 54 |
| CHK-241 | T-073 (test manuel quickstart SC-001 < 5 min) complété | **FAIL** | Non automatisable, à exécuter manuellement. Mettre à jour ici après exécution |
| CHK-242 | `quickstart.md` applicable sur DB vierge | PASS | Procédure documentée, scénarios testés via tests d'intégration (hors chronométrage) |

**Sous-total** : 2 PASS / 1 FAIL / 0 N/A — **67 %**

**Note** : CHK-241 nécessite une exécution manuelle par l'auteur du ticket. Le test manuel doit confirmer que l'ensemble de la procédure (docker compose up → grep logs → login UI → reset → accès dashboard) tient en moins de 5 minutes. À faire avant merge.

---

## Résumé global

| Section | Total | PASS | FAIL | N/A | Taux |
|---------|------:|-----:|-----:|----:|-----:|
| 1 — Spec & Clarify | 11 | 11 | 0 | 0 | 100 % |
| 2 — Constitution & Research | 11 | 11 | 0 | 0 | 100 % |
| 3 — Plan & Contracts | 13 | 13 | 0 | 0 | 100 % |
| 4 — Tasks | 8 | 8 | 0 | 0 | 100 % |
| 5 — Implémentation Backend | 20 | 20 | 0 | 0 | 100 % |
| 6 — Implémentation Frontend | 16 | 16 | 0 | 0 | 100 % |
| 7 — Tests | 14 | 14 | 0 | 0 | 100 % |
| 8 — Sécurité | 12 | 12 | 0 | 0 | 100 % |
| 9 — Self-Hosted Ready | 9 | 9 | 0 | 0 | 100 % |
| 10 — Qualité & Review | 10 | 10 | 0 | 0 | 100 % |
| 11 — Tâches résiduelles | 3 | 2 | 1 | 0 | 67 % |
| **TOTAL** | **127** | **126** | **1** | **0** | **99,2 %** |

### Verdict

**Conformité : 99,2 %**. Une seule action requise avant merge : exécuter T-073 (test manuel chronométré du quickstart.md) pour valider SC-001. Tous les autres critères sont verts : spec, plan, contrats, tasks, implémentation backend, implémentation frontend, tests, sécurité, self-hosted ready, qualité, reviews.
