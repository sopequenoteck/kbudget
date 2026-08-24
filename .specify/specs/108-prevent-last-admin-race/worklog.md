# Worklog — DEMO-007

<!-- devflow:worklog:start -->

## Objectif

La suppression d’un compte administrateur vérifie actuellement le nombre d’administrateurs actifs avant de désactiver le compte, sans sérialisation apparente entre les transactions. Deux administrateurs supprimant simultanément leur compte peuvent chacun observer deux administrateurs actifs puis être tous les deux désactivés, laissant l’instance sans administrateur. Rendre cette invariant atomique au niveau transactionnel ou base de données. Ajouter un test d’intégration concurrent exécutant deux suppressions simultanées et vérifier qu’une seule réussit, que l’autre reçoit LAST_ADMIN_DELETION_FORBIDDEN, qu’il reste exactement un administrateur actif et que les refresh tokens du compte dont la suppression est refusée restent valides. Conserver les statuts HTTP et contrats d’erreur existants.

## Évaluation

- Profil recommandé : `critical`
- Profil sélectionné : `critical`
- Signaux : `{"ambiguity": "medium", "contractChange": false, "dataOrSecurity": true, "risk": "high", "scope": "multiple"}`
- Raison : le changement touche aux donnees ou a la securite

## Progression

- Statut : `completed`
- Activité courante : `done`
- Activités terminées : `assess`, `risk-assessment`, `spec`, `research`, `contracts`, `plan`, `tasks`, `implement`, `verify`, `review`, `rollback-check`, `done`

## Modifications

- Implémentation cohérente après remédiation : verrou transactionnel PostgreSQL commun aux mutations d’administrateurs, relecture protégée avant suppression, préservation des refresh tokens lors du refus et test concurrent couvrant le résultat métier. Une preuve mutationnelle synchronisée démontre désormais déterministement la course de l’ancienne logique.
- `api/pom.xml`
- `api/src/main/java/fr/kksdev/budget/api/runner/AdminSyncRunner.java`
- `api/src/main/java/fr/kksdev/budget/api/service/ActiveAdminInvariantLock.java`
- `api/src/main/java/fr/kksdev/budget/api/service/AdminUserService.java`
- `api/src/main/java/fr/kksdev/budget/api/service/UserDeletionService.java`
- `api/src/main/java/fr/kksdev/budget/api/service/UserOnboardingService.java`
- `api/src/test/java/fr/kksdev/budget/api/controller/UserDeletionConcurrencyIT.java`
- `api/src/test/java/fr/kksdev/budget/api/service/UserDeletionRollbackIT.java`
- `api/src/test/java/fr/kksdev/budget/api/runner/AdminSyncRunnerTest.java`
- `api/src/test/java/fr/kksdev/budget/api/service/AdminUserServiceTest.java`
- `api/src/test/java/fr/kksdev/budget/api/service/UserDeletionServiceTest.java`

## Vérifications

- `test-suite` : **passed**
- `diff-inspection` : **passed**
  - `./mvnw -q -Dtest=AdminSyncRunnerTest,AdminUserServiceTest,UserDeletionConcurrencyIT,UserDeletionServiceTest test` → code `0`
  - `./mvnw -q verify` → code `0`
  - `./mvnw -Dtest=ActiveAdminInvariantLockTest,UserDeletionServiceTest,AdminSyncRunnerTest test` → code `0`
  - `./mvnw verify` → code `0`
  - `rg -n setAdmin\(|setDisabledAt\(|is_admin|disabled_at src/main/java src/main/resources` → code `0`
- `requirements-coverage` : **passed**
- `security-or-data-check` : **passed**
  - `./mvnw -Dtest=UserDeletionConcurrencyIT verify` → code `0`
  - `./mvnw -Dtest=UserControllerTest,GlobalExceptionHandlerTest,UserDeletionServiceTest test` → code `0`
  - `rg -n pg_advisory_xact_lock|CREATE TABLE|ALTER TABLE src/main/java src/main/resources/db/migration` → code `0`
- `independent-review` : **passed**
- `rollback-plan` : **passed**

## Risques restants

- La fiabilité du confinement dépend de l’inventaire et de la suspension effective de tous les écrivains applicatifs, DBA et externes.
- Le retour vers N-1 réintroduit la vulnérabilité et interdit la reprise normale des mutations d’administrateurs jusqu’au redéploiement intégral d’une version protégée.
- La récupération d’une instance déjà dépourvue d’administrateur reste hors périmètre et nécessite une procédure auditée séparée.
- Les seuils opérationnels de contention, deadlock, timeout et 5xx doivent être approuvés avant production.
- Les avertissements Git liés à l’impossibilité de créer le cache xcrun dans /tmp n’ont pas empêché les contrôles, tous terminés avec le code 0.

## Résumé

Workflow terminé avec toutes les preuves requises.

<!-- devflow:worklog:end -->

## Notes manuelles

_Ajoutez ici vos observations._
