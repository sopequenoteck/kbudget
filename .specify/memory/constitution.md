<!--
  Sync Impact Report
  ==================================================
  Version change: 1.0.0 → 2.0.0 (MAJOR — redéfinition complète)
  Bump rationale: Redéfinition totale des principes (5 → 7),
    ajout de 2 nouveaux principes (Testabilité, Observabilité),
    réorganisation des sections. Constitue un changement
    incompatible avec la v1.

  Modified principles:
    - I. API-First (conservé, affiné)
    - II. Sécurité par défaut (conservé, affiné)
    - III. Simplicité & YAGNI (conservé, affiné)
    - IV. Mobile-First UX (conservé, affiné)
    - VII. Self-Hosted Ready (conservé, déplacé en VII)

  Added principles:
    - V. Testabilité (NOUVEAU)
    - VI. Observabilité (NOUVEAU)

  Added sections: aucune (sections existantes conservées)
  Removed sections: aucune

  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ compatible
      (Constitution Check générique, accueille les 7 principes)
    - .specify/templates/spec-template.md ✅ compatible
    - .specify/templates/tasks-template.md ✅ compatible
    - .specify/templates/checklist-template.md ✅ compatible
    - .specify/templates/agent-file-template.md ✅ compatible

  Follow-up TODOs: none
  ==================================================
-->

# Budget App Constitution

## Core Principles

### I. API-First

Toute fonctionnalité DOIT être exposée via l'API REST avant
d'être consommée par le frontend. Le backend est la source de
vérité unique pour la logique métier et la validation.

- Les endpoints DOIVENT suivre les conventions REST
  (GET/POST/PUT/DELETE, codes HTTP standards)
- Les DTOs DOIVENT séparer la couche API de la couche
  persistance — jamais d'entité JPA exposée directement
- Le context path `/api` DOIT être respecté pour tous les
  endpoints
- Les réponses DOIVENT être en JSON
- Chaque ressource DOIT exposer un contrat clair
  (request DTO → response DTO) documenté par ses types

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
  (PWA service worker côté Angular, SQLite local côté Flutter)

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
  SLF4J/Logback

### VII. Self-Hosted Ready

L'application DOIT être déployable sur un serveur personnel
sans dépendance à des services cloud externes.

- La configuration DOIT supporter les profils Spring
  (dev / prod) via fichiers YAML séparés
- En production, toute configuration sensible DOIT provenir
  de variables d'environnement
- PostgreSQL DOIT être la seule dépendance d'infrastructure
  externe
- Pas de dépendance à des services SaaS (monitoring cloud,
  auth externe, CDN) en v1
- L'application DOIT démarrer avec une seule commande
  (`mvn spring-boot:run` ou `java -jar`)

## Contraintes techniques

- **Langage** : Java 21
- **Framework** : Spring Boot 4.x
- **Build** : Maven
- **Base de données** : PostgreSQL 15+
- **ORM** : Spring Data JPA (Hibernate)
- **Auth** : Spring Security + JWT (jjwt)
- **Frontend** : Angular PWA
- **Tests** : JUnit 5 + Spring Boot Test + Mockito
- **Logging** : SLF4J / Logback
- **Package base** : `fr.kksdev.budget.api`
- **Structure** : `config/`, `controller/`, `service/`,
  `repository/`, `model/`, `dto/`, `enums/`
- **DDL dev** : `create-drop` — **DDL prod** : `validate`

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

**Version**: 2.0.0 | **Ratified**: 2026-02-07 | **Last Amended**: 2026-02-07
