# Quickstart — KKS-241 : Refonte 3 formulaires XL Flutter

---

## Prérequis

```bash
# Vérifier que les dépendances KKS-238 et KKS-239 sont disponibles
ls flutter/lib/src/common_widgets/bottom_sheet_4_rows_widget.dart   # KKS-239
ls flutter/lib/src/common_widgets/inline_date_picker.dart           # KKS-238
ls flutter/lib/src/common_widgets/category_select_expand.dart       # KKS-238
```

## Démarrage

```bash
# Depuis la racine du projet
cd flutter

# Vérifier les tests actuels avant de commencer
flutter test test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart

# Lancer l'app pour observer l'état actuel des formulaires
flutter run
```

## Phase 0 — Après création du DTO Freezed (C-01)

```bash
cd flutter

# Regénérer les fichiers Freezed/JSON
dart run build_runner build --delete-conflicting-outputs

# Vérifier que les fichiers sont générés
ls lib/src/data/remote/dtos/recurring_transaction_create_request.freezed.dart
ls lib/src/data/remote/dtos/recurring_transaction_create_request.g.dart

# Vérifier la compilation
flutter analyze
```

## Vérification par phase

### Après Phase 1 (BSheetTypeToggle + app_router)

```bash
# Vérifier que l'app compile
flutter run --no-pub

# Test manuel : ouvrir TransactionForm depuis FAB (+)
# → Row 1 doit afficher le toggle "Dépense / Recette" sans double header
```

### Après Phase 2 (TransactionForm)

```bash
flutter test test/src/features/transactions/presentation/widgets/transaction_form_test.dart
flutter analyze
```

### Après Phase 3 (SubscriptionForm)

```bash
flutter test test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart
flutter analyze
```

### Après Phase 4 (DebtForm)

```bash
flutter test test/src/features/debts/presentation/widgets/debt_form_test.dart
flutter analyze
```

### Validation finale

```bash
# Tous les tests feature
flutter test test/src/features/

# Analyse statique complète
flutter analyze

# Build release
flutter build apk --release
```

## Checklist Success Criteria

- [ ] SC-001 : Saisie transaction en ≤ 3 taps (tester manuellement sur device)
- [ ] SC-002 : Catégorie sans second bottom sheet (taper pill catégorie → expand inline)
- [ ] SC-003 : Date sans dialog Material (taper pill date → InlineDatePicker inline)
- [ ] SC-004 : `flutter test test/src/features/` → 100% PASS
- [ ] SC-005 : Footer grisé quand CategorySelectExpand en mode création
- [ ] SC-006 : Pill "Supprimer" en mode édition + pill "Remboursé/Non remboursé" dans DebtForm
- [ ] SC-007 : `git diff --name-only main` → seuls les fichiers autorisés modifiés hors présentation
- [ ] SC-008 : Icône récurrence absente en mode édition de TransactionForm
- [ ] SC-009 : Champ `includeInBalance` absent de DebtForm UI
