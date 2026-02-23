# Research: Flutter — Écran Dettes Liste

**Feature**: 048-flutter-debts-list | **Date**: 2026-02-23

## Résumé

Aucun "NEEDS CLARIFICATION" dans le Technical Context. Toutes les décisions techniques s'appuient sur des patterns déjà éprouvés dans le projet (SubscriptionListScreen, branche 046). La recherche ci-dessous documente les choix de design et les alternatives évaluées.

---

## R1. State management : ListState<T> générique vs DebtListState custom

**Decision** : Créer un `DebtListState` Freezed custom (comme `SubscriptionListState`).

**Rationale** : Le `ListState<T>` générique ne supporte ni `activeFilter` ni `summary`. Le pattern custom est déjà éprouvé par `SubscriptionListState` et reste simple (un seul fichier Freezed).

**Alternatives considered** :
- Garder `ListState<Debt>` et stocker le filtre/résumé dans des providers séparés → Plus de providers à coordonner, moins cohérent, risque de désynchronisation.
- Ajouter les champs au `ListState<T>` générique → Casserait les autres notifiers (Transaction, Account) qui n'ont pas besoin de ces champs.

---

## R2. Groupement des dettes en sections (Prêts / Emprunts)

**Decision** : Le groupement se fait dans le widget `_buildContent`, pas dans le notifier. Le state contient une liste plate `items`, le screen la partitionne par `debt.sens` (DebtType.pret / DebtType.emprunt).

**Rationale** : Le notifier gère le filtrage et la pagination. Le regroupement visuel est une concern de présentation. Cela évite de complexifier le state avec des listes multiples.

**Alternatives considered** :
- Stocker `prets` et `emprunts` comme deux listes séparées dans le state → Double maintenance dans les méthodes CRUD, pagination complexifiée, pas de précédent dans le projet.
- Utiliser un `groupBy` dans le notifier → Ajoute un concept inutile alors qu'un simple `.where()` dans le screen suffit.

---

## R3. Résumé financier : structure des totaux

**Decision** : Utiliser `Map<Currency, DebtCurrencySummary>` dans le state, où `DebtCurrencySummary` est un record Dart simple (`({double totalEmprunts, double totalPrets})`). Le solde net est calculé à l'affichage (prets − emprunts).

**Rationale** : Un record est léger, pas besoin d'une classe Freezed pour deux doubles. Le solde net est dérivé, donc pas stocké pour éviter la redondance.

**Alternatives considered** :
- `Map<Currency, double>` unique (solde net seulement) → Ne permet pas d'afficher les totaux emprunts/prêts séparément dans la carte récapitulative (FR-007).
- Trois maps séparées (emprunts, prêts, soldeNet) → Plus verbeux, plus d'erreurs possibles de désynchronisation.
- Classe Freezed `DebtSummary` → Over-engineering pour deux champs. Un typedef record suffit.

---

## R4. Sous-totaux de section : calcul côté notifier ou côté widget

**Decision** : Calcul côté widget. Les sous-totaux reflètent les items filtrés visibles (qui sont déjà dans `state.items`). Un simple `fold()` par devise sur les items de chaque section dans le `build()`.

**Rationale** : Les sous-totaux dépendent du filtre actif ET du groupement par type, les deux étant des concerns de présentation. Le notifier fournit déjà les `items` filtrés. Ajouter des sous-totaux dans le state dupliquerait l'information.

**Alternatives considered** :
- Sous-totaux dans le state (4 maps : pretsTotals, empruntsTotals par devise) → Redondant avec `items`, complexifie le state pour un calcul trivial.

---

## R5. Section headers dans un CustomScrollView avec Slivers

**Decision** : Utiliser des `SliverToBoxAdapter` pour les headers de section, suivis de `SliverList.builder` pour les items de chaque section. Les deux sections sont des slivers distincts dans le `CustomScrollView`.

**Rationale** : Pattern Flutter standard pour des listes sectionnées dans un `CustomScrollView`. Pas de package externe nécessaire. Compatible avec le `RefreshIndicator` existant.

**Alternatives considered** :
- Un seul `SliverList.builder` avec des items hétérogènes (headers + items) → Index management complexe, pas de séparation claire.
- `SliverStickyHeader` (package externe) → Dépendance externe inutile pour un cas simple.

---

## R6. Enum de filtre : nommage

**Decision** : `DebtStatusFilter { all, enCours, rembourse }` dans `domain/enums/debt_status_filter.dart`.

**Rationale** : Cohérent avec `SubscriptionStatusFilter { all, actif, inactif }`. Les noms `enCours`/`rembourse` correspondent aux labels UI et au champ `rembourse` du modèle Debt.

**Alternatives considered** :
- `{ all, nonRembourse, rembourse }` → `nonRembourse` est une double négation, moins lisible.
- `{ all, pending, repaid }` → Anglais alors que le reste du domaine utilise des termes français (cohérence).

---

## R7. Couleurs sémantiques du résumé

**Decision** : Utiliser les couleurs existantes de `AppThemeExtension` :
- Emprunts → `debtOweColor` (ce que je dois)
- Prêts → `debtOwedColor` (ce qu'on me doit)
- Solde net positif → `incomeColor` (vert)
- Solde net négatif → `expenseColor` (rouge)
- Solde net zéro → `onSurfaceVariant` (neutre)

**Rationale** : Les couleurs `debtOweColor` et `debtOwedColor` existent déjà dans le thème. Les couleurs income/expense sont déjà utilisées pour indiquer positif/négatif dans l'app.

**Alternatives considered** :
- Couleurs hardcodées → Violation des design tokens du projet.
- Utiliser uniquement colorScheme.error/colorScheme.primary → Moins de nuance sémantique.

---

## R8. Localisation des nouvelles clés

**Decision** : Ajouter les clés i18n dans les fichiers ARB existants (`app_en.arb`, `app_fr.arb`). Clés nécessaires :
- `debtsTitle` : "Dettes"
- `debtsSummaryEmprunts` : "Emprunts"
- `debtsSummaryPrets` : "Prêts"
- `debtsSummaryNet` : "Solde net"
- `debtsFilterAll` : "Tous"
- `debtsFilterEnCours` : "En cours"
- `debtsFilterRembourse` : "Remboursé"
- `debtsEmpty` : "Aucune dette"
- `debtsEmptyEnCours` : "Aucune dette en cours"
- `debtsEmptyRembourse` : "Aucune dette remboursée"
- `debtsSectionPrets` : "Prêts"
- `debtsSectionEmprunts` : "Emprunts"
- `debtBadgeRembourse` : "Remboursé"

**Rationale** : Suit le pattern de nommage `subscriptions*` / `transactions*` déjà en place.
