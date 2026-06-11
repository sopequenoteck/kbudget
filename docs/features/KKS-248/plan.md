# Implementation Plan: Catégories formulaire Flutter (alignement DESIGN.md v5)

**Issue**: KKS-248 | **Branch**: `feature/flutter-screens-medium-v5` | **Date**: 2026-05-14  
**Spec**: [spec.md](spec.md)

---

## Summary

Alignement du formulaire catégorie Flutter sur DESIGN.md v5 en suivant la source de vérité Angular. Deux modifications concrètes : suppression de `CategoryPreviewCard` (absente dans Angular) et audit des tokens v5 sur les widgets concernés. Aucun nouveau composant, aucun changement de logique métier ou d'API publique.

---

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27  
**Primary Dependencies**: flutter_riverpod, AppSpacing, AppTypography, AppColors, AppRadius (tokens v5)  
**Storage**: N/A (pas de modification de données)  
**Testing**: flutter_test (tests widget existants à préserver)  
**Target Platform**: iOS + Android (Trajectoire B — Standalone Commercial)  
**Project Type**: Mobile app  
**Performance Goals**: N/A (refonte purement visuelle)  
**Constraints**: API publique `CategoryFormWidgetState.submit()` et `initialName` non modifiables

---

## Constitution Check

| Principe | Applicable | Statut | Notes |
|----------|-----------|--------|-------|
| I — API-First / Local-First | Non | ✅ N/A | Aucun endpoint modifié, aucune donnée |
| II — Sécurité | Non | ✅ N/A | Pas de routes, pas de secrets |
| III — Simplicité & YAGNI | Oui | ✅ PASS | Suppression de `CategoryPreviewCard` = simplification nette |
| IV — Mobile-First UX | Oui | ✅ PASS | Alignement tokens v5 = amélioration fidélité design |
| V — Testabilité | Oui | ✅ PASS | API publique inchangée, tests existants doivent passer |
| VI — Observabilité | Oui | ✅ PASS | Aucun `print()` à introduire |
| VII — Two Trajectories | Non | ✅ N/A | Trajectoire B uniquement, pas d'impact sync |

**Résultat : PASS — aucune gate violée.**

---

## Architecture — Fichiers impactés

### Modifications (M)

| Fichier | Nature | FR couverts |
|---------|--------|-------------|
| `flutter/lib/src/features/categories/presentation/widgets/category_form_widget.dart` | Supprimer import + usage `CategoryPreviewCard`. Audit valeurs hardcodées. | FR-008, FR-009 |
| `flutter/lib/src/common_widgets/color_palette_picker.dart` | Remplacer `width: 36, height: 36` par token `AppSpacing` si disponible — sinon documenter. | FR-008 |

### Vérification sans modification attendue

| Fichier | Vérification |
|---------|-------------|
| `flutter/lib/src/common_widgets/app_form_field.dart` | Conforme tokens v5 (vérifié) — aucune action |
| `flutter/lib/src/common_widgets/emoji_input.dart` | Audit tokens v5 à confirmer |
| `flutter/lib/src/features/categories/presentation/screens/category_form_screen.dart` | Audit tokens v5 à confirmer |
| `flutter/lib/src/common_widgets/category_select_expand.dart` | Vérifier que le rendu embedded hérite correctement du design modifié |
| `flutter/lib/src/features/categories/presentation/widgets/category_preview_card.dart` | Vérifier si utilisée ailleurs avant de supprimer l'import |

### Aucun fichier à créer

---

## Approche détaillée par composant

### 1. Suppression de `CategoryPreviewCard` — `category_form_widget.dart`

**FR couverts** : FR-009

- Supprimer `import 'package:k_budget/src/features/categories/presentation/widgets/category_preview_card.dart'`
- Supprimer le widget `CategoryPreviewCard(...)` dans `build()` et le `SizedBox` spacer qui le suivait
- Vérifier que `CategoryPreviewCard` n'est pas utilisée dans d'autres fichiers avant de toucher au fichier lui-même (`grep -r "CategoryPreviewCard"`)
- Après suppression, l'ordre visuel devient : Emoji + Color row → champ Nom

**Vérification** : SC-006 — les tests widget existants passent sans modification de leur API.

---

### 2. Audit tokens v5 — `category_form_widget.dart`

**FR couverts** : FR-008

État actuel (d'après lecture du code) :
- `AppSpacing.space4`, `AppSpacing.space6` ✅ tokens
- `AppTypography.sizeMd` ✅ token
- `colorScheme.onSurface` ✅ ThemeData token

Vérifications restantes :
- S'assurer qu'aucune valeur pixel hardcodée ne subsiste après la suppression de `CategoryPreviewCard`
- Grep : `grep -n '[0-9]\+\.0\|width:\|height:\|fontSize:' category_form_widget.dart`

---

### 3. Audit tokens v5 — `color_palette_picker.dart`

**FR couverts** : FR-004, FR-008

Valeur hardcodée identifiée :
```dart
width: 36,
height: 36,
```

Action : vérifier si `AppSpacing` expose une constante `space9` (36px = 9 × 4px base). Si oui → remplacer. Si non → documenter dans Complexity Tracking (valeur sémantique liée au rendu visuel des swatches, pas à l'espacement).

**Attention** : `ColorPalettePicker` est un `common_widget` partagé — tout changement impacte tous ses usages dans l'app. Audit des usages via `grep -r "ColorPalettePicker"` avant modification.

---

### 4. Vérification mode embedded — `category_select_expand.dart`

**FR couverts** : NFR-002

`CategorySelectExpand` embarque `CategoryFormWidget` via `GlobalKey<CategoryFormWidgetState>`. Le rendu visuel de `CategoryFormWidget` modifié (sans `CategoryPreviewCard`) s'applique automatiquement en mode embedded.

Vérification : ouvrir le mode création inline dans `CategorySelectExpand` et confirmer que l'affichage est cohérent (pas de padding cassé, pas d'espace vide là où était la preview card).

---

## Risques & Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| `CategoryPreviewCard` utilisée ailleurs → import cassé | Faible | Bloquant | `grep -r "CategoryPreviewCard"` avant suppression |
| Tests widget vérifient la présence de `CategoryPreviewCard` | Moyenne | Bloquant | Lire `category_form_widget_test.dart` avant modification |
| Modification `ColorPalettePicker` (widget partagé) → régression visuelle sur autres écrans | Faible | Moyen | Scope limité : uniquement si `AppSpacing` a le token exact. Sinon documentation uniquement. |
| Mode embedded `CategorySelectExpand` — layout cassé après suppression preview | Faible | Moyen | Test visuel manuel après modification |

---

## Hors scope

- Toute modification de la logique métier (validation, submit, CRUD)
- Extraction de nouveaux widgets dans `common_widgets/`
- Modification de `CategoryPreviewCard` (fichier source) — uniquement son usage dans `CategoryFormWidget`
- Color picker hex libre → KKS-256
- Modification de l'API publique `CategoryFormWidgetState`

---

## Complexity Tracking

Aucune violation de gate. Aucune complexité ajoutée.

| Éventuel | Justification |
|----------|--------------|
| `width: 36, height: 36` dans `ColorPalettePicker` si non remplaçable par token | Valeur sémantique liée au rendu visuel des swatches (taille d'interaction tactile standard 36px). Pas un espacement de layout. Acceptable si `AppSpacing` ne couvre pas ce cas. |
