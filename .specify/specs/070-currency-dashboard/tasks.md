# Tasks: Currency Dashboard

**Input**: Design documents from `/specs/070-currency-dashboard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-contract.md, quickstart.md

**Tests**: Tests backend requis par la constitution (principe V — Testabilite). Tests d'integration sur les endpoints ExchangeRate, tests unitaires sur ExchangeRateService.

**Organization**: Taches groupees par user story. US2 est prerequis technique pour US1 (pas de conversion sans taux).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'executer en parallele (fichiers differents, pas de dependance)
- **[Story]**: US1-US6, maps vers les user stories de la spec

---

## Phase 1: Setup (Migrations)

**Purpose**: Creer les structures DB necessaires a toute la feature

- [X] T001 Creer la migration Flyway V13 pour ajouter `currencies` a `user_preferences` et creer la table `exchange_rates` dans `api/src/main/resources/db/migration/V13__add_currencies_and_exchange_rates.sql`

---

## Phase 2: Foundational — Backend (Blocking Prerequisites)

**Purpose**: Entites, services, endpoints et tests backend necessaires avant tout travail frontend

**CRITICAL**: Aucune tache frontend ne peut commencer avant la fin de cette phase

- [X] T002 [P] Creer `CurrencyListConverter` (AttributeConverter CSV <-> List\<Currency\>) dans `api/src/main/java/fr/kksdev/budget/api/converter/CurrencyListConverter.java`
- [X] T003 [P] Creer l'entite JPA `ExchangeRate` (id, user, baseCurrency, targetCurrency, rate DECIMAL(20,6), updatedAt) avec contrainte UNIQUE dans `api/src/main/java/fr/kksdev/budget/api/model/ExchangeRate.java`
- [X] T004 [P] Creer `ExchangeRateRepository` (JpaRepository + findAllByUserId, findByUserIdAndBaseCurrencyAndTargetCurrency, deleteByUserIdAndBaseCurrencyAndTargetCurrency) dans `api/src/main/java/fr/kksdev/budget/api/repository/ExchangeRateRepository.java`
- [X] T005 Modifier `UserPreference` : ajouter champ `currencies` (List\<Currency\>, @Convert CurrencyListConverter, default [EUR]) dans `api/src/main/java/fr/kksdev/budget/api/model/UserPreference.java`
- [X] T006 [P] Creer les DTOs `ExchangeRateRequest` (baseCurrency, targetCurrency, rate avec validation @NotNull, @DecimalMin, @Digits) et `ExchangeRateResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/request/ExchangeRateRequest.java` et `dto/response/ExchangeRateResponse.java`
- [X] T007 Modifier `UserPreferenceRequest` et `UserPreferenceResponse` : ajouter champ optionnel `currencies` (List\<Currency\>) dans `api/src/main/java/fr/kksdev/budget/api/dto/request/UserPreferenceRequest.java` et `dto/response/UserPreferenceResponse.java`
- [X] T008 Creer `ExchangeRateService` avec methodes : getAll(userId), upsert(request, userId), delete(userId, base, target), rebaseRates(userId, newBaseCurrency) — rebase inverse tous les taux (1/rate, arrondi 6 decimales, RoundingMode.HALF_UP) dans une transaction atomique. Valider que le resultat de l'inversion reste dans les limites DECIMAL(20,6) (max 14 chiffres entiers — risque negligeable en pratique). Logging INFO sur chaque operation — dans `api/src/main/java/fr/kksdev/budget/api/service/ExchangeRateService.java`
- [X] T009 Modifier `PreferenceService.updatePreferences()` : gerer le champ `currencies` (validation pas de doublons, min 1 element), detecter changement de currencies[0] et appeler `ExchangeRateService.rebaseRates()`, mettre a jour `getOrCreate()` pour initialiser currencies depuis `User.defaultCurrency`, mettre a jour `toResponse()`. La protection contre la suppression de la devise principale (FR-013) est un concern client (T042, T044) — le backend valide uniquement min 1 element — dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java`
- [X] T010 Creer `ExchangeRateController` avec endpoints GET /exchange-rates, PUT /exchange-rates (upsert), DELETE /exchange-rates/{baseCurrency}/{targetCurrency} dans `api/src/main/java/fr/kksdev/budget/api/controller/ExchangeRateController.java`
- [X] T011 Modifier `UserService`, `UserController`, `UserResponse` : supprimer le champ `defaultCurrency` de la reponse profil. Supprimer `UserUpdateRequest` si devenu vide (seul champ etait defaultCurrency) ou le conserver avec un champ `name` pour future extension. La devise est desormais dans preferences.currencies. **Adapter aussi `TransactionService.getMonthlySummary()`** : remplacer `userRepository.getReferenceById(userId).getDefaultCurrency()` par `preferenceService.getOrCreate(userId).getCurrencies().get(0)` (injecter `PreferenceService` dans `TransactionService`). **Mettre a jour les tests existants** qui referencent `defaultCurrency` : `UserControllerTest` (3 tests sur profil/update), `SubscriptionServiceTest` (builder User avec defaultCurrency), `AccountServiceTest` (builder User avec defaultCurrency) — dans `api/src/main/java/fr/kksdev/budget/api/service/UserService.java`, `service/TransactionService.java`, `controller/UserController.java`, `dto/UserUpdateRequest.java`, `dto/UserResponse.java`, `api/src/test/java/.../controller/UserControllerTest.java`, `service/SubscriptionServiceTest.java`, `service/AccountServiceTest.java`
- [X] T012 Creer la migration Flyway V14 pour supprimer la colonne `default_currency` de la table `users` dans `api/src/main/resources/db/migration/V14__remove_user_default_currency.sql`
- [X] T013 [P] Creer les tests d'integration `ExchangeRateControllerTest` : should_returnEmptyList_when_noRates, should_createRate_when_validUpsert, should_updateRate_when_existingPair, should_deleteRate_when_exists, should_return404_when_deletingNonExistent, should_return400_when_rateNegative, should_return400_when_sameCurrency — dans `api/src/test/java/fr/kksdev/budget/api/controller/ExchangeRateControllerTest.java`
- [X] T014 [P] Creer les tests unitaires `ExchangeRateServiceTest` : should_invertAllRates_when_rebase, should_preservePrecision_when_invertHighRate (ex: 655.957 -> 0.001524), should_rejectNegativeRate, should_rejectZeroRate, should_upsertExistingPair — dans `api/src/test/java/fr/kksdev/budget/api/service/ExchangeRateServiceTest.java`

**Checkpoint**: Backend complet — tous les endpoints fonctionnels, migrations appliquees, tests passent. Tester via Swagger UI ou `mvn test`.

---

## Phase 3: Foundational — Flutter & Angular (Infrastructure Client)

**Purpose**: Modeles, services et helpers partages necessaires pour les user stories

- [X] T015 [P] Creer le modele Freezed `ExchangeRate` (id, baseCurrency: Currency, targetCurrency: Currency, rate: double, updatedAt) dans `flutter/lib/src/domain/models/exchange_rate.dart` — utiliser l'enum Currency existant (domain/enums/), pas de String
- [X] T016 [P] Creer l'interface `ExchangeRateRepository` (getAll, upsert, delete) dans `flutter/lib/src/domain/repositories/exchange_rate_repository.dart`
- [X] T017 [P] Creer `ExchangeRateRemoteDataSource` (Dio, endpoints GET/PUT/DELETE /exchange-rates) dans `flutter/lib/src/features/exchange_rates/data/exchange_rate_remote_data_source.dart`
- [X] T018 Creer `ExchangeRateRepositoryImpl` (implements ExchangeRateRepository, delegue a remote data source) dans `flutter/lib/src/features/exchange_rates/data/exchange_rate_repository_impl.dart`
- [X] T019 Ajouter `exchangeRateRepositoryProvider` (remote only, pas de local) dans `flutter/lib/src/data/data_mode_provider.dart`
- [X] T020 Executer `dart run build_runner build --delete-conflicting-outputs` dans `flutter/` pour generer les fichiers Freezed/JSON du modele ExchangeRate
- [X] T021 Creer `ExchangeRateNotifier` (Notifier\<ListState\<ExchangeRate\>\>, methodes loadItems/upsert/delete + getRateFor(base, target) helper) dans `flutter/lib/src/features/exchange_rates/application/exchange_rate_notifier.dart`
- [X] T022 [P] Creer `CurrencyConverter` helper statique (convert(amount, fromCurrency, toCurrency, rates), invertRate(rate), respecte decimalPlaces de la devise cible, prefixe ~). Inclure une map constante `fixedParityRates` pour les parites fixes connues (EUR/XOF=655.957) utilisee par T030 et T031 pour le pre-remplissage — dans `flutter/lib/src/utils/currency_converter.dart`
- [X] T023 Modifier `PreferenceRemoteDataSource` et le modele de preferences Flutter : supporter le champ `currencies` (List\<Currency\>) dans les requetes/reponses PUT/GET /users/me/preferences, ajouter les methodes getCurrencies/setCurrencies dans `flutter/lib/src/data/remote/preference_remote_data_source.dart` et les fichiers de modele de preferences concernes
- [X] T024 [P] Creer le modele TypeScript `ExchangeRate` interface dans `app/src/app/core/models/exchange-rate.model.ts`
- [X] T025 [P] Creer `ExchangeRateService` (signal-based, getAll/upsert/delete, cache local via signal) dans `app/src/app/core/services/exchange-rate.ts`
- [X] T026 [P] Creer `ConversionService` (signal-based, inject ExchangeRateService + PreferenceService, methodes convert(amount, from, to)/canConvert(from, to), computed pour taux disponibles) dans `app/src/app/core/services/conversion.ts`
- [X] T027 Modifier `PreferenceService` : ajouter signal `currencies` (Signal\<string[]\>), mettre a jour loadPreferences/update pour gerer le champ currencies, ajouter `primaryCurrency` computed (currencies()[0]) dans `app/src/app/core/services/preference.ts`
- [X] T028 Modifier `UserPreference` interface : ajouter champ `currencies: string[]` dans `app/src/app/core/models/preference.model.ts`

**Checkpoint**: Infrastructure client prete. Modeles, services et helpers disponibles pour les user stories.

---

## Phase 4: User Story 2 — Saisir et gerer mes taux de conversion (Priority: P1)

**Goal**: L'utilisateur peut creer, modifier et supprimer ses taux de conversion depuis Parametres > Devises & Taux

**Independent Test**: Aller dans Parametres > Devises & Taux, saisir un taux EUR->XOF = 655.957, verifier qu'il est persiste et visible dans la liste

### Flutter

- [X] T029 [US2] Creer `CurrencySettingsScreen` (ConsumerWidget, affiche la liste des taux existants avec option edit/delete, bouton ajouter un taux) dans `flutter/lib/src/features/exchange_rates/presentation/currency_settings_screen.dart`
- [X] T030 [US2] Creer `RateForm` widget (ConsumerStatefulWidget, champs : devise base (read-only = principale), devise cible (SelectPicker), taux (TextFormField 6 decimales), pre-remplissage parities fixes EUR/XOF=655.957) dans `flutter/lib/src/features/exchange_rates/presentation/widgets/rate_form.dart`
- [X] T031 [US2] Creer `RateCalculator` widget (StatefulWidget, deux champs montants « J'ai X [EUR] = Y [USD] », calcul automatique rate=Y/X, affiche le taux calcule) dans `flutter/lib/src/features/exchange_rates/presentation/widgets/rate_calculator.dart`
- [X] T032 [US2] Ajouter la route `/settings/currencies` dans `flutter/lib/src/routing/app_router.dart` et l'entree dans le hub settings `flutter/lib/src/features/settings/presentation/settings_hub_screen.dart`

### Angular

- [X] T033 [P] [US2] Creer `CurrencySettingsComponent` (standalone, OnPush, liste des taux, formulaire upsert inline avec pre-remplissage parities fixes, calculateur de taux, suppression) dans `app/src/app/features/settings/currency-settings/currency-settings.ts`
- [X] T034 [US2] Ajouter la route `/settings/currencies` dans `app/src/app/features/settings/settings.routes.ts` et l'entree dans le menu settings

**Checkpoint**: L'utilisateur peut gerer ses taux dans les deux apps. Verifier CRUD complet + pre-remplissage + calculateur.

---

## Phase 5: User Story 1 — Voir le patrimoine total dans ma devise principale (Priority: P1) MVP

**Goal**: Le dashboard affiche le patrimoine total agrege dans une devise unique avec pill selector

**Independent Test**: Creer 2 comptes (EUR + XOF) + 1 taux EUR/XOF. Le dashboard affiche le patrimoine total converti en EUR.

### Flutter

- [X] T035 [US1] Creer `CurrencyPillSelector` widget (StatelessWidget, row de pills pour chaque devise configuree, pill active = devise principale, onTap callback) dans `flutter/lib/src/features/dashboard/presentation/widgets/currency_pill_selector.dart`
- [X] T036 [US1] Modifier `DashboardNotifier` / `DashboardState` : ajouter `activeCurrency` (Currency) et `exchangeRates` (List\<ExchangeRate\>) au state, charger les taux et les currencies au init. NE PAS calculer les montants convertis dans le notifier (FR-006 : la conversion est un concern de la presentation layer) dans `flutter/lib/src/features/dashboard/application/dashboard_notifier.dart`
- [X] T037 [US1] Modifier `DashboardScreen` : integrer le `CurrencyPillSelector` sous le header, passer `activeCurrency` et `exchangeRates` aux sections enfant. Les sections enfant utilisent `CurrencyConverter.convert()` pour calculer les montants convertis dans la presentation layer. Si aucun taux n'est disponible, afficher les totaux par devise separement en fallback (FR-014) dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart`
- [X] T038 [US1] Modifier `HeroAccountSection` : afficher le solde converti dans `activeCurrency` si la devise du compte differe, utiliser `CurrencyConverter.convert()`, afficher avertissement si taux manquant dans `flutter/lib/src/features/dashboard/presentation/widgets/hero_account_section.dart`
- [X] T039 [US1] Modifier `MiniCardsSection` : agreger les montants abonnements et dettes convertis dans `activeCurrency` via `CurrencyConverter.convert()`, afficher avertissement si taux manquant dans `flutter/lib/src/features/dashboard/presentation/widgets/mini_cards_section.dart`

### Angular

- [X] T040 [P] [US1] Creer `CurrencyPillSelectorComponent` (standalone, OnPush, input currencies + activeCurrency, output currencyChange) dans `app/src/app/features/dashboard/components/currency-pill-selector.ts`
- [X] T041 [US1] Modifier `Dashboard` component : ajouter `activeCurrency` signal, integrer pill selector, remplacer `accountTotalsByCurrency` par un computed `convertedTotalBalance` qui agrege via ConversionService, gerer le fallback (totaux separes si pas de taux) dans `app/src/app/features/dashboard/dashboard.ts`

**Checkpoint**: Dashboard unifie fonctionnel sur les deux apps. Patrimoine total converti visible.

---

## Phase 6: User Story 5 — Gerer les devises dans les parametres (Priority: P2)

**Goal**: L'utilisateur peut ajouter, retirer et reordonner ses devises depuis les parametres

**Independent Test**: Ajouter USD, reordonner en [XOF, EUR, USD], verifier que XOF devient la devise principale

### Flutter

- [X] T042 [US5] Enrichir `CurrencySettingsScreen` : ajouter une section « Mes devises » en haut avec ReorderableListView (drag & drop), bouton ajouter devise (SelectPicker filtre les devises non configurees), suppression avec avertissement si comptes associes (verifier via le state `accountListProvider` en filtrant par `account.currency == deviseASupprimer`), la premiere devise est marquee « Principale », empecher suppression de la principale (FR-013), sauvegarder l'ordre via PUT /users/me/preferences dans `flutter/lib/src/features/exchange_rates/presentation/currency_settings_screen.dart`
- [X] T043 [US5] Creer `CurrencyConfigNotifier` dedie : gerer le state currencies (List\<Currency\>), methodes addCurrency/removeCurrency/reorderCurrencies, sync avec PreferenceRemoteDataSource (PUT /users/me/preferences) dans `flutter/lib/src/features/exchange_rates/application/currency_config_notifier.dart`

### Angular

- [X] T044 [US5] Enrichir `CurrencySettingsComponent` : ajouter section « Mes devises » avec drag & drop (CDK DragDrop), ajout/suppression devises, avertissement comptes associes, sauvegarde via PreferenceService dans `app/src/app/features/settings/currency-settings/currency-settings.ts`

**Checkpoint**: Gestion complete des devises. L'ajout/suppression/reordonnancement fonctionne et persiste.

---

## Phase 7: User Story 3 — Changer rapidement de devise depuis le dashboard (Priority: P2)

**Goal**: Tap sur un pill change la devise principale instantanement, persiste apres debounce 2s ou navigation hors dashboard

**Independent Test**: 2 devises configurees, tap sur la 2e, le dashboard se recalcule instantanement, quitter et revenir — la 2e devise est toujours active

### Flutter

- [X] T045 [US3] Modifier `DashboardScreen` : implementer la logique de changement de devise au tap sur pill — reorder `currencies` en memoire, recalcul instantane via inversion locale (CurrencyConverter.invertRate, FR-016) sans appel serveur, debounce 2000ms via Timer puis PUT /users/me/preferences, annuler le timer si nouveau tap. Au dispose, si un changement est en attente (timer actif), persister immediatement avant de dispose le timer. Apres persistance confirmee, re-fetch GET /exchange-rates pour synchroniser les taux inverses par le backend dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart`

### Angular

- [X] T046 [US3] Modifier `Dashboard` component : implementer debounce 2000ms (rxjs debounceTime ou setTimeout) au changement de pill, persister via PreferenceService.update({ currencies: newOrder }), recalcul instantane via inversion locale (1/rate, FR-016) sans attendre la reponse. Apres reponse du PUT, appeler ExchangeRateService.getAll() pour synchroniser les taux inverses par le backend dans `app/src/app/features/dashboard/dashboard.ts`

**Checkpoint**: Changement de devise fluide (< 200ms percu). Persistance verifiee apres relancement. Taux inverses synchronises.

---

## Phase 8: User Story 4 — Voir les montants convertis dans les listes (Priority: P2)

**Goal**: Chaque item en devise etrangere affiche un sous-texte avec le montant converti dans la devise principale (prefixe ~)

**Independent Test**: Transaction de 50 000 XOF avec taux EUR/XOF. La liste affiche « 50 000 CFA » + sous-texte « ~ 76 EUR ».

### Flutter

- [X] T047 [P] [US4] Modifier `TransactionListScreen` : si la devise de la transaction (via `account.currency` — recuperer la devise du compte via `accountListProvider` en croisant `transaction.accountId`) differe de la devise principale, afficher un sous-texte converti via `CurrencyConverter.convert()` sous le montant, avec prefixe ~. Afficher indicateur visuel si taux manquant dans `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart`
- [X] T048 [P] [US4] Modifier `SubscriptionListScreen` : pour chaque abonnement en devise etrangere, ajouter sous-texte montant converti dans la devise principale dans `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart`
- [X] T049 [P] [US4] Modifier `DebtListScreen` : pour chaque dette en devise etrangere, ajouter sous-texte montant converti dans la devise principale dans `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`

### Angular

- [X] T050 [P] [US4] Creer `ConvertAmountPipe` (standalone, pure, inject ConversionService, transforme (amount, fromCurrency) en string « ~ XX EUR » ou vide si meme devise, indicateur si taux manquant) dans `app/src/app/shared/pipes/convert-amount.pipe.ts`
- [X] T051 [P] [US4] Modifier `Transactions` component : ajouter sous-texte converti sous chaque montant en devise etrangere via ConvertAmountPipe dans `app/src/app/features/transactions/transactions.ts`
- [X] T052 [P] [US4] Modifier `Subscriptions` component : ajouter sous-texte converti pour les abonnements en devise etrangere dans `app/src/app/features/subscriptions/subscriptions.ts`
- [X] T053 [P] [US4] Modifier `Debts` component : ajouter sous-texte converti pour les dettes en devise etrangere dans `app/src/app/features/debts/debts.ts`

**Checkpoint**: Tous les montants en devise etrangere affichent un sous-texte converti dans les deux apps.

---

## Phase 8b: Tests client (CurrencyConverter & ConversionService)

**Purpose**: Tests unitaires sur les composants critiques de conversion cote client

- [X] T059 [P] Creer les tests unitaires `CurrencyConverter` : should_convertAmount_when_rateExists, should_returnNull_when_noRate, should_roundToDecimalPlaces_when_converting (0 pour XOF, 2 pour EUR), should_invertRate_when_called, should_preservePrecision_when_invertHighRate (655.957 → 0.001524) — dans `flutter/test/src/utils/currency_converter_test.dart`
- [X] T060 [P] Creer les tests unitaires `ConversionService` : should_convertAmount_when_rateAvailable, should_returnNull_when_noRate, should_indicateCanConvert_when_rateExists, should_handleSameCurrency_when_converting — dans `app/src/app/core/services/conversion.spec.ts`

**Checkpoint**: Tests de conversion passent sur les deux plateformes.

---

## Phase 9: User Story 6 — Proposition automatique du taux lors de la creation d'un compte (Priority: P3)

**Goal**: Creer un compte dans une nouvelle devise propose automatiquement la saisie du taux de conversion

**Independent Test**: Creer un compte en GBP sans taux EUR/GBP existant — un dialogue propose la saisie du taux

### Flutter

- [X] T054 [US6] Modifier le flux de creation de compte : apres sauvegarde, si la devise du compte n'a pas de taux vers la devise principale, afficher un dialog proposant la saisie du taux (avec pre-remplissage si parite fixe, sinon calculateur). Si l'utilisateur decline, le compte est cree sans taux dans `flutter/lib/src/features/accounts/presentation/widgets/account_form.dart`

### Angular

- [X] T055 [US6] Modifier le flux de creation de compte : apres sauvegarde, si la devise du compte n'a pas de taux, afficher un dialog proposant la saisie du taux. Utiliser ExchangeRateService.upsert() si accepte dans `app/src/app/features/settings/account-form/account-form.ts`

**Checkpoint**: Proposition de taux fonctionnelle a la creation de compte dans les deux apps.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Validations edge cases, coherence cross-app

- [X] T056 Valider les edge cases sur les deux apps : taux = 0 refuse, une seule devise = pas de selecteur, tous taux manquants = fallback totaux par devise, suppression devise principale impossible, perte de precision arrondie selon decimalPlaces, taux pre-remplis modifiables par l'utilisateur (FR-019)
- [X] T057 Verifier la coherence Flutter/Angular : meme affichage pour les montants convertis (prefixe ~, arrondi identique), meme UX pour le pill selector et les parametres devises
- [X] T058 Executer le scenario quickstart.md de bout en bout sur les deux apps (2 comptes, 1 taux, dashboard converti, changement devise, persistance)

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
  └── Phase 2 (Backend + Tests)
        ├── Phase 3 (Flutter/Angular infra)
        │     ├── Phase 4 (US2 — Taux) ← prerequis technique
        │     │     ├── Phase 5 (US1 — Dashboard) ← MVP
        │     │     │     └── Phase 7 (US3 — Changement devise)
        │     │     ├── Phase 6 (US5 — Gestion devises)
        │     │     │     └── Phase 7 (US3 — depend aussi de US5)
        │     │     └── Phase 8 (US4 — Listes converties)
        │     │           └── Phase 8b (Tests client)
        │     └── Phase 4 ──► Phase 9 (US6 — Proposition taux compte)
        └── Phase 10 (Polish)
```

### User Story Dependencies

- **US2 (P1)**: Prerequis pour US1, US3, US4. Peut commencer des Phase 3 terminee.
- **US1 (P1)**: Depend de US2. MVP — le dashboard unifie est la valeur coeur.
- **US5 (P2)**: Depend de Phase 3 (infra). Independant de US1.
- **US3 (P2)**: Depend de US1 (pill selector) et US5 (gestion devises pour persistence).
- **US4 (P2)**: Depend de US2 (taux) et Phase 3 (converter). Independant de US1.
- **US6 (P3)**: Depend de Phase 3 (infra) et Phase 4 (US2 — upsert taux). Independant de US1, US3, US4, US5.

### Within Each User Story

- Modeles avant services
- Services avant endpoints/ecrans
- Flutter et Angular d'une meme story peuvent s'executer en parallele

### Parallel Opportunities

**Phase 2** : T002, T003, T004, T006 en parallele (fichiers differents) ; T013, T014 en parallele (tests independants)
**Phase 3** : T015, T016, T017 (Flutter) en parallele avec T024, T025, T026 (Angular)
**Phase 4 (US2)** : T033 (Angular) en parallele avec T029-T032 (Flutter)
**Phase 5 (US1)** : T040 (Angular) en parallele avec T035-T039 (Flutter)
**Phase 8 (US4)** : T047, T048, T049 (Flutter) tous en parallele ; T050, T051, T052, T053 (Angular) tous en parallele

---

## Parallel Example: Phase 3 (Infrastructure Client)

```
# Flutter — tous en parallele (fichiers independants) :
T015: ExchangeRate model (Freezed)
T016: ExchangeRateRepository interface
T017: ExchangeRateRemoteDataSource

# Angular — tous en parallele (fichiers independants) :
T024: ExchangeRate model
T025: ExchangeRateService
T026: ConversionService
```

## Parallel Example: Phase 8 (US4 — Listes converties)

```
# Flutter — tous en parallele (fichiers differents) :
T047: transaction_day_group.dart
T048: subscription_list_screen.dart
T049: debt_list_screen.dart

# Angular — tous en parallele (fichiers differents) :
T050: convert-amount.pipe.ts
T051: transactions.ts
T052: subscriptions.ts
T053: debts.ts
```

---

## Implementation Strategy

### MVP First (US2 + US1)

1. Phase 1 : Setup (migration V13)
2. Phase 2 : Backend complet (V13 + V14, entites, services, controllers, tests)
3. Phase 3 : Infrastructure client (modeles, services, helpers)
4. Phase 4 : US2 — Saisir les taux (prerequis)
5. Phase 5 : US1 — Dashboard unifie avec pill selector
6. **STOP ET VALIDER** : Tester le scenario quickstart.md + `mvn test`
7. Deploy/demo si pret

### Incremental Delivery

1. Setup + Backend + Tests + Infra client → Fondation prete
2. US2 (taux) → CRUD taux fonctionnel → Demo
3. US1 (dashboard) → Patrimoine converti → **MVP!**
4. US5 (gestion devises) → Parametres complets → Demo
5. US3 (changement devise) → UX fluide → Demo
6. US4 (listes converties) → Experience complete → Demo
7. US6 (proposition taux) → Polish UX → Release

---

## Notes

- Pas de Drift/SQLite pour cette feature (taux serveur uniquement — remote only)
- `build_runner` necessaire une seule fois (T020) apres creation du modele ExchangeRate Freezed
- La migration V14 (suppression defaultCurrency) DOIT etre executee APRES adaptation du code UserService/UserController (T011)
- Les parities fixes (EUR/XOF=655.957) sont des constantes client-side, pas stockees en base
- XAF n'est pas ajoute a l'enum Currency dans cette feature (YAGNI — voir research.md R6)
- Commit recommande apres chaque phase completee
- La conversion des montants Flutter est un concern de la presentation layer (FR-006) — pas dans les Notifiers
