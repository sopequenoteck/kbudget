<!--
  Sync Impact Report
  ==================================================
  Version change: 2.1.2 → 3.0.0 (MAJOR — bifurcation
    des trajectoires de distribution Spring/Angular vs Flutter)
  Bump rationale: Reconnaissance explicite que Flutter devient
    un produit commercial standalone distribué via stores publics
    (App Store, Google Play), modèle paid one-shot, indépendant
    de la trajectoire self-hosted Spring + Angular existante.
    Cette bifurcation impacte structurellement deux principes
    fondateurs (I et VII) ainsi que le contexte d'usage et les
    contraintes techniques Flutter.

  Modified principles:
    - Principe I (API-First) : reformulé en "API-First /
      Local-First" pour couvrir le mode connecté (Spring +
      Angular et Flutter en sync) et le mode standalone
      (Flutter avec Drift comme source de vérité)
    - Principe VII (Self-Hosted Ready) : reformulé en
      "Two Distribution Trajectories" pour acter la coexistence
      des deux modes de distribution (self-hosted et stores)

  Modified sections:
    - Contexte d'usage : dédoublé en Contexte A (self-hosted)
      et Contexte B (standalone commercial)
    - Contraintes techniques (flutter/) : ajout des contraintes
      stores, versioning indépendant, conformité Apple/Google
    - Workflow de développement : précision versioning séparé
      Flutter vs Spring + Angular

  Added sections:
    - Contexte B (Standalone Commercial)

  Removed sections: aucune

  Templates requiring updates:
    - .specify/templates/plan-template.md ⚠ à vérifier
      (principes I et VII modifiés peuvent impacter les
      checklists Constitution Check)
    - .specify/templates/spec-template.md ✅ compatible
    - .specify/templates/tasks-template.md ✅ compatible
    - .specify/templates/checklist-template.md ✅ compatible

  Follow-up TODOs:
    - Réviser plan-template.md pour intégrer la distinction
      Trajectoire A / Trajectoire B dans la Constitution Check
    - Définir la stratégie concrète de versioning Flutter
      (numérotation, branches release, CI/CD séparée) lors
      de la phase technique de mise en commerce
  ==================================================
-->

# Budget App Constitution

## Core Principles

### I. API-First / Local-First

Toute fonctionnalité DOIT avoir une source de vérité unique
explicitement documentée selon le mode de déploiement.

**Mode connecté (Spring + Angular, Flutter en mode sync)** :
le backend est la source de vérité. Toute fonctionnalité DOIT
être exposée via l'API REST avant d'être consommée par le
frontend.

- Les endpoints DOIVENT suivre les conventions REST
  (GET/POST/PUT/DELETE, codes HTTP standards)
- Les DTOs DOIVENT séparer la couche API de la couche
  persistance — jamais d'entité JPA exposée directement
- Le context path `/api` DOIT être respecté pour tous les
  endpoints
- Les réponses DOIVENT être en JSON
- Chaque ressource DOIT exposer un contrat clair
  (request DTO → response DTO) documenté par ses types

**Mode standalone (Flutter local-first)** :
la base Drift locale (SQLite) est la source de vérité.
L'application DOIT fonctionner nominalement sans aucune
dépendance réseau.

- Le schéma Drift DOIT être versionné via migrations
- Aucune feature en mode standalone NE DOIT requérir une
  connexion serveur pour fonctionner
- Si la sync Spring est activée par l'utilisateur (Settings →
  Avancé), l'API devient une réplique secondaire — la
  résolution de conflits DOIT être documentée explicitement
  par feature dans le plan

### II. Sécurité par défaut

Toutes les routes API DOIVENT être protégées par JWT sauf
celles explicitement déclarées publiques dans `SecurityConfig`.

- Les mots de passe DOIVENT être hashés via BCrypt
- Les secrets (JWT secret, credentials DB) NE DOIVENT JAMAIS
  être hardcodés en production — variables d'environnement
  obligatoires
- Les données utilisateur DOIVENT être isolées : chaque requête
  DOIT filtrer par le `user` authentifié (pas d'accès
  cross-user)
- Les inputs DOIVENT être validés via Bean Validation
  (`@Valid`, `@NotNull`, `@Size`, etc.) avant traitement
- Les erreurs de sécurité NE DOIVENT PAS exposer de détails
  internes (stack traces, noms de tables, etc.)
- En mode standalone Flutter, les données locales DOIVENT
  être protégées par le secure storage du device pour les
  secrets (clés de chiffrement éventuelles, tokens de sync)

### III. Simplicité & YAGNI

Le code DOIT rester simple et résoudre uniquement le problème
actuel. Pas d'abstractions prématurées, pas de features
spéculatives.

- Architecture en couches simples :
  Controller → Service → Repository
- Pas de patterns complexes (CQRS, Event Sourcing, DDD
  tactique) sauf justification documentée dans le plan
- Un seul module Maven — pas de multi-module tant que non
  nécessaire
- Les enums DOIVENT être utilisés pour les valeurs fixes
  du domaine (TransactionType, Frequency, DebtType)
- Lombok DOIT être utilisé pour réduire le boilerplate
- Trois lignes similaires valent mieux qu'une abstraction
  prématurée

### IV. Mobile-First UX

Les frontends (PWA Angular et app Flutter) DOIVENT être
optimisés pour un usage mobile quotidien. L'expérience de
saisie rapide est la priorité absolue.

- Saisie d'une dépense en 2-3 interactions maximum
- Le bouton flottant (+) DOIT être accessible sur tous les
  écrans (sauf login)
- Le dashboard DOIT afficher : solde mensuel, résumé
  abonnements, état des dettes
- Le design DOIT être responsive mais optimisé mobile
  en priorité
- Les interactions DOIVENT fonctionner offline quand possible
  (PWA service worker côté Angular, SQLite local côté Flutter).
  **Exception** : les features dont les données doivent être
  fraîches en temps réel (remboursements, paiements, soldes
  agrégés, préférences, comptes, catégories) peuvent
  utiliser le mode server-only (API REST sans Drift/SQLite)
  si justifié dans le plan
- L'onboarding Flutter standalone DOIT être réalisable en
  ≤ 30 secondes et démontrer la valeur produit immédiatement

### V. Testabilité

Chaque couche du système DOIT être testable de manière isolée.
Les tests sont un filet de sécurité, pas une contrainte.

- Les endpoints DOIVENT avoir des tests d'intégration couvrant
  les cas nominaux et les cas d'erreur (4xx, 5xx)
- Les services DOIVENT être testables unitairement via
  injection de dépendances (mocks des repositories)
- Les tests DOIVENT suivre le pattern Arrange-Act-Assert
- Nommage descriptif obligatoire :
  `should_[résultat]_when_[condition]`
- Les cas limites DOIVENT être couverts : null, vide,
  valeurs aux bornes (0, négatif, max)
- Pas de tests triviaux (getter/setter) — tester le
  comportement, pas l'implémentation

### VI. Observabilité

Le système DOIT produire suffisamment d'informations pour
diagnostiquer tout problème sans accès au debugger.

- Chaque endpoint DOIT logger l'action effectuée au niveau
  INFO (création, modification, suppression)
- Les erreurs DOIVENT être loggées au niveau ERROR avec
  contexte suffisant (userId, ressource, cause)
- Les exceptions métier DOIVENT être distinctes des exceptions
  techniques dans les logs
- Le format de log DOIT être structuré et cohérent
  (timestamp, niveau, classe, message)
- Pas de `System.out.println` — utilisation exclusive de
  SLF4J/Logback côté Spring, `developer.log` ou packages
  de logging contrôlé côté Flutter (jamais de `print()`
  laissé en production)

### VII. Two Distribution Trajectories

L'application a deux trajectoires de distribution distinctes
qui partagent le même backend Spring et la même DB PostgreSQL,
mais répondent à des contraintes opérationnelles différentes.

**Trajectoire A — Self-Hosted (Spring + Angular)** :
déploiement auto-hébergé, multi-user contrôlé.

- La configuration DOIT supporter les profils Spring (dev /
  prod) via fichiers YAML séparés
- En production, toute configuration sensible DOIT provenir
  de variables d'environnement
- PostgreSQL DOIT être la seule dépendance d'infrastructure
  externe
- Pas de dépendance à des services SaaS (monitoring cloud,
  auth externe, CDN)
- L'application DOIT démarrer avec une seule commande
  (`mvn spring-boot:run` ou `java -jar`)
- L'application DOIT supporter plusieurs utilisateurs sur une
  même instance (multi-tenant logique via isolation par user
  authentifié, cf. principe II)
- L'inscription publique N'EST PAS un objectif : l'onboarding
  se fait via création de compte contrôlée par l'administrateur
  du serveur

**Trajectoire B — Standalone Commercial (Flutter)** :
distribution publique via App Store et Google Play, app
standalone local-first, modèle économique paid one-shot.

- Local-first par défaut (Drift/SQLite), aucune dépendance
  serveur pour le fonctionnement nominal
- Sync optionnelle vers la trajectoire A pour les utilisateurs
  self-hostés (exposée via Settings → Avancé, non marketée)
- Modèle économique : paid one-shot, prix différencié par
  marché (Europe / Afrique) via les price tiers Apple / Google.
  Pas de freemium, pas d'abonnement, pas de V2 payante prévue
- Conformité stores obligatoire : privacy policy, privacy
  nutrition labels, mécanisme de suppression de données
  utilisateur (exigence Apple), backup cloud (iCloud /
  Google Drive)
- Versioning indépendant de la trajectoire A : releases
  Flutter pilotées par les cycles stores (TestFlight, Play
  Console), non couplées aux releases Spring + Angular

## Contextes d'usage

### Contexte A — Self-Hosted (Spring + Angular)

- **Déploiement cible** : instance unique auto-hébergée,
  utilisée par un groupe restreint (~10-20 comptes actifs).
- **Isolation stricte** : chaque user a ses propres comptes,
  transactions, budgets, dettes. Aucune entité n'est partagée
  entre users.
- **Flux cross-user** : les relations financières entre deux
  users de l'instance (ex : prêt, commande pour compte de
  tiers) sont modélisées séparément dans chaque compte.
  Un rapprochement automatique inter-users N'EST PAS un
  objectif.
- **Pas d'inscription publique** : création de compte
  contrôlée, pas de freemium, pas de quota payant.

### Contexte B — Standalone Commercial (Flutter)

- **Déploiement cible** : application standalone installée
  par l'utilisateur final via App Store ou Google Play.
- **Compte unique par device** : pas d'authentification
  multi-user côté app standalone. Les données sont locales
  au device.
- **Sync optionnelle** : un utilisateur peut activer la sync
  vers une instance self-hostée (Trajectoire A) via
  Settings → Avancé. Ses données restent locales,
  l'API agit comme réplique secondaire.
- **Marchés cibles** : Europe (cible principale au launch) +
  Afrique (cible secondaire avec différenciation potentielle
  tontines / mobile money en post-launch).
- **Modèle économique** : paid one-shot, pricing différencié
  par marché via les price tiers Apple / Google. Pas de
  freemium, pas d'abonnement, pas de V2 payante.
- **Maintenance ciblée** : 3 à 5 ans après le launch, sans
  cycle de re-paiement intermédiaire.

## Contraintes techniques

### Backend (api/)

- **Langage** : Java 21
- **Framework** : Spring Boot 4.x
- **Build** : Maven
- **Base de données** : PostgreSQL 15+
- **ORM** : Spring Data JPA (Hibernate)
- **Auth** : Spring Security + JWT (jjwt)
- **Tests** : JUnit 5 + Spring Boot Test + Mockito
- **Logging** : SLF4J / Logback
- **Package base** : `fr.kksdev.budget.api`
- **Structure** : `config/`, `controller/`, `service/`,
  `repository/`, `model/`, `dto/`, `enums/`
- **DDL dev** : `create-drop` — **DDL prod** : `validate`

### Frontend PWA (app/)

- **Framework** : Angular 21+
- **Langage** : TypeScript 5.9
- **Styles** : SCSS avec design tokens (`var(--token)`)
- **State** : Signals-first (`signal()`, `computed()`,
  `effect()`)
- **Composants** : Standalone, `ChangeDetectionStrategy.OnPush`
- **DI** : `inject()` uniquement (pas de constructor injection)
- **RxJS** : Limité aux flux HTTP et opérateurs complexes
- **Linting** : ESLint + Prettier

### Mobile natif (flutter/)

- **Langage** : Dart >= 3.6
- **Framework** : Flutter >= 3.27 (stable)
- **State management** : flutter_riverpod
- **Routing** : go_router
- **Base de données locale** : Drift (SQLite) — source de
  vérité en mode standalone (Contexte B)
- **HTTP** : Dio (utilisé uniquement en mode sync optionnelle)
- **Secure storage** : flutter_secure_storage
- **Models** : Freezed + json_serializable
- **Tests** : flutter_test + Mockito
- **Code generation** : build_runner (Drift, Freezed, JSON)
- **Structure** : `common_widgets/`, `constants/`, `data/`,
  `domain/`, `features/`, `localization/`, `routing/`,
  `theme/`, `utils/`
- **Data mode** : local-first par défaut. Sync vers l'API
  REST via Dio activable via Settings → Avancé.
- **Distribution** : App Store (iOS) + Google Play (Android)
- **Versioning** : indépendant des releases Spring + Angular,
  piloté par les cycles stores
- **Conformité stores** : privacy policy, privacy nutrition
  labels, mécanisme de suppression de données utilisateur
  (Apple), backup cloud iCloud / Google Drive
- **Monétisation** : IAP pour licence one-shot

## Workflow de développement

- Toute modification DOIT passer par une branche feature
  (`feature/<nom>`)
- Un pre-commit review DOIT être exécuté avant chaque commit
  (code mort, duplication, secrets, console.log)
- Les commits DOIVENT avoir des messages clairs et descriptifs
- Les tests DOIVENT passer avant tout commit
- Chaque user story DOIT être implémentable et testable
  indépendamment
- Les reviews DOIVENT vérifier l'alignement avec les
  7 principes de cette constitution
- **Versioning** : Spring + Angular partagent une SemVer
  commune (`VERSION`, `api/pom.xml`, `app/package.json`).
  Flutter applique sa propre SemVer (`flutter/pubspec.yaml`),
  indépendante des releases self-hostées et alignée sur les
  cycles stores

## Governance

Cette constitution est le document de référence pour toutes
les décisions architecturales et de développement du projet
Budget App. Elle prévaut sur toute autre convention implicite,
tout en restant pragmatique dans son application.

- **Amendements** : toute modification DOIT être documentée
  avec justification, versionnée selon SemVer, et validée
  avant application
- **Versioning** :
  - MAJOR : suppression ou redéfinition d'un principe
  - MINOR : ajout d'un principe ou expansion significative
  - PATCH : clarifications, corrections de formulation
- **Conformité** : les PRs et reviews DOIVENT vérifier
  l'alignement avec les principes — les écarts mineurs
  sont acceptables s'ils sont documentés et justifiés
- **Complexité** : toute déviation des principes DOIT être
  justifiée dans le tableau de tracking du plan
- **Revue périodique** : la constitution DOIT être revue
  à chaque changement majeur d'architecture ou de scope

**Version**: 3.0.0 | **Ratified**: 2026-02-07 | **Last Amended**: 2026-05-03
