# Budget App — Vision produit

## Contexte

Application personnelle de gestion de budget. Usage quotidien, mobile first.
Hebergee en self-hosted sur serveur personnel.

## Modules fonctionnels

### 1. Transactions (depenses + recettes)

- Entite unique `Transaction` avec un type (DEPENSE / RECETTE)
- Saisie rapide : montant + libelle + type minimum
- Enrichissement ulterieur (categorie, note, etc.)
- Bilan mensuel simple (total depense, total recette, solde)

### 2. Abonnements

- Vue centralisee de tous les abonnements recurrents
- Montant total mensuel visible

### 3. Dettes & prets

- Suivi de qui doit quoi a qui (dans les deux sens)
- Historique des remboursements

## Principes UX

- Mobile first
- Saisie ultra-rapide (2-3 taps pour enregistrer une depense)
- Enrichissement des donnees a la volee ou apres coup

## Stack technique

| Couche | Choix |
|--------|-------|
| Backend | Spring Boot 4.0.2 (API REST, Java 21) |
| Frontend | Angular 21 PWA (`k-budget-app`, dossier `app/`) |
| Base de donnees | PostgreSQL 15+ |
| Auth | Spring Security + JWT |
| Reverse proxy | Caddy (auto-HTTPS) |
| Hebergement | Serveur personnel (self-hosted) |
| URL | `https://budget.kksdev.fr` |

## Hors scope v1 (pour plus tard)

- Bilans avances (graphiques, comparaisons mois par mois)
- Ouverture multi-utilisateurs
- Categorisation automatique des depenses
