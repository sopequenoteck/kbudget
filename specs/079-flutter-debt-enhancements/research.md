# Research: Améliorations dettes Flutter

**Feature**: 079-flutter-debt-enhancements | **Date**: 2026-03-13

## R1 — État actuel du model Debt Flutter

**Decision**: Enrichir le model Freezed existant avec les champs manquants.
**Rationale**: Le model actuel ne contient que 9 champs (id, personne, montant, sens, date, currency, rembourse, categoryId, updatedAt). Les champs backend KKS-077 (accountId, accountName, includeInBalance, reminderDate, reminderTime, remainingAmount, dueDate) sont absents. Ajout in-place sans breaking change (tous optionnels ou avec défaut).
**Alternatives considered**: Créer un model DebtDetail séparé → rejeté car duplication et complexité inutile (YAGNI).

## R2 — DebtPayment : nouveau model

**Decision**: Créer `DebtPayment` comme model Freezed dans `domain/models/debt_payment.dart`.
**Rationale**: N'existe pas côté Flutter. Le backend retourne `DebtPaymentResponse` via `GET /debts/{id}/payments`. Champs : id, montant, date, accountName (nullable).
**Alternatives considered**: Intégrer les paiements dans le model Debt → rejeté car les paiements sont chargés séparément (FutureProvider.family).

## R3 — Data layer : mode serveur uniquement

**Decision**: Pas de Drift/SQLite pour cette feature. Modifier uniquement `DebtRepositoryRemote` et `DebtRemoteDataSource`.
**Rationale**: Aligné sur les features récentes (053-accounts, 054-categories, 060-shop). Les données doivent être fraîches depuis l'API. Le repository local (`DebtRepositoryLocal`) et le DAO (`DebtDao`) ne seront PAS modifiés — les nouveaux champs du model Debt auront des valeurs par défaut.
**Alternatives considered**: Enrichir aussi le schéma Drift → rejeté car hors scope (pas de mode offline pour les enrichissements dettes).

## R4 — Écran détail dette : nouveau vs enrichissement

**Decision**: Créer un nouvel écran `DebtDetailScreen` avec route `/debts/:id`.
**Rationale**: Aucun écran détail n'existe actuellement (la liste utilise un modal pour l'édition). Le détail nécessite : montant restant, barre de progression, bouton remboursement, historique paiements, bouton snooze. Trop complexe pour un modal. Pattern identique à `ShopDetailScreen` (route `/shop/:id`).
**Alternatives considered**: Enrichir le modal existant → rejeté car surcharge UX et non aligné sur Angular (qui a un écran dédié).

## R5 — Notification deep link vers détail dette

**Decision**: Exploiter le système de notification existant (`NotificationNotifier` + STOMP). Au tap sur une notification de type `DEBT_REMINDER`/`DEBT_DUE`, naviguer vers `/debts/{entityId}`.
**Rationale**: Le `NotificationModel` contient déjà `entityType` + `entityId`. Le router go_router supporte déjà les deep links. Il suffit d'ajouter la logique de navigation dans le panneau de notifications.
**Alternatives considered**: Actions push natives Flutter → hors scope pour cette itération (dépendrait de flutter_local_notifications qui est déjà configuré dans KKS-072).

## R6 — Pattern de formulaire enrichi

**Decision**: Étendre `DebtForm` avec les widgets existants : `SelectPicker` (compte), `showDatePicker`/`showTimePicker` (rappel), `SwitchListTile` (patrimoine).
**Rationale**: Patterns déjà utilisés dans d'autres formulaires (transaction, subscription, budget). Réutilisation maximale, pas de nouveau widget custom.
**Alternatives considered**: Créer un nouveau widget de formulaire → rejeté (YAGNI, le formulaire existant est extensible).

## R7 — Bottom sheet remboursement

**Decision**: Créer `RepayBottomSheet` comme `ConsumerStatefulWidget` affiché via `AppModal.show()`.
**Rationale**: Pattern cohérent avec les autres modals (SellDialog dans shop, RestockDialog). Champs : SelectPicker (compte, obligatoire), TextFormField (montant, pré-rempli). Validation : montant entre 0.01 et restant dû.
**Alternatives considered**: Inline dans l'écran détail → rejeté car UX trop chargée.

## R8 — Dialogue snooze

**Decision**: Créer `SnoozeDialog` comme `ConsumerStatefulWidget` affiché via `AppModal.show()`.
**Rationale**: Compact : 2 champs (date future + heure). Pattern identique au SnoozeDialog Angular. Validation : date future obligatoire.
**Alternatives considered**: Intégrer dans le formulaire principal → rejeté car le snooze est une action contextuelle du détail, pas de la création.
