# Research — 076-budget-category-tracking

## R1: Notification de seuil budgétaire — mécanisme de déclenchement

**Decision**: Vérification synchrone dans `TransactionService` après chaque create/update/delete de transaction de type DEPENSE.

**Rationale**: L'application est single-user avec un volume de transactions faible. Un check synchrone est simple, fiable et respecte le principe YAGNI. Pas besoin d'événements asynchrones ou de jobs batch.

**Alternatives considered**:
- Job batch périodique (cron toutes les 5 min) : plus complexe, délai non déterministe, ajout de `@Scheduled` inutile pour single-user
- Event-driven (Spring Events) : abstraction prématurée pour un seul consommateur
- Check côté frontend : violerait API-First, logique métier dupliquée

## R2: Déduplication des notifications — tracking par mois

**Decision**: Utiliser la table `notifications` existante pour vérifier si une notification de type `BUDGET_THRESHOLD` ou `BUDGET_EXCEEDED` existe déjà pour un budget donné (`entityType=BUDGET`, `entityId=budgetId`) dans le mois en cours.

**Rationale**: Pas besoin de nouvelle table. La table `notifications` contient déjà `type`, `entityType`, `entityId` et `createdAt`. Une query `existsByTypeAndEntityTypeAndEntityIdAndCreatedAtBetween` suffit.

**Alternatives considered**:
- Nouvelle table `budget_notification_tracking` : sur-ingénierie pour un besoin simple
- Champ `lastNotifiedAt` sur `Budget` : ne gère pas les deux seuils (80% et 100%) séparément
- Colonne `notifiedThresholds` (JSON) sur `Budget` : complexe, pas standard JPA

## R3: Calcul des dépenses non budgétées ("Autre")

**Decision**: Calculer côté API dans `BudgetService` via une query dédiée sur `TransactionRepository` : somme des dépenses du mois par catégorie, excluant les catégories ayant un budget actif. Retourner la liste détaillée (nom catégorie + montant) + le total dans les réponses overview et history.

**Rationale**: Centralise la logique métier côté API (API-First). Les frontends reçoivent les données prêtes à l'emploi. En mode local Flutter, la même logique est reproduite via SQL Drift.

**Alternatives considered**:
- Calcul côté frontend : viole API-First, duplication de logique
- Catégorie système "Autre" en BDD : complexifie le modèle, faux lien catégorie

## R4: Snapshots lazy en mode local Flutter

**Decision**: Dans `BudgetRepositoryLocal.getHistory()`, si aucun snapshot n'existe pour le mois demandé et que le mois est passé, créer les snapshots en utilisant les budgets actifs à la date courante et les dépenses réelles du mois. Stocker le taux de conversion depuis la table locale `exchange_rates`.

**Rationale**: Aligne le comportement local sur le comportement remote (API). L'utilisateur en mode local ne doit pas voir un historique vide.

**Alternatives considered**:
- Ne pas supporter les snapshots en local : dégrade l'expérience offline
- Synchroniser les snapshots depuis l'API : nécessite un mode hybride non supporté actuellement

## R5: Conversion multi-devises en mode local Flutter

**Decision**: Dans `BudgetRepositoryLocal.getOverview()`, pour chaque budget dont la devise diffère de la devise principale (lue depuis `AppConfig`), appliquer le taux de conversion depuis la table Drift `exchange_rates`. Fallback à 1.0 si aucun taux trouvé (même comportement que l'API).

**Rationale**: Cohérence avec le backend. La table `exchange_rates` existe déjà dans le schéma Drift.

**Alternatives considered**:
- Ignorer la conversion en local : totaux faux si budgets multi-devises
- Fetch taux depuis API : sort du scope local-only
