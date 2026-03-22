# Data Model: 016-modal-service

**Date**: 2026-02-12

## Nouvelles entités

### ModalType (type existant, réutilisé)

Type union string déjà défini dans `fab.ts` :

```
'transaction' | 'subscription' | 'debt'
```

Réexporté ou importé depuis le ModalService pour éviter le couplage avec le Fab.

### ModalService (service — état interne)

| Signal | Type | Description |
|--------|------|-------------|
| `activeModal` | `ModalType \| null` | Type de modale actuellement ouverte, `null` si fermée |
| `editingEntity` | `Transaction \| Subscription \| Debt \| null` | Entité en cours d'édition, `null` en mode création |
| `modalOpen` | `boolean` (computed) | Dérivé : `activeModal !== null` |
| `modalTitle` | `string` (computed) | Titre dynamique selon type + mode (create/edit) |

| Méthode | Signature | Description |
|---------|-----------|-------------|
| `openModal` | `(type: ModalType, entity?: Transaction \| Subscription \| Debt) => void` | Ouvre la modale. Si entity fournie = mode édition, sinon = mode création |
| `closeModal` | `() => void` | Ferme la modale et reset l'entité en édition |

### Transitions d'état

```
[fermé] --openModal(type)--> [ouvert, mode création]
[fermé] --openModal(type, entity)--> [ouvert, mode édition]
[ouvert] --closeModal()--> [fermé]
[ouvert] --save/delete réussi--> [fermé] (via closeModal)
[ouvert] --NavigationEnd--> [fermé] (via closeModal)
```

## Entités existantes (non modifiées)

### Transaction, Subscription, Debt

Aucune modification aux modèles existants. Les entités sont passées telles quelles au ModalService via `openModal()`.

### TransactionRequest, SubscriptionRequest, DebtRequest

Aucune modification. Les DTOs de requête continuent d'être émis par les formulaires via l'output `saved`.

## Nouveaux outputs sur les formulaires

| Formulaire | Nouvel output | Type | Description |
|------------|---------------|------|-------------|
| TransactionForm | `deleted` | `string` (ID) | Émis quand l'utilisateur confirme la suppression |
| SubscriptionForm | `deleted` | `string` (ID) | Idem |
| DebtForm | `deleted` | `string` (ID) | Idem |

## Nouvel état local dans les formulaires

| Signal | Type | Description |
|--------|------|-------------|
| `showDeleteConfirm` | `boolean` | Affiche/masque la zone de confirmation de suppression inline |
