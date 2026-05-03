# Feature Specification: Refonte du Design System Partagé

**Feature Branch**: `063-shared-design-tokens`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "Refonte du design system partagé (tokens, couleurs, typo, spacing)"
**Linear**: KKS-149

## Clarifications

### Session 2026-03-01

- Q: Quelle couleur secondaire complémentaire à Amber ? → A: Indigo (#4F46E5) — bleu profond, complémentaire chromatique d'Amber, connotation confiance/finance.
- Q: Stratégie de résolution quand Angular et Flutter divergent sur un token ? → A: Best-of-both — choisir la meilleure valeur existante parmi les deux stacks, justifiée token par token lors du plan.
- Q: Support reduced-motion dans Flutter (absent actuellement, présent dans Angular) ? → A: In scope — implémenter le support reduced-motion dans Flutter dans cette feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la référence unique des tokens (Priority: P1)

En tant que développeur travaillant sur l'application Budget, je souhaite disposer d'un document de référence unique listant tous les design tokens (couleurs, typographie, spacing, radius, ombres, animations) pour que les deux frontends (Angular et Flutter) partagent exactement les mêmes valeurs visuelles.

**Why this priority**: Sans référence unique, chaque stack évolue indépendamment et les incohérences visuelles s'accumulent. Ce document est le fondement de toute la refonte visuelle.

**Independent Test**: Le document de référence peut être livré et validé indépendamment en comparant les valeurs listées aux maquettes et aux besoins identifiés.

**Acceptance Scenarios**:

1. **Given** le document de référence des tokens est publié, **When** un développeur cherche la valeur d'un token (ex: couleur primaire, espacement standard), **Then** il trouve une valeur unique et non-ambiguë applicable aux deux plateformes.
2. **Given** le document de référence existe, **When** un développeur compare les tokens Flutter et Angular, **Then** les valeurs primitives sont identiques entre les deux stacks.
3. **Given** le document inclut les thèmes light et dark, **When** un développeur consulte un token sémantique (ex: couleur de fond, couleur de texte), **Then** les deux variantes (light et dark) sont documentées.

---

### User Story 2 - Utiliser les tokens harmonisés dans Angular (Priority: P2)

En tant que développeur Angular, je souhaite que les fichiers SCSS de tokens soient mis à jour pour refléter les valeurs du document de référence partagé, afin que la PWA soit visuellement cohérente avec l'app Flutter.

**Why this priority**: Angular est le frontend web existant. La mise à jour de ses tokens est essentielle pour concrétiser l'harmonisation sur la plateforme web.

**Independent Test**: Après mise à jour des fichiers SCSS, l'application Angular se compile sans erreur et les couleurs/spacing/typo affichés correspondent au document de référence.

**Acceptance Scenarios**:

1. **Given** les tokens SCSS sont mis à jour, **When** l'application Angular est compilée, **Then** aucune erreur de build n'est générée.
2. **Given** les tokens SCSS reflètent la référence partagée, **When** un composant utilise `var(--color-primary)`, **Then** la couleur affichée est identique à celle définie dans le document de référence.
3. **Given** les thèmes light et dark sont harmonisés, **When** l'utilisateur bascule de thème, **Then** les couleurs sémantiques (fond, texte, bordures, feedback) changent conformément au document de référence.

---

### User Story 3 - Utiliser les tokens harmonisés dans Flutter (Priority: P2)

En tant que développeur Flutter, je souhaite que les constantes Dart de tokens soient mises à jour pour refléter les valeurs du document de référence partagé, afin que l'app mobile soit visuellement cohérente avec la PWA Angular.

**Why this priority**: Flutter est le frontend mobile. La mise à jour de ses constantes est essentielle pour concrétiser l'harmonisation sur mobile.

**Independent Test**: Après mise à jour des constantes Dart, l'application Flutter se compile sans erreur et les couleurs/spacing/typo affichés correspondent au document de référence.

**Acceptance Scenarios**:

1. **Given** les constantes Dart sont mises à jour, **When** l'application Flutter est compilée, **Then** aucune erreur de build n'est générée.
2. **Given** les constantes reflètent la référence partagée, **When** un widget utilise `AppColors.amber500`, **Then** la couleur affichée est identique à celle du document de référence.
3. **Given** les thèmes light et dark sont harmonisés, **When** l'utilisateur bascule de thème dans Flutter, **Then** les couleurs sémantiques changent conformément au document de référence.

---

### User Story 4 - Définir la couleur secondaire (Priority: P1)

En tant qu'utilisateur de l'application Budget, je souhaite que l'interface dispose d'une couleur secondaire complémentaire à la couleur primaire Amber, afin d'enrichir la palette visuelle tout en gardant une identité cohérente.

**Why this priority**: La couleur secondaire impacte l'ensemble du design et doit être définie avant l'implémentation des tokens dans les deux stacks.

**Independent Test**: La couleur secondaire peut être validée indépendamment via un test de contraste (WCAG AA) et une palette de couleurs.

**Acceptance Scenarios**:

1. **Given** une couleur secondaire est proposée, **When** elle est placée à côté de la couleur primaire Amber, **Then** le contraste visuel est suffisant et l'harmonie est respectée.
2. **Given** la couleur secondaire est définie, **When** elle est utilisée sur fond clair et fond sombre, **Then** le ratio de contraste atteint au minimum WCAG AA (4.5:1 pour le texte, 3:1 pour les éléments graphiques).
3. **Given** la couleur secondaire est définie avec sa palette complète (50-900), **When** un développeur cherche une nuance, **Then** il dispose de 10 nuances cohérentes (du plus clair au plus foncé).

---

### User Story 5 - Cohérence visuelle cross-plateforme (Priority: P3)

En tant qu'utilisateur utilisant à la fois la PWA web et l'app mobile, je souhaite que l'apparence visuelle soit cohérente entre les deux plateformes pour une expérience familière quel que soit le support.

**Why this priority**: C'est l'objectif ultime de la refonte, mais il découle naturellement des stories précédentes.

**Independent Test**: En comparant visuellement les mêmes écrans sur Angular et Flutter (captures d'écran côte à côte), les couleurs, espacements et typographies sont visuellement identiques.

**Acceptance Scenarios**:

1. **Given** les tokens sont implémentés dans les deux stacks, **When** le même écran (ex: dashboard, liste de transactions) est affiché sur Angular et Flutter, **Then** les valeurs des tokens couleurs primaires, secondaires et de feedback sont numériquement identiques entre les deux plateformes.
2. **Given** les tokens de spacing sont harmonisés, **When** les marges et paddings sont comparés entre les deux plateformes, **Then** les valeurs sont identiques (même base 4px).
3. **Given** la typographie est harmonisée, **When** les textes sont comparés, **Then** la police (Inter), les tailles et les graisses correspondent entre les deux stacks.

---

### Edge Cases

- Que se passe-t-il si un token est supprimé du document de référence mais encore utilisé dans une des stacks ? Les composants utilisant ce token doivent être identifiés et migrés avant suppression.
- Comment gérer les tokens spécifiques à une plateforme (ex: z-index CSS n'existe pas en Flutter) ? Ils sont documentés comme "plateforme-spécifiques" dans le document de référence.
- Que se passe-t-il si la couleur secondaire ne passe pas les tests de contraste WCAG AA dans un contexte spécifique ? Des variantes de nuance (plus claire ou plus foncée) sont utilisées selon le contexte (texte sur fond clair vs fond sombre).
- Comment gérer le passage d'anciennes valeurs aux nouvelles pour les composants existants ? Un guide de migration liste les anciens tokens et leurs nouveaux équivalents.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT disposer d'un document de référence unique (`docs/design-tokens.md`) listant tous les tokens partagés entre Angular et Flutter.
- **FR-002**: La palette de couleurs DOIT inclure : couleur primaire (Amber #f59e0b conservée), couleur secondaire (Indigo #4F46E5 avec palette complète 50-900), gris neutres, couleurs de feedback (success, error, warning, info) et couleurs métier (income, expense, debt-owe, debt-owed, subscription).
- **FR-003**: Les tokens de typographie DOIVENT définir : famille de police (Inter conservée), échelle de tailles (xs à 3xl), graisses (regular, medium, semibold, bold) et hauteurs de ligne.
- **FR-004**: Les tokens de spacing DOIVENT suivre une échelle basée sur 4px (0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48).
- **FR-005**: Les tokens de border-radius DOIVENT être définis avec des noms sémantiques (sm, md, lg, xl, xxl, round).
- **FR-006**: Les tokens d'ombres DOIVENT être définis en trois niveaux (sm, md, lg) plus une variante colorée.
- **FR-007**: Les tokens d'animation DOIVENT définir les durées (fast, normal, slow) et les courbes d'accélération avec nommage unifié (`easeDefault`, `easeIn`, `easeOut`). Le support reduced-motion DOIT être implémenté dans Flutter (durées à 0ms quand l'accessibilité désactive les animations), à parité avec le support existant dans Angular.
- **FR-008**: Les thèmes light et dark DOIVENT être définis avec des tokens sémantiques couvrant : arrière-plans, textes, bordures, surfaces et couleurs de feedback.
- **FR-009**: Les fichiers SCSS Angular (`app/src/styles/tokens/`) DOIVENT être mis à jour pour refléter exactement les valeurs du document de référence.
- **FR-010**: Les constantes Dart Flutter (`flutter/lib/src/constants/` et `flutter/lib/src/theme/`) DOIVENT être mises à jour pour refléter exactement les valeurs du document de référence.
- **FR-011**: La couleur secondaire Indigo (cf. FR-002) DOIT passer les tests de contraste WCAG AA (ratio >= 4.5:1 pour le texte normal, >= 3:1 pour les éléments graphiques) sur fond clair et fond sombre.
- **FR-012**: Les incohérences actuelles entre Angular et Flutter DOIVENT être résolues selon une approche best-of-both : pour chaque token divergent, la meilleure valeur existante est retenue avec justification documentée dans le plan technique.
- **FR-013**: Les tokens spécifiques à une plateforme (ex: z-index CSS, layout Angular) DOIVENT être documentés séparément dans le document de référence.

### Key Entities

- **Design Token**: Valeur de design nommée (couleur, dimension, durée) avec un nom canonique, une valeur, et une catégorie (color, spacing, typography, radius, shadow, animation).
- **Palette de couleurs**: Ensemble de nuances (50-900) pour une teinte donnée (primaire, secondaire, gris, feedback).
- **Thème**: Ensemble de tokens sémantiques (fond, texte, bordures, surfaces) avec deux variantes : light et dark.

## Assumptions

- La police Inter est conservée comme police principale (confirmé dans l'issue).
- La couleur primaire Amber (#f59e0b) est conservée (confirmé dans l'issue).
- L'échelle de spacing 4px existante est conservée car elle fonctionne bien dans les deux stacks.
- Les couleurs de feedback (success, error, warning, info) restent dans la même famille chromatique (vert, rouge, jaune, bleu) mais leurs valeurs exactes seront harmonisées.
- Le document de référence sera en Markdown (`docs/design-tokens.md`) plutôt qu'en JSON, car c'est le format documentaire du projet.
- Les composants existants ne sont pas redesignés dans cette feature — seuls les tokens fondamentaux sont harmonisés. La refonte écran par écran est un chantier ultérieur.
- Les couleurs métier (income, expense, debt, subscription) seront harmonisées entre les deux stacks.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des tokens primitifs (couleurs, spacing, typo, radius, ombres, animations) ont des valeurs identiques entre le document de référence, les fichiers SCSS Angular et les constantes Dart Flutter.
- **SC-002**: Les deux applications (Angular et Flutter) se compilent sans erreur après la mise à jour des tokens.
- **SC-003**: La couleur secondaire définie passe le test de contraste WCAG AA (ratio >= 4.5:1 pour le texte normal, >= 3:1 pour le texte large et les éléments graphiques) sur fond clair et fond sombre.
- **SC-004**: Les thèmes light et dark produisent des résultats visuellement cohérents entre Angular et Flutter pour les éléments de base (fond, texte, bordures, couleur primaire, couleurs de feedback).
- **SC-005**: Le document de référence couvre au minimum 6 catégories de tokens : couleurs, typographie, spacing, radius, ombres, animations.
- **SC-006**: Zéro incohérence de valeur entre les tokens primitifs Angular et Flutter après implémentation.

## Out of Scope

- Redesign des composants UI individuels (boutons, cartes, inputs) — sera traité écran par écran ultérieurement.
- Wireframes ou maquettes des écrans — l'utilisateur les fera séparément.
- Création d'un outil de synchronisation automatique entre SCSS et Dart.
- Refonte des icônes ou illustrations.
- Ajout de breakpoints responsive (spécifique à Angular, pas partageable avec Flutter).
- Migration des composants existants vers les nouveaux tokens — un guide de migration est fourni mais l'application effective est hors scope.

## Dependencies

- Aucune dépendance technique bloquante : les fichiers de tokens existent déjà dans les deux stacks.
- Cette feature BLOQUE toutes les issues de refonte visuelle écran par écran (fondation du design system).
