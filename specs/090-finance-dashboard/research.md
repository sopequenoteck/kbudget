# Research: Dashboard Finance (Ecran d'accueil)

**Date**: 2026-03-15
**Feature**: 090-finance-dashboard

## Constat principal : les dashboards existent deja

Les deux frontends disposent deja d'un ecran dashboard fonctionnel. Cette feature est une **evolution** (enrichissement), pas une creation.

### Dashboard Angular existant (`app/src/app/features/dashboard/`)

Sections actuelles :
1. Zone comptes — solde total (converti en devise active), cartes de comptes scrollables
2. Zone KPI — selecteur de mois, 3 cartes resume (recettes/depenses/solde), 3 mini-cartes (abos/dettes dues/dettes a recevoir)
3. Transactions recentes — 5 dernieres via `app-list-item`
4. Abonnements actifs — top 3
5. Dettes actives — 3 dernieres
6. Section budgets — conditionnelle (feature toggle BUDGETS)

Services injectes : TransactionService, SubscriptionService, DebtService, AccountService, ModalService, ConversionService, PreferenceService, ExchangeRateService.

Composant `CurrencyPillSelector` deja present.

### Dashboard Flutter

Le dashboard Flutter existe egalement mais **hors scope** de cette spec. L'adaptation Flutter fera l'objet d'une spec separee.

## Ecarts identifies vs wireframe cible (Angular uniquement)

| Element wireframe | Etat actuel Angular | Action |
|---|---|---|
| Patrimoine total avec variation % | Solde total sans variation | MODIFIER : ajouter calcul variation nette du mois |
| Variation en montant absolu + % | Non present | AJOUTER : formule net/patrimoine debut mois |
| Contre-valeur patrimoine | Conversion partielle | ENRICHIR : afficher sous le montant principal |
| Cartes revenus/depenses avec variation vs mois precedent | Cartes KPI sans comparaison mois-1 | MODIFIER : ajouter "+X vs [mois precedent]" |
| Contre-valeurs sur cartes revenus/depenses | Non present | AJOUTER |
| Budgets limites a 4, tries par urgence | Affiche tous les budgets | MODIFIER : limiter a 4 + tri |
| Contre-valeurs sur transactions | Non present | AJOUTER |
| Auto-refresh 60s | Non present | AJOUTER |
| En-tete avec salutation | Dans shell (logo + user) | ENRICHIR : salutation personnalisee |

## Decisions techniques

### Decision 1 : Calcul de la variation du patrimoine

- **Decision** : Calculer cote frontend — net du mois (via summary) rapporte au patrimoine debut de mois (total-balance - net du mois)
- **Rationale** : Pas besoin d'un nouvel endpoint. Les donnees summary (mois courant) + total-balance suffisent
- **Alternatives considerees** : Endpoint dedie GET /dashboard/summary — rejete car viole le principe YAGNI et les donnees existent deja

### Decision 2 : Comparaison revenus/depenses vs mois precedent

- **Decision** : Appeler GET /transactions/summary pour le mois courant ET le mois precedent en parallele
- **Rationale** : Simple, pas de nouvel endpoint, deux appels paralleles negligeables
- **Alternatives considerees** : Endpoint comparatif — rejete, sur-ingenierie

### Decision 3 : Auto-refresh 60s

- **Decision** : Timer periodique cote frontend, annule a la sortie du dashboard
- **Rationale** : Pattern standard, simple a implementer avec effect() (Angular) ou Timer.periodic (Flutter)
- **Alternatives considerees** : WebSocket push — deja en place pour notifications, mais sur-ingenierie pour un refresh global du dashboard

### Decision 4 : Tri des budgets par urgence

- **Decision** : Filtrer/trier cote frontend apres reception de l'overview existant
- **Rationale** : L'endpoint /budgets/overview retourne deja items avec percentage. Trier par percentage DESC, garder les 4 premiers
- **Alternatives considerees** : Parametre ?limit=4&sort=urgency sur l'endpoint — rejete, logique triviale cote client

### Decision 5 : Pas de nouvel endpoint backend

- **Decision** : Aucun nouvel endpoint. Le dashboard consomme exclusivement les endpoints existants
- **Rationale** : Tous les endpoints necessaires existent (total-balance, summary, overview, transactions, exchange-rates, users/me, notifications/unread-count)
- **Alternatives considerees** : Endpoint agrege GET /dashboard — rejete car viole YAGNI et creerait du couplage

### Decision 6 : Restructuration selon le wireframe exact

- **Decision** : Retirer les sections absentes du wireframe (cartes de comptes individuels, mini-cartes abos/dettes, section abonnements actifs, section dettes actives, selecteur de mois) et restructurer le dashboard selon le layout du wireframe KKS-200
- **Rationale** : Le wireframe represente la vision cible. Les donnees retirees du dashboard restent accessibles via les ecrans dedies (comptes, abonnements, dettes). Un dashboard epure est plus lisible et plus utile
- **Alternatives considerees** : Conserver toutes les sections existantes + ajouter les nouvelles — rejete car surchargerait le dashboard et diluerait les informations cles

### Decision 7 : Scope Angular uniquement

- **Decision** : Cette spec couvre uniquement le frontend Angular (PWA). L'adaptation Flutter fera l'objet d'une spec separee
- **Rationale** : Permet de valider le design sur une plateforme avant de l'adapter. Reduit la taille des taches et facilite la review
- **Alternatives considerees** : Spec cross-plateforme — rejete car augmente la complexite et le risque d'incoherences
