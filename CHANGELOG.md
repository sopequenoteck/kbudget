# Changelog

Basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
Ce projet suit [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

## [5.3.0] - 2026-08-26

> Release documentaire — aucun changement de code applicatif. Acte le changement de direction du projet.

### Added

- **`docs/direction.md`** : document de direction produit. k-budget s'ouvre en open source à destination de la communauté self-hosted, avec une différenciation assumée sur la zone francophone (France et Afrique de l'Ouest). Le document conserve les huit décisions structurantes, les alternatives écartées et leurs motifs, le séquencement en huit jalons, les risques et les questions laissées ouvertes.

### Changed

- **Constitution v3.0.0 → v4.0.0** (MAJOR) : suppression de la bifurcation des trajectoires de distribution. Il n'existe plus qu'une trajectoire — self-host, tous les clients consommant la même API.
  - *Principe I* : « API-First / Local-First » redevient « API-First ». L'API est la source de vérité unique ; aucun client ne détient de source de vérité propre. Ajout du contrat de version : une seule version d'API servie à la fois, découverte des capacités par le client, et trois règles de compatibilité descendante.
  - *Principe VII* : « Two Distribution Trajectories » devient « Self-Hosted & Distribution ouverte ». Licences AGPL-3.0 (`api/`, `app/`) et MPL-2.0 (`flutter/`), règle de non-bridage des builds compilés par des tiers, politique de langues (anglais par défaut, français à parité).
  - *Principe VIII* (nouveau) : Angular est le client de référence. Flutter n'a jamais d'obligation de parité — frontière à trois états, Suivi / Gelé / Jamais.
  - Suppression du Contexte B (Standalone Commercial) et des règles propres au mode autonome Flutter.
- **`CLAUDE.md`** : mise en cohérence avec la constitution v4.0.0 (8 principes au lieu de 7) et référencement de `docs/direction.md`.

## [5.2.1] - 2026-08-25

### Fixed

- **Nettoyage qualité (Sonar)** : constante `INVALID_REQUEST_MESSAGE` remplaçant 4 littéraux dupliqués dans `GlobalExceptionHandler`, remplacement de `HttpStatus.UNPROCESSABLE_ENTITY` (déprécié Spring Framework 7.0) par `UNPROCESSABLE_CONTENT` (même code HTTP 422), imports inutilisés retirés dans 2 tests, `throws Exception` inutile et lambda simplifiés dans `UserDeletionConcurrencyIT`.

## [5.2.0] - 2026-08-25

### Added

- **Contrat unifié des erreurs API** : `GlobalExceptionHandler` retourne pour toute erreur gérée un objet unique `{ error, message }`, remplaçant l'ancien format `{ timestamp, status, message }` et le format hybride des conflits. Les erreurs de validation exposent désormais un détail structuré par champ (`ValidationErrorDetail`). Voir `docs/api-errors.md`.

### Fixed

- **Suppression atomique du dernier administrateur** : verrou transactionnel (`ActiveAdminInvariantLock`, `pg_advisory_xact_lock`) empêchant deux suppressions de compte concurrentes de désactiver simultanément tous les administrateurs actifs. La suppression refusée reste sans effet persistant (403 `LAST_ADMIN_DELETION_FORBIDDEN`), la suppression acceptée conserve la désactivation du compte et la révocation de ses refresh tokens. Tests d'intégration concurrents `UserDeletionConcurrencyIT` et `UserDeletionRollbackIT`.
- **Nginx bank-logos** : test de non-régression Vitest (`nginx.conf.spec.ts`) garantissant que `/api/bank-logos/*.svg` reste prioritaire sur la regex SVG générique et que `proxy_pass` pointe vers `http://api:8080/api/`.

## [5.0.5] - 2026-06-14

> Release de maintenance — infrastructure CI/CD. Pas de changement fonctionnel. (Les versions 5.0.3 et 5.0.4 ont été préparées mais jamais publiées : le gate de release a correctement bloqué la livraison sur des tests rouges ; les correctifs sont regroupés ici.)

### Changed

- **Release gatée par les tests** : `release.yml` exécute les tests API (`mvn clean verify`, H2, sur runner GitHub) et APP (`npm run test:coverage`, sur runner self-hosted) avant de construire et publier les images Docker. Si un test échoue, aucune image n'est poussée ni taguée — la prod ne reçoit jamais de code dont les tests échouent. Seul gate dur possible sans branch protection (repo privé, plan GitHub free). Les tests Flutter ne sont pas dans le gate (pas d'image Docker Flutter).
- **Gate APP sur runner self-hosted** : le job `test-app` tourne sur `[self-hosted, kbudget-ci]` (et non `ubuntu-latest`) car l'isolation TestBed vitest est instable à faible nombre de cœurs (cf. DT-006). C'est un contournement en attendant la correction de fond de DT-006.
- **Test de perf API robuste** : `TransactionRepositoryTest` ne mesure plus un temps absolu (« < 100 ms ») mais un **ratio de scaling** T(10k)/T(1k) avec warm-up JIT — détecte une régression algorithmique (N+1, scan quadratique) sans dépendre de la vitesse de la machine. Méthode renommée `should_scale_sublinearly_on_large_transaction_volume`.

### Fixed

- **Tests APP** : correction des timeouts de `recurring-list.spec.ts` et des fuites réseau undici de `transaction-form.spec.ts` (providers manquants dans le TestBed). Suite APP : 475/475.

> Note : les versions 5.0.1 à 5.0.4 ont été taguées ou préparées sans publication ; voir DT-006 pour la dette d'isolation des tests APP restante.

## [5.0.0] - 2026-05-03

> Release MAJOR — 3 BREAKING changes : suppression du module shop, refonte de l'onboarding (KKS-232), refacto architecture admin (KKS-233). Inclut également les features non-breaking KKS-234 (refonte design pages auth) et KKS-235 (page Mon compte).

### Added — KKS-234 Refonte design pages auth

- **Shell auth `<app-auth-shell>`** factorisé pour les 3 pages d'authentification (`login`, `accept-invite`, `first-login-reset`) — bloc identité commun, sections homogènes, icônes prefix dans les inputs. Suppression du code SCSS dupliqué entre les 3 pages, normalisation de l'arborescence `features/auth/pages/first-login-reset/`.
- Le shell auth aligne le rendu des 3 pages sur les patterns réels de l'app (tokens DESIGN.md, hiérarchie typographique, espacements `--space-*`) et améliore la cohérence visuelle de l'expérience d'onboarding/connexion.

### Added — KKS-235 Page Mon compte

- **Page Mon compte** (`/settings/account` Angular, `/settings/profile` Flutter) — 4 sections : Identité (avatar uploadable JPG/PNG ≤ 2 MB, nom éditable, email read-only), Sécurité (changement MDP — min 12 chars, révocation refresh tokens + nouveau JWT device courant), Données (export JSON full backup + CSV transactions UTF-8 BOM), Zone de danger (déconnexion + suppression soft-delete avec garde dernier admin actif).
- **Avatars** : stockés sur disque local (`AVATAR_STORAGE_PATH`, défaut `./data/avatars`), validation MIME via magic numbers (JPEG `FF D8 FF` / PNG `89 50 4E 47…`), redimensionnés en 256×256 JPEG 85% via Thumbnailator avec gestion EXIF auto-rotation, servis avec ETag SHA-256 + `Cache-Control: must-revalidate`. Affichés dans le header, le hub Settings et la page Mon compte (binding réactif via `AvatarService.avatarUrl` signal + blob URL).
- **Politique MDP** harmonisée à 12 caractères dans tous les flows (`ChangePasswordRequest` + `FirstLoginResetRequest`).
- **Soft-delete user** : `users.disabled_at` (V29 préexistant), `AuthService.login` + `JwtFilter` + `StompAuthInterceptor` filtrent `disabled_at IS NULL`. Suppression de compte via `DELETE /api/users/me` avec confirmation MDP + checkbox.
- **Endpoints REST** : `PUT /users/me`, `POST/GET/DELETE /users/me/avatar`, `POST /users/me/password`, `GET /users/me/export?format=json|csv`, `DELETE /users/me`.
- **Codes d'erreur** : `INVALID_IMAGE_FORMAT` (400), `FILE_TOO_LARGE` (413), `AVATAR_NOT_FOUND` (404), `PASSWORD_INCORRECT` (401), `PASSWORD_UNCHANGED` (400), `CONFIRMATION_REQUIRED` (400), `LAST_ADMIN_DELETION_FORBIDDEN` (403), `INVALID_EXPORT_FORMAT` (400). Voir `docs/api-errors.md`.
- **Migrations Flyway** : V32 (`users.avatar_path VARCHAR(512)`), V33/V34 (patches FK `budgets.user_id` + `budget_snapshots.user_id` → `ON DELETE CASCADE`, filet de sécurité), V35 (no-op documentaire — `refresh_tokens.user_id` avait déjà CASCADE depuis V6).
- **Dépendances** : `net.coobird:thumbnailator:0.4.20` (backend Maven, redimensionnement + EXIF), `flutter_image_compress:^2.3.0` (Flutter, pré-compression client avant upload).
- **DTOs** : `UpdateProfileRequest` (renommage de `UpdateUserRequest`, anti privilege escalation — pas de champ email), `ChangePasswordRequest`, `DeleteAccountRequest`, `AvatarMetadataResponse`, `UserExportResponse` (record top-level + 13 sub-records, `password` JAMAIS sérialisé).
- **Documentation** : `docs/api-examples.md`, `docs/api-errors.md`, `docs/deployment.md` (variable `AVATAR_STORAGE_PATH` + procédure backup avatars), `docs/manual-test-plan.md` (section 22, 31 scénarios MC-1 à MC-31).

### Fixed — KKS-235

- **Bouton Déconnexion** sur la page Settings Angular : n'avait aucun handler (bug introduit en phase design KKS-234). Branché sur `authService.logout()` avec résilience en cas d'échec backend.
- **Export CSV** : `HttpMessageNotWritableException: No converter for [...Lambda...] with preset Content-Type 'text/csv'`. `ResponseEntity<?>` + `StreamingResponseBody` ne fonctionne pas — Spring tente de sérialiser la lambda comme un objet. Résolu en séparant en 2 endpoints typés (`params="format=json"` retournant `ResponseEntity<UserExportResponse>` et `params="format=csv"` retournant `ResponseEntity<StreamingResponseBody>`).
- **Avatar 401 sur `<img src>`** : le navigateur ne transmet pas le header `Authorization` JWT sur les requêtes déclenchées par `<img src>`. Résolu en chargeant le binaire via `HttpClient` (interceptor JWT actif) + `URL.createObjectURL(blob)` puis bind sur `<img [src]="blobUrl">`. Gestion du cycle de vie (`URL.revokeObjectURL`) avant chaque rechargement et au delete.
- **Lint Angular** : 2 erreurs `no-unused-vars` préexistantes dans `first-login-reset.spec.ts` (héritées de KKS-233) — corrigées en passant.

### Added
- **KKS-233 Bootstrap du premier admin sur DB vide** — sur instance vierge (`users.count() == 0`), au premier boot Spring post-Flyway, création automatique d'un compte admin seed avec password aléatoire 32 chars (`SecureRandom`, alphanumérique) affiché dans les logs WARN avec bannière encadrée. L'utilisateur est forcé de changer ses credentials via un écran Angular `/first-login-reset` avant tout autre accès. Pattern inspiré de Jenkins `initialAdminPassword` / GitLab `root_password`. Conformité constitution v2.1.2 principe VII "Self-Hosted Ready" (zero config, `docker compose up -d` suffit). Nouvel endpoint `POST /auth/first-login-reset` protégé par JWT avec claim `mustResetCredentials`, validation Bean sur email/password/displayName, codes d'erreur structurés `400 PASSWORD_UNCHANGED`, `403 PASSWORD_RESET_REQUIRED`, `403 PASSWORD_RESET_NOT_REQUIRED`, `409 EMAIL_ALREADY_EXISTS`. `AuthResponse` enrichi d'un champ `mustResetCredentials` (toujours présent). Filtre HTTP dédié `PasswordResetRequiredFilter` (allowlist : `/auth/first-login-reset` + `/auth/logout`). Nouveau service `UserOnboardingService` mutualise `User + Categories + Account + Preferences` entre `accept-invite` et bootstrap. Deux `ApplicationRunner` Spring (`BootstrapSeedRunner` `@Order(1)`, `AdminSyncRunner` `@Order(2)`). Config typée `BootstrapProperties @ConfigurationProperties @Validated @Email` — fail-fast si `BOOTSTRAP_EMAIL` invalide. UI Angular : composant standalone `FirstLoginResetComponent` + guards composables `passwordResetGuard` / `notPasswordResetGuard`. Client Flutter non impacté (indépendant). Migrations Flyway V30 + V31. `docs/deployment.md` enrichi section "Premier démarrage sur instance vierge".

### Changed
- **BREAKING KKS-233 (architecture admin)** — Le statut administrateur est désormais stocké en base (`users.is_admin BOOLEAN NOT NULL DEFAULT FALSE`, V30) au lieu d'être dérivé dynamiquement de `ADMIN_EMAILS` à chaque requête. `AdminAuthorizationFilter` et `UserService.toResponse` lisent `user.isAdmin()`. `ADMIN_EMAILS` devient une source de promotion au démarrage uniquement (jamais de rétrogradation) via `AdminSyncRunner`. **Impact déploiement instance existante** : au prochain boot post-merge, `AdminSyncRunner` promeut automatiquement à `isAdmin=true` tous les users dont l'email figure déjà dans `ADMIN_EMAILS`. Aucune action manuelle requise pour Kelly. **Impact self-hoster après reset** : après un changement d'email via `/auth/first-login-reset`, l'utilisateur conserve son accès admin sans besoin de mettre à jour `.env`.

- **KKS-232 Onboarding controle par invitation admin** — nouveau flux d'onboarding remplacant l'inscription publique (conformite constitution v2.1.2 principe VII "Self-Hosted Ready" + Contexte d'usage). Entite `Invitation(token UUID v4, email, invitedBy, expiresAt, usedAt, revokedAt)` avec TTL 7 jours. Admin designe par env var `ADMIN_EMAILS` (CSV), pas de colonne `role` (YAGNI). Colonne `users.disabled_at` pour soft-disable. Endpoints : `POST /admin/invitations`, `GET /admin/invitations`, `DELETE /admin/invitations/:id`, `GET /admin/users`, `PATCH /admin/users/:id/disable|enable`, `GET /auth/invitations/:token` (public), `POST /auth/accept-invite` (public, remplace register). Protection via `AdminAuthorizationFilter` (403 pour non-admin). Garde-fou dernier admin : `409 LAST_ADMIN_CANNOT_BE_DISABLED`. `JwtFilter` refuse les users desactives (401). `GET /users/me` enrichi avec `isAdmin` (derive cote serveur, non stocke). UI Angular + Flutter : page `Settings > Utilisateurs` (conditionnelle isAdmin) avec tabs Invitations / Users, bouton `+ Inviter` (copie auto du lien), bouton `Copier le lien` par ligne sur invitations actives. Page publique `/accept-invite/:token` sur les 2 fronts avec auto-login post-acceptation. Migrations Flyway V28 + V29.

### Removed
- **BREAKING KKS-232** — Route `POST /api/auth/register` supprimee. DTO `RegisterRequest` supprime. Methode `AuthService.register` supprimee. L'onboarding se fait desormais exclusivement via le flux d'invitation admin. Migration des instances existantes : ajouter `ADMIN_EMAILS=<email-admin>` dans l'env prod — le compte existant correspondant devient admin automatiquement. Composants frontend `RegisterScreen` (Flutter) et `features/auth/pages/register` (Angular) supprimes, ainsi que les liens "Creer un compte" sur les pages de login.

### Fixed
- Suite de tests Angular (Vitest) realignee avec l'API actuelle des composants — 55 tests corriges sur 8 fichiers (`debt-form`, `debt-detail`, `repay-dialog`, `transaction-form`, `subscriptions`, `subscription-detail`, `autocomplete`, `notification-panel`) : mocks de services manquants (`ModalService`, `CurrencyService`, `ToastService`, `PreferenceService`, etc.), stub `IntersectionObserver` pour jsdom, `provideNoopAnimations()` pour les composants avec animations, suppression des assertions sur methodes renommees/disparues (`isEditMode`→`isEditing`, `showRepayDialog()`→`modalService.openModal('repay')`, `hasAccount()`→`selectedAccount()`), alignement sur les selecteurs DOM actuels
- `createAmountWidth` (shared/utils) — guard `if (ctx)` pour tolerer l'absence de canvas 2d context en environnement jsdom/SSR (valeur de largeur estimee en fallback)



### Removed
- **BREAKING** — Module shop (gestion de produits et ventes) entièrement extrait de l'app. Endpoints `/api/products`, `/api/products/*/sell`, `/api/products/*/restock` supprimés. Champs DTO retirés : `TransactionResponse.productId/productName`, `AccountResponse.isShopAccount`, `UserPreferenceResponse/Request.shopAccountId/includeShopInBalance`. Entités JPA `Product` et relation `Transaction.product` supprimées. Feature toggle `SHOP` retirée de l'enum `Feature`. Le code du module est préservé dans le tag git `archive/shop-v0` et les specs devflow correspondantes sont archivées dans `.specify/specs/_archived/`. Une refonte séparée sera faite dans un projet `kshop` dédié à partir des vrais besoins de l'utilisatrice active.

### Changed
- Modèle de données : 19 → 17 entités JPA persistées
- Enum `Feature` : `SUBSCRIPTIONS, DEBTS, SHOP, BUDGETS` → `SUBSCRIPTIONS, DEBTS, BUDGETS`
- Catégorie système "Boutique" retirée du seeding à l'inscription ; les transactions existantes qui y étaient liées ont leur `category_id` mis à NULL via `ON DELETE SET NULL`
- Migration `V26__drop_shop.sql` : DROP FK/colonnes/table `products`, nettoyage `enabled_features` et `nav_order` des users existants

## [4.2.4] - 2026-03-22

### Changed
- FAB contextuel par page — virement restreint au dashboard uniquement, FAB masque sur /settings/**; docs architecture et plan de test mis a jour

## [4.2.2] - 2026-03-21

### Added
- Devise et fuseau horaire a l'inscription — selecteur devise dans le formulaire (Angular + Flutter), timezone auto-detecte par le client (Intl API / DateTime), compte par defaut et preferences initialises avec la devise choisie et le timezone detecte; suppression du selecteur devise fantome dans le profil Angular; fix Africa/Togo → Africa/Lome (identifiant IANA valide) (KKS-100)

## [4.2.1] - 2026-03-20

### Fixed
- SCSS budget depassement — import-review.scss (12kB → 8kB) et import-settings.scss (9kB → 8kB), styles communs extraits dans _utilities.scss

## [4.2.0] - 2026-03-20

### Added
- Settings Angular alignement sur Flutter — hub 3 groupes (General, Gestion, Autre) avec headers et couleurs d'icones variees, ordre identique Flutter, retrait Budget, ajout Securite placeholder; page A propos enrichie (statut serveur, grille stats 2x2, contact mailto, glassmorphism dark mode) (KKS-098)
- Import de releves bancaires CSV — parsing API (Commons CSV), review interactif Angular, brouillons persistants (7j expiration), categorisation par apprentissage (regles pattern→categorie), deduplication fuzzy (Jaro-Winkler seuil 0.85), profils d'import pre-configures (SG) et personnalises, mapping manuel colonnes, actions groupees, nettoyage intelligent des libelles; Flyway V22-V23, 15 endpoints /imports/**, 3 composants Angular (ImportSettings, ImportReview, CsvMapping) (KKS-099)

## [4.1.0] - 2026-03-20

### Added
- Settings Angular alignement sur Flutter — hub 3 groupes (General, Gestion, Autre) avec headers et couleurs d'icones variees, ordre identique Flutter, retrait Budget, ajout Securite placeholder; page A propos enrichie (statut serveur, grille stats 2x2, contact mailto, glassmorphism dark mode) (KKS-098)

## [4.0.0] - 2026-03-20

### Added

**Backend (api/)**
- Preferences utilisateur et feature toggles — Flyway V15, UserPreference entity, endpoints GET/PUT /users/me/preferences (KKS-117)
- Product CRUD — entity, controller, service, repository, Flyway V16 (KKS-118)
- Product sales et restock — endpoints sell/restock/getSales, shop account preference (KKS-119)
- Notification system — WebSocket/STOMP, NotificationScheduler, table notifications, preferences, Flyway V16 (KKS-072)
- Currency management — exchange rates, rebase logic, ExchangeRate entity, Flyway V14 (KKS-156)
- Budget categories — CRUD, overview mensuel, history avec snapshots, normalisation frequence, multi-devises, Flyway V17 (KKS-073)
- Unbudgeted spending tracking dans budget overview et history (KKS-076)
- Debt enhancements — repayment tracking, account association, total balance, snooze reminders, NotificationScheduler DEBT_REMINDER, Flyway V18 (KKS-077)
- Associer une banque a un compte — BankRegistry 29 banques statiques (FR/TG/International), endpoint GET /banks, Flyway V19, AccountRequest/Response enrichis (KKS-081)
- Transactions recurrentes — RecurringTransactionController (5 endpoints), SubscriptionPaymentService (payer/historique/cumul), Flyway V20, Transaction enrichie (+isRecurring, frequency, nextOccurrence, recurringActive, subscription FK, product FK) (KKS-085)
- TextScale enum et sync API — Flyway V21, PreferenceService enrichi (KKS-094)
- Propagation automatique rebase taux de change lors du changement de devise principale (KKS-095)

**Frontend Angular (app/)**
- Feature toggles — settings, DnD navOrder, sidebar dynamique, featureGuard (KKS-150)
- Data settings — statut serveur (health check), reload avec confirmation (KKS-151)
- Transfer form entre comptes avec validation cross-field (KKS-152)
- Responsive bottom nav mobile < 768px (KKS-153)
- Shop module — product CRUD, sell, restock, sales history, images base64 (KKS-154)
- Notification system — STOMP, badge, panel, settings (KKS-072)
- Currency dashboard — selector, conversion, settings (KKS-156)
- Budget categories CRUD + charts ng2-charts (KKS-074)
- Unbudgeted spending display (KKS-076)
- Debt enhancements — detail view, repayment dialog, snooze, historique paiements, barre progression (KKS-078)
- Associer une banque a un compte — BankSelect, AccountBankIcon, AccountForm enrichi, image.utils.ts (KKS-082)
- Transactions recurrentes & paiements abonnements — RecurringList (validate/skip/deactivate), SubscriptionDetail (historique + total cumule), NotificationPanel etendu (KKS-086)
- Creation et conversion de transactions recurrentes — toggle recurrente dans TransactionForm, action "Rendre recurrente" (KKS-087)
- Finance dashboard refactor — layout, currency conversion, shell header (KKS-090)
- Text scale setting — Petit/Normal/Grand dans Appearance (KKS-093)
- Emoji picker — remplacement input texte par emoji-mart picker (categories, recents, recherche, theme dark/light, lazy-loading) (KKS-163)

**Mobile Flutter (flutter/)**
- CRUD Notifiers Riverpod pour 5 entites + CrudNotifier/CrudRepository base classes (KKS-115)
- Common widgets — AppFormField, ListItem, MonthSelector, SegmentedFilter, SelectPicker, CategoryPicker, ModalService, AdaptiveScaffold, AmountFormatter, RelativeDateFormatter
- Dashboard screen — account hero, monthly summary, mini-cards, recent transactions (KKS-042)
- Transaction list + form avec navigation mensuelle, filtrage et i18n (KKS-103)
- Subscription list + form avec frequence toggle, summary et renewal dates (KKS-105, KKS-106)
- Debt list + form avec filter, summary, sections et repaid toggle (KKS-107)
- Transfer form avec validation et FAB conditionnel (KKS-109)
- Settings profile avec currency editing (KKS-111)
- Settings appearance — theme, text scale (KKS-112)
- Settings accounts management (KKS-113)
- Settings categories management (KKS-114)
- EmojiInput widget avec FormField integration (KKS-98)
- Feature toggles settings (KKS-120)
- Bottom nav config — DnD reordering, preview (KKS-121, KKS-122)
- Shop products list avec CRUD notifier (KKS-123)
- Product form — image picker, margin indicator (KKS-124)
- Product detail — sell, restock, sales history (KKS-125)
- Notification system — STOMP, local notifications, settings (KKS-072)
- Currency dashboard — selector, conversion, settings (KKS-156)
- Budget categories — CRUD, dashboard, charts fl_chart, local Drift + remote Dio (KKS-075)
- Unbudgeted spending display + MonthSelector fix (KKS-076)
- Debt enhancements — detail view, repayment bottom sheet, snooze dialog, notifications (KKS-079)
- Associer une banque a un compte — BankSelectPicker, AccountBankIcon, 29 logos SVG, Drift migration v3 (KKS-083)
- Transactions recurrentes & paiements abonnements — RecurringListScreen, SubscriptionDetailScreen, NotificationPanel etendu (KKS-088)
- Refonte dashboard — PatrimoineCard (gradient amber-indigo, variation %), IncomeExpenseCards (delta mois precedent), badges devise, section Budgets, CustomScrollView (KKS-201)

**Cross-plateforme**
- Phosphor Icons migration — ~60 icones Flutter, ~20 icones Angular (KKS-162)
- Design tokens partages — docs/design-tokens.md source de verite unique, 7 categories (KKS-126)
- Product images sync Flutter-Angular via base64 data URI (KKS-154)
- TextScale sync via API — localStorage cache + API source de verite (KKS-094)
- Currency rebase propagation — WebSocket STOMP push, indicateur hasMissingRate (KKS-095)

### Changed
- Dashboard Angular refonte visuelle iOS-like — hero card gradient, glassmorphism, badges variation, barres budget animees, micro-interactions (KKS-091)
- Bottom nav Angular refonte visuelle — pill indicator, glassmorphism dark mode, bordure subtile light mode (KKS-092)
- Icones du dashboard teintees avec la couleur de la categorie
- Icones systeme migrees vers Phosphor Icons (Flutter + Angular) (KKS-162)
- Budget : agregation multi-devises corrigee — transactions converties en devise principale avant sommation, templates recurrents exclus des calculs (KKS-095)
- ExchangeRateService.getRate() centralise la resolution taux direct/inverse, supprime la duplication BudgetService/TransactionService (KKS-095)
- CategoryResponse.from() et AccountSummary.from() static factories remplacent les methodes privees dupliquees dans 5 services (KKS-085)
- SubscriptionPaymentService.getTotalPaid() utilise une COUNT query au lieu de charger toutes les transactions (KKS-085)
- AbstractEnumListConverter extrait pour reduire la duplication des converters JPA (KKS-072)
- ConvertAmountPipe rendu pure pour meilleure performance change detection (KKS-074)
- Currency column elargie a 10 caracteres (KKS-074)
- Settings refonte en hub navigable avec sous-pages (Flutter)
- FAB speed dial corrige — RenderBox.localToGlobal() remplace CompositedTransformFollower (Flutter)

### Fixed
- JWT refresh race condition et cold start auth flow (Flutter)
- FAB speed dial menu et positionnement wide screen (Flutter)
- Filtrage des transactions par mois dans GET /transactions (KKS-103)
- hasValidToken() verifie l'expiration du JWT (Flutter)
- authRemoteDataSourceProvider non initialise dans ProviderScope (Flutter)
- Retourner 401 au lieu de 403 pour les requetes non authentifiees
- Currency.name renomme en displayName pour eviter conflit Dart (Flutter)
- Debt DTOs alignes avec les noms de champs JSON backend (Flutter)
- Base64 images autorisees et filtrage paths locaux Flutter (Shop)

## [2.1.1] - 2026-02-20

### Added
- Ajustement de solde de compte via endpoint `POST /accounts/{id}/adjust-balance`
- Nouveau type de transaction `AJUSTEMENT` (immuable, non modifiable/supprimable)
- Catégorie système "Ajustement" auto-créée
- Handler `AccessDeniedException` (403) dans le GlobalExceptionHandler
- Champ "nouveau solde" dans le formulaire d'édition de compte (frontend)
- Style dédié pour les transactions d'ajustement dans la liste

## [2.0.0] - 2026-02-18

### Added
- Projet Flutter (iOS, Android, Web) avec architecture feature-first
- State management Riverpod, navigation GoRouter avec auth guards
- Base de données locale Drift (SQLite) avec DAOs pour toutes les entités
- Client HTTP Dio avec intercepteur JWT pour le mode serveur
- Flow onboarding avec choix mode local/serveur
- Design system : thèmes light/dark portés depuis les tokens SCSS (Amber primary, Inter font)
- Navigation bottom bar (4 onglets) + NavigationRail adaptatif wide screen
- FAB speed dial (Transaction, Abonnement, Dette, Virement)
- Écrans auth : login, register, lock (biométrie/PIN)
- Data sources et repositories distants pour le mode serveur
- Localisation française (l10n)
- 65 tests unitaires/widget, tests d'intégration

## [1.4.0] - 2026-02-17

### Added
- Documentation d'installation PWA pour Android et iOS (`docs/pwa-install.md`)

## [1.3.0] - 2026-02-17

### Added
- Support multi-devises : enum Currency (EUR/USD/GBP/XOF), CurrencyController, migration Flyway V8, devise par défaut sur User (KKS-030)
- Composant SelectPicker générique avec bottom-sheet et migration des formulaires (KKS-029)
- Gestion des comptes bancaires côté frontend : AccountService, liste comptes, account-form avec preview live et color swatches (KKS-81)
- Refonte page Settings en hub 8 sections avec navigation enfant : Profile, Appearance, Accounts, Categories, Placeholder (KKS-83)
- ThemeService pour gestion centralisée du thème light/dark
- CurrencyService et UserService frontend
- EmojiInput natif en remplacement de EmojiGrid
- Transfer-form : composant de virement entre comptes
- UserController et endpoint PUT `/users/me` pour mise à jour profil et devise
- Formulaire d'inscription avec toggle login/register sur `/auth`
- Icône SVG sans background

### Changed
- Refonte identité visuelle du shell : header et sidebar redesign
- Refonte formulaire account-form avec type cards, preview live et color swatches
- Dashboard enrichi avec sélecteur de compte et affichage multi-devises
- Formulaires debt-form, subscription-form et transaction-form : intégration SelectPicker et compte associé
- AmountPipe mis à jour pour supporter les devises
- CategoryPicker simplifié avec SelectPicker

### Fixed
- Retourner 401 au lieu de 403 pour les requêtes non authentifiées
- Permission denied logs Docker — entrypoint chown avant runuser
- Correctifs visuels post-déploiement V1

## [1.0.0] - 2026-02-13

### Added
- **Frontend Angular 21 PWA** : initialisation projet monorepo `app/` (KKS-23)
- Configuration proxy API, HttpClient et ApiService (KKS-24)
- ESLint, Prettier et conventions signals-first (KKS-25)
- AuthService : login, register, logout, détection d'expiration (KKS-25)
- Guard d'authentification Angular (KKS-27)
- Intercepteur HTTP JWT (KKS-26)
- Design system SCSS : tokens, thèmes light/dark, reset, DESIGN.md
- Écran de login et layout shell (KKS-28, KKS-29)
- Bouton flottant FAB avec speed dial (KKS-30)
- Interfaces TypeScript des entités métier (KKS-47)
- Services CRUD frontend : transactions, subscriptions, debts (KKS-50)
- AmountPipe et RelativeDatePipe (KKS-48)
- Composant ListItem réutilisable (KKS-49)
- Formulaires modaux : Transaction (KKS-51), Subscription (KKS-52), Debt (KKS-53)
- Écrans listes : Transactions (KKS-54), Abonnements (KKS-55), Dettes (KKS-56)
- Écran Dashboard avec KPI 6 indicateurs et mini-cards cliquables (KKS-57, KKS-70)
- ModalService et câblage édition/suppression (KKS-58)
- Entité Category avec CRUD complet et liaison FK aux 3 entités métier
- Système catégories : isSystem, seeding, gardes, @Transactional (KKS-61, KKS-63)
- CategoryPicker, EmojiGrid et CategoryForm (KKS-64, KKS-65, KKS-66)
- Intégration catégories dans formulaires, listes, settings et navigation (KKS-67)
- Tests unitaires services Phase 4 (KKS-59)
- Tests unitaires système catégories : 114 backend, 130 frontend
- JWT refresh token avec rotation et détection de réutilisation backend (KKS-73)
- Refresh token frontend : renouvellement transparent, logout avec révocation (KKS-73)
- PWA installable avec icônes custom et manifest personnalisé (KKS-75)
- Dockerisation API + frontend avec Docker Compose et Caddy (KKS-76)
- Redesign page Dettes : sections groupées, KPI en cours, filtre simplifié (KKS-71)

### Changed
- Refonte UX formulaires : toggle header, grille 2 colonnes, suppression directe (KKS-69)
- Design polish en 6 phases : tokens, boutons, shell, modals, cards, settings
- Renommage DebtType JE_DOIS/ON_ME_DOIT → EMPRUNT/PRET (KKS-60)
- Renommage projet budget → k-budget v1.0.0

### Fixed
- Checkboxes non fonctionnelles dans les formulaires (KKS-68)
- Accents dans les annotations Swagger des controllers
- Fautes d'orthographe
- Build Docker images pour linux/amd64 via buildx

## [0.1.0] - 2026-02-07

### Added
- Initialisation projet Spring Boot 4.0.2 + Java 21
- Entités JPA : User, Transaction, Subscription, Debt (UUID)
- Authentification JWT (login/register) avec Spring Security
- CRUD complet Transactions (KKS-19)
- CRUD complet Subscriptions (KKS-20)
- CRUD complet Debts (KKS-21)
- Endpoint bilan mensuel des transactions (KKS-22)
- Configuration PostgreSQL avec profils dev/prod
- Migrations Flyway
- Documentation API avec springdoc-openapi + Swagger UI (KKS-001)
- Infrastructure de déploiement : Dockerfile, docker-compose, systemd, reverse proxy (Caddy/Nginx), script backup PostgreSQL
- Documentation : README, architecture, exemples API, contrat d'erreurs, guide déploiement
- Constitution projet v2.0.0 et CLAUDE.md

### Changed
- Enums déplacés dans le package `enums/`
- Mise en conformité complète de l'API (score 100%)

[Unreleased]: https://github.com/sopequenoteck/budget/compare/v4.2.0...HEAD
[4.2.0]: https://github.com/sopequenoteck/budget/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/sopequenoteck/budget/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/sopequenoteck/budget/compare/v3.0.0...v4.0.0
[3.0.0]: https://github.com/sopequenoteck/budget/compare/v2.1.1...v3.0.0
[2.1.1]: https://github.com/sopequenoteck/budget/compare/v2.0.0...v2.1.1
[2.0.0]: https://github.com/sopequenoteck/budget/compare/v1.4.0...v2.0.0
[1.4.0]: https://github.com/sopequenoteck/budget/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/sopequenoteck/budget/compare/v1.2.0...v1.3.0
[1.0.0]: https://github.com/sopequenoteck/budget/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/sopequenoteck/budget/releases/tag/v0.1.0
