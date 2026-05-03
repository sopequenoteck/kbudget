# Implementation Plan: Widget SelectPicker

**Branch**: `039-flutter-selectpicker-widget` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/039-flutter-selectpicker-widget/spec.md`

## Summary

Widget Flutter de sélection générique à bottom sheet, implémentant `FormField<String?>` pour l'intégration native dans les formulaires. Le trigger adopte le style visuel d'AppFormField (label, conteneur arrondi, erreur). La liste est affichée via AppModal avec recherche optionnelle, clearable, et affichage riche des items (icône, couleur, texte secondaire). Un seul fichier source + un fichier de tests.

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter (SDK), AppModal (feature 036), design tokens existants
**Storage**: N/A (composant UI pur, pas de persistance)
**Testing**: flutter_test (widget tests)
**Target Platform**: iOS / Android (mobile-first), tablette (dialog via AppModal)
**Project Type**: mobile
**Performance Goals**: 60 fps pour les cas d'usage typiques (< 50 items via Column + SingleChildScrollView d'AppModal). Listes 100+ items : optimisation future si besoin confirmé (cf. research.md R5)
**Constraints**: Composant UI pur, pas de dépendance externe au SDK Flutter
**Scale/Scope**: 1 widget réutilisable, 2 fichiers (source + test)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Composant frontend pur, pas d'endpoint API |
| II. Sécurité par défaut | N/A | Pas de données sensibles ni d'authentification |
| III. Simplicité & YAGNI | PASS | Un seul fichier, pas d'abstractions (pas de freezed, pas de generics inutiles). Classe simple pour le modèle. |
| IV. Mobile-First UX | PASS | Bottom sheet natif via AppModal, sélection en 2 taps, clearable en 1 tap |
| V. Testabilité | PASS | Widget testable via flutter_test, pattern Arrange-Act-Assert, nommage `should_X_when_Y` |
| VI. Observabilité | N/A | Widget UI, pas de logging requis |
| VII. Self-Hosted Ready | N/A | Composant frontend, pas de dépendance infra |

**Gate result**: PASS (aucune violation)

### Post-Phase 1 Re-check

| Principe | Statut | Note |
|----------|--------|------|
| III. Simplicité & YAGNI | PASS | Architecture en 1 fichier, modèle non-freezed, pas de wrapper inutile |
| IV. Mobile-First UX | PASS | Recherche auto au-dessus du seuil, clearable, feedback visuel immédiat |
| V. Testabilité | PASS | Chaque user story testable indépendamment via widget tests |

## Project Structure

### Documentation (this feature)

```text
specs/039-flutter-selectpicker-widget/
├── plan.md              # This file
├── research.md          # Phase 0 output (6 décisions techniques)
├── data-model.md        # Phase 1 output (SelectPickerItem + API)
├── quickstart.md        # Phase 1 output (usage + commandes)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/
├── lib/src/common_widgets/
│   ├── select_picker.dart          # SelectPickerItem + SelectPicker (NEW)
│   ├── app_modal.dart              # Dépendance (existant)
│   ├── app_form_field.dart         # Référence visuelle (existant)
│   └── segmented_filter.dart       # Pattern de référence (existant)
└── test/src/common_widgets/
    └── select_picker_test.dart     # Tests widget (NEW)
```

**Structure Decision**: Widget unique dans `common_widgets/` (cohérent avec les 11 widgets existants). Pas de sous-dossier — le widget tient en un seul fichier comme SegmentedFilter, AppToggle, etc.

## Design

### Architecture du widget

```
SelectPicker extends FormField<String?>
│
├── _SelectPickerState extends FormFieldState<String?>
│   ├── _searchQuery — géré localement via StatefulBuilder dans le modal (éphémère, reset à chaque ouverture)
│   ├── didUpdateWidget() — auto-reset si selectedId absent des items
│   ├── _openModal() — AppModal.show() avec recherche + liste
│   ├── _onItemSelected(String id) — didChange() + onChanged()
│   └── _onClear() — didChange(null) + onChanged(null)
│
├── builder → construit le trigger
│   ├── Label (Text, sm, medium, onSurfaceVariant) — style AppFormField
│   ├── Conteneur (surfaceContainerHighest, radius xl) — style AppFormField
│   │   ├── Item sélectionné : [icône?] [pastille?] label [secondaryText?]
│   │   ├── Ou placeholder (texte atténué)
│   │   └── Trailing : bouton × (clearable) ou chevron ▼
│   └── Message d'erreur (AnimatedSize, sizeXs, error color) — style AppFormField
│
└── Contenu modal (via AppModal.show)
    ├── headerActions → TextField de recherche (si applicable)
    └── child → Column des items (scroll géré par AppModal SingleChildScrollView)
        ├── Chaque item : [icône?] [pastille?] label [secondaryText?] [check si sélectionné]
        └── Si items vide : emptyMessage centré
```

### Détail des composants internes

**Trigger** (reproduit le style AppFormField) :
- Label au-dessus : `TextStyle(fontSize: sizeSm, fontWeight: medium, color: onSurfaceVariant)`
- Conteneur : `BoxDecoration(color: surfaceContainerHighest, borderRadius: xl)`, padding `space3` vertical / `space4` horizontal
- État disabled : opacité réduite (0.5), GestureDetector désactivé
- Erreur : `AnimatedSize` avec texte en `sizeXs` / `error` color

**Item dans la liste** :
- Hauteur : `space12` (48dp) — standard Material pour les items tappables
- Layout Row : [icône 24dp?] [pastille 12dp?] [gap space3] [label Expanded] [secondaryText?]
- Item sélectionné : `color: primary.withValues(alpha: 0.08)` (fond distinct)
- Séparateur : aucun (espacement naturel)

**Recherche** :
- `TextField` avec `InputDecoration.collapsed` dans un conteneur stylé
- Placé dans `headerActions` d'AppModal (fixe, ne scroll pas)
- Filtre `items.where((item) => item.label.toLowerCase().contains(query.toLowerCase()))`
- Reset à chaque ouverture du modal

### Flux de données

```
Parent (Form)
  │
  ├── selectedId ──→ SelectPicker.initialValue ──→ FormFieldState.value
  │                                                      │
  │                                        ┌─────────────┤
  │                                        ▼             ▼
  │                                  Trigger UI    Modal (list)
  │                                        │             │
  │                                   tap trigger    tap item
  │                                        │             │
  │                                   _openModal    _onItemSelected(id)
  │                                                      │
  │                                              state.didChange(id)
  │                                                      │
  ├── onChanged(id) ◄────────────────────────────────────┘
  │
  └── Form.validate() → validator(state.value) → errorText → trigger UI
```

## Complexity Tracking

> Aucune violation de la constitution. Pas de justification requise.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
