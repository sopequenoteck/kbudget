# Feature Specification: Budgets par catégorie — Flutter

**Feature Branch**: `075-flutter-budget-categories`
**Created**: 2026-03-08
**Status**: Draft
**Input**: Linear KKS-190 — Budgets par catégorie Flutter : dashboard section, écran dédié, historique, formulaire
**Parent**: KKS-157 (Budgets par catégorie)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter l'aperçu budgets sur le dashboard (Priority: P1)

L'utilisateur ouvre l'application et voit une section "Budgets" sur le dashboard affichant un résumé de ses budgets du mois en cours : montant total dépensé vs budget total, et les 5 catégories les plus dépensées (triées par % dépensé décroissant) avec des barres de progression visuelles. Un lien "Voir tout" permet d'accéder à l'écran complet.

**Why this priority**: C'est le point d'entrée principal — l'utilisateur doit voir en un coup d'oeil où il en est dans ses budgets sans naviguer.

**Independent Test**: Peut être testé en créant des budgets via l'API et en vérifiant que la section dashboard affiche correctement les données du mois courant.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 3 budgets actifs pour le mois courant, **When** il ouvre le dashboard, **Then** il voit la section "Budgets" avec le total dépensé/budget et les barres de progression par catégorie.
2. **Given** un budget est dépassé (dépenses > montant budgété), **When** le dashboard s'affiche, **Then** la barre de progression et le montant de cette catégorie sont affichés en rouge.
3. **Given** l'utilisateur n'a aucun budget actif, **When** il ouvre le dashboard, **Then** la section "Budgets" n'est pas affichée.
4. **Given** la feature BUDGETS est désactivée dans les préférences, **When** le dashboard s'affiche, **Then** la section "Budgets" est masquée.
5. **Given** l'utilisateur tape sur "Voir tout", **When** l'action est déclenchée, **Then** il est redirigé vers l'écran `/budgets`.

---

### User Story 2 - Consulter la liste complète des budgets (Priority: P1)

L'utilisateur accède à un écran dédié listant tous ses budgets pour un mois donné. Il peut naviguer entre les mois via un sélecteur. Chaque budget affiche la catégorie, le montant budgété, le montant dépensé et une barre de progression.

**Why this priority**: L'écran principal pour gérer et suivre tous les budgets — fonctionnalité coeur.

**Independent Test**: Peut être testé en naviguant vers `/budgets` et en vérifiant l'affichage de la liste, le changement de mois, et le skeleton loading.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran budgets, **When** la page se charge, **Then** il voit tous les budgets du mois courant avec icône catégorie, nom, barre de progression, et montants.
2. **Given** l'utilisateur est sur Mars 2026, **When** il tape la flèche gauche, **Then** le sélecteur passe à Février 2026 et la liste se rafraîchit.
3. **Given** les données sont en cours de chargement, **When** l'écran s'affiche, **Then** un skeleton loading (shimmer) est visible.
4. **Given** l'utilisateur n'a aucun budget, **When** il accède à l'écran, **Then** un état vide est affiché avec une incitation à créer un budget.

---

### User Story 3 - Créer et modifier un budget (Priority: P1)

L'utilisateur crée un budget en sélectionnant une catégorie (parmi celles sans budget existant), un montant, une devise, une fréquence (hebdomadaire/mensuel/annuel) et un seuil de notification. Il peut aussi modifier un budget existant.

**Why this priority**: Sans formulaire de création/édition, aucun budget ne peut exister — c'est un prérequis fonctionnel.

**Independent Test**: Peut être testé en ouvrant le formulaire, remplissant les champs, et vérifiant la création/modification via l'API.

**Acceptance Scenarios**:

1. **Given** l'utilisateur tape le FAB "+" sur l'écran budgets, **When** le formulaire s'ouvre, **Then** il voit les champs : catégorie, montant, devise, fréquence, seuil notification.
2. **Given** l'utilisateur sélectionne une catégorie et remplit le montant, **When** il valide, **Then** le budget est créé et la liste se rafraîchit.
3. **Given** certaines catégories ont déjà un budget, **When** le sélecteur de catégories s'ouvre, **Then** seules les catégories sans budget existant sont proposées.
4. **Given** l'utilisateur édite un budget existant, **When** le formulaire s'ouvre, **Then** les champs sont pré-remplis avec les valeurs actuelles et la catégorie est non modifiable.
5. **Given** l'utilisateur modifie le montant et valide, **When** la sauvegarde réussit, **Then** le budget est mis à jour et la liste reflète les changements.
6. **Given** le seuil de notification est réglé à 80%, **When** l'utilisateur déplace le slider, **Then** la valeur affichée se met à jour en temps réel (entre 50% et 100%).

---

### User Story 4 - Supprimer un budget (Priority: P2)

L'utilisateur supprime un budget existant via le bouton supprimer dans le formulaire d'édition, avec confirmation via `confirm_delete_dialog` (pattern existant).

**Why this priority**: Fonctionnalité de gestion standard, moins critique que la consultation et la création.

**Independent Test**: Peut être testé en ouvrant le formulaire d'édition d'un budget et en utilisant le bouton supprimer avec confirmation.

**Acceptance Scenarios**:

1. **Given** l'utilisateur ouvre le formulaire d'édition d'un budget, **When** il tape le bouton "Supprimer", **Then** une confirmation est demandée via `confirm_delete_dialog`.
2. **Given** l'utilisateur confirme la suppression, **When** l'action est exécutée, **Then** le budget disparaît de la liste.
3. **Given** l'utilisateur annule la suppression, **When** il tape "Annuler", **Then** le budget reste inchangé.

---

### User Story 5 - Consulter l'historique des budgets avec graphique (Priority: P2)

L'utilisateur accède à un écran d'historique affichant un graphique camembert (pie chart) des dépenses par catégorie budgétée pour le mois sélectionné. Il peut taper sur une portion du camembert pour voir le détail.

**Why this priority**: Fonctionnalité de visualisation enrichie — importante mais pas bloquante pour l'usage de base.

**Independent Test**: Peut être testé en naviguant vers l'historique et en vérifiant le rendu du camembert avec des données de test.

**Acceptance Scenarios**:

1. **Given** l'écran budgets est affiché, **When** les données sont chargées, **Then** un camembert résumé est intégré en haut de la liste montrant la répartition des dépenses par catégorie budgétée.
2. **Given** l'utilisateur tape sur le camembert, **When** l'action est déclenchée, **Then** il navigue vers `/budgets/details?month=YYYY-MM` affichant le détail complet.
3. **Given** l'utilisateur accède au détail pour un mois passé, **When** la page se charge, **Then** les données proviennent des snapshots (données figées) + une portion "Autre" pour les non-budgétées.
4. **Given** l'utilisateur consulte le détail du mois courant, **When** la page se charge, **Then** les données live de l'overview sont utilisées (pas de snapshot).
5. **Given** l'utilisateur tape sur une portion du camembert détail, **When** l'action est déclenchée, **Then** un bottom sheet s'ouvre avec le détail de la catégorie (nom, montant dépensé, pourcentage, liste des transactions du mois).
6. **Given** aucune dépense n'existe pour le mois, **When** l'écran s'affiche, **Then** un état vide est montré à la place du camembert.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur a des budgets en devises différentes ? Le dashboard affiche le total converti dans la devise principale.
- Comment gérer un budget hebdomadaire affiché dans un contexte mensuel ? Le backend normalise déjà les montants — l'affichage utilise les valeurs normalisées.
- Que se passe-t-il si la catégorie d'un budget est supprimée ? Le budget reste visible avec les informations de catégorie stockées dans le budget lui-même.
- Comment gérer la navigation mois par mois pour les mois futurs ? Le sélecteur ne permet pas de naviguer au-delà du mois courant ni au-delà de 12 mois en arrière.
- Que se passe-t-il lors d'une erreur réseau ? Un message d'erreur est affiché avec possibilité de réessayer (pattern standard de l'app).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'application DOIT afficher une section "Budgets" sur le dashboard montrant le résumé du mois courant (total dépensé/budget, top 5 catégories triées par % dépensé décroissant avec barres de progression).
- **FR-002**: La section dashboard DOIT être conditionnelle — visible uniquement si la feature BUDGETS est activée et si l'utilisateur a au moins un budget actif.
- **FR-003**: L'application DOIT fournir un écran dédié `/budgets` listant tous les budgets du mois sélectionné.
- **FR-004**: L'écran budgets DOIT inclure un sélecteur de mois permettant de naviguer mois par mois (pas au-delà du mois courant, ni au-delà de 12 mois en arrière).
- **FR-005**: L'application DOIT fournir un formulaire de création de budget avec : sélection catégorie (filtrée), montant, devise, fréquence, seuil de notification.
- **FR-006**: Le formulaire DOIT filtrer les catégories pour n'afficher que celles sans budget existant (mode création).
- **FR-007**: Le formulaire DOIT supporter le mode édition avec pré-remplissage des valeurs et catégorie verrouillée.
- **FR-008**: L'application DOIT permettre la suppression d'un budget avec confirmation.
- **FR-009**: L'application DOIT fournir un écran de détail `/budgets/details` avec un graphique camembert des dépenses par catégorie. Les mois passés utilisent les snapshots (données figées), le mois courant utilise les données live de l'overview.
- **FR-010**: Les barres de progression DOIVENT utiliser la couleur de la catégorie et passer en rouge en cas de dépassement.
- **FR-011**: L'application DOIT afficher un skeleton loading (shimmer) pendant le chargement des données.
- **FR-012**: L'entrée "Budgets" DOIT apparaître dans la navigation bottom nav si la feature BUDGETS est activée.
- **FR-013**: Le seuil de notification DOIT être configurable via un slider (plage 50%-100%, défaut 80%).

### Key Entities

- **Budget**: Allocation financière par catégorie avec montant, devise, fréquence, seuil de notification, et statut actif/inactif. Lié à une catégorie unique (contrainte 1 budget par catégorie).
- **BudgetOverview**: Agrégation mensuelle des budgets — total budgété, total dépensé, pourcentage global, liste des budgets individuels avec leur progression.
- **BudgetSnapshot**: Historique mensuel des budgets (montant budgété, dépensé, taux de change) pour la vue historique.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter ses budgets du mois en moins de 2 secondes depuis le dashboard.
- **SC-002**: La création d'un budget se fait en 3 interactions maximum (sélection catégorie, saisie montant, validation).
- **SC-003**: La navigation entre les mois est instantanée (feedback visuel immédiat, données chargées en arrière-plan).
- **SC-004**: Le graphique camembert affiche correctement la répartition avec des couleurs distinctes par catégorie.
- **SC-005**: Tous les écrans respectent le design system (tokens de couleurs, spacing, radius) et sont cohérents avec le reste de l'application.
- **SC-006**: Les budgets dépassés sont visuellement distingués (couleur rouge) pour alerter l'utilisateur immédiatement.

## Clarifications

### Session 2026-03-08

- Q: Combien de catégories budgets afficher sur la section dashboard ? → A: Top 5 triées par % dépensé décroissant
- Q: Source de données pour l'écran historique ? → A: Snapshots pour mois passés, overview live pour mois courant
- Q: Data mode pour les budgets ? → A: Local+remote (Drift + Dio via dataModeProvider)
- Q: Présentation du formulaire budget ? → A: Modal bottom sheet (via ModalNotifier, pattern existant)
- Q: Navigation vers l'historique ? → A: Camembert intégré dans l'écran budgets, tap navigue vers écran détail (pattern Angular)
- Q: Route écran détail camembert ? → A: `/budgets/details` (cohérent avec Angular)
- Q: Pattern de suppression d'un budget ? → A: Bouton supprimer dans le formulaire d'édition + confirm_delete_dialog (pattern existant)
- Q: Comportement au tap sur portion camembert détail ? → A: Bottom sheet avec détail catégorie (nom, montant, %, liste transactions du mois)
- Q: Source des transactions pour le bottom sheet catégorie ? → A: Filtrage côté client depuis les transactions du mois déjà chargées (pas de nouvel endpoint)
- Q: Limite de navigation mois passés ? → A: 12 mois en arrière maximum
- Q: Tables Drift pour stockage local ? → A: Les deux tables (budgets + budget_snapshots)

## Assumptions

- Le backend (KKS-157 / issue 073) est déjà implémenté et les 7 endpoints API sont disponibles.
- La librairie `fl_chart` sera ajoutée au projet pour le graphique camembert.
- Le pattern CRUD Notifier (`ListState<T>`) existant dans le projet est réutilisé.
- Le `ModalNotifier` existant gère l'ouverture des formulaires (création/édition).
- La conversion multi-devises est gérée côté backend — le frontend affiche les montants tels que reçus.
- Le slider de seuil de notification a une plage de 50% à 100% par pas de 5%.
- Data mode : local+remote (Drift/SQLite + Dio) via strategy pattern `dataModeProvider`, comme les transactions. Les deux implémentations (BudgetRepositoryLocal + BudgetRepositoryRemote) sont nécessaires.
- Tables Drift : `budgets` et `budget_snapshots` (miroir des entités backend pour le mode local complet).
