# Research: Écran Dashboard

**Feature**: 015-dashboard | **Date**: 2026-02-12

## R-001: Pattern de communication parent-enfant pour les modales

**Decision**: Utiliser `inject(Shell)` dans le Dashboard pour accéder aux méthodes d'édition du Shell parent.

**Rationale**: Angular permet l'injection de composants parents via `inject()`. Le Shell est un ancêtre direct du Dashboard dans l'arbre de composants (Shell > RouterOutlet > Dashboard). Les signals du Shell sont déjà publics. Ajouter 3 méthodes d'édition (`openEditTransaction`, `openEditSubscription`, `openEditDebt`) maintient la cohérence et la centralisation.

**Alternatives considered**:
- Service partagé (ModalService) : créerait une indirection inutile pour un seul cas d'usage, viole YAGNI
- @Output chain : impossible avec RouterOutlet (pas de parent-enfant direct dans le template)
- Router state : complexifie la navigation pour un simple clic d'édition

## R-002: Chargement indépendant des sections

**Decision**: 3 appels HTTP séparés avec signaux individuels loading/error/data par section.

**Rationale**: Le `forkJoin` global bloquerait toutes les sections si une seule échoue. Le pattern existant dans les écrans de liste utilise `forkJoin` car les données sont liées (transactions + summary du même mois). Ici, les 3 sections sont indépendantes.

**Alternatives considered**:
- `forkJoin` global : une erreur sur une section bloque tout le dashboard
- `combineLatest` : complexifie la gestion des états individuels sans bénéfice

## R-003: Bilan mensuel — réutilisation du pattern transactions

**Decision**: Réutiliser exactement le pattern du sélecteur de mois et des cartes summary de l'écran transactions.

**Rationale**: Le code HTML/SCSS/TS du sélecteur de mois et des 3 cartes (Recettes, Dépenses, Solde) existe déjà dans `transactions.ts`. Le dashboard reproduit ce même pattern avec les mêmes classes CSS. Pas de refactoring en composant partagé — 2 occurrences seulement (YAGNI).

**Alternatives considered**:
- Extraire un composant `MonthSelector` partagé : prématuré (2 usages), ajoute complexité sans bénéfice immédiat
- Composant `SummaryCards` partagé : même raisonnement

## R-004: Aperçus — tri et filtrage

**Decision**:
- Transactions : tri par date décroissante, slice(0, 5), toutes périodes confondues
- Abonnements : filtre actif=true, tri alphabétique par nom, slice(0, 3)
- Dettes : filtre rembourse=false, tri par date décroissante, slice(0, 3)

**Rationale**: Cohérent avec les hypothèses de la spec et les patterns de tri des écrans de liste existants.
