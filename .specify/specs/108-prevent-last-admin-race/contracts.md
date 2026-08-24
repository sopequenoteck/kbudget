# Contrats — suppression atomique du dernier administrateur

**Issue**: DEMO-007  
**Profil**: critical  
**Date**: 2026-08-18  
**Statut**: défini  
**Sources**: `spec.md`, `research.md`, `risk-assessment.md`

## Objet et portée contractuelle

Ce document formalise les interfaces publiques, le modèle de données pertinent et le protocole transactionnel qui empêchent toute suppression validée de faire tomber le nombre d'administrateurs actifs sous un. La correction est interne au backend : elle ne crée aucun endpoint, ne modifie aucun schéma JSON public et ne change aucun statut, en-tête, contrôle préalable ou code d'erreur existant.

Le chemin concerné est la suppression du compte authentifié par `DELETE /users/me`. Le renouvellement par `POST /auth/refresh` sert d'oracle public pour prouver que les refresh tokens du compte dont la suppression est refusée restent valides. Les créations, promotions, rétrogradations, réactivations et désactivations d'administrateurs appartiennent au même domaine transactionnel protégé, même lorsqu'elles ne changent pas d'interface HTTP.

Exigences couvertes : **FR-001 à FR-025**.

## Contrat API public inchangé

### Suppression du compte courant

**Requête**

```http
DELETE /users/me
Authorization: Bearer <access-token>
Content-Type: application/json

{
  "currentPassword": "<mot-de-passe-non-vide>",
  "confirmed": true
}
```

Schéma de la requête :

| Champ | Type | Obligatoire | Contraintes |
|---|---|---:|---|
| `currentPassword` | chaîne | oui | non vide; contrôlé selon le mécanisme existant |
| `confirmed` | booléen | oui | doit valoir `true`; sinon validation existante avec « Confirmation explicite requise » |

Les contrôles d'authentification, d'autorisation, de confirmation et de mot de passe gardent leur ordre et leurs réponses observables actuels. L'acquisition du verrou ne commence qu'après les validations qui précèdent actuellement la garde du dernier administrateur. (**FR-013, FR-014**)

**Succès**

```http
HTTP/1.1 204 No Content
```

Le corps reste vide. Le compte est désactivé et ses refresh tokens actifs sont révoqués dans la même transaction. Aucun nouvel en-tête n'est introduit. (**FR-008, FR-011, FR-014**)

**Refus du dernier administrateur**

```http
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
  "error": "LAST_ADMIN_DELETION_FORBIDDEN",
  "message": "Au moins un administrateur actif doit exister."
}
```

La propriété optionnelle `details` du schéma générique `ErrorResponse` reste omise lorsqu'elle est vide. Le refus est émis uniquement après acquisition de la protection commune et recomptage de l'état validé. Une panne PostgreSQL, un timeout, un deadlock ou une erreur de sérialisation ne doit pas être converti arbitrairement en ce refus métier et suit le traitement d'incident existant, sans fuite de détail interne. (**FR-004, FR-007, FR-014**)

### Renouvellement d'un refresh token

Le contrat existant est utilisé sans modification :

```http
POST /auth/refresh
Content-Type: application/json

{ "refreshToken": "<token-non-vide>" }
```

Pour le compte dont la suppression est refusée, un token `ACTIVE` émis avant la course doit encore produire la réponse de succès existante `200 OK`, au schéma suivant :

```json
{
  "token": "<nouvel-access-token>",
  "refreshToken": "<nouveau-refresh-token>",
  "email": "<email>",
  "name": "<nom>",
  "mustResetCredentials": false
}
```

La rotation existante peut consommer le token présenté et en émettre un nouveau; cette consommation réussie constitue la preuve de validité demandée. Pour le compte effectivement supprimé, le token antérieur continue de produire la réponse existante `401` avec `error = TOKEN_REVOKED`. (**FR-010, FR-011, FR-017, FR-018**)

## Contrat de données

### Définitions

| Concept | Définition persistante | Exigences |
|---|---|---|
| Administrateur actif | ligne `users` telle que `is_admin = TRUE AND disabled_at IS NULL` | FR-001, FR-006 |
| Compte désactivé | ligne `users` dont `disabled_at IS NOT NULL` | FR-008, FR-009 |
| Token valide avant usage | ligne `refresh_tokens` liée au compte, avec statut `ACTIVE` et non expirée | FR-010 à FR-012 |
| Ensemble protégé | ensemble logique de tous les administrateurs actifs, coordonné par une même clé de verrou stable | FR-003, FR-021 |

Invariant de commit :

```text
pour tout commit d'une mutation couverte :
COUNT(users WHERE is_admin = TRUE AND disabled_at IS NULL) >= 1
```

Invariant du refus : la transaction refusée ne modifie ni `users.disabled_at`, ni `users.is_admin`, ni le statut d'aucun `refresh_tokens` du compte, et ne persiste aucun événement ou journal de succès. (**FR-001, FR-009, FR-010, FR-012**)

Invariant du succès : la transaction gagnante affecte `disabled_at`, révoque selon le comportement existant tous les refresh tokens actifs du compte, puis commite sans faire tomber le cardinal protégé sous un. (**FR-006, FR-008, FR-011, FR-012**)

Aucune migration de schéma n'est requise pour le mécanisme principal. Les colonnes, statuts et relations existants restent inchangés. (**FR-023, FR-024**)

## Contrat de sérialisation transactionnelle

### Ressource commune

Toutes les transactions applicatives qui modifient l'appartenance à l'ensemble protégé doivent appeler un composant unique qui exécute, sur leur connexion transactionnelle courante :

```sql
SELECT pg_advisory_xact_lock(:active_admin_invariant_key);
```

`:active_admin_invariant_key` est une constante numérique, non dérivée de l'utilisateur, de l'instance JVM ou de la requête. Sa valeur exacte sera réservée et documentée dans l'implémentation; tous les participants utilisent strictement la même valeur. Le verrou est exclusif, transactionnel et libéré seulement par commit ou rollback. Aucun verrou JVM et aucun verrou limité à la ligne du compte cible ne satisfait ce contrat. (**FR-002, FR-003, FR-021, FR-022**)

### Frontière et ordre obligatoires

Pour la suppression d'un administrateur actif, une seule transaction Spring et une seule connexion PostgreSQL exécutent dans cet ordre :

1. terminer les validations existantes de confirmation, d'authentification, d'autorisation et de mot de passe;
2. acquérir le verrou consultatif transactionnel commun;
3. recharger si nécessaire l'état pertinent, puis exécuter le décompte des administrateurs actifs après l'acquisition;
4. si le compte courant est actif et que le décompte est inférieur ou égal à un, lever `LastAdminDeletionForbiddenException` avant toute mutation;
5. sinon renseigner `users.disabled_at`, puis révoquer les refresh tokens actifs du compte dans cette même transaction;
6. commiter, ce qui rend les mutations visibles ensemble et libère le verrou; toute exception provoque le rollback conjoint.

Sous PostgreSQL `READ COMMITTED`, le décompte est une instruction exécutée après l'attente : la transaction arrivée seconde observe donc le commit de la première. Il est interdit de décider depuis un décompte lu avant l'acquisition. Aucun `REQUIRES_NEW`, traitement asynchrone ou effet de succès pré-commit n'est permis pour la désactivation ou la révocation. (**FR-002, FR-004, FR-005, FR-012, FR-022**)

La suppression d'un non-administrateur conserve son comportement actuel et peut éviter ce verrou puisqu'elle ne réduit pas l'ensemble protégé. Les chemins runtime inventoriés sont `UserDeletionService` (réduction), `UserOnboardingService` et `AdminSyncRunner` (ajout). Ils doivent adopter le composant commun; toute future promotion, rétrogradation, réactivation ou désactivation administrative doit faire de même. Les écritures SQL/DBA directes doivent soit acquérir la même clé, soit être interdites pendant les mutations concernées. (**FR-003, FR-021**)

### Résultat concurrent contractuel

Avec exactement deux administrateurs actifs A et B, deux suppressions valides simultanées ont seulement les résultats finaux suivants, indépendamment du gagnant :

| Cardinalité | Résultat |
|---:|---|
| 1 | `204 No Content`; compte désactivé; tokens révoqués |
| 1 | `403 Forbidden`; `LAST_ADMIN_DELETION_FORBIDDEN`; compte et tokens inchangés |
| 1 | administrateur actif persistant après les deux terminaisons |

Deux réponses 204, deux réponses 403, zéro administrateur actif, un token révoqué pour le compte refusé ou un token actif pour le compte supprimé violent le contrat. (**FR-005 à FR-012**)

## Compatibilité et déploiement

La correction ne change aucune interface publique et reste compatible avec les clients existants. Elle dépend toutefois de PostgreSQL et de `pg_advisory_xact_lock`; la version de production doit être confirmée compatible et l'autorisation opérationnelle des verrous consultatifs validée avant implémentation. Si cette autorisation est refusée, une ligne sentinelle verrouillée par `SELECT ... FOR UPDATE` est l'option de repli, avec migration additive et nouvelle revue de compatibilité. (**FR-014, FR-019, FR-023**)

Le protocole n'est pas sûr pendant une coexistence d'instances N protégées et N-1 vulnérables. Sans enforcement entièrement en base compris par N-1, `DELETE /users/me` et toutes les mutations de rôle administrateur doivent être suspendues pendant le remplacement des instances, puis rouvertes uniquement lorsque tous les écrivains utilisent la clé commune. Le rollback vers N-1 impose la même suspension jusqu'au rétablissement d'une version protégée. Avant activation, un contrôle en lecture doit confirmer qu'au moins un administrateur actif existe. (**FR-023, FR-024**)

## Contrat d'observabilité et de sécurité

Les journaux et métriques distinguent au minimum : suppression commitée, refus `LAST_ADMIN_DELETION_FORBIDDEN`, attente/timeout de verrou, deadlock ou erreur de base, et rollback. Ils peuvent contenir un identifiant interne de compte et une durée, mais jamais un access token ou refresh token. Un succès ne doit être journalisé qu'après commit ou via un mécanisme transactionnel fiable. (**FR-009, FR-012, FR-025**)

Les timeouts et deadlocks ne sont jamais assimilés silencieusement à un succès. Les politiques de timeout/retry existantes restent applicables; leurs seuils opérationnels doivent être fixés avant production. (**FR-007, FR-022, FR-025**)

## Contrats de vérification

### Test d'intégration concurrent obligatoire

Le test s'exécute contre un PostgreSQL réel, de même version majeure que la production confirmée, sans H2, mocks de repository ni transaction de test englobante. Il crée exactement deux administrateurs actifs et un refresh token distinct pour chacun, neutralise tout bootstrap ou `ADMIN_EMAILS`, puis lance deux requêtes HTTP authentifiées `DELETE /users/me` depuis deux workers indépendants. Une barrière explicite prépare les deux workers avant leur libération; le serveur utilise deux connexions et chaque requête effectue son vrai commit. Aucun `sleep` ne sert de synchronisation. (**FR-015, FR-019, FR-020**)

Après un timeout borné et l'achèvement des deux opérations, le test doit :

1. compter exactement un statut 204;
2. compter exactement un statut 403 et vérifier exactement `error = LAST_ADMIN_DELETION_FORBIDDEN` et `message = "Au moins un administrateur actif doit exister."`;
3. relire depuis une nouvelle transaction et trouver exactement un administrateur actif;
4. identifier le compte refusé d'après la réponse observée et vérifier `is_admin = true`, `disabled_at IS NULL`;
5. appeler réellement `POST /auth/refresh` avec son token préexistant et obtenir le succès 200 existant;
6. vérifier que le compte supprimé a `disabled_at IS NOT NULL` et que son token préexistant produit le `401 TOKEN_REVOKED` existant;
7. fermer proprement workers, connexions et conteneur même en cas d'échec.

Le scénario doit varier l'ordre de soumission ou être répété de manière bornée. Une preuve déterministe doit aussi démontrer que la version vulnérable échoue : point de coordination contrôlé autour des deux anciennes lectures ou exécution mutationnelle ponctuelle avec acquisition du verrou désactivée. Une répétition probabiliste seule est insuffisante. (**FR-016 à FR-020**)

### Régressions obligatoires

- suppression non concurrente : succès 204 et révocation inchangés (**FR-008, FR-011, FR-014**);
- dernier administrateur seul : 403 et corps exact inchangés, sans révocation (**FR-007, FR-009, FR-010, FR-014**);
- confirmation, mot de passe, authentification et autorisation : ordre, statuts et corps inchangés (**FR-013, FR-014**);
- timeout/deadlock injecté : aucun 204, aucune mutation partielle et aucune fuite SQL (**FR-007, FR-012, FR-022**);
- inventaire des mutations : chaque chemin utilise le composant commun ou fournit une preuve de non-conflit (**FR-021**);
- analyse des logs : aucun secret et issues correctement distinguées (**FR-025**).

## Matrice de traçabilité

| Contrat | Exigences applicables |
|---|---|
| API `DELETE /users/me` inchangée | FR-007, FR-008, FR-013, FR-014 |
| API `POST /auth/refresh` comme oracle | FR-010, FR-011, FR-017, FR-018 |
| Schéma et invariants de données | FR-001, FR-006, FR-009 à FR-012 |
| Verrou commun et transaction unique | FR-001 à FR-005, FR-021, FR-022 |
| Résultat concurrent cardinalisé | FR-005 à FR-012, FR-016 |
| Test PostgreSQL concurrent | FR-015 à FR-020 |
| Compatibilité, migration et N/N-1 | FR-023, FR-024 |
| Observabilité et absence de secrets | FR-025 |

## Risques résiduels et gates explicites

- La version exacte de PostgreSQL en production et l'autorisation de `pg_advisory_xact_lock` ne sont pas encore confirmées; leur validation Backend/DBA est un gate d'implémentation.
- Testcontainers n'est pas encore déclaré et l'accès Docker en CI n'est pas prouvé; le test PostgreSQL ne constitue une preuve de fin qu'après validation de cet environnement.
- La méthode déterministe prouvant l'échec de l'ancienne implémentation reste à choisir entre coordination contrôlée et preuve mutationnelle; FR-020 reste un gate tant que cette preuve n'existe pas.
- Les écrivains SQL/DBA ou services externes absents du dépôt peuvent contourner la clé; ils doivent être inventoriés et gouvernés avant production.
- La suspension des mutations pendant coexistence N/N-1 doit être techniquement et opérationnellement démontrée; à défaut, le choix doit revenir à une protection enforceée en base.
- Les seuils SRE de contention, timeout, deadlock et latence restent à fixer avant déploiement.
- La correction ne restaure pas une instance déjà sans administrateur; le contrôle préalable et la procédure de récupération auditée restent obligatoires hors de cette feature.

Aucun de ces points ne bloque la définition des contrats. Ils bloquent la déclaration de l'implémentation ou du déploiement comme terminés tant que leurs preuves ne sont pas fournies.
