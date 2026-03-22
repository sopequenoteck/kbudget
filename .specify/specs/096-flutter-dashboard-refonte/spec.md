# Feature Specification: Refonte Dashboard Flutter

**Feature Branch**: `096-flutter-dashboard-refonte`
**Created**: 2026-03-20
**Status**: Draft
**Linear**: KKS-201
**Input**: Alignement du dashboard Flutter sur le wireframe valide, deja implemente cote Angular (KKS-200)

## Clarifications

### Session 2026-03-20

- Q: Dans quelle devise sont calcules les montants Revenus/Depenses ? → A: Devise principale (currencies[0]), comme Angular. La ligne de conversion secondaire utilise currencies[1].
- Q: Quel comportement au tap sur la cloche et l'avatar du header ? → A: Cloche → ouvre le NotificationPanel existant (ou noop si stub). Avatar → ouvre un menu dropdown avec : nom utilisateur, "Parametres" (navigue vers /settings), "Deconnexion" (logout). Aligne sur le menu utilisateur Angular existant dans le shell.

## User Scenarios & Testing

### User Story 1 - Carte Patrimoine Total (Priority: P1)

L'utilisateur ouvre l'application et voit immediatement une carte "Patrimoine Total" affichant la somme de tous ses comptes actifs convertis dans la devise active. Un badge indique la variation mensuelle (montant + pourcentage). Si l'utilisateur a plusieurs devises, un sous-texte montre la conversion dans la devise secondaire.

**Why this priority**: C'est l'information financiere principale que l'utilisateur recherche en ouvrant l'app. Remplace l'actuel HeroAccountSection qui affiche les comptes individuels.

**Independent Test**: Peut etre teste en verifiant que le montant patrimoine = somme des soldes convertis de tous les comptes actifs, et que la variation % reflete le net du mois par rapport au patrimoine en debut de mois.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec 2 comptes (1 en EUR, 1 en USD) et des taux de change configures, **When** il ouvre le dashboard, **Then** il voit "PATRIMOINE TOTAL" suivi du montant total converti dans la devise active, un badge variation (ex: "+320,00 EUR ce mois (+2,1%)"), et une ligne conversion en devise secondaire (ex: "~ $13 929,36")
2. **Given** un utilisateur avec 1 seul compte et 1 seule devise, **When** il ouvre le dashboard, **Then** il voit la carte patrimoine sans ligne de conversion secondaire
3. **Given** un taux de change manquant pour un compte, **When** le patrimoine est calcule, **Then** un indicateur d'avertissement (icone warning) est affiche a cote du montant
4. **Given** le patrimoine en debut de mois etait 0 (nouveau compte), **When** le dashboard s'affiche, **Then** la variation % n'est pas affichee (eviter division par zero)

---

### User Story 2 - Cartes Revenus / Depenses (Priority: P1)

L'utilisateur voit deux cartes cote-a-cote sous la carte patrimoine : Revenus et Depenses du mois en cours en devise principale (currencies[0]). Chaque carte affiche le montant, un delta par rapport au mois precedent (ex: "+200 vs fev."), et optionnellement une conversion en devise secondaire (currencies[1]).

**Why this priority**: Information essentielle pour le suivi mensuel. Remplace l'actuel MonthlySummarySection (barres de progression + MonthSelector) par un design aligne sur le wireframe Angular.

**Independent Test**: Verifier que les montants Revenus/Depenses correspondent aux sommes des transactions RECETTE/DEPENSE du mois en devise principale, et que le delta est la difference avec le mois precedent.

**Acceptance Scenarios**:

1. **Given** des transactions RECETTE et DEPENSE pour le mois en cours et le mois precedent, **When** le dashboard s'affiche, **Then** deux cartes cote-a-cote montrent les montants en devise principale avec un dot vert (revenus) et rouge (depenses), et un badge delta vs mois precedent (ex: "up +200 vs fev.")
2. **Given** aucune transaction ce mois, **When** le dashboard s'affiche, **Then** les cartes montrent 0,00 et le delta reflete la difference avec le mois precedent
3. **Given** plusieurs devises configurees, **When** le dashboard s'affiche, **Then** chaque carte affiche une ligne conversion en devise secondaire (ex: "~ $1 234,56") sous le montant principal

---

### User Story 3 - Header avec salutation, cloche et avatar (Priority: P2)

L'utilisateur voit un header enrichi avec une salutation personnalisee ("Bonjour [Prenom]"), une icone cloche pour les notifications (avec badge si notifications non lues), et un avatar circulaire avec l'initiale de son nom. La cloche ouvre le panneau de notifications. L'avatar ouvre un menu dropdown avec le nom utilisateur, un lien vers les parametres, et une option de deconnexion.

**Why this priority**: Alignement visuel avec le wireframe et parite fonctionnelle avec le menu utilisateur Angular du shell.

**Independent Test**: Verifier visuellement que le header contient les 3 elements (salutation a gauche, cloche + avatar a droite) et que les interactions fonctionnent.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecte avec le nom "Kelly", **When** le dashboard s'affiche, **Then** le header montre "Bonjour Kelly" a gauche, et une cloche + avatar "K" a droite
2. **Given** des notifications non lues existent, **When** le dashboard s'affiche, **Then** un badge numerique apparait sur l'icone cloche
3. **Given** le systeme de notifications n'est pas encore disponible, **When** le dashboard s'affiche, **Then** la cloche est affichee mais le badge est masque (stub)
4. **Given** l'utilisateur tape sur l'avatar, **When** le menu s'ouvre, **Then** il voit son nom, un lien "Parametres" (navigue vers /settings), et "Deconnexion" (logout + retour ecran login)
5. **Given** l'utilisateur tape sur la cloche, **When** le panneau notifications est disponible, **Then** le NotificationPanel s'ouvre

---

### User Story 4 - Dernieres operations avec badges devise et conversion (Priority: P2)

La liste des 5 dernieres transactions affiche pour chaque operation : l'icone categorie, le libelle, la date + nom du compte, un badge devise si differente de la devise active, le montant (vert/rouge), et un sous-texte de conversion si la devise differe.

**Why this priority**: Enrichissement de la section existante pour atteindre la parite avec Angular (badges devise + montants convertis).

**Independent Test**: Creer des transactions dans differentes devises et verifier que les badges et conversions s'affichent correctement.

**Acceptance Scenarios**:

1. **Given** une transaction en USD alors que la devise active est EUR, **When** le dashboard s'affiche, **Then** la transaction montre un badge "USD" et un sous-texte "~ 123,45 EUR"
2. **Given** une transaction dans la meme devise que la devise active, **When** le dashboard s'affiche, **Then** pas de badge devise ni de sous-texte conversion
3. **Given** un tap sur "Voir tout", **When** l'utilisateur clique, **Then** il est navigue vers la liste complete des transactions
4. **Given** un tap sur une transaction, **When** l'utilisateur clique, **Then** le formulaire d'edition s'ouvre (comportement existant conserve)

---

### User Story 5 - Section Budgets conditionnelle (Priority: P3)

La section Budgets reste visible conditionnellement (feature BUDGETS activee) et affiche un apercu des budgets du mois avec barres de progression. Un lien "Voir tout" mene a l'ecran Budgets.

**Why this priority**: Section deja existante dans Flutter (BudgetSummarySection). Necessite un alignement mineur avec le wireframe (tri par % depasse, max 4 items).

**Independent Test**: Activer/desactiver la feature BUDGETS et verifier l'apparition/disparition de la section.

**Acceptance Scenarios**:

1. **Given** la feature BUDGETS est activee et des budgets existent, **When** le dashboard s'affiche, **Then** la section "Budgets - [Mois]" apparait avec max 4 categories triees par % de consommation decroissant
2. **Given** la feature BUDGETS est desactivee, **When** le dashboard s'affiche, **Then** la section n'apparait pas
3. **Given** un budget depasse (> 100%), **When** la section s'affiche, **Then** il apparait en premier dans la liste avec un indicateur visuel de depassement

---

### User Story 6 - Suppression des MiniCards et du MonthSelector (Priority: P3)

Les sections MiniCardsSection (abonnements/dettes) et le MonthSelector du resume mensuel sont supprimes du dashboard pour se conformer au wireframe valide. Ces informations restent accessibles via les ecrans dedies.

**Why this priority**: Alignement avec le wireframe qui ne contient pas ces elements. Impact faible car les donnees restent accessibles ailleurs.

**Independent Test**: Verifier que le dashboard ne contient plus ces widgets apres la refonte.

**Acceptance Scenarios**:

1. **Given** le nouveau dashboard, **When** l'utilisateur fait defiler, **Then** il ne voit plus les cartes Abonnements/Dettes ni le selecteur de mois
2. **Given** l'utilisateur veut acceder aux abonnements, **When** il utilise la navigation, **Then** il accede toujours a la liste des abonnements via le menu

---

### Edge Cases

- Que se passe-t-il si l'utilisateur n'a aucun compte ? Un etat vide avec message d'invitation est affiche (comportement existant conserve).
- Que se passe-t-il si les taux de change ne sont pas disponibles ? Les montants restent dans leur devise d'origine avec un indicateur d'avertissement sur le patrimoine total.
- Que se passe-t-il si la requete resume mensuel echoue ? Le patrimoine total et les transactions restent affiches ; seules les cartes revenus/depenses montrent un etat d'erreur non-bloquant.
- Que se passe-t-il en mode hors-ligne (donnees locales) ? Le dashboard fonctionne avec les donnees Drift sans conversion multi-devises (pas de taux disponibles en local).
- Que se passe-t-il avec le pull-to-refresh ? Toutes les sections se rechargent (comptes, transactions, taux, resumes).

## Requirements

### Functional Requirements

- **FR-001**: Le dashboard DOIT afficher une carte "Patrimoine Total" avec la somme des soldes de tous les comptes actifs convertis dans la devise active
- **FR-002**: La carte patrimoine DOIT afficher la variation mensuelle en montant et en pourcentage par rapport au patrimoine en debut de mois
- **FR-003**: Si l'utilisateur a au moins 2 devises, la carte patrimoine DOIT afficher une conversion en devise secondaire (currencies[1])
- **FR-004**: Le dashboard DOIT afficher deux cartes Revenus/Depenses cote-a-cote avec les totaux du mois en cours en devise principale (currencies[0])
- **FR-005**: Chaque carte Revenus/Depenses DOIT afficher un delta par rapport au mois precedent (montant absolu + direction)
- **FR-006**: Le header DOIT afficher une salutation personnalisee, une icone cloche notifications (ouvre NotificationPanel), et un avatar utilisateur (ouvre menu dropdown : nom, parametres, deconnexion)
- **FR-007**: Les dernieres transactions DOIVENT afficher un badge devise si la devise de la transaction differe de la devise active
- **FR-008**: Les dernieres transactions DOIVENT afficher un sous-texte de conversion si la devise differe
- **FR-009**: La section Budgets DOIT etre conditionnelle (feature BUDGETS activee) et afficher max 4 items tries par % consommation decroissant
- **FR-010**: Le dashboard DOIT supporter le pull-to-refresh pour recharger toutes les donnees
- **FR-011**: Le dashboard DOIT afficher des skeletons shimmer pendant le chargement initial
- **FR-012**: Les MiniCardsSection (abonnements/dettes) et le MonthSelector DOIVENT etre supprimes du dashboard
- **FR-013**: Le dashboard DOIT utiliser un CustomScrollView avec SliverList pour la performance
- **FR-014**: Un indicateur d'avertissement (icone warning) DOIT s'afficher si des taux de change sont manquants pour le calcul du patrimoine

### Key Entities

- **DashboardState** : Etat agrege du dashboard (patrimoine, variation, revenus/depenses du mois courant et precedent en devise principale, transactions recentes, devise active, devises, taux de change, nom utilisateur)
- **PatrimoineData** : Ensemble de calculs derives (pas une classe Freezed separee) — montant total converti, variation mensuelle (montant + %), montant en devise secondaire, indicateur taux manquants. Calcules dans le widget PatrimoineCard a partir de DashboardState
- **MonthlySummary** : Modele existant reutilise (totalRecettes, totalDepenses, bilan, currency). Le dashboard charge le mois courant et le mois precedent pour calculer le delta

## Success Criteria

### Measurable Outcomes

- **SC-001**: Le dashboard Flutter affiche les memes sections dans le meme ordre que le dashboard Angular (patrimoine, revenus/depenses, budgets, transactions)
- **SC-002**: Les montants de patrimoine, revenus et depenses sont identiques entre Angular et Flutter pour les memes donnees
- **SC-003**: Le temps de chargement initial du dashboard ne depasse pas 3 secondes sur un appareil standard
- **SC-004**: Le pull-to-refresh recharge toutes les donnees en moins de 5 secondes
- **SC-005**: L'utilisateur peut voir son patrimoine total et sa variation mensuelle des l'ouverture de l'app
- **SC-006**: Les tests couvrent le DashboardNotifier (calculs patrimoine, variation, delta) et les widgets principaux (PatrimoineCard, IncomeExpenseCards, DashboardHeader)

## Assumptions

- Le MonthSelector est supprime du dashboard (le resume se base toujours sur le mois en cours, comme Angular)
- Les MiniCards (abonnements/dettes) sont supprimees du dashboard (informations accessibles via navigation)
- Le calcul de la variation patrimoniale utilise la meme logique que Angular : (patrimoine_actuel - patrimoine_debut_mois) / patrimoine_debut_mois * 100, ou patrimoine_debut_mois = patrimoine_actuel - net_du_mois
- La cloche notifications est stub si le systeme de notifications Flutter n'est pas encore cable
- Le DashboardNotifier existant est enrichi/modifie (pas de reecriture complete), en ajoutant les donnees manquantes (resume mois courant + precedent, calculs variation)
- Le selecteur de devises (CurrencyPillSelector) est conserve tel quel
- L'etat vide (aucun compte) reste inchange
