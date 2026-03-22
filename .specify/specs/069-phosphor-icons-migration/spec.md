# Feature Specification: Migration icones systeme vers Phosphor Icons

**Feature Branch**: `069-phosphor-icons-migration`
**Created**: 2026-03-05
**Status**: Draft
**Input**: KKS-162 — Migration icones systeme — Emojis Unicode & Material Icons vers Phosphor Icons
**Linear**: [KKS-162](https://linear.app/kksdev/issue/KKS-162)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Coherence visuelle cross-platform (Priority: P1)

En tant qu'utilisateur, je veux que toutes les icones systeme (navigation, actions, formulaires, parametres) aient le meme style visuel sur l'application web et l'application mobile, afin d'avoir une experience homogene quel que soit le support utilise.

**Why this priority**: La coherence visuelle est la raison d'etre de cette migration. C'est le benefice principal pour l'utilisateur final.

**Independent Test**: Peut etre verifie en comparant visuellement chaque ecran de l'app web et mobile — toutes les icones systeme doivent utiliser le meme jeu d'icones (Phosphor) avec des equivalents visuels coherents.

**Acceptance Scenarios**:

1. **Given** l'application web et mobile sont ouvertes, **When** l'utilisateur navigue sur les memes ecrans (accueil, transactions, parametres), **Then** les icones systeme sont visuellement coherentes entre les deux plateformes
2. **Given** un ecran quelconque de l'application, **When** l'utilisateur observe les icones systeme, **Then** aucune icone n'utilise des emojis Unicode (Angular) ou Material Icons (Flutter)

---

### User Story 2 - Convention de styles par contexte (Priority: P2)

En tant qu'utilisateur, je veux que les icones respectent une convention de style selon leur contexte (navigation, actions, etats actifs), afin que l'interface soit visuellement lisible et les interactions intuitives.

**Why this priority**: Au-dela du changement de librairie, la convention de styles (regular, fill, bold) apporte une hierarchie visuelle qui ameliore l'experience utilisateur.

**Independent Test**: Peut etre verifie en inspectant chaque contexte d'utilisation et en validant que le style Phosphor correspond a la convention definie.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur un ecran avec une barre de navigation, **When** un onglet est selectionne, **Then** l'icone de l'onglet actif utilise le style "fill" et les onglets inactifs utilisent le style "regular"
2. **Given** un bouton d'action (FAB, bouton primaire), **When** l'utilisateur le voit, **Then** l'icone utilise le style "bold"
3. **Given** une liste ou un formulaire, **When** des icones decoratives sont affichees, **Then** elles utilisent le style "regular"

---

### User Story 3 - Nettoyage des anciennes sources d'icones (Priority: P3)

En tant que mainteneur de l'application, je veux que les anciennes sources d'icones systeme (emojis Unicode cote web, Material Icons cote mobile) soient entierement remplacees et nettoyees, afin d'avoir une source unique d'icones et simplifier la maintenance.

**Why this priority**: C'est un benefice technique (coherence du code, maintenance) qui decoule naturellement de la migration. Material Icons cote Flutter est natif et ne peut pas etre "supprime", mais les imports `Icons.*` inutilises doivent etre nettoyes.

**Independent Test**: Peut etre verifie en cherchant toute reference a des emojis systeme hardcodes dans le code Angular et toute reference a `Icons.*` (Material) dans le code Flutter — aucune ne doit subsister pour les icones systeme.

**Acceptance Scenarios**:

1. **Given** le code source Angular, **When** on recherche des emojis hardcodes utilises comme icones systeme (navigation, settings, FAB), **Then** tous sont remplaces par des icones Phosphor
2. **Given** le code source Flutter, **When** on recherche des `Icons.*` pour des icones systeme, **Then** toutes sont remplacees par des equivalents Phosphor

---

### Edge Cases

- Que se passe-t-il si un emoji ou une icone Material n'a pas d'equivalent direct dans Phosphor ? On choisit l'icone Phosphor la plus proche semantiquement, on documente le choix et la justification dans `icon-mapping.md`, et on valide visuellement que l'icone choisie reste comprehensible dans son contexte.
- Que se passe-t-il pour les icones choisies par l'utilisateur (emojis pour categories/comptes) ? Elles ne sont PAS impactees — seules les icones systeme sont migrees.
- Que se passe-t-il pour les images de produits (shop) ? Elles ne sont PAS impactees — ce sont des images uploadees, pas des icones systeme.
- Comment gerer les icones dans les composants partages (common_widgets, lib) ? Elles doivent etre migrees en priorite car elles impactent plusieurs ecrans.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Toutes les icones systeme de l'application web (actuellement des emojis Unicode) et de l'application mobile (actuellement Material Icons) DOIVENT etre remplacees par des icones Phosphor Icons
- **FR-002**: Les icones DOIVENT respecter la convention de styles : "regular" pour l'UI par defaut, "fill" pour l'etat actif (navigation), "bold" pour les actions (boutons, FAB)
- **FR-003**: Les icones DOIVENT respecter la convention de tailles par contexte : navigation 24px, actions/FAB 24px, inline/listes 20px, decoratif 16px
- **FR-004**: Les emojis utilisateur (categories, comptes) NE DOIVENT PAS etre impactes par la migration
- **FR-005**: Les images de produits (shop) NE DOIVENT PAS etre impactees par la migration
- **FR-006**: Un inventaire complet des icones systeme existantes et de leurs equivalents Phosphor DOIT etre realise avant la migration et documente dans un fichier dedie `specs/069-phosphor-icons-migration/icon-mapping.md`
- **FR-007**: Les imports Material Icons inutilises DOIVENT etre nettoyes dans le code Flutter
- **FR-008**: Chaque ecran de chaque plateforme DOIT etre verifie visuellement apres migration (sidebar, header, formulaires, listes, settings, FAB, modals, bottom nav, app bar)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des icones systeme utilisent Phosphor Icons sur les deux plateformes (zero emoji systeme cote Angular, zero `Icons.*` systeme cote Flutter)
- **SC-002**: La convention de styles est respectee sur 100% des contextes (regular/fill/bold selon le contexte)
- **SC-003**: L'inventaire des icones est complet et documente — chaque icone systeme existante a un equivalent Phosphor identifie
- **SC-004**: Aucune regression visuelle — tous les ecrans affichent correctement les nouvelles icones sans element manquant ou mal aligne

## Clarifications

### Session 2026-03-05

- Q: Convention de taille des icones par contexte ? → A: Tailles par contexte — navigation 24px, actions/FAB 24px, inline/listes 20px, decoratif 16px
- Q: Emplacement de l'inventaire des icones (FR-006) ? → A: Fichier separe `specs/069-phosphor-icons-migration/icon-mapping.md`

## Assumptions

- Phosphor Icons couvre tous les besoins en icones systeme de l'application (9 000+ icones disponibles)
- Le package `phosphor_flutter` est compatible avec Flutter >= 3.27
- Le package Angular Phosphor est compatible avec Angular 21
- Le style "duotone" est reserve pour un usage decoratif optionnel et n'est pas obligatoire dans cette migration
- Les icones Material Icons natives de Flutter ne sont pas "supprimees" (elles font partie du framework), mais tous les usages systeme sont remplaces
