# Tasks: Contrat unifie des erreurs API

**Input**: `spec.md` et `plan.md` dans `.specify/specs/107-unified-api-errors/`
**Prerequisites**: specification et plan valides; aucun changement de branche, de persistance ou de dependance
**Tests**: tests backend obligatoires pour chaque handler migre et tests frontend pour chaque consommateur Angular affecte
**Scope**: `GlobalExceptionHandler`, `ErrorResponse`, consommateurs Angular affectes, tests associes et `docs/api-errors.md`; authentification, Flutter, persistance et reponses de succes exclus

## Phase 1 — Inventaire et garde-fous

**But**: figer les comportements existants et identifier les seuls fichiers affectes avant toute implementation.

- [ ] [T-001] Inventorier dans `api/src/main/java/fr/kksdev/budget/api/config/GlobalExceptionHandler.java` chaque handler, son statut HTTP actuel, son message et son eventuel code specialise afin de constituer la reference de non-regression — Ref: FR-003
- [ ] [T-002] Rechercher sous `app/src/app/` tous les lecteurs du corps de `HttpErrorResponse` et leurs tests colocalises, en excluant Flutter et les reponses hors du gestionnaire global — Ref: FR-012
- [ ] [T-003] Etablir par revue du diff une liste de garde des filtres JWT, points d'entree Spring Security, allowlists, routes publiques et strategies Angular de refresh ou deconnexion qui ne doivent recevoir aucun changement — Ref: FR-011
- [ ] [T-004] Identifier les modeles persistants, migrations, donnees metier et reponses de succes situes a proximite des fichiers affectes afin de verifier leur absence du diff final — Ref: FR-017

**Checkpoint**: les statuts historiques, handlers, lecteurs Angular et frontieres hors perimetre sont connus.

## Phase 2 — Tests du contrat backend unifie

**But**: definir les attentes executables avant la migration du gestionnaire global.

- [ ] [T-005] Etendre `api/src/test/java/fr/kksdev/budget/api/config/GlobalExceptionHandlerTest.java` pour verifier sur chaque handler que le corps serialise contient exactement deux chaines non vides nommees `error` et `message` — Ref: FR-001
- [ ] [T-006] Ajouter aux tests de chaque handler des assertions d'absence des proprietes `timestamp` et `status`, le statut demeurant exclusivement dans la reponse HTTP — Ref: FR-002
- [ ] [T-007] Ajouter des tests parametres couvrant les neuf codes generiques `BAD_REQUEST`, `ACCESS_DENIED`, `FEATURE_DISABLED`, `CSV_PROFILE_NOT_FOUND`, `NOT_FOUND`, `MALFORMED_REQUEST`, `VALIDATION_ERROR`, `CONFLICT` et `INTERNAL_ERROR` — Ref: FR-004
- [ ] [T-008] Completer les tests pour les treize codes specialises existants en verifiant pour chacun le code, le message, le statut et la forme exacte du corps — Ref: FR-005
- [ ] [T-009] Tester `LAST_ADMIN_CANNOT_BE_DISABLED`, `EMAIL_ALREADY_EXISTS`, un conflit generique et des conflits a message null ou blanc afin de distinguer les codes specialises du fallback `CONFLICT` — Ref: FR-006
- [ ] [T-010] Tester la conservation des messages metier et de validation non vides, la concatenation Bean Validation et les fallbacks publics des messages null ou blancs — Ref: FR-007
- [ ] [T-011] Tester qu'un corps JSON illisible retourne le statut 400, le code `MALFORMED_REQUEST` et le message exact `Requete invalide` sans texte de la cause de deserialisation — Ref: FR-008
- [ ] [T-012] Tester une exception inattendue contenant des marqueurs de classe, SQL, cause et stack trace, puis verifier le corps exact `INTERNAL_ERROR` et `Une erreur interne est survenue` sans aucun marqueur injecte — Ref: FR-009
- [ ] [T-013] Verifier par test ou capture de logs que la trace complete de l'exception inattendue reste journalisee cote serveur sans entrer dans le corps HTTP public — Ref: FR-010
- [ ] [T-014] Couvrir chaque methode du gestionnaire global avec son statut inchange, ses valeurs `error` et `message` et l'absence des champs historiques — Ref: FR-013
- [ ] [T-015] Ajouter une preuve ciblee du masquage du handler 500 et de la conservation des deux codes de conflit specialises — Ref: FR-014

**Checkpoint**: les tests backend expriment le contrat public, les statuts historiques, les cas limites et les garanties de securite.

## Phase 3 — Implementation backend

**But**: faire de `ErrorResponse` l'unique corps construit par `GlobalExceptionHandler`.

- [ ] [T-016] Modifier toutes les branches de `api/src/main/java/fr/kksdev/budget/api/config/GlobalExceptionHandler.java` pour retourner `ResponseEntity<ErrorResponse>` en reutilisant `api/src/main/java/fr/kksdev/budget/api/dto/response/ErrorResponse.java` — Ref: FR-001
- [ ] [T-017] Supprimer du gestionnaire global la construction historique par `Map`, `LocalDateTime`, `timestamp` et `status`, ainsi que les imports devenus inutiles — Ref: FR-002
- [ ] [T-018] Affecter a chaque exception generique le code stable specifie sans modifier le statut HTTP actuellement associe a son handler — Ref: FR-004
- [ ] [T-019] Conserver sans alteration les codes, messages et statuts des exceptions specialisees deja representees par `ErrorResponse` — Ref: FR-005
- [ ] [T-020] Mapper les deux conflits connus vers leur propre code et traduction publique, puis mapper tout autre conflit vers `CONFLICT` avec son message metier ou un fallback public non vide — Ref: FR-006
- [ ] [T-021] Ajouter une normalisation minimale des messages null ou blancs par categorie tout en preservant tout message metier ou de validation public non vide — Ref: FR-007
- [ ] [T-022] Construire la reponse de lecture JSON uniquement avec `MALFORMED_REQUEST` et `Requete invalide`, sans consulter la cause technique pour le contenu public — Ref: FR-008
- [ ] [T-023] Construire le corps 500 exclusivement depuis les constantes publiques `INTERNAL_ERROR` et `Une erreur interne est survenue` — Ref: FR-009
- [ ] [T-024] Conserver la journalisation serveur existante de l'exception inattendue avec sa trace complete — Ref: FR-010

**Checkpoint**: chaque branche du gestionnaire global produit uniquement `{ error, message }`, avec statut inchange et sans fuite sur le chemin 500.

## Phase 4 — Consommateurs et tests Angular

**But**: maintenir les messages, fallbacks et parcours bases sur les codes avec le nouveau corps.

- [ ] [T-025] Adapter uniquement les consommateurs inventories pour lire defensivement le message dans `HttpErrorResponse.error.message` et le code dans `HttpErrorResponse.error.error`, en conservant le fallback utilisateur actuel pour un corps absent ou invalide — Ref: FR-012
- [ ] [T-026] Mettre a jour les tests Vitest colocalises de chaque consommateur modifie avec des fixtures `{ error, message }`, puis couvrir message valide, corps absent, corps mal forme et fallback — Ref: FR-015
- [ ] [T-027] Ajouter aux tests Angular les codes specialises effectivement interpretes afin de prouver que leurs actions utilisateur ne regressent pas apres migration — Ref: FR-015
- [ ] [T-028] Rejouer les tests 401 et 403 existants et confirmer sans modifier l'intercepteur que refresh, deconnexion, refus d'acces, routes publiques et decisions JWT restent identiques — Ref: FR-011
- [ ] [T-029] Ajouter un cas Angular 500 prouvant que seul le message public generique est affiche et qu'aucun detail interne simule n'atteint l'interface — Ref: FR-015

**Checkpoint**: les lecteurs Angular utilisent le contrat unifie, leurs fallbacks restent robustes et le cycle d'authentification est intact.

## Phase 5 — Documentation normative

**But**: faire de `docs/api-errors.md` la reference exacte du contrat public.

- [ ] [T-030] Reecrire `docs/api-errors.md` autour de l'unique type public `ApiError` contenant `error` et `message`, preciser que le statut reste HTTP et retirer les exemples ou interfaces du format historique — Ref: FR-016
- [ ] [T-031] Ajouter a `docs/api-errors.md` une matrice categorie, statut et code couvrant les neuf codes generiques, les deux conflits specialises et les treize codes specialises avec la semantique publique des messages — Ref: FR-016
- [ ] [T-032] Documenter la frontiere du contrat entre les reponses de `GlobalExceptionHandler` et les erreurs emises directement par Spring Security ou les filtres, sans promettre de changement d'authentification — Ref: FR-011

**Checkpoint**: la documentation decrit un schema unique, tous les codes stables, leurs statuts et la frontiere de securite.

## Phase 6 — Validation transversale

**But**: prouver la conformite complete et l'absence d'elargissement du perimetre.

- [ ] [T-033] Executer `cd api && ./mvnw -Dtest=GlobalExceptionHandlerTest test` et corriger uniquement les regressions du contrat jusqu'a couvrir tous les handlers migres — Ref: FR-013
- [ ] [T-034] Executer `cd api && ./mvnw test` et comparer les statuts observes a l'inventaire initial afin de confirmer leur invariance — Ref: FR-003
- [ ] [T-035] Executer sous `app/` la suite Vitest affectee puis la suite frontend complete, le lint et le controle de format jusqu'a obtenir des validations vertes — Ref: FR-015
- [ ] [T-036] Rechercher dans `docs/api-errors.md` les representations historiques et verifier la presence de tous les codes generiques et specialises documentes — Ref: FR-016
- [ ] [T-037] Examiner le diff final pour confirmer l'absence de modification des filtres, allowlists, configurations de securite, strategies JWT, fichiers Flutter, modeles persistants, migrations et reponses de succes — Ref: FR-017
- [ ] [T-038] Verifier dans les resultats backend que chaque statut historique est conserve et qu'aucun champ HTTP `status` n'est duplique dans le corps JSON — Ref: FR-003

**Checkpoint final**: suites ciblees et completes vertes, documentation concordante, contrat exact et frontieres fonctionnelles preservees.

## Dependances et ordre d'execution

1. La Phase 1 precede toute modification et fixe l'inventaire de reference.
2. La Phase 2 definit les attentes avant la Phase 3; les tests de codes generiques, specialises et de securite peuvent etre prepares independamment.
3. La Phase 4 commence une fois les codes et la representation backend stabilises.
4. La Phase 5 peut avancer en parallele de la Phase 4 apres confirmation de la matrice backend.
5. La Phase 6 attend toutes les phases d'implementation, de tests et de documentation.

## Strategie de livraison

1. Livrer d'abord le socle backend testable: forme exacte, codes stables, statuts inchanges et masquage 500.
2. Adapter ensuite les seuls lecteurs Angular inventories et verifier leurs fallbacks et branches specialisees.
3. Synchroniser la documentation normative avec les constantes et statuts verifies.
4. Terminer par les suites completes et une revue stricte du perimetre.

## Risques et blocages restants

- **Clients externes non inventories**: des versions hors depot peuvent encore lire `timestamp` ou `status`; le changement de contrat doit etre annonce et surveille au deploiement.
- **Coexistence temporaire de versions**: un ancien backend et un nouveau frontend peuvent coexister; les fallbacks Angular limitent l'impact sans restaurer l'ancien contrat.
- **Messages metier variables**: certains textes issus des services restent variables; les consommateurs doivent traiter le code comme seul identifiant machine stable.
- **Erreurs de securite hors gestionnaire**: elles peuvent conserver un corps vide ou distinct; leur unification releve d'une feature separee pour ne pas modifier l'authentification.
- **Blocage actuel**: aucun blocage identifie pour demarrer l'implementation.

## Matrice de couverture

| Exigence | Taches |
|---|---|
| FR-001 | T-005, T-016 |
| FR-002 | T-006, T-017 |
| FR-003 | T-001, T-034, T-038 |
| FR-004 | T-007, T-018 |
| FR-005 | T-008, T-019 |
| FR-006 | T-009, T-020 |
| FR-007 | T-010, T-021 |
| FR-008 | T-011, T-022 |
| FR-009 | T-012, T-023 |
| FR-010 | T-013, T-024 |
| FR-011 | T-003, T-028, T-032 |
| FR-012 | T-002, T-025 |
| FR-013 | T-014, T-033 |
| FR-014 | T-015 |
| FR-015 | T-026, T-027, T-029, T-035 |
| FR-016 | T-030, T-031, T-036 |
| FR-017 | T-004, T-037 |
