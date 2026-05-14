# Feature Specification: Catégories formulaire Flutter (alignement DESIGN.md v5)

**Issue**: KKS-248  
**Feature Branch**: `feature/flutter-screens-medium-v5`  
**Created**: 2026-05-14  
**Status**: Draft  
**Priority**: High  
**Labels**: Feature  

---

## User Scenarios & Testing

### User Story 1 — Saisie du nom avec validation (P1)

L'utilisateur ouvre le formulaire de catégorie (création ou édition) et saisit un nom. Le champ valide la saisie et bloque la soumission si la règle n'est pas respectée.

**Why this priority**: Le nom est l'identifiant principal d'une catégorie. Sans lui, le formulaire n'a aucune valeur. C'est le champ bloquant le plus fréquemment rencontré.

**Independent Test**: Ouvrir le formulaire en création → tenter de soumettre sans nom → constater le message d'erreur inline → saisir un nom valide → soumettre avec succès.

**Acceptance Scenarios**:

1. **Given** le formulaire est ouvert en mode création, **When** l'utilisateur tente de soumettre avec un nom vide, **Then** un message d'erreur apparaît inline sous le champ nom et la soumission est bloquée.
2. **Given** le formulaire est ouvert en mode création, **When** l'utilisateur saisit un nom de plus de 30 caractères, **Then** la saisie est bloquée à 30 caractères (enforcement strict).
3. **Given** le formulaire est ouvert en mode édition, **When** l'écran s'affiche, **Then** le champ nom est pré-rempli avec le nom de la catégorie existante.

---

### User Story 2 — Sélection de l'emoji avec validation (P2)

L'utilisateur sélectionne un emoji pour représenter visuellement la catégorie. La soumission est bloquée si aucun emoji n'est choisi.

**Why this priority**: L'emoji est obligatoire selon le contrat Angular (non soumettable si vide). Il conditionne l'affichage dans toute l'application.

**Independent Test**: Ouvrir le formulaire → saisir un nom valide → tenter de soumettre sans emoji → constater l'erreur → sélectionner un emoji → soumettre avec succès.

**Acceptance Scenarios**:

1. **Given** le formulaire est ouvert, **When** l'utilisateur tente de soumettre sans avoir sélectionné d'emoji, **Then** un message d'erreur apparaît sous le sélecteur emoji et la soumission est bloquée.
2. **Given** le formulaire est en mode édition, **When** l'écran s'affiche, **Then** l'emoji existant de la catégorie est pré-sélectionné.
3. **Given** l'utilisateur a sélectionné un emoji, **When** il change de sélection, **Then** le nouvel emoji remplace l'ancien sans erreur.

---

### User Story 3 — Sélection de la couleur avec défaut aléatoire (P3)

L'utilisateur choisit une couleur parmi une palette fixe. En création, une couleur est pré-sélectionnée aléatoirement. En édition, la couleur existante est affichée.

**Why this priority**: La couleur est cosmétique et a toujours une valeur par défaut — elle ne bloque jamais la soumission. C'est le champ le moins critique.

**Independent Test**: Ouvrir le formulaire en création → constater qu'une couleur est déjà sélectionnée → cliquer sur une autre couleur → constater que la sélection change visuellement.

**Acceptance Scenarios**:

1. **Given** le formulaire est ouvert en mode création, **When** l'écran s'affiche, **Then** une couleur de la palette est pré-sélectionnée de façon aléatoire.
2. **Given** le formulaire est ouvert en mode édition, **When** l'écran s'affiche, **Then** la couleur de la catégorie existante est sélectionnée dans la grille.
3. **Given** l'utilisateur clique sur une couleur de la grille, **When** la sélection change, **Then** la couleur active est visuellement distincte des autres (état actif visible).

---

### Edge Cases

- Que se passe-t-il si `ColorPalettePicker.paletteColors` est vide ? (ne doit pas arriver — liste constante, mais defensive)
- Que se passe-t-il si l'API retourne 409 (nom dupliqué) ? → SnackBar avec message dupliqué spécifique.
- Que se passe-t-il si l'API est indisponible ? → SnackBar avec message d'erreur générique, formulaire reste ouvert.

---

## Requirements

### Functional Requirements

- **FR-001**: Le champ nom DOIT afficher son erreur inline sous le champ (pas de dialog, pas de banner global) lors d'une tentative de soumission avec valeur invalide.
- **FR-002**: Le champ nom DOIT être limité à 30 caractères avec enforcement strict (pas de saisie au-delà).
- **FR-003**: Le sélecteur emoji DOIT bloquer la soumission si vide, avec message d'erreur inline.
- **FR-004**: La grille de couleurs DOIT afficher toutes les couleurs de `ColorPalettePicker.paletteColors` sous forme de swatches circulaires cliquables, avec état actif visuellement distinct. `ColorPalettePicker` est conservé tel quel — seul l'alignement des tokens v5 est vérifié. Le remplacement par un color picker libre est traité dans KKS-256.
- **FR-005**: En mode création, une couleur DOIT être pré-sélectionnée aléatoirement à l'init.
- **FR-006**: En mode édition, les trois champs (nom, emoji, couleur) DOIVENT être pré-remplis avec les valeurs de la catégorie existante.
- **FR-007**: Les erreurs de validation DOIVENT apparaître uniquement après la première tentative de soumission (pas de validation en temps réel avant).
- **FR-008**: Toutes les valeurs de style (couleurs, espacements, typographie, radius) DOIVENT utiliser les tokens v5 (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`) — aucune valeur hardcodée.
- **FR-009**: La `CategoryPreviewCard` DOIT être retirée du formulaire — absente dans Angular, hors périmètre de l'alignement strict DESIGN.md v5.

### Non-Functional Requirements

- **NFR-001**: Les erreurs réseau (duplicate 409, erreur serveur) sont remontées via SnackBar — pas d'erreur inline pour les erreurs serveur.
- **NFR-002**: L'alignement design v5 s'applique au mode standalone (`CategoryFormScreen`) ET au mode embarqué (`CategorySelectExpand`). L'API publique `CategoryFormWidgetState.submit()` et `initialName` ne doivent pas être modifiées — seul le rendu visuel est mis à jour.
- **NFR-003**: Aucun widget privé nouveau ne doit être extrait en `common_widgets` — le périmètre est limité à `category_form_widget.dart` et `category_form_screen.dart`.

### Key Entities

- **Category**: `id`, `nom` (max 30 chars), `icone` (emoji, obligatoire), `couleur` (hex string depuis palette)

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: En création, la grille de couleurs affiche une couleur pré-sélectionnée dès l'ouverture sans action utilisateur.
- **SC-002**: Tenter de soumettre avec emoji vide affiche un message d'erreur visible sous le sélecteur emoji.
- **SC-003**: Tenter de soumettre avec nom vide affiche un message d'erreur visible sous le champ nom.
- **SC-004**: En édition, les trois champs (nom, emoji, couleur) correspondent exactement aux valeurs de la catégorie chargée.
- **SC-005**: Aucune valeur hex, rgba ou pixel hardcodée dans `category_form_widget.dart` ni `category_form_screen.dart` — audit via grep sur le fichier après implémentation.
- **SC-006**: Les tests widget existants (`category_form_widget_test.dart`, `category_form_screen_test.dart`) passent sans modification de leur API.
