# Quickstart: Shared Design Tokens

**Feature**: 063-shared-design-tokens | **Date**: 2026-03-01

## Prerequisites

- Node.js (pour Angular CLI)
- Flutter SDK >= 3.27
- Les deux projets compilent sans erreur sur `main`

## Workflow d'implementation

### Ordre obligatoire

```
1. docs/design-tokens.md      (reference unique)
2. Angular tokens             (SCSS primitives + themes)
3. Flutter constants + theme  (Dart)
4. Verification cross-platform
```

### 1. Document de reference

Creer `docs/design-tokens.md` avec toutes les valeurs de `data-model.md`.
Ce fichier est la source de verite — les implementations Angular et Flutter doivent correspondre exactement.

### 2. Angular

Fichiers a modifier :

| Fichier | Modifications |
|---------|--------------|
| `app/src/styles/tokens/_primitives.scss` | Ajouter palette Indigo (50-900), ajouter `$space-9`, `$space-11`, ajouter `$radius-xxl`, ajouter `$subscription` violet |
| `app/src/styles/tokens/_tokens.scss` | Ajouter CSS vars Indigo, ajouter `--space-9`, `--space-11`, ajouter `--radius-xxl` |
| `app/src/styles/themes/_light.scss` | Ajouter tokens secondary, harmoniser business colors (subscription → violet), ajouter `--color-subscription-light` si absent |
| `app/src/styles/themes/_dark.scss` | Idem dark variants |

Verification :
```bash
cd app && ng build
```

### 3. Flutter

Fichiers a modifier :

| Fichier | Modifications |
|---------|--------------|
| `flutter/lib/src/constants/app_colors.dart` | Ajouter palette Indigo (50-900), corriger warning (#eab308 au lieu de amber500), harmoniser business colors, ajouter feedback light backgrounds |
| `flutter/lib/src/constants/app_typography.dart` | Ajouter line heights (tight, normal, relaxed), ajouter fontMono |
| `flutter/lib/src/constants/app_shadows.dart` | Harmoniser md/lg/colored avec reference Angular |
| `flutter/lib/src/constants/app_durations.dart` | Ajouter `resolve()` pour reduced-motion |
| `flutter/lib/src/theme/app_theme.dart` | Integrer Indigo dans ColorScheme.secondary, remplacer hardcoded values par constantes, fix error dark |
| `flutter/lib/src/theme/app_theme_extension.dart` | Harmoniser 5 business colors, ajouter secondaryColor |

Verification :
```bash
cd flutter && flutter analyze && flutter test
```

### 4. Verification cross-platform

- Comparer visuellement les valeurs du document de reference avec les fichiers SCSS et Dart
- Build Angular : `cd app && ng build`
- Build Flutter : `cd flutter && flutter build apk --debug` (ou `flutter run`)
- Verifier que les 6 criteres de succes (SC-001 a SC-006) sont satisfaits

## Points d'attention

1. **Flutter warning collision** : `AppColors.warning` est actuellement `#F59E0B` = `amber500` = primary. Changer en `#eab308` (yellow-500).
2. **Flutter error dark** : `ColorScheme.error` est identique en light et dark. Adapter en dark (`#f87171`).
3. **Flutter hardcoded values** : `app_theme.dart` utilise `BorderRadius.circular(12)` au lieu de `AppRadius.lg`. Remplacer par les constantes.
4. **Subscription color change** : Angular passe de blue (#2563eb) a violet (#8B5CF6). Flutter conserve violet mais change la valeur exacte si necessaire.
5. **Debt colors change** : Flutter change completement la semantique (amber/blue → red/green). Verifier que tous les widgets utilisant `debtOweColor` / `debtOwedColor` restent coherents.
