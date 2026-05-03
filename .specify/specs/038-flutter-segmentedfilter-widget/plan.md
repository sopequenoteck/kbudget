# Implementation Plan: Widget filtres segmentés (SegmentedFilter)

**Branch**: `038-flutter-segmentedfilter-widget` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/038-flutter-segmentedfilter-widget/spec.md`

## Summary

Widget Flutter réutilisable de type iOS Segmented Control pour filtrer les listes de données (transactions, abonnements, dettes). StatelessWidget contrôlé avec API générique typée (`SegmentedFilter<T>`), cross-fade animé, support thèmes clair/sombre via ColorScheme Material 3, et sémantique d'accessibilité. Se place dans `common_widgets/` aux côtés des widgets existants (AppToggle, MonthSelector, ListItem).

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter (SDK)
**Storage**: N/A (widget UI pur, pas de persistance)
**Testing**: flutter_test (SDK), pattern `pumpWidget` avec `MaterialApp` + `AppTheme.light/dark`
**Target Platform**: iOS, Android (Flutter multiplateforme)
**Project Type**: Mobile
**Performance Goals**: Animations 60 fps, transition cross-fade 120ms
**Constraints**: Widget stateless contrôlé, 2-5 segments, pleine largeur
**Scale/Scope**: 1 widget + 1 classe modèle + ~20-30 tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Applicable | Statut | Notes |
|----------|------------|--------|-------|
| I. API-First | Non | N/A | Widget UI pur, pas d'endpoint REST |
| II. Sécurité par défaut | Non | N/A | Pas de données sensibles |
| III. Simplicité & YAGNI | Oui | PASS | StatelessWidget simple, pas de pattern complexe, 1 fichier widget + 1 classe modèle |
| IV. Mobile-First UX | Oui | PASS | Interaction tap rapide, pleine largeur mobile |
| V. Testabilité | Oui | PASS | Widget testable via flutter_test, assertions constructeur, pattern Arrange-Act-Assert |
| VI. Observabilité | Non | N/A | Widget UI pur, pas de logging |
| VII. Self-Hosted Ready | Non | N/A | Widget UI pur, pas d'infra |

**Gate result**: PASS — aucune violation.

**Post-Phase 1 re-check**: PASS — le design reste simple (1 StatelessWidget, 1 classe item, cross-fade via AnimatedContainer/AnimatedDefaultTextStyle).

## Project Structure

### Documentation (this feature)

```text
specs/038-flutter-segmentedfilter-widget/
├── plan.md
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
flutter/lib/src/common_widgets/
├── segmented_filter.dart          # Widget SegmentedFilter<T> + classe SegmentedFilterItem<T>
├── app_toggle.dart                # (existant, distinct)
├── month_selector.dart            # (existant)
├── app_form_field.dart            # (existant)
├── list_item.dart                 # (existant)
└── app_modal.dart                 # (existant)

flutter/test/src/common_widgets/
└── segmented_filter_test.dart     # Tests widget (~20-30 tests)
```

**Structure Decision**: Fichier unique `segmented_filter.dart` dans `common_widgets/` contenant la classe `SegmentedFilterItem<T>` et le widget `SegmentedFilter<T>`. Pattern identique aux autres widgets du projet (1 fichier = 1 widget + ses types associés). Tests dans le miroir `test/src/common_widgets/`.

## Complexity Tracking

> Aucune violation de la constitution — tableau non applicable.
