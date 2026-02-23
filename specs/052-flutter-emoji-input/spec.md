# Feature Specification: Flutter Emoji Input

**Feature Branch**: `052-flutter-emoji-input`
**Created**: 2026-02-23
**Status**: In Progress
**Linear**: KKS-98

## User Scenarios & Testing

### User Story 1 - Sélectionner un emoji via le picker visuel (Priority: P1)

L'utilisateur tape sur une boîte carrée 48x48 qui affiche l'emoji actuellement sélectionné ou un placeholder "...". Un bottom sheet s'ouvre avec une grille d'emojis organisés par catégories. Un tap sur un emoji ferme le panneau et met à jour la valeur.

**Why this priority**: Fonctionnalité core du widget — sans cela, aucune sélection possible.

**Independent Test**: Peut être testé en intégrant le widget seul dans un écran de test et en vérifiant le cycle tap → picker → sélection → fermeture.

**Acceptance Scenarios**:

1. **Given** le widget sans valeur initiale, **When** l'utilisateur voit le trigger, **Then** il affiche "..." dans une boîte 48x48 avec fond `surfaceContainerHighest`
2. **Given** le trigger affiché, **When** l'utilisateur tape dessus, **Then** un bottom sheet s'ouvre avec la grille d'emojis par catégories
3. **Given** le picker ouvert, **When** l'utilisateur tape sur un emoji, **Then** le bottom sheet se ferme et le trigger affiche l'emoji sélectionné

---

### User Story 2 - Intégration formulaire avec validation (Priority: P2)

Le widget s'intègre dans un `Form` Flutter comme `FormField<String>`. Il supporte la validation (champ requis), l'affichage de messages d'erreur, et le pré-remplissage en mode édition via `initialValue`.

**Why this priority**: Nécessaire pour l'intégration dans les formulaires Account et Category, mais le picker fonctionne déjà sans.

**Independent Test**: Intégrer dans un Form avec validator requis, soumettre sans sélection → message d'erreur visible.

**Acceptance Scenarios**:

1. **Given** un formulaire avec EmojiInput requis, **When** l'utilisateur soumet sans sélectionner, **Then** le message d'erreur s'affiche sous le trigger
2. **Given** un EmojiInput avec `initialValue: '🏠'`, **When** le widget s'affiche, **Then** le trigger montre l'emoji 🏠
3. **Given** un EmojiInput avec `enabled: false`, **When** l'utilisateur tape sur le trigger, **Then** rien ne se passe et le trigger est semi-transparent

---

### User Story 3 - Rechercher un emoji par mot-clé (Priority: P3)

L'utilisateur peut rechercher un emoji par mot-clé dans le panneau du picker pour trouver rapidement un emoji spécifique.

**Why this priority**: Amélioration UX, le parcours par catégories suffit pour un usage basique.

**Independent Test**: Ouvrir le picker, taper "cat" dans la recherche → emojis filtrés.

**Acceptance Scenarios**:

1. **Given** le picker ouvert, **When** l'utilisateur tape "heart" dans le champ de recherche, **Then** seuls les emojis contenant "heart" sont affichés

---

### Edge Cases

- Que se passe-t-il si `initialValue` contient un caractère non-emoji ? → Affiché tel quel dans le trigger
- Comment réagit le widget en mode disabled avec une valeur ? → Emoji affiché mais semi-transparent, tap ignoré
- Recherche sans résultat → Message par défaut du package ("No Emoji Found"), aucune personnalisation

## Requirements

### Functional Requirements

- **FR-001**: Le trigger DOIT être une boîte 48x48 affichant l'emoji sélectionné (24px) ou "..." comme placeholder
- **FR-002**: Un tap sur le trigger DOIT ouvrir un bottom sheet contenant le picker emoji
- **FR-003**: Un tap sur un emoji dans le picker DOIT fermer le bottom sheet et mettre à jour la valeur du FormField
- **FR-004**: Le picker DOIT afficher les emojis organisés par catégories via la barre d'icônes par défaut du package `emoji_picker_flutter`
- **FR-005**: Un champ de recherche dans le picker DOIT permettre de filtrer les emojis par mot-clé
- **FR-006**: Le widget DOIT être un `FormField<String>` supportant `validator`, `onSaved`, `autovalidateMode`
- **FR-007**: Le message d'erreur de validation DOIT s'afficher sous le trigger avec animation
- **FR-008**: L'état désactivé (`enabled: false`) DOIT rendre le trigger semi-transparent (opacity 0.5) et ignorer les taps
- **FR-009**: La valeur initiale (`initialValue`) DOIT pré-remplir l'emoji affiché dans le trigger
- **FR-010**: Le picker DOIT s'adapter au thème clair/sombre via le `colorScheme` du contexte

### Key Entities

- **EmojiInput**: Widget `FormField<String>` — trigger 48x48 + bottom sheet picker. Props : `label`, `onChanged`, `placeholder`, `initialValue`, `validator`, `enabled`

## Scope

### Inclus
- Widget `EmojiInput` autonome dans `common_widgets/`
- Intégration `FormField<String>` avec validation
- Adaptation thème clair/sombre
- Recherche par mot-clé dans le picker
- Organisation par catégories d'emojis

### Dépendances externes

- **`emoji_picker_flutter`** : Package utilisé pour le picker emoji (grille par catégories, recherche par mot-clé, rendu des emojis). Le widget `EmojiInput` wrap ce package dans un `FormField<String>`.

### Exclu
- Sélection de couleur associée
- Emojis custom / stickers
- Multi-sélection d'emojis
- Gestion custom des favoris (les "Recents" natifs du package sont conservés)

## Clarifications

### Session 2026-02-23

- Q: Package existant ou picker from scratch ? → A: Utiliser le package `emoji_picker_flutter`
- Q: Navigation par catégories dans le picker ? → A: Utiliser la navigation par défaut du package (barre d'icônes en bas)
- Q: Comportement recherche sans résultat ? → A: Laisser le message par défaut du package ("No Emoji Found")
- Q: Catégorie "Recents" du package ? → A: Garder activée (géré nativement par le package, gratuit)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Le widget est utilisable dans un formulaire Flutter avec validation en moins de 5 lignes de code
- **SC-002**: `flutter analyze` passe sans erreur
- **SC-003**: Aucune régression sur les tests existants (`flutter test`)
- **SC-004**: Le picker s'affiche correctement en thème clair et sombre
