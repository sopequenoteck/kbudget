# Research: Formulaire Subscription (modal)

**Feature**: 010-subscription-form | **Date**: 2026-02-09

## Resume

Aucun unknown technique majeur identifie. La feature utilise exclusivement des patterns et dependances deja en place dans le projet (identiques a KKS-51). Les recherches ci-dessous documentent les decisions de design pour les elements specifiques a ce formulaire.

## R1 — Toggle segmente pour la frequence

**Decision**: Implementer un toggle segmente custom en CSS/HTML pur (2 boutons `<button>` dans un conteneur flex) pilote par le `FormControl` de la frequence. Reutiliser le meme pattern CSS que le toggle type du formulaire Transaction (KKS-51).

**Rationale**: Le toggle segmente est deja implemente dans KKS-51 pour DEPENSE/RECETTE. Meme pattern, memes styles. Coherent avec YAGNI — pas de composant partage tant que non necessaire (3eme usage).

**Alternatives considered**:
- `<select>` natif : moins intuitif sur mobile pour seulement 2 options
- Composant toggle partage : premature, seulement 2 usages (KKS-51 + KKS-52)

## R2 — Champ "actif" (case a cocher)

**Decision**: Utiliser un `<input type="checkbox">` natif style via les design tokens du projet, lie au `FormControl` `actif` du formulaire reactif. Coche par defaut (true).

**Rationale**: Le checkbox natif est le meilleur choix pour un booleen. Pas besoin de composant custom. Le champ n'est pas obligatoire cote validation (pas de `Validators.required`) car la valeur par defaut (true) est toujours valide.

**Alternatives considered**:
- Toggle switch : plus visuel mais necessite du CSS supplementaire sans benefice UX majeur
- Select (Actif/Inactif) : over-engineering pour un booleen

## R3 — Chargement des categories dans le formulaire

**Decision**: Injecter `CategoryService` dans le composant et charger les categories via `toSignal(categoryService.getAll())` au moment de l'initialisation du composant. Meme pattern que KKS-51.

**Rationale**: Pattern coherent avec l'approche signals-first du projet. Identique au formulaire Transaction.

**Alternatives considered**: Memes que KKS-51 — toutes rejetees pour les memes raisons.

## R4 — Gestion du mode creation vs edition

**Decision**: Utiliser un `input()` optionnel `subscription` de type `Subscription | null`. Si `null` → mode creation (valeurs par defaut). Si objet → mode edition (pre-remplissage). Meme pattern que KKS-51.

**Rationale**: Pattern simple et explicite, deja valide dans KKS-51.

**Alternatives considered**: Memes que KKS-51 — toutes rejetees pour les memes raisons.

## R5 — Format de date pour l'input natif

**Decision**: Utiliser `<input type="date">` natif HTML5 avec le format `YYYY-MM-DD`. Meme pattern que KKS-51.

**Rationale**: L'input date natif est le meilleur choix mobile-first. Le format est identique au format ISO attendu par le backend (LocalDate).

**Alternatives considered**: Memes que KKS-51.
