# Research: Banques sur les comptes — Backend

**Feature**: 081-backend-bank-accounts | **Date**: 2026-03-13

## R1 — Stockage des données banques (statique vs DB)

**Decision**: Registre statique en mémoire (classe Java avec Map<String, Bank>)
**Rationale**: 29 entrées fixes, pas de CRUD utilisateur, pas de mise à jour dynamique. Un registre en mémoire est plus simple qu'une table en base et évite une jointure inutile. Aligné avec le principe III (YAGNI).
**Alternatives considered**:
- Table en base avec seeding Flyway : surcharge (CRUD admin, repository, tests DB) pour des données qui ne changent jamais à runtime
- Enum Java : rigide pour l'ajout futur (recompilation), mais les 29 banques sont stables. Trop de valeurs pour un enum lisible → Map statique préférée
- Fichier JSON/YAML externe : complexité de chargement inutile

## R2 — Modélisation Bank (record vs enum vs POJO)

**Decision**: Java record `Bank` (immutable) + classe utilitaire `BankRegistry` (Map statique)
**Rationale**: Un record est léger, immutable, et adapté aux données statiques. BankRegistry fournit `findByCode()` et `getAll()`. Pas besoin d'un @Service Spring pour des données pures.
**Alternatives considered**:
- Enum avec champs : lisible mais 29 valeurs = enum très long, et le code banque (String "SG") ne suit pas la convention de nommage des enums Java
- @Component + @PostConstruct : suringénierie pour des données statiques

## R3 — Enrichissement Account (colonnes vs table de liaison)

**Decision**: 3 nouvelles colonnes directement sur la table `accounts` : `bank_code` (VARCHAR 20, NOT NULL, DEFAULT 'OTHER'), `bank_custom_name` (VARCHAR 100, nullable), `bank_custom_logo` (TEXT, nullable)
**Rationale**: Relation 1:1 simple (un compte = une banque). Pas besoin de table de liaison. Les champs custom sont nullable et utilisés uniquement quand bank_code='OTHER'. Aligné avec le principe III.
**Alternatives considered**:
- Table `banks` + FK : surcharge pour des données statiques, jointure inutile
- JSON column : perte de validation SQL, plus complexe à requêter

## R4 — Résolution banque dans la réponse

**Decision**: Le service résout bankCode → (bankName, bankCountry, bankBrandColor, bankLogoUrl) au moment de la construction de l'AccountResponse. Pour OTHER, les champs custom (bankCustomName, bankCustomLogo) sont retournés tels quels.
**Rationale**: Le client reçoit toutes les infos en une réponse, sans appel supplémentaire à GET /banks. Cohérent avec SC-005.
**Alternatives considered**:
- Client résout côté frontend : double appel, complexité déportée
- Stocker les infos résolues en base : duplication, problème de sync si les données banque changent

## R5 — Logos statiques : servir via Spring Boot

**Decision**: Les fichiers SVG sont déjà dans `api/src/main/resources/static/banks/`. Spring Boot les sert automatiquement via le resource handler par défaut. URL : `/api/banks/logos/{code}.svg` (ou directement `/api/static/banks/{code}.svg` via le context-path).
**Rationale**: Spring Boot sert `/static/**` par défaut. Avec context-path `/api`, les fichiers sont accessibles à `/api/banks/{code}.svg` si on place les fichiers dans `/static/banks/`. Besoin de vérifier le path exact.

**Clarification** : Avec `server.servlet.context-path=/api`, les ressources statiques dans `src/main/resources/static/banks/` sont servies à `http://host/api/banks/*.svg`. Cela entre en conflit avec le endpoint REST `GET /api/banks`. Solution : placer les logos dans un sous-path distinct, ex: `static/bank-logos/` → URL `/api/bank-logos/{code}.svg`, ou utiliser un ResourceHandler custom pour `/banks/logos/**`.

**Decision finale** : Utiliser le path `static/bank-logos/` pour éviter le conflit avec le endpoint REST. URL finale : `/api/bank-logos/{code}.svg`. Le champ `logoUrl` dans BankResponse contiendra le path relatif `/api/bank-logos/{code}.svg`.
**Alternatives considered**:
- CDN externe : viole le principe VII (Self-Hosted)
- Base64 inline dans le JSON : surcharge réseau, pas de cache navigateur

## R6 — SecurityConfig : routes publiques

**Decision**: Ajouter `/banks` et `/bank-logos/**` aux routes publiques dans SecurityConfig.
**Rationale**: FR-010 exige que ces ressources soient accessibles sans auth. Cohérent avec les données statiques publiques.
**Alternatives considered**:
- Auth requise + cache client : surcomplex pour des données publiques non sensibles

## R7 — Migration Flyway V19

**Decision**: Migration V19 ajoute 3 colonnes à `accounts`, initialise `bank_code='OTHER'` pour les lignes existantes.
**Rationale**: Migration simple et rétrocompatible. Pas de perte de données (FR-009 : icone et couleur préservés).
**Alternatives considered**:
- Migration en 2 étapes (add nullable + backfill + set NOT NULL) : plus sûr pour les grosses tables, mais ici single-user avec ~10 comptes max → une seule migration suffit

## R8 — Validation bankCode

**Decision**: Validation dans AccountService via `BankRegistry.findByCode()`. Si le code n'existe pas → exception 400 Bad Request.
**Rationale**: Validation métier dans le service, pas de custom validator Spring. BankRegistry est la source de vérité.
**Alternatives considered**:
- Custom annotation `@ValidBankCode` : plus élégant mais suringénierie pour une seule validation
- Enum constraint en DB : pas applicable car les codes sont dans le code Java, pas en DB
