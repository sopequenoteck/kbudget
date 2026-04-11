# Feature Specification: Recherche & Filtres Transactions

**Feature Branch**: `feature/search-filter-transactions`
**Created**: 2026-04-11
**Status**: Draft
**Input**: User description: "Les icones recherche/filtre sont dans le section header depuis la session 3, mais sans handler. C'est le seul element d'interaction visible qui ne fait rien. Sur la page la plus utilisee de l'app."

## Contexte

La page Transactions est la page la plus utilisee de l'app. Depuis la session 3 de la refonte design, le section header sticky contient deux icones — recherche (phosphorMagnifyingGlass) et filtre (phosphorFunnel) — qui sont purement decoratives : aucun `(click)` handler, aucun state connecte. C'est le seul element d'interaction visible de l'app qui ne fait rien.

### Etat actuel

- **Donnees** : `getAll()` charge toutes les transactions, filtre client-side par mois/annee via `filteredTransactions` computed signal
- **Groupement** : par periode relative (Aujourd'hui, Hier, Cette semaine, Semaine derniere, Plus ancien)
- **Modele Transaction** : `id`, `montant`, `libelle`, `type` (DEPENSE/RECETTE/AJUSTEMENT), `date`, `category` (nom, icone, couleur), `note`, `account` (currency), `transferId`
- **API** : pas d'endpoint de recherche server-side. Le filtrage se fait cote client sur les donnees deja chargees

### Contrainte design

Le vocabulaire visuel est "quiet utility dark-first" (DESIGN-REFONTE.md). Pas de modal, pas de page separee. Les interactions vivent inline dans la page existante, coherentes avec le pattern bottom sheet / inline expand utilise partout ailleurs.

---

## User Scenarios & Testing

### User Story 1 - Recherche textuelle rapide (Priority: P1)

En tant qu'utilisateur, je veux rechercher une transaction par son libelle depuis la page Transactions, afin de retrouver rapidement une depense specifique sans scroller.

**Why this priority** : C'est le besoin primaire — "ou est passe mon paiement chez X ?". La recherche par libelle couvre 80% des cas d'usage de recherche. L'icone est deja visible et non fonctionnelle, ce qui cree une frustration immediate.

**Independent Test** : Taper "loyer" dans le champ de recherche et verifier que seules les transactions contenant "loyer" dans le libelle apparaissent, toutes periodes confondues du mois selectionne.

**Acceptance Scenarios** :

1. **Given** la page Transactions avec des donnees, **When** je tape sur l'icone recherche (loupe), **Then** le titre "Transactions" est remplace par un champ `<input>` de recherche dans le section header (meme emplacement, transition `duration-fast`). L'icone loupe devient une icone X (fermer). Le champ prend toute la largeur disponible a gauche des icones filtre/recurrences. Focus automatique et clavier ouvert.
2. **Given** le champ de recherche ouvert, **When** je tape "loyer", **Then** la liste se filtre en temps reel pour n'afficher que les transactions dont le libelle contient "loyer" (case-insensitive), en conservant le groupement par periode.
3. **Given** le champ de recherche avec du texte, **When** je tape sur le bouton X (clear) ou que j'efface tout le texte, **Then** la liste revient a l'etat non filtre du mois selectionne.
4. **Given** le champ de recherche ouvert, **When** je tape sur l'icone recherche a nouveau ou que j'appuie sur Escape, **Then** le champ se ferme, le titre "Transactions" reapparait, et la liste revient a l'etat non filtre.
5. **Given** le champ de recherche avec "xyz123" (aucun resultat), **When** la recherche ne retourne rien, **Then** l'empty state contextuel s'affiche : icone phosphorMagnifyingGlass + "Aucune transaction trouvee" (pas le CTA "Ajouter une transaction").

---

### User Story 2 - Filtre par type de transaction (Priority: P1)

En tant qu'utilisateur, je veux filtrer les transactions par type (Depenses / Recettes) depuis la page Transactions, afin de voir uniquement mes depenses ou mes recettes du mois.

**Why this priority** : Le filtre par type est le deuxieme besoin le plus frequent apres la recherche. "Combien j'ai depense ce mois-ci et sur quoi ?" necessite de ne voir que les depenses. Le bouton filtre (entonnoir) est deja present et non fonctionnel.

**Independent Test** : Activer le filtre "Depenses" et verifier que seules les transactions de type DEPENSE apparaissent. Desactiver et verifier le retour a la liste complete.

**Acceptance Scenarios** :

1. **Given** la page Transactions, **When** je tape sur l'icone filtre (entonnoir), **Then** un panneau de filtres slide-down sous le section header (fond `surface-default`, `radius-xl` en bas, padding `space-3`, animation `duration-fast`). Contenu : ligne 1 = chips type segmented (Tout / Depenses / Recettes), ligne 2 = chips categories (emoji + nom, scrollable horizontal, triees par frequence), ligne 3 = chips comptes (si multi-comptes). Lien "Reinitialiser" en `text-tertiary` xs visible quand un filtre est actif.
2. **Given** le panneau de filtres ouvert, **When** je selectionne "Depenses", **Then** seules les transactions de type DEPENSE sont affichees, le hero (solde, recettes, depenses) reste inchange (il reflete le mois, pas le filtre), et l'icone filtre montre un indicateur visuel (dot ou couleur) signalant qu'un filtre est actif.
3. **Given** le filtre "Depenses" actif, **When** je selectionne "Recettes", **Then** seules les transactions de type RECETTE sont affichees (les filtres type sont mutuellement exclusifs, ou deselectionnables pour revenir a "Tous").
4. **Given** un ou plusieurs filtres actifs, **When** je tape sur "Reinitialiser" ou que je re-tape sur l'icone filtre, **Then** tous les filtres sont desactives et la liste revient a l'etat complet.

---

### User Story 3 - Filtre par categorie (Priority: P2)

En tant qu'utilisateur, je veux filtrer les transactions par categorie depuis la page Transactions, afin de voir toutes mes depenses d'une categorie specifique (ex: "Alimentation").

**Why this priority** : Le filtre par categorie est utile mais moins frequent que le filtre par type. Il necessite l'affichage des categories disponibles, ce qui ajoute de la complexite UI. Combine avec le filtre type (US2), il permet des requetes comme "mes depenses Alimentation de mars".

**Independent Test** : Activer le filtre categorie "Alimentation" et verifier que seules les transactions de cette categorie apparaissent.

**Acceptance Scenarios** :

1. **Given** le panneau de filtres ouvert, **When** je vois la section categories, **Then** les categories du mois selectionne sont listees sous forme de chips (emoji + nom), triees par nombre de transactions decroissant.
2. **Given** le panneau de filtres, **When** je tape sur la chip "Alimentation", **Then** seules les transactions de categorie "Alimentation" sont affichees. La chip selectionnee est visuellement distinguee (fond primary attenue).
3. **Given** le filtre categorie "Alimentation" actif ET le filtre type "Depenses" actif, **When** je regarde la liste, **Then** seules les depenses de categorie "Alimentation" sont affichees (les filtres se combinent en AND).
4. **Given** un filtre categorie actif, **When** je tape a nouveau sur la chip, **Then** le filtre categorie est desactive.

---

### User Story 4 - Filtre par compte (Priority: P3)

En tant qu'utilisateur, je veux filtrer les transactions par compte bancaire, afin de voir les mouvements d'un compte specifique.

**Why this priority** : Utile pour les utilisateurs multi-comptes (EUR + CFA par exemple), mais moins critique que type et categorie. L'utilisateur principal a 2 comptes (EUR + CFA), donc le filtre est pertinent. La section comptes est masquee automatiquement si l'utilisateur n'a qu'un seul compte (FR-005).

**Independent Test** : Activer le filtre sur un compte specifique et verifier que seules les transactions de ce compte apparaissent.

**Acceptance Scenarios** :

1. **Given** le panneau de filtres ouvert et l'utilisateur ayant 2+ comptes, **When** je vois la section comptes, **Then** les comptes sont listes sous forme de chips (emoji + nom tronque).
2. **Given** le filtre compte "Boursorama" actif, **When** je regarde la liste, **Then** seules les transactions du compte Boursorama sont affichees.
3. **Given** l'utilisateur ayant un seul compte, **When** j'ouvre le panneau de filtres, **Then** la section comptes n'est pas affichee (filtre inutile).

---

### User Story 5 - Recherche etendue au-dela du libelle (Priority: P3)

En tant qu'utilisateur, je veux que la recherche textuelle trouve aussi dans la categorie et la note, afin de retrouver une transaction dont je me souviens du contexte mais pas du libelle exact.

**Why this priority** : Extension naturelle de l'US1. La note et la categorie sont des informations secondaires mais pertinentes pour la recherche. Implemente comme un elargissement du scope de `filteredTransactions`, sans changement UI.

**Independent Test** : Taper "resto" dans la recherche et verifier qu'une transaction avec la note contenant "resto" apparait meme si son libelle est "CB PAUL".

**Acceptance Scenarios** :

1. **Given** une transaction avec libelle "CB PAUL" et note "resto avec Marie", **When** je recherche "resto", **Then** la transaction apparait dans les resultats.
2. **Given** une transaction categorie "Alimentation", **When** je recherche "aliment", **Then** la transaction apparait dans les resultats.
3. **Given** la recherche "resto" active, **When** je combine avec le filtre type "Depenses", **Then** seules les depenses matchant "resto" sont affichees (recherche + filtres se combinent).

---

### Edge Cases

- **Recherche + changement de mois** : si la recherche est active et l'utilisateur change de mois via les fleches, la recherche doit rester active et se re-appliquer sur le nouveau mois.
- **Filtres + empty state** : si un filtre donne zero resultats, l'empty state contextuel doit indiquer le filtre actif ("Aucune depense en mars 2026") et proposer de reinitialiser les filtres.
- **Categories vides** : les categories sans transaction dans le mois selectionne ne doivent pas apparaitre dans les chips filtre.
- **Recherche avec caracteres speciaux** : la recherche doit etre tolerante (pas de regex cote client, juste `includes()` case-insensitive).
- **Performance** : le filtrage est client-side sur des donnees deja chargees. Avec `getAll()` qui charge toutes les transactions, la recherche est un simple `filter()` sur le signal. Pour un single-user (volume realiste < 2000 transactions), un `computed()` Angular est suffisamment performant (< 1ms). Pas de debounce necessaire.

---

## Requirements

### Functional Requirements

- **FR-001** : Le systeme DOIT afficher un champ de recherche inline dans le section header quand l'utilisateur tape sur l'icone loupe
- **FR-002** : Le systeme DOIT filtrer les transactions en temps reel pendant la saisie (client-side, sur `filteredTransactions`)
- **FR-003** : La recherche DOIT etre case-insensitive et operer sur le libelle (P1), puis sur la categorie et la note (P3)
- **FR-004** : Le systeme DOIT afficher un panneau de filtres inline sous le section header quand l'utilisateur tape sur l'icone entonnoir
- **FR-005** : Le panneau de filtres DOIT proposer : filtre par type (Depenses/Recettes/Tous), filtre par categorie (chips), filtre par compte (chips, masque si mono-compte)
- **FR-006** : Les filtres DOIVENT se combiner en AND (type AND categorie AND compte AND recherche)
- **FR-007** : L'icone filtre DOIT afficher un indicateur visuel (dot) quand un ou plusieurs filtres sont actifs
- **FR-008** : Le systeme DOIT conserver l'etat des filtres et de la recherche lors du changement de mois
- **FR-009** : Le systeme DOIT afficher un empty state contextuel quand la combinaison recherche + filtres donne zero resultats
- **FR-010** : Le systeme NE DOIT PAS modifier le hero (solde, recettes, depenses) — le hero reflete le mois complet, pas les filtres actifs. Justification : le hero repond a "quel est mon solde ce mois-ci ?", les filtres repondent a "quelles transactions correspondent a X ?". Deux questions distinctes. Coherent avec le pattern des autres pages (hero dettes = solde net global, pas un sous-ensemble filtre).

### Non-Functional Requirements

- **NFR-001** : Le filtrage DOIT etre instantane (< 16ms pour rester dans le frame budget a 60fps) — c'est du client-side sur des donnees en memoire
- **NFR-002** : L'animation d'ouverture/fermeture du champ recherche et du panneau filtres DOIT utiliser `--duration-fast` (150ms) pour rester coherent avec les transitions de l'app
- **NFR-003** : Les composants DOIVENT utiliser les design tokens existants (`--surface-default`, `--border-default`, `--text-secondary`, `--color-primary`, `--radius-xl`, etc.)
- **NFR-004** : L'implementation DOIT etre Angular signals-first (`signal()`, `computed()`) sans `subscribe()` manuel
- **NFR-005** : Les composants DOIVENT etre `standalone` avec `ChangeDetectionStrategy.OnPush`

### Key Entities

- **Transaction** (existante) : entite filtree. Champs pertinents : `libelle`, `type`, `category.nom`, `note`, `account`
- **FilterState** (nouveau, local) : etat des filtres actifs. Pas de persistence — reset a la navigation. Champs : `searchQuery: string`, `typeFilter: TransactionType | null`, `categoryFilter: string | null`, `accountFilter: string | null`

### Assumptions

- **A-001** : Le filtrage reste integralement client-side. Le `getAll()` charge deja toutes les transactions — pas besoin d'endpoint server-side. **Si faux** : il faudrait un endpoint `GET /transactions/search?q=...&type=...&categoryId=...` et un refactoring du chargement de donnees.
- **A-002** : Le volume de transactions par utilisateur est raisonnable (< 5000 pour un single-user). **Si faux** : pagination server-side necessaire, impactant toute l'architecture de la page.
- **A-003** : Le panneau filtres vit inline dans la page (pas de bottom sheet ni de modal). **Si faux** : necessite un composant modal supplementaire, contredisant la direction "quiet utility" et le pattern inline expand.

---

## Success Criteria

### Measurable Outcomes

- **SC-001** : L'utilisateur peut retrouver une transaction par recherche textuelle en < 3 secondes (ouvrir recherche, taper, trouver)
- **SC-002** : L'utilisateur peut filtrer par type en 1 interaction (tap filtre + tap type)
- **SC-003** : Les deux icones du section header (loupe, entonnoir) ont un handler fonctionnel — plus aucun element d'interaction inerte dans l'app
- **SC-004** : La combinaison recherche + filtres produit le resultat attendu dans 100% des cas testes (type AND categorie AND compte AND texte)
- **SC-005** : Aucune regression visuelle sur la page Transactions existante (hero, groupement, list rows, empty state standard)
