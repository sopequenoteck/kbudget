# Feature Specification: Documentation API OpenAPI / Swagger UI

**Feature Branch**: `001-springdoc-openapi`
**Created**: 2026-02-07
**Status**: Draft
**Input**: User description: "Integration springdoc-openapi pour generer automatiquement la documentation OpenAPI 3.1 et Swagger UI depuis le code existant. Ajouter la dependance Maven, configurer la securite pour les routes Swagger, creer une classe OpenApiConfig avec metadata et schema JWT, et annoter les 4 controllers avec @Tag et @Operation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la documentation interactive de l'API (Priority: P1)

En tant que developpeur (ou utilisateur futur du frontend), je veux acceder a une interface web interactive listant tous les endpoints de l'API avec leurs parametres, corps de requete et reponses, afin de comprendre et tester l'API sans lire le code source.

**Why this priority**: C'est la raison d'etre de la feature. Sans interface de documentation accessible, rien d'autre n'a de valeur.

**Independent Test**: Acceder a l'URL de Swagger UI dans un navigateur et voir la liste complete des endpoints organises par domaine fonctionnel.

**Acceptance Scenarios**:

1. **Given** l'application est demarree, **When** je navigue vers l'URL de documentation, **Then** je vois une page interactive listant tous les endpoints de l'API groupes par domaine (Authentification, Transactions, Abonnements, Dettes).
2. **Given** l'application est demarree, **When** je navigue vers l'URL de la specification, **Then** je recois un document structure decrivant l'API au format standard OpenAPI 3.1.
3. **Given** je ne suis pas authentifie, **When** j'accede a l'URL de documentation, **Then** la page s'affiche sans exiger de token JWT.

---

### User Story 2 - Tester un endpoint protege depuis Swagger UI (Priority: P2)

En tant que developpeur, je veux pouvoir saisir un token JWT dans l'interface de documentation puis executer des requetes sur les endpoints proteges, afin de tester l'API sans outil externe (Postman, curl).

**Why this priority**: Swagger UI sans possibilite d'authentification est en lecture seule — on peut lire la doc mais pas tester. Le bouton "Authorize" rend l'outil reellement utile.

**Independent Test**: Cliquer sur le bouton d'autorisation, saisir un JWT valide, puis executer un appel a un endpoint protege et recevoir une reponse 200.

**Acceptance Scenarios**:

1. **Given** je suis sur l'interface de documentation, **When** je clique sur le mecanisme d'autorisation et saisis un JWT valide, **Then** les appels suivants incluent automatiquement le token et retournent les donnees attendues.
2. **Given** je suis sur l'interface de documentation, **When** j'execute un appel a un endpoint protege sans avoir fourni de JWT, **Then** je recois une reponse indiquant que l'authentification est requise.

---

### User Story 3 - Comprendre les champs et contraintes d'un endpoint (Priority: P3)

En tant que developpeur, je veux que chaque endpoint affiche les champs attendus en entree (avec leurs contraintes de validation) et le format de la reponse, afin de construire des requetes correctes du premier coup.

**Why this priority**: La documentation auto-generee depuis le code (records Java, annotations Bean Validation) fournit deja cette information. Cette story s'assure que le rendu est clair et complet.

**Independent Test**: Ouvrir un endpoint dans l'interface et verifier que les champs obligatoires, les types, les tailles maximales et les valeurs possibles des enums sont visibles.

**Acceptance Scenarios**:

1. **Given** je consulte un endpoint de creation, **When** je regarde le schema du corps de requete, **Then** je vois les champs avec leur type, les champs obligatoires marques, les contraintes de validation (taille, positivite) et les valeurs possibles des enums.
2. **Given** je consulte un endpoint, **When** je regarde le schema de reponse, **Then** je vois tous les champs retournes avec leur type.

---

### Edge Cases

- Que se passe-t-il si le serveur demarre sans base de donnees ? La documentation doit rester accessible (elle ne depend pas de la BDD).
- Comment l'interface se comporte-t-elle si un token JWT expire pendant l'utilisation ? L'utilisateur doit voir l'erreur 401 et pouvoir re-saisir un nouveau token.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT exposer une interface web interactive de documentation a une URL publique (sans authentification).
- **FR-002**: Le systeme DOIT exposer la specification OpenAPI 3.1 au format JSON a une URL publique.
- **FR-003**: L'interface de documentation DOIT lister tous les endpoints de l'API groupes par domaine fonctionnel : Authentification, Transactions, Abonnements, Dettes.
- **FR-004**: L'interface de documentation DOIT proposer un mecanisme d'autorisation JWT (type Bearer) pour tester les endpoints proteges.
- **FR-005**: Chaque endpoint DOIT afficher son resume (description courte), la methode HTTP, le chemin, les parametres, le corps de requete et les codes de reponse.
- **FR-006**: Les schemas de requete DOIVENT refleter les contraintes de validation existantes (champs obligatoires, tailles, positivite, enums).
- **FR-007**: Les routes de documentation et de specification DOIVENT etre accessibles sans JWT (routes publiques dans la configuration de securite).
- **FR-008**: La documentation DOIT afficher les metadata du projet : titre, description et version de l'API.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'interface de documentation est accessible dans un navigateur en moins de 2 secondes apres le demarrage de l'application.
- **SC-002**: 100% des endpoints existants (4 controllers, 18 routes) apparaissent dans la documentation generee.
- **SC-003**: Un developpeur peut s'authentifier et executer un appel API protege depuis l'interface en moins d'1 minute.
- **SC-004**: La specification generee est conforme au standard OpenAPI 3.1 (validable par un outil tiers).
- **SC-005**: Aucun test existant ne casse apres l'ajout de la documentation (84 tests passent toujours).

## Assumptions

- La documentation est activee dans tous les profils (dev et prod). L'application etant self-hosted et single-user, il n'y a pas de risque de securite a exposer Swagger UI en production.
- Les descriptions auto-generees depuis les noms de methodes et les records Java sont suffisantes pour les schemas de requete/reponse. Des annotations minimales enrichissent le rendu sans sur-documenter.
- Le format de reponse d'erreur existant (timestamp, status, message) est documente via le GlobalExceptionHandler existant.

## Scope Boundaries

**Inclus** :
- Dependance de documentation API
- Configuration de securite pour les routes publiques de documentation
- Configuration des metadata (titre, description, version) et du schema d'autorisation JWT
- Annotations descriptives sur les 4 controllers (groupement par domaine + resume par endpoint)

**Exclus** :
- Annotations detaillees sur les DTOs (auto-detectes depuis les records Java et Bean Validation)
- Personnalisation du theme de l'interface de documentation
- Export de la specification en fichier statique
- Versionning d'API
