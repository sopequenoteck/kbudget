# Feature Specification: Aligner Emoji Picker Angular sur Flutter

**Feature Branch**: `097-angular-emoji-picker`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "KKS-163 — Aligner emoji picker Angular sur Flutter — remplacer input texte par un vrai picker"
**Linear**: [KKS-163](https://linear.app/kksdev/issue/KKS-163)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sélectionner un emoji via le picker (Priority: P1)

L'utilisateur ouvre un formulaire (catégorie ou compte) et clique sur la zone emoji (box 48×48 affichant l'emoji actuel ou un placeholder). Un popover s'ouvre avec une grille d'emojis organisée par catégories (smileys, nature, food, travel, activities, objects, symbols, flags). L'utilisateur parcourt les catégories ou utilise la barre de recherche pour trouver un emoji. Il tape sur l'emoji souhaité, le picker se ferme et l'emoji sélectionné apparaît dans la box.

**Why this priority**: C'est le parcours principal — sans lui, la feature n'existe pas. Il remplace l'input texte brut par une expérience visuelle intuitive, alignée sur Flutter.

**Independent Test**: Ouvrir le formulaire de catégorie, cliquer sur la box emoji, naviguer dans les catégories, sélectionner un emoji → l'emoji apparaît dans la box et le formulaire reçoit la valeur.

**Acceptance Scenarios**:

1. **Given** le formulaire catégorie est ouvert sans emoji sélectionné, **When** l'utilisateur clique sur la box emoji, **Then** un popover s'ouvre avec la grille d'emojis par catégories et une barre de recherche.
2. **Given** le picker est ouvert, **When** l'utilisateur clique sur un emoji, **Then** le picker se ferme, l'emoji sélectionné s'affiche dans la box, et l'événement de changement est émis avec la valeur emoji.
3. **Given** le picker est ouvert, **When** l'utilisateur tape "cat" dans la barre de recherche (mots-clés en anglais), **Then** les emojis correspondants sont filtrés et affichés.
4. **Given** le formulaire compte est ouvert avec un emoji existant, **When** l'utilisateur clique sur la box, **Then** le picker s'ouvre et l'emoji actuel est visible.

---

### User Story 2 - Emojis récents (Priority: P2)

L'utilisateur ouvre le picker et voit en premier une section "Récents" affichant les emojis qu'il a récemment utilisés, permettant une sélection rapide sans parcourir les catégories.

**Why this priority**: Les récents accélèrent significativement la sélection pour les usages répétés (l'utilisateur utilise souvent les mêmes emojis pour ses catégories).

**Independent Test**: Sélectionner 3 emojis différents dans des formulaires successifs, rouvrir le picker → les 3 emojis apparaissent dans la section "Récents".

**Acceptance Scenarios**:

1. **Given** l'utilisateur a déjà sélectionné des emojis précédemment, **When** il ouvre le picker, **Then** la section "Récents" est affichée en premier avec les emojis précédemment utilisés.
2. **Given** c'est la première utilisation (aucun historique), **When** l'utilisateur ouvre le picker, **Then** la section "Récents" est absente ou vide, et la première catégorie standard est affichée.

---

### User Story 3 - Thème dark/light (Priority: P2)

Le picker s'adapte automatiquement au thème actif de l'application (light ou dark), offrant une expérience visuelle cohérente.

**Why this priority**: La cohérence visuelle est essentielle pour l'expérience utilisateur, surtout en dark mode.

**Independent Test**: Basculer entre les modes light et dark → le picker adapte ses couleurs (fond, texte, bordures) en conséquence.

**Acceptance Scenarios**:

1. **Given** l'application est en mode light, **When** l'utilisateur ouvre le picker, **Then** le picker utilise un fond clair avec des textes sombres.
2. **Given** l'application est en mode dark, **When** l'utilisateur ouvre le picker, **Then** le picker utilise un fond sombre avec des textes clairs, cohérent avec le design system.

---

### User Story 4 - Fermeture du picker (Priority: P3)

L'utilisateur peut fermer le picker sans sélectionner d'emoji en cliquant à l'extérieur du popover ou en appuyant sur Escape.

**Why this priority**: Indispensable pour l'accessibilité et l'ergonomie, mais comportement attendu standard.

**Independent Test**: Ouvrir le picker, cliquer à l'extérieur → le picker se ferme sans changement de valeur.

**Acceptance Scenarios**:

1. **Given** le picker est ouvert, **When** l'utilisateur clique à l'extérieur du popover, **Then** le picker se ferme et l'emoji précédent reste inchangé.
2. **Given** le picker est ouvert, **When** l'utilisateur appuie sur la touche Escape, **Then** le picker se ferme et l'emoji précédent reste inchangé.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur redimensionne la fenêtre pendant que le picker est ouvert ? → Le popover se repositionne ou se ferme.
- Comment le picker se comporte-t-il sur écran mobile (< 768px) ? → Le popover s'adapte à la taille disponible.
- Que se passe-t-il si le picker est ouvert et que l'utilisateur navigue vers une autre page ? → Le picker se ferme automatiquement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT remplacer l'input texte brut actuel par une box cliquable (48×48) affichant l'emoji sélectionné ou un placeholder.
- **FR-002**: Le système DOIT ouvrir un popover contenant un picker d'emojis lorsque l'utilisateur clique sur la box.
- **FR-003**: Le picker DOIT organiser les emojis par catégories : smileys, nature, food, travel, activities, objects, symbols, flags.
- **FR-004**: Le picker DOIT inclure une barre de recherche permettant de filtrer les emojis par mot-clé. L'interface (labels catégories, placeholder) est en français. Note : les mots-clés de recherche restent en anglais (limitation du dataset emoji-mart — comportement standard des emoji pickers web).
- **FR-005**: Le picker DOIT afficher une section "Récents" en première position, mémorisant les derniers emojis sélectionnés.
- **FR-006**: Le système DOIT fermer le picker et émettre la valeur sélectionnée lorsqu'un emoji est cliqué.
- **FR-007**: Le système DOIT fermer le picker sans changement lorsque l'utilisateur clique à l'extérieur ou appuie sur Escape.
- **FR-008**: Le picker DOIT s'adapter au thème actif (light/dark) de l'application via les design tokens existants.
- **FR-009**: Le composant DOIT conserver la même API publique (input `value`, output `valueChange`) pour garantir la compatibilité avec les formulaires existants (catégories, comptes).
- **FR-010**: Le système DOIT inclure des tests unitaires couvrant la sélection, la fermeture, et l'intégration avec les formulaires.

### Key Entities

- **EmojiInput** : Composant partagé Angular (standalone, OnPush). Entrées : emoji actuel. Sorties : emoji sélectionné. Utilisé dans les formulaires catégorie et compte.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut sélectionner un emoji en 2 interactions maximum (clic sur la box + clic sur l'emoji), contre une saisie manuelle auparavant.
- **SC-002**: 100% des emojis disponibles sont accessibles via la grille par catégories ou la recherche.
- **SC-003**: Les emojis récemment utilisés sont disponibles en première position du picker, réduisant le temps de sélection pour les usages répétés.
- **SC-004**: Le picker fonctionne correctement dans les deux thèmes (light et dark) sans anomalie visuelle.
- **SC-005**: Les formulaires catégorie et compte continuent de fonctionner sans régression après le remplacement du composant.

## Clarifications

### Session 2026-03-20

- Q: Langue du picker (catégories et recherche) ? → A: Français — catégories et recherche en français (si supporté par le package).

## Assumptions

- Le package `emoji-mart` (ou `@emoji-mart/data` + `emoji-mart`) sera utilisé comme librairie de picker côté web, comme suggéré dans l'issue Linear.
- Les emojis récents sont stockés localement dans le navigateur (localStorage ou mécanisme interne du picker), sans synchronisation serveur.
- Le popover est le pattern d'affichage retenu pour desktop ; sur mobile, le même popover s'adapte à la taille d'écran disponible.
- L'API publique du composant (`value` input / `valueChange` output) ne change pas, assurant une migration transparente pour les formulaires consommateurs.
