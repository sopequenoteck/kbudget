# Feature Specification: Transactions Recurrentes & Paiements Abonnements (Backend)

**Feature Branch**: `085-recurring-transactions-backend`
**Created**: 2026-03-14
**Status**: Draft
**Input**: KKS-191 — Sous-issue backend de KKS-159. Ajout de la notion de transactions recurrentes et enrichissement des abonnements pour generer des paiements tracables.
**Linear**: KKS-191
**Bloque**: KKS-192 (Angular), KKS-193 (Flutter)

## User Scenarios & Testing

### User Story 1 - Validation d'une transaction recurrente (Priority: P1)

L'utilisateur recoit une notification lui rappelant qu'une depense recurrente est due aujourd'hui (ex: "Loyer 800EUR - aujourd'hui"). Il consulte la liste de ses recurrences actives, puis valide l'occurrence. Le systeme cree automatiquement la transaction correspondante et avance la prochaine echeance selon la frequence definie.

**Why this priority**: C'est le coeur de la feature — permettre a l'utilisateur de valider manuellement ses depenses recurrentes (loyer, electricite, etc.) tout en gardant le controle total. Sans cette fonctionnalite, les recurrences n'ont aucune utilite.

**Independent Test**: Creer une transaction recurrente, appeler l'endpoint de validation, verifier qu'une transaction est creee et que la date de prochaine occurrence est avancee.

**Acceptance Scenarios**:

1. **Given** une transaction recurrente active avec nextOccurrence <= aujourd'hui, **When** l'utilisateur valide l'occurrence, **Then** une transaction est creee avec le meme montant/libelle/type/category/account et nextOccurrence avance au prochain cycle selon la frequence
2. **Given** une transaction recurrente avec nextOccurrence dans le futur, **When** l'utilisateur valide l'occurrence, **Then** la validation est acceptee (validation anticipee), la transaction est creee et nextOccurrence avance
3. **Given** une transaction recurrente desactivee, **When** l'utilisateur tente de valider, **Then** le systeme refuse avec une erreur appropriee

---

### User Story 2 - Paiement d'un abonnement (Priority: P1)

L'utilisateur recoit une notification de renouvellement d'abonnement (ex: "Netflix 13,49EUR - renouvellement aujourd'hui"). Il valide le paiement, ce qui cree une transaction liee a l'abonnement. Il peut ensuite consulter l'historique des paiements et le cumul total pour cet abonnement.

**Why this priority**: Les abonnements existants n'ont pas de tracabilite des paiements. Cette fonctionnalite complete le cycle de vie des abonnements et permet a l'utilisateur de savoir combien il a reellement depense par abonnement.

**Independent Test**: Payer un abonnement, verifier la creation de transaction liee, consulter l'historique et le cumul.

**Acceptance Scenarios**:

1. **Given** un abonnement actif a echeance avec un compte associe, **When** l'utilisateur paie, **Then** une transaction est creee avec le montant de l'abonnement sur le compte de l'abonnement, liee par subscriptionId (dateDebut inchangee — prochaine echeance calculee dynamiquement)
2. **Given** un abonnement actif a echeance sans compte associe, **When** l'utilisateur paie, **Then** une transaction est creee sur le compte par defaut de l'utilisateur
3. **Given** un abonnement avec plusieurs paiements, **When** l'utilisateur consulte l'historique, **Then** il voit la liste des transactions liees avec montant et date
4. **Given** un abonnement avec plusieurs paiements, **When** l'utilisateur consulte le cumul, **Then** il voit le total des montants payes
5. **Given** un abonnement inactif, **When** l'utilisateur tente de payer, **Then** le systeme refuse avec une erreur appropriee

---

### User Story 3 - Notification automatique des echeances (Priority: P2)

Chaque jour a 8h, le systeme detecte les transactions recurrentes et abonnements arrives a echeance. Pour chacun, une notification est creee pour informer l'utilisateur. Aucune transaction n'est creee automatiquement — l'utilisateur reste maitre de la validation.

**Why this priority**: Le scheduler est le declencheur du workflow. Sans lui, l'utilisateur devrait manuellement verifier ses echeances, ce qui reduit fortement l'utilite de la feature.

**Independent Test**: Configurer des recurrences/abonnements avec echeance <= aujourd'hui, declencher le scheduler, verifier que les notifications sont creees.

**Acceptance Scenarios**:

1. **Given** des transactions recurrentes actives avec nextOccurrence <= aujourd'hui, **When** le scheduler recurrences (8h) s'execute, **Then** une notification est creee pour chaque occurrence due
2. **Given** des abonnements actifs a echeance, **When** le scheduler abonnements existant (6h) s'execute, **Then** le comportement existant est inchange (notification la veille de l'echeance)
3. **Given** aucune echeance due, **When** les schedulers s'executent, **Then** aucune notification n'est creee

---

### User Story 4 - Passer ou desactiver une recurrence (Priority: P2)

L'utilisateur peut passer une occurrence sans creer de transaction (ex: mois gratuit) ou desactiver completement une recurrence.

**Why this priority**: Complementaire a la validation, ces actions donnent le controle total a l'utilisateur sur ses recurrences.

**Independent Test**: Passer une occurrence et verifier que nextOccurrence avance sans transaction creee. Desactiver et verifier que la recurrence n'apparait plus dans la liste active.

**Acceptance Scenarios**:

1. **Given** une transaction recurrente active, **When** l'utilisateur passe l'occurrence, **Then** nextOccurrence avance au prochain cycle sans creation de transaction
2. **Given** une transaction recurrente active, **When** l'utilisateur la desactive, **Then** recurringActive passe a false et la transaction n'apparait plus dans la liste des recurrences actives
3. **Given** une transaction recurrente desactivee, **When** le scheduler s'execute, **Then** aucune notification n'est creee pour cette recurrence

---

### User Story 5 - Consultation des recurrences actives (Priority: P3)

L'utilisateur consulte la liste de toutes ses transactions recurrentes actives avec leur prochaine echeance, frequence et montant.

**Why this priority**: Necessaire pour que l'utilisateur ait une vue d'ensemble, mais c'est un endpoint de lecture simple.

**Independent Test**: Creer plusieurs recurrences, appeler l'endpoint de liste, verifier le contenu retourne.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des transactions recurrentes actives, **When** il consulte la liste, **Then** il voit toutes ses recurrences avec libelle, montant, type, frequence, prochaine echeance, categorie et compte
2. **Given** l'utilisateur n'a aucune recurrence active, **When** il consulte la liste, **Then** une liste vide est retournee

---

### Edge Cases

- Que se passe-t-il si une recurrence a plusieurs occurrences en retard (nextOccurrence << aujourd'hui) ? Le scheduler cree une notification chaque jour tant que l'occurrence n'est pas validee. L'utilisateur valide, le systeme avance au prochain cycle (pas de rattrapage automatique des occurrences manquees)
- Que se passe-t-il si l'utilisateur supprime le compte (Account) associe a une recurrence ? La recurrence reste active mais le champ account est nullable — l'utilisateur devra choisir un compte lors de la prochaine validation si le compte est manquant
- Que se passe-t-il si un abonnement est desactive entre la notification et le paiement ? Le paiement est refuse avec une erreur
- Comment le calcul de nextOccurrence gere les fins de mois ? Pour la frequence hebdomadaire : +7 jours. Pour mensuel : meme jour du mois suivant, tronque au dernier jour du mois si necessaire (ex: 31 janvier -> 28/29 fevrier). Pour annuel : meme jour l'annee suivante, avec gestion des annees bissextiles

## Requirements

### Functional Requirements

- **FR-001**: Le systeme DOIT permettre de creer une transaction recurrente via un endpoint dedie, avec une frequence (hebdomadaire, mensuel, annuel) et une date de prochaine occurrence obligatoires
- **FR-002**: Le systeme DOIT fournir un endpoint pour lister les transactions recurrentes actives de l'utilisateur authentifie
- **FR-003**: Le systeme DOIT permettre de valider une occurrence d'une transaction recurrente, ce qui cree une nouvelle transaction et avance la prochaine occurrence
- **FR-004**: Le systeme DOIT permettre de passer une occurrence sans creer de transaction, en avancant simplement la prochaine date
- **FR-005**: Le systeme DOIT permettre de desactiver une transaction recurrente
- **FR-006**: Le systeme DOIT permettre de payer un abonnement, creant une transaction liee a l'abonnement avec le montant de celui-ci, sur le compte de l'abonnement (ou le compte par defaut de l'utilisateur si aucun compte n'est associe). La date de debut de l'abonnement (dateDebut) n'est PAS modifiee — la prochaine echeance est calculee dynamiquement par getNextDueDate()
- **FR-007**: Le systeme DOIT fournir l'historique des paiements d'un abonnement (liste des transactions liees)
- **FR-008**: Le systeme DOIT fournir le cumul total des paiements pour un abonnement
- **FR-009**: Le systeme DOIT executer quotidiennement un traitement planifie qui detecte les echeances dues et cree des notifications
- **FR-010**: Le systeme NE DOIT PAS creer de transaction automatiquement — seule la validation explicite de l'utilisateur cree une transaction
- **FR-011**: Chaque transaction liee a un abonnement DOIT porter la reference de l'abonnement source
- **FR-012**: Les donnees DOIVENT etre isolees par utilisateur authentifie
- **FR-013**: Les inputs DOIVENT etre valides (frequence non nulle, date de prochaine occurrence non nulle et valide)
- **FR-014**: Les transactions recurrentes "templates" (isRecurring=true) NE DOIVENT PAS apparaitre dans les listings de transactions standard (GET /transactions). Elles sont consultables uniquement via GET /transactions/recurring

### Key Entities

- **Transaction (enrichie)** : ajoute isRecurring (boolean), frequency (enum Frequency, nullable), nextOccurrence (date, nullable), recurringActive (boolean), subscription (reference vers Subscription, nullable)
- **Subscription (existante)** : inchangee. Les paiements sont traces via les transactions liees (subscriptionId sur Transaction)
- **Notification (existante)** : utilisee par le scheduler pour informer l'utilisateur des echeances dues

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut valider une transaction recurrente en une seule action et la transaction est creee immediatement
- **SC-002**: L'historique des paiements d'un abonnement est consultable et le cumul est exact a l'euro pres
- **SC-003**: Les notifications d'echeance sont creees quotidiennement pour toutes les recurrences et abonnements dus, sans omission. Une notification est recree chaque jour tant que l'occurrence n'est pas validee (rappel persistant)
- **SC-004**: Le systeme gere correctement les trois frequences (hebdomadaire, mensuel, annuel) avec un calcul de prochaine occurrence fiable, y compris les cas limites (fin de mois, annees bissextiles)
- **SC-005**: Tous les endpoints sont proteges par authentification et les donnees sont strictement isolees par utilisateur
- **SC-006**: La couverture de tests couvre les cas nominaux, les cas d'erreur (4xx) et les cas limites pour les services et les controllers

## Assumptions

- Le systeme de notifications (KKS-158 / feature 072) est deja en place et fonctionnel — les types NotificationType et EntityType peuvent etre etendus
- La table `subscriptions` existe deja avec les champs necessaires (nom, montant, frequence, dateDebut, actif, category, account)
- Le calcul de la prochaine occurrence pour la frequence mensuelle utilise la meme logique que les abonnements existants (meme jour du mois suivant, tronque au dernier jour du mois si necessaire)
- Les paiements partiels ne sont pas supportes pour les abonnements — le montant est toujours celui defini dans l'abonnement
- Le scheduler s'execute a 8h (heure serveur) chaque jour, les dates sont calculees par timezone utilisateur
- La migration Flyway sera la V20 (apres V19 existante pour bank-accounts)

## Clarifications

### Session 2026-03-14

- Q: Si l'utilisateur ne valide pas une occurrence, le scheduler doit-il recreer une notification chaque jour ou ignorer les doublons ? → A: Creer une nouvelle notification chaque jour tant que non valide (rappel quotidien persistant). Le but est que l'utilisateur n'oublie pas de valider.
- Q: Comment creer une transaction recurrente — endpoint dedie ou enrichissement du endpoint existant ? → A: Endpoint dedie POST /transactions/recurring avec DTO specifique (frequence + nextOccurrence obligatoires). Separation des responsabilites.
- Q: Quel compte utiliser pour le paiement d'un abonnement ? → A: Utiliser le compte de l'abonnement (subscription.account), fallback sur le compte par defaut de l'utilisateur si null.

## Out of Scope

- Interface utilisateur (Angular et Flutter traites dans KKS-192 et KKS-193)
- Creation automatique de transactions sans validation utilisateur
- Paiements partiels d'abonnements
- Suppression d'une transaction recurrente (la desactivation remplace la suppression pour preserver l'historique)
- Modification de la frequence ou du montant d'une recurrence existante (suppression + recreation)
- Gestion multi-devises des recurrences (utilise la devise du compte associe)
