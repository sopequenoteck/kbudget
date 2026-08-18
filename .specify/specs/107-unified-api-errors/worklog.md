# Worklog — DEMO-006

<!-- devflow:worklog:start -->

## Objectif

Unifier les réponses d’erreur gérées de l’API KBudget sur un contrat JSON commun contenant error et message. Remplacer le format historique timestamp/status/message produit par GlobalExceptionHandler, attribuer des codes d’erreur stables aux cas concernés, adapter les consommateurs Angular si nécessaire, mettre à jour les tests backend et frontend ainsi que docs/api-errors.md. Conserver les statuts HTTP existants, ne pas modifier les règles d’authentification et ne pas exposer de détails internes dans les erreurs 500.

## Évaluation

- Profil recommandé : `deep`
- Profil sélectionné : `deep`
- Signaux : `{"ambiguity": "medium", "contractChange": true, "dataOrSecurity": false, "risk": "medium", "scope": "transversal"}`
- Raison : le changement est transversal
- Raison : des contrats partages sont modifies

## Progression

- Statut : `completed`
- Activité courante : `done`
- Activités terminées : `assess`, `spec`, `plan`, `tasks`, `implement`, `verify`, `review`, `done`

## Modifications

- Contrat d’erreur unifié implémenté pour GlobalExceptionHandler avec les champs error et message, codes stables, statuts HTTP préservés, conflits spécialisés conservés, fallbacks non vides et erreurs 500 sans détails internes. Les consommateurs Angular étaient déjà compatibles. Documentation et tests backend mis à jour.
- `api/src/main/java/fr/kksdev/budget/api/config/GlobalExceptionHandler.java`
- `api/src/test/java/fr/kksdev/budget/api/config/GlobalExceptionHandlerTest.java`
- `docs/api-errors.md`

## Vérifications

- `test-suite` : **passed**
- `diff-inspection` : **passed**
  - `./mvnw -q -Dtest=GlobalExceptionHandlerTest test` → code `0`
  - `./mvnw -q verify` → code `0`
  - `./mvnw -Dtest=GlobalExceptionHandlerTest test` → code `0`
  - `./mvnw test` → code `0`
  - `npm test -- --run` → code `0`
  - `npm run lint` → code `0`
  - `npm run format:check` → code `1` (non bloquant)
  - `rg -n BAD_REQUEST|ACCESS_DENIED|FEATURE_DISABLED|CSV_PROFILE_NOT_FOUND|NOT_FOUND|MALFORMED_REQUEST|VALIDATION_ERROR|CONFLICT|INTERNAL_ERROR docs/api-errors.md` → code `0`
- `requirements-coverage` : **passed**

## Risques restants

- Les clients externes au dépôt qui consomment encore timestamp ou status devront migrer vers error et message.
- Le contrôle Prettier global reste rouge sur 144 fichiers frontend préexistants non modifiés par cette activité.
- La nouvelle exécution Maven pendant la review n’a pas pu écrire dans api/target à cause de la sandbox en lecture seule; la revue repose donc aussi sur la preuve test-suite enregistrée, qui rapporte les suites Maven réussies.

## Résumé

Workflow terminé avec toutes les preuves requises.

<!-- devflow:worklog:end -->

## Notes manuelles

_Ajoutez ici vos observations._
