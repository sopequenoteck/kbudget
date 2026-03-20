# Research: 078-angular-debt-enhancements

## R1 — État actuel de l'interface dettes Angular

**Decision**: Enrichir les composants existants + créer un écran détail
**Rationale**: Le `DebtService`, `DebtFormComponent` et `Debts` (liste) existent mais sont CRUD-only. Le modèle `Debt` manque ~8 champs disponibles côté API depuis KKS-077. Aucun écran détail n'existe.
**Alternatives considered**:
- Refonte complète du module dettes → Rejeté (over-engineering, le code existant est sain)
- Tout en modal (pas d'écran détail) → Rejeté (historique des paiements + barre progression nécessitent un écran dédié)

## R2 — Contrats API backend (KKS-077)

**Decision**: Consommer les 3 nouveaux endpoints + enrichir les DTOs Angular
**Rationale**: Backend expose : `POST /debts/{id}/repay` (DebtRepayRequest → DebtResponse), `GET /debts/{id}/payments` (→ DebtPaymentResponse[]), `POST /debts/{id}/snooze` (DebtSnoozeRequest → DebtResponse). DebtResponse inclut désormais `montantRestant`, `account` (AccountSummary), `includeInBalance`, `reminderDate`, `reminderTime`, `dueDate`.
**Alternatives considered**: Aucune — contrats API fixés.

## R3 — Pattern toast/snackbar

**Decision**: Créer un `ToastService` signal-based + composant `Toast`
**Rationale**: Aucun système toast n'existe dans le projet Angular. Les patterns existants (error banner dans les forms, notification panel) ne couvrent pas le besoin de feedback transient post-action. Signal-based est cohérent avec l'approche signals-first du projet.
**Alternatives considered**:
- Angular Material Snackbar → Rejeté (pas de dépendance Material dans le projet)
- Réutiliser le NotificationPanel → Rejeté (c'est pour les notifications persistantes, pas le feedback transient)

## R4 — Pattern dialogs contextuels

**Decision**: Dialogs standalone (overlay + backdrop) séparés du ModalService
**Rationale**: Le ModalService existant gère les formulaires CRUD via un pattern centralisé dans le Shell (`@switch` sur `modalService.activeModal()`). Les dialogs remboursement/report sont simples (2-3 champs), contextuels (attachés à l'écran détail ou notification), et ne suivent pas le cycle CRUD.
**Alternatives considered**:
- Ajouter `ModalType.repay` / `ModalType.snooze` → Rejeté (surcharge le ModalService, mélange formulaires CRUD et actions contextuelles)
- Utiliser Angular CDK Dialog → Rejeté (pas de dépendance CDK Dialog dans le projet)

## R5 — Navigation liste → détail

**Decision**: Tap sur dette → navigation `/debts/:id` (remplace l'ouverture du modal d'édition)
**Rationale**: L'écran détail est le hub pour consulter montant restant, progression, historique et actions. L'édition se fait depuis le détail via un bouton "Modifier".
**Alternatives considered**:
- Garder tap → modal + ajouter un bouton "Détail" séparé → Rejeté (double action confuse, mobile-unfriendly)

## R6 — NotificationType Angular

**Decision**: Ajouter `DEBT_REMINDER` au type Angular `NotificationType`
**Rationale**: Le backend (KKS-077) a ajouté `DEBT_REMINDER` à l'enum `NotificationType`. Angular expose actuellement `'SUBSCRIPTION_DUE' | 'DEBT_DUE'` uniquement. Les notifications `DEBT_REMINDER` et `DEBT_DUE` doivent toutes deux afficher les actions "Reporter" / "Rembourser".
**Alternatives considered**: Aucune — alignement nécessaire avec le backend.
