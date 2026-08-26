<!--
  Sync Impact Report
  ==================================================
  Version change: 3.0.0 → 4.0.0 (MAJOR — suppression de
    la bifurcation des trajectoires de distribution)
  Bump rationale: La direction actée le 2026-08-26 supprime
    la Trajectoire B (Flutter standalone commercial
    local-first). Le projet s'ouvre en open source à
    destination de la communauté self-hosted, avec une
    trajectoire unique : chaque utilisateur héberge son
    instance, et tous les clients — Angular comme Flutter —
    consomment la même API. Cette suppression redéfinit
    structurellement les principes I et VII, retire le
    Contexte B et introduit un principe VIII.

  Modified principles:
    - Principe I : "API-First / Local-First" → "API-First".
      L'API est la source de vérité unique pour tous les
      clients. Ajout des règles de versioning et de
      compatibilité descendante (une seule version courante).
    - Principe II : retrait de la clause propre au mode
      standalone (protection des données locales comme
      source de vérité).
    - Principe IV : retrait de l'onboarding standalone en
      ≤ 30 s ; l'offline redevient un cache, jamais une
      source de vérité.
    - Principe VII : "Two Distribution Trajectories" →
      "Self-Hosted & Distribution ouverte". Trajectoire
      unique, licences, règle de non-bridage des builds,
      politique de langues.

  Added sections:
    - Principe VIII — Angular, client de référence
      (frontière Suivi / Gelé / Jamais)

  Removed sections:
    - Contexte B (Standalone Commercial)
    - Trajectoire A / Trajectoire B (principe VII)
    - Mode standalone (principe I)

  Templates requiring updates:
    - .specify/templates/plan-template.md ⚠ à vérifier —
      toute Constitution Check distinguant Trajectoire A /
      Trajectoire B doit être supprimée
    - .specify/templates/spec-template.md ✅ compatible
    - .specify/templates/tasks-template.md ✅ compatible
    - .specify/templates/checklist-template.md ✅ compatible

  Follow-up TODOs:
    - Retirer la distinction Trajectoire A / B de
      plan-template.md (TODO hérité de la v3.0.0, désormais
      sans objet : il n'y a plus qu'une trajectoire)
    - Aligner docs/vision.md, docs/architecture.md et
      CLAUDE.md sur la trajectoire unique
    - Suppression effective du mode standalone Flutter :
      voir KKS-335
  ==================================================
-->

# Budget App Constitution

## Core Principles

### I. API-First

L'API REST est la source de vérité unique pour tous les
clients. Toute fonctionnalité DOIT être exposée via l'API
avant d'être consommée par un frontend, quel qu'il soit.

- Les endpoints DOIVENT suivre les conventions REST
  (GET/POST/PUT/DELETE, codes HTTP standards)
- Les DTOs DOIVENT séparer la couche API de la couche
  persistance — jamais d'entité JPA exposée directement
- Le context path `/api` DOIT être respecté pour tous les
  endpoints
- Les réponses DOIVENT être en JSON
- Chaque ressource DOIT exposer un contrat clair
  (request DTO → response DTO) documenté par ses types
- Aucun client NE DOIT détenir de source de vérité propre.
  Un stockage local est un cache : il peut disparaître sans
  perte de donnée.

**Contrat de version.** Les clients se mettent à jour
indépendamment des serveurs : une app installée depuis un
store évolue seule, tandis que l'instance de l'utilisateur
reste sur la version qu'il a choisi de déployer.

- Une seule version d'API est servie à la fois. Aucune
  version antérieure N'EST maintenue en parallèle
- Un endpoint public et non versionné DOIT permettre à tout
  client de découvrir la version du serveur, la version
  d'API, la version minimale de client supportée et les
  capacités disponibles
- Un client incompatible DOIT l'apprendre explicitement et
  le dire à l'utilisateur — jamais échouer sur une erreur
  technique
- On NE retire ni NE renomme jamais un champ de réponse ;
  on ajoute
- On NE rend jamais obligatoire un champ de requête qui ne
  l'était pas
- Un changement de contrat passe par un nouvel endpoint,
  pas par la modification d'un existant
- Une rupture inévitable DOIT être assumée : version
  minimale de client relevée, note de migration publiée

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
- Les secrets détenus par un client (jetons d'authentification,
  code de verrouillage) DOIVENT être conservés dans le stockage
  sécurisé de la plateforme
- Les instances étant exposées publiquement par leurs
  propriétaires, les endpoints d'authentification DOIVENT
  être protégés contre les tentatives répétées

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

Les clients (PWA Angular et app Flutter) DOIVENT être
optimisés pour un usage mobile quotidien. L'expérience de
saisie rapide est la priorité absolue.

- Saisie d'une dépense en 2-3 interactions maximum
- Le bouton flottant (+) DOIT être accessible sur tous les
  écrans (sauf login)
- Le dashboard DOIT afficher : solde mensuel, résumé
  abonnements, état des dettes
- Le design DOIT être responsive mais optimisé mobile
  en priorité
- **L'instance de l'utilisateur sera régulièrement
  injoignable** : elle est hébergée chez lui, derrière un
  VPN ou un reverse proxy fragile. Les clients DOIVENT
  dégrader proprement plutôt qu'échouer — cache de lecture,
  message explicite, reprise automatique. Ce cache N'EST
  JAMAIS une source de vérité (cf. principe I)

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
- La suite de tests DOIT être exécutable par un contributeur
  extérieur, sans accès à une infrastructure privée

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
- Les logs et les messages techniques de l'API DOIVENT être
  en anglais : ils s'adressent aux développeurs et aux
  administrateurs d'instance, pas aux utilisateurs finaux

### VII. Self-Hosted & Distribution ouverte

Il existe **une seule trajectoire** : chaque utilisateur
héberge sa propre instance. Le projet n'exploite aucun
service et ne collecte aucune donnée.

**Contraintes d'hébergement**

- La configuration DOIT supporter les profils Spring
  (dev / prod) via fichiers YAML séparés
- En production, toute configuration sensible DOIT provenir
  de variables d'environnement
- PostgreSQL DOIT être la seule dépendance d'infrastructure
  externe
- Pas de dépendance à des services SaaS (monitoring cloud,
  auth externe, CDN, notifications propriétaires)
- L'installation DOIT être réalisable sans connaissance
  préalable du projet, base de données comprise
- L'application DOIT supporter plusieurs utilisateurs sur une
  même instance (isolation par user authentifié, cf.
  principe II)
- L'inscription publique N'EST PAS un objectif : l'onboarding
  se fait via invitation contrôlée par l'administrateur de
  l'instance

**Ouverture du code**

- `api/` et `app/` sont sous AGPL-3.0 : la clause réseau
  empêche un tiers de fermer le backend pour en exploiter
  un service
- `flutter/` est sous MPL-2.0 : GPL et AGPL sont
  incompatibles avec les conditions des stores
- Les actifs tiers (logos de marques, polices) NE SONT PAS
  couverts par ces licences et DOIVENT être déclarés
  séparément
- Le nom et le logo du projet sont réservés et hors licence
- Toute contribution externe DOIT être couverte par un
  accord de contribution, faute de quoi la licence devient
  impossible à faire évoluer

**Non-bridage**

L'application mobile est payante sur les stores : on y vend
la commodité, pas le logiciel.

- Un build compilé par un tiers DOIT être fonctionnellement
  identique à celui distribué sur les stores
- Aucune fonctionnalité NE DOIT être conditionnée à
  l'origine du build, à un achat ou à une licence

**Langues**

- L'anglais est la langue par défaut de l'interface et de
  la vitrine du projet
- Le français est maintenu **à parité** et n'est jamais en
  retard sur l'anglais : c'est la langue de la zone visée
- Aucune chaîne d'interface NE DOIT être codée en dur
- L'API ne se traduit pas : elle émet des codes d'erreur,
  et les clients en affichent une traduction locale

### VIII. Angular, client de référence

Deux clients complets servis par une même API représentent
un coût de maintenance double. Ce coût vient de la **parité**,
pas de l'existence du second client.

- **Toute fonctionnalité naît côté Angular**, qui est le
  client de référence et la surface fonctionnelle complète
- **Flutter n'a jamais d'obligation de parité.** Une
  fonctionnalité absente de Flutter n'est pas une dette
- Toute surface DOIT être classée dans l'un des trois états :
  - **Suivi** — parité maintenue, toute évolution est portée
  - **Gelé** — existe côté Flutter, continue de fonctionner
    et reste maintenu (traductions, montées de version,
    tests), mais n'accueille aucune évolution fonctionnelle
  - **Jamais** — n'existe pas côté Flutter et n'existera pas
- Le critère de classement d'une nouvelle surface est unique :
  *cette surface va-t-elle continuer à bouger ?* Si oui et
  qu'elle est complexe, elle reste côté Angular. Si c'est un
  CRUD stable sur une entité, elle peut vivre des deux côtés
- Flutter porte en propre ce que le web ne peut pas offrir :
  verrouillage biométrique, notifications locales planifiées
  fonctionnant serveur injoignable, intégrations système
- Le classement d'une surface DOIT être vérifié avant tout
  portage, et documenté

## Contexte d'usage

- **Déploiement cible** : instance auto-hébergée, installée
  et administrée par son propriétaire.
- **Public visé** : la communauté self-hosted, avec une
  différenciation assumée sur la zone francophone — France
  et Afrique de l'Ouest — via le multi-devises et la
  couverture bancaire par profils d'import.
- **Isolation stricte** : chaque user a ses propres comptes,
  transactions, budgets, dettes. Aucune entité n'est partagée
  entre users.
- **Flux cross-user** : les relations financières entre deux
  users de l'instance (ex : prêt) sont modélisées séparément
  dans chaque compte. Un rapprochement automatique inter-users
  N'EST PAS un objectif.
- **Pas d'inscription publique** : création de compte par
  invitation, contrôlée par l'administrateur de l'instance.
- **Aucune collecte** : le projet n'exploite aucun serveur,
  ne reçoit aucune donnée, n'embarque ni analytique ni
  traceur.
- **Pas d'agrégation bancaire** : elle exigerait un agrément
  AISP, donc une entité exploitant un service. L'alimentation
  se fait par import de relevés, avec des profils bancaires
  contribués par la communauté.

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
- **Licence** : AGPL-3.0

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
- **i18n** : chargement à l'exécution — une seule image
  Docker DOIT servir toutes les langues
- **Licence** : AGPL-3.0

### Mobile natif (flutter/)

- **Langage** : Dart >= 3.6
- **Framework** : Flutter >= 3.27 (stable)
- **State management** : flutter_riverpod
- **Routing** : go_router
- **HTTP** : Dio — l'API est la source de vérité
- **Stockage local** : cache et préférences uniquement,
  jamais une source de vérité
- **Secure storage** : flutter_secure_storage
- **Models** : Freezed + json_serializable
- **Tests** : flutter_test + Mockito
- **Code generation** : build_runner (Freezed, JSON)
- **Structure** : `common_widgets/`, `constants/`, `data/`,
  `domain/`, `features/`, `l10n/`, `routing/`, `theme/`,
  `utils/`
- **Configuration serveur** : l'URL de l'instance est une
  étape primaire et assumée de l'onboarding, jamais une
  option avancée
- **Distribution** : App Store, Google Play et F-Droid
- **Build sans secret** : la compilation depuis les sources
  DOIT réussir sans keystore ni configuration privée
- **Licence** : MPL-2.0

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
  8 principes de cette constitution
- Avant tout portage vers Flutter, l'état de la surface
  (Suivi / Gelé / Jamais) DOIT être vérifié
- **Versioning** : `VERSION`, `api/pom.xml` et
  `app/package.json` partagent une SemVer commune. Flutter
  applique sa propre SemVer (`flutter/pubspec.yaml`), alignée
  sur les cycles stores, mais DOIT rester compatible avec la
  version minimale de client déclarée par l'API

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

**Version**: 4.0.0 | **Ratified**: 2026-02-07 | **Last Amended**: 2026-08-26
