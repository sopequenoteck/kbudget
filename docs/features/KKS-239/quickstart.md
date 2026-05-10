# Quickstart — KKS-239 : BottomSheet4RowsWidget composable

> Date : 2026-05-10
> Issue : KKS-239

---

## Pré-requis

- [ ] Constitution lue (`docs/constitution.md`)
- [ ] Spec validée (`docs/features/KKS-239/spec.md` — review PASS ×2)
- [ ] Research complétée (`docs/features/KKS-239/research.md`)
- [ ] Plan approuvé (`docs/features/KKS-239/plan.md`)
- [ ] Branche active : `feature/bottom-sheet-4-rows-widget`

---

## Phase 1 — Prérequis : token errorContainer

### Fichier à modifier

```
flutter/lib/src/theme/app_theme.dart
```

### Étapes

1. Dans `ColorScheme.light(...)`, ajouter après `onError: Colors.white,` :
   ```dart
   errorContainer: AppColors.errorLight,
   ```

2. Dans `ColorScheme.dark(...)`, ajouter après `onError: Colors.white,` :
   ```dart
   errorContainer: const Color(0x1AEF4444),
   ```

**Vérification** :
```bash
cd flutter && dart analyze lib/src/theme/app_theme.dart
```
Aucune erreur attendue.

---

## Phase 2 — Fichier widget principal

### Fichier à créer

```
flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart
```

### Ordre d'implémentation dans le fichier

1. Imports (material, phosphor, constants, theme)
2. `enum BSheetSubmitVariant { primary, danger }`
3. `enum _BSheetActionPillVariant { primary, cancel, danger, status, loading }` (privé)
4. `class _BSheetHandle extends StatelessWidget`
5. `class _BSheetActionPill extends StatelessWidget`
6. `class _BSheetErrorBanner extends StatelessWidget`
7. `class BottomSheet4RowsWidget extends StatelessWidget` (widget principal avec doc `///`)

### Vérification après T-5

```bash
cd flutter && dart analyze lib/src/common_widgets/bottom_sheet_4_rows_widget.dart
# exit 0 attendu

grep -nE "Color\(0x|#[0-9a-fA-F]{6,8}" lib/src/common_widgets/bottom_sheet_4_rows_widget.dart
# 0 résultats attendus (SC-009)
```

---

## Phase 3 — Tests

### Fichier à créer

```
flutter/test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart
```

### Structure recommandée

```dart
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/theme_test_helpers.dart';
// ...

Future<void> pumpWidget(WidgetTester tester, ThemeData theme, {
  // paramètres optionnels pour les variantes de test
}) async { ... }

void main() {
  // SC-001 — 4 rows keys présentes (× 2 thèmes)
  forEachTheme((theme, name) {
    testWidgets('should_render_4_rows_keys_when_minimal_slots_$name', ...);
  });

  // SC-002 — slots injectés présents (3 variantes × 2 thèmes)
  forEachTheme((theme, name) {
    testWidgets('should_render_injected_slots_unchanged_transaction_like_$name', ...);
    testWidgets('should_render_injected_slots_unchanged_subscription_like_$name', ...);
    testWidgets('should_render_injected_slots_unchanged_debt_like_$name', ...);
  });

  // SC-003 — AnimatedSize sur expand (× 2 thèmes)
  // SC-004 — loading spinner + callback bloqué (× 2 thèmes)
  // SC-005 — errorMessage bandeau couleurs (× 2 thèmes)
  // SC-006 — loading + errorMessage coexistence (× 2 thèmes)
  // SC-007 — footerLeading à gauche (× 2 thèmes)
  // SC-008 — footerEnabled: false bloque callbacks (× 2 thèmes)
  // SC-012 — 3 hauteurs sans overflow (× 2 thèmes)
  // SC-013 — notePreview null vs non-null (× 2 thèmes)
  // SC-014 — footerLeading 3 cas (× 2 thèmes)
}
```

### Commande de test

```bash
cd flutter && flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart --reporter=expanded
```

---

## Phase 4 — Polish & validation

1. **Analyse statique** :
   ```bash
   cd flutter && flutter analyze
   ```

2. **Grep no-hex** (SC-009) :
   ```bash
   grep -nE "Color\(0x|#[0-9a-fA-F]{6,8}" flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart
   # 0 résultats attendus
   ```

3. **Suite complète** :
   ```bash
   cd flutter && flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart
   # exit 0 attendu
   ```

4. **Review documentation** (SC-011) :
   ```bash
   cd flutter && dart doc lib/src/common_widgets/bottom_sheet_4_rows_widget.dart
   # Vérifier que l'exemple Transaction-like apparaît dans la doc générée
   ```

---

## Commandes utiles

| Action | Commande |
|--------|----------|
| Tests du widget | `cd flutter && flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart` |
| Tous les tests common_widgets | `cd flutter && flutter test test/src/common_widgets/` |
| Analyse statique | `cd flutter && flutter analyze` |
| Code generation (si besoin) | `cd flutter && dart run build_runner build --delete-conflicting-outputs` |

---

## Checklist finale

- [ ] `app_theme.dart` : `errorContainer` ajouté light (`AppColors.errorLight`) + dark (`Color(0x1AEF4444)`)
- [ ] `bottom_sheet_4_rows_widget.dart` : `dart analyze` exit 0
- [ ] Grep no-hex : 0 résultats
- [ ] Tests flutter : exit 0, ≥ 10 tests (5 SC × 2 thèmes minimum)
- [ ] Keys structurelles toutes présentes : `bsheet_top`, `bsheet_main_row`, `bsheet_meta_row`, `bsheet_bottom_row`, `bsheet_submit`, `bsheet_cancel`, `bsheet_error_banner`, `bsheet_expand`, `bsheet_note_preview`
- [ ] Documentation `///` : exemple Transaction-like présent dans la classe
- [ ] Pas de `print()` ni `debugPrint()` laissés
- [ ] Pre-commit review passé
