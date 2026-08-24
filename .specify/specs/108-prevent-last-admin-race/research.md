# Research: suppression atomique du dernier administrateur

**Issue**: DEMO-007  
**Date**: 2026-08-18  
**Spec**: [spec.md](./spec.md)  
**Profil**: critical

## Contexte technique confirme

- Le chemin `DELETE /users/me` appelle `UserDeletionService.softDelete()`; la confirmation et le mot de passe sont verifies avant la garde du dernier administrateur.
- `softDelete()` est deja `@Transactional`. Dans cette transaction, il execute `countActiveAdmins()`, renseigne `users.disabled_at`, puis appelle `RefreshTokenService.revokeAllUserTokens()`. Ce dernier participe par propagation par defaut a la transaction appelante. Une exception metier levee avant ces mutations laisse donc actuellement le compte et ses tokens inchanges.
- `countActiveAdmins()` est une simple agregation JPQL sans verrou. Sous l'isolation PostgreSQL par defaut `READ COMMITTED`, deux transactions peuvent lire le meme cardinal avant que l'une des desactivations soit validee: la course decrite est donc presente.
- La production utilise le pilote PostgreSQL et Flyway. L'environnement de developpement declare `postgres:16-alpine`; la version exacte de la base de production n'est pas fixee dans le depot. Les tests ordinaires utilisent H2 avec `create-drop`, et le projet ne declare actuellement pas Testcontainers.
- L'administrateur actif est represente par `users.is_admin = true AND users.disabled_at IS NULL`. Les refresh tokens sont des lignes persistantes dont le statut passe de `ACTIVE` a `REVOKED`.
- Les mutations d'administrateurs trouvees sont: provisionnement avec `isAdmin` dans `UserOnboardingService`, promotion au demarrage depuis `ADMIN_EMAILS` dans `AdminSyncRunner`, et soft-delete dans `UserDeletionService`. Aucun chemin applicatif de retrogradation ou de reactivation n'a ete trouve. Le bootstrap et les tests construisent aussi des administrateurs, mais ne constituent pas des mutations HTTP concurrentes en fonctionnement normal.

Ces constats confirment R1, R3, R4 et R9 de l'evaluation des risques: la lecture non verrouillee est vulnerable, la frontiere transactionnelle existe mais doit englober une ressource commune, la revocation est transactionnelle, et H2 ne peut pas prouver la semantique PostgreSQL attendue.

## R1 — Mecanisme de serialisation commun

**Decision**: Acquerir un verrou consultatif transactionnel PostgreSQL exclusif, avec une cle numerique constante et documentee reservee a l'invariant des administrateurs actifs, via `pg_advisory_xact_lock`, avant de compter les administrateurs actifs. Toutes les mutations capables de reduire ou de modifier l'ensemble protege doivent utiliser le meme composant de verrouillage et la meme cle. Apres acquisition, la transaction relit `countActiveAdmins()` puis decide de refuser ou de poursuivre.

**Justification**:

- Le verrou porte sur une ressource stable commune, independante des lignes cibles; deux suppressions de comptes differents sont donc serialisees, ce qui satisfait FR-003 et mitige R1/R2.
- La variante transactionnelle est liberee automatiquement au commit ou au rollback, y compris sur exception, et utilise la connexion de la transaction courante. Elle satisfait FR-002/R3 sans etat de verrou persistant ni nettoyage.
- Sous `READ COMMITTED`, chaque instruction qui suit l'acquisition voit les commits acheves pendant l'attente. Le second appel recompte donc apres le commit du premier et retourne l'erreur metier existante, ce qui satisfait FR-004 a FR-007.
- La transaction reste courte: validations preexistantes d'abord, puis verrou, recomptage, desactivation et revocation. Une seule classe de verrou est necessaire, avec un ordre unique, ce qui limite R7 et satisfait FR-022.
- PostgreSQL 16, declare pour le developpement, supporte ce mecanisme sans migration. La version de production doit toutefois etre confirmee avant implementation et le test doit utiliser une version identique ou explicitement compatible.

**Detail de conception attendu**:

1. Conserver les validations de confirmation et de mot de passe dans leur ordre actuel, avant l'acquisition, afin de satisfaire FR-013 et de ne pas allonger inutilement la section critique.
2. Pour un compte non administrateur, conserver le chemin actuel sans verrou, car sa desactivation ne reduit pas l'ensemble protege.
3. Pour un administrateur, acquerir le verrou transactionnel, recharger si necessaire l'utilisateur dans la transaction, puis compter les administrateurs actifs.
4. Si le compte courant est actif et le compte est inferieur ou egal a un, lever `LastAdminDeletionForbiddenException` avant toute mutation.
5. Sinon, desactiver le compte et revoquer ses tokens dans la meme transaction, puis laisser le commit liberer le verrou.

**Alternatives etudiees**:

- Verrou pessimiste sur le compte supprime: rejete, car les deux transactions verrouillent des lignes differentes et prennent une decision sur la meme agregation; R2 reste entier.
- `SELECT ... FOR UPDATE` de toutes les lignes administrateur: rejete comme mecanisme principal. Il augmente la contention, son ensemble de lignes est instable face aux insertions et promotions, et les verrous de lignes ne protegent pas naturellement l'absence ou les phantoms sous `READ COMMITTED`.
- Isolation `SERIALIZABLE`: non retenue. Elle peut detecter l'anomalie, mais expose une erreur de serialisation qu'il faut rejouer et traduire; sans protocole de retry borne, elle ne garantit pas directement que le perdant recoit `LAST_ADMIN_DELETION_FORBIDDEN`. Elle elargit aussi le cout transactionnel et le risque R6/R7.
- Table sentinelle avec une ligne verrouillee `FOR UPDATE`: techniquement correcte et portable au niveau SQL, mais rejetee ici car elle exige une migration et une ligne de reference a initialiser et maintenir alors que PostgreSQL fournit deja une ressource transactionnelle stable. Elle resterait le choix de repli si les verrous consultatifs sont interdits par l'exploitation.
- Trigger ou contrainte declarative garantissant au moins une ligne active: rejetes. Une contrainte de ligne ou un index partiel ne peut pas exprimer simplement une cardinalite globale minimale; un trigger devrait lui-meme definir un protocole de verrouillage commun et complexifierait la traduction vers le contrat HTTP.
- Verrou JVM (`synchronized`, mutex local): rejete, car il ne coordonne ni plusieurs instances applicatives ni les ecritures hors processus.

## R2 — Frontiere transactionnelle et refresh tokens

**Decision**: Conserver la desactivation du compte et `revokeAllUserTokens()` dans la transaction Spring de `softDelete()`, et placer toute la section acquisition-relecture-decision-mutations dans cette meme methode transactionnelle. Aucun `REQUIRES_NEW`, appel asynchrone ou effet de succes avant commit ne doit etre introduit.

**Justification**:

- `RefreshTokenService` est transactionnel avec la propagation `REQUIRED` par defaut; son appel interne participe donc a la transaction de suppression. Un refus avant mutation conserve tous les tokens, et une exception ulterieure annule conjointement compte et revocations, conformement a FR-009, FR-010 et FR-012 et en mitigation de R4.
- La suppression gagnante conserve exactement le comportement de revocation existant, conformement a FR-008/FR-011 et en mitigation de R5.
- L'exception metier existante continue d'etre traitee par le gestionnaire global; aucune exception PostgreSQL attendue n'a a etre exposee ou convertie dans le chemin nominal, ce qui preserve R6, FR-007 et FR-014.

**Alternatives etudiees**:

- Revoquer avant le verrou ou avant la decision: rejete, car un refus pourrait invalider la session du dernier administrateur.
- Revoquer apres commit ou dans une tache asynchrone: rejete, car une fenetre laisserait les tokens du compte desactive valides et un echec produirait un etat partiel.
- Ouvrir une transaction separee pour les tokens: rejete, car son commit ne serait pas annule avec celui du compte.

## R3 — Couverture des autres mutations d'administrateurs

**Decision**: Etendre le protocole de verrou commun a tout chemin runtime qui modifie `is_admin` ou reactive/desactive un administrateur. Dans le code actuellement inventorie, `UserDeletionService` est le seul chemin qui reduit le cardinal; `UserOnboardingService` et `AdminSyncRunner` ne font qu'ajouter des administrateurs. Ils doivent neanmoins utiliser le meme verrou lors de l'implementation afin d'etablir une regle unique et de rendre les evolutions futures sures. Toute future retrogradation, reactivation ou desactivation administrative devra passer par ce composant.

**Justification**:

- Une promotion ou creation concurrente ne peut pas, a elle seule, faire tomber le cardinal sous un; elle ne contredit donc pas la correction minimale. La coordonner formalise cependant le `protected set` de FR-021 et ferme le risque R2 si ces chemins evoluent ou ajoutent des decisions basees sur le cardinal.
- L'inventaire doit etre reexecute dans le plan puis en revue, notamment pour les scripts SQL, migrations, jobs et nouveaux endpoints. Les ecritures DBA directes restent hors du controle applicatif et doivent etre encadrees operationnellement.

**Alternatives etudiees**:

- Ne verrouiller que `UserDeletionService`: suffisant pour la course DEMO-007 avec le code actuel, mais rejete comme regle de conception car FR-021 exige l'inventaire et une protection partagee ou une preuve d'absence de conflit.
- Interdire toute creation/promotion pendant une suppression: rejete, car cela deplace la coherence dans une procedure d'exploitation sans enforcement applicatif.

## R4 — Strategie du test d'integration concurrent

**Decision**: Ajouter une suite d'integration dediee a PostgreSQL reel, provisionne par Testcontainers avec une image PostgreSQL de meme version majeure que la production confirmee. Le test appelle l'API par deux requetes HTTP authentifiees independantes, sans transaction de test englobante, depuis un pool de deux threads. Une barriere de depart (`CyclicBarrier` ou deux latches start/ready) libere les deux requetes ensemble; chaque requete utilise sa propre connexion acquise par le serveur et effectue un commit reel.

**Oracles obligatoires**:

1. Creer exactement deux comptes administrateurs actifs, avec mots de passe et refresh tokens distincts, puis confirmer qu'aucun autre administrateur actif ne provient du bootstrap ou de `ADMIN_EMAILS`.
2. Authentifier chaque requete comme le compte qu'elle supprime et preparer les deux workers avant d'ouvrir la barriere.
3. Attendre les deux reponses avec un timeout borne; compter exactement un HTTP 204 et un HTTP 403.
4. Verifier le corps 403 complet selon le contrat existant, dont `error = LAST_ADMIN_DELETION_FORBIDDEN` et le message public existant.
5. Dans une nouvelle transaction/connexion apres les deux terminaisons, verifier exactement un administrateur actif et identifier le compte refuse a partir de la reponse observee.
6. Appeler reellement l'endpoint de refresh avec le token preexistant du compte refuse; verifier le renouvellement reussi et le maintien du compte actif et administrateur.
7. Appeler le meme endpoint avec le token du compte supprime et verifier l'echec de revocation conforme au contrat existant.
8. Repeter le scenario un nombre borne de fois ou avec les deux ordres de soumission afin de varier le gagnant sans transformer le test en test de probabilite.

**Fiabilite et preuve de regression**:

- La barriere de depart prouve que les appels sont emis ensemble, mais ne garantit pas a elle seule que l'ancienne implementation intercale ses deux lectures avant les updates. Pour satisfaire FR-020/SC-007, la mise en oeuvre du test doit ajouter un point de coordination testable au niveau du composant de garde, sans delai arbitraire et sans modifier le comportement de production: les deux workers signalent leur entree dans la garde; en mode regression de l'ancien protocole, ils sont liberes seulement apres que les deux lectures vulnerables ont eu lieu. Pour la version corrigee, le test principal doit conserver le verrou PostgreSQL reel et demontrer que le second worker ne peut prendre sa decision qu'apres le commit du premier.
- Si ce point de coordination ne peut etre ajoute sans coupler le code de production au test, une preuve mutationnelle ponctuelle est requise: desactiver localement l'acquisition du verrou, executer le scenario sous orchestration controlee et conserver le rapport montrant les deux 204. Une simple repetition fondee sur le timing ne satisfait pas FR-020.
- Les timeouts doivent echouer explicitement le test et liberer executors/containers en `finally`; aucun `sleep` ne doit servir de synchronisation.

**Alternatives etudiees**:

- H2 ou repository simule: rejetes, car H2 ne fournit pas la semantique de `pg_advisory_xact_lock` et ne satisfait pas FR-019/R9.
- Deux appels sequentiels: rejetes, car ils ne couvrent pas la fenetre de course.
- `Thread.sleep` pour provoquer l'interleaving: rejete, car non deterministe et contraire a FR-020/R8.
- Test direct du service avec repositories mocks: utile en unitaire pour l'ordre des appels, mais rejete comme preuve centrale car il ne valide ni connexions, ni verrous, ni commits, ni contrat HTTP.

## R5 — Compatibilite de deploiement, migration et rollback

**Decision**: Ne pas creer de migration pour le choix principal. Deployer avec une phase de maintenance qui suspend `DELETE /users/me` et toute mutation de role administrateur tant que des instances N-1 vulnerables peuvent recevoir des ecritures; activer ensuite uniquement les instances utilisant le protocole commun, executer le controle de cardinalite, puis rouvrir les mutations. Le rollback vers N-1 doit de nouveau suspendre ces mutations jusqu'a restauration d'une version protegee.

**Justification**:

- Un verrou consultatif n'est efficace que pour les participants qui respectent la meme cle. Une instance N-1 ne l'acquiert pas et peut contourner la protection pendant un rolling deploy, ce qui materialise R11/FR-024.
- L'absence de migration supprime R10 lie aux verrous DDL et aux donnees sentinelles, mais ne rend pas la coexistence N/N-1 sure. La suspension explicite est donc un gate de deploiement, pas une recommandation optionnelle.
- Le rollback applicatif seul reintroduit la course (R13). La mesure sure est de garder le chemin ferme jusqu'au redeploiement d'une version protegee.

**Alternatives etudiees**:

- Rolling deploy sans suspension: rejete, car les anciennes instances ne participent pas au verrou.
- Migration ajoutant une sentinelle, puis anciennes instances inchangees: rejetee comme solution a N/N-1; l'ancienne application n'acquiert pas davantage le verrou de cette ligne.
- Trigger base de donnees deploye avant le code: pourrait proteger N/N-1, mais rejete pour la complexite et les risques de contrat/deadlock mentionnes en R1. Il ne doit etre reconsidere que si une interruption des mutations est operationnellement impossible.

## R6 — Contrats, observabilite et comportement des erreurs

**Decision**: Ne modifier ni le controleur, ni `LastAdminDeletionForbiddenException`, ni son mapping global. Journaliser l'acquisition/attente sans cle sensible, distinguer succes, refus metier, timeout/deadlock et rollback, et ne jamais journaliser les refresh tokens. Utiliser les politiques de timeout de transaction/verrou deja approuvees; en leur absence, les fixer dans le plan avant production plutot que convertir arbitrairement tout incident de base en `LAST_ADMIN_DELETION_FORBIDDEN`.

**Justification**:

- Seul le recomptage apres serialisation doit produire le refus metier. Un timeout ou une panne PostgreSQL n'etablit pas que le compte est le dernier administrateur; le convertir en 403 masquerait un incident et violerait le sens du contrat (R6).
- Les metriques demandees par R12/FR-025 doivent inclure le minimum d'administrateurs actifs, les 403 metier, les 5xx, la latence/attente du verrou, deadlocks/timeouts et erreurs de refresh, sans secret.

**Alternatives etudiees**:

- Mapper toute exception de verrou vers `LAST_ADMIN_DELETION_FORBIDDEN`: rejete, car factuellement faux et susceptible de cacher une indisponibilite.
- Modifier le statut ou ajouter un nouveau code de conflit: rejete explicitement par FR-007, FR-014 et l'objectif.

## Matrice decisions — exigences et risques

| Decision | Exigences couvertes | Risques principalement traites |
|---|---|---|
| R1 verrou consultatif transactionnel commun et recomptage apres acquisition | FR-001 a FR-007, FR-022 | R1, R2, R3, R7 |
| R2 compte et tokens dans une transaction unique | FR-008 a FR-012 | R4, R5 |
| R3 inventaire et protocole partage | FR-003, FR-021 | R2, R11 |
| R4 test HTTP PostgreSQL concurrent et oracles tokens | FR-015 a FR-020, SC-001 a SC-007 | R6, R8, R9 |
| R5 suspension N/N-1 et rollback protege | FR-023, FR-024 | R10, R11, R13 |
| R6 contrat et observabilite inchanges | FR-007, FR-013, FR-014, FR-025 | R6, R12 |

## Risques residuels et gates

- **Version et politique PostgreSQL**: le depot confirme PostgreSQL 16 en developpement, pas la version exacte de production ni l'autorisation operationnelle des verrous consultatifs. Backend/DBA doivent les confirmer avant implementation; sinon la table sentinelle devient l'option de repli.
- **Testcontainers absent**: la dependance et l'image de test PostgreSQL devront etre ajoutees pendant l'implementation. L'acces Docker en CI et la version d'image doivent etre valides avant que SC-007 puisse etre prouve.
- **Determinisme de la preuve avant correction**: une simple barriere HTTP ne force pas l'interleaving interne vulnerable. Le plan doit choisir et faire revoir le point de coordination ou la preuve mutationnelle decrite en R4; sans cela FR-020 reste non satisfait.
- **Inventaire hors application**: les ecritures SQL/DBA directes et d'eventuels consommateurs non presents dans le depot ne prennent pas le verrou. Leur interdiction ou leur adoption de la meme cle doit etre documentee par l'exploitation.
- **Deploiement N/N-1**: aucun rolling deploy melange n'est sur avec le mecanisme retenu. La capacite a suspendre les mutations administrateur est un gate; si elle n'existe pas, la conception doit revenir a une protection base de donnees enforcee pour les anciennes versions.
- **Timeouts et capacite**: aucun seuil SRE explicite de temps d'attente, deadlocks ou latence n'a ete trouve. Ils doivent etre fixes avant deploiement et testes sous contention, conformement a R7/R12.
- **Etat preexistant**: avant activation, une requete en lecture doit verifier qu'au moins un administrateur actif existe. La recuperation d'une instance deja a zero reste hors perimetre et requiert la procedure auditee de R14.
- **Effets secondaires**: aucun evenement non transactionnel de suppression n'est visible dans le chemin inspecte. Une revue d'implementation doit reconfirmer ce point et empecher toute journalisation de succes avant commit.

## Conclusion

Le choix recommande est un verrou PostgreSQL `pg_advisory_xact_lock` commun, acquis dans la transaction existante avant tout recomptage, suivi de la decision, de la desactivation et de la revocation transactionnelle. Il corrige atomiquement la course sans migration ni changement du contrat HTTP. Son acceptation reste conditionnee a un test concurrent PostgreSQL deterministe, a la confirmation de l'environnement de production, a l'alignement de toutes les mutations d'administrateurs et a une procedure de deploiement/rollback qui empeche toute instance N-1 de contourner le protocole.
