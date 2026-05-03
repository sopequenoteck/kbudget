# Research — KKS-235 : Page Mon compte (profil, sécurité, données, suppression) + fix bouton déconnexion

> Date : 2026-04-30
> Issue : KKS-235
> Spec : [spec.md](./spec.md)
> Clarify : [clarify-log.md](./clarify-log.md)
> Review-spec : [review-log.md](./review-log.md) (PASS, 5 WARNING, 5 INFO)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Backend — Lib | Quelle lib pour le redimensionnement d'image (BufferedImage natif, Thumbnailator, autre) ? | Haute |
| RES-002 | Backend — Sécurité | Validation MIME via magic numbers : Apache Tika, jmimemagic, ou validation custom ? | Haute |
| RES-003 | Backend — Stockage | Organisation du stockage des avatars sur disque (property name, structure dossiers, naming) ? | Moyenne |
| RES-004 | Backend — Cache | Stratégie de cache HTTP pour les avatars (ETag, Cache-Control, Last-Modified) ? | Moyenne |
| RES-005 | Backend — Soft-delete | Pattern d'application du filtre soft-delete sur les requêtes (Hibernate `@Filter`, `@Where` global, ou filtre manuel par repo) ? | Haute |
| RES-006 | Backend — Lib export | Lib pour génération CSV (réutilisation) et JSON (streaming vs in-memory) ? | Basse |
| RES-007 | Backend — DTO | Comment garantir que `PUT /users/me` ne permet pas de modifier l'email (sécurité privilege escalation) ? | Haute |
| RES-008 | Backend — Refresh tokens | Stratégie de révocation lors du change-password : méthode existante ? cascade DB ? | Moyenne |
| RES-009 | Backend — Migrations | Numérotation Flyway pour les 4 migrations à introduire | Basse |
| RES-010 | Frontend Angular — UI | Pattern d'upload avatar (composant custom vs lib `ngx-image-cropper`) | Moyenne |
| RES-011 | Frontend Angular — UX | Réutilisation du `ConfirmDialog` existant pour confirmation suppression compte | Basse |
| RES-012 | Frontend Flutter — UI | Stratégie image picker + redimensionnement (côté client vs serveur) | Moyenne |
| RES-013 | Frontend Flutter — Architecture | Mode offline pour la page Mon compte (server-only vs cache Drift partiel) — résout I-005 du review-spec | Moyenne |

---

## Décisions techniques

### RES-001 — Lib de redimensionnement d'image (backend)

- **Contexte** : NFR-006 exige un redimensionnement serveur en 256x256 pixels (sortie JPEG ~85% qualité). Audit : `BufferedImage`, `ImageIO`, `Thumbnailator` ABSENTS du codebase. Aucune lib image présente.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `java.awt.image.BufferedImage` + `javax.imageio.ImageIO` (JDK natif) | Zéro dépendance externe (présent dans le JDK), contrôle fin du processus | API verbeuse (~30 lignes pour un redim simple), gestion manuelle de la qualité JPEG via `ImageWriteParam` | 3/5 |
| B — `net.coobird:thumbnailator:0.4.20` | API fluide (`Thumbnails.of(input).size(256, 256).outputFormat("jpg").outputQuality(0.85).toFile(...)`), gère EXIF rotation auto, taille jar ~150 KB | Une dépendance Maven supplémentaire | **5/5** |
| C — `org.imgscalr:imgscalr-lib` | Léger | API moins fluide que Thumbnailator, gestion EXIF non incluse | 3/5 |
| D — ImageMagick via `im4java` ou subprocess | Très puissant | Dépendance binaire externe (cassage du principe self-hosted simple), risque de configuration sur l'hôte | 1/5 |

- **Décision** : **Option B** — ajouter `net.coobird:thumbnailator:0.4.20` à `pom.xml`.
- **Rationale** :
  - API fluide → moins de code à écrire et tester (~5 lignes vs ~30 pour BufferedImage natif).
  - Gestion EXIF auto-rotation : critique pour les photos prises sur smartphone (sinon les avatars peuvent apparaître à l'envers selon l'orientation EXIF du fichier source).
  - Taille jar (~150 KB) négligeable pour un projet self-hosted.
  - Pas de dépendance binaire externe → conforme constitution principe VII (Self-Hosted Ready).
  - Pattern courant Spring Boot — précédents nombreux dans la communauté.
- **Alternatives rejetées** : A (verbosité + EXIF manuel = risque de bugs sur photos mobile), C (pas de gestion EXIF), D (incompatible self-hosted simple).
- **Impact sur le plan** :
  - Ajouter `thumbnailator` dans `api/pom.xml`.
  - Créer `service/AvatarStorageService` exposant `storeAvatar(User user, MultipartFile file) → String path` et `deleteAvatar(User user)`.
  - Tests unitaires : redim 256x256, output JPEG, qualité ~85%, EXIF auto-rotation, formats input PNG/JPEG.

---

### RES-002 — Validation MIME via magic numbers

- **Contexte** : NFR-002 exige une validation MIME via les magic numbers (pas via l'extension), formats acceptés `image/jpeg` et `image/png`. Audit : Apache Tika et jmimemagic ABSENTS du codebase. Spring Boot inclut un `MediaType` mais pas de détection magic numbers native.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Apache Tika (`org.apache.tika:tika-core` ~600 KB) | Détection MIME exhaustive, standard industrie | Lourd pour 2 formats (JPEG/PNG), parsing toutes signatures | 2/5 |
| B — Validation custom via lecture des premiers octets (signatures JPEG `FF D8 FF` et PNG `89 50 4E 47 0D 0A 1A 0A`) | Zéro dépendance, ~10 lignes, suffisant pour 2 formats | Pas extensible facilement à d'autres formats | **5/5** |
| C — `MultipartFile.getContentType()` (header HTTP) | API standard Spring | Header trivialement falsifiable côté client → ne couvre pas le besoin de sécurité | 1/5 |
| D — `jmimemagic` (lib historique) | Léger | Plus maintenu activement, projet dormant depuis 2014 | 1/5 |

- **Décision** : **Option B** — validation custom des magic numbers en utilitaire dédié.
- **Rationale** :
  - YAGNI (constitution principe III) : on a 2 formats à valider, pas 200. Apache Tika est sur-dimensionné.
  - Validation custom triviale et explicite (signature JPEG `0xFF 0xD8 0xFF`, signature PNG `0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A`).
  - Aucune dépendance externe à ajouter.
  - Lecture des 8 premiers octets via `MultipartFile.getInputStream()` (zéro coût significatif).
- **Alternatives rejetées** : A (over-engineering), C (faille de sécurité), D (lib non maintenue).
- **Impact sur le plan** :
  - Créer `util/ImageMimeValidator` (classe finale, méthode statique `boolean isValidImage(MultipartFile file)`).
  - Test unitaire : fichier JPG valide accepté, PNG valide accepté, GIF rejeté, fichier renommé `.jpg` mais avec contenu PDF rejeté, fichier vide rejeté.
  - Utilisé en amont dans `AvatarController.uploadAvatar` ; échec → `400 Bad Request` payload `{ error: "INVALID_IMAGE_FORMAT" }`.

---

### RES-003 — Organisation du stockage des avatars sur disque

- **Contexte** : NFR-008 exige un stockage disque local avec chemin configurable. Audit : aucune property "chemin disque" existante. Pattern config existant : préfixe `app.*` (ex: `BootstrapProperties` avec `app.bootstrap.*`).
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Property `app.storage.avatars.path`, structure plate `{path}/{user_id}.jpg` | Simple, lookup direct par `user_id` | Conflit potentiel si on extend à d'autres types de fichiers (`avatars` reste explicite) | **4/5** |
| B — Property `app.storage.path`, structure `{path}/avatars/{user_id}.jpg` | Centralise tout le stockage future-proof | Anticipation de besoins non confirmés (constitution principe III YAGNI) | 3/5 |
| C — Stockage en bytea PostgreSQL | Aucune gestion de filesystem | Bloat DB (chaque requête user charge potentiellement 50 KB), backups DB plus lourds, pattern non standard | 1/5 |

- **Décision** : **Option A** — property `app.storage.avatars.path` (default `./data/avatars` en dev, `/var/k-budget/avatars` en prod via env var). Naming : `{user_id}.jpg` (extension fixe car output toujours JPEG après redim).
- **Rationale** :
  - Extension fixe `.jpg` cohérente avec le redim qui produit toujours du JPEG (RES-001 décision Thumbnailator).
  - `user_id` = clé unique → pas de collision possible, lookup O(1).
  - Préfixe `app.storage.avatars.*` permet d'ajouter futur `app.storage.exports.*` sans refactor.
  - Default pratique en dev (`./data/avatars` relatif au CWD), surchargé en prod par env var.
- **Alternatives rejetées** : B (anticipation prématurée), C (anti-pattern stockage fichiers en DB pour ce volume).
- **Impact sur le plan** :
  - `application.yaml` : `app.storage.avatars.path: ${AVATAR_STORAGE_PATH:./data/avatars}`.
  - Créer `config/StorageProperties` `@ConfigurationProperties(prefix = "app.storage")` avec sous-record `Avatars(String path)`.
  - `AvatarStorageService` : utilise `Path.of(properties.avatars().path()).resolve(userId + ".jpg")`.
  - Création automatique du dossier au démarrage si absent.
  - Documentation `docs/deployment.md` : ajouter mention de la variable d'env `AVATAR_STORAGE_PATH` et conseils de backup.
  - **Résout I-003 du review-spec**.

---

### RES-004 — Stratégie de cache HTTP pour les avatars

- **Contexte** : FR-005 mentionne "en-têtes de cache appropriés" sans spec précise (I-002 du review-spec). Trois stratégies courantes : `Cache-Control: max-age`, `ETag`, `Last-Modified`. Choix doit être cohérent côté Angular ET Flutter pour invalidation après upload/delete.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `Cache-Control: private, max-age=86400` (24h) seul | Simple, allègent les requêtes pendant 24h | Après upload, pas d'invalidation immédiate (le client garde l'ancien avatar 24h) | 2/5 |
| B — `ETag` basé sur le hash SHA-256 du fichier + `Cache-Control: private, must-revalidate` | Invalidation immédiate à chaque upload (hash change → ETag change → 200 ; sinon 304) | Coût CPU négligeable (hash à chaque requête, mais image petite ~50 KB) | **5/5** |
| C — Versionning dans l'URL `/users/me/avatar?v={timestamp}` | Pas de calcul ETag serveur | Pollue le client avec un state de version à gérer côté Angular/Flutter | 3/5 |
| D — `Last-Modified` basé sur le mtime du fichier disque | Standard HTTP | Précision à la seconde insuffisante (deux uploads dans la même seconde indistinguables, rare mais possible) | 3/5 |

- **Décision** : **Option B** — `ETag` basé sur le hash SHA-256 (8 premiers chars) du fichier + `Cache-Control: private, must-revalidate, max-age=0`.
- **Rationale** :
  - Invalidation immédiate après upload : le hash change, l'ETag change, les clients récupèrent automatiquement la nouvelle version.
  - Header `Cache-Control: must-revalidate, max-age=0` force le client à revalider à chaque requête (avec `If-None-Match`), Spring Boot répond 304 si l'ETag matche → pas de retransmission de bytes.
  - Coût CPU SHA-256 sur ~50 KB : <1 ms, négligeable.
  - Stratégie identique côté Angular et Flutter (les deux clients utilisent les standards HTTP) → pas de divergence d'implémentation.
- **Alternatives rejetées** : A (invalidation trop lente), C (pollution client), D (précision insuffisante).
- **Impact sur le plan** :
  - `AvatarController.getAvatar` : calcul ETag (`DigestUtils` Spring déjà disponible via `org.springframework.util.DigestUtils.md5DigestAsHex` — ou utiliser `MessageDigest` JDK pour SHA-256), comparaison `If-None-Match`, retour `304 Not Modified` si match.
  - Réponse `200 OK` avec `Content-Type: image/jpeg`, `Cache-Control: private, must-revalidate, max-age=0`, `ETag: "<hash>"`.
  - Tests d'intégration : premier GET → 200 + ETag, deuxième GET avec `If-None-Match` → 304, après upload → ETag différent → 200.
  - **Résout I-002 du review-spec**.

---

### RES-005 — Pattern d'application du filtre soft-delete

- **Contexte** : FR-019 et FR-020 imposent un filtrage `WHERE disabled_at IS NULL` à tous les `findByEmail` et autres lookups d'authentification. Audit : champ `disabled_at` déjà présent sur `User` (migration V29) mais pas de pattern soft-delete uniformisé. Pas de `@SQLDelete`, `@Where`, `@Filter` Hibernate dans le projet.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `@SQLRestriction("disabled_at IS NULL")` Hibernate sur `User` (succède à `@Where` déprécié en Hibernate 6+) | Filtrage automatique sur TOUTES les requêtes JPA — y compris `findById`, `findAll`, jointures | Effet "global" : impossible d'oublier un filtre. **MAIS** : le bootstrap admin (KKS-233) et l'admin user management ont besoin d'accéder aux users disabled (audit, restauration). Nécessite des accès non-filtrés via repository custom + `@Subselect` ou requêtes natives | 3/5 |
| B — Filtrage explicite dans les méthodes de `UserRepository` concernées (`findByEmailAndDisabledAtIsNull`) + nouveaux noms de méthode pour les cas où on veut accéder à TOUS les users | Contrôle explicite, pas d'effet de bord | Risque d'oubli sur de nouveaux endpoints (un dev ajoute `findByEmail` sans suffixe et bypass le filtre) | 3/5 |
| C — `@Filter` Hibernate paramétré (activé/désactivé par session via `Session.enableFilter`) | Granulaire | Complexifie le code (chaque service doit penser à activer/désactiver le filter). Pas de précédent projet | 2/5 |
| D — Hybride : `@SQLRestriction` sur `User` POUR les requêtes courantes + méthodes annotées `@Query("... ignoring filter ...")` pour les cas admin | Sécurité par défaut + contrôle explicite quand nécessaire | Hibernate `@SQLRestriction` ne permet pas de bypass per-query natif → nécessite requêtes natives ou repository alternatif | 3/5 |
| E — Filtrage dans `AuthService.login` et `JwtFilter` uniquement (les seuls flow critiques) + reset des refresh tokens à la suppression | Minimaliste, alignement YAGNI | N'empêche pas un futur endpoint de retrouver un user disabled si pas codé prudemment ; l'isolation user disabled n'est pas systémique | **4/5** |

- **Décision** : **Option E** — filtrage explicite dans les 2 flows critiques (`AuthService.login` et `JwtFilter.doFilterInternal`) + révocation des refresh tokens à la suppression. Une assumption documente que **tous les endpoints protégés transitent par `JwtFilter`** : si le filter rejette le user disabled (lookup `findByEmailAndDisabledAtIsNull`), aucun endpoint protégé ne peut servir un user disabled.
- **Rationale** :
  - YAGNI strict (constitution principe III) : pas d'introduction d'un mécanisme global Hibernate pour 2 flows à protéger.
  - Architecture en couches simples (constitution principe III) : Controller → Service → Repository sans filter Hibernate caché.
  - Isolation systémique garantie par le `JwtFilter` qui est l'unique porte d'entrée de tous les endpoints protégés.
  - Le `BootstrapSeedRunner` et les futurs use cases admin (consulter / restaurer un user disabled) accèdent simplement au repo standard sans contournement à coder.
  - Coût d'oubli minimisé : seulement 2 callsites à protéger (login + filter JWT), pas N endpoints.
- **Alternatives rejetées** : A (effet de bord trop fort, complique bootstrap/admin), B (risque d'oubli sur nouveaux flows), C (aucun précédent projet), D (complexité injustifiée).
- **Impact sur le plan** :
  - Ajouter `Optional<User> findByEmailAndDisabledAtIsNull(String email)` dans `UserRepository`.
  - Modifier `AuthService.login` pour utiliser cette méthode.
  - Modifier `JwtFilter.doFilterInternal` pour utiliser cette méthode.
  - Ajouter méthode `softDelete(User user)` sur `UserService` qui : (a) set `disabled_at = now()`, (b) appelle `refreshTokenService.revokeAllUserTokens(user)` pour invalider les refresh tokens.
  - Test d'intégration : tentative de login après soft-delete → 401, requête authentifiée avec JWT pré-soft-delete → 401 (le filter rejette).

---

### RES-006 — Lib pour génération CSV et JSON

- **Contexte** : FR-014 et FR-015 imposent l'export en JSON et CSV. Audit : Apache Commons CSV 1.11.0 déjà présent (utilisé par `CsvParsingService` pour l'import KKS-099). Jackson présent (Spring Boot starter web).
- **Décision** : **Réutilisation directe**, pas d'option à débattre.
  - **CSV** : Apache Commons CSV `CSVPrinter` avec format `RFC4180`. Encodage UTF-8 avec BOM (`﻿` au début du writer). Streaming via `OutputStreamWriter`.
  - **JSON** : Jackson `ObjectMapper` standard (déjà configuré dans le projet pour la sérialisation REST). Streaming via `JsonGenerator` si nécessaire pour gros datasets, sinon sérialisation in-memory standard.
- **Rationale** :
  - Pas de nouvelle dépendance Maven (cohérence stack).
  - Apache Commons CSV `CSVPrinter` supporte nativement RFC 4180 (échappement guillemets, virgules, sauts de ligne).
  - Pour 16 users avec quelques milliers de transactions max : in-memory in-stream suffisant. Streaming `JsonGenerator` introduit une complexité non justifiée pour ces volumes (NFR-004 fixe 10 000 transactions max → ~3-5 MB JSON, gérable in-memory).
- **Impact sur le plan** :
  - Créer `service/UserExportService` avec deux méthodes : `exportJson(User user) → JsonNode/Map` et `exportCsv(User user, OutputStream) → void`.
  - Pas de nouvelle dépendance.
  - Pour la décision "incluure ou non `invitations`" (I-004 du review-spec) : voir RES-007 ci-dessous (DTO export = liste explicite des entités, à valider en plan).

---

### RES-007 — Garantir l'immutabilité de l'email côté DTO `PUT /users/me`

- **Contexte** : I-001 du review-spec a soulevé le risque qu'un futur dev étende le DTO `UpdateUserRequest` pour y inclure l'email, ce qui ouvrirait la faille de privilege escalation identifiée au sparring (audit bootstrap admin). Comment empêcher structurellement cette extension ?
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Garder le DTO `UpdateUserRequest` actuel (champ `name` only), ajouter un commentaire "Ne pas ajouter `email` ici, voir KKS-235 §FR-007" | Simple, code minimal | Documentation seule = pas de garde-fou structurel | 2/5 |
| B — Renommer le DTO en `UpdateProfileRequest` (intent explicite "profil = ce que le user peut éditer lui-même") + commentaire de garde | Intent codé dans le nom du DTO, plus difficile à étendre par mégarde | Refactor (renommage) | **5/5** |
| C — Créer un DTO admin séparé `AdminUpdateUserRequest` qui contient l'email, et garder `UpdateProfileRequest` pour le user. L'endpoint admin gère email | Séparation explicite des permissions au niveau DTO | Complexifie pour un besoin futur (pas d'endpoint admin de modification d'email actuellement) | 3/5 |

- **Décision** : **Option B** — renommer `UpdateUserRequest` en `UpdateProfileRequest` + commentaire `// Self-service profile fields ONLY. Email is admin-managed (cf. KKS-235 §FR-007). Do not add fields that require admin authorization.`.
- **Rationale** :
  - Intent codé dans le nom : un dev qui voit `UpdateProfileRequest` comprend instinctivement que c'est self-service.
  - Refactor minimal (renommage de 1 classe + 2-3 callsites).
  - Conforme constitution principe III (simplicité) : pas de DTO admin spéculatif.
- **Alternatives rejetées** : A (pas de garde-fou structurel), C (anticipation prématurée).
- **Impact sur le plan** :
  - Renommer `dto/request/UpdateUserRequest.java` → `UpdateProfileRequest.java`.
  - Mettre à jour les callsites (UserController, UserService).
  - Ajouter le commentaire de garde dans le fichier renommé.
  - Mettre à jour la doc `docs/api-examples.md` (PUT /users/me).
  - **Résout I-001 du review-spec**.

---

### RES-008 — Stratégie de révocation des refresh tokens au change-password

- **Contexte** : FR-023 exige la révocation immédiate de tous les refresh tokens du user. Audit : `RefreshTokenService.revokeAllUserTokens(User user)` **existe déjà** (utilisé pour le logout massif). Le pattern est en place.
- **Décision** : **Réutilisation directe** de `RefreshTokenService.revokeAllUserTokens(User)`.
- **Rationale** :
  - Aucun nouveau code à écrire — méthode déjà testée et utilisée.
  - Cohérence avec patterns existants.
- **Impact sur le plan** :
  - `UserPasswordService.changePassword()` (nouveau service ou méthode dans `UserService`) :
    1. Vérifier `currentPassword` via `BCryptPasswordEncoder.matches`.
    2. Vérifier que `newPassword != currentPassword` (BCrypt matches sur `newPassword` plaintext et `user.password` hash).
    3. Hasher le nouveau MDP, persister.
    4. Appeler `refreshTokenService.revokeAllUserTokens(user)`.
    5. Générer nouveau JWT + nouveau refresh token pour le device courant.
    6. Renvoyer `AuthResponse` (DTO existant) avec les nouveaux tokens.
  - Décision additionnelle : Cascade JPA sur `User → RefreshToken` ABSENTE actuellement (audit). À AJOUTER dans la migration V32 (cf. RES-009) avec `ON DELETE CASCADE` côté DB pour cohérence avec le soft-delete (si jamais un hard-delete est ajouté plus tard).

---

### RES-009 — Numérotation Flyway

- **Contexte** : Dernière migration : `V31__add_user_password_reset_required.sql`. 4 migrations à introduire pour KKS-235 (cf. spec MIG-001 à MIG-004) + 1 sur cascade `User → RefreshToken` (RES-008).
- **Décision** : Numérotation séquentielle V32 → V35 :

| Fichier | Contenu |
|---|---|
| `V32__add_user_avatar_path.sql` | `ALTER TABLE users ADD COLUMN avatar_path VARCHAR(512) NULL;` |
| `V33__patch_budgets_user_fk_cascade.sql` | Drop + recreate FK `budgets.user_id` avec `ON DELETE CASCADE` |
| `V34__patch_budget_snapshots_user_fk_cascade.sql` | Drop + recreate FK `budget_snapshots.user_id` avec `ON DELETE CASCADE` |
| `V35__patch_refresh_tokens_user_fk_cascade.sql` | Vérifier ou ajouter `ON DELETE CASCADE` sur `refresh_tokens.user_id` (RES-008) |

- **Rationale** :
  - Une migration = un changement atomique (rollback indépendant).
  - **Note importante** : `users.disabled_at` (MIG-001 spec) déjà appliqué via V29 (audit RES-005). **MIG-001 disparaît du plan** — la migration existe déjà.
- **Impact sur le plan** :
  - Réviser la liste des migrations dans le plan : 4 (et non 5) car V29 couvre déjà `disabled_at`.
  - Ajouter V35 (cascade refresh tokens) — non listée dans la spec mais découverte audit RES-008.

---

### RES-010 — Pattern d'upload avatar côté Angular

- **Contexte** : Audit : aucune lib UI upload côté Angular (`ngx-image-cropper`, `ngx-dropzone` ABSENTS). Ne pas introduire de lib lourde pour un seul écran.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Composant custom `<app-avatar-upload>` avec `<input type="file" accept="image/jpeg,image/png">` caché + click sur l'avatar = trigger input. Affichage preview avant upload via `URL.createObjectURL`. | Zéro dépendance, ~50 lignes de code, pleine maîtrise du style | Pas de crop côté client (le redim se fait côté serveur en 256x256, donc pas de besoin de crop UI) | **5/5** |
| B — `ngx-image-cropper` | Crop côté client | Ajoute une dépendance npm, complexité injustifiée (le serveur gère le redim) | 2/5 |

- **Décision** : **Option A** — composant standalone `app-avatar-upload` dans `lib/` (composant réutilisable du projet — cf. CLAUDE.md "Lib-first").
- **Rationale** :
  - Pas de crop côté client → pas besoin de lib (le serveur fait du redim 256x256 simple, pas de crop interactif).
  - Approche signals-first (constitution Angular) : `signal()` pour l'état (uploading, error), `output()` pour l'événement upload réussi.
- **Alternatives rejetées** : B (over-engineering pour ce besoin).
- **Impact sur le plan** :
  - Créer `lib/avatar-upload/avatar-upload.component.ts` (standalone, OnPush, signals-first).
  - Inputs : `currentAvatarUrl: InputSignal<string | null>`, `userInitials: InputSignal<string>`.
  - Outputs : `upload: OutputEmitterRef<File>`, `delete: OutputEmitterRef<void>`.
  - State interne : `isUploading: WritableSignal<boolean>`, `error: WritableSignal<string | null>`.
  - Tests unitaires : trigger input, validation taille (>2 MB rejeté côté client avec message), validation extension (autres que JPG/PNG rejetés côté client).

---

### RES-011 — Réutilisation `ConfirmDialog` existant pour confirmation suppression

- **Contexte** : Audit : `ConfirmDialog` custom existant dans `app/src/app/shared/components/confirm-dialog/` avec `ConfirmService` réutilisable. Pattern `CdkTrapFocus` déjà en place.
- **Décision** : **Réutilisation directe** + extension si nécessaire.
- **Rationale** :
  - Un seul pattern de modale dans l'app = cohérence UX.
  - L'existant gère le focus trap (a11y) et le pattern signal `isOpen()`.
- **Impact sur le plan** :
  - Vérifier que `ConfirmDialog` accepte un slot pour saisie utilisateur (mot de passe + checkbox). Si non, étendre le composant ou créer une variante `ConfirmDeleteAccountDialog` qui inline le password input + checkbox.
  - Hypothèse à confirmer en plan : extension probable car le dialog actuel est pensé pour confirmation simple (yes/no) — la suppression de compte demande input MDP + checkbox. Pattern recommandé : un composant dédié `DeleteAccountConfirmDialog` qui réutilise les primitives (CdkTrapFocus, overlay) du `ConfirmDialog` mais avec un contenu spécifique.

---

### RES-012 — Image picker Flutter et redimensionnement

- **Contexte** : Audit : `image_picker: ^1.1.2` déjà présent dans `pubspec.yaml`, déjà utilisé dans `account_form_screen.dart`. `image_cropper` et `flutter_image_compress` ABSENTS.
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `image_picker` seul + envoi du fichier brut au backend (qui redim) | Zéro dépendance supplémentaire, redim serveur fait foi | Upload potentiel de gros fichiers (photo HD smartphone ~3-5 MB > limite 2 MB) → erreur 400 côté serveur, mauvaise UX | 3/5 |
| B — `image_picker` + `flutter_image_compress` pour pré-compresser côté client à <2 MB avant upload | Évite les rejets côté serveur, respecte la limite 2 MB en transit | Une dépendance pubspec.yaml supplémentaire (~ish 2 MB) | **5/5** |
| C — `image_picker` avec `imageQuality: 70` paramètre natif | Compression intégrée à image_picker, zéro dépendance supplémentaire | Compression de qualité variable selon plateforme (iOS vs Android ne donnent pas les mêmes résultats), pas de garantie de taille finale | 3/5 |

- **Décision** : **Option B** — ajouter `flutter_image_compress` pour pré-compresser à <2 MB.
- **Rationale** :
  - Mobile-first (constitution principe IV) : un user ne veut pas voir "Erreur upload" parce que sa photo fait 4 MB. Pré-compression côté client = UX fluide.
  - Limite 2 MB en transit respectée systématiquement.
  - Le serveur redim quand même en 256x256 (RES-001) pour stockage final → la pré-compression côté client est une simple optimisation transport.
- **Alternatives rejetées** : A (UX dégradée sur photos HD), C (qualité non déterministe selon plateforme).
- **Impact sur le plan** :
  - Ajouter `flutter_image_compress: ^2.x` dans `pubspec.yaml`.
  - Créer `lib/src/features/user_profile/presentation/widgets/avatar_picker.dart`.
  - Flow : `image_picker` → `flutter_image_compress` (target ~1.5 MB max, sécurité < 2 MB serveur) → upload via Dio.
  - Tests widget : sélection image, compression, upload.

---

### RES-013 — Mode offline pour la page Mon compte côté Flutter

- **Contexte** : I-005 du review-spec a soulevé la question de la conformité au principe IV (offline-when-possible) pour cette page. Audit : `dataModeProvider` permet de basculer entre `RepositoryLocal` (Drift) et `RepositoryRemote` (Dio). Précédents server-only existent : `exchangeRateRepositoryProvider`, `notificationRepositoryProvider` (FutureProvider sans cache local).
- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Page Mon compte = server-only (pas de cache Drift), comme `exchangeRateRepository` | Cohérent avec l'exception constitution principe IV (données sensibles devant être fraîches), déjà précédent dans le projet | Le user offline ne voit RIEN sur la page Mon compte | 4/5 |
| B — Cache Drift partiel : nom et avatar URL en cache local (lecture offline OK), mais toutes les actions (change MDP, export, suppression) en server-only | Lecture offline du profil possible | Complexité accrue pour peu de valeur (qui consulte son profil offline ?) | 2/5 |
| C — Tout en server-only ET afficher un état offline dégradé (skeleton + message "Connexion requise pour la page Mon compte") | UX claire en cas d'offline | UX dégradée mais explicite | **5/5** |

- **Décision** : **Option C** — mode server-only avec état offline explicite.
- **Rationale** :
  - Toutes les actions de cette page (changement MDP, export, suppression) sont intrinsèquement online — pas de sens d'avoir un cache offline pour des actions qui ne peuvent pas s'exécuter offline.
  - Constitution principe IV autorise explicitement l'exception "données devant être fraîches" pour les features comme préférences/comptes — le compte utilisateur tombe naturellement dans cette catégorie.
  - UX claire : afficher un état offline plutôt que des données potentiellement désynchronisées (ex: l'avatar local n'est plus à jour si modifié sur un autre device).
  - Précédent projet : `exchangeRateRepositoryProvider` est déjà server-only.
- **Alternatives rejetées** : A (UX trop abrupte sans message), B (over-engineering).
- **Impact sur le plan** :
  - Documenter dans `Assumptions` (`A-008` à ajouter en plan) : "La page Mon compte est server-only côté Flutter — pas de cache Drift local. Le user offline voit un état dégradé avec message 'Connexion requise'."
  - Repository `UserProfileRepository` : implémentation `Remote` uniquement (pas de `Local`).
  - Provider `userProfileProvider` : `FutureProvider` sans branchement `dataMode`.
  - UI : widget `_OfflineState` quand `connectivity` indique offline.
  - **Résout I-005 du review-spec**.

---

## Synthèse

- **Inconnues identifiées** : 13 (RES-001 à RES-013)
- **Décisions prises en research** : 13/13
- **Nouvelles dépendances externes** :
  - **Backend** : `net.coobird:thumbnailator:0.4.20` (RES-001)
  - **Flutter** : `flutter_image_compress: ^2.x` (RES-012)
  - **Angular** : aucune
- **Dépendances réutilisées (pas de nouvelle)** :
  - Apache Commons CSV 1.11.0 (export CSV — RES-006)
  - Jackson (export JSON — RES-006)
  - BCryptPasswordEncoder (change password — déjà mentionné en sparring)
  - `RefreshTokenService.revokeAllUserTokens` (révocation tokens — RES-008)
  - `image_picker` Flutter (RES-012)
  - `ConfirmDialog` Angular (RES-011)
- **Patterns introduits dans le projet** :
  - Stockage fichiers disque local avec `@ConfigurationProperties` `app.storage.avatars.*` (RES-003)
  - Validation MIME custom via magic numbers (RES-002) — premier usage projet
  - `ETag` HTTP avec hash SHA-256 (RES-004) — premier usage projet
- **Patterns refusés (YAGNI)** :
  - Apache Tika (RES-002) — over-engineering
  - Hibernate `@SQLRestriction` global (RES-005) — effet de bord trop fort
  - `ngx-image-cropper` Angular (RES-010) — pas besoin de crop client
- **Items du review-spec résolus en research** :
  - **I-001** (DTO `PUT /users/me` strict) — résolu par RES-007 (renommage en `UpdateProfileRequest`)
  - **I-002** (stratégie cache HTTP avatar) — résolu par RES-004 (ETag SHA-256)
  - **I-003** (property name stockage) — résolu par RES-003 (`app.storage.avatars.path`)
  - **I-005** (mode offline page Mon compte Flutter) — résolu par RES-013 (server-only + état offline explicite)
- **Items du review-spec à traiter en plan** :
  - **W-001** (assumption FK CASCADE budgets/budget_snapshots) — à documenter dans Assumptions du plan
  - **W-002** (SC manquant pour nouveau JWT post-change-password) — à ajouter dans le plan
  - **W-003** (SC manquant pour perf export JSON) — à ajouter dans le plan
  - **W-004** (scénario "admin non-seul peut se supprimer") — à ajouter dans le plan
  - **W-005** (SC-004 perf avatar séparé en deux SC) — à ajouter dans le plan
  - **I-004** (inclusion ou non de `invitations` dans export JSON) — à trancher en plan
- **Découverte audit non listée dans la spec** :
  - **MIG-001 supprimée** : `users.disabled_at` déjà ajouté en V29 (lors d'un précédent travail). La spec annonçait 4 migrations, en réalité 4 nouvelles (V32 à V35) avec une migration en plus (V35 cascade refresh tokens).
  - **Cascade `User → RefreshToken`** absente — à ajouter en V35 pour cohérence (RES-008).

---

## Notes

- **Stack confirmée** : Spring Boot 4.0.2, Java 21, Angular 21.1.0, Flutter avec Riverpod et go_router.
- **Conformité constitution** : toutes les décisions respectent les 7 principes (notamment principe III YAGNI sur le rejet de Hibernate filters globaux et lib image lourde, principe VII Self-Hosted Ready sur le rejet d'ImageMagick).
- **Aucun rouge** : aucune décision technique ne nécessite un amendement de la constitution ou un Q-DIFF à reporter en plan.
