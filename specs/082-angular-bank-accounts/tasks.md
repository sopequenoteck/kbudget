# Tasks: Banques sur les comptes — Angular

**Input**: Design documents from `/specs/082-angular-bank-accounts/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Inclus (demandé dans SC-005 de la spec)

**Organization**: Tasks groupées par user story pour permettre l'implémentation et le test indépendant de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend Angular**: `app/src/app/`
- Préfixe implicite : tous les chemins relatifs partent de `app/src/app/`

---

## Phase 1: Foundational (Modèles + Service)

**Purpose**: Modèle de données enrichi et service BankService — bloquent toutes les user stories

**CRITICAL**: Aucune user story ne peut commencer sans cette phase

- [x] T001 [P] Créer l'interface `BankResponse` dans `app/src/app/core/models/bank.model.ts` — champs: code, name, country (string|null), brandColor (string|null), logoUrl (string|null) (cf. data-model.md)
- [x] T002 [P] Mettre à jour les interfaces `Account` (+7 champs bank: bankCode, bankName, bankCountry, bankBrandColor, bankLogoUrl, bankCustomName, bankCustomLogo) et `AccountRequest` (+3 champs: bankCode, bankCustomName, bankCustomLogo) dans `app/src/app/core/models/account.model.ts` (cf. data-model.md)
- [x] T003 Créer `BankService` signal-based dans `app/src/app/core/services/bank.ts` — signal `banks` initialisé à `[]`, signal `error` (string|null). `loadBanks()` lazy via `GET /api/banks` avec cache (un seul appel réseau). `getBankByCode(code)`, `getBankLogoUrl(code)`. En cas d'erreur API: `banks` reste `[]`, `error` contient le message — le BankSelectComponent doit gérer le cas `banks.length === 0` en proposant uniquement l'option "Autre" en fallback. Pattern: suivre `PreferenceService` existant (cf. research.md R-001)

**Checkpoint**: Modèles et service prêts — les user stories peuvent commencer

---

## Phase 2: User Story 1 — Associer une banque à un compte (Priority: P1) MVP

**Goal**: L'utilisateur peut sélectionner une banque dans le formulaire de création/édition de compte. Le sélecteur affiche les banques groupées par région. Le formulaire masque icône/couleur quand une banque connue est sélectionnée.

**Independent Test**: Ouvrir le formulaire de création de compte → sélectionner Société Générale → vérifier que icône/couleur sont masqués → soumettre → vérifier bankCode = "SG" dans la requête

### Implementation

- [x] T004 [US1] Créer `BankSelectComponent` (standalone, OnPush) dans `app/src/app/shared/components/bank-select/` — dropdown avec liste des banques groupées par région (France: country="FR", Afrique de l'Ouest: country="TG", International: country=null), option "Autre" (OTHER) toujours en dernière position. ControlValueAccessor pour intégration formulaire. Affiche logo SVG (`<img>`) + nom + dot couleur brand pour chaque banque. Template (`bank-select.html`) + styles (`bank-select.scss`). Cf. DD-001 dans plan.md, groupement dans data-model.md
- [x] T005 [US1] Enrichir `AccountFormComponent` avec section banque dans `app/src/app/shared/components/account-form/account-form.ts` et `account-form.html` — ajouter le `BankSelectComponent` en haut du formulaire (avant le type). Signal `isKnownBank = computed(() => selectedBankCode !== 'OTHER')`. Quand `isKnownBank` est true: masquer les sections icône (emoji picker) et couleur (color palette), utiliser `bankBrandColor` pour la prévisualisation. Quand bankCode = "OTHER": afficher les champs existants icône/couleur + nouveau champ texte `bankCustomName` (max 100 chars) + bouton upload logo custom. En mode édition: pré-remplir le sélecteur avec le `bankCode` du compte existant (et les champs custom si OTHER). Cf. DD-005 dans plan.md
- [x] T006 [US1] Ajouter l'upload de logo custom dans `AccountFormComponent` (`app/src/app/shared/components/account-form/account-form.ts`) — réutiliser le pattern compression canvas du ProductForm mais avec des valeurs adaptées aux logos: `<input type="file" accept="image/*">`, `compressImage(file, maxWidth=512, quality=0.8)` (vs 1024/0.85 pour les produits — un logo n'a pas besoin de haute résolution) → data URI JPEG stocké dans `bankCustomLogo`. Afficher preview du logo uploadé. Cf. DD-004 dans plan.md
- [x] T007 [US1] Mettre à jour les styles du formulaire compte dans `app/src/app/shared/components/account-form/account-form.scss` — styles section banque, transition masquage icône/couleur, preview logo custom, cohérence design tokens existants

**Checkpoint**: US1 fonctionnelle — on peut associer une banque à un compte via le formulaire

---

## Phase 3: User Story 2 — Voir le logo banque sur les comptes (Priority: P2)

**Goal**: Partout où un compte est affiché, le logo banque apparaît (logo SVG pour banque connue, logo custom pour "Autre" avec upload, emoji pour "Autre" sans logo).

**Independent Test**: Créer un compte avec banque SG → naviguer aux paramètres comptes → vérifier le logo SG affiché

### Implementation

- [x] T008 [P] [US2] Créer `AccountBankIconComponent` (standalone, OnPush) dans `app/src/app/shared/components/account-bank-icon/` — input signal `account` (Account). Résolution 3 niveaux (cf. DD-003 dans plan.md): (1) bankCode ≠ OTHER → `<img [src]="account.bankLogoUrl">` avec `(error)` handler → fallback emoji, (2) bankCode = OTHER + bankCustomLogo → `<img [src]="account.bankCustomLogo">` avec `(error)` handler → fallback emoji, (3) bankCode = OTHER sans logo → `<span>{{ account.icone }}</span>`. Input optionnel `size` (24 ou 32, défaut 24) pour dimensionnement cohérent des logos (FR-010): utiliser `[width]` et `[height]` sur les `<img>`, `font-size` sur le `<span>` emoji. Template + styles (border-radius, background accent brandColor)
- [x] T009 [P] [US2] Ajouter le champ optionnel `iconUrl` sur l'interface `SelectPickerItem` dans `app/src/app/shared/components/select-picker/select-picker.ts` et mettre à jour le template `select-picker.html` pour afficher `<img [src]="item.iconUrl">` quand `iconUrl` est présent (prioritaire sur emoji `icon`). Cf. research.md R-005
- [x] T010 [US2] Mettre à jour le composant liste des comptes dans `app/src/app/features/settings/components/accounts/accounts.ts` et `accounts.html` — remplacer l'affichage emoji par `<app-account-bank-icon [account]="account">`. Afficher le nom de la banque en sous-texte si `bankName` est non null
- [x] T011 [US2] Mettre à jour les sélecteurs de compte dans les formulaires et le dashboard pour inclure `iconUrl` (bankLogoUrl ou bankCustomLogo) dans les `SelectPickerItem` — fichiers concernés: `app/src/app/shared/components/transfer-form/transfer-form.ts` (comptes source/destination), `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` (compte transaction), `app/src/app/features/debts/components/debt-form/debt-form.ts` (compte dette), `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts` (compte abonnement), `app/src/app/features/dashboard/` (affichage comptes sur le dashboard — utiliser `AccountBankIcon` si le dashboard affiche des comptes avec icônes). Pour chaque formulaire: mapper `account.bankLogoUrl ?? account.bankCustomLogo` → `item.iconUrl` lors de la construction des SelectPickerItem à partir de comptes

**Checkpoint**: US2 fonctionnelle — logo banque visible partout où un compte est affiché

---

## Phase 4: User Story 3 — Recherche et filtrage dans le sélecteur (Priority: P3)

**Goal**: Le sélecteur de banque permet de filtrer par nom via un champ de recherche. L'option "Autre" reste toujours visible pendant le filtrage.

**Independent Test**: Ouvrir le sélecteur → taper "eco" → vérifier que seul Ecobank apparaît + "Autre" reste visible

### Implementation

- [x] T012 [US3] Ajouter le champ de recherche et la logique de filtrage dans `BankSelectComponent` (`app/src/app/shared/components/bank-select/bank-select.ts` et `bank-select.html`) — signal `searchQuery`, computed `filteredBanks` (filtre case-insensitive sur `bank.name`). L'option "Autre" (OTHER) reste toujours visible même quand le filtre ne la matche pas. Afficher "Aucune banque trouvée" quand la liste filtrée (hors "Autre") est vide. Cf. FR-004, FR-011 dans spec.md

**Checkpoint**: US3 fonctionnelle — recherche dans le sélecteur opérationnelle

---

## Phase 5: Tests unitaires

**Purpose**: Tests des composants clés (SC-005)

- [x] T013 [P] Tests unitaires `BankService` dans `app/src/app/core/services/bank.spec.ts` — should_load_banks_from_api, should_cache_banks_after_first_load, should_return_bank_by_code, should_handle_api_error_gracefully
- [x] T014 [P] Tests unitaires `AccountBankIconComponent` dans `app/src/app/shared/components/account-bank-icon/account-bank-icon.spec.ts` — should_display_svg_logo_when_known_bank, should_display_custom_logo_when_other_with_logo, should_display_emoji_when_other_without_logo, should_fallback_to_emoji_on_img_error
- [x] T015 [P] Tests unitaires `BankSelectComponent` dans `app/src/app/shared/components/bank-select/bank-select.spec.ts` — should_group_banks_by_region, should_show_other_last, should_filter_by_search_query, should_keep_other_visible_during_filter, should_emit_selected_bank_code. Tests `SelectPicker` enrichi dans `app/src/app/shared/components/select-picker/select-picker.spec.ts` — should_display_iconUrl_img_when_provided, should_fallback_to_emoji_when_no_iconUrl
- [x] T016 Tests unitaires `AccountFormComponent` enrichi dans `app/src/app/shared/components/account-form/account-form.spec.ts` — should_hide_icon_color_when_known_bank_selected, should_show_icon_color_when_other_selected, should_populate_bank_select_in_edit_mode, should_include_bank_fields_in_request

---

## Phase 6: Polish & Edge Cases

**Purpose**: Gestion des cas limites et cohérence globale

- [x] T017 Gérer les edge cases dans `AccountBankIconComponent` et `BankSelectComponent` — bankCode inconnu (traiter comme OTHER), API banks indisponible (fallback "Autre" seul), base64 invalide (fallback emoji), transition banque connue ↔ "Autre" (conserver valeurs custom en mémoire). Cf. Edge Cases dans spec.md
- [x] T018 Vérification de build et lint — `cd app && ng build && ng lint`. Corriger les éventuelles erreurs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Aucune dépendance — démarre immédiatement. BLOQUE toutes les user stories
- **US1 (Phase 2)**: Dépend de Phase 1. MVP — doit être complétée en premier
- **US2 (Phase 3)**: Dépend de Phase 1 uniquement (indépendante de US1)
- **US3 (Phase 4)**: Dépend de US1 (le BankSelectComponent doit exister)
- **Tests (Phase 5)**: Dépend de US1 + US2 + US3
- **Polish (Phase 6)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Foundational → US1. Crée le BankSelectComponent
- **US2 (P2)**: Foundational → US2. Crée le AccountBankIcon. Indépendant de US1
- **US3 (P3)**: Foundational → US1 → US3. Étend le BankSelectComponent avec la recherche

### Within Each User Story

- Modèles/interfaces avant services
- Services avant composants
- Composants standalone avant intégration dans composants existants

### Parallel Opportunities

**Phase 1**: T001 et T002 en parallèle (fichiers différents), T003 après
**Phase 2 + 3**: US1 et US2 peuvent avancer en parallèle après Phase 1
- T004 (BankSelect) ∥ T008 (AccountBankIcon) ∥ T009 (SelectPicker iconUrl)
**Phase 5**: T013, T014, T015 en parallèle (fichiers de test différents)

---

## Parallel Example: Phase 1

```bash
# Lancer T001 et T002 en parallèle (fichiers différents):
Task: "Créer BankResponse dans core/models/bank.model.ts"
Task: "Mettre à jour Account dans core/models/account.model.ts"

# Puis T003 (dépend de T001):
Task: "Créer BankService dans core/services/bank.ts"
```

## Parallel Example: US1 + US2

```bash
# Après Phase 1, lancer en parallèle:
Task: "T004 [US1] BankSelectComponent"
Task: "T008 [US2] AccountBankIconComponent"
Task: "T009 [US2] SelectPicker iconUrl"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (T001-T003)
2. Complete Phase 2: US1 (T004-T007)
3. **STOP and VALIDATE**: Tester le formulaire compte avec sélecteur banque
4. Commit + vérifier `/sync-doc`

### Incremental Delivery

1. Phase 1 → Fondations prêtes
2. US1 (Phase 2) → Sélecteur banque dans le formulaire → Commit
3. US2 (Phase 3) → Logo banque visible partout → Commit
4. US3 (Phase 4) → Recherche dans le sélecteur → Commit
5. Tests (Phase 5) → Couverture tests → Commit
6. Polish (Phase 6) → Edge cases + build → Commit final

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label associe la tâche à une user story pour traçabilité
- Les logos SVG sont servis par le backend — aucun asset local Angular nécessaire
- Le `BankSelectComponent` est dédié (pas d'extension du SelectPicker) — cf. DD-001
- Le `AccountBankIcon` n'a pas besoin d'injecter `BankService` — toutes les infos sont sur AccountResponse
- Commit après chaque checkpoint de phase
