# Feature Specification: Budgets par catégorie — Angular

**Feature Branch**: `074-angular-budget-categories`
**Created**: 2026-03-08
**Status**: Draft
**Input**: Linear KKS-189 — Budgets par catégorie Angular : dashboard section, écran dédié, historique, formulaire

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter l'apercu des budgets sur le dashboard (Priority: P1)

L'utilisateur ouvre le dashboard et voit une section "Budgets" affichant un résumé de ses budgets du mois en cours : montant total dépensé vs budget total, et les catégories principales avec barres de progression colorées.

**Why this priority**: Le dashboard est le premier écran visible. Afficher les budgets ici donne une visibilité immédiate sur l'état financier sans navigation supplémentaire.

**Independent Test**: Peut être testé en vérifiant que la section budgets s'affiche avec les données du mois courant et que les barres de progression reflètent les montants réels.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a la feature BUDGETS activée et au moins un budget configuré, **When** il ouvre le dashboard, **Then** une section "Budgets" affiche le total dépensé/budgété en devise principale et les catégories avec barres de progression
2. **Given** l'utilisateur a la feature BUDGETS désactivée, **When** il ouvre le dashboard, **Then** la section budgets n'apparaît pas
3. **Given** une catégorie a dépassé 100% du budget, **When** le dashboard s'affiche, **Then** le montant de cette catégorie est affiché en rouge
4. **Given** l'utilisateur n'a aucun budget configuré, **When** il ouvre le dashboard, **Then** la section budgets affiche un état vide avec message et bouton "Créer un budget" (CTA)

---

### User Story 2 - Gérer les budgets depuis l'écran dédié (Priority: P1)

L'utilisateur accède à un écran dédié listant tous ses budgets du mois sélectionné. Il peut naviguer entre les mois, voir le détail de chaque catégorie budgétée (montant dépensé vs budget), et accéder à la création, l'édition ou la suppression d'un budget.

**Why this priority**: C'est l'écran central de gestion des budgets, nécessaire pour toutes les opérations CRUD.

**Independent Test**: Peut être testé en naviguant vers /budgets, vérifiant la liste des budgets, changeant de mois, et effectuant des opérations CRUD.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran budgets, **When** la page se charge, **Then** tous les budgets du mois courant sont affichés avec montant dépensé/budgété et barre de progression
2. **Given** des dépenses existent sans budget associé, **When** l'écran budgets se charge, **Then** une catégorie "Autre" regroupe les dépenses non budgétées
3. **Given** l'utilisateur clique sur les flèches de navigation mois, **When** il sélectionne un mois différent, **Then** les données se mettent à jour pour le mois choisi
4. **Given** l'utilisateur clique sur "Supprimer" un budget, **When** il confirme dans la boîte de dialogue, **Then** le budget est supprimé et la liste se rafraîchit
5. **Given** la feature BUDGETS est désactivée, **When** l'utilisateur tente d'accéder à /budgets, **Then** il est redirigé vers le dashboard

---

### User Story 3 - Créer ou modifier un budget (Priority: P1)

L'utilisateur crée un nouveau budget en sélectionnant une catégorie (parmi celles sans budget existant), un montant, une devise, une fréquence et un seuil de notification. Il peut aussi modifier un budget existant.

**Why this priority**: Sans formulaire, impossible de créer des budgets. Fonctionnalité fondamentale.

**Independent Test**: Peut être testé en ouvrant le formulaire, remplissant les champs, et vérifiant que le budget est créé/modifié via l'API.

**Acceptance Scenarios**:

1. **Given** l'utilisateur clique sur "Nouveau budget", **When** le formulaire s'affiche, **Then** seules les catégories sans budget existant sont proposées dans la liste déroulante
2. **Given** l'utilisateur remplit tous les champs requis (catégorie, montant, fréquence), **When** il soumet le formulaire, **Then** le budget est créé et la liste se rafraîchit
3. **Given** l'utilisateur édite un budget existant, **When** le formulaire s'ouvre, **Then** les champs sont pré-remplis avec les valeurs actuelles
4. **Given** l'utilisateur modifie le montant et soumet, **When** la requête réussit, **Then** le budget mis à jour apparaît dans la liste
5. **Given** l'utilisateur soumet le formulaire avec des champs invalides (montant vide ou négatif), **When** la validation s'exécute, **Then** des messages d'erreur apparaissent sur les champs concernés

---

### User Story 4 - Visualiser la répartition des dépenses (Priority: P2)

L'utilisateur voit, sous la liste des budgets dans l'écran `/budgets`, un Doughnut Chart affichant la répartition des dépenses par catégorie budgétée (+ "Autre") avec le total des dépenses au centre. Il peut cliquer dessus pour une vue détaillée.

**Why this priority**: La répartition visuelle est complémentaire à la gestion quotidienne. Elle apporte de la valeur analytique mais n'est pas bloquante pour l'utilisation de base des budgets.

**Independent Test**: Peut être testé en naviguant vers /budgets, vérifiant le rendu du Doughnut Chart sous la liste et la vue détaillée au clic.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran /budgets avec des budgets configurés, **When** la page se charge, **Then** un Doughnut Chart sous la liste affiche la répartition des dépenses par catégorie avec les couleurs des catégories et le total au centre
2. **Given** l'utilisateur clique sur le Doughnut Chart, **When** il est redirigé vers `/budgets/details`, **Then** un graphique agrandi et une liste des catégories avec montants et pourcentages sont visibles
3. **Given** aucune dépense n'existe pour le mois sélectionné, **When** la page se charge, **Then** la section Doughnut Chart affiche un état vide avec le message "Aucune dépense ce mois-ci"

---

### User Story 5 - Accéder aux budgets via la navigation (Priority: P2)

L'utilisateur voit une entrée "Budgets" dans la sidebar (desktop) et la barre de navigation inférieure (mobile) si la feature est activée. Le lien "Voir tout" dans la section dashboard mène à l'écran budgets.

**Why this priority**: L'intégration dans la navigation est essentielle pour la découvrabilité mais dépend des composants principaux.

**Independent Test**: Peut être testé en activant la feature BUDGETS et vérifiant l'apparition de l'entrée dans la navigation.

**Acceptance Scenarios**:

1. **Given** la feature BUDGETS est activée, **When** l'utilisateur voit la sidebar/bottom nav, **Then** une entrée "Budgets" apparaît avec l'icône Phosphor `ChartPie` (outline) / `ChartPieFill` (active)
2. **Given** l'utilisateur clique sur "Voir tout" dans la section budgets du dashboard, **When** la navigation s'effectue, **Then** il est redirigé vers /budgets
3. **Given** la feature BUDGETS est désactivée, **When** l'utilisateur voit la navigation, **Then** aucune entrée "Budgets" n'apparaît

---

### Edge Cases

- Que se passe-t-il si l'utilisateur a plusieurs devises configurées ? Les montants sont convertis en devise principale pour le total côté backend (les endpoints overview et history retournent `totalBudget`/`totalSpent` déjà convertis en devise principale dans le champ `currency`). Le frontend n'effectue aucune conversion — il affiche les valeurs telles que retournées par l'API. Chaque budget individuel affiche sa propre devise.
- Que se passe-t-il si une catégorie est supprimée alors qu'un budget y est associé ? Le budget reste affiché avec la catégorie d'origine (gestion côté backend).
- Que se passe-t-il si l'API est indisponible pendant le chargement ? Un message d'erreur s'affiche avec possibilité de réessayer.
- Comment le sélecteur de mois gère-t-il les limites ? Pas de limite future (le mois courant + futurs sont accessibles), pas de limite passée (navigation libre dans l'historique).
- Que se passe-t-il quand toutes les catégories ont déjà un budget ? Le bouton "Nouveau budget" est désactivé ou masqué avec un message explicatif.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher une section budgets sur le dashboard, positionnée juste après le résumé mensuel, avec le total dépensé/budgété du mois courant et les 5 premières catégories (triées par pourcentage décroissant) avec barres de progression
- **FR-002**: Le système DOIT fournir un écran dédié listant tous les budgets avec sélecteur de mois (navigation avant/arrière)
- **FR-003**: Le système DOIT afficher une catégorie "Autre" regroupant les dépenses des catégories sans budget
- **FR-004**: Le système DOIT permettre la création d'un budget via un formulaire en modale avec : sélection catégorie (filtrée), montant, devise, fréquence (Hebdomadaire/Mensuel/Annuel), seuil de notification (champ informatif stocké pour usage backend — le frontend ne déclenche pas d'alerte visuelle au seuil)
- **FR-005**: Le système DOIT permettre la modification d'un budget existant via la même modale avec pré-remplissage des valeurs actuelles
- **FR-006**: Le système DOIT permettre la suppression d'un budget avec confirmation préalable
- **FR-007**: Le système DOIT afficher les barres de progression avec la couleur de la catégorie correspondante
- **FR-008**: Le système DOIT afficher en rouge les montants des catégories ayant dépassé 100% du budget
- **FR-009**: Le système DOIT afficher un Doughnut Chart miniature (ng2-charts / Chart.js) dans l'écran `/budgets`, sous la liste des budgets, montrant la répartition des dépenses par catégorie avec le total des dépenses au centre du graphique. Ce Doughnut miniature est intégré directement dans la page (pas de route séparée).
- **FR-010**: Le système DOIT permettre de cliquer sur le Doughnut Chart miniature pour naviguer vers la sous-route `/budgets/details` affichant un graphique agrandi et une liste des catégories avec montants et pourcentages
- **FR-011**: Le système DOIT conditionner l'accès aux routes budgets à l'activation de la feature BUDGETS
- **FR-012**: Le système DOIT intégrer une entrée "Budgets" dans la sidebar et la barre de navigation inférieure si la feature est activée
- **FR-013**: Le système DOIT valider les champs du formulaire (montant requis et positif, catégorie requise, fréquence requise)
- **FR-014**: Le système DOIT filtrer la liste des catégories dans le formulaire de création pour n'afficher que celles sans budget existant

### Key Entities

- **Budget** : Association entre une catégorie et un plafond de dépenses, avec montant, devise, fréquence (hebdomadaire/mensuel/annuel), seuil de notification. Unique par catégorie et utilisateur.
- **Budget Overview** : Agrégation mensuelle de tous les budgets avec total budgété, total dépensé, pourcentage global, et détail par catégorie (montant budgété, dépensé, pourcentage, catégorie "Autre").
- **Budget Snapshot** : Enregistrement historique d'un budget pour un mois donné (montant budget, montant dépensé, devise, taux de change).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter l'état de ses budgets en moins de 2 secondes depuis le dashboard (section visible sans scroll si budgets configurés)
- **SC-002**: L'utilisateur peut créer un nouveau budget en moins de 30 secondes (3 champs obligatoires minimum)
- **SC-003**: La navigation entre les mois met à jour les données en moins de 1 seconde
- **SC-004**: Le diagramme camembert affiche correctement la répartition avec les couleurs des catégories
- **SC-005**: Toutes les opérations CRUD (créer, lire, modifier, supprimer) fonctionnent sans perte de données
- **SC-006**: L'interface est utilisable sur mobile (écrans >= 320px) et desktop sans dégradation fonctionnelle

## Clarifications

### Session 2026-03-08

- Q: Dashboard sans budget configuré : masquer la section ou afficher un état vide avec CTA ? → A: Afficher un état vide avec message + bouton "Créer un budget"
- Q: Nombre maximum de catégories affichées dans la section dashboard ? → A: 5 catégories (triées par pourcentage décroissant)
- Q: Formulaire budget : modale ou page dédiée ? → A: Modale (cohérent avec les autres formulaires de l'app)
- Q: Quelle librairie de charts et quel type de graphique pour l'historique ? → A: ng2-charts (Chart.js) avec Doughnut Chart et total des dépenses affiché au centre
- Q: L'historique est-il une route séparée ou intégré dans l'écran budgets ? → A: Section intégrée dans /budgets (Doughnut Chart sous la liste, pas de route séparée)
- Q: Quel pattern de chargement utiliser ? → A: Spinner simple (pattern dominant dans l'app Angular — 6 composants sur 7)
- Q: Comment afficher la vue détaillée du Doughnut Chart ? → A: Navigation vers sous-route /budgets/details
- Q: Position de la section Budgets sur le dashboard ? → A: Juste après le résumé mensuel

## Assumptions

- Les endpoints API backend sont disponibles et fonctionnels (KKS-073 terminé)
- La feature BUDGETS n'existe pas encore dans le type `Feature` Angular (`preference.model.ts`) — sera ajoutée lors de l'implémentation
- Le pattern signal-based des services existants (ProductService, TransactionService) sera suivi
- Les design tokens existants couvrent les besoins visuels (couleurs, spacing, radius)
- Le sélecteur de mois suivra le même pattern que celui utilisé dans le dashboard (résumé mensuel)
- La librairie `ng2-charts` (wrapper Chart.js) sera ajoutée comme nouvelle dépendance pour le Doughnut Chart
