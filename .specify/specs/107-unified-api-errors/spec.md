# Feature Specification: Contrat unifie des erreurs API

**Feature Branch**: `courante (aucun changement de branche autorise)`  
**Created**: 2026-08-18  
**Status**: Draft  
**Input**: Unifier les reponses d'erreur gerees de l'API KBudget sur un contrat JSON commun contenant `error` et `message`, sans modifier les statuts HTTP ni les regles d'authentification.

## Scope

Cette feature couvre toutes les reponses produites par `GlobalExceptionHandler`, les consommateurs Angular qui lisent leur corps, les tests backend et frontend correspondants et la reference `docs/api-errors.md`. Elle remplace le format historique `{ timestamp, status, message }` et le format hybride des conflits par un unique objet `{ error, message }`.

Les mecanismes d'authentification et d'autorisation hors `GlobalExceptionHandler` (filtres, points d'entree Spring Security et decisions d'acces) ne changent pas. Les codes specialises deja exposes dans un `ErrorResponse` restent inchanges. Flutter et les autres clients ne sont pas modifies dans cette feature.

## User Scenarios & Testing

### User Story 1 - Exploiter un contrat d'erreur unique (Priority: P1)

En tant que consommateur de l'API, je recois pour chaque erreur geree par le gestionnaire global un objet JSON de meme forme, afin de pouvoir traiter le code machine et afficher un message sans reconnaitre plusieurs schemas.

**Why this priority**: Le contrat commun est la finalite principale et conditionne la fiabilite de tous les consommateurs.

**Independent Test**: Provoquer un cas representatif de chaque handler global et verifier le statut HTTP, la presence exclusive de chaines non vides `error` et `message`, ainsi que l'absence de `timestamp` et `status` dans le corps.

**Acceptance Scenarios**:

1. **Given** une requete rejetee par la validation des champs, **When** le gestionnaire global construit la reponse, **Then** le statut reste 400 et le corps vaut `{ "error": "VALIDATION_ERROR", "message": "..." }`.
2. **Given** une ressource inexistante traitee par le gestionnaire global, **When** la reponse est retournee, **Then** le statut reste 404 et le corps contient `error = "NOT_FOUND"` et le message metier existant.
3. **Given** un conflit metier sans code specialise reconnu, **When** la reponse est retournee, **Then** le statut reste 409 et le corps contient `error = "CONFLICT"` ainsi que le message metier existant.
4. **Given** un conflit portant le code `LAST_ADMIN_CANNOT_BE_DISABLED` ou `EMAIL_ALREADY_EXISTS`, **When** la reponse est retournee, **Then** le statut reste 409, le code specialise est conserve dans `error` et son message utilisateur stable est conserve.
5. **Given** une exception deja associee a un code specialise, **When** elle est geree, **Then** son statut, son code `error` et son message restent inchanges.

---

### User Story 2 - Proteger les erreurs inattendues (Priority: P1)

En tant qu'utilisateur, je recois une explication generique lorsqu'une erreur serveur inattendue se produit, sans detail technique susceptible de reveler l'implementation.

**Why this priority**: La migration du contrat ne doit pas creer de fuite d'information sur le chemin 500.

**Independent Test**: Declencher une exception non prise en charge et verifier une reponse 500 strictement egale au contrat public attendu, tandis que l'exception peut rester journalisee cote serveur.

**Acceptance Scenarios**:

1. **Given** une exception inattendue contenant un nom de classe, une requete SQL ou une stack trace, **When** le handler generique repond, **Then** le statut reste 500 et le corps vaut `{ "error": "INTERNAL_ERROR", "message": "Une erreur interne est survenue" }` sans detail de l'exception.
2. **Given** une erreur 500, **When** Angular la presente, **Then** aucun detail autre que le message generique public n'est affiche.

---

### User Story 3 - Maintenir le comportement Angular (Priority: P2)

En tant qu'utilisateur Angular, je continue de voir les messages utiles et les parcours specifiques aux codes d'erreur apres l'unification du contrat.

**Why this priority**: Le changement de schema backend ne doit pas casser les formulaires, la gestion des conflits ou les parcours de securite deja pris en charge.

**Independent Test**: Simuler dans les tests Angular des `HttpErrorResponse` au nouveau format pour les cas effectivement consommes, puis verifier les messages et actions obtenus.

**Acceptance Scenarios**:

1. **Given** une erreur metier ou de validation au format unifie, **When** un consommateur Angular en extrait le message, **Then** il utilise `error.error.message` et conserve son fallback actuel si le corps est absent ou invalide.
2. **Given** un code specialise deja interprete par Angular, **When** la reponse migree est recue, **Then** la comparaison via `error.error.error` continue de declencher le meme comportement.
3. **Given** une erreur provenant d'un mecanisme d'authentification hors gestionnaire global, **When** l'intercepteur Angular la recoit, **Then** le flux de rafraichissement, deconnexion ou refus d'acces reste identique.

---

### User Story 4 - Disposer d'une reference exacte (Priority: P2)

En tant que developpeur integrateur, je peux consulter une documentation qui decrit un seul schema, les codes stables et les statuts associes.

**Why this priority**: Un contrat partage n'est durable que si sa reference et ses tests evoluent avec l'implementation.

**Independent Test**: Comparer `docs/api-errors.md` aux handlers et aux tests et verifier que chaque categorie geree est documentee avec son statut et son code.

**Acceptance Scenarios**:

1. **Given** la documentation des erreurs, **When** un integrateur consulte le format standard, **Then** il ne trouve plus le schema historique `timestamp/status/message` ni une distinction de format entre erreurs generales et specialisees.
2. **Given** la matrice des erreurs, **When** un integrateur recherche une categorie geree, **Then** il trouve son statut HTTP inchange, son code stable et la semantique de son message.

### Edge Cases

- Un message d'exception null ou vide ne doit pas produire un champ `message` null ou vide : un libelle public pertinent a la categorie est utilise.
- Une requete JSON illisible reste une erreur 400 avec `MALFORMED_REQUEST` et le message public `Requete invalide`; la cause de deserialisation n'est jamais exposee.
- Plusieurs erreurs Bean Validation restent concatenees selon le format existant `champ: contrainte; ...`; seul le conteneur JSON change.
- Un `ConflictException` dont le message correspond a un code specialise connu conserve ce code et sa traduction publique; toute autre valeur produit le code stable `CONFLICT` et conserve la valeur comme message metier.
- Une ressource absente parce qu'elle n'existe pas ou n'appartient pas a l'utilisateur conserve le meme statut 404 et le meme niveau de discretion.
- Une reponse d'erreur emise directement par Spring Security ou un filtre ne doit pas etre forcee dans `GlobalExceptionHandler`; aucun changement de decision, allowlist, statut ou cycle JWT n'est autorise.
- Les reponses specialisees existantes respectant deja `{ error, message }` ne doivent pas gagner de champs supplementaires ni changer de code.

## Requirements

### Functional Requirements

- **FR-001**: Toute reponse produite par `GlobalExceptionHandler` DOIT utiliser un objet type contenant exactement deux proprietes JSON publiques, `error` et `message`, toutes deux des chaines non vides.
- **FR-002**: Les proprietes historiques `timestamp` et `status` DOIVENT etre retirees des corps produits par `GlobalExceptionHandler`; le statut reste porte par la reponse HTTP.
- **FR-003**: Les statuts HTTP associes a chaque exception DOIVENT rester identiques a ceux anterieurs a cette feature.
- **FR-004**: Les handlers generiques migres DOIVENT utiliser les codes stables suivants : `BAD_REQUEST` pour `IllegalArgumentException` et `IllegalStateException`, `ACCESS_DENIED` pour `AccessDeniedException`, `FEATURE_DISABLED` pour `FeatureDisabledException`, `CSV_PROFILE_NOT_FOUND` pour `CsvProfileNotFoundException`, `NOT_FOUND` pour `EntityNotFoundException`, `MALFORMED_REQUEST` pour `HttpMessageNotReadableException`, `VALIDATION_ERROR` pour `MethodArgumentNotValidException`, `CONFLICT` pour un conflit non specialise et `INTERNAL_ERROR` pour toute exception inattendue.
- **FR-005**: Les codes specialises existants DOIVENT rester inchanges : `INVALID_IMAGE_FORMAT`, `FILE_TOO_LARGE`, `AVATAR_NOT_FOUND`, `PASSWORD_INCORRECT`, `INVALID_EXPORT_FORMAT`, `PASSWORD_UNCHANGED`, `PASSWORD_RESET_NOT_REQUIRED`, `TOKEN_EXPIRED`, `TOKEN_REVOKED`, `TOKEN_REUSE_DETECTED`, `TOKEN_INVALID`, `CONFIRMATION_REQUIRED` et `LAST_ADMIN_DELETION_FORBIDDEN`.
- **FR-006**: Un `ConflictException` portant `LAST_ADMIN_CANNOT_BE_DISABLED` ou `EMAIL_ALREADY_EXISTS` DOIT conserver cette valeur comme code `error`; les autres conflits DOIVENT utiliser `CONFLICT`.
- **FR-007**: Les messages metier et de validation actuellement exposes DOIVENT etre conserves, sauf lorsqu'ils sont absents ou lorsqu'une exigence de securite impose un message public generique.
- **FR-008**: Une erreur de lecture JSON DOIT exposer `MALFORMED_REQUEST` et le message public `Requete invalide`, sans reprendre la cause technique.
- **FR-009**: Une exception inattendue DOIT exposer uniquement `INTERNAL_ERROR` et `Une erreur interne est survenue` dans le corps; son message, sa classe, sa cause et sa stack trace ne DOIVENT pas etre exposes au client.
- **FR-010**: La journalisation serveur existante, y compris la trace complete des exceptions inattendues, PEUT etre conservee et n'est pas soumise au contrat public du corps HTTP.
- **FR-011**: Les regles d'authentification et d'autorisation, les routes publiques, les allowlists, les decisions des filtres JWT et les strategies Angular de refresh/deconnexion NE DOIVENT pas etre modifiees.
- **FR-012**: Les consommateurs Angular affectes DOIVENT lire le message dans `HttpErrorResponse.error.message` et le code dans `HttpErrorResponse.error.error`, avec un fallback utilisateur lorsqu'un corps est absent ou non conforme.
- **FR-013**: Les tests backend DOIVENT couvrir chaque handler migre, verifier le statut inchange, les valeurs `error` et `message`, et l'absence de `timestamp` et `status`.
- **FR-014**: Les tests backend DOIVENT prouver que le handler 500 masque les details internes et que les deux conflits specialises conservent leur code.
- **FR-015**: Les tests frontend DOIVENT etre adaptes pour utiliser le contrat unifie dans tous les consommateurs Angular touches et verifier que les comportements fondes sur les codes specialises ne regressent pas.
- **FR-016**: `docs/api-errors.md` DOIT definir `{ error, message }` comme unique contrat des erreurs gerees, documenter la matrice code/statut et retirer les exemples et interfaces du format historique.
- **FR-017**: Aucun changement de modele persistant, de donnee metier ou de reponse de succes ne DOIT etre introduit.

### Error Contract

- **ApiError**: Reponse JSON d'une erreur geree. `error` est un identifiant machine stable en majuscules et snake case; `message` est une explication publique lisible. Le code HTTP n'est pas duplique dans le corps.
- **Stable error code**: Identifiant dont la valeur et la semantique font partie du contrat public. Un message peut etre affiche ou localise par les clients, mais ne doit pas servir d'identifiant machine.

| Categorie geree | Statut conserve | Code `error` |
|---|---:|---|
| Argument ou etat metier invalide | 400 | `BAD_REQUEST` |
| Corps JSON illisible | 400 | `MALFORMED_REQUEST` |
| Bean Validation | 400 | `VALIDATION_ERROR` |
| Acces refuse par exception geree | 403 | `ACCESS_DENIED` |
| Feature desactivee | 403 | `FEATURE_DISABLED` |
| Entite introuvable | 404 | `NOT_FOUND` |
| Conflit generique | 409 | `CONFLICT` |
| Profil CSV introuvable | 422 | `CSV_PROFILE_NOT_FOUND` |
| Exception inattendue | 500 | `INTERNAL_ERROR` |
| Exceptions specialisees existantes | statut existant | code existant conserve |

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100 % des branches de `GlobalExceptionHandler` couvertes par les tests retournent exactement les proprietes publiques `error` et `message`, sans `timestamp` ni `status` dans le corps.
- **SC-002**: 100 % des statuts HTTP verifies avant et apres migration restent identiques pour les memes categories d'exception.
- **SC-003**: 100 % des codes specialises existants et des deux conflits specialises conservent leur valeur et leur comportement Angular.
- **SC-004**: Les tests backend prouvent qu'aucun detail interne injecte dans une exception inattendue n'apparait dans la reponse 500.
- **SC-005**: Tous les tests backend cibles et tests Angular affectes reussissent avec le nouveau contrat.
- **SC-006**: `docs/api-errors.md` ne contient plus d'exemple ou d'interface presentant `timestamp/status/message` comme corps d'erreur gere et documente tous les codes generiques de FR-004.

## Assumptions

- Le perimetre « erreurs gerees » designe les reponses construites par `GlobalExceptionHandler`; les reponses produites ailleurs ne sont incluses que si elles respectent deja `{ error, message }` et doivent rester compatibles.
- `ErrorResponse` demeure le contrat commun et peut etre reutilise par tous les handlers.
- Les messages metier existants restent une aide lisible, tandis que `error` devient le seul discriminant machine stable.
- Aucun consommateur Flutter connu ne depend des champs historiques; sa modification reste hors scope conformement a l'objectif qui cite Angular.

## Dependencies and Risks

- Certains messages de `IllegalArgumentException`, `IllegalStateException`, `EntityNotFoundException` et conflits generiques proviennent directement des services; leur contenu reste potentiellement variable meme si leur code machine devient stable.
- Les erreurs emises avant le controleur par Spring Security peuvent avoir un corps vide ou distinct. Elles sont hors du gestionnaire global et l'unification totale de ces chemins demanderait une feature separee pour ne pas modifier l'authentification.
- Des consommateurs non inventories ou des versions clientes anciennes peuvent encore lire `timestamp` ou `status`; la suppression est un changement de contrat assumé et doit etre annoncee via la documentation.
- La coexistence temporaire de versions backend/frontend lors d'un deploiement peut exposer l'ancien corps au nouveau client ou inversement; les fallbacks Angular reduisent ce risque sans reintroduire l'ancien contrat.
