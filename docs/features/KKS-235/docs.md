# Documentation — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-05-03
> Issue : [KKS-235](https://linear.app/kksdev/issue/KKS-235/page-mon-compte-profil-securite-donnees-suppression-fix-bouton)
> Branche : `feature/KKS-235`

---

## Résumé

KKS-235 introduit une page **Mon compte** dédiée (`/settings/account` côté Angular, `/settings/profile` côté Flutter) regroupant 4 sections fonctionnelles : Identité (avatar + nom + email), Sécurité (changement de mot de passe), Données (export JSON + CSV), Zone de danger (déconnexion + suppression de compte). La feature corrige également un bug d'UI préexistant : le bouton Déconnexion sur Settings n'avait aucun handler côté Angular. La suppression de compte est implémentée en **soft-delete** avec garde-fou dernier administrateur actif, et l'avatar uploadable est désormais affiché de manière cohérente dans le header, le hub Settings et la page Mon compte.

---

## Guide utilisateur

### Fonctionnalités

#### 1. Modifier son nom

**Description** : un utilisateur peut modifier son nom affiché depuis la section Identité de la page Mon compte. Le changement est persistant et reflété immédiatement dans le header et le hub Settings.

**Usage** :
1. Ouvrir le menu utilisateur (pastille en haut à droite) → "Paramètres" → "Mon compte"
2. Dans la section Identité, taper sur le crayon à côté du nom
3. Saisir le nouveau nom (1 à 100 caractères) puis valider

**Note** : l'email est en lecture seule. Toute modification d'email passe par l'administrateur du serveur (sécurité — prévention de l'élévation de privilèges via `ADMIN_EMAILS`).

---

#### 2. Personnaliser sa photo de profil (avatar)

**Description** : upload d'une photo de profil personnalisée affichée dans le header, le hub Settings et la page Mon compte. Les fichiers sont validés (format JPG/PNG via magic numbers, taille ≤ 2 MB), redimensionnés en 256×256 pixels et stockés sur le disque local du serveur self-hosted.

**Usage** :
1. Page Mon compte → section Identité → taper sur l'avatar circulaire (initiales ou photo actuelle)
2. Sélectionner une image JPG ou PNG (≤ 2 MB)
3. La photo est uploadée, redimensionnée côté serveur et affichée immédiatement
4. Pour retirer la photo : taper sur l'avatar → menu → "Supprimer la photo" → fallback sur les initiales

**Limites** :
- Formats acceptés : `image/jpeg`, `image/png`
- Taille max : 2 MB en transit (côté Flutter, pré-compression automatique pour respecter la limite)
- Sortie : JPEG 256×256 qualité 85% (~30-60 KB sur disque, EXIF-rotation gérée automatiquement)

---

#### 3. Changer son mot de passe

**Description** : changement du mot de passe avec vérification de l'ancien mot de passe et politique de sécurité harmonisée (minimum 12 caractères, doit être différent de l'actuel). Au succès, tous les refresh tokens sont révoqués (autres devices déconnectés à expiration JWT) et le device courant reçoit immédiatement un nouveau couple JWT + refresh token (continuité de session).

**Usage** :
1. Page Mon compte → section Sécurité → "Changer le mot de passe"
2. Saisir l'ancien mot de passe + le nouveau (≥ 12 caractères) + sa confirmation
3. Valider

**Sécurité** :
- Tous les refresh tokens du compte sont invalidés à l'instant du changement
- Les autres devices peuvent encore utiliser leur JWT actuel jusqu'à expiration (≤ 15 min) mais ne peuvent plus se renouveler

---

#### 4. Exporter ses données

**Description** : export RGPD de toutes les données du compte au format JSON (full backup) ou CSV (transactions seulement, optimisé pour Excel/LibreOffice).

**Usage** :
1. Page Mon compte → section Données
2. **JSON** : "Exporter mes données (JSON)" — télécharge un fichier `kbudget-export-{user_id}-{date}.json` contenant toutes les entités (transactions, comptes, catégories, budgets, abonnements, dettes, préférences, règles d'import, profils d'import, historique d'import, invitations émises) avec le hash du mot de passe **explicitement exclu** pour la sécurité.
3. **CSV** : "Exporter mes transactions (CSV)" — télécharge `kbudget-transactions-{user_id}-{date}.csv` au format RFC 4180, encodage UTF-8 BOM (compatible Excel), entêtes français : `Date`, `Libellé`, `Montant`, `Devise`, `Compte`, `Catégorie`, `Type` (avec traduction `RECETTE → "Revenu"`, `DEPENSE → "Dépense"`, `AJUSTEMENT → "Ajustement"`).

**Versionning** : la clé `schemaVersion` (SemVer, initial `"1.0.0"`) au top-level du JSON permet aux outils tiers de détecter le format. Les évolutions futures incrémenteront cette version selon SemVer (PATCH = correction, MINOR = ajout d'entité, MAJOR = breaking change).

---

#### 5. Se déconnecter

**Description** : déconnexion proprement implémentée (auparavant le bouton existait visuellement sans handler). Révoque le refresh token côté serveur et purge le JWT côté client. Résilient en cas d'échec réseau (purge locale + redirect garantis).

**Usage** :
- Pastille utilisateur (header, top-right) → "Déconnexion" — OU
- Page Mon compte → section Zone de danger → "Déconnexion"

---

#### 6. Supprimer son compte

**Description** : suppression définitive du compte en **soft-delete** (le row reste en base avec `disabled_at = now()`). Garde-fou : le dernier administrateur actif ne peut pas se supprimer (refus 403 explicite). Confirmation par mot de passe + checkbox de confirmation explicite.

**Usage** :
1. Page Mon compte → section Zone de danger → "Supprimer mon compte"
2. Saisir le mot de passe actuel + cocher la case "Je comprends que cette action est définitive"
3. Le bouton "Supprimer mon compte" devient actif → valider
4. Déconnexion immédiate + redirection vers `/auth`

**Effet** :
- `users.disabled_at` positionné à `now()`
- Tous les refresh tokens révoqués
- Login bloqué (401) sur ce compte
- Données conservées en base pour traçabilité (auditabilité, restauration possible par un admin via SQL si besoin)

---

### Exemples d'utilisation

#### Exemple : exporter ses transactions et ouvrir dans Excel

```bash
# Côté Angular : un fichier kbudget-transactions-<user_id>-20260503.csv est téléchargé
# Côté Flutter : sauvegardé dans getApplicationDocumentsDirectory()
```

Ouvrir avec Excel : double-clic, les accents apparaissent correctement grâce au BOM UTF-8.

#### Exemple : changer son mot de passe via l'API

```http
POST /api/users/me/password
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "currentPassword": "ancien_mot_de_passe",
  "newPassword": "nouveau_mot_de_passe_12_chars_min"
}

→ 200 OK
{
  "token": "<nouveau_jwt>",
  "refreshToken": "<nouveau_refresh_token>",
  "email": "user@example.com",
  "name": "Utilisateur Test",
  "mustResetCredentials": false
}
```

---

## Changements techniques

### Fichiers créés

#### Backend Spring Boot (api/)

| Fichier | Description |
|---------|-------------|
| `db/migration/V32__add_user_avatar_path.sql` | Ajout colonne `users.avatar_path VARCHAR(512)` |
| `db/migration/V33__patch_budgets_user_fk_cascade.sql` | Patch FK `budgets.user_id` → `ON DELETE CASCADE` (filet de sécurité) |
| `db/migration/V34__patch_budget_snapshots_user_fk_cascade.sql` | Patch FK `budget_snapshots.user_id` → `ON DELETE CASCADE` |
| `db/migration/V35__patch_refresh_tokens_user_fk_cascade.sql` | No-op documentaire (cascade existait déjà depuis V6) |
| `config/StorageProperties.java` | `@ConfigurationProperties(prefix = "app.storage")` pour le path des avatars |
| `util/ImageMimeValidator.java` | Validation MIME via magic numbers (JPEG `FF D8 FF`, PNG `89 50 4E 47…`) |
| `dto/request/UpdateProfileRequest.java` | DTO self-service profil (renommage de `UpdateUserRequest`, **PAS de champ email**) |
| `dto/request/ChangePasswordRequest.java` | DTO change-password avec `@Size(min=12, max=100)` |
| `dto/request/DeleteAccountRequest.java` | DTO suppression avec `@AssertTrue confirmed` |
| `dto/response/AvatarMetadataResponse.java` | DTO réponse upload avatar (url, etag, uploadedAt) |
| `dto/response/UserExportResponse.java` | Record top-level export JSON + 13 sub-records (sans `password`) |
| `service/AvatarStorageService.java` | Validation + redim Thumbnailator + ETag SHA-256 |
| `service/UserPasswordService.java` | Change-password avec révocation refresh tokens + nouveau JWT |
| `service/UserExportService.java` | Export JSON (Jackson) + CSV (Apache Commons CSV streaming) |
| `service/UserDeletionService.java` | Soft-delete avec garde dernier admin |
| `exception/InvalidImageFormatException.java` | 400 INVALID_IMAGE_FORMAT |
| `exception/FileTooLargeException.java` | 413 FILE_TOO_LARGE |
| `exception/AvatarNotFoundException.java` | 404 AVATAR_NOT_FOUND |
| `exception/PasswordIncorrectException.java` | 401 PASSWORD_INCORRECT |
| `exception/ConfirmationRequiredException.java` | 400 CONFIRMATION_REQUIRED |
| `exception/LastAdminDeletionForbiddenException.java` | 403 LAST_ADMIN_DELETION_FORBIDDEN |
| `exception/InvalidExportFormatException.java` | 400 INVALID_EXPORT_FORMAT |

#### Frontend Angular (app/)

| Fichier | Description |
|---------|-------------|
| `core/services/avatar.service.ts` | Singleton avatar avec signal blob URL, gestion cycle de vie URL.createObjectURL/revokeObjectURL |
| `core/services/user-export.service.ts` | Service export JSON/CSV avec déclenchement download via blob URL |
| `core/models/update-profile-request.model.ts` | Interface TS DTO profil |
| `core/models/avatar-metadata.model.ts` | Interface TS DTO avatar |
| `core/models/delete-account-request.model.ts` | Interface TS DTO suppression |
| `lib/avatar-upload/avatar-upload.component.{ts,html,scss}` | Composant lib réutilisable d'upload avatar (signals-first, OnPush) |
| `features/settings/account/mon-compte.component.{ts,html,scss}` | Page Mon compte avec 4 sections |
| `features/settings/account/change-password-dialog.component.{ts,html,scss}` | Dialog changement mot de passe |
| `features/settings/account/delete-account-confirm-dialog.component.{ts,html,scss}` | Dialog confirmation suppression |

#### Frontend Flutter (flutter/)

| Fichier | Description |
|---------|-------------|
| `features/user_profile/domain/models/avatar_metadata.dart` | Model Freezed avatar |
| `features/user_profile/domain/models/change_password_request.dart` | Model Freezed change-password |
| `features/user_profile/domain/models/delete_account_request.dart` | Model Freezed suppression |
| `features/user_profile/domain/repositories/user_profile_repository.dart` | Interface étendue |
| `features/user_profile/data/user_profile_repository_remote.dart` | Implémentation Dio (server-only, pas de cache Drift) |
| `features/user_profile/application/user_profile_repository_provider.dart` | `FutureProvider` server-only |
| `features/user_profile/presentation/widgets/avatar_picker.dart` | Widget picker + flutter_image_compress + Dio upload |
| `features/user_profile/presentation/widgets/change_password_sheet.dart` | Bottom sheet change-password |
| `features/user_profile/presentation/widgets/delete_account_sheet.dart` | Bottom sheet suppression |

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `api/pom.xml` | Ajout dépendance `net.coobird:thumbnailator:0.4.20` |
| `api/src/main/resources/application.yaml` | Ajout `app.storage.avatars.path: ${AVATAR_STORAGE_PATH:./data/avatars}` |
| `api/src/main/java/.../model/User.java` | Ajout `@Column(name = "avatar_path") String avatarPath` |
| `api/src/main/java/.../repository/UserRepository.java` | Ajout `findByEmailAndDisabledAtIsNull` + `countActiveAdmins` |
| `api/src/main/java/.../service/AuthService.java` | `login` filtre `disabled_at` |
| `api/src/main/java/.../service/UserService.java` | Méthode `findById` rendue publique pour respecter Controller→Service→Repository |
| `api/src/main/java/.../config/JwtFilter.java` | Filtre `disabled_at` lors de la résolution user |
| `api/src/main/java/.../config/StompAuthInterceptor.java` | Idem (sécurité STOMP) |
| `api/src/main/java/.../controller/UserController.java` | 8 endpoints (1 modifié + 7 nouveaux) |
| `api/src/main/java/.../config/GlobalExceptionHandler.java` | 7 nouveaux handlers d'exception |
| `api/src/main/java/.../dto/request/FirstLoginResetRequest.java` | `@Size(min=8)` → `@Size(min=12)` (politique MDP harmonisée) |
| `flutter/pubspec.yaml` | Ajout `flutter_image_compress: ^2.3.0` |
| `flutter/.../profile_settings_screen.dart` | Étendu avec sections Identité (AvatarPicker), Sécurité, Données, Zone de danger |
| `app/src/app/features/settings/settings.{html,ts,scss}` | Bouton Déconnexion retiré (déplacé), bind `avatarUrl` |
| `app/src/app/shared/components/shell/shell.{ts,html,scss}` | Avatar dans le header bind sur `AvatarService.avatarUrl` |
| `app/src/app/core/services/user.ts` | Ajout `updateProfile`, `changePassword`, `deleteAccount` |
| `app/src/app/core/services/api.ts` | Ajout helper `deleteWithBody` (DELETE avec body JSON) |
| `docs/api-examples.md` | Section "Mon compte (KKS-235)" — 8 endpoints documentés |
| `docs/api-errors.md` | 8 nouveaux codes d'erreur + règles de validation |
| `docs/deployment.md` | Variable `AVATAR_STORAGE_PATH` + procédure backup avatars |
| `docs/manual-test-plan.md` | Section 22 KKS-235 — 31 scénarios manuels |
| `.gitignore` | Ajout `data/` et `**/data/avatars/` |

### Dépendances ajoutées

| Package | Version | Couche | Raison |
|---------|---------|--------|--------|
| `net.coobird:thumbnailator` | 0.4.20 | Backend Maven | Redimensionnement image avec gestion EXIF auto-rotation (RES-001) |
| `flutter_image_compress` | ^2.3.0 | Flutter pubspec | Pré-compression côté client avant upload pour respecter la limite 2 MB serveur (RES-012) |

---

## Configuration

### Variables d'environnement

| Variable | Défaut | Description |
|----------|--------|-------------|
| `AVATAR_STORAGE_PATH` | `./data/avatars` | Chemin disque local de stockage des avatars utilisateurs. **Recommandation production** : `/var/k-budget/avatars`. Le dossier est créé automatiquement au démarrage si absent. |

### Permissions disque

```bash
# En production self-hosted
mkdir -p /var/k-budget/avatars
chown -R k-budget:k-budget /var/k-budget/avatars
chmod 750 /var/k-budget/avatars
```

### Backup

Le dossier `${AVATAR_STORAGE_PATH}` doit être inclus dans la stratégie de backup serveur (les avatars ne sont **pas** dans le dump PostgreSQL). Exemple cron :

```bash
0 3 * * * tar -czf /backup/avatars-$(date +\%Y\%m\%d).tar.gz /var/k-budget/avatars
```

Voir `docs/deployment.md` pour les détails complets.

---

## Tests et validation

### Tests unitaires (backend Spring Boot)

| Suite | Tests | Statut |
|-------|-------|--------|
| `ImageMimeValidatorTest` | 5 | ✅ |
| `AvatarStorageServiceTest` | 8+ | ✅ |
| `UserPasswordServiceTest` | 5 | ✅ |
| `UserDeletionServiceTest` | 7 | ✅ |
| `UserExportServiceTest` | 7 | ✅ |
| **Suite complète backend** | **592** | ✅ 0 failure |

### Tests d'intégration (backend)

| Scénario | Test | Statut |
|----------|------|--------|
| Upload avatar JPG valide | `should_upload_avatar_when_valid_jpg` | ✅ |
| Rejet MIME invalide | `should_reject_when_invalid_mime` | ✅ |
| Service avec ETag SHA-256 | `should_serve_avatar_with_etag` | ✅ |
| 304 sur If-None-Match correct | `should_return_304_when_etag_matches` | ✅ |
| Change password — nominal + 4 cas erreurs | 5 tests | ✅ |
| Soft-delete + login bloqué après | `should_soft_delete_user_when_password_correct` + `should_block_login_after_soft_delete` | ✅ |
| Garde dernier admin actif | `should_throw_when_last_admin` + `should_succeed_when_admin_not_alone` | ✅ |
| Export JSON exhaustif | `should_export_all_user_entities_when_format_json` | ✅ |
| Export CSV BOM + traduction Type | `should_translate_transaction_type_in_csv` + `should_include_utf8_bom_in_csv` | ✅ |
| Pas de password hash dans export | `should_not_expose_password_hash_in_export` | ✅ |
| Performance JSON 10K transactions < 5s | `UserExportPerformanceIT` (`@Tag("performance")`) | ✅ |

### Tests frontend

| Stack | Tests | Statut |
|-------|-------|--------|
| Angular (vitest) | 475 | ✅ 0 failure |
| Flutter (`test/src/features/user_profile/`) | 30+ | ✅ |

### Validation manuelle

Voir `docs/manual-test-plan.md` section "22. KKS-235 — Page Mon compte" : 31 scénarios documentés (MC-1 à MC-31).

- [x] Scénario nominal testé (page accessible, avatar upload, change password, export, déconnexion, soft-delete)
- [x] Edge cases testés (fichier trop grand, MIME invalide, MDP incorrect, dernier admin, format export invalide)
- [x] Régression vérifiée (`BudgetServiceTest`, `BudgetSnapshotServiceTest`, `AuthServiceTest` : tous verts après les 4 migrations CASCADE)

---

## Sécurité

Points de vigilance implémentés :

| Risque | Mitigation |
|--------|------------|
| Privilege escalation via modification d'email | DTO `UpdateProfileRequest` n'expose **pas** de champ email. Renommé depuis `UpdateUserRequest` avec commentaire de garde explicite. Email géré par l'admin uniquement. |
| Fichier maquillé (extension JPG, contenu PDF) | `ImageMimeValidator` valide les magic numbers (premiers octets) côté serveur. Test dédié. |
| Password hash exposé dans l'export JSON | DTO `UserExportResponse.UserDto` ne contient **pas** de champ `password`. Test dédié `should_not_expose_password_hash_in_export`. |
| Suppression du dernier admin → instance ingérable | Garde explicite dans `UserDeletionService` : refus 403 `LAST_ADMIN_DELETION_FORBIDDEN` si `countActiveAdmins() <= 1`. |
| Login après soft-delete | `AuthService.login`, `JwtFilter` et `StompAuthInterceptor` filtrent `disabled_at IS NULL` (filtrage explicite, pas de Hibernate filter global — décision RES-005 YAGNI). |
| Sessions actives après change-password | Tous les refresh tokens du user sont révoqués. Le device courant reçoit un nouveau couple JWT + refresh token (continuité). Les autres devices peuvent encore utiliser leur JWT actuel jusqu'à expiration naturelle (≤ 15 min) mais ne peuvent plus se renouveler. |

---

## Architecture

### Endpoints REST

| Verbe | Path | Description |
|-------|------|-------------|
| `PUT` | `/api/users/me` | Modifier nom (UpdateProfileRequest) |
| `POST` | `/api/users/me/avatar` | Upload avatar (multipart) |
| `GET` | `/api/users/me/avatar` | Servir avatar (avec ETag SHA-256) |
| `DELETE` | `/api/users/me/avatar` | Supprimer avatar (204) |
| `POST` | `/api/users/me/password` | Changer mot de passe (retour AuthResponse avec nouveaux tokens) |
| `GET` | `/api/users/me/export?format=json` | Export JSON full backup |
| `GET` | `/api/users/me/export?format=csv` | Export CSV transactions (streaming) |
| `DELETE` | `/api/users/me` | Suppression compte soft-delete |

### Cache HTTP avatar

Pattern ETag SHA-256 (8 premiers caractères hex) + `Cache-Control: private, must-revalidate, max-age=0`. Permet :
- 304 Not Modified si l'avatar n'a pas changé (économie de bande passante)
- Invalidation immédiate après upload/delete (le hash change → ETag différent → re-fetch automatique)

### Mode offline (Flutter)

La page Mon compte est en **mode server-only** (RES-013) — pas de cache Drift local. Justification : toutes les actions de cette page sont intrinsèquement online (changement MDP, export, suppression). En cas de connectivité perdue, un état dégradé est affiché sans données obsolètes. Conforme au principe IV de la constitution (exception "données fraîches requises").

---

## Historique de la feature

### Commits sur `feature/KKS-235`

| Commit | Description |
|--------|-------------|
| `88374f5` | Fondations backend : migrations + soft-delete login + StorageProperties + ImageMimeValidator |
| `f8da239` | Page Mon compte (US-001/002/003) + fix bouton déconnexion |
| `05e21c4` | Export données (US-004) |
| `d7649fc` | Suppression de compte (US-005) |
| `8fbc9ec` | Documentation polish phase 4 + nettoyage gitignore |
| `e0b5146` | Corrections review-impl (W-1, W-2/6, W-5, I-1, I-4) |
| `86e9356` | Fix avatar 401 (HttpClient + blob URL) |
| `b4e33ed` | Fix export CSV (séparation endpoints typés) |
| `ef52cd3` | Avatar global — header + settings hub bind sur AvatarService |

### Reviews

| Phase | Verdict | Itérations |
|-------|---------|------------|
| `review-spec` | PASS | 1 |
| `review-tasks` | PASS | 1 |
| `review-impl` | PASS | 1 (5 WARNING + 5 INFO traités en post-review) |

### Items review-spec absorbés

10/10 items (W-001 à W-005 et I-001 à I-005) absorbés en plan ou en code. Voir `review-log.md` pour le détail.

---

## Références

- [`spec.md`](./spec.md) — Spécification fonctionnelle (25 FR, 9 NFR, 14 SC, 5 US)
- [`clarify-log.md`](./clarify-log.md) — Résolution des 5 ambiguïtés (CL-001 à CL-005)
- [`research.md`](./research.md) — 13 décisions techniques (RES-001 à RES-013)
- [`plan.md`](./plan.md) — Plan d'architecture, 7/7 gates constitutionnelles PASS
- [`data-model.md`](./data-model.md) — Schéma DB et migrations
- [`contracts.md`](./contracts.md) — Contrats API (DTOs + endpoints + composants UI)
- [`tasks.md`](./tasks.md) — 77 tâches en 4 phases
- [`quickstart.md`](./quickstart.md) — Guide d'implémentation pas-à-pas
- [`review-log.md`](./review-log.md) — Journal des 3 reviews PASS

### Documentation projet mise à jour

- [`docs/api-examples.md`](../../api-examples.md) — section "Mon compte (KKS-235)"
- [`docs/api-errors.md`](../../api-errors.md) — 8 nouveaux codes
- [`docs/deployment.md`](../../deployment.md) — `AVATAR_STORAGE_PATH` + backup avatars
- [`docs/manual-test-plan.md`](../../manual-test-plan.md) — 31 scénarios manuels
