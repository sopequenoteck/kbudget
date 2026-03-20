# Quickstart: Améliorations dettes Flutter

**Feature**: 079-flutter-debt-enhancements | **Date**: 2026-03-13

## Prérequis

- Backend KKS-077 déployé (endpoints debt enhancements)
- Flutter >= 3.27 + Dart >= 3.6
- `flutter pub get` à jour

## Commandes

```bash
# Build (code generation Freezed/json_serializable)
cd flutter && dart run build_runner build --delete-conflicting-outputs

# Tests
cd flutter && flutter test test/src/features/debts/

# Lancer
cd flutter && flutter run
```

## Fichiers clés

| Fichier | Description |
|---------|-------------|
| `domain/models/debt.dart` | Model Debt enrichi (Freezed) |
| `domain/models/debt_payment.dart` | Nouveau model DebtPayment |
| `data/remote/dtos/debt_dtos.dart` | DTOs enrichis + RepayRequest + SnoozeRequest |
| `data/remote/data_sources/debt_remote_data_source.dart` | Appels Dio enrichis |
| `features/debts/data/debt_repository_remote.dart` | Repository enrichi |
| `features/debts/application/debt_notifier.dart` | Notifier enrichi + debtPaymentsProvider |
| `features/debts/presentation/debt_detail_screen.dart` | Nouvel écran détail |
| `features/debts/presentation/widgets/debt_form.dart` | Formulaire enrichi |
| `features/debts/presentation/widgets/repay_bottom_sheet.dart` | Bottom sheet remboursement |
| `features/debts/presentation/widgets/snooze_dialog.dart` | Dialogue report rappel |

## Ordre d'implémentation recommandé

1. Data layer (model + DTOs + data source + repository)
2. Application layer (notifier + providers)
3. Formulaire enrichi
4. Écran détail + barre de progression + historique
5. Bottom sheet remboursement
6. Dialogue snooze
7. Routing (route `/debts/:id`)
8. Notification deep link
9. Tests
