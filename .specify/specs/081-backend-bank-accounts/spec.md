# Feature Specification: Banques sur les comptes — Backend

**Feature Branch**: `081-backend-bank-accounts`
**Created**: 2026-03-13
**Status**: Draft
**Input**: Linear issue KKS-197 (sous-issue de KKS-164)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des banques supportées (Priority: P1)

En tant qu'utilisateur de l'application, je veux consulter la liste complète des banques supportées afin de pouvoir associer mon compte à la bonne banque lors de la création ou modification.

**Why this priority**: Fondation de la feature — sans la liste des banques, aucune association n'est possible. L'endpoint statique est le prérequis de tous les frontends.

**Independent Test**: Peut être testé en appelant GET /banks et en vérifiant que la liste contient les 29 banques (28 banques connues + OTHER).

**Acceptance Scenarios**:

1. **Given** l'application est démarrée, **When** un utilisateur appelle GET /api/banks, **Then** il reçoit la liste des 29 banques avec code, nom, pays et couleur brand.
2. **Given** l'application est démarrée, **When** un utilisateur non authentifié appelle GET /api/banks, **Then** il reçoit la liste (endpoint public, pas d'auth requise).
3. **Given** la liste des banques, **When** je consulte une banque spécifique (ex: SG), **Then** elle contient un code unique, un nom lisible, un pays (FR/TG/null pour International et OTHER) et une couleur hexadécimale.

---

### User Story 2 - Associer une banque connue à un compte (Priority: P1)

En tant qu'utilisateur, je veux pouvoir associer une banque connue (ex: Société Générale, Ecobank) à mon compte bancaire afin que l'application affiche automatiquement le logo et les couleurs de ma banque.

**Why this priority**: Cas d'usage principal — la majorité des utilisateurs ont un compte dans une banque connue.

**Independent Test**: Peut être testé en créant un compte avec bankCode="SG" et en vérifiant que la réponse contient les informations résolues de la banque.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié, **When** il crée un compte avec bankCode="SG", **Then** le compte est créé et la réponse contient bankCode="SG", bankName="Société Générale", bankCountry="FR", bankBrandColor="#e2001a".
2. **Given** un compte existant sans banque, **When** l'utilisateur le met à jour avec bankCode="ECOBANK", **Then** le compte est mis à jour avec les informations de la banque Ecobank.
3. **Given** un utilisateur authentifié, **When** il crée un compte avec un bankCode invalide ("INEXISTANT"), **Then** le système refuse la création avec une erreur de validation.

---

### User Story 3 - Utiliser une banque personnalisée (OTHER) (Priority: P2)

En tant qu'utilisateur ayant un compte dans une banque non listée, je veux pouvoir saisir manuellement le nom et le logo de ma banque afin de ne pas être limité à la liste prédéfinie.

**Why this priority**: Cas secondaire mais nécessaire pour la complétude — certains utilisateurs ont des comptes dans des banques non référencées.

**Independent Test**: Peut être testé en créant un compte avec bankCode="OTHER", bankCustomName="Ma Banque" et en vérifiant la réponse.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié, **When** il crée un compte avec bankCode="OTHER" et bankCustomName="Ma Banque Locale", **Then** le compte est créé avec ces valeurs personnalisées.
2. **Given** un utilisateur authentifié, **When** il crée un compte avec bankCode="OTHER" et bankCustomLogo="data:image/png;base64,...", **Then** le logo personnalisé est persisté.
3. **Given** un utilisateur authentifié, **When** il crée un compte avec bankCode="OTHER" sans bankCustomName, **Then** le compte est créé (le nom personnalisé est optionnel).

---

### User Story 4 - Rétrocompatibilité des comptes existants (Priority: P1)

En tant qu'utilisateur existant, je veux que mes comptes actuels continuent de fonctionner normalement après la migration, avec la banque "OTHER" attribuée par défaut.

**Why this priority**: Critique pour éviter toute régression — les données existantes doivent être préservées.

**Independent Test**: Peut être testé en vérifiant qu'après migration, tous les comptes existants ont bankCode="OTHER" et que les champs icone/couleur existants sont toujours présents.

**Acceptance Scenarios**:

1. **Given** des comptes existants en base, **When** la migration Flyway s'exécute, **Then** tous les comptes reçoivent bankCode="OTHER" par défaut.
2. **Given** un compte existant avec icone et couleur, **When** je le consulte après migration, **Then** les champs icone et couleur sont toujours présents et inchangés.
3. **Given** un compte avec bankCode="SG", **When** je le consulte, **Then** la réponse contient à la fois icone/couleur (préservés) et bankName/bankBrandColor (résolus) ; le frontend utilise bankName/bankBrandColor quand bankCode est une banque connue.

---

### Edge Cases

- Que se passe-t-il si bankCode est null dans une requête de création ? Le système utilise "OTHER" par défaut.
- Que se passe-t-il si bankCustomName dépasse 100 caractères ? Le système rejette avec une erreur de validation.
- Que se passe-t-il si bankCustomLogo contient un format non-base64 ? Le système stocke la valeur telle quelle (validation côté frontend uniquement).
- Que se passe-t-il si un utilisateur change bankCode de "SG" vers "OTHER" ? Les champs bankCustomName et bankCustomLogo deviennent utilisables.
- Que se passe-t-il si un utilisateur fournit bankCustomName avec un bankCode connu (non-OTHER) ? Les champs custom sont ignorés à la résolution (la banque connue prévaut).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT fournir un endpoint public GET /api/banks retournant la liste des 29 banques supportées (15 France, 12 Togo/UEMOA, 1 International, 1 OTHER), triée par pays (FR → TG → International → OTHER en dernier) puis par nom alphabétique au sein de chaque groupe.
- **FR-002**: Chaque banque de la liste DOIT contenir un code unique, un nom lisible, un pays d'origine, une couleur brand hexadécimale et une URL de logo (chemin relatif au context path, ex: `/api/bank-logos/SG.svg`).
- **FR-011**: Le backend DOIT servir les fichiers logo des banques connues au format SVG comme ressources statiques (source unique pour Angular et Flutter). Le champ `logoUrl` du BankResponse pointe vers cette ressource.
- **FR-003**: Le système DOIT permettre d'associer un bankCode valide lors de la création ou modification d'un compte.
- **FR-004**: Le système DOIT valider que le bankCode fourni existe dans la liste des banques supportées. En cas de bankCode invalide, le système DOIT retourner une erreur HTTP 400 avec un message explicite (ex: `"Invalid bank code: INEXISTANT"`), cohérent avec le contrat d'erreurs `docs/api-errors.md`.
- **FR-005**: Le système DOIT attribuer bankCode="OTHER" par défaut si aucun bankCode n'est fourni.
- **FR-006**: Le système DOIT accepter les champs bankCustomName (max 100 caractères) et bankCustomLogo (texte libre) lorsque bankCode="OTHER".
- **FR-007**: Le système DOIT résoudre automatiquement bankName, bankCountry et bankBrandColor dans la réponse à partir du bankCode (pour les banques connues).
- **FR-008**: Le système DOIT migrer tous les comptes existants avec bankCode="OTHER" via une migration Flyway.
- **FR-009**: Les champs icone et couleur existants des comptes DOIVENT être préservés en base pour rétrocompatibilité.
- **FR-010**: L'endpoint GET /api/banks et les ressources statiques de logos SVG DOIVENT être accessibles sans authentification (données statiques publiques).

### Key Entities

- **Bank**: Représente une banque supportée par l'application. Attributs : code (identifiant unique), nom, pays (FR/TG/null), couleur brand (hex), URL du logo (ressource statique servie par le backend). Données statiques en mémoire (pas de table en base).
- **Account (enrichi)**: Compte bancaire de l'utilisateur, enrichi avec l'association à une banque. Nouveaux attributs : code banque, nom personnalisé (si OTHER), logo personnalisé (si OTHER).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: La liste des banques est consultable et retourne exactement 29 entrées, chacune avec code, nom, pays et couleur.
- **SC-002**: La création d'un compte avec un bankCode valide fonctionne en une seule requête sans étape supplémentaire.
- **SC-003**: 100% des comptes existants sont migrés avec bankCode="OTHER" sans perte de données.
- **SC-004**: Toute requête avec un bankCode invalide est rejetée avec un message d'erreur explicite.
- **SC-005**: Les réponses de compte contiennent les informations banque résolues (nom, pays, couleur) sans que le client ait besoin de faire un appel supplémentaire.

## Clarifications

### Session 2026-03-13

- Q: Comment les logos des banques connues sont-ils fournis aux frontends (Angular + Flutter) ? → A: Le backend sert les logos comme ressources statiques (classpath Spring Boot). Source unique dans `api/`, les deux frontends consomment la même URL via le champ `logoUrl` du BankResponse.
- Q: Quel format de fichier pour les logos des banques ? → A: SVG (vectoriel, léger, scalable, adapté multi-plateforme Angular + Flutter).
- Q: Les fichiers SVG de logos sont-ils accessibles sans authentification ? → A: Oui, public (données non sensibles, cohérent avec GET /api/banks).

## Assumptions

- Les données des banques sont statiques et gérées en code (pas de table en base) — tout ajout de banque nécessite un déploiement.
- Les logos des banques connues sont servis par le backend comme ressources statiques (fichiers dans le classpath Spring Boot). Les deux frontends (Angular + Flutter) consomment la même URL.
- La validation du format base64 du logo custom n'est pas effectuée côté backend — le frontend est responsable de fournir un format valide.
- Le pays est un code ISO simple (FR, TG) sans validation poussée.
- Les 28 banques identifiées couvrent les besoins actuels de l'utilisateur (France + Togo/UEMOA + International).

## Out of Scope

- Création/design des fichiers logo eux-mêmes (les fichiers SVG/PNG doivent être fournis manuellement ou sourcés).
- UI de sélection de banque (features frontend séparées KKS-164).
- Ajout dynamique de banques via un endpoint d'administration.
- Validation du format d'image du logo custom côté backend.
- Internationalisation des noms de banques.
