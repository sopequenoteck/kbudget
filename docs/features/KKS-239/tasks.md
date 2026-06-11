# Tasks — KKS-239 : Phase 1 / Étape 3 — BottomSheet4RowsWidget composable

> Date : 2026-05-10
> Issue : KKS-239
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

---

## Phase 1 : Setup

- [x] [T-001] [P1] Vérifier l'état de la branche `feature/bottom-sheet-4-rows-widget` et confirmer que KKS-238 est bien mergé sur main (dépendances `InlineDatePicker`, `CategorySelectExpand`, `forEachTheme` helper) — Réf: NFR-004, Dépendances KKS-237+KKS-238

**Checkpoint** : `git log --oneline main | head -5` contient le commit KKS-238. `flutter analyze` passe sans erreur sur la branche courante.

---

## Phase 2 : Fondations (bloquantes)

- [x] [T-010] [P1] `app_theme.dart` — Ajouter `errorContainer: AppColors.errorLight` dans `ColorScheme.light` et `errorContainer: const Color(0x1AEF4444)` dans `ColorScheme.dark`, après `onError: Colors.white` dans chacun — Réf: FR-009, SC-005, RES-003

**Checkpoint** : `cd flutter && dart analyze lib/src/theme/app_theme.dart` exit 0. `colorScheme.errorContainer` résolvable depuis un widget test avec `AppTheme.light` et `AppTheme.dark`.

---

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

- [x] [T-020] [P] [P1] [US-002] Créer `enum BSheetSubmitVariant { primary, danger }` et `enum _BSheetActionPillVariant { primary, cancel, danger, status, loading }` en tête du fichier `bottom_sheet_4_rows_widget.dart`, avec documentation `///` sur chaque valeur — Réf: FR-006, FR-013, NFR-005

- [x] [T-021] [P] [P1] [US-001] Implémenter `_BSheetHandle` (file-scoped) : `Container(width: 36, height: 4)` centré, couleur `onSurfaceVariant×0.4`, `borderRadius: AppRadius.round`, `margin: vertical AppSpacing.s2` — Réf: FR-002, FR-013, FR-015

- [x] [T-022] [P1] [US-002] [US-005] Implémenter `_BSheetActionPill` (file-scoped) : `InkWell + Container(BoxDecoration(border, borderRadius: round))`, 5 variantes via `_BSheetActionPillVariant`, états pressed par variante (`highlightColor`, `splashColor`), variante `loading` avec `CircularProgressIndicator` 16×16 + tap ignoré — Réf: FR-005, FR-006, FR-007, FR-008, FR-013, FR-015, RES-004, RES-005

- [x] [T-023] [P] [P1] [US-004] Implémenter `_BSheetErrorBanner` (file-scoped) : `Container(key: Key('bsheet_error_banner'), color: colorScheme.errorContainer, borderRadius: AppRadius.lg, padding s2/s3)` + `Text(AppTypography.bodySmall, color: colorScheme.error)` — Réf: FR-009, FR-013, FR-015, SC-005

- [x] [T-024] [P1] [US-001] [US-002] [US-003] Implémenter `BottomSheet4RowsWidget` — layout `Column { _BSheetErrorBanner?, Expanded(SingleChildScrollView { Row1(key bsheet_top), Row2(key bsheet_main_row), notePreview?(key bsheet_note_preview), Row3?(key bsheet_meta_row si non vide), AnimatedSize(expandedContent?, key bsheet_expand) }), Row4(key bsheet_bottom_row) }`, API publique complète (tous paramètres FR-005), keys structurelles FR-004, comportements footerLeading/onCancel (CL-002) et Row 3 vide (CL-001) — Réf: FR-001, FR-002, FR-003, FR-004, FR-005, FR-011, FR-014, FR-015, RES-001, RES-002

- [x] [T-025] [P1] [US-001] Ajouter documentation `///` complète sur `BottomSheet4RowsWidget` (classe + chaque paramètre public + `BSheetSubmitVariant`) avec exemple Transaction-like complet (`topTrailing`, `amountField`, `libelleField`, `metaPills`, `expandedContent` piloté par `ValueNotifier<String?>`) ; documenter responsabilité appelant pour clavier (`showModalBottomSheet(isScrollControlled: true)` + `viewInsets.bottom`) et `onExpandClose` + `PopScope` — Réf: FR-012, NFR-005, NFR-006, NFR-007, SC-011

### P2 — Importantes

- [x] [T-030] [P2] [US-004] [US-005] Compléter les comportements d'état dans `BottomSheet4RowsWidget` : `loading: true` → spinner sur Valider + tap ignoré (FR-008) ; `footerEnabled: false` → `Opacity(0.4) + IgnorePointer` sur Row 4 entière (FR-007) ; coexistence `loading + errorMessage` (FR-010) ; `submitVariant: danger` → pill Valider en variante danger (FR-006) — Réf: FR-006, FR-007, FR-008, FR-010, SC-004, SC-006, SC-008

**Checkpoint** : `flutter analyze lib/src/common_widgets/bottom_sheet_4_rows_widget.dart` exit 0. Grep no-hex : `grep -nE "Color\(0x|#[0-9a-fA-F]{6,8}" lib/src/common_widgets/bottom_sheet_4_rows_widget.dart` → 0 résultats (SC-009).

---

## Phase 4 : Polish

- [x] [T-050] [P1] Tests SC-001 à SC-008 dans `bottom_sheet_4_rows_widget_test.dart` via `forEachTheme` : rendu 4 rows (SC-001), slots injectés 3 variantes (SC-002), AnimatedSize expand (SC-003), loading spinner + callback bloqué (SC-004), errorMessage bandeau couleurs (SC-005), loading + errorMessage coexistence (SC-006), footerLeading à gauche (SC-007), footerEnabled:false callbacks bloqués (SC-008) — Réf: SC-001→SC-008, NFR-001

- [x] [T-051] [P2] Tests SC-010/SC-012/SC-013/SC-014 dans `bottom_sheet_4_rows_widget_test.dart` : dark + light via `forEachTheme` (SC-010), 3 hauteurs sans overflow 320/600/900px (SC-012), notePreview null vs non-null (SC-013), footerLeading 3 cas null/[1]/[2] (SC-014) — Réf: SC-010, SC-012, SC-013, SC-014, NFR-001

- [x] [T-052] [P2] Validation finale : `flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart` exit 0 (≥ 10 tests) ; grep no-hex exit 0 (SC-009) ; `flutter analyze` exit 0 ; `dart doc` sur le fichier pour vérifier l'exemple Transaction-like (SC-011) — Réf: SC-009, SC-010, SC-011, NFR-001

**Checkpoint** : `flutter test test/src/common_widgets/bottom_sheet_4_rows_widget_test.dart` exit 0, ≥ 10 tests passés. `flutter analyze` exit 0. Grep no-hex 0 résultats.

---

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances

```
T-001
  └─ T-010 (prérequis errorContainer)
       ├─ T-020 [P] (enums — indépendant après T-001)
       │    └─ T-022 (_BSheetActionPill — utilise _BSheetActionPillVariant)
       ├─ T-021 [P] (_BSheetHandle — indépendant après T-001)
       │    └─ T-024 (widget principal — utilise les 3 sous-widgets)
       ├─ T-023 [P] (_BSheetErrorBanner — utilise colorScheme.errorContainer)
       │    └─ T-024
       └─ T-022 ────────────────────────────────────── T-024
                                                         ├─ T-025 (doc — peut démarrer avec T-024)
                                                         └─ T-030 (états — peut démarrer avec T-024)
                                                              ├─ T-050 (tests SC-001→SC-008)
                                                              │    └─ T-052 (validation finale)
                                                              └─ T-051 (tests SC-010/SC-012→SC-014)
                                                                   └─ T-052
```

### US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US-001 — Squelette 4 rows | T-021, T-024, T-025 | T-010, T-020, T-022, T-023 |
| US-002 — API slots | T-020, T-022, T-024, T-030 | T-010, T-021, T-023 |
| US-003 — Zone expand | T-024 | T-021, T-022, T-023 |
| US-004 — États loading/error | T-023, T-030, T-050 | T-010, T-024 |
| US-005 — Footer configurable | T-022, T-030, T-050 | T-020, T-024 |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|----------------------|-----------|
| G1 | T-020, T-021, T-023 | T-001 complété (T-010 peut démarrer en même temps) |
| G2 | T-025, T-030 | T-024 démarré / en cours |
| G3 | T-050, T-051 | T-024 + T-030 complétés |

---

## Implementation Strategy

### MVP First

- **MVP** : T-001 → T-010 → T-020 + T-021 + T-023 → T-022 → T-024 + T-025
  Livre le squelette composable complet (4 rows, zone expand, footer, documentation) sans tests.
  Valeur : les 3 formulaires (Étape 5) peuvent déjà être prototypés contre l'API.

- **Itération 2** : T-030 — comportements états (loading, footerEnabled, submitVariant danger)
  Valeur : squelette robuste prêt pour usage production.

- **Itération 3** : T-050 + T-051 + T-052 — couverture de tests complète
  Valeur : filet de sécurité pour les refactos Étape 5.

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée |
|-----------|--------|----------------|
| L1 — Setup + Prérequis | T-001, T-010 | Token `errorContainer` disponible, branche prête |
| L2 — Sous-widgets | T-020, T-021, T-022, T-023 | Briques visuelles (handle, pills, bandeau) disponibles |
| L3 — Widget MVP | T-024, T-025 | `BottomSheet4RowsWidget` utilisable par les formulaires |
| L4 — États complets | T-030 | Comportements loading/error/footer robustes |
| L5 — Tests | T-050, T-051, T-052 | Couverture complète, prêt pour review-impl |

---

## Mapping Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (StatelessWidget) | T-024 |
| FR-002 (4 rows structure) | T-021, T-024 |
| FR-003 (AnimatedSize expand) | T-024 |
| FR-004 (keys structurelles) | T-024 |
| FR-005 (API publique slots) | T-022, T-024, T-030 |
| FR-006 (submitVariant danger) | T-020, T-022, T-030 |
| FR-007 (footerEnabled) | T-030 |
| FR-008 (loading spinner) | T-022, T-030 |
| FR-009 (errorMessage bandeau) | T-010, T-023, T-030 |
| FR-010 (loading + error coexistence) | T-030 |
| FR-011 (pas d'instanciation interne) | T-024 |
| FR-012 (documentation example) | T-025 |
| FR-013 (sous-widgets privés) | T-020, T-021, T-022, T-023 |
| FR-014 (topTrailing universel) | T-024 |
| FR-015 (tokens exclusivement) | T-021, T-022, T-023, T-024 |
| FR-016 (dark + light) | T-050, T-051 |
| SC-001 à SC-014 | T-050, T-051 |
| NFR-001 (10 tests min) | T-050, T-051, T-052 |
| NFR-005 (documentation ///) | T-025 |
| NFR-006 (onExpandClose) | T-025 |
| NFR-007 (responsabilité clavier) | T-025 |

---

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| Setup | 1 | 1 | 0 | 0 | 0 |
| Fondations | 1 | 1 | 0 | 0 | 0 |
| User Stories P1 | 6 | 6 | 0 | 0 | 3 (T-020, T-021, T-023) |
| User Stories P2 | 1 | 0 | 1 | 0 | 0 |
| Polish | 3 | 1 | 2 | 0 | 2 (T-050, T-051) |
| **Total** | **12** | **9** | **3** | **0** | **5** |
