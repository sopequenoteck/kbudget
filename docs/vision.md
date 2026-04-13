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
- Transactions recurrentes (HEBDOMADAIRE / MENSUEL / ANNUEL) avec validation/skip/desactivation
- Virements entre comptes

### 2. Abonnements

- Vue centralisee de tous les abonnements recurrents
- Montant total mensuel visible
- Paiement d'abonnement (cree une transaction liee)
- Historique et cumul des paiements

### 3. Dettes & prets

- Suivi de qui doit quoi a qui (dans les deux sens)
- Historique des remboursements (partiels ou totaux)
- Multi-devises (EUR, XOF, USD, GBP, CHF, CAD, MAD)
- Rappels configurables (date + heure) avec snooze
- Option d'inclusion dans le solde total

### 4. Comptes

- Multi-comptes (COURANT / EPARGNE / ESPECES) avec soldes calcules
- Virements inter-comptes
- Association a une banque (29 banques supportees FR/TG/International)
- Solde total agrege par devise

### 5. Budgets

- Budget par categorie (HEBDOMADAIRE / MENSUEL / ANNUEL)
- Vue mensuelle avec pourcentage de consommation
- Seuil de notification configurable (defaut 80%)
- Historique (snapshots mensuels)
- Detection des depenses hors budget

### 6. Import CSV

- Upload avec detection automatique du profil bancaire
- Preview, mapping manuel, brouillons editables
- Detection de doublons (Jaro-Winkler)
- Regles de categorisation par pattern
- Profils pre-configures + personnalises

### 7. Notifications

- Notifications en temps reel via WebSocket/STOMP (auth via StompAuthInterceptor)
- Scheduler backend pour les notifications planifiees (echeances abonnements, dettes, seuils budgets)
- Types : SUBSCRIPTION_DUE, DEBT_DUE, DEBT_REMINDER, BUDGET_THRESHOLD, BUDGET_EXCEEDED
- Marquage lu/non lu, compteur non lues, suppression unitaire et globale
- Pagination des notifications

### 8. Profil utilisateur

- Consultation et modification du profil (nom)

### 9. Preferences et personnalisation

- Features activables (SUBSCRIPTIONS, DEBTS, BUDGETS)
- Multi-devises avec devise principale configurable
- Taux de conversion manuels avec rebase automatique
- Ordre de navigation personnalisable
- Types de notifications activables (opt-out par type)
- Taille de texte configurable (SMALL / MEDIUM / LARGE)

## Principes UX

- Mobile first
- Saisie ultra-rapide (2-3 taps pour enregistrer une depense)
- Enrichissement des donnees a la volee ou apres coup

## Stack technique

| Couche | Choix |
|--------|-------|
| Backend | Spring Boot 4.0.2 (API REST, Java 21) |
| Frontend | Angular 21 PWA (`k-budget-app`, dossier `app/`) |
| Mobile | Flutter >= 3.27 / Dart >= 3.6 (`k_budget`, dossier `flutter/`) |
| Base de donnees | PostgreSQL 15+ |
| Auth | Spring Security + JWT |
| Reverse proxy | Caddy (auto-HTTPS) |
| Hebergement | Serveur personnel (self-hosted) |
| URL | `https://budget.kksdev.fr` |

## Hors scope (pour plus tard)

- Bilans avances (graphiques, comparaisons mois par mois)
- Ouverture multi-utilisateurs
- Categorisation automatique par ML (les regles de categorisation manuelles par pattern sont implementees)
