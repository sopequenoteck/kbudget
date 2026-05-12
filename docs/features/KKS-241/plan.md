# Plan d'implémentation — KKS-241 : Refonte 3 formulaires XL Flutter (bottom sheet 4-rows)

**Branch** : `feature/flutter-formulaires-xl-v5` | **Date** : 2026-05-11 | **Spec** : [spec.md](./spec.md)
**Research** : [research.md](./research.md) | **Data model** : [data-model.md](./data-model.md)

---

## Résumé

Migrer les 3 formulaires Flutter (`TransactionForm`, `SubscriptionForm`, `DebtForm`) vers le squelette composable `BottomSheet4RowsWidget` (KKS-239), en consommant `InlineDatePicker` et `CategorySelectExpand` (KKS-238) en zone expand inline. `TransactionForm` intègre également la création de transactions récurrentes (portée depuis Angular). L'approche est purement présentationnelle côté formulaires — les seules modifications non-UI concernent l'ajout d'une méthode `create()` dans la chaîne data récurrence existante, et le bypass d'`AppModal` dans `app_router.dart`.

---

## Contexte technique

**Langage/Version** : Dart 3.6+ / Flutter 3.27+
**State management** : flutter_riverpod (`ConsumerStatefulWidget` + `setState` pour expand local)
**Routing** : go_router + `showModalBottomSheet` direct (bypass AppModal pour les 3 formulaires)
**Base de données** : Drift/SQLite (local-first) — aucune migration requise
**Tests** : flutter_test + Mockito (`ProviderScope` + overrides repository)
**Code generation** : Freezed + json_serializable via build_runner
**Nouvelles dépendances** : aucune
**Contraintes** : saisie transaction ≤ 3 interactions (constitution IV), `print()` interdit (constitution VI)

---

## Constitution Check

| Principe | Gate | Statut | Note |
|----------|------|--------|------|
| I — API-First / Local-First | Trajectoire B : source de vérité = Drift local. La récurrence appelle l'API existante via la chaîne data déjà en place (`recurringTransactionRepositoryProvider`). | **PASS** | L'appel est server-only — si `dataModeProvider = local`, l'icône récurrence est désactivée (R-004) |
| II — Sécurité par défaut | Aucune donnée sensible. L'appel API récurrence utilise `authenticatedDioProvider`. Aucun secret hardcodé. | **PASS** | — |
| III — Simplicité & YAGNI | 2 nouveaux fichiers justifiés : `RecurringTransactionCreateRequest` (DTO nécessaire) + `BSheetTypeToggle` (3 usages identiques → composant partagé). État expand = `setState` local, pas de Provider superflu. | **PASS** | — |
| IV — Mobile-First UX | Saisie transaction en ≤ 3 taps (SC-001). Suppression du second bottom sheet pour catégorie. Expand inline sans navigation supplémentaire. | **PASS** | — |
| V — Testabilité | Tests widget pour les 3 formulaires. Nommage `should_[résultat]_when_[condition]`. Pattern `ProviderScope` + overrides repository. | **PASS** | `subscription_form_test.dart` adapté (assertions structurelles), cas métier préservés |
| VI — Observabilité | Aucun `print()`. SnackBar d'erreur visible pour échec création récurrence. Aucune couche service modifiée. | **PASS** | — |
| VII — Two Distribution Trajectories | Feature entièrement dans la trajectoire B (Flutter). Sans impact sur Spring + Angular. | **PASS** | — |

**Résultat** : PASS — 7/7 principes respectés. **Aucune dérogation requise.**

---

## Architecture

### Fichiers à créer (C)

| Ref | Fichier | Description |
|-----|---------|-------------|
| **C-01** | `flutter/lib/src/data/remote/dtos/recurring_transaction_create_request.dart` | Freezed DTO `RecurringTransactionCreateRequest` — payload `POST /transactions/recurring` |
| **C-02** | `flutter/lib/src/common_widgets/bsheet_type_toggle.dart` | Widget `BSheetTypeToggle` — toggle pill compact N-boutons pour slot `topTrailing` |
| **C-03** | `flutter/test/src/features/transactions/presentation/widgets/transaction_form_test.dart` | Tests widget TransactionForm (création, édition, récurrence, validation) |
| **C-04** | `flutter/test/src/features/debts/presentation/widgets/debt_form_test.dart` | Tests widget DebtForm (création, édition, suppression) |

### Fichiers à modifier (M)

| Ref | Fichier | Modification | FR couverts |
|-----|---------|-------------|-------------|
| **M-01** | `flutter/lib/src/domain/repositories/recurring_transaction_repository.dart` | Ajout signature `Future<RecurringTransaction> create(RecurringTransactionCreateRequest)` | FR-012, FR-013 |
| **M-02** | `flutter/lib/src/data/remote/data_sources/recurring_transaction_remote_data_source.dart` | Ajout `Future<RecurringTransactionResponse> create(RecurringTransactionCreateRequest)` — `POST /transactions/recurring` | FR-012, FR-013 |
| **M-03** | `flutter/lib/src/features/recurring/data/recurring_transaction_repository_remote.dart` | Implémentation `create()` : appel data source + `toDomain()` | FR-012, FR-013 |
| **M-04** | `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart` | Ajout `Future<void> create(RecurringTransactionCreateRequest)` : pattern mutatingIds + try/catch + `_refreshList()` | FR-012, FR-013 |
| **M-05** | `flutter/lib/src/routing/app_router.dart` | Ajout `_showFormBottomSheet()`, mise à jour `_showModal()` pour types transaction/subscription/debt | FR-012, CL-001 |
| **M-06** | `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` | Migration complète vers `BottomSheet4RowsWidget` | FR-001 à FR-009, FR-013 |
| **M-07** | `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` | Migration complète vers `BottomSheet4RowsWidget` | FR-001 à FR-008, FR-010, FR-016 |
| **M-08** | `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart` | Migration complète vers `BottomSheet4RowsWidget` | FR-001 à FR-008, FR-014 à FR-017 |
| **M-09** | `flutter/test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart` | Adaptation assertions au nouveau pattern (BottomSheet4RowsWidget, pills, `Key('bsheet_submit')`) | FR-011, SC-004 |

### Structure source (Flutter uniquement)

```text
flutter/
├── lib/src/
│   ├── common_widgets/
│   │   └── bsheet_type_toggle.dart                        [C-02]
│   ├── data/remote/
│   │   ├── data_sources/
│   │   │   └── recurring_transaction_remote_data_source.dart  [M-02]
│   │   └── dtos/
│   │       ├── recurring_transaction_create_request.dart   [C-01]
│   │       ├── recurring_transaction_create_request.freezed.dart  [généré]
│   │       └── recurring_transaction_create_request.g.dart        [généré]
│   ├── domain/repositories/
│   │   └── recurring_transaction_repository.dart          [M-01]
│   ├── features/
│   │   ├── recurring/
│   │   │   ├── application/recurring_list_notifier.dart   [M-04]
│   │   │   └── data/recurring_transaction_repository_remote.dart  [M-03]
│   │   ├── transactions/presentation/widgets/
│   │   │   └── transaction_form.dart                      [M-06]
│   │   ├── subscriptions/presentation/widgets/
│   │   │   └── subscription_form.dart                     [M-07]
│   │   └── debts/presentation/widgets/
│   │       └── debt_form.dart                             [M-08]
│   └── routing/
│       └── app_router.dart                                [M-05]
└── test/src/features/
    ├── transactions/presentation/widgets/
    │   └── transaction_form_test.dart                     [C-03]
    ├── subscriptions/presentation/widgets/
    │   └── subscription_form_test.dart                    [M-09]
    └── debts/presentation/widgets/
        └── debt_form_test.dart                            [C-04]
```

---

## Approche détaillée par composant

### Phase 0 — Infrastructure récurrence (prérequis)

**Objectif** : Propager `create()` dans la chaîne data récurrence. Bloquant pour Phase 2.

**C-01 — `RecurringTransactionCreateRequest`**

```dart
@freezed
class RecurringTransactionCreateRequest with _$RecurringTransactionCreateRequest {
  const factory RecurringTransactionCreateRequest({
    required double montant,
    required String libelle,
    required String type,       // TransactionType.name → "DEPENSE"/"REVENU"
    required String frequency,  // Frequency.name → "HEBDOMADAIRE"/"MENSUEL"/"ANNUEL"
    required String nextOccurrence,  // ISO 8601 date
    String? categoryId,
    String? accountId,
    String? note,
  }) = _RecurringTransactionCreateRequest;

  factory RecurringTransactionCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionCreateRequestFromJson(json);
}
```

**M-02 — Data source** (endpoint `POST /transactions/recurring`) :
```dart
Future<RecurringTransactionResponse> create(RecurringTransactionCreateRequest req) async {
  final response = await _dio.post('/transactions/recurring', data: req.toJson());
  return RecurringTransactionResponse.fromJson(response.data);
}
```

**M-04 — Notifier** (pattern identique à `deactivate`) :
```dart
Future<void> create(RecurringTransactionCreateRequest req) async {
  state = state.copyWith(isLoading: true);
  try {
    final repo = await ref.read(recurringTransactionRepositoryProvider.future);
    await repo.create(req);
    await _refreshList();
  } catch (e) {
    state = state.copyWith(error: e.toString(), isLoading: false);
  }
}
```

**FR couverts** : FR-012, FR-013 | **SC couverts** : SC-007, SC-008

---

### Phase 1 — Infrastructure routing + composant partagé

**C-02 — `BSheetTypeToggle`**

Widget `StatelessWidget`. API minimale :
```dart
class BSheetTypeToggle extends StatelessWidget {
  const BSheetTypeToggle({
    super.key,
    required this.labels,       // ['Dépense', 'Recette'] ou ['Hebdo', 'Mensuel', 'Annuel']
    required this.selectedIndex,
    required this.onChanged,    // ValueChanged<int>
  });
}
```

Style : boutons pill adjacents — actif = `colorScheme.primary` + texte `onPrimary` ; inactif = bordure `colorScheme.outline` + texte `onSurfaceVariant`. Police `AppTypography.sizeSm`, padding `vertical: 4, horizontal: AppSpacing.space3`.

**M-05 — `app_router.dart`**

Ajout de `_showFormBottomSheet` dans `_RootLayoutState` :
```dart
void _showFormBottomSheet(BuildContext context, Widget child) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: child,
    ),
  );
}
```

Mise à jour de `_showModal` : pour `ModalType.transaction`, `ModalType.subscription`, `ModalType.debt` → appeler `_showFormBottomSheet` (pas `AppModal.show`). Les `headerActions` / `_ModalToggle` sont supprimés pour ces 3 types (le toggle migre dans `topTrailing` via `BSheetTypeToggle`). Pour `ModalType.budget` et `ModalType.transfer` : `AppModal.show` inchangé.

**FR couverts** : FR-012 (routing) | **SC couverts** : SC-007

---

### Phase 2 — Migration TransactionForm (P1)

**M-06 — `TransactionForm`**

State ajouté :
```dart
String? _expandedSection;   // 'date' | 'categorie' | 'compte' | 'note' | 'recurring'
bool _isRecurring = false;
Frequency _recurringFrequency = Frequency.mensuel;
DateTime? _recurringNextOccurrence;

void _toggleSection(String key) {
  setState(() => _expandedSection = _expandedSection == key ? null : key);
}
```

Structure `BottomSheet4RowsWidget` :

| Slot | Contenu |
|------|---------|
| `title` | `state.type.title(state.mode)` depuis `modalNotifierProvider` |
| `topTrailing` | `BSheetTypeToggle(labels: ['Dépense', 'Recette'], selectedIndex: ...)` |
| `amountField` | TextField montant hero (controller existant `_montantController`) |
| `libelleField` | `LibelleAutocompleteField` (existant, controller `_libelleController`) |
| `notePreview` | Texte note grisé si `_noteController.text.isNotEmpty` |
| `iconButtons` | `phosphorNoteBlank` (note) + `phosphorRepeat` (récurrence, mode création uniquement) |
| `metaPills` | date + catégorie + compte |
| `expandedContent` | Switch sur `_expandedSection` : `InlineDatePicker` / `CategorySelectExpand` / SelectPicker accounts / textarea note / expand récurrence |
| `footerLeading` | Pill "Supprimer" si mode édition → `showDeleteConfirmDialog` |
| `footerEnabled` | `!_isCreatingCategory` (via `CategorySelectExpand.onCreatingChanged`) |
| `onSubmit` | Validation + `create`/`update` transaction + `recurringListNotifier.create()` si `_isRecurring` |

**Expand récurrence** (mode création) :
- Toggle "Transaction récurrente" (Switch)
- Si activé : `BSheetTypeToggle(labels: ['Hebdo', 'Mensuel', 'Annuel'])` + `InlineDatePicker(nextOccurrence)`

**PopScope** : `canPop = _expandedSection == null` ; `onPopInvokedWithResult` ferme l'expand si ouvert.

**FR couverts** : FR-001 à FR-009, FR-013 | **SC couverts** : SC-001, SC-002, SC-003, SC-006, SC-008

---

### Phase 3 — Migration SubscriptionForm (P2)

**M-07 — `SubscriptionForm`**

State ajouté :
```dart
String? _expandedSection;   // 'date' | 'categorie' | 'compte' | 'devise'
Frequency _selectedFrequency = widget.frequence;
Currency? _forcedCurrency;
```

Structure `BottomSheet4RowsWidget` :

| Slot | Contenu |
|------|---------|
| `topTrailing` | `BSheetTypeToggle(labels: ['Hebdo', 'Mensuel', 'Annuel'])` |
| `amountField` | TextField montant hero |
| `libelleField` | TextField nom abonnement (controller `_nomController`) |
| `iconButtons` | `phosphorToggleRight/Left` (actif/inactif, mode édition uniquement) |
| `metaPills` | date de début + catégorie + compte + devise (si `_selectedAccountId == null`) |
| `expandedContent` | `InlineDatePicker` / `CategorySelectExpand` / SelectPicker accounts / SelectPicker devise |
| `footerLeading` | Pill "Supprimer" si mode édition |

**Pill devise** : visible si `_selectedAccountId == null`. Tap → expand devise : `SelectPicker` avec `Currency.values.map((c) => SelectPickerItem(id: c.name, label: '${c.displayName} (${c.symbol})'))`. Quand un compte est sélectionné : `_forcedCurrency = null`, pill masquée.

**FR couverts** : FR-001 à FR-008, FR-010, FR-016 | **SC couverts** : SC-001, SC-002, SC-003, SC-005, SC-006

---

### Phase 4 — Migration DebtForm (P3)

**M-08 — `DebtForm`**

State ajouté :
```dart
String? _expandedSection;   // 'date' | 'categorie' | 'compte' | 'echeance' | 'devise' | 'reminder'
// _forcedCurrency, _reminderDate, _reminderTime, _dueDate : déjà présents dans le form actuel
// _includeInBalance : supprimé de l'UI, calculé silencieusement à la soumission
```

Structure `BottomSheet4RowsWidget` :

| Slot | Contenu |
|------|---------|
| `topTrailing` | `BSheetTypeToggle(labels: ['Emprunt', 'Prêt'])` |
| `amountField` | TextField montant hero (coloration dynamique : vert prêt / rouge emprunt) |
| `libelleField` | TextField personne (controller `_personneController`) |
| `iconButtons` | `phosphorBell` (reminder) |
| `metaPills` | date + catégorie + compte + échéance (toujours visible) + devise (si `_selectedAccountId == null`) |
| `expandedContent` | Switch : `InlineDatePicker` (date) / `CategorySelectExpand` / SelectPicker accounts / `InlineDatePicker` (échéance) / SelectPicker devise / reminder expand |
| `footerLeading` (édition) | Pill "Supprimer" (danger) + Pill "Remboursé/Non remboursé" (status `BSheetSubmitVariant`) |
| `onSubmit` | ... + `includeInBalance = _selectedAccountId != null` (calcul silencieux) |

**Pill "Échéance"** : toujours présente dans `metaPills`. État vide : icône calendrier grisée + label "Échéance". État rempli : date formatée. Tap → expand `dueDate`. × optionnel pour effacer.

**Expand reminder** : `InlineDatePicker(reminderDate)` + `ElevatedButton("Choisir l'heure")` → `showTimePicker()` Material déclenché après sélection date.

**Soumission** : `includeInBalance = _selectedAccountId != null` (FR-017).

**FR couverts** : FR-001 à FR-008, FR-014 à FR-017 | **SC couverts** : SC-001, SC-002, SC-003, SC-005, SC-006, SC-009

---

### Phase 5 — Tests widget (P2)

**M-09 — `subscription_form_test.dart`**
- Conserver les cas métier (création, édition, validation libellé vide)
- Remplacer les `find.byType(AppFormField)` par `find.byType(BottomSheet4RowsWidget)`
- Remplacer `find.byType(FilledButton)` par `find.byKey(Key('bsheet_submit'))`
- Ajouter test `should_disable_footer_when_creating_category`

**C-03 — `transaction_form_test.dart`**
- `should_display_amount_field_when_form_opens`
- `should_submit_transaction_when_amount_and_libelle_valid`
- `should_show_error_when_libelle_empty`
- `should_show_error_when_amount_negative`
- `should_show_delete_pill_when_edit_mode`
- `should_hide_recurring_icon_when_edit_mode`

**C-04 — `debt_form_test.dart`**
- `should_display_echeance_pill_always`
- `should_submit_debt_when_valid`
- `should_show_delete_pill_when_edit_mode`
- `should_show_rembourse_pill_when_edit_mode`

**FR couverts** : FR-011 | **SC couverts** : SC-004

---

## Séquence d'implémentation

```
Phase 0 (prérequis)   : C-01 → M-01 → M-02 → M-03 → M-04 → build_runner
Phase 1 (infra)       : C-02 → M-05
Phase 2 (P1)          : M-06 → tests unitaires form
Phase 3 (P2)          : M-07 → tests unitaires form
Phase 4 (P3)          : M-08 → tests unitaires form
Phase 5 (tests)       : M-09 → C-03 → C-04 → flutter test
```

Chaque phase est indépendamment testable. Les phases 2-4 peuvent être mises en production séparément.

---

## Risques et mitigations

| # | Risque | P | I | Mitigation |
|---|--------|---|---|------------|
| R-001 | `LibelleAutocompleteField` incompatible avec le slot `libelleField` (A-004 non vérifiée) | Faible | Moyen | Tester en isolation avant migration complète Phase 2 |
| R-002 | Conflits `build_runner` sur fichiers `.freezed.dart` existants | Faible | Moyen | `dart run build_runner build --delete-conflicting-outputs` |
| R-003 | `BSheetTypeToggle` trop large sur petits écrans (3 boutons, iPhone SE 375px) | Moyen | Faible | Labels courts `H/M/A` si espace insuffisant — à vérifier Phase 1 |
| R-004 | `recurringListNotifier.create()` appelé en mode local-first (Drift) — méthode non implémentée pour Drift | Moyen | Moyen | Désactiver l'icône `phosphorRepeat` si `dataModeProvider = DataMode.local` ; SnackBar informatif |
| R-005 | `subscription_form_test.dart` structurellement cassé après migration | Certain | Faible | Phase 5 dédiée à l'adaptation — cas métier conservés |

---

## Hors scope

- Modification de `AppModal` (budget, transfer non migrés)
- Implementation de `create()` côté Drift/local pour les récurrences
- Nouveaux écrans ou routes
- Refactoring des formulaires non migrés
- Tests d'intégration backend

---

## Artefacts complémentaires

| Artefact | Fichier | Contenu |
|----------|---------|---------|
| Research | [research.md](./research.md) | 6 décisions techniques (RES-001 à RES-006) |
| Data model | [data-model.md](./data-model.md) | DTO `RecurringTransactionCreateRequest` |
| Quickstart | [quickstart.md](./quickstart.md) | Commandes de démarrage + vérification |
