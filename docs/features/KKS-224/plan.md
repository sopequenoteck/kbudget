# Implementation Plan: Mettre a jour DESIGN.md avec les patterns du dashboard redesigne

**Branch**: `sopequenotech/kks-224-mettre-a-jour-designmd-avec-les-patterns-du-dashboard` | **Date**: 2026-03-22 | **Spec**: [spec.md](spec.md)

## Summary

Mettre a jour le fichier `app/DESIGN.md` pour documenter les nouveaux patterns visuels introduits par le dashboard redesigne : Hero Card, Glassmorphism Summary Cards, Variation Badges, Radial gradient, Section headers, et les 11 nouveaux tokens CSS. Ajouter un tableau de regles de decision "quand utiliser quoi" pour les 7 patterns identifies. Feature purement documentaire — aucun code applicatif modifie.

## Technical Context

**Language/Version**: Markdown (documentation pure)
**Primary Dependencies**: Aucune
**Storage**: N/A
**Testing**: Verification manuelle — correspondance tokens doc vs code SCSS
**Target Platform**: Documentation reference developpeurs Angular
**Project Type**: Documentation
**Constraints**: Un seul fichier (`app/DESIGN.md`), pas de fragmentation

## Constitution Check

| # | Principe | Statut | Commentaire |
|---|----------|--------|-------------|
| I | API-First | N/A | Feature documentation, pas de code API |
| II | Securite par defaut | N/A | Pas de code applicatif |
| III | Simplicite & YAGNI | PASS | Modification minimale d'un fichier existant |
| IV | Mobile-First UX | PASS | Documente les patterns mobiles du dashboard |
| V | Testabilite | N/A | Pas de code testable |
| VI | Observabilite | N/A | Pas de code applicatif |
| VII | Self-Hosted Ready | N/A | Pas d'infra |

Aucune violation. Aucune derogation necessaire.

## Project Structure

### Documentation (this feature)

```text
docs/features/KKS-224/
├── spec.md
├── clarify-log.md
├── review-log.md
├── plan.md              # This file
└── state.json
```

### Source Code (repository root)

```text
app/
└── DESIGN.md            # (M) Seul fichier modifie
```

**Structure Decision**: Un seul fichier modifie. Pas de creation de fichier. Le contenu est ajoute dans les sections existantes de DESIGN.md et de nouvelles sous-sections sont creees dans "Composants de reference".

## Architecture des modifications

### Composant 1 : Nouveaux composants de reference (FR-002, FR-003, FR-006)

**Fichier**: `app/DESIGN.md` (M) — section "Composants de reference"

Ajouter 5 nouvelles sous-sections apres "Month Selector" (L138) :

#### 1.1 Hero Card (Patrimoine)

Specs extraites de `dashboard.scss` L39-76 :
- Background : `var(--hero-gradient)` (gradient 135deg amber → indigo)
- Border-radius : `var(--radius-xl)` (16px)
- Shadow : `var(--shadow-lg)`
- Padding : `var(--space-4)` (16px)
- Label : `font-size-xs` + `font-weight-medium` + `text-secondary` + uppercase + letter-spacing 0.05em
- Montant : `var(--font-size-hero)` (2.25rem/36px) + `font-weight-bold` + `var(--shadow-hero-text)`
- Press feedback : `transform: scale(0.97)` sur `:active` avec transition `var(--duration-fast)`
- Usage : **dashboard uniquement** — affichage patrimoine total

#### 1.2 Glassmorphism Summary Cards

Specs extraites de `dashboard.scss` L139-201 :
- Background : `var(--glass-bg)`
- Border : `1px solid var(--glass-border)`
- Backdrop-filter : `blur(var(--glass-blur))` (avec `@supports`)
- Border-radius : `var(--radius-xl)` (16px)
- Shadow : `none` (pas d'ombre, le glass suffit)
- Padding : `var(--space-4)` (16px)
- Label : `font-size-xs` + `font-weight-semibold` + `text-secondary` + uppercase
- Montant : `font-size-xl` + `font-weight-bold`
- Dot colore : 8x8px cercle (`--color-income` ou `--color-expense`)
- Press feedback : `scale(0.97)` sur `:active`
- Comportement dark/light : en light le glass est opaque (`--glass-blur: 0px`), en dark le vrai glassmorphism est actif (`--glass-blur: 20px`, bg translucide)
- Usage : **dashboard uniquement** — cartes recettes/depenses

#### 1.3 Variation Badges (Pills)

Specs extraites de `dashboard.scss` L85-108 :
- Display : `inline-flex`, `align-items: center`
- Padding : `var(--space-1)` vertical, `var(--space-2)` horizontal
- Border-radius : `var(--radius-round)` (pill)
- Font : `font-size-xs` + `font-weight-medium`
- Variantes :
  - Positive : `background: var(--bg-success)`, `color: var(--text-success)`
  - Negative : `background: var(--bg-error)`, `color: var(--text-error)`
  - Neutral : `background: var(--bg-tertiary)`, `color: var(--text-secondary)`
- Usage : **donnees avec comparaison temporelle uniquement** (ex: variation mois precedent)

#### 1.4 Radial Gradient (Fond de page)

Specs extraites de `dashboard.scss` L8-18 :
- Pseudo-element `::before` sur `:host`
- Position : `fixed`, top 0, pleine largeur, hauteur `40vh`
- Gradient : `radial-gradient(ellipse at top center, var(--page-gradient-color) 0%, transparent 70%)`
- `pointer-events: none`, `z-index: -1`
- Usage : **toutes les pages** — ambiance subtile et coherente

#### 1.5 Section Headers (Titre + Lien)

Specs extraites de `dashboard.scss` L209-237 :
- Layout : `flex`, `justify-content: space-between`, `align-items: center`
- Titre : `font-size-lg` + `font-weight-semibold` + `text-primary`
- Lien : `font-size-sm` + `font-weight-medium` + `color-primary`, underline on hover
- Usage : en-tete de chaque section du dashboard et des pages interieures

### Composant 2 : Tableau de regles de decision (FR-004, FR-006)

**Fichier**: `app/DESIGN.md` (M) — nouvelle section "Regles de design" apres "Composants de reference"

Tableau avec les 7 patterns :

| Pattern | Usage | Critere |
|---------|-------|---------|
| Glassmorphism cards | Dashboard (apercu court) | Ecran d'apercu avec peu d'items |
| Surface solide + dots colores | Pages interieures (listes longues) | Listes de travail, ecrans principaux |
| Items separes (radius + shadow) | Listes courtes (<=7 items) | Dashboard, apercu |
| Bloc unique + dividers | Listes longues (transactions, abonnements) | Plus de 7 items, scroll attendu |
| Radial gradient fond | Toutes les pages | Ambiance, coherence atmospherique |
| Variation badges | Comparaison temporelle | Donnees avec delta mois precedent |
| Press feedback `scale(0.97)` | Toutes cards interactives | Cards cliquables/navigables |

### Composant 3 : Mise a jour section tokens (FR-001, FR-005)

**Fichier**: `app/DESIGN.md` (M) — section "Tokens existants a utiliser"

Modifications :
1. Ajouter dans **Couleurs** : `--bg-success`, `--text-success`, `--bg-error`, `--text-error`
2. Creer sous-section **Glass / Effects** : `--glass-bg`, `--glass-border`, `--glass-blur`, `--hero-gradient`, `--page-gradient-color`
3. Ajouter dans **Typography** : `--font-size-hero`
4. Ajouter dans **Shadows** : `--shadow-hero-text`
5. Documenter les variantes dark/light significatives pour les tokens glass (tableau)

### Mapping FR → Composants

| FR | Composant(s) |
|----|-------------|
| FR-001 | Composant 3 (tokens) |
| FR-002 | Composant 1 (5 composants de reference) |
| FR-003 | Composant 1 (specs incluses dans chaque composant) |
| FR-004 | Composant 2 (tableau de regles) |
| FR-005 | Composant 3 (integration tokens existants) |
| FR-006 | Composants 1+2 (documente dans Hero Card, Glass Cards, et regles) |

## Risques

| Risque | Impact | Probabilite | Mitigation |
|--------|--------|-------------|------------|
| Desynchro future doc/code | Moyen | Moyenne | Le skill `design-coherence` et le hook `frontend-design-review` verifient la coherence |
| DESIGN.md devient trop long | Bas | Basse | NFR-001 impose des sous-titres toutes les 30 lignes. Structure en sections navigables |

## Hors scope

- Creation ou modification de tokens CSS dans les fichiers SCSS (tokens deja existants)
- Mise a jour des constantes Flutter (`flutter/lib/src/constants/`)
- Modification du code du dashboard
- Creation de composants Angular

## Complexity Tracking

Aucune complexite ajoutee. Modification d'un fichier Markdown existant uniquement.

## Artefacts complementaires

- `research.md` : non requis (feature documentation, pas de recherche technique)
- `data-model.md` : non requis (pas d'entites de donnees a modeliser — les Key Entities de la spec sont des concepts documentaires, pas des entites BDD)
- `quickstart.md` : non requis (pas de setup technique, juste editer DESIGN.md)
