# Tasks: Formulaire Virement

**Input**: Design documents from `/specs/050-flutter-transfer-form/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/api-contract.md

**Tests**: Non demandés dans la spec. Pas de tâches de test.

**Organization**: Tasks groupées par user story. Chaque story est implémentable et testable indépendamment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story concernée (US1, US2, US3)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: DTOs, méthode data source et i18n — prérequis bloquants pour toutes les user stories

**CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase

- [x] T001 [P] Créer les DTOs de transfert (`TransferRequest`, `TransferResponse`, `TransactionRef`) avec `@freezed` et `@JsonSerializable` dans `flutter/lib/src/data/remote/dtos/transfer_dtos.dart`
- [x] T002 [P] Ajouter les chaînes i18n du formulaire de virement (labels, erreurs de validation, messages) dans `flutter/lib/src/localization/app_fr.arb` et `flutter/lib/src/localization/app_en.arb`
- [x] T003 Ajouter la méthode `transfer(TransferRequest request)` retournant `Future<TransferResponse>` dans `flutter/lib/src/data/remote/data_sources/account_remote_data_source.dart` — POST `/accounts/transfer` via Dio
- [x] T004 Exécuter `dart run build_runner build --delete-conflicting-outputs` dans `flutter/` pour générer les fichiers `.freezed.dart` et `.g.dart`

**Checkpoint**: DTOs générés, data source prêt, i18n en place — l'implémentation des user stories peut commencer

---

## Phase 2: User Story 1 — Effectuer un virement entre comptes (Priority: P1) MVP

**Goal**: L'utilisateur peut ouvrir le formulaire de virement depuis le FAB, sélectionner source/destination, saisir un montant, et valider. Le serveur crée 2 transactions liées.

**Independent Test**: Ouvrir le FAB → choisir "Virement" → remplir source, destination, montant → valider → vérifier que la modal se ferme et que 2 transactions apparaissent dans la liste.

### Implementation for User Story 1

- [x] T005 [US1] Créer le widget `TransferForm` (`ConsumerStatefulWidget`) dans `flutter/lib/src/features/transactions/presentation/widgets/transfer_form.dart` — champs : compte source (`SelectPicker` affichant icône, nom, solde et devise des comptes actifs), compte destination (`SelectPicker` idem, filtrant le compte déjà sélectionné en source), montant (`AppFormField` numérique), note (`AppFormField` texte optionnel, max 500 car.) — callbacks `onSaved(TransferRequest)` et `onCancelled` — états `_isSubmitting` et `_showErrors` — pattern similaire à `DebtForm` (mais sans toggle type, avec 2 sélecteurs de comptes au lieu d'un)
- [x] T006 [US1] Intégrer le formulaire dans le système de modal : ajouter le cas `ModalType.transfer` dans `_buildModalChild()` avec un widget `_TransferFormConsumer` qui appelle `accountRemoteDataSource.transfer()`, gère le succès (fermer modal + `transactionListNotifierProvider.notifier.refresh()`) et l'échec — inclure un guard `if (!mounted) return` après l'appel async pour gérer la fermeture de la modal pendant l'envoi — dans `flutter/lib/src/routing/app_router.dart`

**Checkpoint**: Le virement fonctionne de bout en bout (FAB → formulaire → soumission → refresh). Prêt pour la validation détaillée.

---

## Phase 3: User Story 2 — Validation du formulaire (Priority: P2)

**Goal**: Le système empêche la soumission de virements invalides avec des messages d'erreur clairs et contextuels.

**Independent Test**: Tenter de soumettre avec des données invalides (champs vides, même compte, montant 0) → vérifier que les messages d'erreur s'affichent. Simuler une erreur serveur → vérifier que le message s'affiche et les champs restent remplis.

### Implementation for User Story 2

- [x] T007 [US2] Ajouter les règles de validation complètes au `TransferForm` dans `flutter/lib/src/features/transactions/presentation/widgets/transfer_form.dart` — validation champs obligatoires (source, destination, montant), vérification que source != destination avec message explicite, montant > 0 (min 0.01), note max 500 car., erreurs affichées uniquement après tentative de soumission (`_showErrors` flag)
- [x] T008 [US2] Ajouter la gestion des erreurs serveur dans `_TransferFormConsumer` de `flutter/lib/src/routing/app_router.dart` — afficher le message d'erreur inline dans le formulaire (via SnackBar comme les autres forms du projet), conserver les données saisies, permettre une nouvelle tentative

**Checkpoint**: Toutes les validations front-end et la gestion d'erreurs serveur fonctionnent. Aucun virement invalide ne peut être soumis.

---

## Phase 4: User Story 3 — Accès conditionnel au formulaire (Priority: P3)

**Goal**: L'option "Virement" dans le FAB est masquée si l'utilisateur a moins de 2 comptes actifs.

**Independent Test**: Avec 1 seul compte actif → ouvrir le FAB → "Virement" absent du menu. Avec 2+ comptes → "Virement" visible.

### Implementation for User Story 3

- [x] T009 [US3] Modifier le widget `FabMenu` pour filtrer l'item "Virement" (`ModalType.transfer`) quand le nombre de comptes actifs est < 2 — watch `accountNotifierProvider` pour accéder à la liste des comptes et filtrer dans `flutter/lib/src/common_widgets/fab_menu.dart`

**Checkpoint**: Le FAB masque "Virement" dynamiquement selon le nombre de comptes actifs.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale et nettoyage

- [x] T010 Exécuter le scénario `quickstart.md` complet (virement réussi, validation, FAB conditionnel) et vérifier les critères de succès SC-001 à SC-004

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Pas de dépendance — peut démarrer immédiatement
- **US1 (Phase 2)**: Dépend de Phase 1 (DTOs + data source requis)
- **US2 (Phase 3)**: Dépend de Phase 2 (le formulaire doit exister pour y ajouter la validation)
- **US3 (Phase 4)**: Dépend de Phase 1 uniquement (pas besoin du formulaire pour modifier le FAB)
- **Polish (Phase 5)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Dépend de Phase 1 — prérequis obligatoire
- **US2 (P2)**: Dépend de US1 — la validation s'ajoute au formulaire existant
- **US3 (P3)**: Indépendant de US1/US2 — peut être implémenté en parallèle après Phase 1

### Within Each User Story

- DTOs avant data source
- Data source avant formulaire
- Formulaire avant intégration router
- Validation après formulaire de base

### Parallel Opportunities

- **Phase 1**: T001 (DTOs) et T002 (i18n) en parallèle — fichiers différents
- **Phase 2 + Phase 4**: US1 (T005-T006) et US3 (T009) en parallèle après Phase 1 — fichiers différents
- T003 (data source) peut démarrer dès que T001 (DTOs) est terminé

---

## Parallel Example: After Phase 1

```bash
# Après Phase 1 complétée, lancer en parallèle :
Agent A: "[US1] TransferForm dans transfer_form.dart"
Agent B: "[US3] FabMenu conditionnel dans fab_menu.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Foundational (T001-T004)
2. Compléter Phase 2: User Story 1 (T005-T006)
3. **STOP et VALIDER**: Tester le virement de bout en bout
4. Le formulaire est fonctionnel, même sans validation avancée

### Incremental Delivery

1. Phase 1 → Foundation prête
2. US1 (T005-T006) → Virement fonctionnel (MVP)
3. US2 (T007-T008) → Validation robuste
4. US3 (T009) → Accès conditionnel
5. Polish (T010) → Validation complète

### Files Modified/Created Summary

| Fichier | Action | Phases |
|---------|--------|--------|
| `flutter/lib/src/data/remote/dtos/transfer_dtos.dart` | NEW | Phase 1 |
| `flutter/lib/src/data/remote/data_sources/account_remote_data_source.dart` | MODIFY | Phase 1 |
| `flutter/lib/src/localization/*.arb` | MODIFY | Phase 1 |
| `flutter/lib/src/features/transactions/presentation/widgets/transfer_form.dart` | NEW | Phase 2, 3 |
| `flutter/lib/src/routing/app_router.dart` | MODIFY | Phase 2, 3 |
| `flutter/lib/src/common_widgets/fab_menu.dart` | MODIFY | Phase 4 |

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label = traçabilité vers la user story
- Pas de repository abstract (YAGNI — server-only, 1 méthode)
- Le `TransferResponse` n'est pas mappé vers un modèle domaine — utilisé uniquement pour confirmer le succès
- Le refresh de la liste des transactions utilise le mécanisme existant (`transactionListNotifierProvider.notifier.refresh()`)
- `ModalType.transfer` existe déjà dans l'enum — pas de modification nécessaire
- Commiter après chaque tâche ou groupe logique
