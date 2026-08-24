# Implementation Plan: Suppression atomique du dernier administrateur

**Issue**: `DEMO-007` | **Profil**: `critical` | **Date**: 2026-08-18  
**Branche**: courante (aucun changement autorisé) | **Spec**: [spec.md](spec.md)  
**Entrées**: `assessment.json`, `workflow-state.json`, `risk-assessment.md`, `spec.md`, `research.md`, `contracts.md`

## Résumé

Remplacer la vérification concurrente non sérialisée de `UserDeletionService` par un protocole PostgreSQL commun fondé sur `pg_advisory_xact_lock`, acquis dans la transaction Spring existante avant le décompte des administrateurs actifs. La désactivation et la révocation des refresh tokens restent dans cette transaction. Le second DELETE attend le commit du premier, recompte sous `READ COMMITTED`, puis conserve le refus public existant `403 LAST_ADMIN_DELETION_FORBIDDEN` sans modifier le compte ni ses tokens.

La même abstraction de verrou protège les autres écritures applicatives qui ajoutent un administrateur (`UserOnboardingService`, `AdminSyncRunner`) afin de définir un protocole unique pour l'ensemble logique. Aucune migration ni modification d'API n'est prévue. Un test d'intégration HTTP sur PostgreSQL réel, deux connexions et une barrière explicite prouve le résultat cardinalisé, les états persistés et les deux comportements de refresh token.

## Contexte technique

| Élément | Décision / état |
|---|---|
| Langage / runtime | Java 21, Spring Boot 4.0.2 |
| Persistance | Spring Data JPA, PostgreSQL; isolation attendue `READ COMMITTED` |
| Transaction | Une transaction Spring et une connexion pour verrou, recomptage, désactivation et révocation |
| Protection | `SELECT pg_advisory_xact_lock(:key)` avec une constante globale documentée et stable |
| API | `DELETE /users/me` et `POST /auth/refresh`, contrats inchangés |
| Tests actuels | Maven/JUnit; H2 présent pour les tests généraux, insuffisant pour la preuve concurrente |
| Test cible | Testcontainers PostgreSQL, serveur HTTP réel, workers et commits indépendants, aucun `sleep` |
| Migration | Aucune pour l'option principale; replanification obligatoire si la ligne sentinelle de repli est retenue |
| Périmètre | Backend uniquement; aucun changement Angular, Flutter ou contrat public |

## Constitution et gates

| Principe | Statut | Justification / gate |
|---|---|---|
| API-first | PASS | Aucun endpoint, statut, en-tête ni schéma public ne change. |
| Sécurité et données | CONDITIONNEL | L'invariant et les tokens sont protégés atomiquement; PostgreSQL 16 local et revue sécurité obligatoires pour la preuve, validation de production requise avant déploiement. |
| Simplicité / YAGNI | PASS | Un composant de verrou transactionnel, sans schéma nouveau; la clé unique matérialise l'ensemble protégé. |
| Testabilité | CONDITIONNEL | Test concurrent déterministe prévu; Docker/Testcontainers doit réussir localement, puis être confirmé en CI avant déploiement. |
| Observabilité | CONDITIONNEL | Issues et attente de verrou distinguées, aucun token journalisé; seuils SRE à fixer avant production. |
| Self-hosted / portabilité | CONDITIONNEL | PostgreSQL requis; version majeure de production et autorisation des advisory locks à confirmer. |

**Résultat du gate de planification**: PASS pour implémenter et vérifier localement avec PostgreSQL 16, déclaré par `docker-compose-dev.yml`, et `pg_advisory_xact_lock`, disponible nativement sur ce moteur. La clé globale doit être réservée et documentée dans le code. La version exacte de production et les validations Backend/DBA, CI, N/N-1, SRE, sécurité/données et rollback restent des gates de déploiement et ne sont pas réputées acquises.

## Architecture cible et frontières transactionnelles

### D1 — Abstraction commune de verrouillage

Créer `ActiveAdminInvariantLock`, composant dédié qui exécute via la connexion transactionnelle courante une native query `SELECT pg_advisory_xact_lock(?1)`. La clé est une constante `long`, indépendante d'un utilisateur, d'une JVM et d'une requête, réservée par un commentaire et un test. La méthode exige une transaction active; aucun fallback JVM silencieux n'est permis.

Le verrou est transactionnel: PostgreSQL le libère au commit ou au rollback. Il protège une ressource logique stable, contrairement à un verrou sur le seul compte cible, qui ne sérialiserait pas l'agrégat. Les erreurs de timeout, deadlock ou base continuent vers le traitement technique existant et ne sont jamais traduites en `LAST_ADMIN_DELETION_FORBIDDEN`.

### D2 — Suppression atomique

Conserver dans `UserDeletionService.softDelete` l'ordre observable actuel:

1. valider `confirmed` et le mot de passe;
2. pour un administrateur actif, acquérir le verrou commun;
3. exécuter `countActiveAdmins()` seulement après acquisition;
4. si le compte est encore administrateur actif et si le compte est inférieur ou égal à un, lever `LastAdminDeletionForbiddenException` avant toute écriture;
5. sinon définir `disabledAt`, sauvegarder et révoquer les refresh tokens dans la transaction courante;
6. commiter puis considérer la suppression comme réussie; toute exception rollbacke compte et tokens.

Le compte passé au service peut être détaché ou obsolète pendant l'attente. Après le verrou, recharger le compte par identifiant ou verrouiller/revalider son état avant de décider, sans modifier l'ordre des contrôles publics. Le journal de succès ne doit pas précéder le commit; utiliser une synchronisation `afterCommit` ou ne journaliser que l'intention transactionnelle avec une issue finale fiable.

### D3 — Tous les écrivains d'administrateurs

Faire acquérir la même clé, dans leur transaction existante, avant toute mutation de `isAdmin` par:

- `UserDeletionService` pour la réduction de l'ensemble;
- `UserOnboardingService` lorsqu'il crée un utilisateur avec `isAdmin=true`;
- `AdminSyncRunner` avant ses promotions.

Confirmer par recherche et revue qu'il n'existe aucun autre chemin runtime de promotion, rétrogradation, réactivation ou désactivation. Les écritures SQL/DBA et services externes doivent acquérir la même clé ou être interdites pendant la fenêtre de mutation. Tout nouveau chemin devra passer par cette abstraction.

### D4 — Contrat public et tokens

Ne modifier ni le contrôleur, ni `LastAdminDeletionForbiddenException`, ni `GlobalExceptionHandler`. Le gagnant conserve `204` et la révocation de ses tokens. Le perdant conserve exactement `403`, `error=LAST_ADMIN_DELETION_FORBIDDEN`, le message existant, son état actif et ses tokens actifs. La preuve de validité est un vrai `POST /auth/refresh` à `200`; le token du gagnant doit conserver le comportement existant `401 TOKEN_REVOKED`.

### D5 — Migration et solution de repli

L'option principale n'ajoute aucun objet de schéma: aucune migration Flyway et aucun rollback de schéma. Si PostgreSQL de production ou la politique DBA interdit `pg_advisory_xact_lock`, arrêter l'implémentation et replanifier une ligne sentinelle verrouillée par `SELECT ... FOR UPDATE`: migration additive, audit des données, compatibilité N/N-1, montée/descente et durée des verrous devront alors faire l'objet d'une nouvelle revue.

## Structure projet et inventaire prévisionnel

```text
api/
├── pom.xml                                                       # M — dépendances Testcontainers PostgreSQL
├── src/main/java/fr/kksdev/budget/api/
│   ├── repository/UserRepository.java                            # M — décompte/rechargement utilisés sous verrou
│   ├── service/ActiveAdminInvariantLock.java                     # C — verrou advisory commun
│   ├── service/UserDeletionService.java                          # M — verrou, recomptage, atomicité
│   ├── service/UserOnboardingService.java                        # M — protocole lors d'une création admin
│   └── runner/AdminSyncRunner.java                               # M — protocole lors d'une promotion
└── src/test/java/fr/kksdev/budget/api/
    ├── service/ActiveAdminInvariantLockTest.java                 # C — transaction/clé/rollback
    ├── service/UserDeletionServiceTest.java                      # M — ordre et absence d'effets au refus
    ├── runner/AdminSyncRunnerTest.java                           # M — adoption du verrou commun
    └── controller/UserDeletionConcurrencyIT.java                 # C — PostgreSQL + HTTP concurrent + tokens
```

Les noms exacts peuvent suivre les conventions locales, mais les responsabilités et les preuves ne doivent pas être fusionnées au point de masquer la frontière transactionnelle. Aucun fichier frontend ni migration ne fait partie de l'option retenue.

## Phases d'implémentation

### Phase 0 — Gates et baseline

1. Confirmer dans le dépôt PostgreSQL 16 pour le développement, vérifier localement `READ COMMITTED` et `pg_advisory_xact_lock`, puis réserver et documenter la clé numérique. Conserver la confirmation de la version de production et l'approbation Backend/DBA comme gates de déploiement.
2. Confirmer Docker localement et pinner PostgreSQL 16 pour Testcontainers, jamais `latest`. Conserver l'exécution en CI comme gate de déploiement si elle n'est pas disponible pendant l'implémentation locale.
3. Inventorier dans le dépôt tous les écrivains de `is_admin`/`disabled_at`; conserver l'inventaire des SQL directs et services externes comme gate opérationnel de déploiement.
4. Exécuter les tests de suppression, authentification et exceptions existants afin d'établir la baseline.
5. Utiliser des timeouts de test bornés et documenter les métriques attendues; les seuils SRE d'attente, deadlock, 5xx et latence restent à approuver avant mise en production.

### Phase 1 — Primitive transactionnelle

1. Ajouter le composant de verrou avec native query et constante documentée.
2. Garantir qu'il réutilise la transaction/connexion courante et échoue explicitement hors transaction.
3. Tester deux transactions indépendantes: la seconde attend, puis progresse après commit ou rollback de la première.
4. Vérifier qu'aucune exception technique n'est remappée en refus métier.

### Phase 2 — Chemin de suppression

1. Injecter la primitive dans `UserDeletionService`.
2. Après les validations existantes, acquérir le verrou pour l'administrateur actif, recharger son état et recompter.
3. Lever l'exception existante avant toute mutation lorsque le cardinal est `<= 1`.
4. Conserver désactivation et révocation dans la transaction; tester le rollback conjoint lors d'une erreur de révocation.
5. Déplacer ou qualifier la journalisation afin qu'aucun succès ne soit annoncé avant commit et qu'aucun secret ne soit écrit.

### Phase 3 — Adoption par les autres mutations

1. Dans `UserOnboardingService`, acquérir le verrou avant la création lorsque `isAdmin=true`; laisser les créations non-admin inchangées.
2. Dans `AdminSyncRunner`, acquérir une fois le verrou dans sa transaction avant les promotions.
3. Ajouter des tests d'interaction/transaction et une recherche bloquante sur les écritures restantes de `isAdmin` et `disabledAt`.
4. Documenter la règle pour les futurs chemins et les opérations DBA.

### Phase 4 — Test concurrent PostgreSQL déterministe

1. Ajouter Testcontainers PostgreSQL au scope test et un profil d'intégration sans H2, avec migrations Flyway réelles.
2. Démarrer l'application sur un port aléatoire, neutraliser bootstrap et `ADMIN_EMAILS`, nettoyer les données sans transaction de test englobante.
3. Créer exactement deux administrateurs actifs, leurs credentials et un refresh token distinct valide chacun.
4. Préparer deux workers HTTP authentifiés, utiliser une barrière pour les libérer ensemble et garantir deux connexions serveur; borner l'attente et fermer toutes les ressources en `finally`.
5. Stabiliser l'interleaving par un hook de test au point de l'ancienne lecture ou par une mutation test qui désactive ponctuellement l'acquisition; ne pas utiliser `sleep`. Prouver que l'ancienne logique autoriserait les deux désactivations, puis que la logique protégée ne le peut pas.
6. Compter exactement un `204` et un `403`; vérifier le code et le message exacts du refus.
7. Depuis une nouvelle transaction, vérifier exactement un administrateur actif, le perdant actif et le gagnant désactivé.
8. Appeler réellement le refresh avec les deux tokens: `200` pour le perdant, `401 TOKEN_REVOKED` pour le gagnant.
9. Répéter de façon bornée en alternant l'ordre de soumission pour détecter les hypothèses liées à l'identité du gagnant.

### Phase 5 — Régressions, revue et livraison

1. Vérifier suppression nominale, dernier admin seul, confirmation, mot de passe, authentification et autorisation.
2. Injecter timeout/deadlock/erreur de révocation: aucun `204`, aucune mutation partielle, aucune fuite SQL.
3. Exécuter toute la suite Maven puis une revue indépendante de la clé, de l'ordre des verrous, de la connexion unique, des tokens, des logs et de N/N-1.
4. Produire les preuves `requirements-coverage`, `test-suite`, `security-or-data-check`, `rollback-plan` et `independent-review` exigées par le profil critical.

## Stratégie de validation

| ID | Validation | Bloquante | Critère de succès |
|---|---|---:|---|
| V-01 | Tests unitaires ciblés du verrou et de la suppression | Oui | Ordre verrou→count→mutation, refus sans écriture, rollback tokens/compte |
| V-02 | Test PostgreSQL HTTP concurrent | Oui | 1×204, 1×403 exact, 1 admin actif, tokens du perdant valides, tokens du gagnant révoqués |
| V-03 | Régressions auth/contrats | Oui | Statuts, corps, ordre des contrôles et renouvellement inchangés |
| V-04 | Suite backend complète | Oui | Tous les tests Maven réussissent |
| V-05 | Sécurité/données et logs | Oui | Invariant après commit, rollback intégral, aucune fuite de token/SQL, erreurs techniques non maquillées |
| V-06 | Migration/rollback/N/N-1 | Oui | Absence de migration confirmée; suspension des mutations démontrée pendant coexistence/rollback |
| V-07 | Revue indépendante | Oui | Backend/DBA/Sécurité valident clé, isolation, écrivains, contention et procédures |

## Déploiement, observabilité et rollback

Avant activation, exécuter une requête en lecture confirmant au moins un administrateur actif par instance. Suspendre `DELETE /users/me` et toutes les mutations de rôle administrateur pendant le remplacement des instances N-1; ne rouvrir que lorsque tous les écrivains N utilisent la clé commune. Un rolling deploy mixte sans suspension est interdit.

Surveiller minimum d'administrateurs actifs, taux de refus métier, 5xx, latence et attente du verrou, timeouts, deadlocks et échecs de refresh. Les logs distinguent commit, refus, attente/timeout et rollback avec identifiant interne, jamais avec un access ou refresh token.

Déclencher le rollback ou confinement si zéro admin est observé, si les deux suppressions réussissent, si les tokens ont le mauvais état, si le contrat HTTP dérive, ou si contention/5xx dépassent les seuils approuvés. Suspendre d'abord les mutations administrateur, arrêter le rollout et préserver preuves et état. Revenir applicativement seulement vers une version qui maintient la protection; puisque l'option principale n'a pas de migration, aucun rollback de schéma n'est requis. Ne jamais réactiver N-1 vulnérable avec les mutations ouvertes. Vérifier ensuite cardinal, états des comptes et tokens, puis réexécuter V-02 à V-05. La récupération d'une instance déjà à zéro admin reste une procédure auditée hors périmètre.

## Traçabilité exigences → réalisation → preuve

| Exigences | Réalisation | Preuve |
|---|---|---|
| FR-001 à FR-006, FR-022 | D1/D2, phases 1-2 | V-01, V-02, V-05 |
| FR-007 à FR-014 | D2/D4, phases 2 et 5 | V-02, V-03, V-05 |
| FR-015 à FR-020 | D4, phase 4 | V-02 et preuve négative déterministe |
| FR-021 | D3, phase 3 | Inventaire des écrivains + V-01/V-07 |
| FR-023 à FR-024 | D5, déploiement/rollback | V-06, approbation DBA/SRE |
| FR-025 | D4, phase 5, observabilité | V-05, inspection logs/métriques |
| SC-001 à SC-007 | Phases 4-5 | V-02 à V-07 |

## Risques résiduels, mitigations et blocages

| Risque / gate | État | Mitigation / condition de levée |
|---|---|---|
| PostgreSQL 16 local et advisory lock | Vérifiable pendant l'implémentation locale | Contrôler le moteur déclaré, exécuter le test PostgreSQL et réserver la clé; l'approbation production reste un gate de déploiement. |
| Docker/Testcontainers CI non prouvé | Ouvert, bloque le déploiement mais pas la preuve locale | Test local avec image PostgreSQL 16 pinnée; pipeline V-02 vert requis avant déploiement. |
| Preuve négative de l'ancienne course à instrumenter | Ouvert, bloque FR-020 | Hook de coordination test-only ou mutation déterministe revue, sans altérer la production. |
| Écrivains externes/DBA inconnus | Ouvert, bloque le déploiement | Inventaire opérationnel et interdiction ou adoption de la clé commune. |
| Coexistence N/N-1 vulnérable | Ouvert, bloque le rolling deploy | Suspension démontrée; sinon protection enforceée en base et nouvelle conception. |
| Seuils contention/deadlock absents | Ouvert, bloque la production | Seuils SRE et alertes approuvés, test sous contention. |
| Instance déjà sans admin | Hors périmètre de correction | Détection pré-déploiement et récupération auditée séparée. |

Ces points n'empêchent pas la production du plan. Ils constituent des gates explicites des activités d'implémentation, de vérification et de déploiement; aucun ne doit être contourné ou converti arbitrairement en erreur métier.

## Critères de fin de l'implémentation

- Toutes les mutations applicatives inventoriées partagent le verrou commun dans leur transaction.
- Le test PostgreSQL concurrent est déterministe et satisfait tous les oracles HTTP, données et tokens.
- Les contrats existants et la suite backend complète restent verts.
- L'absence de migration, la procédure N/N-1 et le rollback confiné sont validés.
- Les cinq preuves du profil critical sont produites et la revue indépendante ne conserve aucun finding critique ou élevé non traité.
- Les risques ouverts ci-dessus sont levés ou le déploiement reste explicitement bloqué.
