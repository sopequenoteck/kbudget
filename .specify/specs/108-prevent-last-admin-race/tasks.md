# Tasks: Suppression atomique du dernier administrateur

**Issue**: `DEMO-007` | **Profil**: `critical` | **Entrées**: `spec.md`, `contracts.md`, `plan.md`, `assessment.json`, `workflow-state.json`

**Objectif**: Sérialiser toutes les décisions modifiant l’ensemble des administrateurs actifs, préserver les contrats HTTP et l’état des tokens en cas de refus, puis le prouver par un test d’intégration PostgreSQL réellement concurrent.

**Format obligatoire**: chaque tâche est non démarrée, possède un identifiant unique `[T-XXX]` et référence directement une exigence fonctionnelle.

## Phase 0 — Gates, inventaire et baseline

- [ ] [T-001] Confirmer dans `docker-compose-dev.yml` PostgreSQL 16, vérifier localement `READ COMMITTED` et `pg_advisory_xact_lock`, puis réserver et documenter la clé globale; conserver la validation de la version de production et l’approbation Backend/DBA comme gates de déploiement — Ref: FR-003
- [ ] [T-002] Exécuter et consigner la baseline des tests de suppression, authentification, refresh tokens et gestion des erreurs avant toute modification afin de détecter toute dérive de contrat — Ref: FR-014
- [ ] [T-003] Inventorier dans le dépôt tous les chemins de création, promotion, rétrogradation, réactivation et désactivation d’administrateurs avec leur frontière transactionnelle; consigner l’inventaire opérationnel des SQL directs et services externes comme gate de déploiement — Ref: FR-021
- [ ] [T-004] Confirmer Docker localement et pinner une image Testcontainers PostgreSQL 16, sans H2 ni repository simulé pour la preuve concurrente; conserver l’exécution en CI comme gate de déploiement — Ref: FR-019
- [ ] [T-005] Définir des timeouts de test bornés, un ordre de verrouillage unique et les métriques attendues; conserver l’approbation SRE des seuils de contention, deadlocks, latence et 5xx comme gate de production — Ref: FR-022

**Checkpoint**: l’implémentation locale commence après vérification du PostgreSQL 16 déclaré, de l’advisory lock et de Docker local. La mise en production reste interdite sans validation de la version réelle, exécution CI, inventaire opérationnel et approbations Backend/DBA/SRE.

## Phase 1 — Primitive transactionnelle commune

- [ ] [T-006] Créer `ActiveAdminInvariantLock` avec une constante `long` globale documentée et une requête native `SELECT pg_advisory_xact_lock(?1)` protégeant la ressource logique commune à toutes les mutations d’administrateurs actifs — Ref: FR-003
- [ ] [T-007] Faire échouer explicitement l’acquisition hors transaction et vérifier que le verrou, le rechargement, le décompte, la décision et les écritures utilisent la transaction Spring et la même connexion — Ref: FR-002
- [ ] [T-008] Ajouter un test PostgreSQL à deux transactions indépendantes démontrant que la seconde acquisition attend puis progresse uniquement après le commit ou le rollback de la première — Ref: FR-001
- [ ] [T-009] Tester que toute transaction ayant attendu le verrou recharge l’utilisateur et exécute `countActiveAdmins()` après l’acquisition, sans réutiliser un utilisateur ou un décompte obsolète — Ref: FR-004

**Checkpoint**: une ressource stable unique sérialise les transactions, se libère à leur fin et ne possède aucun fallback JVM silencieux.

## Phase 2 — Suppression atomique et contrats existants

- [ ] [T-010] Intégrer le verrou commun dans `UserDeletionService.softDelete` après les validations existantes et avant toute lecture ou mutation participant à la garde du dernier administrateur — Ref: FR-013
- [ ] [T-011] Recharger sous protection l’état persistant du compte, recompter les administrateurs actifs et lever l’exception métier existante avant toute écriture lorsque le compte est encore administrateur et que le cardinal est inférieur ou égal à un — Ref: FR-001
- [ ] [T-012] Conserver la désactivation du compte et la révocation de ses refresh tokens dans la transaction protégée qui porte la décision de suppression — Ref: FR-012
- [ ] [T-013] Ajouter un test de rollback injectant une erreur de révocation et vérifiant que compte, rôle, tokens et effets secondaires reviennent intégralement à leur état antérieur — Ref: FR-009
- [ ] [T-014] Vérifier que le refus du dernier administrateur conserve exactement le statut 403, le code `LAST_ADMIN_DELETION_FORBIDDEN` et le message public existant sans détail PostgreSQL — Ref: FR-007
- [ ] [T-015] Vérifier que la suppression autorisée conserve exactement le statut 204 et tous les effets métier existants — Ref: FR-008
- [ ] [T-016] Ajouter des tests garantissant que les confirmations, mot de passe, authentification et autorisation conservent leur ordre observable et leurs réponses avant l’acquisition du verrou — Ref: FR-013
- [ ] [T-017] Tester qu’un timeout, deadlock ou échec technique suit le traitement d’erreur existant, n’est jamais maquillé en refus métier ou succès et ne produit aucune mutation partielle — Ref: FR-014

**Checkpoint**: le chemin nominal et le refus public restent inchangés; aucun état de compte ou de token ne survit à un refus ou rollback.

## Phase 3 — Adoption par tous les écrivains et observabilité

- [ ] [T-018] Faire acquérir le verrou commun dans `UserOnboardingService` avant toute création avec `isAdmin=true`, sans modifier le chemin non administrateur — Ref: FR-021
- [ ] [T-019] Faire acquérir une fois le verrou commun dans la transaction de `AdminSyncRunner` avant ses promotions et ajouter les tests d’interaction correspondants — Ref: FR-021
- [ ] [T-020] Traiter chaque autre écrivain découvert par l’inventaire en lui imposant le même protocole ou en documentant et faisant revoir une preuve de non-conflit concurrent — Ref: FR-021
- [ ] [T-021] Différer toute journalisation de succès jusqu’après commit et distinguer commit, refus métier, timeout et rollback dans les logs et métriques sans jamais enregistrer access token ni refresh token — Ref: FR-025

**Checkpoint**: aucune mutation applicative ou opérationnelle connue ne peut réduire ou modifier l’ensemble protégé sans coordination commune.

## Phase 4 — Test d’intégration HTTP concurrent déterministe

- [ ] [T-022] Configurer le test d’intégration avec Testcontainers PostgreSQL, migrations réelles, serveur sur port aléatoire, données nettoyées hors transaction englobante et bootstrap administrateur neutralisé — Ref: FR-019
- [ ] [T-023] Créer exactement deux administrateurs actifs avec credentials et refresh token distinct valide, puis préparer deux requêtes `DELETE /users/me` sur deux connexions serveur indépendantes — Ref: FR-015
- [ ] [T-024] Synchroniser les deux workers avec une barrière explicite, borner toutes les attentes et libérer les ressources en `finally`, sans utiliser de délai arbitraire comme mécanisme de concurrence — Ref: FR-020
- [ ] [T-025] Ajouter un hook test-only ou une preuve mutationnelle revue qui force l’interleaving vulnérable et démontre de manière reproductible que l’ancienne logique permettrait deux désactivations — Ref: FR-020
- [ ] [T-026] Exécuter simultanément les deux suppressions et vérifier par cardinalité qu’une seule réponse est un succès et qu’une seule est un refus — Ref: FR-005
- [ ] [T-027] Vérifier exactement une réponse 204 et une réponse 403 dont le code et le message sont `LAST_ADMIN_DELETION_FORBIDDEN` et le message public existant — Ref: FR-016
- [ ] [T-028] Relire l’état depuis une nouvelle transaction après les deux commits et vérifier qu’exactement un administrateur actif subsiste — Ref: FR-006
- [ ] [T-029] Identifier le compte refusé à partir des réponses observées, vérifier qu’il reste actif avec son rôle, puis réussir un vrai `POST /auth/refresh` avec son token émis avant la course — Ref: FR-017
- [ ] [T-030] Vérifier directement que tous les refresh tokens du compte refusé conservent leur état antérieur après la course — Ref: FR-010
- [ ] [T-031] Identifier le compte supprimé, vérifier sa désactivation et confirmer par un vrai refresh que son token suit toujours la révocation existante — Ref: FR-018
- [ ] [T-032] Vérifier dans les tests de service et d’intégration que les refresh tokens d’une suppression réussie sont révoqués selon le comportement antérieur — Ref: FR-011
- [ ] [T-033] Répéter le scénario un nombre borné de fois en alternant l’ordre de soumission et vérifier à chaque exécution un succès, un refus et un seul administrateur actif — Ref: FR-005

**Checkpoint**: la preuve échoue sur la logique vulnérable et réussit sur PostgreSQL compatible production avec deux connexions, des commits indépendants et les oracles HTTP, données et tokens complets.

## Phase 5 — Compatibilité, déploiement et preuves critical

- [ ] [T-034] Confirmer qu’aucune migration n’est requise pour l’advisory lock et démontrer que les versions N et N-1 ne coexistent jamais avec les mutations administrateur ouvertes; sinon bloquer le rollout et replanifier une protection enforceée en base — Ref: FR-024
- [ ] [T-035] Si le gate PostgreSQL impose une sentinelle ou une migration, concevoir une migration additive précédée d’un contrôle des données, compatible N/N-1 et réversible sans retirer prématurément la protection — Ref: FR-023
- [ ] [T-036] Exécuter avant déploiement une lecture confirmant au moins un administrateur actif par instance et suspendre les mutations administrateur pendant tout remplacement ou rollback impliquant une version vulnérable — Ref: FR-001
- [ ] [T-037] Exécuter les tests ciblés puis toute la suite Maven et archiver la preuve `test-suite` montrant l’absence de régression des statuts, corps d’erreur, comptes et tokens — Ref: FR-014
- [ ] [T-038] Produire la preuve `requirements-coverage` reliant FR-001 à FR-025 aux changements, tests et résultats sans exigence orpheline — Ref: FR-001
- [ ] [T-039] Produire la preuve `security-or-data-check` couvrant invariant après commit, connexion unique, rollback intégral, absence de fuite de secret et traitement des erreurs techniques — Ref: FR-012
- [ ] [T-040] Produire la preuve `rollback-plan` interdisant le retour à N-1 avec mutations ouvertes et décrivant confinement, contrôles d’état et réexécution des validations — Ref: FR-024
- [ ] [T-041] Obtenir la preuve `independent-review` Backend/DBA/Sécurité sur la clé, l’isolation, tous les écrivains, l’ordre des verrous, la contention et les procédures opérationnelles — Ref: FR-022

## Dépendances et ordre d’exécution

La phase 0 bloque la phase 1. La phase 1 bloque l’intégration dans les phases 2 et 3. Les phases 2 et 3 doivent être terminées avant la preuve concurrente de phase 4. La phase 5 n’est déclarée terminée qu’après succès des suites et production des cinq preuves du profil `critical`. Les tâches portant sur `UserOnboardingService` et `AdminSyncRunner` peuvent être menées en parallèle après stabilisation de `ActiveAdminInvariantLock`; les assertions HTTP, données et tokens du test concurrent peuvent être préparées en parallèle, mais s’exécutent dans un scénario unique.

## Risques et blocages restants

- PostgreSQL 16, `READ COMMITTED`, l’advisory lock et la clé doivent être vérifiés localement; la version réelle et l’approbation Backend/DBA restent des gates de déploiement et leur refus impose une nouvelle conception.
- Docker/Testcontainers avec PostgreSQL 16 doit fournir la preuve locale; son absence en CI bloque le déploiement, sans empêcher l’implémentation et la vérification locales.
- Le mécanisme déterministe démontrant l’échec de l’ancienne implémentation reste à choisir et faire revoir; une simple répétition ou des `sleep` ne lève pas FR-020.
- Les écrivains SQL, DBA ou services externes absents du dépôt peuvent contourner le verrou jusqu’à achèvement de l’inventaire opérationnel.
- La coexistence N/N-1 demeure dangereuse sans suspension techniquement démontrée des mutations; aucun rolling deploy mixte ne doit être autorisé avant levée de ce gate.
- Les seuils SRE de contention, timeout, deadlock et latence restent à approuver avant production.
- Une instance déjà sans administrateur n’est pas réparée par cette feature; sa récupération reste une procédure auditée hors périmètre.

## Critères de clôture

Toutes les tâches locales applicables sont achevées; chaque exigence FR-001 à FR-025 dispose d’au moins une tâche et d’une preuve; le test PostgreSQL concurrent déterministe observe exactement `1×204`, `1×403 LAST_ADMIN_DELETION_FORBIDDEN` et un administrateur actif; le compte refusé et ses tokens sont inchangés; le compte supprimé et ses tokens conservent leur comportement existant; la suite backend est verte et les cinq preuves `critical` sont produites. Les gates Backend/DBA, CI, Sécurité, SRE et N/N-1 encore ouverts sont déclarés comme risques de déploiement et interdisent la production, sans être présentés comme accomplis.
