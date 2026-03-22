# Tasks: Currency Rebase Propagation

**Input**: Design documents from `/specs/095-currency-rebase-propagation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/preferences-api.md, quickstart.md

**Organization**: Tasks groupées par user story. Pas de phase Setup ni Foundational — toute l'infrastructure existe déjà.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: User Story 1 + 2 — Rebase automatique et propagation UI (Priority: P1)

**Goal**: Quand l'utilisateur change sa devise principale, les taux sont automatiquement rebasés côté serveur et l'UI (web + mobile) se met à jour instantanément.

**Independent Test**: Changer la devise principale de EUR → XOF → vérifier que les taux en base sont rebasés et que le dashboard affiche les montants convertis corrects sans rechargement.

### Backend

- [x] T001 [US1] Ajouter le rebase automatique dans `PreferenceService.updatePreferences()` — détecter le changement de `currencies[0]` et appeler `exchangeRateService.rebaseRates(userId, oldPrimary, newPrimary)` avant `setCurrencies()` dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java`
- [x] T002 [US1] Ajouter le log INFO pour le déclenchement du rebase dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java`
- [x] T003 [US1] Ajouter test `should_rebaseRates_when_primaryCurrencyChanges` dans `api/src/test/java/fr/kksdev/budget/api/service/PreferenceServiceTest.java`
- [x] T004 [US1] Ajouter test `should_notRebaseRates_when_primaryCurrencyUnchanged` dans `api/src/test/java/fr/kksdev/budget/api/service/PreferenceServiceTest.java`
- [x] T005 [US1] Ajouter test `should_rollbackPreferences_when_rebaseFails` dans `api/src/test/java/fr/kksdev/budget/api/service/PreferenceServiceTest.java`

### Angular

- [x] T006 [US2] S'assurer que `loadRates()` est public dans `ExchangeRateService` dans `app/src/app/core/services/exchange-rate.ts`
- [x] T007 [US2] Injecter `ExchangeRateService` dans `PreferenceService` et appeler `loadRates()` après `setCurrencies()` dans `app/src/app/core/services/preference.ts`

### Flutter

- [x] T008 [P] [US2] Appeler `ref.read(exchangeRateNotifierProvider.notifier).loadItems()` après le PUT preferences dans `reorderCurrencies()` de `flutter/lib/src/features/exchange_rates/application/currency_config_notifier.dart`

### WebSocket push (multi-device)

- [x] T009 [US2] Envoyer un événement WebSocket STOMP `EXCHANGE_RATES_UPDATED` à l'utilisateur après le rebase dans `api/src/main/java/fr/kksdev/budget/api/service/PreferenceService.java` (via `NotificationService` ou `SimpMessagingTemplate`)
- [x] T010 [P] [US2] Écouter l'événement `EXCHANGE_RATES_UPDATED` côté Angular et déclencher `ExchangeRateService.loadRates()` dans `app/src/app/core/services/exchange-rate.ts`
- [x] T011 [P] [US2] Écouter l'événement `EXCHANGE_RATES_UPDATED` côté Flutter et déclencher `ExchangeRateNotifier.loadItems()` dans le listener WebSocket Flutter

### Error handling frontend

- [x] T012 [P] [US2] Gérer l'échec du rechargement des taux dans Angular — afficher un toast d'erreur + permettre retry dans `app/src/app/core/services/preference.ts`
- [x] T013 [P] [US2] Gérer l'échec du rechargement des taux dans Flutter — afficher un SnackBar d'erreur + permettre retry dans `flutter/lib/src/features/exchange_rates/application/currency_config_notifier.dart`

**Checkpoint**: Le rebase est automatique, les frontends rechargent les taux (y compris sur d'autres devices via WebSocket), l'UI se met à jour via les mécanismes réactifs existants (Signals Angular, Riverpod Flutter). En cas d'échec du rechargement, l'utilisateur est informé.

---

## Phase 2: User Story 3 — Indicateur visuel taux manquant (Priority: P2)

**Goal**: Afficher une icône avec tooltip à côté du solde total converti quand au moins une conversion a échoué faute de taux de change.

**Independent Test**: Supprimer un taux de change → vérifier qu'un indicateur apparaît sur le total du dashboard.

### Angular

- [x] T014 [US3] Ajouter le rendu conditionnel de l'indicateur `hasMissingRate` (icône `ph-warning-circle` + tooltip "Certains montants n'ont pas pu être convertis") dans le template du dashboard `app/src/app/features/dashboard/dashboard.ts`

### Flutter

- [x] T015 [US3] Ajouter le calcul de `hasMissingRate` dans le dashboard state ou notifier de `flutter/lib/src/features/dashboard/application/dashboard_notifier.dart`
- [x] T016 [US3] Ajouter le rendu conditionnel de l'indicateur taux manquant (icône Phosphor `warning-circle` + tooltip) dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart`

**Checkpoint**: L'indicateur visuel apparaît sur le total du dashboard quand un taux manque (web + mobile).

---

## Phase 3: Polish & Cross-Cutting Concerns

- [x] T017 Mettre à jour CLAUDE.md section Recent Changes avec l'entrée 095 dans `CLAUDE.md`
- [x] T018 Exécuter la validation quickstart.md (5 étapes de vérification manuelle)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1+US2)**: Pas de dépendance — peut démarrer immédiatement
- **Phase 2 (US3)**: Indépendante de Phase 1 — peut être faite en parallèle
- **Phase 3 (Polish)**: Après Phase 1 + Phase 2

### Within Phase 1

```
T001 (backend rebase) → T002 (log) → T003, T004, T005 (tests, parallélisables)
                                       ↓
T006, T007 (Angular reload) — dépend de T001 (backend déployé)
T008 (Flutter reload) — dépend de T001, parallélisable avec T006/T007
T009 (WebSocket push backend) — dépend de T001
T010, T011 (WebSocket listeners Angular/Flutter) — dépend de T009, parallélisables
T012, T013 (Error handling Angular/Flutter) — parallélisables avec T010/T011
```

### Parallel Opportunities

- T003 + T004 + T005 : tests backend parallélisables
- T006 + T008 : Angular et Flutter reload parallélisables
- T010 + T011 : WebSocket listeners Angular et Flutter parallélisables
- T012 + T013 : Error handling Angular et Flutter parallélisables
- T014 + T015 + T016 : indicateurs Angular et Flutter parallélisables
- Phase 1 backend (T001-T005) et Phase 2 (T014-T016) : parallélisables

---

## Parallel Example: Phase 1

```bash
# Backend d'abord (séquentiel) :
Task T001: "Rebase automatique dans PreferenceService.java"
Task T002: "Log INFO du rebase"
Task T009: "WebSocket push EXCHANGE_RATES_UPDATED"

# Puis tests en parallèle :
Task T003: "Test should_rebaseRates_when_primaryCurrencyChanges"
Task T004: "Test should_notRebaseRates_when_primaryCurrencyUnchanged"
Task T005: "Test should_rollbackPreferences_when_rebaseFails"

# Puis frontend en parallèle (4 tâches) :
Task T006 + T007: "Angular reload taux"
Task T008: "Flutter reload taux"
Task T010: "Angular WebSocket listener"
Task T011: "Flutter WebSocket listener"
Task T012: "Angular error handling"
Task T013: "Flutter error handling"
```

---

## Implementation Strategy

### MVP First (Phase 1 Only)

1. T001-T002 : Backend rebase automatique
2. T003-T005 : Tests backend
3. T006-T008 : Frontend reload taux
4. **STOP and VALIDATE** : Changer devise principale → vérifier taux rebasés + UI mise à jour

### Incremental Delivery

1. Phase 1 (US1+US2) → Rebase + propagation fonctionnels → Deploy
2. Phase 2 (US3) → Indicateur taux manquant → Deploy
3. Phase 3 → Doc + validation → Done

---

## Notes

- Aucun nouveau fichier créé — modifications ciblées dans les fichiers existants
- Le `@Transactional` existant de Spring assure le rollback automatique (FR-002)
- Les mécanismes réactifs (Signals Angular, Riverpod Flutter) propagent automatiquement les changements d'état
- 18 tâches au total (13 initiales + 5 ajoutées pour WebSocket push et error handling)
