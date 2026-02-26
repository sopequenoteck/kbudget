# Implementation Plan: Flutter — Widget CategoryPicker

**Branch**: `040-flutter-categorypicker-widget` | **Date**: 2026-02-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/040-flutter-categorypicker-widget/spec.md`

## Summary

Widget Flutter `CategoryPicker` — wrapper de `SelectPicker` spécialisé pour la sélection de catégories avec affichage emoji + pastille couleur. Approche par composition : CategoryPicker est un StatelessWidget léger qui mappe `Category` → `SelectPickerItem` et ajoute le bouton "+ Créer" via un nouveau paramètre `emptyActionBuilder` sur SelectPicker.

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter (SDK), SelectPicker (feature 039), AppModal (feature 036)
**Storage**: N/A (composant UI pur, pas de persistance)
**Testing**: flutter_test (widget tests)
**Target Platform**: iOS, Android (mobile-first)
**Project Type**: mobile
**Performance Goals**: Rendu instantané, filtrage sans latence perceptible
**Constraints**: Aucune dépendance externe ajoutée
**Scale/Scope**: 1 widget (~80 lignes) + 1 modification SelectPicker (~10 lignes) + tests (~500 lignes)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Widget frontend pur, pas d'endpoint API |
| II. Sécurité par défaut | N/A | Pas de donnée sensible, pas d'authentification |
| III. Simplicité & YAGNI | PASS | Composition simple : wrapper de SelectPicker. Pas d'abstraction ni de pattern complexe. ~80 lignes de code |
| IV. Mobile-First UX | PASS | Bottom sheet modal, sélection en 2 taps, recherche intégrée |
| V. Testabilité | PASS | Widget tests avec `pumpCategoryPicker` helper. Scénarios d'acceptation tous testables |
| VI. Observabilité | N/A | Widget UI, pas de logging applicatif |
| VII. Self-Hosted Ready | N/A | Pas de dépendance infrastructure |

**Résultat** : Tous les principes applicables passent. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/040-flutter-categorypicker-widget/
├── spec.md              # Spécification fonctionnelle
├── plan.md              # Ce fichier
├── research.md          # Décisions techniques
├── data-model.md        # Mapping Category → SelectPickerItem
├── quickstart.md        # Exemples d'utilisation
└── checklists/
    └── requirements.md  # Checklist qualité spec
```

### Source Code (repository root)

```text
flutter/lib/src/
├── common_widgets/
│   ├── select_picker.dart       # MODIFIÉ : ajout paramètre emptyActionBuilder
│   └── category_picker.dart     # NOUVEAU : widget CategoryPicker
└── domain/models/
    └── category.dart            # EXISTANT : modèle Freezed (pas modifié)

flutter/test/src/common_widgets/
├── select_picker_test.dart      # MODIFIÉ : tests emptyActionBuilder
└── category_picker_test.dart    # NOUVEAU : tests CategoryPicker
```

**Structure Decision** : Widget ajouté dans `common_widgets/` (réutilisable dans les formulaires transaction, abonnement, dette). Pas de nouveau module, pas de nouvelle dépendance.

## Architecture détaillée

### 1. Modification de SelectPicker (backward-compatible)

Ajout d'un paramètre optionnel :

```
SelectPicker(
  ...paramètres existants...,
  Widget Function(String searchTerm)? emptyActionBuilder,  // NOUVEAU
)
```

**Impact dans `_buildItemsList`** : quand `filteredItems.isEmpty`, si `emptyActionBuilder != null` → appeler le builder au lieu d'afficher `emptyMessage`.

Changement estimé : ~10 lignes (1 champ, 1 paramètre constructeur, 1 condition dans `_buildItemsList`).

### 2. Widget CategoryPicker

```
CategoryPicker (StatelessWidget)
├── Entrée : List<Category>, selectedId, callbacks, paramètres FormField
├── Mapping : Category[] → SelectPickerItem[] (computed à chaque build)
├── Sortie : SelectPicker configuré avec :
│   ├── items: SelectPickerItem[] mappés
│   ├── label, placeholder, clearable, enabled, searchThreshold
│   ├── emptyMessage: 'Aucune catégorie'
│   ├── emptyActionBuilder: bouton "+ Créer « [terme] »" (si onCreateRequested fourni)
│   ├── onSearchChanged → propagé au parent
│   └── validator, onSaved, autovalidateMode → passés au FormField
└── Bouton "+ Créer" :
    ├── Affiché par emptyActionBuilder quand liste filtrée vide
    ├── Style : icône +, texte primary color, centré
    ├── Tap → Navigator.pop() + onCreateRequested(searchTerm)
    └── Sémantique : button: true, label: 'Créer [terme]'
```

### 3. Conversion couleur hex → Color

Fonction utilitaire privée dans `category_picker.dart` :
- Parse `"#ef4444"` ou `"ef4444"` en `Color`
- Ajoute alpha `FF` si 6 caractères
- Utilisée dans le mapping Category → SelectPickerItem

### 4. Stratégie de test

| Groupe | Cible | Nb tests estimé |
|--------|-------|-----------------|
| Smoke | Rendu basique avec catégories | 1 |
| Sélection & Trigger | Sélection, mise à jour, trigger display, re-sélection identique, surlignage | 7 |
| Recherche & Filtrage | Filtrage par nom, seuil automatique, onSearchChanged | 5 |
| Affichage riche | Emoji, pastille couleur, absence pastille sans couleur, truncation | 4 |
| Bouton "+ Créer" | Apparition quand vide, callback, pas de bouton si pas de callback, pas de bouton si résultats | 4 |
| Clear & Validation | Effacement, validation required, auto-reset | 3 |
| Accessibilité | Sémantiques trigger, items, bouton créer | 2 |
| Edge cases | Désactivé, thème sombre, liste vide, nom long | 4 |
| **SelectPicker (ajouts)** | emptyActionBuilder callback, backward compat, searchTerm passé | 3 |
| **Total** | | **~33** |

## Complexity Tracking

Aucune violation de la constitution. Pas de tracking nécessaire.
