# Quickstart — KKS-232 : Onboarding contrôlé

> Date : 2026-04-19
> Issue : KKS-232

---

## Pré-requis

- [x] Constitution lue (`.specify/memory/constitution.md` v2.1.2)
- [x] Spec validée (`spec.md` — review PASS itération 2)
- [x] Research complétée (`research.md` — 10 décisions)
- [x] Plan approuvé (`plan.md`)
- [ ] Tasks générées (`tasks.md` — étape suivante)

## Phase 1 — Setup

```bash
# Branche déjà créée lors de /devflow.spec
git checkout feature/KKS-232

# Vérifier que le backend compile et que la DB dev est up
cd api && mvn clean compile
cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev   # laisser tourner
```

**Vérification** : `http://localhost:8080/api/swagger-ui.html` accessible. Migrations Flyway déjà appliquées jusqu'à V27.

## Phase 2 — Fondations

### Fichiers à créer

| Fichier | Template/Base | Description |
|---------|---------------|-------------|
| `api/src/main/resources/db/migration/V28__add_invitations.sql` | cf. data-model.md §Migrations | Table `invitation` + index |
| `api/src/main/resources/db/migration/V29__add_user_disabled_at.sql` | cf. data-model.md | Colonne `disabled_at` |
| `api/.../model/Invitation.java` | Lombok JPA pattern (cf. `User.java`) | Entité |
| `api/.../enums/InvitationStatus.java` | pattern `enums/` existant | Enum dérivé |
| `api/.../repository/InvitationRepository.java` | `JpaRepository<Invitation, Long>` | + `findByToken` |
| `api/.../config/AdminEmailResolver.java` | pattern `@Value` + `@PostConstruct` | Composant config |
| `api/.../config/AdminAuthorizationFilter.java` | pattern `JwtFilter.java` | `OncePerRequestFilter` |

### Étapes

1. Créer les deux fichiers Flyway `V28` et `V29` — laisser Spring Boot les appliquer au prochain restart.
2. Créer l'entité `Invitation` + `InvitationRepository` + enum `InvitationStatus`.
3. Créer `AdminEmailResolver` avec test unitaire (match trim/lowercase, warn vide).
4. Ajouter la property `app.admin-emails: ${ADMIN_EMAILS:}` dans `application.yaml` (défaut vide).
5. Créer `AdminAuthorizationFilter` + enregistrer dans `SecurityConfig` (`.addFilterAfter(adminAuthFilter, JwtFilter.class)`).
6. Modifier `JwtFilter` — ajouter `.filter(u -> u.getDisabledAt() == null)` avant `.ifPresent`.
7. Ajouter colonne `disabledAt` dans `User.java` (Lombok prendra en charge les getters/setters).

**Vérification** : `cd api && mvn test` — aucun test cassé (modifs encore transparentes). Restart dev → Flyway applique V28/V29.

## Phase 3 — Implémentation User Stories

### US-001 — Admin crée une invitation

1. Créer `CreateInvitationRequest` (record avec `@Email @NotBlank email`).
2. Créer `InvitationCreatedResponse` (record `token`, `expiresAt`).
3. Créer `InvitationService.create(User invitedBy, String email)` avec `@Transactional`.
4. Créer `AdminInvitationController` — endpoint `POST /admin/invitations` (201).
5. Tests : unitaire service + intégration controller (matrice anonyme → 401, non-admin → 403, admin → 201).

**Test** : `curl -X POST http://localhost:8080/api/admin/invitations -H "Authorization: Bearer $TOKEN_ADMIN" -H "Content-Type: application/json" -d '{"email":"new@example.com"}'` → `{ token, expiresAt }`.

### US-002 — Invité accepte l'invitation

1. Créer `AcceptInviteRequest` (record `token`, `password`, `displayName`, `currency`, `timezone`).
2. Créer `InviteLookupResponse` (record `email`).
3. Implémenter `InvitationService.validatePublic(UUID)` — retourne `Optional<Invitation>` uniquement si ACTIVE.
4. Créer `AcceptInviteService.acceptInvite(AcceptInviteRequest)` — `@Transactional`, migrer la logique de `AuthService.register` (save user, seedCategories, createAccount, createPreference, markUsed, generate JWT).
5. Modifier `AuthController` — ajouter `GET /auth/invitations/:token` + `POST /auth/accept-invite`, retirer `POST /auth/register`.
6. Supprimer `AuthService.register` + `RegisterRequest`.
7. Tests : cas nominal, token expiré, utilisé, révoqué, inconnu, email non-modifiable.

**Test** : `curl http://localhost:8080/api/auth/invitations/<token>` → `{ email }`. Puis `POST /auth/accept-invite` avec le body complet → `{ token, refreshToken, email, name }`.

### US-003 — Admin révoque une invitation

1. `InvitationService.revoke(Long id)` → set `revokedAt = now`.
2. `AdminInvitationController` endpoint `DELETE /admin/invitations/:id` (204).
3. Test : révocation puis `GET /auth/invitations/:token` → 404.

### US-004, US-005, US-007 — Disable / Enable user + garde-fou

1. Créer `AdminUserService.list()`, `disable(UUID)`, `enable(UUID)`.
2. Garde-fou : `if (email ∈ ADMIN_EMAILS && countActiveAdmins() == 1) throw new ConflictException("LAST_ADMIN_CANNOT_BE_DISABLED")`.
3. Controller `AdminUserController` — `GET /admin/users`, `PATCH /admin/users/:id/disable`, `PATCH /admin/users/:id/enable`.
4. Tests : disable + rejouer request authentifiée → 401 ; enable + request → 200 ; garde-fou → 409 payload `LAST_ADMIN_CANNOT_BE_DISABLED`.

### US-008, US-009 — Listes admin

1. `InvitationService.list()` — tri `createdAt DESC`, statut dérivé.
2. `AdminInvitationController` — `GET /admin/invitations`.
3. `AdminUserService.list()` → `AdminUserResponse(id, email, displayName, createdAt, disabledAt, isAdmin)`.
4. Tests : fixtures 4 invitations dans les 4 états → tous présents avec bon statut.

### US-010 — `isAdmin` dans `/users/me`

1. Modifier `UserResponse` : `(name, email, isAdmin)`.
2. Modifier `UserService.getProfile` — injecter `AdminEmailResolver`, peupler `isAdmin`.
3. Tests : fixture admin → `isAdmin=true` ; non-admin → `false`.

### US-011, US-013 — Angular

1. `admin.service.ts`, `invitation.service.ts` — HTTP clients typés.
2. `current-user.store.ts` — ajouter `isAdmin` signal (lu depuis `/users/me`).
3. Modifier `user.model.ts` + `invitation.model.ts`.
4. Créer `features/settings/pages/users/` (standalone, OnPush, signals).
5. Ajouter route `users` dans `settings.routes.ts`, tuile conditionnelle dans menu settings.
6. Créer `features/auth/pages/accept-invite/` — route dans `auth.routes.ts`.
7. Supprimer `features/auth/pages/register/` + lien "Créer un compte".
8. Tests unitaires composants + manuels parcours.

**Test UI** : `cd app && ng serve` → naviguer `Settings > Utilisateurs`, créer invitation, copier lien, ouvrir navigation privée, coller l'URL, remplir le formulaire, vérifier redirection dashboard.

### US-012, US-013 — Flutter

1. Créer `features/admin/` (data + application + presentation) selon pattern projet.
2. Regen `UserModel` Freezed avec `isAdmin` : `dart run build_runner build --delete-conflicting-outputs`.
3. Ajouter route `/accept-invite/:token` dans `app_router.dart` + étendre `redirect` global.
4. Créer `accept_invite_screen.dart`, supprimer `register_screen.dart` + imports + `RouteNames.register`.
5. Modifier `settings_screen.dart` — tuile `Utilisateurs` conditionnelle à `isAdmin`.
6. Tests widget + providers (pattern `ProviderContainer` + overrides).

**Test UI** : `cd flutter && flutter run` → émulateur → parcours admin + parcours invité.

## Phase 4 — Polish

1. Exécuter les tests backend : `cd api && mvn test`
2. Exécuter les tests Angular : `cd app && ng test`
3. Exécuter les tests Flutter : `cd flutter && flutter test`
4. Lint : `cd app && ng lint` + `cd flutter && flutter analyze`
5. Vérifier `/design-check` sur les pages Angular.
6. Documentation :
   - `docs/deployment.md` — ajouter section "Configuration admin" (`ADMIN_EMAILS`).
   - `docs/api-examples.md` — exemples pour les 8 nouveaux endpoints.
   - `docs/api-errors.md` — `LAST_ADMIN_CANNOT_BE_DISABLED` (409).
7. Pre-commit review (`pre-commit-review` + `frontend-design-review` sur fichiers frontend).
8. `/devflow.review-impl KKS-232`.

## Commandes utiles

| Action | Commande |
|--------|----------|
| Lancer backend dev | `cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev` |
| Tests backend | `cd api && mvn test` |
| Un test unique | `cd api && mvn test -Dtest=AcceptInviteServiceTest` |
| Lancer Angular | `cd app && ng serve` |
| Tests Angular | `cd app && ng test` |
| Lint Angular | `cd app && ng lint` |
| Lancer Flutter | `cd flutter && flutter run` |
| Regen Flutter | `cd flutter && dart run build_runner build --delete-conflicting-outputs` |
| Tests Flutter | `cd flutter && flutter test` |
| Swagger | `http://localhost:8080/api/swagger-ui.html` |

## Checklist finale

- [ ] Migrations V28 + V29 appliquées en dev et vérifiées en prod staging
- [ ] `POST /auth/register` retourne 404
- [ ] Matrice `admin/*` × (anonyme, user non-admin, admin) couverte
- [ ] Garde-fou dernier admin → 409 `LAST_ADMIN_CANNOT_BE_DISABLED`
- [ ] User désactivé → 401 sur requêtes authentifiées
- [ ] Token expiré / utilisé / révoqué → 404 sur GET et POST
- [ ] Email verrouillé côté formulaire Angular + Flutter
- [ ] `ADMIN_EMAILS` documenté dans `docs/deployment.md`
- [ ] WARN au boot si `ADMIN_EMAILS` vide ou aucun user actif correspondant
- [ ] `/users/me` renvoie `isAdmin` correct
- [ ] Parité UX Angular / Flutter vérifiée manuellement
- [ ] Tous les tests passent
- [ ] Pas de warning lint (`ng lint`, `flutter analyze`)
- [ ] Pre-commit review + frontend-design-review OK
- [ ] `/devflow.review-impl` PASS
- [ ] `CHANGELOG.md` mis à jour (section Unreleased)
- [ ] Documentation `docs/` alignée (deployment, api-examples, api-errors)
