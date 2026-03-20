# Feature Specification: Dashboard Finance (Ecran d'accueil)

**Feature Branch**: `090-finance-dashboard`
**Created**: 2026-03-15
**Status**: Draft
**Linear**: KKS-200
**Input**: Wireframe detaille du dashboard finance — ecran d'accueil avec patrimoine total, revenus/depenses, budgets, transactions recentes, multi-devises

## Clarifications

### Session 2026-03-15

- Q: Combien de budgets afficher sur le dashboard et dans quel ordre ? → A: Maximum 4 budgets, tries par urgence (depasses d'abord, puis pourcentage de consommation le plus eleve). Le lien "Voir tout" mene a la liste complete.
- Q: Comment calculer la variation du patrimoine affichee sur le dashboard ? → A: Combine deux approches — le patrimoine affiche la variation nette du mois (montant absolu + pourcentage : net du mois / patrimoine debut de mois), les cartes revenus/depenses affichent la comparaison vs mois precedent en montant absolu.
- Q: Quelle strategie de rafraichissement des donnees du dashboard ? → A: Auto-refresh au retour sur le dashboard + refresh periodique toutes les 60 secondes tant que le dashboard est visible.
- Q: Que faire des sections existantes du dashboard absentes du wireframe (cartes comptes, mini-cartes abos/dettes, section abonnements, section dettes, selecteur de mois) ? → A: Le dashboard suit le wireframe exactement. Ces sections sont retirees. Les donnees restent accessibles via les ecrans dedies.
- Q: FR-022 pull-to-refresh est-il applicable au web Angular ? → A: Non, FR-022 retire. Le pull-to-refresh sera dans la spec Flutter separee.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Voir son patrimoine total au premier coup d'oeil (Priority: P1)

En ouvrant l'application, l'utilisateur voit immediatement son patrimoine total dans sa devise principale, avec la variation par rapport au mois precedent et la contre-valeur dans une devise secondaire. C'est l'information la plus importante du dashboard : savoir ou on en est financierement.

**Why this priority**: Le patrimoine total est la donnee financiere la plus recherchee. Sans elle, le dashboard n'a pas de raison d'etre.

**Independent Test**: Peut etre teste en accedant au dashboard avec un compte ayant des transactions. Le patrimoine total s'affiche avec sa variation mensuelle et sa conversion.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des comptes actifs et des transactions, **When** il ouvre le dashboard, **Then** le patrimoine total s'affiche dans sa devise principale (premiere devise de ses preferences)
2. **Given** un patrimoine de 2500 EUR avec un revenu net de 1276 EUR ce mois (revenus 3200 - depenses 1924), **When** le dashboard se charge, **Then** la variation affiche "+1 276 EUR ce mois (+104,2%)" en vert, calculee comme le net du mois rapporte au patrimoine de debut de mois
3. **Given** un utilisateur avec EUR comme devise principale et XAF dans ses devises, **When** le patrimoine s'affiche, **Then** une contre-valeur approximative en XAF est affichee sous le montant principal (calculee via les taux de change de l'utilisateur)
4. **Given** un utilisateur sans aucun compte, **When** il ouvre le dashboard, **Then** le patrimoine affiche 0 dans sa devise principale avec un message d'incitation a creer un compte

---

### User Story 2 - Consulter le bilan mensuel revenus/depenses (Priority: P1)

L'utilisateur voit deux cartes cote a cote : revenus du mois en cours et depenses du mois en cours, chacune avec le montant, la variation par rapport au mois precedent et une contre-valeur dans la devise secondaire selectionnee.

**Why this priority**: Le couple revenus/depenses est le coeur du suivi budgetaire mensuel. C'est l'information qui guide les decisions de depenses au quotidien.

**Independent Test**: Peut etre teste avec des transactions du mois courant et du mois precedent. Les deux cartes affichent les montants et variations corrects.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des transactions ce mois, **When** le dashboard se charge, **Then** deux cartes revenus et depenses s'affichent cote a cote avec les totaux du mois en cours
2. **Given** des revenus de 3200 EUR ce mois et 3000 EUR le mois precedent, **When** la carte revenus s'affiche, **Then** elle montre "+200 vs [mois precedent]" en indicateur de tendance
3. **Given** un utilisateur avec USD selectionne comme devise d'affichage, **When** les cartes s'affichent, **Then** une contre-valeur en USD est visible sous chaque montant
4. **Given** un utilisateur sans transaction ce mois, **When** le dashboard se charge, **Then** les deux cartes affichent 0 dans la devise principale

---

### User Story 3 - Suivre ses budgets du mois (Priority: P2)

L'utilisateur voit un resume de ses budgets du mois en cours : un total global (depenses/budget total) et la liste des budgets par categorie avec une barre de progression. Les budgets depasses sont clairement signales visuellement.

**Why this priority**: Le suivi budgetaire est un pilier de la gestion de budget. L'afficher sur le dashboard evite de naviguer vers un ecran dedie pour un simple coup d'oeil.

**Independent Test**: Peut etre teste en creant des budgets et des transactions. Les barres de progression et le total s'affichent correctement, les depassements sont visibles.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des budgets actifs, **When** le dashboard se charge, **Then** une section "Budgets - [Mois courant]" affiche le resume global et les 4 budgets les plus urgents (depasses d'abord, puis par pourcentage de consommation decroissant)
2. **Given** un budget "Voyages" de 300 EUR avec 450 EUR depenses, **When** la section budgets s'affiche, **Then** ce budget est affiche avec une barre de progression a 150% et un indicateur visuel de depassement
3. **Given** un utilisateur avec des budgets, **When** il appuie sur "Voir tout", **Then** il est redirige vers l'ecran complet des budgets
4. **Given** un utilisateur sans budget, **When** le dashboard se charge, **Then** la section budgets n'est pas affichee (ou affiche un message d'incitation)
5. **Given** un utilisateur dont la feature BUDGETS est desactivee, **When** le dashboard se charge, **Then** la section budgets n'apparait pas

---

### User Story 4 - Voir les dernieres transactions (Priority: P2)

L'utilisateur voit ses transactions les plus recentes (les 5 dernieres) avec l'icone de categorie, le libelle, le montant (signe), la date et la devise. Si la transaction est dans une devise differente de la devise d'affichage, la contre-valeur est indiquee.

**Why this priority**: Les dernieres transactions donnent un apercu rapide de l'activite financiere recente sans naviguer vers la liste complete.

**Independent Test**: Peut etre teste en creant des transactions. Les 5 dernieres apparaissent dans l'ordre chronologique inverse avec les bonnes informations.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des transactions, **When** le dashboard se charge, **Then** les 5 dernieres transactions s'affichent en ordre chronologique inverse
2. **Given** une transaction de -210 EUR dans la categorie "Voyages", **When** la liste s'affiche, **Then** la transaction montre l'icone de la categorie, le libelle, "-210,00 EUR" et la date
3. **Given** une transaction en USD et un affichage en EUR, **When** la transaction s'affiche, **Then** la contre-valeur approximative en EUR est indiquee
4. **Given** un utilisateur avec des transactions, **When** il appuie sur "Voir tout", **Then** il est redirige vers la liste complete des transactions
5. **Given** un utilisateur sans transaction, **When** le dashboard se charge, **Then** la section affiche un message indiquant qu'il n'y a pas encore de transaction

---

### User Story 5 - Selectionner la devise d'affichage des contre-valeurs (Priority: P3)

L'utilisateur peut changer la devise d'affichage des contre-valeurs via un selecteur horizontal en haut du dashboard. La devise principale reste celle de ses preferences, mais les contre-valeurs affichees sous les montants changent selon la devise selectionnee.

**Why this priority**: La multi-devises est un besoin secondaire mais important pour un utilisateur international. Le selecteur enrichit l'experience sans etre bloquant pour le MVP.

**Independent Test**: Peut etre teste en selectionnant differentes devises dans le selecteur. Les contre-valeurs changent sur toutes les sections du dashboard.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec les devises [EUR, USD, GBP, XAF] dans ses preferences, **When** le dashboard se charge, **Then** un selecteur horizontal affiche ces devises, avec la devise principale (EUR) pre-selectionnee
2. **Given** la devise USD selectionnee dans le selecteur, **When** l'utilisateur change pour GBP, **Then** toutes les contre-valeurs du dashboard se mettent a jour en GBP
3. **Given** un utilisateur avec une seule devise configuree, **When** le dashboard se charge, **Then** le selecteur de devise n'est pas affiche et aucune contre-valeur n'apparait

---

### User Story 6 - En-tete personnalise avec salutation et acces rapides (Priority: P3)

L'utilisateur est accueilli avec un message de salutation personnalise (son prenom ou nom) et a un acces direct aux notifications (icone cloche) et a son profil (avatar).

**Why this priority**: L'en-tete personnalise est un element de polish UX. Il apporte de la chaleur a l'application mais n'est pas fonctionnellement critique.

**Independent Test**: Peut etre teste en se connectant avec un utilisateur ayant un nom renseigne. Le message de salutation et les icones s'affichent.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecte avec le nom "Kelly SOSSOE", **When** le dashboard se charge, **Then** l'en-tete affiche "Bonjour Kelly SOSSOE"
2. **Given** un utilisateur sans nom renseigne, **When** le dashboard se charge, **Then** l'en-tete affiche "Bonjour" sans nom
3. **Given** des notifications non lues, **When** le dashboard se charge, **Then** l'icone de notification affiche un badge avec le nombre de non-lues
4. **Given** l'utilisateur appuie sur l'icone notification, **When** l'action se declenche, **Then** le panneau de notifications s'ouvre

---

### Edge Cases

- Que se passe-t-il si l'utilisateur n'a configure aucun taux de change ? Les contre-valeurs ne sont pas affichees (masquees, pas de "N/A" ni de 0)
- Que se passe-t-il si le serveur est injoignable au chargement du dashboard ? Un etat d'erreur avec bouton "Reessayer" s'affiche
- Que se passe-t-il si la variation mensuelle est de 0% ? L'indicateur affiche "0% ce mois" en neutre (ni vert ni rouge)
- Que se passe-t-il si le patrimoine total est negatif ? Le montant s'affiche en rouge avec un signe moins
- Que se passe-t-il si une devise dans le selecteur n'a pas de taux de change configure ? Les contre-valeurs ne sont pas affichees (masquees, pas de "N/A" ni de 0)
- Que se passe-t-il au 1er du mois quand il n'y a pas encore de transactions ? Les sections affichent 0 avec la mention du mois precedent en comparaison

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher un ecran d'accueil (dashboard) comme premier ecran apres connexion
- **FR-002**: Le dashboard DOIT afficher le patrimoine total de l'utilisateur dans sa devise principale (premiere devise des preferences utilisateur)
- **FR-003**: Le dashboard DOIT afficher la variation nette du patrimoine ce mois, en montant absolu ET en pourcentage (net du mois / patrimoine debut de mois), avec un indicateur visuel (couleur verte pour hausse, rouge pour baisse, neutre pour stable)
- **FR-004**: Le dashboard DOIT afficher une contre-valeur du patrimoine total dans la devise secondaire selectionnee, calculee via les taux de change de l'utilisateur
- **FR-005**: Le dashboard DOIT afficher deux cartes cote a cote pour les revenus et depenses du mois en cours
- **FR-006**: Chaque carte revenus/depenses DOIT afficher le montant total, la variation par rapport au mois precedent (en montant absolu, ex: "+200 vs fev.") et une contre-valeur dans la devise selectionnee
- **FR-007**: Le dashboard DOIT afficher un resume des budgets du mois avec un total global et les 4 budgets les plus urgents (tries par depassement puis par pourcentage de consommation decroissant), avec une barre de progression par categorie
- **FR-008**: Les budgets depasses DOIVENT etre visuellement distingues (couleur d'alerte, indicateur de depassement)
- **FR-009**: Le dashboard DOIT afficher les 5 transactions les plus recentes en ordre chronologique inverse
- **FR-010**: Chaque transaction DOIT afficher : icone categorie, libelle, montant signe, date, devise, et contre-valeur si la devise differe de la devise d'affichage
- **FR-011**: Le dashboard DOIT proposer un selecteur horizontal de devises base sur les devises configurees dans les preferences de l'utilisateur
- **FR-012**: Le changement de devise dans le selecteur DOIT mettre a jour toutes les contre-valeurs affichees sur le dashboard
- **FR-013**: L'en-tete DOIT afficher un message de salutation personnalise avec le nom de l'utilisateur
- **FR-014**: L'en-tete DOIT afficher une icone de notification avec badge (nombre de non-lues) et une icone profil/avatar
- **FR-015**: Les liens "Voir tout" DOIVENT rediriger vers les ecrans complets (budgets, transactions)
- **FR-016**: Les sections conditionnelles (budgets) DOIVENT respecter les feature toggles de l'utilisateur
- **FR-017**: Le dashboard DOIT gerer les etats vides (aucun compte, aucune transaction, aucun budget) avec des messages d'incitation adaptes
- **FR-018**: Le dashboard DOIT afficher un etat de chargement (skeleton/shimmer) pendant le chargement des donnees
- **FR-019**: Le dashboard DOIT gerer les erreurs de chargement avec un mecanisme de retry
- **FR-020**: Le dashboard DOIT rafraichir automatiquement ses donnees au retour sur l'ecran (apres navigation ou retour d'arriere-plan)
- **FR-021**: Le dashboard DOIT rafraichir ses donnees periodiquement toutes les 60 secondes tant qu'il est visible
- **FR-022**: [RETIRE — non applicable au web Angular. Sera dans la spec Flutter separee.]
- **FR-023**: Le dashboard DOIT suivre la structure du wireframe KKS-200 : en-tete → selecteur devise → patrimoine total → revenus/depenses → budgets → transactions recentes. Les sections existantes absentes du wireframe (cartes de comptes individuels, mini-cartes abonnements/dettes, section abonnements actifs, section dettes actives, selecteur de mois) DOIVENT etre retirees

### Key Entities

- **Patrimoine Total** : Solde agrege de tous les comptes actifs par devise, ajuste avec les dettes. Attributs : montant par devise, variation mensuelle (pourcentage), contre-valeur dans la devise selectionnee
- **Bilan Mensuel** : Somme des revenus et depenses du mois courant et du mois precedent. Attributs : total revenus, total depenses, variation vs mois precedent, devise, contre-valeur
- **Resume Budget** : Agregation de l'overview des budgets du mois. Attributs : total budget, total depense, pourcentage global, liste des budgets par categorie avec progression
- **Transaction Recente** : Les N dernieres transactions de l'utilisateur. Attributs : libelle, montant, type, date, categorie (nom, icone, couleur), devise, contre-valeur

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur voit son patrimoine total, revenus et depenses du mois en moins de 2 secondes apres ouverture du dashboard
- **SC-002**: Les contre-valeurs en devises secondaires s'affichent correctement pour toutes les devises configurees par l'utilisateur
- **SC-003**: Le changement de devise dans le selecteur met a jour toutes les contre-valeurs instantanement (sans rechargement des donnees)
- **SC-004**: 100% des sections conditionnelles respectent les feature toggles actifs de l'utilisateur
- **SC-005**: Les etats vides (aucun compte, aucune transaction, aucun budget) affichent des messages d'incitation clairs au lieu d'ecrans vides
- **SC-006**: L'utilisateur peut acceder a la liste complete des transactions ou des budgets en un seul appui depuis le dashboard
- **SC-007**: Le dashboard fonctionne correctement avec 1 seule devise configuree (pas de selecteur, pas de contre-valeurs) comme avec 4+ devises

## Assumptions

- Le calcul du patrimoine total reutilise l'endpoint existant `GET /accounts/total-balance` qui agrege comptes + dettes par devise
- Le bilan mensuel reutilise l'endpoint existant `GET /transactions/summary?month=M&year=Y`
- Le resume budgets reutilise l'endpoint existant `GET /budgets/overview`
- Les transactions recentes reutilisent l'endpoint existant `GET /transactions` avec pagination (les 5 premieres)
- Les taux de change reutilisent l'endpoint existant `GET /exchange-rates`
- Le nom de l'utilisateur provient de `GET /users/me`
- Les notifications non-lues proviennent du systeme de notifications existant
- La variation du patrimoine est calculee cote frontend : net du mois (revenus - depenses via summary) rapporte au patrimoine de debut de mois (total-balance actuel - net du mois)
- L'endpoint `GET /transactions/summary` doit etre appele pour le mois courant ET le mois precedent pour calculer les variations
- Le dashboard est une feature frontend uniquement — aucun nouvel endpoint backend n'est necessaire
- Cette spec couvre uniquement le frontend Angular (PWA). L'adaptation Flutter fera l'objet d'une spec separee
