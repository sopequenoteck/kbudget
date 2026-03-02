# Tasks: Shared Design Tokens

**Input**: Design documents from `/specs/063-shared-design-tokens/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Non demandes dans la spec. Verification par compilation (ng build, flutter analyze).

**Organization**: Tasks grouped by user story. US1+US4 (P1) fusionnees car la couleur secondaire fait partie du document de reference.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

---

## Phase 1: Foundational — Document de Reference (US1 + US4, Priority: P1)

**Goal**: Creer le document de reference unique listant tous les design tokens partages, incluant la palette Indigo secondaire complete.

**Independent Test**: Le document `docs/design-tokens.md` existe, couvre les 7 categories (couleurs, typo, spacing, radius, ombres, animations, platform-specific), et les valeurs correspondent exactement a data-model.md et research.md.

- [X] T001 [US1] Create complete reference document in `docs/design-tokens.md` with all 7 token categories (colors with Indigo palette per research.md R2, typography, spacing, radius, shadows, animations) plus semantic tokens light/dark and platform-specific section per data-model.md. Include a "Migration Guide" section listing all renamed/changed tokens with old→new mapping (e.g., subscription: #2563eb→#8B5CF6, debt-owe Flutter: amber→red, debt-owed Flutter: blue→green, easeInOut→easeDefault)

**Checkpoint**: Reference document ready. Values source: data-model.md (complete taxonomy), research.md R1 (best-of-both decisions), research.md R2 (Indigo palette + WCAG). US2/US3 implementation can now begin.

---

## Phase 2: Angular Tokens (US2, Priority: P2)

**Goal**: Mettre a jour les fichiers SCSS Angular pour refleter exactement les valeurs du document de reference.

**Independent Test**: `cd app && ng build` compile sans erreur. Les CSS variables correspondent au document de reference.

- [X] T002 [US2] Update SCSS primitives in `app/src/styles/tokens/_primitives.scss` — add Indigo palette ($indigo-50 to $indigo-900 per research.md R2), add $space-9: 2.25rem and $space-11: 2.75rem, add $radius-xxl: 1.5rem, change $subscription from #2563eb to #8B5CF6 (violet-500), add $subscription-light: #f5f3ff, add $violet-400: #a78bfa and $violet-500: #8b5cf6
- [X] T003 [US2] Update CSS custom properties in `app/src/styles/tokens/_tokens.scss` — expose all new Indigo primitives as --indigo-50 through --indigo-900, add --indigo-600-rgb for transparency, add --space-9, --space-11, add --radius-xxl, add --color-subscription-raw with violet value
- [X] T004 [P] [US2] Update light theme in `app/src/styles/themes/_light.scss` — add secondary tokens (--color-secondary: var(--indigo-600), --color-secondary-hover: var(--indigo-700), --color-secondary-light: var(--indigo-100), --color-secondary-contrast: #ffffff), change --color-subscription from #2563eb to #8B5CF6
- [X] T005 [P] [US2] Update dark theme in `app/src/styles/themes/_dark.scss` — add secondary tokens (--color-secondary: var(--indigo-400), --color-secondary-hover: var(--indigo-300), --color-secondary-light: var(--indigo-900), --color-secondary-contrast: var(--gray-900)), change --color-subscription from #60a5fa to #A78BFA
- [X] T006 [US2] Verify Angular build passes: `cd app && ng build`

**Checkpoint**: Angular tokens harmonized. All SCSS values match docs/design-tokens.md.

---

## Phase 3: Flutter Tokens (US3, Priority: P2)

**Goal**: Mettre a jour les constantes Dart et le theme Flutter pour refleter exactement les valeurs du document de reference. Implementer reduced-motion.

**Independent Test**: `cd flutter && flutter analyze` sans erreur et `flutter test` passe. Les constantes Dart correspondent au document de reference.

### Constants (parallel — different files, no inter-dependencies)

- [X] T007 [P] [US3] Update colors in `flutter/lib/src/constants/app_colors.dart` — add Indigo palette (indigo50 through indigo900 per research.md R2), change warning from 0xFFF59E0B to 0xFFEAB308 (yellow-500), change success from 0xFF10B981 to 0xFF22C55E (green-500), add warningLight: 0xFFFEF9C3, successLight: 0xFFDCFCE7, errorLight: 0xFFFEE2E2, infoLight: 0xFFDBEAFE, add textSuccess/textError/textWarning/textInfo for light, change incomeLight from 0xFF10B981 to 0xFF16A34A, change expenseLight from 0xFFEF4444 to 0xFFDC2626, change debtOweLight from 0xFFF59E0B to 0xFFDC2626, change debtOwedLight from 0xFF3B82F6 to 0xFF16A34A, change incomeDark from 0xFF34D399 to 0xFF4ADE80, change debtOweDark from 0xFFFBBF24 to 0xFFF87171, change debtOwedDark from 0xFF60A5FA to 0xFF4ADE80, add violet400: 0xFFA78BFA and violet500: 0xFF8B5CF6 (needed by T012 for subscriptionColor)
- [X] T008 [P] [US3] Update typography in `flutter/lib/src/constants/app_typography.dart` — add lineHeightTight: 1.25, lineHeightNormal: 1.5, lineHeightRelaxed: 1.75, add fontMono: 'monospace' (Flutter uses platform monospace)
- [X] T009 [P] [US3] Update shadows in `flutter/lib/src/constants/app_shadows.dart` — change md to BoxShadow(offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1, color: Color(0x1A000000)), change lg to BoxShadow(offset: Offset(0, 10), blurRadius: 15, spreadRadius: -3, color: Color(0x1A000000)), change colored to offset: Offset(0, 8), blurRadius: 24, spreadRadius: -4, alpha 0.4 (light) / 0.35 (dark) per research.md R4 and data-model.md — Flutter colored shadow method must accept theme-aware alpha (102 light, 89 dark)
- [X] T010 [P] [US3] Update animations in `flutter/lib/src/constants/app_durations.dart` — add static Duration resolve(Duration duration, BuildContext context) method per research.md R3, rename easeInOut to easeDefault (keep alias for backward compat), ensure easeIn and easeOut match Angular values

### Theme (depends on T007 for AppColors.indigo*)

- [X] T011 [US3] Update theme in `flutter/lib/src/theme/app_theme.dart` — set ColorScheme.secondary to AppColors.indigo600 (light) / indigo400 (dark), set ColorScheme.onSecondary to white (light) / gray900 (dark), set ColorScheme.secondaryContainer to indigo100 (light) / indigo800 (dark), fix dark ColorScheme.error to Color(0xFFF87171) (red-400), replace hardcoded BorderRadius.circular(12) with AppRadius.lg, replace hardcoded BorderRadius.circular(8) with AppRadius.md, replace hardcoded EdgeInsets values with AppSpacing constants where applicable
- [X] T012 [US3] Update theme extension in `flutter/lib/src/theme/app_theme_extension.dart` — harmonize 5 business colors to match research.md R1 decisions (incomeColor, expenseColor, debtOweColor, debtOwedColor, subscriptionColor for both light and dark), add secondaryColor property (indigo600 light / indigo400 dark)
- [X] T013 [US3] Verify Flutter passes: `cd flutter && flutter analyze` and `cd flutter && flutter test`

**Checkpoint**: Flutter tokens harmonized. All Dart constant values match docs/design-tokens.md.

---

## Phase 4: Cross-Platform Verification (US5, Priority: P3)

**Goal**: Verifier que les valeurs sont identiques entre les 3 artefacts (reference, SCSS, Dart).

**Independent Test**: Audit systematique token par token entre les 3 fichiers. Zero divergence = success.

- [X] T014 [US5] Cross-platform token value audit — systematically compare every primitive and semantic token value across docs/design-tokens.md, Angular SCSS files (app/src/styles/tokens/ + themes/), and Flutter Dart files (flutter/lib/src/constants/ + theme/) to confirm SC-001 (100% identical primitives) and SC-006 (zero inconsistencies). Additionally, grep all usages of debtOweColor, debtOwedColor, and subscriptionColor in Flutter widgets to verify semantic coherence after palette changes (amber/blue→red/green for debt, blue→violet for subscription)
- [X] T015 [US5] WCAG AA contrast verification for Indigo secondary — verify indigo-600 on white >= 4.5:1 and indigo-400 on #111827 >= 4.5:1 per SC-003, verify all feedback and business text colors meet AA ratios per research.md R1

**Checkpoint**: All 6 success criteria (SC-001 to SC-006) validated.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [X] T016 Sync documentation — update CLAUDE.md and README.md to reflect design tokens harmonization (mention docs/design-tokens.md as reference, updated token categories)

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Foundational: US1+US4)
    │
    ├──→ Phase 2 (Angular: US2)  ──┐
    │                               ├──→ Phase 4 (Verification: US5) → Phase 5 (Polish)
    └──→ Phase 3 (Flutter: US3)  ──┘
```

- **Phase 1**: No dependencies — start immediately
- **Phase 2 + Phase 3**: Both depend on Phase 1 completion. **CAN RUN IN PARALLEL** (different stacks, different files)
- **Phase 4**: Depends on BOTH Phase 2 and Phase 3 completion
- **Phase 5**: Depends on Phase 4 completion

### Within Phase 2 (Angular)

```
T002 (_primitives.scss) → T003 (_tokens.scss) → T004[P] + T005[P] (_light + _dark) → T006 (verify)
```

### Within Phase 3 (Flutter)

```
T007[P] + T008[P] + T009[P] + T010[P] (constants) → T011 + T012 (theme) → T013 (verify)
```

### Parallel Opportunities

- **Phase 2 and Phase 3** are fully independent (Angular vs Flutter) — run in parallel
- **T004 and T005** (light + dark themes) — different files, parallel
- **T007, T008, T009, T010** (Flutter constants) — all different files, parallel
- **T011 and T012** could be parallel but T012 is small and T011 uses same AppColors

---

## Parallel Example: Flutter Constants

```bash
# Launch all Flutter constant updates in parallel (Phase 3, first batch):
Task T007: "Update colors in flutter/lib/src/constants/app_colors.dart"
Task T008: "Update typography in flutter/lib/src/constants/app_typography.dart"
Task T009: "Update shadows in flutter/lib/src/constants/app_shadows.dart"
Task T010: "Update animations in flutter/lib/src/constants/app_durations.dart"

# Then sequentially (depends on T007):
Task T011: "Update theme in flutter/lib/src/theme/app_theme.dart"
Task T012: "Update theme extension in flutter/lib/src/theme/app_theme_extension.dart"
```

---

## Implementation Strategy

### MVP First (Phase 1 Only)

1. Complete Phase 1: Reference document → **deliverable independant**
2. **STOP and VALIDATE**: document couvre 7 categories, Indigo palette complète, WCAG check

### Incremental Delivery

1. Phase 1 → Reference document ready (US1+US4 done)
2. Phase 2 → Angular harmonized → `ng build` passes (US2 done)
3. Phase 3 → Flutter harmonized → `flutter analyze` passes (US3 done)
4. Phase 4 → Cross-platform audit → Zero divergences (US5 done)
5. Phase 5 → Documentation sync

### Recommended: Parallel Angular + Flutter

1. Complete Phase 1 (reference document)
2. Launch Phase 2 (Angular) and Phase 3 (Flutter) **in parallel**
3. After both complete → Phase 4 verification
4. Phase 5 polish

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- No backend changes — this is a frontend-only feature
- Sources of truth for values: data-model.md (taxonomy), research.md R1 (best-of-both), research.md R2 (Indigo)
- Commit after each phase checkpoint
- Key risk: Flutter debt color semantic change (amber/blue → red/green) — verify all widgets using debtOweColor/debtOwedColor remain coherent
