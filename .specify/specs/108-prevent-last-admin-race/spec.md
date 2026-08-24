# Feature Specification: Suppression atomique du dernier administrateur

**Feature Branch**: `courante (aucun changement de branche autorise)`  
**Created**: 2026-08-18  
**Status**: Draft  
**Input**: Empêcher deux suppressions concurrentes de désactiver tous les administrateurs, sans modifier le contrat HTTP existant ni invalider les sessions du compte dont la suppression est refusée.

## Scope

Cette feature couvre le chemin backend de suppression du compte courant par `DELETE /users/me`, la protection transactionnelle de l'invariant « au moins un administrateur actif existe après chaque commit » et le test d'intégration concurrent correspondant. La protection doit sérialiser les décisions concurrentes portant sur l'ensemble partagé des administrateurs actifs, pas seulement verrouiller le compte ciblé.

La suppression qui réussit conserve tous ses effets existants, notamment la désactivation du compte et la révocation de ses refresh tokens. La suppression refusée reste sans effet persistant et retourne le statut HTTP 403 ainsi que le code `LAST_ADMIN_DELETION_FORBIDDEN` et le corps d'erreur existants.

Sont hors périmètre : modification des écrans ou clients, refonte des rôles et autorisations, changement des contrats HTTP, récupération automatique d'une instance déjà sans administrateur, correction de données historiques et changement général de la gestion des sessions. Les autres mutations capables de changer l'ensemble des administrateurs actifs doivent néanmoins être inventoriées afin de démontrer qu'elles utilisent la même protection ou qu'elles ne peuvent pas entrer en conflit avec ce chemin.

## User Scenarios & Testing

### User Story 1 - Préserver un administrateur lors de suppressions concurrentes (Priority: P1)

En tant qu'exploitant d'une instance, je veux que deux administrateurs qui suppriment simultanément leur propre compte ne puissent pas tous les deux être désactivés, afin que l'instance conserve toujours un accès administratif actif.

**Why this priority**: La course actuelle peut rendre l'instance inadministrable et constitue un risque critique de disponibilité et de contrôle d'accès.

**Independent Test**: Avec exactement deux administrateurs actifs, lancer simultanément leurs suppressions sur deux connexions indépendantes synchronisées par une barrière, attendre les deux commits, puis vérifier qu'une seule suppression réussit, qu'une seule est refusée et qu'il reste exactement un administrateur actif.

**Acceptance Scenarios**:

1. **Given** exactement deux administrateurs actifs et deux demandes valides de suppression visant chacune le compte authentifié correspondant, **When** les deux demandes franchissent une barrière et exécutent réellement leur décision en concurrence, **Then** une et une seule demande réussit avec le statut de succès existant 204.
2. **Given** ces deux suppressions concurrentes, **When** la première désactivation est rendue visible à la seconde décision sérialisée, **Then** la seconde est refusée avec le statut 403, le code `LAST_ADMIN_DELETION_FORBIDDEN` et le message public existant.
3. **Given** l'achèvement des deux opérations concurrentes, **When** l'état persistant est relu depuis une nouvelle transaction, **Then** exactement un administrateur reste actif et aucun état intermédiaire sans administrateur n'a été validé.
4. **Given** plusieurs exécutions du scénario concurrent, **When** l'ordonnancement des deux demandes varie, **Then** le résultat dépend éventuellement du gagnant mais conserve toujours la cardinalité d'un succès, d'un refus et d'un administrateur actif.

---

### User Story 2 - Conserver la session du compte protégé (Priority: P1)

En tant qu'administrateur dont la suppression est refusée parce que je suis devenu le dernier administrateur actif, je veux que mon compte et mes refresh tokens restent valides afin de pouvoir continuer à administrer l'instance.

**Why this priority**: Refuser la désactivation tout en révoquant la session produirait un déni de service logique équivalent pour le dernier administrateur.

**Independent Test**: Créer un refresh token distinct pour chacun des deux administrateurs avant la course; identifier le compte perdant après les deux réponses, puis utiliser son token pour renouveler effectivement l'authentification et vérifier que son compte demeure actif.

**Acceptance Scenarios**:

1. **Given** un refresh token valide pour chacun des deux administrateurs avant la course, **When** une suppression est refusée avec `LAST_ADMIN_DELETION_FORBIDDEN`, **Then** le compte refusé reste actif et son refresh token permet encore un renouvellement conforme au contrat existant.
2. **Given** la suppression concurrente qui réussit, **When** ses effets sont validés, **Then** le compte gagnant est désactivé et ses refresh tokens suivent le comportement de révocation existant.
3. **Given** une erreur métier, un rollback ou un conflit transactionnel sur la suppression refusée, **When** l'opération se termine, **Then** aucune désactivation, révocation de token, journalisation de succès ou autre effet persistant propre à une suppression réussie n'est conservé pour ce compte.

---

### User Story 3 - Préserver les contrats et comportements existants (Priority: P2)

En tant que client de l'API, je veux que la correction de concurrence soit transparente hors du choix atomique entre succès et refus, afin de ne pas devoir adapter mon intégration.

**Why this priority**: La protection est une correction interne de cohérence et ne doit pas introduire de rupture de contrat ni exposer des erreurs de base de données.

**Independent Test**: Exécuter les tests existants de suppression, d'authentification et de gestion des erreurs, puis vérifier explicitement les réponses 204 et 403 du scénario concurrent.

**Acceptance Scenarios**:

1. **Given** une suppression valide qui ne menace pas le dernier administrateur, **When** elle est exécutée sans concurrence, **Then** son statut 204 et ses effets existants restent inchangés.
2. **Given** une tentative de supprimer le dernier administrateur actif, concurrente ou non, **When** elle est refusée, **Then** le statut reste 403 et le corps conserve exactement le code `LAST_ADMIN_DELETION_FORBIDDEN` ainsi que le message public existant.
3. **Given** une attente de verrou, un conflit de sérialisation ou un mécanisme de contrainte interne, **When** il correspond au cas métier du dernier administrateur, **Then** aucun détail interne de base de données ne fuit et le client reçoit le contrat métier existant.
4. **Given** une demande invalide pour une raison antérieure à la garde du dernier administrateur, **When** elle est traitée, **Then** l'ordre, le statut et le contrat d'erreur des validations existantes restent inchangés.

### Edge Cases

- Plus de deux administrateurs actifs peuvent demander simultanément une suppression : chaque décision validée doit conserver au moins un administrateur actif, quel que soit l'ordre d'acquisition de la protection.
- Une création, promotion, rétrogradation, réactivation ou désactivation administrative concurrente ne doit pas contourner l'invariant; chaque chemin doit partager la ressource stable de sérialisation ou être prouvé sans conflit possible.
- Verrouiller uniquement les lignes des comptes supprimés est insuffisant, car deux transactions peuvent verrouiller des lignes différentes tout en prenant une décision sur la même agrégation.
- Une attente de verrou, un deadlock ou une erreur de sérialisation ne doit pas être interprété silencieusement comme une suppression réussie ni révoquer des tokens. Les politiques existantes de timeout et de retry doivent être respectées.
- Le test ne doit pas utiliser une base en mémoire ou une transaction englobante qui masque les commits et la sémantique de verrouillage de production.
- Un compte désactivé ne compte pas comme administrateur actif. Une modification de rôle ou une réactivation en cours doit être évaluée selon l'état sérialisé visible au commit.
- Un effet secondaire non transactionnel ne doit pas annoncer une suppression avant son commit; aucun événement de succès ne doit subsister après le refus ou le rollback.
- Une instance déjà dépourvue d'administrateur n'est pas réparée par cette feature et doit être détectée et traitée par une procédure opérationnelle distincte.

## Requirements

### Functional Requirements

- **FR-001**: Le système DOIT garantir au niveau transactionnel ou base de données qu'après chaque commit visible il existe au moins un administrateur actif.
- **FR-002**: Pour une suppression de compte administrateur, la lecture de l'état protégé, la décision de suppression et la désactivation DOIVENT appartenir à une même transaction et utiliser la même connexion.
- **FR-003**: La protection DOIT porter sur une ressource stable commune à toutes les transactions qui décident à partir de l'ensemble des administrateurs actifs, ou être imposée par une contrainte de base de données équivalente.
- **FR-004**: Une transaction concurrente qui attend la protection DOIT réévaluer l'invariant à partir de l'état validé avant de décider; elle NE DOIT PAS agir sur un décompte obsolète lu avant l'attente.
- **FR-005**: Avec exactement deux administrateurs actifs et deux suppressions simultanées valides, une et une seule suppression DOIT réussir et une et une seule DOIT être refusée.
- **FR-006**: Après ces deux opérations, exactement un administrateur DOIT rester actif dans l'état persistant relu après commit.
- **FR-007**: La suppression refusée DOIT retourner le statut HTTP existant 403, le code `LAST_ADMIN_DELETION_FORBIDDEN` et le message public existant, sans exposer d'erreur de verrouillage, de contrainte ou de sérialisation.
- **FR-008**: La suppression réussie DOIT conserver le statut HTTP existant 204 et tous les effets métier existants.
- **FR-009**: La suppression refusée DOIT être sans effet sur le compte visé : il reste actif, conserve son rôle et ne reçoit aucun effet secondaire de suppression persisté.
- **FR-010**: Tous les refresh tokens du compte dont la suppression est refusée DOIVENT conserver leur état antérieur; au moins un token créé avant la course DOIT permettre un renouvellement réel après le refus.
- **FR-011**: Les refresh tokens du compte dont la suppression réussit DOIVENT continuer à être révoqués selon le comportement existant.
- **FR-012**: Toute révocation de refresh tokens liée à la suppression DOIT être ordonnée de façon à ne devenir effective que pour une suppression validée; un rollback ou refus DOIT restaurer intégralement l'état du compte et de ses tokens.
- **FR-013**: Les contrôles existants de confirmation, de mot de passe, d'authentification et d'autorisation ainsi que leur ordre observable NE DOIVENT PAS être modifiés.
- **FR-014**: Aucun statut HTTP, code d'erreur, structure de corps, en-tête ou réponse de succès existant NE DOIT être modifié par cette feature.
- **FR-015**: Un test d'intégration concurrent DOIT utiliser exactement deux administrateurs actifs, deux requêtes ou transactions réelles, deux connexions indépendantes, une barrière de synchronisation et des commits réels.
- **FR-016**: Le test concurrent DOIT vérifier les cardinalités exactes suivantes : un succès 204, un refus 403 avec `LAST_ADMIN_DELETION_FORBIDDEN` et un administrateur actif après les deux commits.
- **FR-017**: Le test concurrent DOIT identifier le compte refusé à partir du résultat observé, vérifier qu'il reste actif et démontrer la validité de son refresh token par un renouvellement effectif.
- **FR-018**: Le test concurrent DOIT vérifier que les refresh tokens du compte supprimé respectent toujours la révocation existante.
- **FR-019**: Le test concurrent DOIT s'exécuter sur le même moteur de base de données et une version compatible avec la production; une base en mémoire ou une simulation de repository ne satisfait pas cette exigence.
- **FR-020**: Le test DOIT contrôler explicitement la simultanéité sans dépendre uniquement de délais arbitraires, et DOIT échouer de manière reproductible sur l'implémentation vulnérable.
- **FR-021**: Les chemins de création, promotion, rétrogradation, réactivation et désactivation pouvant modifier l'ensemble des administrateurs actifs DOIVENT être inventoriés; chacun DOIT employer la même protection ou être accompagné d'une démonstration qu'il ne peut pas violer l'invariant en concurrence.
- **FR-022**: La transaction protégée DOIT être courte, appliquer un ordre de verrouillage unique et respecter les politiques existantes de timeout et de retry afin de limiter contention et deadlocks.
- **FR-023**: Si la correction nécessite une migration, celle-ci DOIT être additive avant activation, compatible avec les versions N et N-1, précédée d'un contrôle des données et réversible sans retirer prématurément la protection de l'invariant.
- **FR-024**: Si aucune migration n'est requise, la conception DOIT démontrer que le protocole choisi reste effectif pendant la coexistence des versions N et N-1; sinon le déploiement progressif DOIT empêcher les anciennes instances de contourner la protection.
- **FR-025**: Les journaux et métriques NE DOIVENT PAS contenir de refresh token et DOIVENT permettre de distinguer une suppression validée d'un refus métier, d'un timeout et d'un rollback.

### Data and Transactional Invariants

- **Active administrator**: utilisateur persistant possédant le rôle administrateur et ne portant pas l'état de désactivation selon le modèle existant.
- **Protected set**: ensemble logique de tous les administrateurs actifs d'une instance; toute décision réduisant cet ensemble doit être coordonnée sur une ressource commune.
- **Commit invariant**: pour tout état validé par une transaction, `nombre(administrateurs actifs) >= 1`.
- **Rejected deletion invariant**: le compte, le rôle, les refresh tokens et les effets secondaires du compte refusé sont identiques avant et après la tentative.
- **Successful deletion invariant**: le compte réussi est désactivé et ses refresh tokens sont révoqués conformément au comportement existant, sans que le nombre d'administrateurs actifs tombe sous un.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Sur 100 % des exécutions du test d'intégration concurrent, exactement une des deux suppressions retourne 204 et exactement une retourne 403 avec `LAST_ADMIN_DELETION_FORBIDDEN`.
- **SC-002**: Après 100 % de ces exécutions, une lecture effectuée dans une nouvelle transaction trouve exactement un administrateur actif.
- **SC-003**: Sur 100 % des exécutions, le compte refusé reste actif et un refresh token émis avant la course permet un renouvellement effectif après le refus.
- **SC-004**: Sur 100 % des exécutions, les tokens du compte supprimé suivent le comportement de révocation existant et ne bénéficient d'aucune régression.
- **SC-005**: Les suites ciblées de suppression de compte, authentification, refresh tokens et contrats d'erreur réussissent sans modification des statuts ni des corps existants.
- **SC-006**: La revue de conception identifie la ressource commune protégée, la frontière transactionnelle, le niveau d'isolation, l'ordre des verrous et tous les chemins modifiant l'ensemble des administrateurs actifs.
- **SC-007**: Le test concurrent échoue sur l'implémentation vulnérable et réussit sur un moteur et une version compatibles avec la production, avec des connexions et commits indépendants.
- **SC-008**: Avant déploiement, un contrôle en lecture confirme qu'aucune instance ciblée ne possède zéro administrateur actif et satisfait toute précondition d'une éventuelle migration.

## Assumptions

- La notion d'administrateur actif est persistée et correspond au rôle administrateur combiné à l'absence de désactivation.
- `DELETE /users/me` retourne actuellement 204 en cas de succès et 403 avec `LAST_ADMIN_DELETION_FORBIDDEN` lorsque le dernier administrateur tente de se supprimer.
- La révocation des refresh tokens du compte supprimé est un comportement existant à préserver.
- Le moteur de production offre un mécanisme permettant de sérialiser les mutations sur une ressource commune ou d'imposer l'invariant en base.
- Le choix précis entre verrou transactionnel, verrou consultatif, ressource sentinelle, contrainte ou autre mécanisme atomique sera arrêté pendant la recherche et la conception, sous réserve de satisfaire tous les invariants de cette spécification.

## Dependencies and Risks

- La sémantique exacte du moteur de production, de sa version et de son niveau d'isolation reste à documenter; un mécanisme correct sur un moteur peut être inefficace dans l'environnement de test ou de production réel.
- L'inventaire des créations, promotions, rétrogradations, réactivations et désactivations d'administrateurs n'est pas encore confirmé. Un seul chemin non coordonné peut contourner la protection.
- L'architecture exacte de stockage et de révocation des refresh tokens doit confirmer qu'un rollback annule toute révocation du compte refusé et qu'aucun effet secondaire non transactionnel ne fuit avant commit.
- Un verrou trop large, une transaction longue ou un ordre incohérent peut provoquer contention, deadlocks, timeouts et hausse de latence sur la gestion des utilisateurs.
- Une migration éventuelle peut introduire des verrous de table, des incompatibilités de données et une coexistence N/N-1 dangereuse; une solution sans migration n'est acceptable que si elle protège aussi le déploiement progressif.
- Le test concurrent peut être faussement rassurant s'il utilise une base en mémoire, une seule connexion, une transaction englobante ou une synchronisation fondée sur le hasard du scheduler.
- La correction ne restaure pas une instance déjà sans administrateur. La détection préalable et une procédure de récupération auditée restent nécessaires hors de cette feature.
- Les seuils opérationnels acceptables pour latence, deadlocks, timeouts et taux de refus doivent être fixés avant déploiement, avec une alerte critique si une instance atteint zéro administrateur actif.
- Le rollback applicatif seul peut réintroduire la course. La protection de données doit rester en place tant qu'une version ancienne capable d'écrire subsiste; à défaut, les suppressions et mutations de rôles administrateur doivent être suspendues pendant le retour arrière.

## Open Decisions and Delivery Gates

- La recherche doit confirmer le moteur, sa version, le niveau d'isolation et le mécanisme commun de sérialisation applicable à tous les chemins concernés.
- Le plan doit préciser si une migration est nécessaire, sa compatibilité N/N-1, ses préconditions de données, la durée de verrouillage attendue et sa stratégie de rollback.
- La mise en œuvre ne peut être déclarée prête au déploiement avant preuve du comportement transactionnel des refresh tokens, réussite du test concurrent sur un moteur compatible production et revue indépendante de la protection.
- Les seuils d'observabilité et la procédure de récupération d'une instance déjà sans administrateur doivent être validés par les responsables Backend, DBA, SRE et Sécurité avant production.

Aucun blocage n'empêche la conception de la feature. La mise en œuvre et le déploiement restent conditionnés aux décisions et preuves ci-dessus; toute absence de protection commune, de transaction unique ou de préservation des tokens du compte refusé maintient le risque critique.
