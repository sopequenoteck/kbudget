# Roadmap V2 — document clos

> **Statut : archivé le 26 août 2026.** Ce document a été défini le 15 février 2026 pour une
> échéance au 7 avril 2026. Il est conservé pour l'historique des décisions, mais **ne décrit
> plus la trajectoire du projet**.
>
> La direction en vigueur est [`direction.md`](direction.md), traduite en règles dans
> [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) v4.0.0.
> Le backlog d'exécution vit dans Linear (projet Budget, jalons P1 à P8).

## Bilan de livraison

État vérifié contre le code au 26 août 2026.

| # | Feature | État | Détail |
|---|---|---|---|
| 1 | Comptes bancaires | **Livré** | Entité `Account`, rattachement transactions et abonnements, virements par `transferId`, soldes par compte, 29 banques référencées |
| 2 | Refonte Settings | **Livré** | Sections comptes, catégories, budgets, notifications, profil, apparence, données |
| 3 | Budget mensuel | **Livré** | Budgets par catégorie (hebdo/mensuel/annuel), seuils d'alerte, snapshots, détection hors-budget |
| 4 | Notifications | **Partiel** | In-app via WebSocket/STOMP et scheduler backend : livrés. **Web Push (VAPID) et résumés périodiques : non implémentés** |
| 5 | Graphiques & bilans | **Partiel** | `budget-chart` et `doughnut-mini` existent, mais **uniquement dans les budgets**. Pas de camembert global par catégorie, pas de barres d'évolution mensuelle, pas de comparaison mois par mois |
| 6 | UX filtres, recherche, pagination | **Non livré** | La spec `docs/features/search-filter-transactions/` est restée en statut *Draft*. Les icônes recherche et filtre du header de la page Transactions **sont décoratives** — aucun handler. Aucune pagination `Pageable` côté transactions (elle n'existe que sur les notifications et l'historique d'import) |

## Ce que la nouvelle direction change

- **L'agrégation bancaire, un temps envisagée en suite de cette roadmap, est écartée** : elle
  exigerait un agrément AISP, donc une entité exploitant un service. L'alimentation passe par
  l'import de relevés avec des profils bancaires contribués par la communauté
  (jalon P6 dans Linear).
- **Les graphiques avancés (feature 5) sont classés « Jamais » côté Flutter** : ils restent une
  surface Angular. Cf. principe VIII de la constitution.
- **Web Push (feature 4) reste pertinent** et devient même nécessaire : sans lui, un utilisateur
  qui n'installe pas l'app mobile n'a aucune notification hors application ouverte.
- **Les items 4, 5 et 6 non livrés n'ont pas d'issue Linear à ce jour.** Ils ne figurent dans
  aucun des jalons P1 à P8, qui portent l'ouverture du projet et non les fonctionnalités.

---

# Document d'origine (15 février 2026)

## Vision

La V1 pose les fondations (CRUD, auth, PWA). La V2 rend l'app **intelligente et proactive** : comptes bancaires, budgets, graphiques, notifications push.

## Features

### 1. Comptes bancaires

Structurer les donnees autour de comptes reels.

- Entite `Account` : nom, type (COURANT/EPARGNE/ESPECES), soldeInitial, icone, couleur, actif, isDefault
- Transaction rattachee a un compte (obligatoire, compte par defaut pre-selectionne)
- Abonnement rattache a un compte (optionnel dans un premier temps)
- Dettes NON rattachees a un compte (pas pertinent tant que non remboursee)
- Solde courant = soldeInitial + recettes - depenses
- Virements entre comptes : 2 transactions liees par un `transferId`
- Dashboard : solde par compte + solde total

### 2. Refonte Settings

Page Settings restructuree en 8 sections :

| Section | Contenu |
|---------|---------|
| Comptes bancaires | CRUD comptes, compte par defaut |
| Categories | Gestion categories (existe deja) |
| Budget | Objectifs mensuels (global + par categorie) |
| Notifications | Activer/desactiver par type, delais, heure d'envoi |
| Profil | Nom, email, mot de passe, devise |
| Apparence | Theme light/dark, langue |
| Donnees | Export CSV/PDF, purge, stats stockage |
| A propos | Version, lien repo |

### 3. Budget mensuel

Definir des objectifs et suivre la progression.

- Budget global mensuel (ex: max 2000 EUR/mois)
- Budget par categorie (ex: max 200 EUR/mois en Resto)
- Barre de progression sur le dashboard
- Seuils d'alerte (80%, 100%) alimentant les notifications

### 4. Notifications

Rendre l'app proactive.

**Implemente :**
- Notifications in-app via WebSocket/STOMP (temps reel)
- Scheduler backend (NotificationScheduler) pour echeances abonnements, dettes, seuils budgets
- CRUD notifications : liste paginee, compteur non lues, marquage lu, suppression
- Preferences : types de notifications activables (opt-out par type)

**Non implemente (prevu plus tard) :**
- Web Push API (VAPID keys) pour notifications native meme app fermee
- Resumes periodiques (bilan hebdo/mensuel automatique)

### 5. Graphiques & bilans

Comprendre ses depenses visuellement.

- Camembert repartition par categorie
- Barres evolution mensuelle (depenses/recettes)
- Comparaison mois par mois
- Lib graphique frontend (Chart.js ou equivalent)
- Endpoints backend pour les agregations

### 6. UX (filtres, recherche, pagination)

Naviguer efficacement dans les donnees.

- Filtrage transactions : par categorie, periode, montant, compte
- Recherche full-text (libelle, note)
- Tri (date, montant)
- Pagination backend (Spring Data Pageable)

## Phases

```
Phase 1 — Fondations
  ├── Comptes bancaires
  └── Refonte Settings

Phase 2 — Intelligence
  ├── Budget mensuel
  └── Notifications push

Phase 3 — Visibilite
  ├── Graphiques & bilans
  └── UX (filtres, recherche, pagination)
```

## Decisions prises

| Decision | Choix | Raison |
|----------|-------|--------|
| Compte sur transaction | Obligatoire | Donnee structurante, compte par defaut pour garder la saisie rapide |
| Compte sur abonnement | Oui | Savoir ou est preleve chaque abo |
| Compte sur dette | Non | Pas pertinent tant que non remboursee |
| Virements | Oui | 2 transactions liees par transferId |
| Type de notifications | In-app (WebSocket/STOMP) | Web Push prevu plus tard, notifications in-app suffisantes pour le MVP |
| Rappels | Abonnements + dettes + budget | Les 3 types implementes via scheduler backend |
