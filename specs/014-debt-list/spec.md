# Feature Specification: Ecran Debts (liste + filtres)

**Feature Branch**: `014-debt-list`
**Created**: 2026-02-12
**Status**: Draft
**Input**: User description: "Ecran Debts (liste + filtres) - KKS-56"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des dettes (Priority: P1)

L'utilisateur ouvre l'ecran des dettes pour voir toutes ses dettes en cours et remboursees. La liste affiche chaque dette avec le nom de la personne, le montant, le sens (je dois / on me doit) et la date. Les dettes sont differenciees visuellement par des couleurs : rouge pour "je dois", vert pour "on me doit".

**Why this priority**: C'est la fonctionnalite principale de l'ecran. Sans la liste, aucune autre fonctionnalite (filtres, resume) n'a de sens.

**Independent Test**: Peut etre teste en naviguant vers l'ecran des dettes et en verifiant que toutes les dettes de l'utilisateur connecte sont affichees avec les bonnes informations et couleurs.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est connecte et possede des dettes, **When** il accede a l'ecran des dettes, **Then** toutes ses dettes sont affichees sous forme de liste avec personne, montant, sens et date
2. **Given** l'utilisateur est connecte et ne possede aucune dette, **When** il accede a l'ecran des dettes, **Then** un message "Aucune dette" est affiche
3. **Given** une dette a le sens "je dois", **When** elle est affichee dans la liste, **Then** le montant est affiche en rouge avec le prefixe "-"
4. **Given** une dette a le sens "on me doit", **When** elle est affichee dans la liste, **Then** le montant est affiche en vert avec le prefixe "+"

---

### User Story 2 - Filtrer les dettes par statut (Priority: P2)

L'utilisateur filtre les dettes par statut de remboursement : toutes, en cours ou remboursees. Le filtre par statut interroge l'API avec le parametre de requete correspondant pour ne recuperer que les dettes pertinentes.

**Why this priority**: Permet a l'utilisateur de se concentrer sur les dettes actives ou de retrouver les dettes deja remboursees. C'est le filtre principal qui modifie les donnees chargees depuis le serveur.

**Independent Test**: Peut etre teste en cliquant sur chaque option de filtre statut et en verifiant que seules les dettes correspondantes sont affichees.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'ecran des dettes, **When** il selectionne le filtre "Tous", **Then** toutes les dettes (en cours et remboursees) sont affichees
2. **Given** l'utilisateur est sur l'ecran des dettes, **When** il selectionne le filtre "En cours", **Then** seules les dettes non remboursees sont affichees
3. **Given** l'utilisateur est sur l'ecran des dettes, **When** il selectionne le filtre "Rembourse", **Then** seules les dettes remboursees sont affichees
4. **Given** le filtre statut est actif et aucune dette ne correspond, **When** la liste est vide, **Then** le message "Aucune dette" est affiche

---

### User Story 3 - Filtrer les dettes par sens (Priority: P2)

L'utilisateur filtre les dettes par sens : toutes, "je dois" ou "on me doit". Ce filtrage s'effectue cote client sur les dettes deja chargees, sans nouvel appel API.

**Why this priority**: Permet de separer rapidement les emprunts des prets. Ce filtre est complementaire au filtre statut et fonctionne en combinaison avec celui-ci.

**Independent Test**: Peut etre teste en selectionnant chaque option de filtre sens et en verifiant que seules les dettes du sens choisi sont affichees.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'ecran des dettes avec des dettes des deux sens, **When** il selectionne "Tous", **Then** les dettes des deux sens sont affichees
2. **Given** l'utilisateur est sur l'ecran des dettes, **When** il selectionne "Je dois", **Then** seules les dettes de type "je dois" sont affichees
3. **Given** l'utilisateur est sur l'ecran des dettes, **When** il selectionne "On me doit", **Then** seules les dettes de type "on me doit" sont affichees
4. **Given** le filtre statut est sur "En cours" et le filtre sens est sur "Je dois", **When** les deux filtres sont actifs, **Then** seules les dettes en cours de type "je dois" sont affichees

---

### User Story 4 - Voir le resume financier des dettes (Priority: P3)

L'utilisateur voit un resume en haut de l'ecran avec trois montants : le total "je dois" (en rouge), le total "on me doit" (en vert) et le solde net. Le resume est calcule a partir des dettes actuellement affichees (apres application des filtres).

**Why this priority**: Offre une vue synthetique utile mais non essentielle. La liste seule suffit a consulter les dettes.

**Independent Test**: Peut etre teste en verifiant que les totaux affiches correspondent a la somme des montants des dettes visibles, et que le solde net est correct.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des dettes en cours des deux sens, **When** l'ecran s'affiche, **Then** le total "je dois" est affiche en rouge, le total "on me doit" en vert, et le solde net est la difference
2. **Given** l'utilisateur n'a aucune dette, **When** l'ecran s'affiche, **Then** le resume n'est pas affiche
3. **Given** le solde net est positif (on lui doit plus), **When** l'ecran s'affiche, **Then** le solde est affiche en vert
4. **Given** le solde net est negatif (il doit plus), **When** l'ecran s'affiche, **Then** le solde est affiche en rouge

---

### User Story 5 - Gerer les etats de chargement et d'erreur (Priority: P1)

L'utilisateur voit un indicateur de chargement pendant le chargement des donnees. En cas d'erreur reseau, un message d'erreur avec un bouton "Reessayer" est affiche.

**Why this priority**: Indispensable pour une experience utilisateur correcte. L'absence de feedback de chargement ou d'erreur rend l'interface inutilisable.

**Independent Test**: Peut etre teste en simulant un chargement lent (spinner visible) et une erreur reseau (message d'erreur avec bouton retry).

**Acceptance Scenarios**:

1. **Given** l'ecran des dettes est en cours de chargement, **When** les donnees sont en transit, **Then** un spinner de chargement est affiche
2. **Given** le chargement des dettes echoue, **When** l'erreur survient, **Then** un message "Erreur de chargement" et un bouton "Reessayer" sont affiches
3. **Given** une erreur est affichee, **When** l'utilisateur clique sur "Reessayer", **Then** le chargement est relance

---

### Edge Cases

- Que se passe-t-il lorsque toutes les dettes sont remboursees et le filtre est sur "En cours" ? Le message "Aucune dette" doit s'afficher.
- Que se passe-t-il si une dette a un montant de 0 ? Elle doit s'afficher normalement sans prefixe de signe.
- Que se passe-t-il si la personne a un nom tres long ? Le texte doit etre tronque avec des points de suspension.
- Comment se comporte le resume quand le filtre sens est actif ? Le resume doit refleter uniquement les dettes filtrees visibles.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher la liste de toutes les dettes de l'utilisateur connecte avec : nom de la personne, montant, sens et date
- **FR-002**: Le systeme DOIT differencier visuellement les dettes "je dois" (rouge) et "on me doit" (vert) via des couleurs dediees
- **FR-003**: Le systeme DOIT permettre de filtrer les dettes par statut de remboursement (tous / en cours / rembourse) via un appel API avec le parametre `?rembourse=true/false`
- **FR-004**: Le systeme DOIT permettre de filtrer les dettes par sens (tous / je dois / on me doit) cote client sans nouvel appel API
- **FR-005**: Les filtres statut et sens DOIVENT fonctionner en combinaison
- **FR-006**: Le systeme DOIT afficher un resume avec le total "je dois", le total "on me doit" et le solde net
- **FR-007**: Le resume DOIT utiliser les couleurs semantiques : rouge pour "je dois", vert pour "on me doit"
- **FR-008**: Le solde net DOIT etre colore en vert s'il est positif (on me doit plus) et en rouge s'il est negatif (je dois plus)
- **FR-009**: Le systeme DOIT afficher un spinner pendant le chargement des donnees
- **FR-010**: Le systeme DOIT afficher un message d'erreur avec un bouton "Reessayer" en cas d'echec de chargement
- **FR-011**: Le systeme DOIT afficher le message "Aucune dette" lorsque la liste filtree est vide
- **FR-012**: Chaque dette DOIT afficher une icone coloree selon le sens
- **FR-013**: Les montants DOIVENT etre formates selon les conventions locales (EUR, format francais)
- **FR-014**: Les dates DOIVENT etre affichees en format relatif (aujourd'hui, hier, il y a X jours, etc.)
- **FR-015**: Le resume NE DOIT PAS s'afficher lorsqu'il n'y a aucune dette chargee

### Key Entities

- **Debt** : Represente une dette entre l'utilisateur et une personne tierce. Attributs principaux : personne (nom), montant, sens (je dois / on me doit), date, statut de remboursement, categorie optionnelle.
- **DebtType** : Enumeration du sens de la dette : "je dois" (l'utilisateur doit de l'argent) ou "on me doit" (quelqu'un doit de l'argent a l'utilisateur).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter sa liste de dettes en moins de 2 secondes apres navigation vers l'ecran
- **SC-002**: L'utilisateur peut filtrer les dettes par statut et par sens en un seul clic par filtre
- **SC-003**: Le resume financier (total je dois, total on me doit, solde net) est visible sans defilement sur un ecran mobile standard
- **SC-004**: L'utilisateur peut identifier instantanement le sens d'une dette grace a la differenciation visuelle par couleur
- **SC-005**: En cas d'erreur, l'utilisateur peut relancer le chargement en un seul clic sur "Reessayer"
- **SC-006**: L'ecran gere correctement les trois etats (chargement, erreur, vide) sans comportement inattendu

## Assumptions

- L'API backend pour les dettes est deja fonctionnelle et supporte le parametre `?rembourse=true/false`
- Le composant `ListItem` est deja disponible et prend en charge les inputs necessaires (icon, title, subtitle, value, rightSubtitle, valueClass)
- Les pipes `AmountPipe` et `RelativeDatePipe` sont deja implementes et fonctionnels
- Les tokens CSS `--color-debt-owe` et `--color-debt-owed` sont definis dans les themes light et dark
- Le `DebtService` avec la methode `getAll(rembourse?: boolean)` est deja implemente
- Le resume est calcule cote client a partir des dettes chargees (pas d'endpoint API dedie pour le resume)
- Le filtre statut par defaut est "Tous" au chargement de l'ecran
- Le filtre sens par defaut est "Tous" au chargement de l'ecran
