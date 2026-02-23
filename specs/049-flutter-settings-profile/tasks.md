# Tasks: Settings — Profil

**Input**: Design documents from `/specs/049-flutter-settings-profile/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Non demandés dans la spec. Non inclus dans cette itération. L'architecture (Notifier + interface repository) permet l'ajout ultérieur de tests via ProviderContainer + mock repository.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story concernée (US1, US2, US3)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup

**Purpose**: Création de la structure du feature module et des répertoires

- [x] T001 Create feature module directory structure for `flutter/lib/src/features/user_profile/` with subdirectories `application/`, `data/`, `presentation/screens/`, `presentation/widgets/`

---

## Phase 2: Foundational (Data Layer)

**Purpose**: Infrastructure data partagée par toutes les user stories. DOIT être complétée avant toute implémentation UI.

- [x] T002 [P] Create user DTOs (UserResponse, UserUpdateRequest) with Freezed in `flutter/lib/src/data/remote/dtos/user_dtos.dart` — UserResponse: name (String?), email (String), defaultCurrency (String). UserUpdateRequest: defaultCurrency (String). Include fromJson factories.
- [x] T003 [P] Create UserRepository abstract interface in `flutter/lib/src/domain/repositories/user_repository.dart` — methods: `Future<User> getProfile()`, `Future<User> updateProfile({required Currency defaultCurrency})`
- [x] T004 Create UserRemoteDataSource in `flutter/lib/src/data/remote/data_sources/user_remote_data_source.dart` — constructor takes Dio. Methods: `getProfile()` calls GET `/users/me`, `updateProfile(UserUpdateRequest)` calls PUT `/users/me`. Returns DTOs.
- [x] T005 Create UserRepositoryRemote implementing UserRepository in `flutter/lib/src/features/user_profile/data/user_repository_remote.dart` — constructor takes UserRemoteDataSource. Maps DTOs to domain User model. Currency mapping: `Currency.values.byName(response.defaultCurrency.toLowerCase())`. Le backend ne retourne pas l'id dans UserResponse : utiliser `'profile'` comme id constant (valeur sentinelle explicite, jamais utilisée en dehors de ce contexte — l'écran profil ne manipule pas l'id).
- [x] T006 Run `dart run build_runner build --delete-conflicting-outputs` from `flutter/` to generate `.freezed.dart` and `.g.dart` files for user DTOs
- [x] T007 Create user_profile_providers.dart in `flutter/lib/src/features/user_profile/application/user_profile_providers.dart` — declare `userRemoteDataSourceProvider` (depends on `authenticatedDioProvider`), `userRepositoryProvider` (depends on data source), and `userProfileNotifierProvider` (forward declaration, will be wired in US1)

**Checkpoint**: Data layer complète — repository, data source, DTOs, providers prêts.

---

## Phase 3: User Story 1 — Consulter son profil (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur peut naviguer vers /settings/profile et voir ses informations (nom, email, devise) chargées depuis le serveur, avec skeleton loading et gestion d'erreur.

**Independent Test**: Naviguer vers Paramètres → Profil, vérifier que nom, email et devise s'affichent correctement.

### Implementation for User Story 1

- [x] T008 [US1] Create UserProfileNotifier extending Notifier<AsyncValue<User>> in `flutter/lib/src/features/user_profile/application/user_profile_notifier.dart` — implement `build()` that calls `loadProfile()`. `loadProfile()` sets state to AsyncLoading, calls `userRepository.getProfile()`, sets state to AsyncData(user) or AsyncError on failure. Wire notifierProvider in providers file.
- [x] T009 [P] [US1] Create ProfileSettingsSkeleton widget in `flutter/lib/src/features/user_profile/presentation/widgets/profile_settings_skeleton.dart` — shimmer skeleton with 3 field placeholders (nom, email, devise) matching the profile screen layout. Use `shimmer` package and AppSpacing/AppRadius design tokens.
- [x] T010 [US1] Create ProfileSettingsScreen (ConsumerStatefulWidget) in `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` — AppBar with title "Profil". Body watches `userProfileNotifierProvider`. AsyncValue.when: loading → ProfileSettingsSkeleton, error → error message with retry button (calls notifier.loadProfile()), data → display 3 fields: nom (Text), email (Text), devise (Text showing symbol + name). Use AppSpacing, AppTypography design tokens. Use ConsumerStatefulWidget (et non ConsumerWidget) car US2 ajoutera du state local mutable (`_selectedCurrency`, `_hasChanged`) nécessitant `setState`.
- [x] T011 [US1] Update routing in `flutter/lib/src/routing/app_router.dart` — replace `StubSettingsScreen(title: 'Profil')` import and usage with `ProfileSettingsScreen` for the `/settings/profile` route

**Checkpoint**: US1 complète — l'écran Profil affiche les données du serveur avec loading et error states.

---

## Phase 4: User Story 2 — Modifier sa devise par défaut (Priority: P2)

**Goal**: L'utilisateur peut modifier sa devise via SelectPicker et sauvegarder la modification sur le serveur avec feedback visuel.

**Independent Test**: Ouvrir le picker devise → sélectionner une nouvelle devise → sauvegarder → vérifier le SnackBar de succès et la persistance côté serveur.

**Depends on**: US1 (l'écran doit exister)

### Implementation for User Story 2

- [x] T012 [US2] Add `updateCurrency(Currency currency)` method to UserProfileNotifier in `flutter/lib/src/features/user_profile/application/user_profile_notifier.dart` — save previous user, call `userRepository.updateProfile(defaultCurrency: currency)`, on success set state to AsyncData(updated user) and return true, on failure restore previous state and return false (for SnackBar error)
- [x] T013a [US2] Add SelectPicker for currency in ProfileSettingsScreen in `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` — convert devise field to SelectPicker with Currency items (7 devises: id=currency.name, label="${currency.symbol} — ${currency.displayName}", icon=null). Add `_selectedCurrency` (Currency?) and `_hasChanged` (bool) local state. Initialize `_selectedCurrency` from loaded user data. Update `_hasChanged` on selection change.
- [x] T013b [US2] Add save action in ProfileSettingsScreen in `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` — add save IconButton in AppBar (enabled only when `_hasChanged` is true). On save: call notifier.updateCurrency(), show SnackBar success or error via ScaffoldMessenger. Restore previous value on error (FR-009b).

**Checkpoint**: US2 complète — la devise est modifiable via picker avec sauvegarde serveur et feedback.

---

## Phase 5: User Story 3 — Champs en lecture seule (Priority: P3)

**Goal**: Les champs nom et email sont visuellement distincts des champs éditables, non interactifs, et gèrent le cas null.

**Independent Test**: Vérifier que nom et email ont un style atténué, ne réagissent pas au tap, et que "Non renseigné" s'affiche quand le nom est null.

**Depends on**: US1 (les champs doivent être affichés)

### Implementation for User Story 3

- [x] T014 [US3] Style read-only fields in ProfileSettingsScreen in `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` — extract a `_ReadOnlyField` private widget with label + value. Apply distinct visual style: text color using `theme.colorScheme.onSurfaceVariant` (atténué), no tap handler, no trailing chevron/icon. Use for nom and email fields.
- [x] T015 [US3] Handle null name display in ProfileSettingsScreen in `flutter/lib/src/features/user_profile/presentation/screens/profile_settings_screen.dart` — if `user.name` is null or empty, display "Non renseigné" in italic with `theme.colorScheme.outline` color (FR-010)

**Checkpoint**: US3 complète — champs lecture seule visuellement distincts, cas null géré.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et validation

- [x] T016 Run `flutter analyze` from `flutter/` to check for static analysis issues
- [x] T017 Run `flutter test` from `flutter/` to ensure no regressions on existing tests
- [x] T018 Manual validation following `specs/049-flutter-settings-profile/quickstart.md` test steps

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — démarrage immédiat
- **Foundational (Phase 2)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Dépend de Phase 2 — première story à implémenter
- **US2 (Phase 4)**: Dépend de US1 (l'écran ProfileSettingsScreen doit exister)
- **US3 (Phase 5)**: Dépend de US2 (même fichier — exécuter après US2 pour éviter conflits)
- **Polish (Phase 6)**: Dépend de toutes les user stories

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational)
    ↓
Phase 3 (US1: Consulter profil)  ← MVP
    ↓          ↓
Phase 4 (US2: Devise)
    ↓
Phase 5 (US3: Lecture seule)  ← Séquentiel (même fichier)
    ↓          ↓
Phase 6 (Polish)
```

- **US1 (P1)**: Après Phase 2 — indépendante
- **US2 (P2)**: Après US1 — nécessite l'écran existant pour ajouter le picker et le save
- **US3 (P3)**: Après US1 — nécessite les champs affichés pour ajouter le styling
- **US2 puis US3**: Exécuter séquentiellement — T013 (US2), T014 et T015 (US3) modifient tous `profile_settings_screen.dart`. Appliquer US2 d'abord (ajout picker/save), puis US3 (styling lecture seule) pour éviter les conflits d'édition.

### Within Each User Story

- Notifier avant Screen (US1: T008 avant T010)
- Widgets parallèles au Notifier (US1: T009 // T008)
- Routing après Screen (US1: T011 après T010)

### Parallel Opportunities

**Phase 2**:
```
T002 (DTOs) // T003 (Repository interface)  → puis T004 → T005 → T006 → T007
```

**Phase 3 (US1)**:
```
T008 (Notifier) // T009 (Skeleton)  → puis T010 (Screen) → T011 (Routing)
```

**Phase 4 → Phase 5 (US2 puis US3)** (séquentiel — même fichier):
```
T012 → T013a → T013b (US2)  →  T014 → T015 (US3)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001)
2. Phase 2: Foundational (T002–T007)
3. Phase 3: User Story 1 (T008–T011)
4. **STOP and VALIDATE**: L'écran Profil affiche nom, email, devise depuis le serveur
5. Commit stratégique après US1

### Incremental Delivery

1. Setup + Foundational → Data layer prête
2. US1 → Écran consultation fonctionnel → **MVP déployable**
3. US2 → Modification devise ajoutée → Écran pleinement fonctionnel
4. US3 → Styling lecture seule finalisé → Feature complète
5. Polish → Analyse statique + tests de non-régression

---

## Notes

- Aucun test unitaire demandé dans la spec — non inclus
- Le modèle User existant (`flutter/lib/src/domain/models/user.dart`) n'est pas modifié
- L'enum Currency existant (`flutter/lib/src/domain/enums/currency.dart`) n'est pas modifié
- Backend déjà implémenté — aucune tâche API côté `api/`
- `build_runner` nécessaire une seule fois (T006) après création des DTOs Freezed
- Commit recommandé après chaque phase complétée
- Edge case "navigation hors écran pendant chargement" : géré automatiquement par Riverpod (AsyncValue + widget lifecycle). Pas de task spécifique nécessaire.
