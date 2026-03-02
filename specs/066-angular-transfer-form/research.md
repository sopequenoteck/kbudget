# Research: Virement entre comptes Angular

**Feature**: 066-angular-transfer-form
**Date**: 2026-03-01

## R1 — API Transfer existante

**Decision**: Utiliser l'endpoint `POST /api/accounts/transfer` existant via `AccountService.transfer()`.

**Rationale**: L'API est déjà implémentée et testée côté backend. Le DTO `TransferRequest` attend `fromAccountId`, `toAccountId`, `montant`, et `note` (optionnelle). La réponse `TransferResponse` retourne le `transferId` et les références des deux transactions créées.

**Alternatives considered**:
- Créer un endpoint dédié dans `TransactionController` → rejeté, l'endpoint existe déjà dans `AccountController` et est cohérent avec Flutter.

## R2 — Intégration dans le parcours utilisateur

**Decision**: Intégration via le FAB (speed dial) et le système de modales existant (`ModalService`).

**Rationale**: Le pattern est déjà établi pour les transactions, abonnements et dettes. Le `ModalType = 'transfer'` est déjà déclaré dans `ModalService`. Le FAB conditionne l'affichage de l'action "Virement" à `hasEnoughAccounts()` (>= 2 comptes actifs).

**Alternatives considered**:
- Page dédiée avec route `/transfers` → rejeté, incohérent avec le pattern modal utilisé partout dans l'app.
- Bouton dans la liste des comptes → rejeté, moins accessible que le FAB omniprésent.

## R3 — Validation formulaire

**Decision**: Validation via Angular Reactive Forms avec un validateur cross-champ custom `differentAccountsValidator`.

**Rationale**: Angular Reactive Forms est déjà utilisé dans `TransactionForm` et `SubscriptionForm`. Le validateur cross-champ est le pattern standard Angular pour valider des relations entre champs. Les validations : `fromAccountId` required, `toAccountId` required, `montant` min 0.01, `note` maxLength 500, comptes source ≠ destination.

**Alternatives considered**:
- Validation template-driven → rejeté, le projet utilise Reactive Forms partout.
- Validation côté serveur uniquement → rejeté, mauvaise UX (feedback tardif).

## R4 — Composant de sélection de compte

**Decision**: Utiliser le composant `SelectPicker` existant avec les comptes actifs formatés (icône + solde).

**Rationale**: `SelectPicker` est déjà utilisé dans `TransactionForm` pour la sélection de compte. Le computed signal `accountItems` transforme les comptes en `SelectItem[]` avec icône et texte secondaire (solde formaté).

**Alternatives considered**:
- Créer un sélecteur spécialisé `AccountPicker` → rejeté, `SelectPicker` est générique et suffisant.

## R5 — Gestion du rafraîchissement post-virement

**Decision**: Après un virement réussi, incrémenter `transactionService.refreshTrigger` et fermer la modale.

**Rationale**: C'est le pattern standard utilisé par `onTransactionSaved()` et `onSubscriptionSaved()` dans le Shell. Le `refreshTrigger` signal déclenche le rechargement réactif de la liste des transactions.

**Alternatives considered**:
- Rafraîchir aussi les soldes des comptes → déjà géré par `AccountService.refresh()` appelé dans `AccountService.transfer()` via `tap()`.
