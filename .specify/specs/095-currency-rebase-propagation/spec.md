# Feature Specification: Rebase automatique des taux de change et propagation UI

**Feature Branch**: `095-currency-rebase-propagation`
**Created**: 2026-03-15
**Status**: Draft
**Input**: Automatiser le rebase des taux de change et la propagation UI quand l'utilisateur change sa devise principale

## Clarifications

### Session 2026-03-15

- Q: Si le rebase échoue, que se passe-t-il pour le changement de devise ? → A: Transactionnel — rollback complet (devise principale + taux inchangés).
- Q: Quelle forme prend le feedback visuel pour les taux manquants ? → A: Indicateur sur le total agrégé uniquement (icône/tooltip à côté du solde total converti).
- Q: Que se passe-t-il si le rechargement des taux échoue côté frontend après un rebase réussi ? → A: Message d'erreur + retry possible. Anciennes valeurs affichées avec indicateur "taux périmés".
- Q: Le rebase fonctionne-t-il en mode local Flutter (Drift) ? → A: Non — les taux sont server-only. En mode local, pas de taux configurables donc pas de rebase.
- Q: Un 2ème device connecté est-il informé du rebase ? → A: Oui — via WebSocket STOMP existant, un événement EXCHANGE_RATES_UPDATED est poussé pour déclencher le rechargement automatique.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Changement de devise principale avec rebase automatique (Priority: P1)

L'utilisateur utilise l'application avec EUR comme devise principale et possède des taux de change configurés (ex: 1 EUR = 655.957 XOF, 1 EUR = 1.08 USD). Il décide de passer sa devise principale à XOF. Dès qu'il valide ce changement, tous ses taux de change sont automatiquement recalculés avec XOF comme nouvelle base (ex: 1 XOF = 0.001524 EUR, 1 XOF = 0.001647 USD). Les montants affichés sur toutes les pages (dashboard, budgets, dettes, abonnements) se mettent à jour instantanément sans que l'utilisateur ait besoin de rafraîchir manuellement.

**Why this priority**: C'est le coeur du problème. Sans rebase automatique, tous les montants convertis sont faux après un changement de devise principale, rendant l'application inutilisable pour un utilisateur multi-devises.

**Independent Test**: Peut être testé en changeant la devise principale dans les paramètres et en vérifiant que les montants convertis sur le dashboard sont immédiatement corrects.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec EUR comme devise principale et des taux EUR→XOF et EUR→USD configurés, **When** il change sa devise principale à XOF, **Then** tous les taux sont automatiquement rebasés sur XOF et les montants affichés sur le dashboard reflètent les nouvelles conversions.
2. **Given** un utilisateur avec EUR comme devise principale, **When** il change sa devise principale à XOF, **Then** il n'a pas besoin de reconfigurer manuellement ses taux de change.
3. **Given** un utilisateur qui vient de changer sa devise principale, **When** il navigue vers les budgets, dettes ou abonnements, **Then** les montants convertis utilisent les nouveaux taux rebasés.

---

### User Story 2 - Rafraîchissement instantané de l'interface après changement (Priority: P1)

Après le changement de devise principale, l'interface se met à jour en temps réel sans rechargement de page. Le dashboard, les listes de budgets, dettes et abonnements affichent immédiatement les montants dans la nouvelle devise principale avec les conversions correctes.

**Why this priority**: Même si le rebase backend fonctionne, sans propagation frontend les données affichées restent périmées jusqu'au prochain rechargement, créant une incohérence visible.

**Independent Test**: Après changement de devise, vérifier que le dashboard et les écrans de listes affichent les montants mis à jour sans navigation manuelle.

**Acceptance Scenarios**:

1. **Given** un utilisateur sur le dashboard avec des comptes multi-devises, **When** il change sa devise principale dans les paramètres, **Then** le solde total converti sur le dashboard se recalcule instantanément avec les nouveaux taux.
2. **Given** un utilisateur avec des dettes en devises étrangères, **When** il change sa devise principale, **Then** les montants estimés ("~ X EUR") sur la liste des dettes se mettent à jour sans quitter l'écran.
3. **Given** un utilisateur sur l'application mobile (Flutter), **When** il change sa devise principale, **Then** les mêmes mises à jour instantanées se produisent que sur la version web.

---

### User Story 3 - Feedback utilisateur en cas de taux manquant (Priority: P2)

Lorsqu'une conversion est impossible (taux manquant entre deux devises), l'utilisateur est informé clairement plutôt que de voir un montant disparaître silencieusement. Un indicateur visuel lui signale quels montants n'ont pas pu être convertis.

**Why this priority**: Améliore la confiance de l'utilisateur dans les montants affichés. Sans feedback, l'utilisateur pourrait croire que ses totaux sont complets alors que certaines conversions ont été ignorées.

**Independent Test**: Supprimer un taux de change puis vérifier qu'un indicateur apparaît sur les montants concernés.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec un compte en GBP mais sans taux GBP→devise principale configuré, **When** il consulte le dashboard, **Then** une icône avec tooltip à côté du solde total converti signale que le total est partiel (certaines conversions manquantes).
2. **Given** une dette en USD sans taux USD→devise principale, **When** l'utilisateur consulte la liste des dettes, **Then** la dette affiche son montant natif dans sa devise d'origine (pas de conversion affichée, pas de disparition silencieuse).

---

### Edge Cases

- Que se passe-t-il si l'utilisateur n'a qu'une seule devise configurée (pas de taux de change) ? Aucun rebase nécessaire, aucun changement visible.
- Que se passe-t-il si l'utilisateur change rapidement de devise principale plusieurs fois de suite ? Chaque changement doit rebaser correctement sans corruption des taux (idempotence). Le dernier changement l'emporte (sérialisation via transaction côté serveur).
- Que se passe-t-il si le rebase backend échoue ? L'opération complète est annulée (rollback transactionnel) : la devise principale et les taux restent inchangés. L'utilisateur est informé de l'échec.
- Que se passe-t-il pour les snapshots de budget historiques ? Les snapshots conservent le taux de change au moment de la capture (comportement existant, inchangé).
- Que se passe-t-il si deux devises n'ont pas de taux direct ni de cross-rate possible ? Le système signale le taux manquant plutôt que d'afficher un montant erroné.
- Que se passe-t-il si le rechargement des taux échoue côté frontend après un rebase backend réussi ? Le frontend affiche un message d'erreur, permet un retry, et garde les anciennes valeurs avec un indicateur "taux périmés".
- Que se passe-t-il si l'utilisateur est connecté sur 2 devices et change la devise sur l'un ? Le serveur push un événement WebSocket STOMP au 2ème device, qui recharge automatiquement ses taux.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT automatiquement rebaser tous les taux de change de l'utilisateur quand sa devise principale change (réordonnancement de la liste des devises).
- **FR-002**: Le rebase DOIT être déclenché côté serveur au moment de la sauvegarde des préférences, avant de renvoyer la réponse. L'opération DOIT être transactionnelle : si le rebase échoue, le changement de devise principale est annulé (rollback complet).
- **FR-003**: Les applications clientes (web et mobile) DOIVENT recharger les taux de change depuis le serveur après un changement de devise principale.
- **FR-004**: Les interfaces DOIVENT se mettre à jour automatiquement après le rechargement des taux, sans action manuelle de l'utilisateur.
- **FR-005**: Le système DOIT afficher un indicateur visuel sur le total agrégé (icône/tooltip à côté du solde total converti) quand au moins une conversion a échoué faute de taux de change disponible. Les montants individuels non convertis restent affichés dans leur devise native sans marquage inline — le montant natif est toujours correct, seule la conversion en devise principale est absente.
- **FR-006**: Le système DOIT gérer les changements rapides successifs de devise principale sans corruption des taux. Le dernier changement l'emporte (sérialisation côté serveur via transaction). Si `oldPrimary == newPrimary`, aucun rebase n'est déclenché (no-op).
- **FR-007**: Le système NE DOIT PAS modifier les snapshots de budget historiques lors d'un rebase (les taux capturés au moment du snapshot sont immuables).
- **FR-008**: Si le rechargement des taux échoue côté frontend après un rebase réussi, le système DOIT afficher un message d'erreur et permettre un retry. Les valeurs précédentes restent affichées avec un indicateur "taux périmés".
- **FR-009**: Après un rebase, le serveur DOIT envoyer un événement WebSocket STOMP (`EXCHANGE_RATES_UPDATED`) à l'utilisateur pour que les autres devices connectés rechargent automatiquement les taux.

### Key Entities

- **ExchangeRate**: Taux de change entre deux devises pour un utilisateur. Attributs clés : devise de base, devise cible, taux, date de mise à jour. Contraint par l'unicité (utilisateur + base + cible).
- **UserPreference**: Préférences utilisateur incluant la liste ordonnée des devises (le premier élément est la devise principale).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Après un changement de devise principale, 100% des taux de change existants sont automatiquement rebasés sans intervention manuelle.
- **SC-002**: Les montants convertis affichés sur toutes les pages se mettent à jour en moins de 2 secondes après le clic de l'utilisateur sur le changement de devise principale.
- **SC-003**: Les conversions impossibles (taux manquant) sont signalées visuellement via un indicateur sur le total agrégé du dashboard (web et mobile).
- **SC-004**: Les changements successifs rapides de devise principale (3+ changements en moins de 10 secondes) ne corrompent pas les taux de change.
- **SC-005**: Les snapshots de budget historiques restent inchangés après un rebase (vérifiable par comparaison avant/après).

## Assumptions

- Le mécanisme de rebase (`rebaseRates`) existe déjà côté serveur et fonctionne correctement (inversion + cross-rate). Seul le déclencheur automatique manque.
- Les frameworks frontend (Angular Signals, Flutter Riverpod) propagent automatiquement les changements d'état aux composants qui les observent. Le travail frontend consiste à déclencher le rechargement des données, pas à gérer la propagation.
- L'application est single-user. Le multi-device simultané est géré via WebSocket STOMP (push d'événement après rebase).
- Les taux de change sont server-only dans Flutter (pas de table Drift). En mode local, les taux ne sont pas disponibles et aucun rebase n'est nécessaire.
