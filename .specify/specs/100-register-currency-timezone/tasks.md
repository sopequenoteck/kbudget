# Tasks: Devise et fuseau horaire a l'inscription

**Input**: Design documents from `/specs/100-register-currency-timezone/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Inclus (constitution exige des tests unitaires et d'integration).

**Organization**: Tasks groupees par user story pour implementation et tests independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Pas de setup necessaire — le projet existe, pas de nouvelle dependance, pas de migration Flyway.

(Phase vide — aucune tache de setup requise.)

---

## Phase 2: Foundational (Backend — RegisterRequest + AuthService + PreferenceService)

**Purpose**: Enrichir le backend pour accepter currency et timezone a l'inscription. DOIT etre complete avant les user stories frontend.

- [x] T001 Ajouter les champs optionnels `currency` (Currency enum) et `timezone` (String) au record `RegisterRequest` dans `api/src/main/java/fr/kksdev/budget/api/dto/request/RegisterRequest.java`
- [x] T002 Modifier `AccountService.createDefaultAccount(User user)` pour accepter un parametre `Currency currency` et creer le compte avec cette devise dans `api/src/main/java/fr/kksdev/budget/api/service/AccountService.java`
- [x] T003 Ajouter une methode `createInitialPreference(User user, Currency currency, String timezone)` dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java` — cree les preferences avec currencies=[currency] et timezone fourni. Valider timezone via ZoneId.of(), fallback "Europe/Paris" si invalide/null
- [x] T004 Modifier `AuthService.register()` dans `api/src/main/java/fr/kksdev/budget/api/service/AuthService.java` — extraire currency (fallback EUR) et timezone du RegisterRequest (passer le timezone brut a PreferenceService qui valide et applique le fallback), appeler `createDefaultAccount(user, currency)` et `createInitialPreference(user, currency, timezone)`
- [x] T005 [P] Ajouter tests unitaires dans `api/src/test/java/fr/kksdev/budget/api/service/AuthServiceTest.java` — should_createAccountWithXOF_when_currencyProvided, should_createAccountWithEUR_when_currencyNull, should_createPreferenceWithTimezone_when_timezoneProvided, should_useDefaultTimezone_when_timezoneInvalid
- [x] T006 [P] Ajouter tests unitaires dans `api/src/test/java/fr/kksdev/budget/api/service/AccountServiceTest.java` — should_createDefaultAccountWithCurrency_when_currencyProvided
- [x] T007 [P] Ajouter tests unitaires dans `api/src/test/java/fr/kksdev/budget/api/service/PreferenceServiceTest.java` — should_createInitialPreference_when_called, should_fallbackTimezone_when_invalidTimezone
- [x] T008 Ajouter tests d'integration dans `api/src/test/java/fr/kksdev/budget/api/controller/AuthControllerTest.java` — should_registerWithCurrency_when_currencyProvided, should_registerWithDefaults_when_noCurrencyOrTimezone, should_rejectRegistration_when_invalidCurrency

**Checkpoint**: Backend pret — POST /api/auth/register accepte currency et timezone. Tests passent.

---

## Phase 3: User Story 1 — Choix de la devise a l'inscription (Priority: P1) MVP

**Goal**: L'utilisateur choisit sa devise dans le formulaire d'inscription (web et mobile). Le Compte Principal et les preferences sont initialises avec cette devise.

**Independent Test**: S'inscrire avec XOF → verifier Compte Principal en XOF et preferences currencies=[XOF].

### Implementation Angular (US1)

- [x] T009 [US1] Ajouter un FormControl `currency` (defaut 'EUR') au `registerForm` et un selecteur de devise (apres le champ Nom, avant Email) affichant symbole + nom pour chaque devise dans `app/src/app/features/auth/auth.ts` et `app/src/app/features/auth/auth.html`
- [x] T010 [US1] Modifier `AuthService.register()` dans `app/src/app/core/services/auth.ts` pour envoyer le champ `currency` dans le payload POST /auth/register

### Implementation Flutter (US1)

- [x] T011 [P] [US1] Ajouter les champs optionnels `currency` et `timezone` au DTO `RegisterRequest` dans `flutter/lib/src/data/remote/dtos/auth_dtos.dart` et regenerer les fichiers Freezed (inclut timezone pour eviter double modification du DTO — timezone sera utilise en Phase 4/US2)
- [x] T012 [US1] Ajouter un selecteur de devise (DropdownButtonFormField ou equivalent) apres le champ Nom et avant Email dans `flutter/lib/src/features/auth/presentation/register_screen.dart` — afficher symbole + nom, pre-selectionner EUR
- [x] T013 [US1] Modifier `AuthNotifier.register()` dans `flutter/lib/src/features/auth/application/auth_notifier.dart` pour accepter et transmettre le parametre `currency`
- [x] T014 [US1] Modifier `AuthRemoteDataSource` et `AuthRepository` pour transmettre `currency` dans le payload d'inscription dans `flutter/lib/src/features/auth/data/auth_remote_data_source.dart` et `flutter/lib/src/domain/repositories/auth_repository.dart`

**Checkpoint**: US1 complete — inscription avec choix de devise fonctionnelle sur web et mobile.

---

## Phase 4: User Story 2 — Detection automatique du fuseau horaire (Priority: P2)

**Goal**: Le timezone est detecte automatiquement par le client et envoye silencieusement dans la requete d'inscription.

**Independent Test**: S'inscrire depuis un navigateur en Africa/Lome → verifier preferences timezone="Africa/Lome" sans action utilisateur.

### Implementation Angular (US2)

- [x] T015 [US2] Detecter le timezone via `Intl.DateTimeFormat().resolvedOptions().timeZone` et l'inclure dans le payload d'inscription (champ `timezone`) dans `app/src/app/features/auth/auth.ts` — fallback "Europe/Paris" si detection echoue

### Implementation Flutter (US2)

- [x] T016 [P] [US2] Detecter le timezone du device et l'inclure dans le payload d'inscription (champ `timezone`) dans `flutter/lib/src/features/auth/presentation/register_screen.dart` et le transmettre via `AuthNotifier.register()` — fallback "Europe/Paris" si detection echoue

**Checkpoint**: US2 complete — timezone detecte et persiste sans intervention utilisateur.

---

## Phase 5: User Story 3 — Retrocompatibilite (Priority: P1)

**Goal**: Les clients non mis a jour (sans currency/timezone) continuent de fonctionner avec les defauts EUR / Europe/Paris.

**Independent Test**: POST /auth/register avec { email, password, name } uniquement → compte cree en EUR, timezone Europe/Paris.

(Deja couvert par T001 + T004 + T008 — les champs sont optionnels avec fallbacks. Pas de tache supplementaire, mais verification explicite via les tests d'integration T008.)

**Checkpoint**: Retrocompatibilite assuree par les tests T008.

---

## Phase 6: Nettoyage — Suppression selecteur devise fantome du profil (FR-014)

**Purpose**: Supprimer le selecteur "Devise par defaut" non fonctionnel dans le profil Angular et le remplacer par un lien vers "Devises & Taux".

- [x] T017 Supprimer le `currencyControl`, l'import `CurrencyService`, et la logique `onCurrencyChange`/`updateDefaultCurrency` dans `app/src/app/features/settings/components/profile/profile.ts` — verifier que `ReactiveFormsModule` et `SelectPicker` ne sont pas utilises par d'autres elements du template avant suppression
- [x] T018 Remplacer le selecteur devise par un lien navigant vers `/settings/currencies` ("Devises & Taux") dans `app/src/app/features/settings/components/profile/profile.html`
- [x] T019 [P] Mettre a jour la description du menu Profil Flutter de 'Nom, email, devise' vers 'Nom, email' dans `flutter/lib/src/features/settings/domain/settings_section.dart` (ligne 39)

**Checkpoint**: Profil Angular ne contient plus de selecteur devise fantome, lien fonctionnel vers Devises & Taux.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [x] T020 Verifier que tous les tests existants passent toujours (`cd api && mvn test`, `cd app && ng test`)
- [x] T021 Executer le quickstart.md — tester manuellement inscription avec XOF, inscription sans currency, verification du compte et des preferences
- [x] T022 [P] Regenerer les fichiers Freezed/json_serializable Flutter (`cd flutter && dart run build_runner build --delete-conflicting-outputs`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 2 (Foundational)**: Aucune dependance — commence immediatement
- **Phase 3 (US1)**: Depend de Phase 2 (backend pret)
- **Phase 4 (US2)**: Depend de Phase 3 (formulaire avec currency deja en place pour ajouter timezone)
- **Phase 5 (US3)**: Couvert par Phase 2 (tests)
- **Phase 6 (Nettoyage)**: Independant — peut etre fait en parallele de Phase 3/4
- **Phase 7 (Polish)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1 (devise)**: Depend uniquement de Phase 2 (backend)
- **US2 (timezone)**: Depend de US1 (formulaire Angular/Flutter modifie pour y ajouter le timezone)
- **US3 (retrocompat)**: Aucune dependance specifique — couvert par les fallbacks backend

### Parallel Opportunities

- T005, T006, T007 : tests backend en parallele
- T009 (Angular US1) et T011-T014 (Flutter US1) : en parallele apres Phase 2
- T015 (Angular US2) et T016 (Flutter US2) : en parallele
- T017-T018 (nettoyage profil) : en parallele de Phase 3/4

---

## Parallel Example: Phase 2

```bash
# Apres T001-T004 (sequentiels), lancer les tests en parallele :
Task T005: "Tests AuthServiceTest"
Task T006: "Tests AccountServiceTest"
Task T007: "Tests PreferenceServiceTest"
```

## Parallel Example: Phase 3 (US1)

```bash
# Angular et Flutter en parallele :
Task T009-T010: "Angular — formulaire + auth service"
Task T011-T014: "Flutter — DTO + ecran + notifier + data source"
```

---

## Implementation Strategy

### MVP First (US1 seul)

1. Complete Phase 2: Backend (T001-T008)
2. Complete Phase 3: US1 Angular + Flutter (T009-T014)
3. **STOP and VALIDATE**: Inscription avec XOF → Compte Principal en XOF
4. Deploy/demo si pret

### Incremental Delivery

1. Phase 2 → Backend pret
2. Phase 3 (US1) → Choix devise fonctionnel → Demo MVP
3. Phase 4 (US2) → Timezone auto-detecte → Demo
4. Phase 6 → Nettoyage profil
5. Phase 7 → Validation finale

---

## Notes

- Pas de migration Flyway — toutes les colonnes existent deja
- T011 necessite `dart run build_runner build` apres modification du DTO Freezed
- Le selecteur devise affiche symbole + nom complet (ex: "CFA - Franc CFA (BCEAO)") — utiliser les proprietes `symbol` et `displayName` de l'enum Currency
- La detection timezone Flutter peut necessiter le package `flutter_timezone` si `DateTime.now().timeZoneName` ne retourne pas un identifiant IANA — a evaluer lors de T016
