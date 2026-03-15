# Changelog

Basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
Ce projet suit [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Added
- Associer une banque à un compte — BankRegistry 29 banques statiques (FR/TG/International), endpoint GET /banks, Flyway V19, AccountRequest/Response enrichis (KKS-081)
- Associer une banque à un compte (Angular) — BankSelect, AccountBankIcon, AccountForm enrichi, image.utils.ts (KKS-082)
- Associer une banque à un compte (Flutter) — BankSelectPicker, AccountBankIcon, 29 logos SVG, Drift migration v3 (KKS-083)
- Transactions récurrentes backend — RecurringTransactionController (5 endpoints), SubscriptionPaymentService (payer/historique/cumul), Flyway V20, Transaction enrichie (+isRecurring, frequency, nextOccurrence, recurringActive, subscription FK, product FK) (KKS-085)

### Changed
- CategoryResponse.from() et AccountSummary.from() static factories remplacent les méthodes privées dupliquées dans 5 services (KKS-085)
- SubscriptionPaymentService.getTotalPaid() utilise une COUNT query au lieu de charger toutes les transactions (KKS-085)

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

[Unreleased]: https://github.com/sopequenoteck/budget/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/sopequenoteck/budget/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/sopequenoteck/budget/compare/v1.2.0...v1.3.0
[1.0.0]: https://github.com/sopequenoteck/budget/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/sopequenoteck/budget/releases/tag/v0.1.0
