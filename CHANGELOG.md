# Changelog

Basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
Ce projet suit [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Added
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
