# Research: Écran Transactions Liste (Flutter)

**Feature**: `043-flutter-transactions-list` | **Date**: 2026-02-22

## R1 — Chargement par mois (`getByMonth`)

**Decision**: Ajouter `getByMonth(int month, int year)` au repository, DAO et remote data source.

**Rationale**: Le `TransactionNotifier` existant charge TOUTES les transactions via `getAll()`. Le spec (FR-015) exige un chargement par mois uniquement. Ajouter une méthode dédiée est plus performant que filtrer côté client après un `getAll()`.

**Alternatives considered**:
- Filtrer `getAll()` côté client → rejeté : charge inutile, pas scalable
- Modifier `getAll()` avec paramètres optionnels → rejeté : casse l'interface existante utilisée par le dashboard

**Implementation**:
- DAO: requête Drift avec filtre date `>= startOfMonth` et `< startOfNextMonth`
- Remote: `GET /transactions?month=M&year=Y` (endpoint à confirmer/créer côté API)
- Pattern identique à `getMonthlySummary()` déjà implémenté dans le DAO

## R2 — Notifier dédié vs extension du notifier existant

**Decision**: Créer un `TransactionListNotifier` séparé avec son propre `TransactionListState` (Freezed).

**Rationale**: Le `TransactionNotifier` existant gère le CRUD global et est consommé par le dashboard (`dashboardNotifierProvider`). Le modifier pour supporter le chargement par mois casserait le dashboard. Un notifier dédié permet une séparation propre : chargement mensuel + filtrage type + résumé.

**Alternatives considered**:
- Étendre `TransactionNotifier` avec `loadByMonth()` → rejeté : casse le contrat `loadItems()` utilisé par le dashboard
- `FutureProvider.family<List<Transaction>, ({int month, int year})>` → rejeté : pas de gestion du filtrage client-side ni du state complexe (summary + filter + loading)

## R3 — Renommage `solde` → `bilan` dans MonthlySummary

**Decision**: Renommer le champ `solde` en `bilan` dans le modèle `MonthlySummary` et adapter le DTO `MonthlySummaryResponse`.

**Rationale**: Clarification spec — le terme "bilan" est préféré à "solde" pour la métrique recettes - dépenses.

**Impact cascade**:
- `monthly_summary.dart` → champ `bilan`
- `transaction_dtos.dart` → `MonthlySummaryResponse` : garder `solde` dans le JSON API mais mapper vers `bilan` via `@JsonKey(name: 'solde')`
- `transaction_repository_local.dart` → variable locale `bilan`
- `transaction_repository_remote.dart` → mapper `r.solde` → `bilan:`
- Dashboard widgets → accès `.bilan` au lieu de `.solde`
- Régénération `build_runner`

## R4 — Ajustements exclus du résumé mensuel

**Decision**: Filtrer les transactions de type `ajustement` dans le calcul du résumé mensuel.

**Rationale**: Clarification spec — les ajustements sont des corrections techniques, pas des recettes/dépenses. Les inclure fausserait les métriques.

**Implementation**:
- DAO local : ajouter `AND type != 'ajustement'` dans la requête SQL `getMonthlySummary()`
- Remote : le backend filtre déjà (contrat API existant retourne les métriques calculées côté serveur)

## R5 — Groupement par jour avec en-têtes de section

**Decision**: Utiliser `SliverList` natif avec des en-têtes de section (pas de sticky réel).

**Rationale**: La complexité d'un vrai sticky header (package `sliver_tools` ou `SliverPersistentHeader`) n'apporte pas assez de valeur pour une liste mensuelle (~30 jours max). Un en-tête de section standard dans un `CustomScrollView` suffit et reste simple.

**Alternatives considered**:
- `sliver_tools` package → rejeté : dépendance supplémentaire non justifiée pour ce volume de données
- `grouped_list` package → rejeté : widget opinioné qui ne s'intègre pas dans un `CustomScrollView`
- `SliverPersistentHeader` natif → viable mais complexe pour un bénéfice marginal

## R6 — Format des en-têtes de jour

**Decision**: Créer un helper `DayHeaderFormatter` (méthode statique) :
- "Aujourd'hui" si `date == today`
- "Hier" si `date == yesterday`
- "Lundi 20 février" sinon (`EEEE d MMMM` locale `fr_FR`)

**Rationale**: FR-004a spécifie ce format. Le `RelativeDateFormatter` existant ne correspond pas (utilise "il y a X jours"). Le helper sera dans `utils/` car réutilisable.

## R7 — Réactivité retour formulaire édition

**Decision**: Recharger le mois courant au retour du formulaire d'édition via `refresh()` sur le `TransactionListNotifier`.

**Rationale**: Plus simple que d'écouter les changements du `TransactionNotifier` global via `ref.listen()`. Le screen appelle `refresh()` dans un callback `.then()` après `context.push()` (quand la route pop).

## R8 — SegmentedFilter — type du filtre

**Decision**: Créer un enum `TransactionTypeFilter { all, depense, recette }` local au feature.

**Rationale**: Utiliser `TransactionType?` avec `null` pour "Tous" est ambigu. Un enum dédié est explicite et le coût est minimal (3 valeurs).

**Alternatives considered**:
- `SegmentedFilter<String>` avec `'tous'`, `'depense'`, `'recette'` → rejeté : pas type-safe
- `TransactionType?` avec `null` = "Tous" → rejeté : semantique ambiguë

## R9 — Navigation vers formulaire d'édition

**Decision**: Utiliser `context.push('/transactions/${transaction.id}')` via go_router.

**Rationale**: Le formulaire d'édition n'existe pas encore (ticket séparé). La navigation est préparée avec le pattern standard. Quand le formulaire sera développé, la route enfant sera ajoutée au router. En attendant, le tap ne navigue pas (protection via vérification de l'existence de la route, ou simplement non implémenté — TODO).
