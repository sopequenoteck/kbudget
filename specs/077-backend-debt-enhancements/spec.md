# Feature Specification: Améliorations dettes — Backend

**Feature Branch**: `077-backend-debt-enhancements`
**Created**: 2026-03-09
**Status**: Draft
**Input**: Linear KKS-194 — Enrichissement gestion des dettes : association compte bancaire, remboursement avec transactions, devise, rappels, inclusion dans le patrimoine.
**Parent Issue**: KKS-160

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rembourser une dette (Priority: P1)

L'utilisateur souhaite enregistrer un remboursement partiel ou total d'une dette. Le système crée automatiquement une transaction liée à la dette et met à jour le montant restant. Si la dette est entièrement remboursée, elle est automatiquement marquée comme soldée.

**Why this priority**: Le remboursement est la fonctionnalité centrale de la gestion des dettes. Sans elle, l'utilisateur ne peut pas suivre l'évolution de ses dettes ni savoir combien il reste à payer.

**Independent Test**: Peut être testé en créant une dette, puis en effectuant un remboursement et en vérifiant que la transaction est créée, le montant restant est correct, et la dette est marquée remboursée si montant restant = 0.

**Acceptance Scenarios**:

1. **Given** une dette de 500€ non remboursée avec un compte source disponible, **When** l'utilisateur effectue un remboursement de 200€, **Then** une transaction de 200€ est créée avec un lien vers la dette, et le montant restant est 300€.
2. **Given** une dette de 300€ avec 200€ déjà remboursés, **When** l'utilisateur rembourse les 100€ restants, **Then** la dette est automatiquement marquée comme remboursée (`rembourse = true`).
3. **Given** une dette de 500€, **When** l'utilisateur lance un remboursement sans préciser le montant, **Then** le montant proposé par défaut est le montant restant (500€).
4. **Given** une dette, **When** l'utilisateur consulte l'historique des remboursements, **Then** la liste de toutes les transactions de remboursement avec montant, date et nom du compte est affichée.

---

### User Story 2 - Associer une dette à un compte bancaire (Priority: P2)

L'utilisateur souhaite lier une dette à un compte bancaire spécifique. La devise de la dette est alors automatiquement alignée sur celle du compte. Si la dette est ensuite associée à un autre compte avec une devise différente, une conversion est effectuée.

**Why this priority**: L'association à un compte bancaire permet d'intégrer les dettes dans le suivi financier global et d'assurer la cohérence des devises.

**Independent Test**: Peut être testé en créant une dette avec un compte associé et en vérifiant que la devise est forcée à celle du compte.

**Acceptance Scenarios**:

1. **Given** un compte en EUR, **When** l'utilisateur crée une dette associée à ce compte, **Then** la devise de la dette est automatiquement EUR, quelle que soit la devise de l'utilisateur.
2. **Given** une dette sans compte associé, **When** l'utilisateur associe tardivement un compte en USD, **Then** le montant est converti via les taux de change existants (KKS-156) et la devise est mise à jour.
3. **Given** une dette associée à un compte, **When** l'utilisateur tente d'associer un compte appartenant à un autre utilisateur, **Then** le système refuse avec une erreur de validation.
4. **Given** une dette sans compte, **When** elle est créée, **Then** sa devise est la devise principale de l'utilisateur.

---

### User Story 3 - Inclure une dette dans le patrimoine total (Priority: P3)

L'utilisateur souhaite choisir si une dette sans compte bancaire doit être comptabilisée dans son patrimoine total (solde global). Les dettes associées à un compte sont automatiquement incluses via le solde du compte.

**Why this priority**: Permet une vision patrimoniale complète en incluant les dettes hors comptes bancaires.

**Independent Test**: Peut être testé en activant `includeInBalance` sur une dette sans compte et en vérifiant que le calcul du patrimoine total est impacté.

**Acceptance Scenarios**:

1. **Given** une dette de 200€ sans compte avec `includeInBalance = false`, **When** l'utilisateur consulte son patrimoine total, **Then** cette dette n'est pas prise en compte.
2. **Given** une dette de 200€ sans compte avec `includeInBalance = true`, **When** l'utilisateur consulte son patrimoine total, **Then** cette dette est soustraite (EMPRUNT) ou ajoutée (PRÊT) au total.
3. **Given** une dette de 500€ (EMPRUNT) associée à un compte de 10 000€, **When** l'utilisateur consulte son patrimoine total, **Then** le patrimoine inclut le solde du compte (10 000€) moins le montant restant de la dette (500€), soit un impact net de 9 500€ pour ce compte+dette. Le toggle `includeInBalance` n'est pas disponible (inclusion automatique via le compte).

---

### User Story 4 - Configurer un rappel sur une dette (Priority: P4)

L'utilisateur souhaite programmer un rappel (date et heure) sur une dette. Le système envoie une notification à l'heure prévue avec des actions rapides : reporter ou rembourser.

**Why this priority**: Les rappels sont une fonctionnalité de confort qui améliore l'expérience mais n'est pas bloquante pour le suivi des dettes.

**Independent Test**: Peut être testé en configurant un rappel sur une dette et en vérifiant qu'une notification est créée à l'heure prévue.

**Acceptance Scenarios**:

1. **Given** une dette avec un rappel configuré pour aujourd'hui à 14h00, **When** l'heure 14h00 est atteinte, **Then** une notification est créée avec le titre contenant le nom de la personne et le montant.
2. **Given** une notification de rappel, **When** l'utilisateur choisit "Reporter", **Then** le système met à jour la date et l'heure du rappel selon les nouvelles valeurs fournies.
3. **Given** une dette déjà remboursée, **When** l'heure du rappel est atteinte, **Then** aucune notification n'est créée.

---

### User Story 5 - Reporter un rappel de dette (Priority: P5)

L'utilisateur souhaite reporter le rappel d'une dette à une date et heure ultérieures, directement depuis la notification ou l'écran de détail de la dette.

**Why this priority**: Complément naturel de la US4, permet de gérer les rappels de manière flexible.

**Independent Test**: Peut être testé en appelant l'endpoint de report et en vérifiant que la date/heure de rappel sont mises à jour.

**Acceptance Scenarios**:

1. **Given** une dette avec un rappel au 15 mars à 10h00, **When** l'utilisateur reporte au 20 mars à 14h00, **Then** les champs `reminderDate` et `reminderTime` sont mis à jour.
2. **Given** une dette sans rappel configuré, **When** l'utilisateur tente de reporter, **Then** le système refuse avec une erreur.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur tente de rembourser plus que le montant restant ? → Le système refuse avec une erreur de validation.
- Que se passe-t-il si le compte source du remboursement est supprimé ou désactivé ? → Le système refuse le remboursement si le compte n'est pas actif.
- Que se passe-t-il si un rappel est configuré dans le passé ? → Le rappel est déclenché immédiatement au prochain cycle du scheduler.
- Que se passe-t-il si l'utilisateur dissocie un compte d'une dette qui avait `includeInBalance = false` ? → Le champ `includeInBalance` reste à false, l'utilisateur peut l'activer manuellement.
- Que se passe-t-il si les taux de change ne sont pas disponibles lors d'une association tardive ? → Le système refuse l'association et demande de configurer les taux d'abord.
- Que se passe-t-il si une dette déjà remboursée reçoit un nouveau remboursement ? → Le système refuse car le montant restant est 0.
- Que se passe-t-il si deux remboursements sont soumis simultanément ? → Le montant restant est recalculé dans la transaction ; si le total dépasse le montant initial, le second remboursement est refusé.
- Que se passe-t-il si on dissocie un compte d'une dette ? → La devise reste celle du compte dissocié (pas de reconversion), pour préserver la cohérence avec les remboursements existants.
- Que se passe-t-il si on supprime une dette ayant des remboursements ? → Les transactions de remboursement sont conservées (debtId mis à NULL via FK ON DELETE SET NULL), l'intégrité comptable est préservée. Un test d'intégration doit vérifier ce comportement.
- Que se passe-t-il si on supprime une transaction de remboursement ? → Le montant restant et le statut `rembourse` sont recalculés dynamiquement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre d'enregistrer un remboursement partiel ou total d'une dette, en créant automatiquement une transaction liée.
- **FR-002**: Le système DOIT calculer dynamiquement le montant restant d'une dette comme : montant initial - somme des transactions de remboursement liées (pas de champ persisté).
- **FR-003**: Le système DOIT marquer automatiquement une dette comme remboursée lorsque le montant restant atteint 0.
- **FR-004**: Le système DOIT permettre d'associer une dette à un compte bancaire existant appartenant au même utilisateur.
- **FR-005**: Le système DOIT forcer la devise d'une dette à celle du compte bancaire associé (si un compte est associé).
- **FR-006**: Le système DOIT utiliser la devise principale de l'utilisateur pour les dettes sans compte associé.
- **FR-007**: Le système DOIT convertir le montant initial (`montant`) via les taux de change lors d'une association tardive à un compte ayant une devise différente. Les transactions de remboursement existantes ne sont pas reconverties.
- **FR-008**: Le système DOIT permettre d'inclure ou exclure une dette sans compte du calcul du patrimoine total, via un toggle par dette.
- **FR-009**: Le toggle `includeInBalance` NE DOIT être disponible QUE pour les dettes sans compte bancaire associé.
- **FR-010**: Le système DOIT permettre de configurer un rappel (date + heure) sur une dette.
- **FR-011**: Le système DOIT envoyer une notification à l'heure configurée du rappel, contenant les informations de la dette (personne, montant). La déduplication est assurée par le pattern existant (`existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter` avec fenêtre 24h).
- **FR-012**: Le système DOIT permettre de reporter un rappel en modifiant sa date et son heure.
- **FR-013**: Le système DOIT exposer l'historique des remboursements d'une dette (montant, date, compte utilisé).
- **FR-014**: Le système DOIT refuser un remboursement dont le montant dépasse le montant restant.
- **FR-015**: Le système DOIT refuser un remboursement vers un compte inactif.
- **FR-016**: Le système NE DOIT PAS créer de notification de rappel pour une dette déjà remboursée.
- **FR-017**: Le système DOIT recalculer le montant restant dans la même transaction avant d'accepter un remboursement, pour empêcher tout dépassement.
- **FR-018**: La transaction de remboursement DOIT hériter de la catégorie de la dette (`debt.category`).
- **FR-019**: Le système DOIT exposer un endpoint `GET /accounts/total-balance` retournant le patrimoine total : somme des soldes de tous les comptes **actifs** uniquement, ajustée par TOUTES les dettes non remboursées (EMPRUNT soustrait montantRestant, PRÊT ajoute montantRestant), groupé par devise. Les dettes avec compte sont automatiquement incluses. Le toggle `includeInBalance` ne concerne que les dettes sans compte.
- **FR-020**: Lors de la dissociation d'un compte d'une dette (accountId → NULL), la devise de la dette DOIT rester celle du compte dissocié (pas de reconversion).
- **FR-021**: Lors de la suppression d'une dette ayant des transactions de remboursement, les transactions DOIVENT être conservées (debtId mis à NULL). Pas de suppression en cascade.
- **FR-022**: Le libellé des transactions de remboursement DOIT être auto-généré au format `Remboursement - {personne}`.
- **FR-023**: Le champ `rembourse` DOIT être recalculé dynamiquement (montant restant = 0 → true, sinon false), y compris après suppression d'une transaction de remboursement.

### Key Entities

- **Debt (enrichie)** : Représente une somme due ou prêtée. Enrichie avec : devise (Currency, stockée explicitement), association optionnelle à un compte bancaire, indicateur d'inclusion dans le patrimoine, date et heure de rappel. La devise est forcée à celle du compte associé, ou à la devise principale de l'utilisateur si aucun compte. Relations : appartient à un utilisateur, liée optionnellement à un compte et une catégorie.
- **Transaction (enrichie)** : Représente un mouvement financier. Enrichie avec un lien optionnel vers une dette pour tracer les remboursements. Relations : appartient à un utilisateur et un compte, liée optionnellement à une dette.
- **DebtRepayRequest** : Données nécessaires pour un remboursement — compte source (obligatoire, libre choix parmi les comptes actifs de l'utilisateur), montant (optionnel, défaut = montant restant calculé dynamiquement).
- **DebtPaymentResponse** : Représentation d'un remboursement — identifiant, montant, date, nom du compte source.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut enregistrer un remboursement de dette et voir le montant restant mis à jour en une seule action.
- **SC-002**: La devise d'une dette associée à un compte est automatiquement cohérente avec celle du compte, sans intervention manuelle.
- **SC-003**: Les dettes marquées comme incluses dans le patrimoine sont reflétées dans le calcul du solde global.
- **SC-004**: Les rappels de dette déclenchent une notification dans la minute suivant l'heure configurée.
- **SC-005**: 100% des remboursements créent une transaction traçable liée à la dette d'origine.
- **SC-006**: Le système empêche tout remboursement excédant le montant restant (taux de rejet = 100% des tentatives invalides).

## Clarifications

### Session 2026-03-09

- Q: La devise doit-elle être stockée explicitement sur l'entité Debt ou toujours inférée ? → A: Ajouter un champ `currency` (Currency) sur Debt, mis à jour selon les règles devise (forcé par le compte ou devise principale utilisateur).
- Q: Comment éviter les doublons de notification après déclenchement d'un rappel personnalisé ? → A: Déduplication 24h via `existsByUserIdAndTypeAndEntityIdAndCreatedAtAfter`, cohérent avec le pattern existant des autres notifications. Le rappel reste en place (pas d'effacement ni de flag supplémentaire).
- Q: Comment protéger contre les remboursements concurrents sur la même dette ? → A: Vérification simple dans la même transaction : recalculer le montant restant avant d'accepter, refuser si dépassement. Cohérent avec les patterns existants (app single-user, pas de `@Version` dans le codebase).
- Q: Quelle stratégie de migration pour les dettes existantes (nouveaux champs currency, accountId, includeInBalance, reminder, debtId) ? → A: Migration Flyway avec script SQL : currency déduit depuis la devise principale de l'utilisateur, accountId=NULL, includeInBalance=false, reminder=NULL, debtId=NULL sur Transaction.
- Q: Le montant restant d'une dette est-il stocké ou calculé dynamiquement ? → A: Calculé dynamiquement via SUM des transactions liées (montant initial - somme remboursements). Pas de champ persisté — single-source-of-truth, pas de désynchronisation.
- Q: Le remboursement doit-il utiliser le compte associé à la dette ou l'utilisateur peut-il choisir librement ? → A: Libre choix — l'utilisateur peut rembourser depuis n'importe quel compte actif, indépendamment du compte associé à la dette.
- Q: Quelle catégorie pour les transactions de remboursement ? → A: La catégorie de la dette (`debt.category`) est héritée automatiquement par la transaction de remboursement.
- Q: Comment exposer l'impact des dettes sur le patrimoine total ? → A: Créer un nouvel endpoint `GET /accounts/total-balance` qui agrège les soldes des comptes + les dettes avec `includeInBalance = true` (EMPRUNT soustrait, PRÊT ajoute). Il n'existait aucun endpoint de patrimoine global — les frontends agrègeaient côté client.
- Q: Quand un compte est dissocié d'une dette, que devient la devise ? → A: La devise reste celle du compte dissocié (pas de reconversion), pour préserver la cohérence avec les remboursements déjà effectués.
- Q: Que se passe-t-il quand une dette ayant des remboursements est supprimée ? → A: Les transactions de remboursement sont conservées (debtId mis à NULL), la dette est supprimée. L'intégrité comptable est préservée.
- Q: Quel libellé pour les transactions de remboursement auto-générées ? → A: Format `Remboursement - {personne}` (ex: "Remboursement - Alice").
- Q: Si une transaction de remboursement est supprimée, le statut rembourse est-il recalculé ? → A: Oui, `rembourse` est recalculé dynamiquement (comme le montant restant via FR-002), pour garantir la cohérence.
- Q: Une dette associée à un compte impacte-t-elle automatiquement le patrimoine total ? → A: Oui — le endpoint total-balance inclut TOUTES les dettes non remboursées (avec ou sans compte). Les dettes avec compte sont automatiquement incluses (EMPRUNT soustrait montantRestant, PRÊT ajoute). Le toggle includeInBalance ne concerne que les dettes sans compte.

## Migration

- Migration Flyway (V18+) avec script SQL pour les données existantes :
  - `Debt` : `currency` déduit via JOIN sur `SPLIT_PART(user_preferences.currencies, ',', 1)` (devise principale utilisateur, stockée en VARCHAR CSV), `account_id = NULL`, `include_in_balance = false`, `reminder_date = NULL`, `reminder_time = NULL`
  - `Transaction` : `debt_id = NULL` (colonne nullable ajoutée)

## Assumptions

- Les taux de change (KKS-156) sont déjà disponibles dans le système pour la conversion de devise.
- Le système de notifications (KKS-158 / 072-notification-system) est déjà en place et fonctionnel.
- Le remboursement crée une transaction de type DEPENSE (pour un EMPRUNT) ou RECETTE (pour un PRÊT), cohérent avec le sens de la dette.
- Le scheduler de rappels tourne chaque minute et vérifie les dettes dont la date de rappel est aujourd'hui et l'heure est passée.

## Dependencies

- **KKS-156** : Taux de conversion — nécessaire pour la conversion de devise lors d'une association tardive.
- **KKS-158 / 072-notification-system** : Système de notifications — nécessaire pour les rappels de dette.
