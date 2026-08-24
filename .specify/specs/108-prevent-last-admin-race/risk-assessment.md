# Évaluation des risques — DEMO-007

## Contexte et périmètre

La suppression d'un compte administrateur vérifie le nombre d'administrateurs actifs avant de désactiver le compte. En l'absence de sérialisation entre transactions, deux suppressions simultanées peuvent chacune observer deux administrateurs actifs, puis désactiver les deux comptes. L'instance se retrouve alors sans administrateur.

Cette activité couvre exclusivement l'évaluation des risques de la correction qui doit rendre atomique l'invariant « il reste au moins un administrateur actif ». La correction attendue inclut un test d'intégration lançant simultanément deux suppressions et démontrant qu'une seule réussit, que l'autre échoue avec `LAST_ADMIN_DELETION_FORBIDDEN`, qu'il reste exactement un administrateur actif et que les refresh tokens du compte dont la suppression est refusée restent valides. Les statuts HTTP et les contrats d'erreur existants doivent rester inchangés.

Hors périmètre : refonte du modèle d'autorisation, modification des contrats HTTP, changement général de la gestion des sessions, récupération automatique d'une instance déjà dépourvue d'administrateur et correction de données historiques.

## Hypothèses et invariants

- La notion d'« administrateur actif » repose sur des données persistées et peut être évaluée dans la même transaction que la désactivation.
- Une suppression refusée est atomiquement sans effet : ni compte désactivé, ni refresh token révoqué, ni effet de bord persistant.
- Une suppression réussie conserve le comportement actuel, notamment la révocation des refresh tokens du compte effectivement désactivé.
- Le mécanisme de concurrence retenu est supporté de manière équivalente par la base utilisée en production et par celle du test d'intégration.
- Toute création, réactivation, suppression ou modification de rôle d'administrateur partage le même mécanisme de protection de l'invariant, ou il est démontré que ces chemins ne peuvent pas entrer en conflit.

## Échelle d'évaluation

- Probabilité : faible, moyenne ou élevée selon la vraisemblance avant mitigation.
- Impact : modéré, élevé ou critique selon les conséquences sur l'accès, la sécurité, les données et l'exploitation.
- Un risque est critique lorsque son impact peut supprimer tout accès administratif, violer l'autorisation ou produire un état difficilement récupérable.

## Matrice des risques

| ID | Domaine | Risque | Probabilité | Impact | Mitigation requise | Responsable |
|---|---|---|---|---|---|---|
| R1 | Données / concurrence | Deux suppressions concurrentes franchissent la vérification et désactivent tous les administrateurs. | Élevée | Critique | Sérialiser dans une transaction la lecture de l'état protégé et la désactivation, au moyen d'un verrou ou d'une contrainte base de données dont la portée couvre toutes les lignes concernées. Le second concurrent doit réévaluer l'invariant après l'attente. | Backend / DBA |
| R2 | Données | Un verrou limité aux deux lignes de compte ne protège pas une agrégation sur l'ensemble des administrateurs et laisse subsister des anomalies avec création, promotion ou réactivation concurrente. | Moyenne | Critique | Verrouiller une ressource stable commune à toutes les mutations d'administrateurs, ou imposer l'invariant par la base. Inventorier et aligner tous les chemins qui modifient l'ensemble des administrateurs actifs. | Backend / DBA |
| R3 | Transactions | La vérification et la désactivation utilisent des transactions, connexions ou niveaux d'isolation différents, rendant le verrou inefficace. | Moyenne | Critique | Garantir une transaction unique et une même connexion; documenter l'ordre des opérations et le niveau d'isolation; ajouter un test qui échoue avec l'ancienne implémentation. | Backend |
| R4 | Sécurité / sessions | Le chemin refusé révoque malgré tout les refresh tokens, déconnectant le dernier administrateur et créant un déni de service logique. | Moyenne | Critique | N'exécuter la révocation qu'après validation de l'invariant et dans la même unité atomique, ou après commit avec idempotence maîtrisée. Vérifier explicitement qu'un refresh token du compte refusé permet encore le renouvellement. | Backend / Sécurité |
| R5 | Sécurité | Une suppression réussie ne révoque plus les refresh tokens du compte désactivé à cause du nouvel ordre transactionnel. | Faible | Élevé | Conserver la révocation existante pour le compte supprimé et ajouter une assertion de non-validité de ses tokens, sans modifier le comportement du compte refusé. | Backend / QA sécurité |
| R6 | Contrat API | Une erreur de verrou, de contrainte ou de sérialisation fuit en erreur générique, modifie le statut HTTP ou remplace `LAST_ADMIN_DELETION_FORBIDDEN`. | Moyenne | Élevé | Traduire uniquement le conflit métier attendu vers le contrat existant; conserver statut, code, corps et en-têtes; tester le contrat de la réponse perdante. | Backend / QA API |
| R7 | Disponibilité | Des verrous trop larges, un ordre de verrouillage incohérent ou des transactions longues causent contention, deadlocks ou timeouts sur la gestion des utilisateurs. | Moyenne | Élevé | Utiliser une ressource de verrouillage minimale et stable, un ordre unique, une transaction courte et les politiques de timeout/retry existantes; mesurer contention et deadlocks. | Backend / SRE / DBA |
| R8 | Tests | Le test « simultané » est séquentiel, dépend du timing ou passe sans reproduire la fenêtre de course. | Élevée | Élevé | Utiliser deux connexions/transactions réelles, une barrière de synchronisation et un démarrage contrôlé; exécuter plusieurs répétitions si nécessaire; vérifier les quatre résultats métier et prouver que le test échoue avant correction. | QA / Backend |
| R9 | Tests / environnement | SQLite, une base en mémoire ou une transaction de test englobante ne reproduit pas la sémantique de verrouillage de production. | Moyenne | Élevé | Exécuter le test concurrent sur le même moteur et une version compatible avec la production, avec connexions indépendantes et commits réels. | QA / DevOps |
| R10 | Migrations | Une nouvelle contrainte, table de verrouillage, fonction ou index est incompatible avec les données existantes, bloque le déploiement ou exige un verrou de table prolongé. | Moyenne | Critique | Préférer une correction sans migration si elle garantit l'invariant; sinon réaliser un audit préalable, une migration compatible avec déploiement progressif, estimer le verrouillage et tester montée/descente sur une copie représentative. | DBA / Backend / SRE |
| R11 | Déploiement | Pendant un déploiement progressif, des instances anciennes et nouvelles appliquent des protocoles de concurrence différents et contournent mutuellement la protection. | Moyenne | Critique | Choisir une protection base de données comprise par les deux versions, ou séquencer le déploiement afin qu'aucune écriture incompatible ne soit possible; inclure la coexistence N/N-1 dans la revue. | SRE / Backend |
| R12 | Observabilité | Une régression laisse zéro administrateur ou augmente les conflits sans alerte immédiate. | Moyenne | Critique | Ajouter une surveillance de l'existence d'au moins un administrateur actif, du taux de refus métier, des deadlocks/timeouts et des erreurs de refresh; définir alertes et procédure d'escalade. | SRE / Sécurité |
| R13 | Retour arrière | Le rollback applicatif réintroduit la course alors qu'un schéma nouveau demeure, ou le rollback de schéma détruit une protection nécessaire. | Moyenne | Critique | Prévoir un rollback ordonné et compatible N/N-1; conserver la protection de données tant que l'ancienne version peut écrire; interdire toute migration descendante destructive en urgence. | SRE / DBA / Backend |
| R14 | Récupération | Une instance déjà sans administrateur n'est pas réparée par la correction et reste inexploitable. | Faible | Critique | Avant déploiement, détecter les instances sans administrateur; traiter celles-ci via une procédure de récupération auditée et autorisée, distincte de cette correction. | SRE / Sécurité / Support |

## Risques critiques et contrôles obligatoires

La mise en œuvre ne doit être acceptée que si R1 à R4, R10 à R14 disposent de contrôles vérifiables. La preuve centrale est qu'avec exactement deux administrateurs actifs et deux suppressions réellement concurrentes, une seule transaction commite la désactivation. La transaction perdante doit observer l'état sérialisé, retourner l'erreur métier existante et ne produire aucun effet sur le compte ou ses refresh tokens.

Une simple augmentation du niveau d'isolation sans gestion documentée des erreurs de sérialisation, une vérification répétée hors transaction, ou un verrou sur la seule ligne du compte supprimé ne constitue pas à elle seule une mitigation suffisante. La solution doit identifier la ressource commune qui sérialise toutes les mutations pouvant changer le nombre d'administrateurs actifs.

## Sécurité et autorisation

Le défaut est un risque de disponibilité et de contrôle d'accès critique : la disparition du dernier administrateur peut empêcher toute administration légitime et encourager une récupération manuelle risquée. La correction ne doit ni créer un moyen de conserver les sessions du compte effectivement supprimé, ni révoquer celles du compte protégé par le refus.

Les contrôles de sécurité attendus sont : autorisation inchangée sur l'endpoint, absence de fuite d'erreurs internes de base de données, maintien exact de `LAST_ADMIN_DELETION_FORBIDDEN`, révocation des credentials du compte supprimé, validité des refresh tokens du compte refusé, et journalisation non ambiguë de l'issue de chaque tentative sans exposer les tokens.

## Données et cohérence transactionnelle

L'invariant doit être vrai après chaque commit visible. La lecture du nombre d'administrateurs, la décision métier, la désactivation et les mutations de tokens qui doivent être atomiques doivent partager une frontière transactionnelle explicite. L'échec ou l'annulation doit restaurer intégralement l'état antérieur du compte refusé.

Le choix technique doit être évalué face aux suppressions, promotions, rétrogradations, créations et réactivations simultanées. Les effets secondaires non transactionnels éventuels, tels que messages ou événements, ne doivent être émis qu'après commit ou via un mécanisme transactionnel afin d'éviter d'annoncer une suppression refusée.

Avant déploiement, un contrôle en lecture doit confirmer qu'aucune instance n'a zéro administrateur actif et que les données satisfont toute nouvelle contrainte. Aucun nettoyage automatique de données n'est autorisé implicitement par cette correction.

## Migrations et compatibilité de déploiement

Si la solution repose uniquement sur un verrou transactionnel appliqué à une ressource existante, aucune migration ne devrait être nécessaire; cette absence doit être confirmée dans le plan. Si une migration est requise, elle doit préciser la compatibilité avec les versions N et N-1, la durée et la portée des verrous, les préconditions de données, la procédure de répétition après échec et la stratégie de descente.

La migration doit être additive avant l'activation du nouveau code. Une contrainte protectrice ne doit être retirée qu'après retrait de toute version qui en dépend. Le déploiement progressif est bloqué si l'ancienne version peut encore contourner le protocole choisi.

## Validation et preuves attendues

- Test d'intégration avec exactement deux administrateurs actifs et deux suppressions lancées via deux connexions indépendantes, synchronisées par une barrière.
- Une et une seule suppression réussit; une et une seule réponse conserve le statut HTTP existant et le code `LAST_ADMIN_DELETION_FORBIDDEN`.
- Après commit des deux opérations, la base contient exactement un administrateur actif.
- Le refresh token du compte dont la suppression est refusée reste valide et permet un renouvellement; le compte reste actif.
- Les refresh tokens du compte dont la suppression réussit suivent le comportement de révocation existant.
- Le test concurrent échoue de manière reproductible sur l'implémentation vulnérable et réussit sur le moteur de base de données compatible production.
- Les suites de régression d'authentification, de suppression de compte et de contrats d'erreur restent vertes.
- Une revue indépendante confirme la ressource verrouillée, la frontière transactionnelle, l'ordre des verrous et la compatibilité de déploiement.

## Surveillance post-déploiement

Surveiller pendant le déploiement et la période d'observation : nombre minimal d'administrateurs actifs par instance, taux de `LAST_ADMIN_DELETION_FORBIDDEN`, erreurs 5xx sur la suppression, échecs de refresh pour le compte refusé, deadlocks, erreurs de sérialisation, timeouts et latence de la transaction. Toute instance à zéro administrateur déclenche une alerte critique immédiate et la procédure de récupération auditée.

## Conditions et plan de retour arrière

### Déclencheurs de rollback

- Une instance atteint zéro administrateur actif après le déploiement.
- Le test ou la production montre que les deux suppressions concurrentes réussissent, ou qu'aucune ne réussit sans raison métier.
- Le compte dont la suppression est refusée est désactivé ou ses refresh tokens deviennent invalides.
- Le compte supprimé conserve des refresh tokens valides contrairement au contrat existant.
- Le statut HTTP ou le corps d'erreur existant change pour `LAST_ADMIN_DELETION_FORBIDDEN`.
- Le taux de deadlocks, timeouts ou erreurs 5xx dépasse le seuil opérationnel approuvé, ou la latence rend le chemin indisponible.
- Une migration échoue, bloque les écritures au-delà de la fenêtre approuvée ou révèle des données incompatibles.
- La coexistence des versions N et N-1 permet de contourner l'invariant.

### Procédure de rollback

1. Suspendre temporairement les suppressions et mutations de rôles administrateur si l'invariant ou les sessions sont menacés.
2. Arrêter le déploiement et isoler la version fautive; préserver journaux, métriques et état de base pour l'analyse.
3. Revenir à la dernière version applicative compatible uniquement si la protection base de données reste sûre avec cette version. Ne pas retirer en urgence une contrainte ou ressource protectrice.
4. Si une migration additive a été appliquée, la laisser en place lorsqu'elle est compatible. Exécuter une migration descendante seulement après validation DBA, sauvegarde et preuve qu'elle ne réintroduit pas la course ni ne détruit de données.
5. Vérifier le nombre d'administrateurs actifs, l'état des deux comptes concernés et la validité/révocation attendue de leurs tokens. Toute restauration d'accès administratif suit une procédure auditée avec approbation sécurité.
6. Réexécuter les tests concurrent, d'authentification et de contrat avant de rouvrir les mutations administrateur.

Le rollback applicatif seul est insuffisant s'il réintroduit la vulnérabilité. Dans ce cas, maintenir le chemin de suppression désactivé jusqu'à la livraison d'une version corrigée constitue la mesure de confinement sûre.

## Risques résiduels et blocages

Risques résiduels à traiter dans les activités suivantes : sémantique exacte du moteur de base de données et de son niveau d'isolation non encore documentée; inventaire des autres chemins modifiant le statut administrateur non encore confirmé; architecture précise de révocation des refresh tokens et éventuels effets secondaires non transactionnels non encore vérifiée; seuils SRE de latence, deadlocks et timeouts à fixer avant déploiement; procédure opérationnelle de récupération d'une instance déjà sans administrateur à valider avec la sécurité.

Aucun blocage n'empêche la production de cette évaluation. La mise en œuvre et le déploiement restent toutefois bloqués tant que le mécanisme de sérialisation, la compatibilité N/N-1 et le comportement transactionnel des refresh tokens ne sont pas démontrés par le plan, les tests et la revue indépendante.

## Décision de risque

Risque initial : **critique**, avec probabilité élevée et impact critique. Risque cible acceptable : **faible à moyen**, uniquement après satisfaction de tous les contrôles obligatoires, réussite des preuves concurrentes et de sécurité, validation de la stratégie de migration éventuelle et approbation du rollback par Backend, DBA, SRE et Sécurité. Toute dérogation sur R1, R3 ou R4 maintient le risque critique et interdit le déploiement.
