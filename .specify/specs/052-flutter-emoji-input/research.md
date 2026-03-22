# Research: Flutter Emoji Input

**Feature**: 052-flutter-emoji-input | **Date**: 2026-02-23

## R1: Package emoji_picker_flutter

**Decision**: Utiliser `emoji_picker_flutter: ^4.4.0`

**Rationale**: Package mature avec support natif des catégories, recherche, recents, et adaptation thème. Évite de réimplémenter un picker from scratch. Déjà ajouté au `pubspec.yaml`.

**Alternatives considered**:
- **Picker from scratch** : Rejeté — effort disproportionné (catalogue Unicode, catégorisation, rendu multi-plateforme)
- **`emojis` (package)** : Données emoji seulement, pas de widget picker
- **`emoji_selector`** : Moins maintenu, moins de features (pas de recherche native)

## R2: Pattern FormField<String>

**Decision**: Étendre `FormField<String>` directement (comme `SelectPicker`)

**Rationale**: Pattern existant dans le projet (`select_picker.dart`). Le widget gère son propre label, trigger et erreur — pas besoin du wrapper `AppFormField`.

**Alternatives considered**:
- **Wrapper AppFormField** : Rejeté — EmojiInput a son propre layout (trigger carré 48x48, pas un champ texte standard)
- **StatefulWidget + callback** : Rejeté — perd l'intégration native avec `Form.validate()`

## R3: Présentation bottom sheet

**Decision**: `showModalBottomSheet` direct avec hauteur 50% de l'écran

**Rationale**: Le package emoji_picker_flutter gère sa propre UI interne (grille, catégories, recherche). Un `AppModal` ajouterait un header redondant.

**Alternatives considered**:
- **AppModal** : Rejeté — ajoute un header/close button alors que le sheet a déjà le sien
- **Full screen** : Rejeté — trop intrusif pour un picker rapide
- **Dialog** : Rejeté — pas adapté mobile (bottom sheet = pattern natif iOS/Android)

## R4: Adaptation thème

**Decision**: Lire `Theme.of(context).colorScheme` et passer les couleurs à `Config` du package

**Rationale**: Le package supporte la configuration couleur via `EmojiViewConfig`, `CategoryViewConfig`, `SearchViewConfig`. Aucun theming custom nécessaire.

**Alternatives considered**:
- **Thème custom dédié** : Rejeté — over-engineering, les tokens du colorScheme suffisent

## R5: Stratégie de test

**Decision**: Widget tests uniquement (pas de tests unitaires séparés)

**Rationale**: Widget UI pur sans logique métier. Les tests vérifient le rendu, les interactions (tap → picker), la validation, et les états (disabled, error, initialValue).

**Alternatives considered**:
- **Golden tests** : Rejeté — fragiles avec le package emoji_picker_flutter (rendu platform-dependent)
- **Integration tests** : Rejeté — disproportionné pour un widget autonome
