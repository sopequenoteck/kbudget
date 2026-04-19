# Tasks — KKS-232 : Onboarding contrôlé : flux d'invitation admin

> Date : 2026-04-19
> Issue : KKS-232
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)
> Contracts : [contracts.md](./contracts.md)
> Data Model : [data-model.md](./data-model.md)

---

## Phase 1 : Setup

- [x] [T-001] [P1] Vérifier branche `feature/KKS-232` active, backend dev démarrable, DB accessible (`mvn clean compile` OK) — Réf: setup
- [x] [T-002] [P1] [P] Ajouter property `app.admin-emails: ${ADMIN_EMAILS:}` dans `api/src/main/resources/application.yaml` — Réf: FR-012
- [x] [T-003] [P1] [P] Documenter `ADMIN_EMAILS` dans `docs/deployment.md` (section "Configuration admin") — Réf: NFR-008

**Checkpoint** : Backend démarre sans régression. `application.yaml` contient la property. `docs/deployment.md` mentionne `ADMIN_EMAILS`.

## Phase 2 : Fondations (bloquantes)

- [x] [T-010] [P1] Créer `api/src/main/resources/db/migration/V28__add_invitations.sql` (table + index + FK) — Réf: FR-001, DC-001, DC-002
- [x] [T-011] [P1] [P] Créer `api/src/main/resources/db/migration/V29__add_user_disabled_at.sql` (colonne `disabled_at`) — Réf: FR-002
- [x] [T-012] [P1] Créer enum `fr.kksdev.budget.api.enums.InvitationStatus` (ACTIVE/EXPIRED/USED/REVOKED) — Réf: FR-004
- [x] [T-013] [P1] Créer entité `fr.kksdev.budget.api.model.Invitation` (Lombok JPA, ManyToOne User) — Réf: FR-001
- [x] [T-014] [P1] Ajouter champ `disabledAt` sur `fr.kksdev.budget.api.model.User` — Réf: FR-002
- [x] [T-015] [P1] Créer `fr.kksdev.budget.api.repository.InvitationRepository` (JpaRepository + `findByToken(UUID)` + `findAllByOrderByCreatedAtDesc()`) — Réf: FR-001, FR-004
- [x] [T-016] [P1] [P] Créer `fr.kksdev.budget.api.config.AdminEmailResolver` (@Component, `@Value("${app.admin-emails:}") List<String>`, `@PostConstruct` normalisation, API `isAdminEmail`/`listAdminEmails`, WARN au boot si vide ou no-match) — Réf: FR-012, NFR-008
- [x] [T-017] [P1] [P] Test unitaire `AdminEmailResolverTest` (trim, lowercase, WARN, no match) — Réf: FR-012, NFR-006
- [x] [T-018] [P1] Modifier `fr.kksdev.budget.api.config.JwtFilter` : ajouter `.filter(u -> u.getDisabledAt() == null)` avant `.ifPresent(...)` — Réf: FR-016, SC-007
- [x] [T-019] [P1] [P] Mettre à jour `JwtFilterTest` avec cas `should_not_authenticate_when_user_disabled` — Réf: FR-016, NFR-006

**Checkpoint** : `mvn test` OK. DB migrations appliquées en dev (`\d invitation` + `\d users` affichent les nouveaux champs). `AdminEmailResolver` loggue WARN si `ADMIN_EMAILS` vide au boot.

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

#### [US-001] Admin crée une invitation

- [x] [T-020] [P1] [US-001] Créer DTO record `CreateInvitationRequest(@Email @NotBlank String email)` — Réf: FR-003
- [x] [T-021] [P1] [US-001] [P] Créer DTO record `InvitationCreatedResponse(UUID token, Instant expiresAt)` — Réf: FR-003
- [x] [T-022] [P1] [US-001] Créer `fr.kksdev.budget.api.service.InvitationService` avec méthode `create(User invitedBy, String email)` — Réf: FR-003, FR-013
- [x] [T-023] [P1] [US-001] Créer `fr.kksdev.budget.api.controller.AdminInvitationController` avec `POST /admin/invitations` (201, log INFO `"Admin action: invitation.create ..."`) — Réf: FR-003, NFR-002
- [x] [T-024] [P1] [US-001] [P] Test unitaire `InvitationServiceTest.should_persist_invitation_with_7d_expiry_when_created` — Réf: FR-013, NFR-006

#### [US-002, US-013] Invité accepte une invitation

- [x] [T-025] [P1] [US-002] Créer DTO record `AcceptInviteRequest(UUID token, String password, String displayName, Currency currency, String timezone)` avec Bean Validation — Réf: FR-010, NFR-004
- [x] [T-026] [P1] [US-002] [P] Créer DTO record `InviteLookupResponse(String email)` — Réf: FR-009
- [x] [T-027] [P1] [US-002] Ajouter `InvitationService.validatePublic(UUID token) -> Optional<Invitation>` (retourne uniquement si ACTIVE) — Réf: FR-009, FR-014
- [x] [T-028] [P1] [US-002] Ajouter `InvitationService.markUsed(Invitation)` + `InvitationService.deriveStatus(Invitation)` — Réf: FR-014
- [x] [T-029] [P1] [US-002] Créer `fr.kksdev.budget.api.service.AcceptInviteService.acceptInvite(AcceptInviteRequest)` (`@Transactional`, migrer logique de `AuthService.register`, mark used, JWT + refresh, log INFO) — Réf: FR-010, FR-014, FR-015
- [x] [T-030] [P1] [US-002] Ajouter endpoints `GET /auth/invitations/{token}` et `POST /auth/accept-invite` dans `AuthController` — Réf: FR-009, FR-010
- [x] [T-031] [P1] [US-002] **SUPPRIMER** `POST /auth/register` du `AuthController` + méthode `AuthService.register` + DTO `RegisterRequest` — Réf: FR-011, SC-001
- [x] [T-032] [P1] [US-002] [P] Supprimer / migrer les tests obsolètes `AuthControllerIT.register_*` → adapter en `AuthControllerIT.acceptInvite_*` (nominal, token expiré, utilisé, révoqué, inconnu, email non modifiable dans body, **double-use après revoke / revoke après use** — couvre DC-003) — Réf: FR-014, FR-015, SC-003, SC-004, SC-005, DC-003, NFR-006
- [x] [T-033] [P1] [US-002] [P] Test unitaire `AcceptInviteServiceTest` (eager creation, markUsed, isolation données, **cas email déjà utilisé par un user existant → rejet**) — Réf: FR-010, NFR-003, SC-012

#### [US-003] Admin révoque une invitation

- [x] [T-034] [P1] [US-003] Ajouter `InvitationService.revoke(Long id)` (log INFO format `"Admin action: invitation.revoke by <adminEmail> target=invitation:<id>"`) — Réf: FR-005, NFR-002
- [x] [T-035] [P1] [US-003] Ajouter endpoint `DELETE /admin/invitations/{id}` dans `AdminInvitationController` — Réf: FR-005
- [x] [T-036] [P1] [US-003] [P] Test d'intégration : revoke puis GET /auth/invitations/{token} → 404 ; tenter revoke sur une invitation `USED` → comportement défini (no-op idempotent ou rejet selon impl — couvre DC-003) — Réf: SC-005, DC-003

#### [US-008] Admin liste les invitations

- [x] [T-037] [P1] [US-008] Créer DTO record `InvitationResponse(id, email, invitedByEmail, status, createdAt, expiresAt, usedAt, revokedAt)` — Réf: FR-004
- [x] [T-038] [P1] [US-008] Ajouter `InvitationService.list() -> List<InvitationResponse>` (tri createdAt DESC, statut dérivé, projection `invitedByEmail`) — Réf: FR-004, CL-002
- [x] [T-039] [P1] [US-008] Ajouter endpoint `GET /admin/invitations` dans `AdminInvitationController` — Réf: FR-004
- [x] [T-040] [P1] [US-008] [P] Test d'intégration : 4 fixtures (ACTIVE/EXPIRED/USED/REVOKED) → tous listés avec bon status — Réf: FR-004, NFR-006

#### [US-004, US-005, US-007] Disable/Enable users + garde-fou

- [ ] [T-041] [P1] [US-004] Créer DTO record `AdminUserResponse(id, email, displayName, createdAt, disabledAt, isAdmin)` — Réf: FR-006
- [ ] [T-042] [P1] [US-004] Créer `fr.kksdev.budget.api.service.AdminUserService` avec `list()`, `disable(UUID)`, `enable(UUID)` (logs INFO format `"Admin action: user.<disable|enable> by <adminEmail> target=user:<id>"`) — Réf: FR-006, FR-007, FR-008, NFR-002
- [ ] [T-043] [P1] [US-007] Implémenter garde-fou dans `AdminUserService.disable` : `ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED")` si dernier admin actif — Réf: FR-017
- [ ] [T-044] [P1] [US-004] Créer `fr.kksdev.budget.api.controller.AdminUserController` avec `GET /admin/users`, `PATCH /admin/users/{id}/disable`, `PATCH /admin/users/{id}/enable` (logs INFO) — Réf: FR-006, FR-007, FR-008, NFR-002
- [ ] [T-045] [P1] [US-004] [P] Test d'intégration : disable user + requête avec son JWT → 401 — Réf: SC-007
- [ ] [T-046] [P1] [US-005] [P] Test d'intégration `should_allow_reauthentication_after_enable` (disable → enable → login OK / requête 200) — Réf: SC-013
- [ ] [T-047] [P1] [US-007] [P] Test d'intégration : fixture mono-admin tente self-disable → 409 `{error: "LAST_ADMIN_CANNOT_BE_DISABLED"}` — Réf: SC-008

#### [US-006] Protection endpoints /admin/*

- [ ] [T-048] [P1] [US-006] Créer `fr.kksdev.budget.api.config.AdminAuthorizationFilter` (OncePerRequestFilter, matche `/admin/**`, résout email via UserRepository, 403 si non-admin) — Réf: FR-019
- [ ] [T-049] [P1] [US-006] Enregistrer `AdminAuthorizationFilter` dans `SecurityConfig` via `.addFilterAfter(adminAuthorizationFilter, JwtFilter.class)` — Réf: FR-019
- [ ] [T-050] [P1] [US-006] [P] Test d'intégration `AdminAuthorizationFilterIT` — matrice { anonyme, user non-admin, admin } × { POST /admin/invitations, GET /admin/invitations, DELETE, GET /admin/users, PATCH disable, PATCH enable } → 401 / 403 / 200 — Réf: FR-019, SC-002

#### [US-010] `isAdmin` dans `/users/me`

- [ ] [T-051] [P1] [US-010] Modifier record `UserResponse(name, email, isAdmin)` — Réf: FR-018
- [ ] [T-052] [P1] [US-010] Injecter `AdminEmailResolver` dans `UserService` et peupler `isAdmin` dans `getProfile` — Réf: FR-018
- [ ] [T-053] [P1] [US-010] [P] Test d'intégration `UserControllerIT.should_return_isAdmin_true_when_email_in_admin_list` + cas false — Réf: FR-018, SC-011

### P2 — Importantes

#### [US-011] UI Angular Settings > Utilisateurs

- [ ] [T-060] [P2] [US-011] [P] Créer modèles TypeScript `shared/models/invitation.model.ts` (Invitation, InvitationStatus, InvitationCreated, CreateInvitationRequest, AcceptInviteRequest, InviteLookup) — Réf: FR-020, FR-022
- [ ] [T-061] [P2] [US-011] [P] Modifier `shared/models/user.model.ts` : ajouter `isAdmin: boolean` à `CurrentUser`, créer `AdminUser` — Réf: FR-020, FR-024
- [ ] [T-062] [P2] [US-011] [P] Créer service `core/services/admin.service.ts` (méthodes HttpClient typed) — Réf: FR-003, FR-004, FR-005, FR-006, FR-007, FR-008
- [ ] [T-063] [P2] [US-011] [P] Créer service `core/services/invitation.service.ts` (lookup, accept) — Réf: FR-009, FR-010
- [ ] [T-064] [P2] [US-011] Modifier `core/stores/current-user.store.ts` : ajouter signal/computed `isAdmin`, `loadMe()` met à jour — Réf: FR-018, FR-024
- [ ] [T-065] [P2] [US-011] Créer page standalone `features/settings/pages/users/users.ts|html|scss` (tabs Invitations + Users, actions) — Réf: FR-020, US-011
- [ ] [T-066] [P2] [US-011] Ajouter route `users` dans `features/settings/settings.routes.ts` — Réf: FR-020
- [ ] [T-067] [P2] [US-011] [P] Ajouter tuile `Utilisateurs` dans menu Settings, conditionnelle à `@if (currentUser.isAdmin())` — Réf: FR-024
- [ ] [T-068] [P2] [US-011] Design check sur la page `Users` : `var(--...)` only, patterns `_list-patterns.scss` + `_bottom-sheet.scss` réutilisés (après T-065) — Réf: DESIGN.md

#### [US-013] UI Angular page publique `/auth/accept-invite/:token`

- [ ] [T-069] [P2] [US-013] Créer composant standalone `features/auth/pages/accept-invite/accept-invite.ts|html|scss` (lookup au mount, form, submit, auto-login) — Réf: FR-022
- [ ] [T-070] [P2] [US-013] Ajouter route `{ path: 'accept-invite/:token', loadComponent: ... }` dans `features/auth/auth.routes.ts` — Réf: FR-022
- [ ] [T-071] [P2] [US-013] [P] Supprimer dossier `features/auth/pages/register/` + lien "Créer un compte" sur page login — Réf: FR-011, CX-002
- [ ] [T-072] [P2] [US-013] Modifier `features/auth/services/auth.service.ts` : retirer `register()`, ajouter `acceptInvite()`, `lookupInvite()` — Réf: FR-009, FR-010, FR-011

#### [US-012] UI Flutter Settings > Utilisateurs

- [ ] [T-073] [P2] [US-012] Créer feature `flutter/lib/src/features/admin/` — squelette `data/`, `application/`, `presentation/` — Réf: FR-021
- [ ] [T-074] [P2] [US-012] [P] Créer `data/invitation_model.dart` (Freezed + enum `InvitationStatus`) et `data/admin_user_model.dart` — Réf: FR-021
- [ ] [T-075] [P2] [US-012] Créer `data/admin_repository.dart` (interface) + `data/admin_remote_repository.dart` (impl Dio, pas de Drift) — Réf: FR-021
- [ ] [T-076] [P2] [US-012] Créer `application/invitations_notifier.dart` + `application/admin_users_notifier.dart` (Notifier<ListState<T>>) — Réf: FR-021
- [ ] [T-077] [P2] [US-012] Créer `presentation/users_screen.dart` + `invite_dialog.dart` + widgets de liste — Réf: FR-021, US-012
- [ ] [T-078] [P2] [US-012] Modifier `features/user/data/user_model.dart` : ajouter `isAdmin`, regen (`build_runner`) — Réf: FR-018, FR-024
- [ ] [T-079] [P2] [US-012] Modifier `features/settings/presentation/settings_screen.dart` : tuile `Utilisateurs` conditionnelle à `user.isAdmin` — Réf: FR-024
- [ ] [T-080] [P2] [US-012] Design check Flutter sur `UsersScreen` : `AppColors`, `AppSpacing`, `AppTypography` uniquement (après T-077) — Réf: DESIGN.md

#### [US-013] UI Flutter page publique

- [ ] [T-081] [P2] [US-013] Modifier `routing/route_names.dart` : `acceptInvite = '/accept-invite/:token'`, `acceptInviteName` ; supprimer `register`/`registerName` — Réf: FR-023, CX-003
- [ ] [T-082] [P2] [US-013] Modifier `routing/app_router.dart` : nouvelle `GoRoute` `acceptInvite`, étendre `redirect` avec `isAcceptInviteRoute`, retirer `GoRoute` register + import — Réf: FR-023, CX-003
- [ ] [T-083] [P2] [US-013] Créer `features/auth/presentation/accept_invite_screen.dart` (ConsumerStatefulWidget, lookup via `FutureProvider.family`, form, submit, auto-login, `context.go('/dashboard')`) — Réf: FR-023
- [ ] [T-084] [P2] [US-013] [P] Supprimer `features/auth/presentation/register_screen.dart` + import depuis `app_router.dart` — Réf: FR-011, CX-003

### P3 — Nice to have

_Aucune US P3 dans la spec v1._

**Checkpoint** : Backend : tous les endpoints implémentés, tests PASS. Angular : parcours admin (invitation + copie lien + revoke + disable/enable) fonctionnel manuel. Flutter : parité validée manuellement sur émulateur.

## Phase 4 : Polish

- [ ] [T-090] [P2] [P] Mettre à jour `docs/api-examples.md` (8 nouveaux endpoints + GET /users/me modifié) — Réf: Documentation
- [ ] [T-091] [P2] [P] Mettre à jour `docs/api-errors.md` (409 LAST_ADMIN_CANNOT_BE_DISABLED, 404 invitation, 403 admin) — Réf: Documentation
- [ ] [T-092] [P2] [P] Mettre à jour `docs/architecture.md` (nouvelle entité Invitation, AdminEmailResolver, AdminAuthorizationFilter) — Réf: Documentation
- [ ] [T-093] [P2] [P] Mettre à jour `CHANGELOG.md` (section Unreleased) — Réf: Release
- [ ] [T-094] [P2] Lancer `/design-check` sur les pages Angular (Users, AcceptInvite) — Réf: DESIGN.md
- [ ] [T-095] [P2] [P] Exécuter suite complète backend : `cd api && mvn test` — Réf: NFR-006
- [ ] [T-096] [P2] [P] Exécuter suite complète Angular : `cd app && ng test && ng lint` — Réf: NFR-006
- [ ] [T-097] [P2] [P] Exécuter suite complète Flutter : `cd flutter && flutter test && flutter analyze` — Réf: NFR-006
- [ ] [T-098] [P2] Parcours manuel E2E complet (cf. `quickstart.md` checklist) — Réf: SC-010
- [ ] [T-099] [P2] Review finale : `/devflow.review-impl KKS-232` — Réf: Qualité

**Checkpoint** : Tous les tests PASS. `/design-check` clean. Parcours E2E manuel OK. `review-impl` PASS.

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances

```
Setup (Phase 1)
  T-001 ─┬─► T-002  [P avec T-003 dès T-001 OK]
         └─► T-003
Fondations (Phase 2)
  T-010 ─┐
  T-011 ─┤ (migrations [P] entre elles)
         ├─► T-012 ─► T-013 ─┐
         └─► T-014            │
                              ├─► T-015
  T-014 ─► T-018 ─► T-019 [P]
  T-002 ─► T-016 ─► T-017 [P]
  (T-016/017 [P] avec T-012/013/014/018/019)
P1 User Stories (Phase 3)
  US-001 : T-020/021 [P] ─► T-022 ─► T-023 ─► T-024 [P]
  US-002 : T-025/026 [P] ─► T-027 ─► T-028 ─► T-029 ─► T-030 ─► T-031 ─► T-032/033 [P]
  US-003 : T-034 ─► T-035 ─► T-036 [P]                 (après T-022/023)
  US-008 : T-037 ─► T-038 ─► T-039 ─► T-040 [P]        (après T-022)
  US-004/005/007 : T-041 ─► T-042 ─► T-043 ─► T-044 ─► T-045/046/047 [P]
  US-006 : T-048 ─► T-049 ─► T-050 [P]                 (après T-023, T-035, T-039, T-044)
  US-010 : T-051 ─► T-052 ─► T-053 [P]                 (après T-016)

P2 User Stories (Phase 3 suite)
  Angular :
    T-060/061 [P] ─► T-062/063 [P] ─► T-064 ─► T-065 ─► T-066 ─► T-067 [P] ─► T-068 (design check)
    T-069 ─► T-070 ─► T-071/072 [P]
  Flutter :
    T-073 ─► T-074 ─► T-075 ─► T-076 ─► T-077 ─► T-080 (design check)
    T-078 ─► T-079
    T-081 ─► T-082 ─► T-083 ─► T-084

Polish (Phase 4)
  Tous les P2 user stories ─► T-090..T-094 [tous P entre eux]
                          ─► T-095/096/097 [P]
                          ─► T-098 ─► T-099
```

### US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US-001 | T-020→T-024 | T-013, T-015 |
| US-002 | T-025→T-033 | T-013, T-015, T-022, T-028 |
| US-003 | T-034→T-036 | T-015, T-022, T-023 |
| US-004 | T-041→T-045 | T-014, T-015 |
| US-005 | T-046 | T-042, T-044 |
| US-006 | T-048→T-050 | T-016, T-023, T-035, T-039, T-044 |
| US-007 | T-043, T-047 | T-016, T-042 |
| US-008 | T-037→T-040 | T-022 |
| US-009 | T-041, T-042, T-044 (tâches partagées avec US-004) | T-014, T-016 |
| US-010 | T-051→T-053 | T-016 |
| US-011 | T-060→T-068 (ordre : T-060/T-061 [P] → T-062/T-063 [P] → T-064 → T-065 → T-066 → T-067 → T-068) | T-010–T-053 (backend P1 complet) |
| US-012 | T-073→T-080 (ordre : T-073 → T-074 → T-075 → T-076 → T-077 → T-080 ; T-078 → T-079 en parallèle) | T-010–T-053 |
| US-013 | Angular : T-069 → T-070 → T-071/T-072 [P] ; Flutter : T-081 → T-082 → T-083 → T-084 | T-030, T-031 |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|----------------------|-----------|
| G1 | T-002 + T-003 | T-001 complété |
| G2 | T-010 + T-011 + T-016 (migrations + AdminEmailResolver sont indépendants — T-016 lit la property mais ne requiert pas le schéma DB) | T-001 + T-002 complétés |
| G3 | T-012 + T-014 (enum autonome + ajout colonne entité User) | T-010 + T-011 complétés |
| G4 | T-017 (AdminEmailResolverTest) + T-019 (JwtFilterTest disabled) | T-016 complété (pour T-017) et T-018 complété (pour T-019) |
| G5 | Backend P1 — US-001, US-002, US-003, US-008 entre elles (pas de dépendance mutuelle une fois T-022 présent) | Fondations complétées (T-010→T-019). US-001 et US-008 strictement parallèles une fois `InvitationService.create` écrit. US-003 après T-022/T-023. US-002 indépendante d'US-001/003/008. |
| G6 | Backend P1 — US-004/005/007 (disable/enable/garde-fou) | T-014 + T-016 complétés |
| G7 | Backend P1 — US-006 filter + US-010 isAdmin | T-016 complété |
| G8 | Angular Users (T-060..T-068) + Angular AcceptInvite (T-069..T-072) | Backend P1 complet |
| G9 | Flutter Users (T-073..T-080) + Flutter AcceptInvite (T-081..T-084) | Backend P1 complet |
| G10 | Angular global (G8) + Flutter global (G9) | Backend P1 complet — deux fronts indépendants (équipes séparées possibles) |
| G11 | Polish T-090/T-091/T-092/T-093 (docs) + T-095/T-096/T-097 (tests) | Implémentation complète (L1+L2+L3) |

## Implementation Strategy

### MVP First

Le MVP livre la valeur de conformité constitutionnelle (fermer l'inscription publique) et le flux d'onboarding via API, sans UI.

- **MVP** (Backend P1 complet, pas encore d'UI frontend) : **T-001 → T-053**
  - Phase 1 setup + Phase 2 fondations complète + toutes les US P1 côté backend.
  - À ce stade : `POST /auth/register` n'existe plus, `POST /auth/accept-invite` fonctionne via curl, admin peut inviter / lister / révoquer / désactiver via HTTP. Kelly peut faire tourner en prod avec son compte existant et inviter de nouveaux users en utilisant l'API directement.
- **Itération 2** (UI Angular) : **T-060 → T-072** — UX admin via PWA + page publique acceptation Angular. Kelly peut quitter curl.
- **Itération 3** (UI Flutter + Polish) : **T-073 → T-099** — parité mobile + tests complets + doc + `/design-check` + review-impl.

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée |
|-----------|--------|----------------|
| **L1 — MVP Backend** | T-001 → T-053 | Conformité constitution v2.1.2 (inscription publique retirée). API d'onboarding contrôlé fonctionnelle. Kelly self-hosté opérationnel via API / curl. |
| **L2 — UI Angular** | T-060 → T-072 | Kelly gère les invitations et users depuis la PWA. Parcours complet invité via navigateur. |
| **L3 — UI Flutter** | T-073 → T-084 | Parité mobile. Admin peut opérer depuis son téléphone. |
| **L4 — Polish** | T-090 → T-099 | Documentation à jour, tests complets, design check, review-impl PASS — prêt à merger dans `develop`. |

## Mapping Requirements → Tâches

> **Convention** : les tâches backend (T-010 à T-053) implémentent les endpoints. Les tâches Angular (T-060..T-072) / Flutter (T-073..T-084) consomment ces endpoints et sont traçées via les FR frontend (FR-020 à FR-024) plutôt que sur les FR backend (FR-003 à FR-010). Les endpoints admin (FR-003 à FR-008) restent donc mappés uniquement aux tâches backend.

| Requirement | Tâches backend | Tâches frontend (consommateurs) |
|-------------|----------------|---------------------------------|
| FR-001 | T-010, T-013, T-015 | — |
| FR-002 | T-011, T-014 | — |
| FR-003 | T-020, T-021, T-022, T-023 | T-062 (via FR-020) |
| FR-004 | T-012, T-037, T-038, T-039, T-040 | T-062 (via FR-020) |
| FR-005 | T-034, T-035, T-036 | T-062 (via FR-020) |
| FR-006 | T-041, T-042, T-044 | T-062 (via FR-020) |
| FR-007 | T-042, T-044, T-045 | T-062 (via FR-020) |
| FR-008 | T-042, T-044, T-046 | T-062 (via FR-020) |
| FR-009 | T-026, T-027, T-030, T-036 | T-063, T-072 (via FR-022/FR-023) |
| FR-010 | T-025, T-029, T-030, T-032, T-033 | T-063, T-072 (via FR-022/FR-023) |
| FR-011 | T-031, T-032 | T-071, T-072, T-081, T-082, T-084 |
| FR-012 | T-002, T-016, T-017 | — |
| FR-013 | T-022, T-024 | — |
| FR-014 | T-027, T-028, T-029, T-032, T-036 | — |
| FR-015 | T-029, T-032 | T-069, T-083 (email lecture seule UI) |
| FR-016 | T-018, T-019 | — |
| FR-017 | T-043, T-047 | — |
| FR-018 | T-051, T-052, T-053 | T-064, T-078 |
| FR-019 | T-048, T-049, T-050 | — |
| FR-020 | — | T-060, T-061, T-062, T-065, T-066 |
| FR-021 | — | T-073, T-074, T-075, T-076, T-077 |
| FR-022 | — | T-060, T-069, T-070 |
| FR-023 | — | T-081, T-082, T-083 |
| FR-024 | T-051, T-052 (flag isAdmin backend) | T-061, T-064, T-067, T-078, T-079 |

### NFR / SC / Contraintes data-model

| Référence | Tâches |
|-----------|--------|
| NFR-002 (logs INFO admin) | T-023 (create), T-034 (revoke), T-042 (disable/enable), T-044 (controller), T-029 (accept-invite) |
| NFR-003 (isolation user) | T-033 |
| NFR-004 (Bean Validation) | T-020, T-025 |
| NFR-005 (BCrypt) | T-029 (réutilise `passwordEncoder` existant du pattern `AuthService`) |
| NFR-006 (tests) | T-017, T-019, T-024, T-032, T-033, T-036, T-040, T-045, T-046, T-047, T-050, T-053, T-095, T-096, T-097 |
| NFR-008 (WARN boot) | T-016, T-017 |
| DC-001 (token UNIQUE) | T-010, T-015 |
| DC-002 (FK invited_by) | T-010 |
| DC-003 (exclusion usedAt / revokedAt) | T-027, T-028, T-032, T-036 |
| DC-004 (expiresAt = created + 7j) | T-022, T-024 |
| DC-005 (au moins 1 admin actif) | T-043, T-047 |
| DC-006 (acceptation uniquement ACTIVE) | T-027, T-029, T-032 |
| SC-001 | T-031, T-032 |
| SC-002 | T-050 |
| SC-003 | T-032 |
| SC-004 | T-032 |
| SC-005 | T-036 |
| SC-006 | T-032, T-069, T-083 |
| SC-007 | T-018, T-019, T-045 |
| SC-008 | T-047 |
| SC-009 | T-098 |
| SC-010 | T-098 |
| SC-011 | T-053 |
| SC-012 | T-033 |
| SC-013 | T-046 |

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| Setup | 3 | 3 | 0 | 0 | 2 (T-002, T-003) |
| Fondations | 10 | 10 | 0 | 0 | 4 (T-011, T-016, T-017, T-019) |
| User Stories P1 | 34 | 34 | 0 | 0 | 12 (T-021, T-024, T-026, T-032, T-033, T-036, T-040, T-045, T-046, T-047, T-050, T-053) |
| User Stories P2 | 25 | 0 | 25 | 0 | 8 (T-060, T-061, T-062, T-063, T-067, T-071, T-074, T-084) |
| User Stories P3 | 0 | 0 | 0 | 0 | 0 |
| Polish | 10 | 0 | 10 | 0 | 7 (T-090, T-091, T-092, T-093, T-095, T-096, T-097) |
| **Total** | **82** | **47** | **35** | **0** | **33** |
