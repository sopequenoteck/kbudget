# Quickstart: Flutter — Système Modal / Bottom Sheet

**Feature**: 036-flutter-modal-system

## Prérequis

- Flutter >= 3.27 (stable)
- Dart >= 3.6
- Dépendances du projet installées (`flutter pub get` depuis `flutter/`)

## Lancer l'application

```bash
cd flutter && flutter run
```

## Tester la feature

### Tests automatisés

```bash
# Tous les tests
cd flutter && flutter test

# Tests du notifier modal
cd flutter && flutter test test/features/modal/application/modal_notifier_test.dart

# Tests du widget modal
cd flutter && flutter test test/common_widgets/app_modal_test.dart

# Tests du widget toggle
cd flutter && flutter test test/common_widgets/app_toggle_test.dart
```

### Tests manuels

1. **Ouverture bottom sheet (mobile)** :
   - Lancer l'app sur un émulateur mobile (< 768px de large)
   - Appuyer sur le FAB (+)
   - Sélectionner "Transaction"
   - Vérifier : bottom sheet apparaît depuis le bas avec titre "Nouvelle transaction"

2. **Ouverture dialog (tablette)** :
   - Lancer l'app sur un émulateur tablette (>= 768px de large)
   - Appuyer sur le FAB (+)
   - Sélectionner "Transaction"
   - Vérifier : dialog centré avec overlay sombre

3. **Toggle type** :
   - Ouvrir une modale "Transaction"
   - Vérifier : toggle Dépense/Recette visible, "Dépense" actif
   - Appuyer sur "Recette"
   - Vérifier : "Recette" devient actif visuellement

4. **Fermeture** :
   - Bottom sheet : swipe vers le bas → se ferme
   - Dialog : tap overlay → se ferme
   - Bouton × → se ferme
   - Bouton retour Android → se ferme

5. **Types sans toggle** :
   - Ouvrir une modale "Virement"
   - Vérifier : pas de toggle dans le header

## Régénérer le code freezed

Après modification des classes `@freezed` :

```bash
cd flutter && dart run build_runner build --delete-conflicting-outputs
```

## Structure des fichiers créés

| Fichier | Rôle |
| ------- | ---- |
| `lib/src/domain/enums/modal_type.dart` | Enum ModalType (6 types) |
| `lib/src/features/modal/application/modal_state.dart` | State freezed (ModalClosed / ModalOpen) |
| `lib/src/features/modal/application/modal_notifier.dart` | Notifier Riverpod (open, close, setSubType) |
| `lib/src/common_widgets/app_modal.dart` | Widget modal adaptatif (bottom sheet / dialog) |
| `lib/src/common_widgets/app_toggle.dart` | Widget toggle 2 options |
