# Documentation — KKS-241 : Refonte 3 formulaires XL Flutter (bottom sheet 4-rows)

> Date : 2026-05-11
> Issue : KKS-241
> Branch : `feature/flutter-formulaires-xl-v5`
> Parent : KKS-236

---

## Résumé

Les 3 formulaires de saisie XL Flutter (`TransactionForm`, `SubscriptionForm`, `DebtForm`) ont été migrés vers le squelette composable `BottomSheet4RowsWidget` (KKS-239), avec sélection de date et de catégorie entièrement inline (plus de dialogs ou de second bottom sheet). `TransactionForm` intègre désormais la création de transactions récurrentes portée depuis Angular. L'expérience de saisie est réduite à ≤ 3 interactions sans quitter le bottom sheet.

---

## Guide utilisateur

### TransactionForm — Formulaire de transaction

**Description** : Formulaire de saisie d'une transaction (dépense ou revenu), accessible via le bouton (+) flottant.

**Fonctionnalités** :
- **Toggle type** en Row 1 : bascule entre "Dépense" et "Recette" sans fermer le formulaire
- **Montant hero** : champ montant prominent en Row 2 gauche
- **Libellé avec autocomplétion** : champ libellé en Row 2 droite, propose les libellés existants
- **Date inline** : tap sur la pill "date" → `InlineDatePicker` s'ouvre en zone expand (pas de dialog)
- **Catégorie inline** : tap sur la pill "catégorie" → `CategorySelectExpand` s'ouvre inline, permet de créer une catégorie directement
- **Compte** : tap sur la pill "compte" → sélection inline
- **Note** : icône crayon → textarea de note en expand ; aperçu de la note visible sous le libellé
- **Récurrence** (création uniquement) : icône répétition → activer "Transaction récurrente", choisir fréquence (Hebdo/Mensuel/Annuel) et date de prochaine occurrence. La récurrence est créée en même temps que la transaction.
- **Suppression** (mode édition) : pill "Supprimer" en bas à gauche avec confirmation

**Comportement retour Android** : si une zone expand est ouverte, le retour Android ferme l'expand sans fermer le formulaire.

---

### SubscriptionForm — Formulaire d'abonnement

**Description** : Formulaire de saisie/édition d'un abonnement, accessible depuis la liste des abonnements.

**Fonctionnalités** :
- **Toggle fréquence** en Row 1 : "Hebdo" / "Mensuel" / "Annuel" (couvre les 3 valeurs de l'enum `Frequency`)
- **Date de début inline** : `InlineDatePicker` en expand
- **Catégorie inline** : `CategorySelectExpand` en expand
- **Compte inline** : `SelectPicker` en expand
- **Devise** : pill "Devise" visible uniquement si aucun compte n'est sélectionné → sélection de la devise libre (EUR, XOF, USD, GBP, CHF, CAD, MAD)
- **Actif/Inactif** (mode édition) : icône toggle en Row 3 pour basculer l'état de l'abonnement
- **Suppression** (mode édition) : pill "Supprimer" en bas à gauche

---

### DebtForm — Formulaire de dette

**Description** : Formulaire de saisie/édition d'une dette (emprunt ou prêt), accessible depuis la liste des dettes.

**Fonctionnalités** :
- **Toggle type** en Row 1 : "Emprunt" (montant rouge) / "Prêt" (montant vert)
- **Date inline** : `InlineDatePicker` en expand
- **Catégorie inline** : `CategorySelectExpand` en expand
- **Compte inline** : `SelectPicker` en expand
- **Échéance** : pill "Échéance" **toujours visible** (grisée si non définie) → `InlineDatePicker` en expand. Icône × pour effacer la date
- **Devise** : pill "Devise" visible si aucun compte sélectionné
- **Rappel** (Bell) : icône cloche → sélection date (`InlineDatePicker`) + heure (`showTimePicker` Material enchaîné)
- **Statut remboursement** (mode édition) : pill "Remboursé / Non remboursé" en bas à gauche, à côté de "Supprimer"
- **`includeInBalance`** : champ supprimé de l'UI — calculé silencieusement (`includeInBalance = accountId != null`)

---

### BSheetTypeToggle — Nouveau composant partagé

**Description** : Toggle N-boutons compact pour le slot `topTrailing` des formulaires.

**Usage** :
```dart
BSheetTypeToggle(
  labels: const ['Option A', 'Option B', 'Option C'],
  selectedIndex: _selectedIndex,
  onChanged: (i) => setState(() => _selectedIndex = i),
)
```

Utilisé dans les 3 formulaires : TransactionForm (2 boutons), SubscriptionForm (3 boutons), DebtForm (2 boutons).

---

## Changements techniques

### Fichiers créés

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/data/remote/dtos/recurring_transaction_create_request.dart` | DTO Freezed pour la création d'une transaction récurrente (`POST /transactions/recurring`) |
| `flutter/lib/src/common_widgets/bsheet_type_toggle.dart` | Widget toggle N-boutons compact pour `topTrailing` de `BottomSheet4RowsWidget` |
| `flutter/test/src/features/transactions/presentation/widgets/transaction_form_test.dart` | 6 tests widget TransactionForm |
| `flutter/test/src/features/debts/presentation/widgets/debt_form_test.dart` | 4 tests widget DebtForm |
| `flutter/lib/src/data/remote/dtos/recurring_transaction_create_request.freezed.dart` | Généré par build_runner |
| `flutter/lib/src/data/remote/dtos/recurring_transaction_create_request.g.dart` | Généré par build_runner |

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/domain/repositories/recurring_transaction_repository.dart` | Ajout de la signature `create(RecurringTransactionCreateRequest)` à l'interface |
| `flutter/lib/src/data/remote/data_sources/recurring_transaction_remote_data_source.dart` | Ajout de `create()` — appel `POST /transactions/recurring` |
| `flutter/lib/src/features/recurring/data/recurring_transaction_repository_remote.dart` | Implémentation de `create()` : appel data source + `toDomain()` |
| `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart` | Ajout de `create()` avec pattern isLoading + try/catch + `_refreshList()` |
| `flutter/lib/src/routing/app_router.dart` | Ajout de `_showFormBottomSheet()`, `_showModal()` conditionnel (transaction/subscription/debt → bottom sheet natif ; budget/transfer → AppModal inchangé) |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` | Migration complète vers `BottomSheet4RowsWidget` |
| `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` | Migration complète vers `BottomSheet4RowsWidget` |
| `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart` | Migration complète vers `BottomSheet4RowsWidget` |
| `flutter/test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart` | Adaptation au nouveau pattern (9 tests, dont 1 nouveau) |

### Dépendances ajoutées

Aucune nouvelle dépendance externe — toutes les fonctionnalités réutilisent les packages existants (`freezed`, `flutter_riverpod`, `phosphor_flutter`, `go_router`).

---

## Configuration

Aucune configuration supplémentaire requise. La feature s'active automatiquement au démarrage de l'app. L'icône de récurrence dans `TransactionForm` nécessite un mode connecté (sync activée) — elle est présente mais l'erreur est gérée par un SnackBar si la création échoue en mode local.

---

## Tests et validation

### Tests widget

| Fichier | Tests | Résultat |
|---------|-------|---------|
| `transaction_form_test.dart` | 6 cas (création, édition, validation, récurrence) | PASS |
| `subscription_form_test.dart` | 9 cas (dont 1 nouveau : footer désactivé lors de création catégorie) | PASS |
| `debt_form_test.dart` | 4 cas (pill échéance, soumission, suppression, remboursement) | PASS |

**Total : 454 tests features — 0 régression**

### Commande de test

```bash
cd flutter
flutter test test/src/features/    # 454 tests, all PASS
flutter analyze                    # 0 erreur
```

### Validation manuelle (checklist SC)

- [ ] SC-001 : Saisie transaction en ≤ 3 taps sans que le clavier masque Valider
- [ ] SC-002 : Catégorie sans second bottom sheet (expand inline)
- [ ] SC-003 : Date sans dialog Material (InlineDatePicker inline)
- [ ] SC-004 : `flutter test test/src/features/` → 100% PASS ✅
- [ ] SC-005 : Footer visuellement désactivé (Opacity 0.4) quand CategorySelectExpand en mode création
- [ ] SC-006 : Pill "Supprimer" présente en mode édition ; "Remboursé/Non remboursé" dans DebtForm
- [ ] SC-007 : Seuls les fichiers autorisés hors présentation modifiés ✅
- [ ] SC-008 : Icône récurrence absente en mode édition TransactionForm
- [ ] SC-009 : Champ `includeInBalance` absent de DebtForm UI

---

## Dettes techniques documentées

| Ref | Description | Impact |
|-----|-------------|--------|
| W-001 | Icône récurrence non désactivée en mode local-first (`DataMode.local`). Un SnackBar informe l'utilisateur en cas d'échec réseau. | Faible — fallback présent |
| W-002 | `RecurringListNotifier.create()` utilise `isLoading` global au lieu du pattern `mutatingIds` des autres mutations. | Cosmétique — pas d'impact fonctionnel |
| I-001 | Widgets privés `_MetaPill` / `_DeletePill` dupliqués dans les 3 formulaires. | Candidat future extraction dans `common_widgets/form_pills.dart` |

---

## Références

| Artefact | Lien |
|----------|------|
| Spec | [spec.md](./spec.md) |
| Plan | [plan.md](./plan.md) |
| Tâches | [tasks.md](./tasks.md) |
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| Quickstart | [quickstart.md](./quickstart.md) |
| Review log | [review-log.md](./review-log.md) |
| KKS-239 | BottomSheet4RowsWidget (squelette composable) |
| KKS-238 | InlineDatePicker + CategorySelectExpand |
