# Research: Flutter — Écran Abonnements Liste

**Date**: 2026-02-23 | **Branch**: `046-flutter-subscriptions-list`

## R1 — Pattern filtre côté client (notifier + state dédié)

**Decision**: Créer un `SubscriptionListState` Freezed dédié avec `activeFilter` et `filteredItems`, en suivant le pattern `TransactionListState`.

**Rationale**: Le `TransactionListNotifier` utilise un state Freezed dédié (`TransactionListState`) séparé du générique `ListState<T>`. Ce state contient `allMonthTransactions`, `filteredTransactions`, `activeFilter`, `summary`, `isLoading`, `error`. Le pattern `_applyFilter()` + `setFilter()` est éprouvé et permet un changement de filtre instantané sans appel réseau. Le `SubscriptionNotifier` actuel utilise `ListState<Subscription>` avec un `_allItems` interne — il sera refactoré pour utiliser un state dédié identique au pattern transaction.

**Alternatives considered**:
- Garder `ListState<Subscription>` et ajouter le filtre comme variable locale dans le screen → Rejeté : le filtre ne serait pas persisté lors de refresh, et le summary ne pourrait pas être calculé côté notifier.
- Créer un notifier séparé juste pour le filtre → Rejeté : complexité inutile, le notifier existant gère déjà la liste.

## R2 — Calcul prochaine date de renouvellement

**Decision**: Créer une fonction utilitaire `nextRenewalDate(DateTime dateDebut, Frequency frequence)` dans `utils/next_renewal_date.dart`.

**Rationale**: La logique Angular existante avance la date par incrément (mois ou année) depuis `dateDebut` jusqu'à dépasser `today`. C'est une logique pure (sans side effects) qui mérite d'être isolée pour testabilité et réutilisation (dashboard, notifications futures). Le pattern Dart utilise `DateTime(year, month + n, day)` qui gère nativement le débordement de mois.

**Alternatives considered**:
- Extension method sur `Subscription` → Rejeté : couple la logique au modèle, moins testable isolément.
- Calcul inline dans le screen → Rejeté : non testable, dupliqué si réutilisé.

## R3 — Badge inactif

**Decision**: Utiliser le paramètre `rightSubtitle` de `ListItem` existant pour afficher le badge inactif. Le texte "Inactif" est affiché via `rightSubtitle` en `bodySmall` sous la valeur de l'item. La spec a été alignée sur cette approche (texte en couleur d'erreur du thème, sans pill badge).

**Rationale**: Le `ListItem` actuel a un `rightSubtitle` qui rend un texte discret sous la valeur à droite. Pour une app mono-utilisateur avec ~50 abonnements max, ce texte est suffisamment visible pour identifier les inactifs au premier coup d'œil (SC-004). L'approche pill badge de l'Angular (positionnement absolu, fond coloré) serait de la sur-ingénierie côté Flutter.

**Alternatives considered**:
- Widget badge custom wrappant le `ListItem` → Rejeté : sur-ingénierie pour un texte statique (Principe III YAGNI).
- Modifier `ListItem` pour ajouter un paramètre `badge` avec fond coloré → Rejeté : modification d'un widget partagé pour un seul usage.

## R4 — Total mensuel par devise (summary card)

**Decision**: Calculer les totaux dans le notifier et les exposer via le state. Widget `_SubscriptionSummaryCard` privé dans le screen (pas de widget séparé).

**Rationale**: Le total mensuel est un calcul simple : `sum(actifs.map(s => s.frequence == mensuel ? s.montant : s.montant / 12))` groupé par `currency`. Le `TransactionListScreen` utilise un `TransactionSummaryCard` comme widget séparé. Mais pour les abonnements, le summary est plus simple (juste un total) donc un widget privé dans le screen suffit.

**Alternatives considered**:
- Widget séparé dans `presentation/widgets/` → Rejeté : un seul usage, pas de réutilisation prévisible.
- Calcul dans le screen via `computed` → Rejeté : logique métier mieux placée dans le notifier.

## R5 — Localisation des labels de fréquence

**Decision**: Ajouter des clés i18n pour les labels de fréquence (`/mois`, `/an`) et les options du filtre dans `app_fr.arb` et `app_en.arb`.

**Rationale**: Actuellement les labels "Mensuel"/"Annuel" sont hardcodés dans le screen. Ils doivent être localisés via les fichiers ARB existants. Les clés suivront le pattern existant (`subscriptionsFilter*`, `subscriptionsSummary*`).

**Alternatives considered**: Aucune — la localisation est un standard du projet.
