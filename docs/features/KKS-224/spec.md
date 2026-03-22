# Feature Specification: Mettre a jour DESIGN.md avec les patterns du dashboard redesigne

**Feature Branch**: `sopequenotech/kks-224-mettre-a-jour-designmd-avec-les-patterns-du-dashboard`
**Created**: 2026-03-22
**Status**: Draft
**Issue Linear**: [KKS-224](https://linear.app/kksdev/issue/KKS-224/mettre-a-jour-designmd-avec-les-patterns-du-dashboard-redesigne)
**Priority**: High
**Labels**: Feature
**Milestone**: Refonte UX pages interieures (Angular)

## User Scenarios & Testing

### User Story 1 - Documenter les nouveaux tokens de design (Priority: P1)

En tant que developpeur frontend, je veux que les nouveaux tokens introduits par le dashboard redesigne (hero gradient, glassmorphism, variation badges, etc.) soient documentes dans DESIGN.md afin de pouvoir les reutiliser de maniere coherente dans les prochaines pages.

**Why this priority**: Sans documentation des tokens, chaque developpeur risque de reimplementer les memes patterns differemment. C'est le prerequis pour toutes les issues suivantes du milestone "Refonte UX pages interieures".

**Independent Test**: Verifier que la section "Tokens existants a utiliser" de DESIGN.md contient tous les nouveaux tokens (`--hero-gradient`, `--glass-bg`, `--glass-border`, `--glass-blur`, `--page-gradient-color`, `--font-size-hero`, `--shadow-hero-text`, `--bg-success`, `--text-success`, `--bg-error`, `--text-error`) et que chaque token a une description claire de son usage.

**Acceptance Scenarios**:

1. **Given** le fichier DESIGN.md existant, **When** je consulte la section "Tokens existants a utiliser", **Then** je trouve tous les nouveaux tokens documentes avec leurs noms, valeurs et contextes d'utilisation.
2. **Given** un nouveau token documente (ex: `--glass-bg`), **When** je cherche ce token dans le codebase Angular, **Then** il correspond a une variable CSS definie dans les fichiers de tokens.

---

### User Story 2 - Documenter les nouveaux composants de reference (Priority: P1)

En tant que developpeur frontend, je veux que les nouveaux composants visuels (Hero Card, Glassmorphism Summary Cards, Variation Badges, Radial gradient fond de page, Section headers) soient documentes dans DESIGN.md avec leurs specifications (dimensions, radius, shadows, padding, usage).

**Why this priority**: Ces composants sont les patterns de reference pour la refonte des pages interieures. Sans documentation, les prochaines issues ne pourront pas garantir la coherence visuelle.

**Independent Test**: Verifier que chaque nouveau composant a une section dediee dans DESIGN.md avec : description, proprietes CSS, contexte d'utilisation, et un exemple visuel textuel (structure HTML simplifiee ou description de layout).

**Acceptance Scenarios**:

1. **Given** DESIGN.md mis a jour, **When** je lis la section "Hero Card", **Then** je trouve les specs completes : dimensions, gradient, typographie hero, ombre texte, padding, et le contexte d'usage (dashboard patrimoine).
2. **Given** DESIGN.md mis a jour, **When** je lis la section "Glassmorphism Summary Cards", **Then** je trouve les proprietes glass (blur, bg, border), le radius, l'ombre, et la distinction avec les cards solides.
3. **Given** DESIGN.md mis a jour, **When** je lis la section "Variation Badges", **Then** je trouve le format pill, les couleurs (succes/erreur), la taille, et le contexte d'usage (comparaison temporelle uniquement).

---

### User Story 3 - Formaliser les regles "quand utiliser quoi" (Priority: P1)

En tant que developpeur frontend, je veux des regles explicites pour choisir entre les differents patterns visuels (glass vs solide, items separes vs bloc avec dividers, etc.) afin d'avoir une prise de decision rapide et coherente.

**Why this priority**: Les regles de decision sont aussi importantes que les specs techniques. Sans elles, deux developpeurs pourraient faire des choix differents pour des cas similaires.

**Independent Test**: Verifier qu'une section "Regles de design" ou equivalent contient un tableau de decision avec les 7 patterns identifies dans l'issue Linear.

**Acceptance Scenarios**:

1. **Given** DESIGN.md mis a jour, **When** je cherche quand utiliser le glassmorphism, **Then** je trouve la regle : "Dashboard uniquement (ecran d'apercu court)".
2. **Given** DESIGN.md mis a jour, **When** je cherche quand utiliser des items separes vs bloc avec dividers, **Then** je trouve la regle : "Items separes pour listes courtes (<=7), bloc unique + dividers pour listes longues".
3. **Given** DESIGN.md mis a jour, **When** je cherche quand utiliser les variation badges, **Then** je trouve la regle : "Donnees avec comparaison temporelle uniquement".

---

### User Story 4 - Mettre a jour la section tokens existants (Priority: P2)

En tant que developpeur frontend, je veux que la section "Tokens existants a utiliser" existante soit mise a jour (pas seulement ajoutee) pour integrer les nouveaux tokens de maniere organisee et coherente avec la structure existante.

**Why this priority**: Eviter une section tokens fragmentee entre "anciens" et "nouveaux". L'integration dans la structure existante facilite la consultation.

**Independent Test**: Verifier que la section tokens n'a pas de doublons, que les nouveaux tokens sont integres dans les categories existantes (Couleurs, Shadows, Typography) ou dans une nouvelle categorie si necessaire, et que l'organisation est logique.

**Acceptance Scenarios**:

1. **Given** la section tokens mise a jour, **When** je parcours les categories, **Then** les tokens de glassmorphism sont dans une sous-section "Glass / Effects" clairement identifiee.
2. **Given** la section tokens mise a jour, **When** je cherche `--bg-success` et `--text-success`, **Then** ils sont dans la categorie "Couleurs" aux cotes des tokens existants (income, expense, debt).

---

### Edge Cases

- Que se passe-t-il si certains tokens du dashboard n'existent pas encore dans les fichiers SCSS ? **Resolu** : les 11 tokens existent deja dans `_light.scss` et `_dark.scss`. Le scope est uniquement documentation, pas creation de tokens.
- Comment gerer les tokens specifiques au theme dark vs light pour le glassmorphism ? **Resolu** : les tokens sont deja theme-aware (ex: `--glass-blur: 0px` en light, `20px` en dark ; `--glass-bg: var(--surface-raised)` en light, `rgba(31,41,55,0.6)` en dark). DESIGN.md doit documenter les deux variantes pour les tokens ayant des valeurs significativement differentes.

## Requirements

### Functional Requirements

- **FR-001**: DESIGN.md DOIT documenter tous les nouveaux tokens introduits par le dashboard redesigne : `--hero-gradient`, `--glass-bg`, `--glass-border`, `--glass-blur`, `--page-gradient-color`, `--font-size-hero`, `--shadow-hero-text`, `--bg-success`, `--text-success`, `--bg-error`, `--text-error`.
- **FR-002**: DESIGN.md DOIT contenir une section dediee pour chaque nouveau composant de reference : Hero Card, Glassmorphism Summary Cards, Variation Badges, Radial gradient fond de page, Section headers (titre + lien).
- **FR-003**: Chaque composant documente DOIT inclure : description, proprietes CSS utilisees, contexte d'utilisation, et dimensions/spacing.
- **FR-004**: DESIGN.md DOIT contenir un tableau de regles de decision "quand utiliser quoi" couvrant les 7 patterns identifies : glassmorphism cards, surface solide + dots, items separes, bloc unique + dividers, radial gradient fond, variation badges, press feedback `scale(0.97)`.
- **FR-005**: La section "Tokens existants a utiliser" DOIT etre mise a jour pour integrer les nouveaux tokens de maniere coherente avec la structure existante.
- **FR-006**: DESIGN.md DOIT documenter le pattern press feedback `scale(0.97)` applicable a toutes les cards interactives.

### Non-Functional Requirements

- **NFR-001**: Le document DOIT rester lisible et navigable — pas de section de plus de 30 lignes sans sous-titre.
- **NFR-002**: Les noms de tokens DOIVENT correspondre exactement aux variables CSS definies dans le code. **Verifie** : les 11 tokens sont presents dans `app/src/styles/themes/_light.scss` (L40-69) et `_dark.scss` (L39-71) avec les noms exacts de l'issue.
- **NFR-003**: Le document DOIT rester un fichier unique (`app/DESIGN.md`) sans fragmentation.

### Key Entities

- **Design Token** : Variable CSS nommee (`--token-name`) avec valeur, description et contexte d'utilisation. Categorie : couleurs, typographie, spacing, radius, ombres, effets.
- **Composant de reference** : Pattern UI documente avec ses proprietes visuelles, son usage recommande et ses contraintes.
- **Regle de design** : Decision binaire (quand utiliser pattern A vs pattern B) avec critere explicite et exemples.

### Assumptions

- **A-001**: Les tokens listes dans l'issue Linear (`--hero-gradient`, `--glass-bg`, etc.) existent deja dans le code SCSS du dashboard redesigne. **Impact si faux** : il faudra creer les variables CSS en plus de la documentation, ce qui change le scope de l'issue.
- **A-002**: Le fichier `app/DESIGN.md` est la seule source de verite pour les decisions de design Angular (pas de fichier Figma ou autre outil). **Impact si faux** : la documentation pourrait diverger de la source primaire.
- **A-003**: Les regles de design s'appliquent uniquement a l'app Angular (`app/`) et non a l'app Flutter (`flutter/`). **Impact si faux** : il faudrait aussi mettre a jour les constantes Flutter. **Confirme** : le milestone est "Refonte UX pages interieures (Angular)", l'issue ne mentionne que `app/DESIGN.md`. Scope = Angular uniquement.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Tous les 11 nouveaux tokens sont documentes dans la section "Tokens existants a utiliser" avec nom, description et contexte d'usage.
- **SC-002**: Les 5 nouveaux composants de reference (Hero Card, Glassmorphism Summary Cards, Variation Badges, Radial gradient, Section headers) ont chacun une section dediee avec specs completes.
- **SC-003**: Le tableau de regles de decision contient les 7 patterns avec critere d'usage explicite.
- **SC-004**: La section "Tokens existants a utiliser" existante integre les nouveaux tokens sans doublons ni rupture de structure.
- **SC-005**: Un developpeur peut, en lisant uniquement DESIGN.md, implementer un nouvel ecran en respectant tous les patterns du dashboard redesigne sans consulter le code source du dashboard.
