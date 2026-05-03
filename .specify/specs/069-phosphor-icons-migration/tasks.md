# Tasks: Migration Phosphor Icons

**Input**: Design documents from `/specs/069-phosphor-icons-migration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Non demandes dans la spec — verification par grep automatise et inspection visuelle.

**Organization**: Tasks groupees par user story pour implementation independante.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Installation des packages et creation de l'inventaire

- [x] T001 [P] Installer `@ng-icons/core` et `@ng-icons/phosphor-icons` dans `app/package.json` via `cd app && npm install @ng-icons/core @ng-icons/phosphor-icons`
- [x] T002 [P] Ajouter `phosphor_flutter: ^2.1.0` dans `flutter/pubspec.yaml` et lancer `cd flutter && flutter pub get`
- [x] T003 Creer l'inventaire complet des icones dans `specs/069-phosphor-icons-migration/icon-mapping.md` — mapper chaque icone systeme existante (emojis Angular + Material Icons Flutter) vers son equivalent Phosphor avec le style et la taille cibles

**Checkpoint**: Packages installes, inventaire documente — pret pour la migration.

---

## Phase 2: Foundational (Composants partages)

**Purpose**: Migrer les composants partages en priorite car ils impactent plusieurs ecrans

**CRITICAL**: Ces composants sont utilises partout — les migrer d'abord evite les conflits.

- [x] T004 [P] Migrer les icones systeme dans `flutter/lib/src/common_widgets/app_modal.dart` — remplacer `Icons.close` par `PhosphorIconsBold.x` (24px)
- [x] T005 [P] Migrer les icones systeme dans `flutter/lib/src/common_widgets/select_picker.dart` — remplacer `Icons.close` et `Icons.keyboard_arrow_down` par equivalents Phosphor
- [x] T006 [P] Migrer les icones systeme dans `flutter/lib/src/common_widgets/color_palette_picker.dart` — remplacer `Icons.check` par `PhosphorIconsBold.check` (16px decoratif)
- [x] T006b [P] Migrer les icones systeme dans `flutter/lib/src/common_widgets/emoji_input.dart` — remplacer `Icons.close` par `PhosphorIconsBold.x` (24px)

**Checkpoint**: Composants partages migres — les ecrans peuvent etre migres sans conflit.

---

## Phase 3: User Story 1 - Coherence visuelle cross-platform (Priority: P1)

**Goal**: Remplacer 100% des icones systeme par Phosphor Icons sur les deux plateformes

**Independent Test**: Grep pour `Icons\.` (Flutter) et emojis systeme (Angular) — zero resultat pour les icones systeme

### Flutter — Navigation & Structure

- [x] T007 [P] [US1] Migrer les icones de navigation dans `flutter/lib/src/routing/app_router.dart` — remplacer les 10 icones bottom nav (home, receipt_long, autorenew, handshake, storefront — outlined→Regular, filled→Fill, 24px)
- [x] T008 [P] [US1] Migrer les icones de feature dans `flutter/lib/src/domain/enums/feature.dart` — remplacer `Icons.autorenew`, `Icons.handshake`, `Icons.storefront` et leurs variantes outlined par equivalents Phosphor
- [x] T009 [P] [US1] Migrer les icones du FAB dans `flutter/lib/src/common_widgets/fab_menu.dart` — remplacer `Icons.add`, `Icons.receipt_long`, `Icons.swap_horiz` par Phosphor Bold (24px actions)

### Flutter — Auth & Onboarding

- [x] T010 [P] [US1] Migrer les icones dans `flutter/lib/src/features/auth/presentation/login_screen.dart` — remplacer `Icons.email_outlined`, `Icons.lock_outlined`, `Icons.visibility_outlined`, `Icons.visibility_off_outlined` par Phosphor Regular (20px inline)
- [x] T011 [P] [US1] Migrer les icones dans `flutter/lib/src/features/auth/presentation/register_screen.dart` — remplacer `Icons.person_outlined`, `Icons.email_outlined`, `Icons.lock_outlined`, `Icons.visibility_*`, `Icons.verified_outlined` par Phosphor Regular (20px)
- [x] T012 [P] [US1] Migrer les icones dans `flutter/lib/src/features/auth/presentation/lock_screen.dart` — remplacer `Icons.lock_outlined`, `Icons.fingerprint` par Phosphor Regular (24px)
- [x] T013 [P] [US1] Migrer les icones dans `flutter/lib/src/features/onboarding/presentation/onboarding_screen.dart` — remplacer `Icons.account_balance_wallet`, `Icons.smartphone`, `Icons.cloud_outlined`, `Icons.check_circle` par Phosphor Regular (24px)

### Flutter — Features principales

- [x] T014 [P] [US1] Migrer les icones dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — remplacer `Icons.account_balance_wallet_outlined` et autres par Phosphor Regular
- [x] T015 [P] [US1] Migrer les icones dans `flutter/lib/src/features/dashboard/presentation/widgets/mini_cards_section.dart` — remplacer `Icons.autorenew`, `Icons.handshake` par Phosphor Regular (20px)
- [x] T016 [P] [US1] Migrer les icones dans `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` — remplacer `Icons.receipt_long_outlined`, `Icons.error_outline`, `Icons.refresh` par Phosphor Regular (20px/24px)
- [x] T017 [P] [US1] Migrer les icones dans `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — remplacer `Icons.calendar_today`, `Icons.delete_outline` par Phosphor (Regular 20px inline, Bold 24px action)
- [x] T018 [P] [US1] Migrer les icones dans `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` — remplacer `Icons.repeat_outlined`, `Icons.error_outline`, `Icons.refresh` par Phosphor Regular
- [x] T019 [P] [US1] Migrer les icones dans `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — remplacer `Icons.calendar_today`, `Icons.delete_outline` par Phosphor
- [x] T020 [P] [US1] Migrer les icones dans `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` — remplacer `Icons.account_balance_wallet_outlined`, `Icons.error_outline`, `Icons.refresh` par Phosphor Regular
- [x] T021 [P] [US1] Migrer les icones dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart` — remplacer `Icons.calendar_today`, `Icons.delete_outline` par Phosphor

### Flutter — Shop

- [x] T022 [P] [US1] Migrer les icones dans `flutter/lib/src/features/shop/presentation/product_list_screen.dart` — remplacer `Icons.receipt_long_outlined`, `Icons.storefront_outlined`, `Icons.error_outline`, `Icons.refresh`, `Icons.add` par Phosphor
- [x] T023 [P] [US1] Migrer les icones dans `flutter/lib/src/features/shop/presentation/widgets/product_form.dart` — remplacer `Icons.camera_alt`, `Icons.photo_library`, `Icons.add_a_photo`, `Icons.delete_outline` par Phosphor
- [x] T024 [P] [US1] Migrer les icones dans `flutter/lib/src/features/shop/presentation/product_detail_screen.dart` — remplacer `Icons.edit_outlined`, `Icons.add_shopping_cart`, `Icons.sell`, `Icons.trending_up`, `Icons.trending_down`, `Icons.refresh` par Phosphor

### Flutter — Settings

- [x] T025 [P] [US1] Migrer les icones dans `flutter/lib/src/features/settings/presentation/settings_section.dart` — remplacer les 8 icones de sections (person, toggle_on, palette, account_balance, label, storage, lock, info) par Phosphor Regular (24px)
- [x] T026 [P] [US1] Migrer les icones dans `flutter/lib/src/features/settings/presentation/profile_settings_screen.dart` — remplacer `Icons.check`, `Icons.error_outline`, `Icons.refresh`, `Icons.chevron_right` par Phosphor
- [x] T027 [P] [US1] Migrer les icones dans `flutter/lib/src/features/settings/presentation/appearance_settings_screen.dart` — remplacer `Icons.light_mode`, `Icons.dark_mode`, `Icons.check_circle` par Phosphor
- [x] T028 [P] [US1] Migrer les icones dans `flutter/lib/src/features/settings/presentation/feature_settings_screen.dart` — remplacer `Icons.home`, `Icons.receipt_long`, `Icons.lock_outline`, `Icons.drag_handle` par Phosphor
- [x] T029 [P] [US1] Migrer les icones dans `flutter/lib/src/features/settings/presentation/data_settings_screen.dart` — remplacer `Icons.phone_android`, `Icons.cloud`, `Icons.save`, `Icons.link`, `Icons.error_outline`, `Icons.refresh` par Phosphor
- [x] T030 [P] [US1] Migrer les icones dans `flutter/lib/src/features/settings/presentation/account_list_screen.dart` et `account_form_screen.dart` — remplacer `Icons.add`, `Icons.check`, `Icons.error_outline`, `Icons.refresh` par Phosphor
- [x] T031 [P] [US1] Migrer les icones dans `flutter/lib/src/features/settings/presentation/category_list_screen.dart` et `category_form_screen.dart` — remplacer `Icons.label_outlined`, `Icons.add`, `Icons.check`, `Icons.delete_outline`, `Icons.error_outline`, `Icons.refresh` par Phosphor

### Flutter — Divers

- [x] T032 [P] [US1] Migrer les icones dans `flutter/lib/src/common_widgets/month_selector.dart` — remplacer `Icons.chevron_left`, `Icons.chevron_right` par Phosphor Regular (20px)
- [x] T033 [P] [US1] Migrer les icones dans `flutter/lib/src/common_widgets/settings_item.dart` — remplacer `Icons.chevron_right` par Phosphor Regular (20px)
- [x] T034 [P] [US1] Migrer les icones dans `flutter/lib/src/common_widgets/account_list_tile.dart` — remplacer `Icons.more_vert` par Phosphor Regular (20px)
- [x] T035 [P] [US1] Migrer les icones dans `flutter/lib/src/features/auth/presentation/user_menu_button.dart` — remplacer `Icons.settings_outlined`, `Icons.logout` par Phosphor Regular (20px)
- [x] T036 [P] [US1] Migrer les icones dans `flutter/lib/src/features/auth/presentation/server_setup_screen.dart` — remplacer `Icons.link`, `Icons.wifi_find`, `Icons.check_circle`, `Icons.error_outline` par Phosphor

### Angular — Migration emojis systeme

> **Ref**: Voir `icon-mapping.md` pour le mapping exact emoji → nom Phosphor Angular (ex: 🏠 → `phosphorHouse`, 💰 → `phosphorCurrencyDollar`). Chaque composant doit importer `NgIcon` + `provideIcons()` (cf. plan D1).

- [x] T037 [P] [US1] Migrer les emojis navigation dans `app/src/app/shared/components/shell/shell.ts` et `shell.html` — remplacer 🏠, 💰 (nav) et ⚙️, 🚪 (user menu) par composants `<ng-icon>` Phosphor (cf. icon-mapping.md)
- [x] T038 [P] [US1] Migrer les emojis FAB dans `app/src/app/shared/components/fab/fab.ts` — remplacer 💰, 🔄, 🤝, ↔️, 📦, 💸 et le `+` par composants `<ng-icon>` Phosphor Bold (24px) (cf. icon-mapping.md)
- [x] T039 [P] [US1] Migrer les emojis bottom nav dans `app/src/app/shared/components/bottom-nav/bottom-nav.ts` — adapter le template pour afficher des `<ng-icon>` au lieu d'emojis (cf. icon-mapping.md)
- [x] T040 [P] [US1] Migrer les emojis settings dans `app/src/app/features/settings/settings.ts` — remplacer 🏦, 🏷️, 📊, 🔔, 👤, ⚡, 🎨, 💾, ℹ️ par icones Phosphor Regular (24px) (cf. icon-mapping.md)
- [x] T041 [P] [US1] Migrer les icones feature dans `app/src/app/core/models/preference.model.ts` — remplacer 🔄, 🤝, 🏪 par identifiants Phosphor pour les features dynamiques (cf. icon-mapping.md)
- [x] T042 [P] [US1] Migrer les emojis shop dans `app/src/app/features/shop/shop-list/shop-list.html` et `shop-detail/shop-detail.html` — remplacer 🏪, 📦 (empty states) par `<ng-icon>` Phosphor Regular (cf. icon-mapping.md)

**Checkpoint**: 100% des icones systeme utilisent Phosphor sur les deux plateformes.

---

## Phase 4: User Story 2 - Convention de styles par contexte (Priority: P2)

**Goal**: Verifier et corriger que chaque icone respecte la convention de styles (regular/fill/bold) et de tailles (24/20/16px)

**Independent Test**: Inspecter chaque contexte (navigation, actions, inline) et valider le style et la taille

### Audit & Corrections

- [x] T043 [P] [US2] Auditer et corriger les styles Flutter — verifier que toutes les icones navigation utilisent Regular (inactif) / Fill (actif), les actions utilisent Bold, et les inline utilisent Regular dans tous les fichiers sous `flutter/lib/src/`
- [x] T044 [P] [US2] Auditer et corriger les styles Angular — verifier que toutes les `<ng-icon>` utilisent le bon suffixe de style (sans suffixe=Regular, Fill, Bold) dans tous les fichiers sous `app/src/app/`
- [x] T045 [US2] Auditer et corriger les tailles — verifier la convention 24px (navigation, actions), 20px (inline/listes), 16px (decoratif) sur les deux plateformes

**Checkpoint**: Convention de styles et tailles respectee sur 100% des contextes.

---

## Phase 5: User Story 3 - Nettoyage des anciennes sources (Priority: P3)

**Goal**: Zero reference residuelle aux anciennes icones systeme, builds propres

**Independent Test**: `grep -r "Icons\." flutter/lib/src/` ne retourne aucun usage systeme, aucun emoji systeme dans Angular

### Verification & Nettoyage

- [x] T046 [P] [US3] Nettoyer les imports Flutter — supprimer les imports `material_icons` inutilises et verifier qu'aucun `Icons.*` systeme ne subsiste via `grep -rn "Icons\." flutter/lib/src/ --include="*.dart"`. Confirmer que les emojis utilisateur (categories, comptes) sont intacts (FR-004). Croiser les resultats avec l'inventaire `icon-mapping.md` pour valider la completude (SC-003)
- [x] T047 [P] [US3] Verifier les emojis Angular — confirmer qu'aucun emoji systeme (🏠, 💰, 🔄, 🤝, 🏪, ⚙️, 🚪, etc.) ne subsiste dans les fichiers sous `app/src/app/` pour des usages systeme. Confirmer que les emojis utilisateur (account-form defaults, category-picker test data) sont intacts (FR-004). Croiser les resultats avec l'inventaire `icon-mapping.md` pour valider la completude (SC-003)
- [x] T048 [P] [US3] Verifier le build Angular — executer `cd app && ng build` et confirmer zero erreur
- [x] T049 [P] [US3] Verifier le build Flutter — executer `cd flutter && flutter analyze && flutter build apk --debug` et confirmer zero erreur

**Checkpoint**: Builds propres, zero reference residuelle.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation et verification finale

- [x] T050 Mettre a jour `docs/design-tokens.md` — ajouter la section icones avec les conventions Phosphor (styles, tailles, packages)
- [x] T051 Verification visuelle finale — parcourir chaque ecran des deux plateformes (sidebar, header, formulaires, listes, settings, FAB, modals, bottom nav, app bar) et confirmer zero regression. Verifier que les images de produits (shop) sont intactes (FR-005)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — peut commencer immediatement
- **Foundational (Phase 2)**: Depend de T001 + T002 (packages installes)
- **US1 (Phase 3)**: Depend de Phase 2 (composants partages migres) + T003 (inventaire)
- **US2 (Phase 4)**: Depend de US1 (toutes les icones remplacees)
- **US3 (Phase 5)**: Depend de US2 (styles corrects)
- **Polish (Phase 6)**: Depend de US3

### User Story Dependencies

- **US1 (P1)**: Depend de Setup + Foundational — implementation principale
- **US2 (P2)**: Depend de US1 — audit des styles/tailles (passe de verification)
- **US3 (P3)**: Depend de US2 — nettoyage final et validation builds

### Within Each User Story

- Les taches Flutter marquees [P] peuvent etre executees en parallele (fichiers differents)
- Les taches Angular marquees [P] peuvent etre executees en parallele (fichiers differents)
- Flutter et Angular peuvent etre migres en parallele

### Parallel Opportunities

- T001 + T002 en parallele (packages Angular et Flutter)
- T004 + T005 + T006 + T006b en parallele (composants partages Flutter)
- T007 a T036 en parallele (tous les fichiers Flutter sont independants)
- T037 a T042 en parallele (tous les fichiers Angular sont independants)
- T043 + T044 en parallele (audit Flutter et Angular)
- T046 + T047 + T048 + T049 en parallele (verifications independantes)

---

## Parallel Example: User Story 1

```bash
# Lancer toutes les migrations Flutter en parallele :
Task: "Migrer app_router.dart (navigation)"
Task: "Migrer feature.dart (enums)"
Task: "Migrer fab_menu.dart (FAB)"
Task: "Migrer login_screen.dart (auth)"
Task: "Migrer settings_section.dart (settings)"
# ... tous les fichiers Flutter sont independants

# En parallele, lancer les migrations Angular :
Task: "Migrer shell.ts (navigation)"
Task: "Migrer fab.ts (FAB)"
Task: "Migrer settings.ts (settings)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (installer packages)
2. Complete Phase 2: Foundational (composants partages)
3. Complete Phase 3: US1 (remplacer toutes les icones)
4. **STOP and VALIDATE**: Grep zero `Icons.*` systeme + zero emoji systeme
5. Les apps fonctionnent avec Phosphor Icons

### Incremental Delivery

1. Setup + Foundational → Packages prets, composants partages migres
2. US1 → Toutes les icones Phosphor → **MVP livre**
3. US2 → Audit styles/tailles → Coherence visuelle garantie
4. US3 → Nettoyage + builds verts → Production-ready
5. Polish → Documentation + verification visuelle

---

## Notes

- [P] tasks = fichiers differents, pas de dependances
- US2 et US3 sont des passes de verification/nettoyage, pas de nouvelles features
- Les emojis utilisateur (categories, comptes) NE DOIVENT PAS etre modifies
- Les images de produits (shop) NE DOIVENT PAS etre modifiees
- Commiter apres chaque groupe logique (ex: toutes les migrations Flutter settings)
