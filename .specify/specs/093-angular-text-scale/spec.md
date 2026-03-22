# Feature Specification: Angular — Contrôle de la taille du texte

**Feature Branch**: `093-angular-text-scale`
**Created**: 2026-03-15
**Status**: Draft
**Input**: Porter la fonctionnalité de contrôle de taille de texte (TextScale) de Flutter vers Angular, dans l'écran Apparence existant

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Changer la taille du texte depuis les paramètres (Priority: P1)

L'utilisateur ouvre Paramètres > Apparence et trouve une section "Taille du texte" sous la section Thème existante. Il peut choisir entre 3 options : Petit, Normal (défaut), Grand. La taille de tous les textes de l'application change immédiatement. Le choix est persisté et restauré au prochain chargement.

**Why this priority**: C'est la fonctionnalité principale — sans le sélecteur et la persistance, rien d'autre n'est possible.

**Independent Test**: Ouvrir Paramètres > Apparence, changer la taille en "Grand", vérifier que tous les textes de l'app sont plus grands. Recharger la page — le réglage est conservé.

**Acceptance Scenarios**:

1. **Given** l'écran Apparence ouvert, **When** l'utilisateur sélectionne "Petit", **Then** tous les textes de l'application rétrécissent immédiatement (facteur 0.85x)
2. **Given** l'écran Apparence ouvert, **When** l'utilisateur sélectionne "Grand", **Then** tous les textes de l'application agrandissent immédiatement (facteur 1.3x)
3. **Given** la taille réglée sur "Grand", **When** l'utilisateur recharge la page ou ferme/rouvre le navigateur, **Then** la taille "Grand" est restaurée automatiquement
4. **Given** aucun réglage sauvegardé, **When** l'utilisateur ouvre l'app pour la première fois, **Then** la taille par défaut est "Normal" (facteur 1.0x)

---

### User Story 2 — Aperçu en temps réel de la taille choisie (Priority: P2)

Sous le sélecteur de taille, un aperçu affiche un texte d'exemple rendu à la taille choisie, permettant à l'utilisateur de voir l'effet avant de naviguer ailleurs. Identique au comportement Flutter (`_TextPreview`).

**Why this priority**: L'aperçu donne confiance à l'utilisateur que son choix est correct sans devoir quitter l'écran.

**Independent Test**: Sélectionner chaque option et vérifier que le texte de preview change de taille en temps réel.

**Acceptance Scenarios**:

1. **Given** l'écran Apparence ouvert, **When** l'utilisateur sélectionne "Petit", **Then** le texte d'aperçu sous le sélecteur s'affiche en taille réduite
2. **Given** l'écran Apparence ouvert, **When** l'utilisateur passe de "Petit" à "Grand", **Then** le texte d'aperçu change de taille immédiatement

---

### Edge Cases

- Que se passe-t-il si le stockage local est vidé ? Le réglage revient à "Normal" (défaut).
- La taille du texte affecte-t-elle les icônes ? Non, seuls les textes sont affectés — les icônes gardent leur taille fixe.
- La taille du texte affecte-t-elle l'écran de login ? Oui, le scale s'applique à toute l'application.
- Comment la taille interagit-elle avec le zoom navigateur ? Le text-scale se cumule avec le zoom navigateur (comportement standard CSS).
- Que se passe-t-il si le navigateur a déjà un réglage d'accessibilité texte ? Le text-scale se cumule — c'est le comportement attendu et conforme à l'accessibilité.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'écran Apparence DOIT afficher une section "Taille du texte" avec 3 options : Petit (0.85x), Normal (1.0x), Grand (1.3x)
- **FR-002**: La sélection d'une taille DOIT modifier immédiatement la taille de tous les textes de l'application (sans rechargement)
- **FR-003**: Le choix de taille DOIT être persisté localement et restauré au prochain chargement de l'application
- **FR-004**: La taille par défaut DOIT être "Normal" (1.0x) quand aucun réglage n'est sauvegardé
- **FR-005**: Un aperçu textuel DOIT afficher un texte d'exemple rendu à la taille choisie, directement sous le sélecteur
- **FR-006**: Le sélecteur de taille DOIT utiliser le même style visuel que le sélecteur de thème existant (segmented control)
- **FR-007**: Les facteurs de mise à l'échelle DOIVENT correspondre exactement à ceux de Flutter : Petit = 0.85, Normal = 1.0, Grand = 1.3
- **FR-008**: Le contrôle de taille NE DOIT PAS affecter la taille des icônes

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut changer la taille du texte en 2 taps (ouvrir Apparence + sélectionner la taille)
- **SC-002**: Le changement de taille est visible instantanément (< 100ms) sans rechargement de page
- **SC-003**: Le réglage persiste après fermeture et réouverture du navigateur
- **SC-004**: La parité fonctionnelle avec Flutter est atteinte — mêmes 3 options, mêmes facteurs de scale
- **SC-005**: Aucune fonctionnalité existante n'est altérée — tous les tests passent

## Assumptions

- La persistance utilise `localStorage` (standard web) — pas besoin de synchronisation serveur pour un réglage d'affichage local
- Le scale s'applique via une propriété CSS sur le `<html>` ou le conteneur racine de l'application — pas de modification de chaque composant individuellement
- L'écran Apparence existe déjà avec le sélecteur de thème — on ajoute une section en dessous
- Le sélecteur réutilise le pattern visuel `.segmented-control` déjà en place pour le thème
- Le scope est limité à l'application Angular (app/) — aucun changement backend ou Flutter
