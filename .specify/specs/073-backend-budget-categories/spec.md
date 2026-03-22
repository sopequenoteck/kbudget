# Feature Specification: Budgets par categorie — Backend

**Feature Branch**: `073-backend-budget-categories`
**Created**: 2026-03-07
**Status**: Draft
**Input**: User description: "KKS-188 — Budgets par categorie — Backend : entities, migrations, service, controller, tests"
**Linear**: KKS-188 (sous-issue de KKS-157)

## Clarifications

### Session 2026-03-07

- Q: Le DELETE budget est-il un hard delete ou un soft delete (via champ `actif`) ? → A: Hard delete (suppression definitive). Le champ `actif` sert uniquement a la desactivation temporaire via PUT.
- Q: Quel comportement quand aucun taux de change n'est disponible pour un budget en devise etrangere ? → A: Retourner une erreur. L'utilisateur doit configurer ses taux de change avant de pouvoir utiliser des budgets multi-devises.
- Q: Que deviennent les snapshots historiques lors de la suppression d'un budget ? → A: Les snapshots sont conserves (donnees historiques preservees meme apres suppression du budget).
- Q: Overview et historique : un seul endpoint ou deux endpoints distincts ? → A: Deux endpoints distincts — `GET /budgets/overview` (mois courant, calcul temps reel) et `GET /budgets/history?month=YYYY-MM` (mois passe, snapshots).
- Q: Suppression d'une categorie : les snapshots historiques sont-ils supprimes en cascade ? → A: Oui, cascade complete — budget ET snapshots supprimes avec la categorie.
- Q: Type du champ seuil de notification ? → A: Integer (0-100), representant un pourcentage.
- Q: Quelle est la devise principale pour la conversion multi-devises dans l'overview ? → A: `currencies[0]` de UserPreference (premiere devise de la liste ordonnee).
- Q: L'endpoint overview accepte-t-il un parametre month ? → A: Non, strictement mois en cours sans parametre. Les mois passes sont couverts par l'endpoint history.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Creer et gerer des budgets par categorie (Priority: P1)

L'utilisateur souhaite definir un budget mensuel, hebdomadaire ou annuel pour chacune de ses categories de depenses. Il peut creer, modifier, consulter et supprimer ses budgets. Chaque categorie ne peut avoir qu'un seul budget.

**Why this priority**: Le CRUD est le socle fonctionnel de la feature. Sans lui, aucune autre fonctionnalite (overview, historique) n'est possible.

**Independent Test**: Peut etre teste en creant un budget via l'API, puis en le consultant, le modifiant et le supprimant. Livre de la valeur immediate : l'utilisateur peut definir ses enveloppes budgetaires.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifie avec des categories existantes, **When** il cree un budget pour une categorie avec un montant et une frequence, **Then** le budget est cree et renvoye avec un statut 201.
2. **Given** un budget existant pour une categorie, **When** l'utilisateur tente de creer un second budget pour la meme categorie, **Then** le systeme refuse avec une erreur (conflit).
3. **Given** un budget existant, **When** l'utilisateur le modifie (montant, frequence, seuil, actif, ou categoryId), **Then** les modifications sont persistees et renvoyees. Si le changement de categorie cree un doublon, le systeme refuse avec une erreur (conflit).
4. **Given** un budget existant, **When** l'utilisateur le supprime, **Then** le budget est definitivement supprime (hard delete) et le systeme renvoie un statut 204. Les snapshots historiques associes sont conserves.
5. **Given** un utilisateur avec plusieurs budgets, **When** il liste ses budgets, **Then** il recoit la liste de ses budgets actifs avec le montant depense calcule.
6. **Given** un utilisateur avec des budgets actifs et inactifs, **When** il liste ses budgets avec `includeInactive=true`, **Then** il recoit tous ses budgets (actifs et inactifs) avec le montant depense calcule.

---

### User Story 2 - Consulter le tableau de bord budgetaire mensuel (Priority: P2)

L'utilisateur souhaite voir une vue d'ensemble de tous ses budgets pour un mois donne : budget total, depenses totales, pourcentage global, et le detail par categorie avec le montant depense et le pourcentage de consommation.

**Why this priority**: L'overview est la vue principale du dashboard budgetaire. Elle donne du sens aux budgets en les confrontant aux depenses reelles.

**Independent Test**: Peut etre teste en creant des budgets et des transactions de type DEPENSE pour le mois en cours, puis en appelant l'endpoint overview et en verifiant les totaux.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des budgets actifs et des depenses pour le mois en cours, **When** il consulte l'overview du mois, **Then** il recoit le budget total normalise en mensuel, les depenses totales et le pourcentage global.
2. **Given** un budget hebdomadaire de 100, **When** le systeme calcule l'overview mensuel, **Then** le montant budget normalise est 433 (100 x 4.33).
3. **Given** un budget annuel de 1200, **When** le systeme calcule l'overview mensuel, **Then** le montant budget normalise est 100 (1200 / 12).
4. **Given** un budget en devise differente de la devise principale, **When** le systeme calcule les totaux, **Then** les montants sont convertis via les taux de change.

---

### User Story 3 - Consulter l'historique budgetaire d'un mois passe (Priority: P3)

L'utilisateur souhaite consulter les performances budgetaires d'un mois passe. Le systeme utilise des snapshots pour figer les donnees historiques.

**Why this priority**: L'historique permet le suivi dans le temps mais n'est pas indispensable pour l'utilisation quotidienne.

**Independent Test**: Peut etre teste en creant un budget, des transactions sur un mois passe, puis en consultant l'historique de ce mois. Le snapshot doit etre cree a la volee s'il n'existe pas.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des budgets et des depenses pour un mois passe, **When** il consulte l'historique de ce mois et qu'aucun snapshot n'existe, **Then** le systeme cree les snapshots a la volee et renvoie les donnees.
2. **Given** un snapshot existant pour un mois, **When** l'utilisateur consulte l'historique de ce mois, **Then** le systeme renvoie les donnees du snapshot existant.
3. **Given** un mois sans aucun budget ni depense, **When** l'utilisateur consulte l'historique, **Then** le systeme renvoie une liste vide.

---

### Edge Cases

- **Suppression categorie vs suppression budget** : La suppression d'une categorie entraine la suppression en cascade du budget ET des snapshots associes (CASCADE DB). La suppression d'un budget seul (hard delete via DELETE /budgets/{id}) conserve les snapshots (FR-015) — les snapshots referencent (user, category, mois), pas le budget.
- Que se passe-t-il quand l'utilisateur consulte l'overview sans aucun budget actif ? Le systeme renvoie des totaux a zero.
- Que se passe-t-il quand le seuil de notification est a 0 ou 100 ? Valeurs acceptees, 0 desactive les alertes, 100 alerte des le premier euro depense.
- Comment sont geres les montants negatifs ou nuls pour le budget ? Le montant doit etre strictement positif (validation @Positive).
- Que se passe-t-il si aucun taux de change n'est disponible pour une devise ? Le systeme retourne une erreur 400. L'utilisateur doit configurer ses taux de change avant d'utiliser des budgets multi-devises.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT permettre de creer un budget associant une categorie, un montant, une devise, une frequence et un seuil de notification.
- **FR-002**: Le systeme DOIT garantir l'unicite d'un budget par categorie et par utilisateur (un seul budget par categorie).
- **FR-003**: Le systeme DOIT supporter trois frequences de budget : hebdomadaire, mensuel, annuel.
- **FR-004**: Le systeme DOIT normaliser tous les montants en mensuel pour les calculs d'overview (hebdo x 4.33, annuel / 12).
- **FR-005**: Le systeme DOIT calculer le montant depense en sommant les transactions de type DEPENSE du mois calendaire (du 1er au dernier jour du mois) pour la categorie de l'utilisateur, quelle que soit la frequence du budget. Le montant depense (`montantDepense`) est toujours dans la devise des transactions (devise du compte). La conversion en devise principale ne s'applique qu'au `montantBudget` pour les totaux de l'overview.
- **FR-006**: Le systeme DOIT fournir un endpoint `GET /budgets/overview` (sans parametre) calculant en temps reel le budget total, les depenses totales et le pourcentage pour le mois en cours uniquement.
- **FR-006b**: Le systeme DOIT fournir un endpoint distinct `GET /budgets/history?month=YYYY-MM` renvoyant les donnees historiques d'un mois passe a partir des snapshots.
- **FR-007**: Le systeme DOIT creer des snapshots a la volee (lazy) lors de la consultation d'un mois passe via l'endpoint history si aucun snapshot n'existe.
- **FR-008**: Le systeme DOIT persister les snapshots avec le montant budget, la devise, le taux de change et le montant depense a la date de creation.
- **FR-009**: Le systeme DOIT filtrer toutes les donnees par l'utilisateur authentifie (isolation des donnees).
- **FR-010**: Le systeme DOIT valider les entrees : montant strictement positif, frequence parmi les valeurs autorisees, categoryId existante.
- **FR-011**: Le systeme DOIT convertir les montants en devise principale (`currencies[0]` de UserPreference) via les taux de change pour les totaux de l'overview. Si un taux de change est manquant, le systeme DOIT retourner une erreur 400 Bad Request avec un message indiquant la devise manquante. (Choix : 400 plutot que 422, alignement avec le pattern existant du projet pour les erreurs de configuration utilisateur — l'utilisateur doit configurer ses taux via `PUT /exchange-rates` avant d'utiliser des budgets multi-devises.)
- **FR-014**: Le DELETE d'un budget DOIT etre un hard delete (suppression definitive). La desactivation temporaire se fait via PUT avec `actif=false`.
- **FR-015**: La suppression d'un budget NE DOIT PAS supprimer les snapshots historiques associes.
- **FR-012**: Le systeme DOIT exposer la feature derriere le feature toggle BUDGETS (ajout a l'enum Feature existante).
- **FR-013**: ~~Supprime~~ — la liste retourne un `List<>` sans pagination Spring (volume faible : 5-20 budgets max par utilisateur, alignement avec les patterns existants CategoryController/AccountController).

### Key Entities

- **Budget**: Enveloppe budgetaire associant une categorie a un montant, une devise, une frequence et un seuil d'alerte. Attributs : montant (BigDecimal), devise (Currency), frequence (Frequency), seuil de notification (Integer 0-100, defaut 80), actif (Boolean). Relation : un utilisateur, une categorie (unique par utilisateur).
- **BudgetSnapshot**: Photo mensuelle figee des performances budgetaires pour une categorie. Attributs : mois, montant budget, devise, taux de change, montant depense. Relation : un utilisateur, une categorie, un mois (unique par triplet).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut creer, lire, modifier et supprimer un budget en moins de 3 interactions par operation.
- **SC-002**: L'overview budgetaire d'un mois affiche les totaux en moins de 2 secondes avec 50 budgets actifs.
- **SC-003**: La normalisation mensuelle est mathematiquement correcte : hebdo x 4.33 et annuel / 12, avec une precision au centime.
- **SC-004**: Les snapshots historiques sont crees a la volee sans action manuelle de l'utilisateur.
- **SC-005**: 100% des endpoints respectent l'isolation des donnees par utilisateur : aucun utilisateur ne peut consulter les budgets d'un autre.
- **SC-006**: Les budgets multi-devises sont correctement agreges via les taux de change dans la vue d'ensemble.

## Assumptions

- La feature depend du systeme de taux de change (KKS-156) deja implemente pour la conversion multi-devises.
- Le systeme de notifications existant (KKS-072) sera utilise pour les alertes de seuil, mais l'integration notification n'est pas dans le scope de cette issue backend.
- Le seuil de notification par defaut est 80% si non specifie.
- La devise par defaut est EUR si non specifiee a la creation.
- Les snapshots ne sont crees que pour les mois passes, pas pour le mois en cours (le mois en cours est toujours calcule en temps reel).
- Les snapshots lazy sont crees a partir des budgets actifs au moment de la consultation. Si un budget a ete supprime entre le mois cible et la date de consultation, il ne sera pas capture dans le snapshot (limitation acceptee pour un usage single-user).

## Out of Scope

- Interface utilisateur (frontend Angular et Flutter) — issues separees.
- Envoi effectif de notifications de depassement de seuil — sera traite dans une issue dediee.
- Budget global (sans categorie) — uniquement des budgets par categorie.
- Rapports et graphiques d'evolution — scope frontend.
