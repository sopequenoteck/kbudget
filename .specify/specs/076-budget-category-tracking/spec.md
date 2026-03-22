# Feature Specification: Budgets par catégorie — suivi des dépenses avec snapshots mensuels

**Feature Branch**: `076-budget-category-tracking`
**Created**: 2026-03-09
**Status**: Draft
**Input**: Linear KKS-157 — Budgets par catégorie — suivi des dépenses avec snapshots mensuels
**Labels**: Backend, Frontend, Mobile

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Créer un budget par catégorie (Priority: P1)

L'utilisateur souhaite définir un plafond de dépenses pour une catégorie donnée. Il accède à l'écran Budgets, appuie sur "+ Nouveau budget", sélectionne une catégorie (seules celles sans budget existant sont proposées), saisit un montant, choisit une devise, une fréquence (hebdomadaire, mensuel, annuel) et un seuil de notification (défaut 80%). Le budget est enregistré et apparaît immédiatement dans la liste.

**Why this priority**: Sans création de budget, aucune autre fonctionnalité n'est utilisable. C'est le socle de la feature.

**Independent Test**: Peut être testé en créant un budget et en vérifiant qu'il apparaît dans la liste avec les bons paramètres.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Budgets et a au moins une catégorie sans budget, **When** il crée un budget avec montant=500, devise=EUR, fréquence=MENSUEL, seuil=80%, **Then** le budget apparaît dans la liste avec ces paramètres.
2. **Given** l'utilisateur a déjà un budget sur la catégorie "Alimentation", **When** il ouvre le formulaire de création, **Then** "Alimentation" n'apparaît pas dans la liste des catégories sélectionnables.
3. **Given** l'utilisateur crée un budget avec fréquence HEBDOMADAIRE et montant 100, **When** le budget est affiché, **Then** le montant mensuel normalisé affiché est ~433 (100 x 4.33).

---

### User Story 2 - Visualiser la progression des dépenses vs budget (Priority: P1)

L'utilisateur consulte ses budgets pour voir combien il a dépensé par rapport à chaque plafond. Sur le dashboard, une section "Budgets - [Mois]" affiche le total dépensé vs total budgété en devise principale, avec les top catégories et leurs barres de progression. Un lien "Voir tout" mène à l'écran dédié listant toutes les catégories budgétées.

**Why this priority**: La visualisation de la progression est la valeur principale de la feature — savoir où on en est.

**Independent Test**: Avec un budget créé et des transactions enregistrées ce mois-ci, vérifier que les barres de progression reflètent le ratio dépenses/plafond.

**Acceptance Scenarios**:

1. **Given** un budget "Alimentation" de 500 EUR/mois et 300 EUR de dépenses ce mois, **When** l'utilisateur consulte le dashboard, **Then** la barre de progression "Alimentation" affiche 60% avec la couleur de la catégorie.
2. **Given** l'utilisateur a 3 budgets actifs, **When** il consulte le dashboard, **Then** le total dépensé / total budgété (en devise principale) est affiché en haut de la section, avec les 5 catégories les plus consommées (ratio dépenses/budget).
3. **Given** l'utilisateur a des budgets en devises différentes, **When** le total est calculé, **Then** chaque budget est converti en devise principale via les taux de conversion configurés.
4. **Given** des dépenses existent dans des catégories sans budget, **When** l'utilisateur consulte l'écran "Voir tout", **Then** ces dépenses sont regroupées sous une catégorie "Autre" (icône `dots-three`, couleur grise #9ca3af).
5. **Given** des dépenses non budgétées existent, **When** l'utilisateur tape sur "Autre", **Then** le détail s'affiche avec chaque catégorie non budgétée et son montant.

---

### User Story 3 - Modifier et supprimer un budget (Priority: P2)

L'utilisateur peut modifier les paramètres d'un budget existant (montant, fréquence, devise, seuil) ou le supprimer. La modification n'altère pas les snapshots historiques déjà créés.

**Why this priority**: Nécessaire pour corriger des erreurs de saisie et ajuster les plafonds au fil du temps.

**Independent Test**: Modifier un budget existant et vérifier que les nouveaux paramètres sont appliqués sans affecter l'historique.

**Acceptance Scenarios**:

1. **Given** un budget "Transport" à 200 EUR/mois, **When** l'utilisateur le modifie à 300 EUR, **Then** le plafond affiché passe à 300 EUR pour le mois en cours.
2. **Given** un budget avec un snapshot historique pour janvier, **When** l'utilisateur modifie le montant du budget, **Then** le snapshot de janvier reste inchangé.
3. **Given** un budget "Loisirs", **When** l'utilisateur le supprime, **Then** il disparaît de la liste et les dépenses de cette catégorie rejoignent "Autre".

---

### User Story 4 - Consulter l'historique mensuel (Priority: P2)

L'utilisateur navigue entre les mois pour voir l'évolution de ses dépenses budgétées. Un sélecteur de mois (< Mars 2026 >) permet de consulter les mois passés. Un camembert affiche la répartition des dépenses par catégorie (budgétées + "Autre"). Taper sur le camembert affiche une vue détaillée avec les montants et pourcentages.

**Why this priority**: L'historique permet d'analyser les tendances et d'ajuster les budgets.

**Independent Test**: Naviguer vers un mois passé et vérifier que les montants affichés correspondent aux snapshots.

**Acceptance Scenarios**:

1. **Given** l'utilisateur consulte le mois en cours, **When** les dépenses sont calculées, **Then** elles sont calculées à la volée depuis les transactions réelles.
2. **Given** l'utilisateur navigue vers un mois passé sans snapshot existant, **When** la page se charge, **Then** un snapshot est créé automatiquement (lazy) avec le budget et le taux de conversion du moment, puis affiché.
3. **Given** un snapshot existe pour janvier, **When** l'utilisateur consulte janvier, **Then** les données du snapshot sont affichées (budget, taux, dépenses figées).
4. **Given** l'utilisateur consulte l'historique, **When** il tape sur le camembert, **Then** une vue détaillée s'affiche avec chaque catégorie, son montant et son pourcentage.

---

### User Story 5 - Recevoir des notifications de seuil (Priority: P3)

L'utilisateur est notifié quand ses dépenses atteignent le seuil configuré (défaut 80%) et quand le budget est dépassé (100%). Les notifications sont envoyées en push et en in-app.

**Why this priority**: Les notifications sont un complément utile mais ne bloquent pas l'utilisation de la feature principale.

**Independent Test**: Créer un budget avec seuil 80%, ajouter des dépenses jusqu'à 80% du plafond et vérifier qu'une notification est déclenchée.

**Acceptance Scenarios**:

1. **Given** un budget "Alimentation" à 500 EUR avec seuil 80%, **When** les dépenses atteignent 400 EUR (80%), **Then** une notification push + in-app est envoyée.
2. **Given** un budget à 500 EUR, **When** les dépenses atteignent 500 EUR (100%), **Then** une notification "budget dépassé" est envoyée.
3. **Given** un budget avec seuil personnalisé à 60%, **When** les dépenses atteignent 60%, **Then** la notification est déclenchée à ce seuil (pas à 80%).

---

### Edge Cases

- Que se passe-t-il si une transaction est modifiée ou supprimée après qu'un snapshot a été créé pour un mois passé ? Le snapshot reste inchangé (intégrité historique).
- Que se passe-t-il si l'utilisateur supprime une catégorie qui a un budget ? Le budget associé est supprimé en cascade.
- Que se passe-t-il si aucun taux de conversion n'est défini pour la devise d'un budget ? Le système utilise un taux de 1.0 (même devise) ou affiche une alerte invitant à configurer le taux.
- Que se passe-t-il si l'utilisateur n'a aucun budget actif ? La section Budgets du dashboard est masquée.
- Que se passe-t-il si l'utilisateur change sa devise principale ? Les totaux sont recalculés avec les nouveaux taux pour le mois en cours ; les snapshots passés conservent le taux figé.
- Comment sont gérées les dépenses à cheval sur deux semaines pour un budget hebdomadaire ? La fréquence hebdomadaire est normalisée en mensuel (x4.33) ; le calcul se fait sur le mois calendaire.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre de créer un budget par catégorie avec montant, devise, fréquence et seuil de notification.
- **FR-002**: Le système DOIT garantir l'unicité d'un budget par catégorie (un seul budget par catégorie par utilisateur).
- **FR-003**: Le système DOIT normaliser les montants en mensuel : hebdomadaire x 4.33, annuel / 12.
- **FR-004**: Le système DOIT calculer les dépenses du mois en cours à la volée depuis les transactions de type DEPENSE.
- **FR-005**: Le système DOIT créer un snapshot de manière lazy lorsqu'un mois passé est consulté pour la première fois.
- **FR-006**: Le système DOIT conserver dans chaque snapshot le montant du budget, la devise, le taux de conversion et le total dépensé au moment de la création.
- **FR-007**: Le système DOIT convertir les budgets multi-devises en devise principale pour afficher les totaux agrégés.
- **FR-008**: Le système DOIT afficher une section "Budgets - [Mois]" sur le dashboard avec le total et les 5 catégories les plus consommées (ratio dépenses/budget le plus élevé).
- **FR-009**: Le système DOIT proposer un écran dédié "Budgets" avec toutes les catégories budgétées et une catégorie "Autre" (icône `dots-three`, couleur #9ca3af) pour les dépenses non budgétées.
- **FR-019**: Le système DOIT permettre de taper sur la catégorie "Autre" pour afficher le détail des catégories non budgétées avec leurs montants respectifs.
- **FR-010**: Le système DOIT permettre la modification d'un budget existant (montant, devise, fréquence, seuil).
- **FR-011**: Le système DOIT permettre la suppression définitive d'un budget.
- **FR-020**: Le système DOIT permettre de désactiver un budget (masqué du dashboard, notifications stoppées, historique conservé).
- **FR-012**: Le système DOIT fournir un sélecteur de mois pour naviguer dans l'historique.
- **FR-013**: Le système DOIT afficher un graphique camembert de répartition des dépenses par catégorie avec vue détaillée au tap.
- **FR-014**: Le système DOIT envoyer une seule notification (push + in-app) par mois lorsque les dépenses franchissent le seuil configuré du budget.
- **FR-015**: Le système DOIT envoyer une seule notification (push + in-app) par mois lorsque les dépenses franchissent 100% du budget.
- **FR-016**: Le système DOIT respecter le feature toggle BUDGETS (la feature est désactivable).
- **FR-017**: Le système DOIT filtrer la liste des catégories dans le formulaire de création pour exclure celles ayant déjà un budget.
- **FR-018**: Le système DOIT afficher les barres de progression avec la couleur de la catégorie correspondante.

### Key Entities

- **Budget**: Plafond de dépenses associé à une catégorie. Attributs : montant, devise, fréquence (hebdomadaire/mensuel/annuel), seuil de notification (pourcentage), état actif/inactif. Contrainte : un seul budget par catégorie par utilisateur. Un budget désactivé est masqué du dashboard et ne déclenche plus de notifications, mais son historique (snapshots) reste consultable. La suppression est définitive et irréversible.
- **Snapshot budgétaire**: Capture historique mensuelle d'un budget. Attributs : montant budgété (normalisé en mensuel), devise, taux de conversion vers la devise principale, montant dépensé, mois concerné. Créé de manière lazy à la première consultation d'un mois passé. Immuable une fois créé.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer un budget en moins de 30 secondes (3 champs à remplir + sélection catégorie).
- **SC-002**: La progression des dépenses par rapport au budget est visible en moins de 2 secondes après ouverture du dashboard.
- **SC-003**: La navigation entre les mois de l'historique est fluide, chaque mois se charge en moins de 2 secondes.
- **SC-004**: Les notifications de seuil sont envoyées immédiatement (synchrone, dans le même appel HTTP) lors de l'ajout, modification ou suppression d'une transaction.
- **SC-005**: 100% des snapshots de mois passés restent intacts même après modification des budgets ou des taux de conversion.
- **SC-006**: L'utilisateur peut identifier en un coup d'oeil les catégories proches du dépassement grâce aux barres de progression colorées.
- **SC-007**: La feature est disponible sur les trois plateformes (API, Angular, Flutter) de manière cohérente.

## Clarifications

### Session 2026-03-09

- Q: Déduplication des notifications de seuil — une seule notification par franchissement ou à chaque transaction ? → A: Une seule notification par seuil franchi par mois (80% notifié une fois, 100% notifié une fois).
- Q: Budget actif/inactif vs suppression — quel comportement pour un budget désactivé ? → A: Désactiver masque le budget du dashboard et stoppe les notifications, mais conserve l'historique. Supprimer efface définitivement.
- Q: Combien de "top catégories" afficher dans la section Budgets du dashboard ? → A: Top 5 catégories (les plus consommées, ratio dépenses/budget le plus élevé).
- Q: La catégorie "Autre" (dépenses non budgétées) est-elle interactive ? → A: Oui, cliquable avec drill-down affichant le détail des catégories non budgétées et leurs montants.

## Assumptions

- Le système de taux de conversion (KKS-156) est disponible et fonctionnel.
- Le système de notifications push + in-app est disponible.
- La devise principale de l'utilisateur est configurable dans ses préférences.
- Les catégories sont déjà gérées et associables aux transactions.
- Le calcul des dépenses se base uniquement sur les transactions de type DEPENSE (pas les recettes).
- Le facteur de normalisation hebdomadaire vers mensuel est fixé à 4.33 (52 semaines / 12 mois).

## Dependencies

- **KKS-156**: Gestion des devises — taux de conversion manuels (requis pour les budgets multi-devises).
- **Système de notifications**: Push + in-app (requis pour les alertes de seuil).
- **Feature toggles existants**: Enum Feature avec valeur BUDGETS.

## Scope Boundaries

### Inclus

- CRUD complet des budgets (création, lecture, modification, suppression)
- Calcul des dépenses par catégorie et par mois
- Normalisation des fréquences (hebdo/mensuel/annuel) en mensuel
- Snapshots lazy pour l'historique
- Dashboard avec section budgets
- Écran dédié avec liste complète + catégorie "Autre"
- Historique avec camembert et vue détaillée
- Notifications de seuil et de dépassement
- Feature toggle BUDGETS
- Multi-devises avec conversion

### Exclu

- Suivi des recettes (dépenses uniquement)
- Budgets partagés entre utilisateurs
- Export des données budgétaires
- Prévisions ou recommandations automatiques
- Budgets par compte (uniquement par catégorie)
