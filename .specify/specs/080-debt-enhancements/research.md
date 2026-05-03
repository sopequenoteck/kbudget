# Research: 080-debt-enhancements

## Decision 1: Stratégie de remboursement (Transaction liée vs champ dédié)

**Decision**: Créer une Transaction liée à la dette via FK `transactions.debt_id`.

**Rationale**: Le remboursement crée une vraie transaction financière (impact sur le solde du compte). Lier la transaction à la dette permet de calculer le `montantRestant` par agrégation (`montant - SUM(transactions.montant)`), évitant la désynchronisation d'un champ dupliqué. Le pessimistic lock (`findByIdForUpdate()`) prévient les remboursements concurrents.

**Alternatives considered**:
- Champ `montantRembourse` sur Debt : risque de désynchronisation avec les transactions réelles, nécessiterait un recalcul périodique.
- Table `debt_payments` séparée : sur-ingénierie pour un single-user, duplique la notion de Transaction.

## Decision 2: Mode de données (Local+Remote vs Server-only)

**Decision**: Server-only pour repay, snooze, et payments. Pas de Drift/SQLite.

**Rationale**: Les opérations de remboursement nécessitent une cohérence transactionnelle (création atomique transaction + mise à jour dette + calcul remaining). Le mode local ne peut pas garantir cette atomicité. Conforme à l'exception Constitution IV pour les "opérations atomiques".

**Alternatives considered**:
- Mode local-first avec sync : complexité disproportionnée pour des opérations qui modifient l'état serveur.
- Mode hybride (lecture locale, écriture serveur) : incohérence possible entre le cache local et l'état serveur post-repay.

## Decision 3: Forçage devise lors de l'association compte-dette

**Decision**: La devise de la dette est **forcée** à celle du compte associé. Conversion automatique si devise différente via taux de change existants.

**Rationale**: Une dette et son compte doivent partager la même devise pour que les transactions de remboursement soient cohérentes. La conversion à l'association évite les calculs multi-devises à chaque opération.

**Alternatives considered**:
- Permettre des devises différentes dette/compte : complexifie le remboursement (quelle devise pour la transaction ?).
- Interdire l'association si devises différentes : trop restrictif, l'utilisateur peut avoir configuré les taux.

## Decision 4: Inclusion dans le patrimoine (includeInBalance)

**Decision**: Toggle `includeInBalance` pour les dettes sans compte. Les dettes avec compte sont **toujours** incluses (le toggle est masqué).

**Rationale**: Une dette attachée à un compte impacte déjà le patrimoine via le solde du compte. Le toggle n'est utile que pour les dettes autonomes (ex: dette informelle non liée à un compte).

**Alternatives considered**:
- Toggle visible même avec compte : confusant, double-comptage possible.
- Toujours inclure toutes les dettes : retire le contrôle à l'utilisateur pour les dettes informelles.

## Decision 5: Scheduler de rappels (Cron vs fixedDelay)

**Decision**: `fixedDelay = 60_000` ms (vérification minutaire) pour les rappels avec heure précise. Cron `0 0 6 * * *` pour les rappels de type "dette due" (quotidien à 6h).

**Rationale**: Les rappels avec heure configurée nécessitent une précision à la minute. Le fixedDelay est plus adapté qu'un cron pour ce cas. La déduplication via fenêtre de 24h empêche les notifications dupliquées.

**Alternatives considered**:
- Cron toutes les minutes : fonctionnellement identique mais moins lisible.
- Push temps réel (WebSocket trigger) : sur-ingénierie pour un single-user.

## Decision 6: Agrégation solde total multi-devises

**Decision**: Endpoint `GET /accounts/total-balance` agrège comptes + dettes éligibles, groupés par devise.

**Rationale**: Le solde total doit refléter l'impact des dettes sur le patrimoine. L'agrégation serveur évite les calculs côté client et garantit la cohérence. Batch query `sumByDebtIds()` évite le N+1.

**Alternatives considered**:
- Calcul côté client : nécessiterait de charger toutes les transactions de remboursement.
- Endpoint séparé dettes + comptes : double appel réseau, calcul distribué.
