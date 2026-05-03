# Tasks: Banques sur les comptes — Flutter

**Input**: Design documents from `/specs/083-flutter-bank-accounts/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-consumed.md, quickstart.md

**Tests**: Tests widget inclus (demandés dans la spec SC-005).

**Organization**: Tasks grouped by user story (US1: Associer banque, US2: Logo partout, US3: Recherche sélecteur).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Ajout des dépendances et assets SVG

- [x] T001 Ajouter `flutter_svg` au `flutter/pubspec.yaml` et déclarer `assets/banks/` dans la section flutter > assets
- [x] T002 Copier les 29 fichiers SVG depuis `api/src/main/resources/static/bank-logos/` vers `flutter/assets/banks/` (sg.svg, bnp.svg, boa.svg, bourso.svg, bp.svg, bdt.svg, bia.svg, bsic.svg, btci.svg, ca.svg, ce.svg, cm.svg, coris.svg, ecobank.svg, fortuneo.svg, hello.svg, hsbc_fr.svg, lbp.svg, lcl.svg, n26.svg, nsia.svg, orabank.svg, other.svg, revolut.svg, sgto.svg, sunu.svg, uba.svg, utb.svg, wise.svg)

---

## Phase 2: Foundational (Data Layer)

**Purpose**: Modèles, DTOs, repositories, Drift migration — BLOQUE toutes les user stories

**CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase

### Modèles & DTOs

- [x] T003 [P] Créer le modèle Bank (Freezed) avec champs code, name, country, brandColor, logoUrl + factory fromJson dans `flutter/lib/src/domain/models/bank.dart`
- [x] T004 [P] Créer le DTO BankResponse (Freezed) avec les mêmes champs + factory fromJson dans `flutter/lib/src/data/remote/dtos/bank_dtos.dart`
- [x] T005 [P] Enrichir le modèle Account (Freezed) avec 7 champs bank : bankCode (@Default("OTHER") String), bankName (String?), bankCountry (String?), bankBrandColor (String?), bankLogoUrl (String?), bankCustomName (String?), bankCustomLogo (String?) dans `flutter/lib/src/domain/models/account.dart`
- [x] T006 [P] Enrichir AccountRequest avec 3 champs nullable (bankCode String?, bankCustomName String?, bankCustomLogo String?) et AccountResponse avec 7 champs nullable dans `flutter/lib/src/data/remote/dtos/account_dtos.dart`

### Drift (stockage local)

- [x] T007 Enrichir la table Drift `Accounts` avec 3 colonnes TextColumn nullable (bankCode, bankCustomName, bankCustomLogo) + incrémenter schemaVersion + ajouter step de migration ALTER TABLE dans `flutter/lib/src/data/local/database.dart`
- [x] T008 Mettre à jour les fonctions `accountFromDb()` et `accountToDb()` pour mapper les 3 champs bank (bankCode, bankCustomName, bankCustomLogo) dans `flutter/lib/src/data/local/mappers.dart`

### Repository & Provider banques

- [x] T009 [P] Créer BankRemoteDataSource avec méthode `getAll()` → GET /api/banks retournant `List<BankResponse>` dans `flutter/lib/src/data/remote/data_sources/bank_remote_data_source.dart`
- [x] T010 [P] Créer l'interface abstraite BankRepository avec méthode `getAll()` → `Future<List<Bank>>` dans `flutter/lib/src/domain/repositories/bank_repository.dart`
- [x] T011 Créer BankRepositoryRemote implémentant BankRepository, avec mapper `_toDomain(BankResponse)` → Bank dans `flutter/lib/src/features/accounts/data/bank_repository_remote.dart`
- [x] T012 Créer `banksProvider` (FutureProvider<List<Bank>>) qui charge les banques une seule fois via BankRepositoryRemote dans `flutter/lib/src/features/accounts/application/bank_provider.dart`

### Mise à jour repository comptes

- [x] T013 Mettre à jour `_toDomain(AccountResponse)` et `_toRequest(Account)` dans AccountRepositoryRemote pour mapper les 7 champs bank (response) et 3 champs bank (request, envoyer bankCustomName/bankCustomLogo seulement si bankCode == "OTHER") dans `flutter/lib/src/features/accounts/data/account_repository_remote.dart`

### Code generation

- [x] T014 Exécuter `dart run build_runner build --delete-conflicting-outputs` depuis `flutter/` pour générer les fichiers .freezed.dart et .g.dart des modèles Bank, BankResponse, Account et AccountRequest/AccountResponse modifiés

### Widget réutilisable

- [x] T015 Créer le widget AccountBankIcon (StatelessWidget) dans `flutter/lib/src/common_widgets/account_bank_icon.dart` avec paramètres `Account account` et `double size` (default 24). Cascade de résolution : (1) si bankCode != "OTHER" et non vide → SvgPicture.asset('assets/banks/${bankCode.toLowerCase()}.svg', width: size, height: size) avec errorBuilder → PhosphorIcon bank Phosphor en fallback si l'asset SVG est introuvable ; (2) si bankCode == "OTHER" et bankCustomLogo non null → Image.memory(base64Decode(dataUri), width: size, height: size) avec errorBuilder → emoji fallback ; (3) sinon → Text(account.icone) emoji. Encapsuler dans un Container rond avec background couleur brand (10% opacity) si bankBrandColor est défini, sinon utiliser account.couleur

**Checkpoint**: Data layer complet — les user stories peuvent commencer

---

## Phase 3: User Story 1 — Associer une banque à un compte (Priority: P1) MVP

**Goal**: L'utilisateur peut sélectionner une banque lors de la création/édition d'un compte. Les champs icône/couleur sont masqués pour les banques connues.

**Independent Test**: Ouvrir le formulaire de création de compte, sélectionner Société Générale, vérifier que icône/couleur sont masqués, soumettre, vérifier que le compte est créé avec bankCode="SG".

### Implementation for User Story 1

- [x] T016 [US1] Créer le widget BankSelectPicker (ConsumerWidget) dans `flutter/lib/src/common_widgets/bank_select_picker.dart`. Paramètres : selectedBankCode (String?), onChanged (ValueChanged<String>), banks (AsyncValue<List<Bank>>). Affiche un trigger (comme SelectPicker : nom banque + logo SVG 32×32 ou "Sélectionner une banque"). Au tap, ouvre AppModal.show() en bottom sheet avec : (1) champ de recherche TextField en haut, (2) liste groupée par pays — "France" (country=="FR"), "Afrique de l'Ouest" (country=="TG"), "International" (country==null) avec headers de section, (3) chaque item : SvgPicture.asset 24×24 + nom + dot couleur brand, (4) option "Autre / Personnalisé" toujours visible en bas même pendant le filtrage, (5) recherche insensible à la casse sur le nom, (6) message "Aucune banque trouvée" si aucun résultat (mais Autre reste visible), (7) item sélectionné mis en surbrillance, (8) gestion de AsyncValue.error → afficher message d'erreur + seule l'option "Autre" en fallback. Exclure "OTHER" des groupes (affiché séparément)

- [x] T017 [US1] Enrichir AccountFormScreen dans `flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart`. Ajouter : (1) état `_selectedBankCode` (String, default "OTHER"), `_bankCustomName` (String?), `_bankCustomLogo` (String?) ; (2) en initState edit mode : initialiser depuis widget.account.bankCode/bankCustomName/bankCustomLogo ; (3) dans le build, ajouter BankSelectPicker AVANT AccountTypeSelector, alimenté par ref.watch(banksProvider) ; (4) handler `_onBankCodeChanged(String code)` : si code != "OTHER" → trouver la banque dans la liste, auto-remplir `_selectedColor` avec brandColor ; (5) masquer la Row emoji+couleur si bankCode != "OTHER" (`if (_selectedBankCode == "OTHER") ...`) ; (6) si bankCode == "OTHER" : afficher AppFormField pour bankCustomName + bouton upload logo custom (réutiliser pattern ProductForm avec image_picker maxWidth=512 quality=80, stocker en base64 via fileToBase64DataUri de image_utils.dart) ; (7) dans _onSubmit : passer bankCode, bankCustomName (si OTHER), bankCustomLogo (si OTHER) dans le Account créé/mis à jour

- [x] T018 [US1] Mettre à jour AccountPreviewCard dans `flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart` pour supporter l'affichage du logo banque. Ajouter paramètres optionnels `bankCode` (String?) et `bankBrandColor` (String?). Si bankCode != null et != "OTHER" → afficher SvgPicture.asset (size: 32) au lieu de l'emoji. Sinon → comportement actuel (emoji)

**Checkpoint**: US1 complète — le formulaire de compte permet de sélectionner une banque avec masquage conditionnel

---

## Phase 4: User Story 2 — Voir le logo banque partout (Priority: P2)

**Goal**: Partout où un compte est affiché (dashboard, paramètres, sélecteurs), le logo banque remplace l'emoji.

**Independent Test**: Créer un compte avec banque BNP, naviguer vers les paramètres comptes et le dashboard, vérifier que le logo BNP apparaît.

### Implementation for User Story 2

- [x] T019 [P] [US2] Remplacer l'affichage emoji par AccountBankIcon dans AccountListTile : dans `flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart`, remplacer le Container rond + Text(account.icone) (lignes 60-74) par AccountBankIcon(account: account, size: AppSpacing.space10)

- [x] T020 [P] [US2] Remplacer l'affichage emoji par AccountBankIcon dans HeroAccountSection : dans `flutter/lib/src/features/dashboard/presentation/widgets/hero_account_section.dart`, (1) dans _HeroCard (lignes 129-143) : remplacer Container rond + Text(account.icone) par AccountBankIcon(account: account, size: AppSpacing.space12), (2) dans _AccountRow (lignes 225-238) : remplacer Container rond + Text(account.icone) par AccountBankIcon(account: account, size: AppSpacing.space9)

- [x] T021 [US2] Étendre SelectPickerItem avec un champ optionnel `imageUrl` (String?) dans `flutter/lib/src/common_widgets/select_picker.dart`. Mettre à jour _buildItemTile et _buildTrigger pour afficher l'image (si imageUrl est un chemin asset SVG → SvgPicture.asset, si c'est un data URI base64 → Image.memory) avant le label, avec priorité imageUrl > icon > color

- [x] T022 [US2] Mettre à jour les sélecteurs de compte dans les 5 formulaires suivants pour inclure le logo banque dans les items SelectPicker en ajoutant `imageUrl: _resolveBankAssetPath(account)` (helper retournant le chemin asset SVG pour les banques connues ou le bankCustomLogo pour OTHER) : (1) `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` (1 SelectPicker comptes), (2) `flutter/lib/src/features/transactions/presentation/widgets/transfer_form.dart` (2 SelectPicker source/destination), (3) `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart` (1 SelectPicker compte), (4) `flutter/lib/src/features/debts/presentation/widgets/repay_bottom_sheet.dart` (1 SelectPicker compte), (5) `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` (1 SelectPicker compte)

**Checkpoint**: US2 complète — tous les écrans affichent le logo banque

---

## Phase 5: User Story 3 — Recherche dans le sélecteur (Priority: P3)

**Goal**: Le sélecteur de banque permet de trouver une banque par nom via un champ de recherche.

**Independent Test**: Ouvrir le sélecteur, taper "eco", vérifier que seul "Ecobank" apparaît avec l'option "Autre" toujours visible.

### Implementation for User Story 3

- [x] T023 [US3] Valider et affiner les edge cases de recherche dans BankSelectPicker (`flutter/lib/src/common_widgets/bank_select_picker.dart`) : (1) vérifier que l'option "Autre" reste visible même quand le filtre ne match aucune banque, (2) afficher le message "Aucune banque trouvée" dans la zone des groupes quand le filtre ne donne aucun résultat (mais Autre reste en bas), (3) réinitialiser le champ de recherche quand la bottom sheet se ferme, (4) vérifier la gestion du bankCode inconnu (code qui n'existe pas dans la liste) → afficher le code brut comme label et traiter comme "Autre"

**Checkpoint**: US3 complète — la recherche fonctionne avec tous les edge cases

---

## Phase 6: Polish & Tests

**Purpose**: Tests widget, validation, nettoyage

- [x] T024 [P] Créer les tests widget pour AccountBankIcon dans `flutter/test/src/features/accounts/account_bank_icon_test.dart` : (1) should_show_svg_when_bankCode_is_known — vérifier que SvgPicture est rendu pour un compte avec bankCode="SG", (2) should_show_custom_logo_when_bankCode_is_other_with_custom_logo — vérifier que Image.memory est rendu, (3) should_show_emoji_when_bankCode_is_other_without_logo — vérifier que le Text emoji est rendu, (4) should_use_brand_color_background_when_available — vérifier le Container avec couleur brand
- [x] T025 [P] Créer les tests widget pour BankSelectPicker dans `flutter/test/src/features/accounts/bank_select_picker_test.dart` : (1) should_show_grouped_banks_when_opened — vérifier les 3 groupes (France, Afrique de l'Ouest, International), (2) should_filter_banks_when_searching — taper "soc" et vérifier que seule Société Générale apparaît, (3) should_always_show_other_option_when_filtering — vérifier que "Autre" reste visible même avec un filtre sans résultat, (4) should_call_onChanged_when_bank_selected — vérifier le callback, (5) should_show_empty_message_when_no_results — vérifier le message "Aucune banque trouvée"
- [x] T026 Exécuter `flutter analyze` depuis `flutter/` et corriger les éventuelles erreurs d'analyse statique
- [x] T027 Exécuter `flutter test` depuis `flutter/` et vérifier que tous les tests passent (existants + nouveaux)
- [x] T028 Exécuter la validation quickstart.md : lancer le backend et l'app Flutter, vérifier manuellement le flux complet (création compte avec banque, affichage logo dans liste et dashboard)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — commence immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (T001-T002) — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2 (T003-T015) — MVP
- **US2 (Phase 4)**: Dépend de Phase 2 (T015 AccountBankIcon) — peut démarrer en parallèle avec US1
- **US3 (Phase 5)**: Dépend de US1 (T016 BankSelectPicker)
- **Polish (Phase 6)**: Dépend de US1, US2, US3

### User Story Dependencies

- **US1 (P1)**: Peut commencer après Phase 2 — pas de dépendance sur d'autres stories
- **US2 (P2)**: Peut commencer après Phase 2 — INDÉPENDANTE de US1 (utilise AccountBankIcon de Phase 2)
- **US3 (P3)**: Dépend de US1 (enrichissement du BankSelectPicker créé en T016)

### Within Each User Story

- Modèles avant services
- Services avant UI
- Core avant intégration

### Parallel Opportunities

- T003, T004, T005, T006 peuvent s'exécuter en parallèle (fichiers différents)
- T009, T010 peuvent s'exécuter en parallèle
- US1 et US2 peuvent s'exécuter en parallèle (après Phase 2)
- T019, T020 peuvent s'exécuter en parallèle (fichiers différents)
- T024, T025 peuvent s'exécuter en parallèle (fichiers de test différents)

---

## Parallel Example: Phase 2 Foundation

```text
# Lancer les 4 modèles/DTOs en parallèle :
T003: Créer Bank model dans flutter/lib/src/domain/models/bank.dart
T004: Créer BankResponse DTO dans flutter/lib/src/data/remote/dtos/bank_dtos.dart
T005: Enrichir Account model dans flutter/lib/src/domain/models/account.dart
T006: Enrichir Account DTOs dans flutter/lib/src/data/remote/dtos/account_dtos.dart

# Puis les repos en parallèle :
T009: Créer BankRemoteDataSource
T010: Créer BankRepository interface
```

## Parallel Example: US2

```text
# Lancer les mises à jour d'affichage en parallèle :
T019: AccountListTile → AccountBankIcon
T020: HeroAccountSection → AccountBankIcon
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (assets + flutter_svg)
2. Compléter Phase 2: Foundational (data layer complet)
3. Compléter Phase 3: User Story 1 (formulaire avec sélecteur banque)
4. **STOP et VALIDER** : tester le formulaire indépendamment
5. Commit intermédiaire

### Incremental Delivery

1. Setup + Foundational → data layer prêt
2. + User Story 1 → formulaire fonctionnel (MVP!)
3. + User Story 2 → logos visibles partout
4. + User Story 3 → recherche affinée
5. + Polish → tests + validation

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label = traçabilité vers les user stories de la spec
- Chaque user story est testable indépendamment
- Commiter après chaque phase ou groupe logique
- Les fichiers .freezed.dart et .g.dart sont régénérés par T014 — ne pas les modifier manuellement
- Le AccountBankIcon est dans Phase 2 (pas US2) car il est un prérequis partagé entre US1 (preview card) et US2 (listes)
