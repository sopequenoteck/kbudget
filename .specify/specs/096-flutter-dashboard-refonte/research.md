# Research: Refonte Dashboard Flutter

**Feature**: 096-flutter-dashboard-refonte | **Date**: 2026-03-20

## R1: Source de donnees pour le resume mensuel (revenus/depenses)

**Decision**: Utiliser le `monthlySummaryProvider` existant qui appelle l'API `GET /api/transactions/summary?month=X&year=Y`. Charger le mois courant ET le mois precedent en parallele pour calculer le delta.

**Rationale**: Angular utilise `TransactionService.getSummary(month, year)` qui retourne un `MonthlySummary` avec `totalRecettes`, `totalDepenses`, `solde`, `currency`. Flutter dispose deja de ce provider (`monthlySummaryProvider`). L'API retourne les totaux en devise principale du compte — les conversions sont faites cote client.

**Alternatives considered**:
- Calculer les totaux cote client a partir de la liste de transactions → rejete : redondant avec l'API existante, risque de divergence avec Angular
- Ajouter un nouvel endpoint "dashboard summary" → rejete : YAGNI, les endpoints existants suffisent

## R2: Calcul de la variation patrimoniale

**Decision**: Adopter la meme logique que Angular :
- `patrimoine_actuel` = somme des soldes comptes actifs convertis en devise principale
- `net_du_mois` = totalRecettes - totalDepenses (du mois courant)
- `patrimoine_debut_mois` = patrimoine_actuel - net_du_mois
- `variation_%` = (net_du_mois / patrimoine_debut_mois) * 100
- Si patrimoine_debut_mois = 0, la variation % n'est pas affichee

**Rationale**: Coherence cross-plateforme. Le calcul est une approximation (ne prend pas en compte les transferts ou ajustements intra-mois) mais suffisant pour un indicateur mensuel.

**Alternatives considered**:
- Calculer via snapshots historiques → rejete : pas de table snapshots patrimoine, complexite inutile
- Utiliser les taux du debut de mois pour la conversion → rejete : taux historiques non stockes

## R3: Devise secondaire pour les conversions

**Decision**: `currencies[1]` (deuxieme devise dans la liste ordonnee des preferences utilisateur). Si la devise active (currencies[0]) a ete changee via le pill selector, la devise secondaire est la devise principale initiale ou la prochaine disponible (meme logique que Angular `secondaryCurrency` computed).

**Rationale**: Aligne sur Angular. L'utilisateur voit toujours une conversion dans une devise differente de celle affichee.

**Alternatives considered**:
- Toujours afficher en EUR comme secondaire → rejete : pas pertinent si l'utilisateur a EUR comme devise principale
- Afficher toutes les devises → rejete : surcharge visuelle

## R4: Menu avatar (dropdown)

**Decision**: Implementer un menu popup (PopupMenuButton ou custom overlay) qui affiche : nom utilisateur (non cliquable), "Parametres" (navigue vers /settings), "Deconnexion" (appelle AuthService.logout() + retour ecran login).

**Rationale**: Parite avec Angular qui a ce menu dans le shell (shell.html). Flutter n'a pas de barre laterale, donc le menu va dans le header du dashboard.

**Alternatives considered**:
- Bottom sheet au lieu de dropdown → rejete : trop lourd pour 2 actions
- Navigation directe sans menu → rejete : ne permet pas le logout depuis le dashboard

## R5: Gestion du NotificationPanel (cloche)

**Decision**: Verifier si le NotificationPanel Flutter existe et est fonctionnel. Si oui, l'ouvrir au tap. Si non disponible (pas encore implemente), la cloche est affichee mais le tap est un no-op.

**Rationale**: La spec precise "stub si le systeme de notifications n'est pas encore disponible". Evite de bloquer la feature sur une dependance optionnelle.

**Alternatives considered**:
- Ne pas afficher la cloche du tout si stub → rejete : le wireframe l'inclut, et elle sera fonctionnelle a terme

## R6: Widgets existants a supprimer

**Decision**: Supprimer `hero_account_section.dart`, `monthly_summary_section.dart`, `mini_cards_section.dart` apres avoir cree leurs remplacants. Verifier qu'aucun autre ecran ne les importe.

**Rationale**: Ces widgets ne sont utilises que dans `dashboard_screen.dart`. Leur suppression evite le code mort.

**Alternatives considered**:
- Les conserver et les deprecier → rejete : YAGNI, ils ne sont pas reutilises ailleurs

## R7: DashboardState — champs a ajouter/modifier

**Decision**: Enrichir le DashboardState existant avec :
- `currentSummary` (MonthlySummary?) : totaux du mois courant
- `previousSummary` (MonthlySummary?) : totaux du mois precedent
- Supprimer `selectedMonth`, `selectedYear`, `isSummaryLoading` (plus de MonthSelector)
- Supprimer `subscriptionMonthlyTotal`, `activeSubscriptionCount`, `debtNetBalance`, `activeDebtCount` (plus de MiniCards)
- Conserver `accounts`, `defaultAccount` (pour le calcul patrimoine), `recentTransactions`, `activeCurrency`, `exchangeRates`, `currencies`, `userName`, `isLoading`, `error`

**Rationale**: Le DashboardState doit refleter la nouvelle structure du dashboard. Supprimer les champs inutiles pour eviter la dette technique.

**Alternatives considered**:
- Creer un nouveau state from scratch → rejete : le state existant contient deja la majorite des champs necessaires, mieux vaut le modifier
