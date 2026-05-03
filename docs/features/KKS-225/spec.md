# Feature Specification: Alignement design des pages Transactions, Abonnements et Dettes

**Feature Branch**: `sopequenotech/kks-225-alignement-design-des-pages-transactions-abonnements-et`
**Created**: 2026-03-22
**Status**: Draft
**Issue Linear**: [KKS-225](https://linear.app/kksdev/issue/KKS-225/alignement-design-des-pages-transactions-abonnements-et-dettes)
**Priority**: High
**Labels**: Feature
**Milestone**: Refonte UX pages interieures (Angular)
**Depends on**: KKS-224 (DESIGN.md documente les patterns de reference)

## User Scenarios & Testing

### User Story 1 - Harmoniser la typographie et le press feedback des summary cards (Priority: P1)

En tant qu'utilisateur, je veux que les summary cards des pages Transactions, Abonnements et Dettes aient la meme typographie et le meme press feedback que le dashboard, afin de ressentir une continuite visuelle en naviguant.

**Why this priority**: La typographie et le feedback tactile sont les premiers elements perceptibles par l'utilisateur. C'est le changement qui apporte le plus de coherence visuelle avec le moins de risque.

**Independent Test**: Ouvrir chaque page (Transactions, Abonnements, Dettes), verifier que les montants sont en `font-size-xl` + `font-weight-bold`, les labels en `font-weight-semibold`, et que le press feedback `scale(0.97)` est actif au toucher sur chaque summary card.

**Acceptance Scenarios**:

1. **Given** la page Transactions, **When** je regarde les summary cards, **Then** les montants sont en `font-size-xl` + `font-weight-bold` et les labels en `font-weight-semibold`.
2. **Given** la page Abonnements, **When** je regarde la summary card "Total mensuel", **Then** le montant est en `font-size-xl` + `font-weight-bold` (au lieu de `font-size-2xl`).
3. **Given** n'importe quelle page avec summary cards, **When** j'appuie sur une summary card, **Then** la card se reduit a `scale(0.97)` avec une transition `duration-fast`, puis revient a sa taille normale au relachement.

---

### User Story 2 - Ajouter les dots colores sur les summary cards (Priority: P1)

En tant qu'utilisateur, je veux voir un dot colore (vert pour recettes/prets, rouge pour depenses/emprunts) en haut de chaque summary card sur les pages Transactions et Dettes, afin d'identifier instantanement le type de donnee sans lire le label.

**Why this priority**: Les dots colores sont le marqueur visuel le plus distinctif du nouveau design. Ils renforcent la lisibilite et la coherence avec le dashboard.

**Independent Test**: Ouvrir les pages Transactions et Dettes, verifier la presence d'un dot 8px colore en haut de chaque summary card (sauf sur Abonnements ou il n'y a pas de distinction income/expense).

**Acceptance Scenarios**:

1. **Given** la page Transactions, **When** je regarde la summary card "Recettes", **Then** je vois un dot vert (`--color-income`) de 8px en haut de la card.
2. **Given** la page Transactions, **When** je regarde la summary card "Depenses", **Then** je vois un dot rouge (`--color-expense`) de 8px.
3. **Given** la page Transactions, **When** je regarde la summary card "Solde", **Then** je vois un dot dont la couleur depend du signe du solde (vert si positif, rouge si negatif, `--text-secondary` gris si exactement zero). **Resolu** : un dot neutre gris pour zero est coherent avec les variation badges du dashboard qui ont une variante `--neutral`.
4. **Given** la page Dettes, **When** je regarde les summary cards, **Then** les prets ont un dot `--color-debt-owed` et les emprunts un dot `--color-debt-owe`.
5. **Given** la page Abonnements, **When** je regarde les summary cards, **Then** il n'y a pas de dot colore.

---

### User Story 3 - Ajouter le radial gradient en fond de page (Priority: P1)

En tant qu'utilisateur, je veux voir le meme fond degrade radial subtil que le dashboard sur les pages Transactions, Abonnements et Dettes, afin de ressentir une atmosphere visuelle coherente sur toute l'application.

**Why this priority**: Le gradient est un element atmospherique qui unifie l'experience. C'est une modification CSS pure sans impact sur le HTML ni risque de regression fonctionnelle.

**Independent Test**: Ouvrir chaque page et verifier visuellement que le gradient radial amber est visible en haut de page (subtil, 40vh de hauteur), en light et en dark mode.

**Acceptance Scenarios**:

1. **Given** la page Transactions, **When** je charge la page, **Then** je vois un radial gradient subtil (`--page-gradient-color`) en haut, couvrant 40vh de hauteur, fixe au scroll.
2. **Given** la page Abonnements en dark mode, **When** je charge la page, **Then** le gradient est visible avec la couleur dark (`rgba(251, 191, 36, 0.08)`).
3. **Given** n'importe quelle page avec le gradient, **When** je scroll vers le bas, **Then** le gradient reste fixe en haut (position fixed).

---

### User Story 4 - Verifier l'absence de regression sur les listes (Priority: P2)

En tant qu'utilisateur, je veux que les listes de transactions, abonnements et dettes gardent exactement leur apparence actuelle (bloc unique + dividers), sans que l'alignement design n'introduise de changement non voulu.

**Why this priority**: Les listes ne doivent PAS changer (decision explicite dans l'issue : listes longues = bloc unique + dividers). Cette US est une verification, pas une implementation.

**Independent Test**: Comparer visuellement les listes avant/apres le changement. Verifier que le style des items, les dividers, les ombres et le border-radius sont identiques.

**Acceptance Scenarios**:

1. **Given** la page Transactions avec des transactions, **When** je regarde la liste, **Then** les items sont dans un bloc unique avec dividers (pas d'items separes avec shadow individuelle).
2. **Given** la page Dettes avec des dettes, **When** je regarde la liste, **Then** le style est identique a l'existant.

---

### Edge Cases

- Que se passe-t-il si une summary card a un montant tres long (ex: 1 000 000,00 EUR) avec `font-size-xl` ? Risque de debordement sur mobile.
- Comment se comporte le press feedback sur les summary cards non cliquables (ex: Solde qui n'a pas de navigation) ? **Resolu** : les 3 pages utilisent des `<div>` pour les summary cards (aucune n'est cliquable). L'issue demande explicitement le press feedback sur toutes les summary cards. Le feedback tactile s'applique meme sur des elements non navigables — c'est un retour sensoriel, pas un indicateur de navigation.
- Le gradient `:host::before` peut-il entrer en conflit avec d'autres pseudo-elements deja utilises sur `:host` ?

## Requirements

### Functional Requirements

- **FR-001**: Les montants des summary cards DOIVENT utiliser `--font-size-xl` + `--font-weight-bold` sur les 3 pages.
- **FR-002**: Les labels des summary cards DOIVENT utiliser `--font-weight-semibold` sur les 3 pages.
- **FR-003**: Toutes les summary cards DOIVENT avoir un press feedback `scale(0.97)` sur `:active` avec transition `duration-fast`.
- **FR-004**: Les summary cards de la page Transactions DOIVENT avoir un dot colore 8px (`--color-income` pour Recettes, `--color-expense` pour Depenses, conditionnel pour Solde).
- **FR-005**: Les summary cards de la page Dettes DOIVENT avoir un dot colore 8px (`--color-debt-owed` pour Prets, `--color-debt-owe` pour Emprunts, conditionnel pour Solde net).
- **FR-006**: Les summary cards de la page Abonnements NE DOIVENT PAS avoir de dot colore.
- **FR-007**: Les 3 pages DOIVENT avoir un radial gradient en fond via `:host::before` avec `--page-gradient-color`, `40vh`, `position: fixed`.
- **FR-008**: Les listes (transactions, abonnements, dettes) NE DOIVENT PAS etre modifiees (structure, style, comportement).

### Non-Functional Requirements

- **NFR-001**: Les modifications DOIVENT utiliser exclusivement les tokens CSS definis dans `app/DESIGN.md` et les fichiers de themes.
- **NFR-002**: Le press feedback DOIT etre fluide (pas de jank) sur mobile (60fps).
- **NFR-003**: Le radial gradient NE DOIT PAS impacter les performances de scroll.
- **NFR-004**: Les modifications DOIVENT fonctionner en light et dark mode. **Verifie** : les 4 tokens business ont des variantes dark adaptees (`--color-income`: `#4ade80` en dark, `--color-expense`: `#f87171` en dark, idem pour debt-owe/debt-owed).

### Key Entities

- **Summary Card** : Composant visuel affichant un montant agrege avec label, present en haut des pages interieures. Proprietes : montant, label, dot (optionnel), couleur dot, press feedback.
- **Page Layout** : Structure `:host` des pages interieures avec gradient radial en pseudo-element `::before`.

### Assumptions

- **A-001**: Les summary cards des 3 pages utilisent une structure HTML similaire (classe `.summary__card` ou equivalent). **Impact si faux** : il faudra adapter le HTML de chaque page individuellement au lieu de partager un pattern CSS commun.
- **A-002**: Le pseudo-element `::before` sur `:host` n'est pas deja utilise par les 3 pages. **Impact si faux** : conflit CSS, il faudra utiliser un autre pseudo-element ou un element HTML dedie.
- **A-003**: Les tokens `--color-income`, `--color-expense`, `--color-debt-owe`, `--color-debt-owed` existent deja et ont des variantes dark. **Impact si faux** : il faudra creer ces tokens.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Les montants des summary cards sur les 3 pages utilisent `font-size-xl` + `font-weight-bold` (verification par inspection CSS).
- **SC-002**: Les labels des summary cards utilisent `font-weight-semibold` sur les 3 pages.
- **SC-003**: Le press feedback `scale(0.97)` est visible sur toutes les summary cards au toucher/clic.
- **SC-004**: Les dots colores 8px sont presents sur Transactions (3 cards) et Dettes (3 cards), absents sur Abonnements.
- **SC-005**: Le radial gradient est visible en haut des 3 pages, fixe au scroll, en light et dark mode.
- **SC-006**: Les listes de chaque page sont visuellement identiques avant et apres la modification (test de non-regression visuel).
