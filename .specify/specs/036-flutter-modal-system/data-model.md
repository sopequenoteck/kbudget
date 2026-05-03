# Data Model: Flutter — Système Modal / Bottom Sheet

**Feature**: 036-flutter-modal-system
**Date**: 2026-02-21

> Pas de modification de base de données. Ce document décrit les structures de données côté Flutter (état applicatif).

## Enums

### ModalType

Représente les 6 types de modale supportés.

| Valeur | Description | Toggle associé |
| ------ | ----------- | -------------- |
| `transaction` | Création/édition de transaction | Dépense / Recette |
| `subscription` | Création/édition d'abonnement | Mensuel / Annuel |
| `debt` | Création/édition de dette | Emprunt / Prêt |
| `transfer` | Création/édition de virement | Aucun |
| `category` | Création/édition de catégorie | Aucun |
| `account` | Création/édition de compte | Aucun |

### ModalMode

| Valeur | Description |
| ------ | ----------- |
| `create` | Mode création (nouvelle entité) |
| `edit` | Mode édition (entité existante) |

## State Classes

### ModalState (sealed union via freezed)

```
ModalState
├── ModalClosed            → Aucune modale ouverte
└── ModalOpen              → Une modale est ouverte
    ├── type: ModalType    → Type de modale (transaction, subscription, etc.)
    ├── mode: ModalMode    → Mode création ou édition
    ├── entity: Object?    → Entité en cours d'édition (null en création)
    └── subType: dynamic?  → Sous-type actif du toggle (TransactionType, Frequency, DebtType, ou null)
```

### Transitions d'état

```
ModalClosed ──open(type, entity?)──→ ModalOpen
ModalOpen   ──close()─────────────→ ModalClosed
ModalOpen   ──setSubType(value)───→ ModalOpen (même type, sous-type mis à jour)
ModalOpen   ──open(type, entity?)──→ ModalClosed → ModalOpen (ferme puis ouvre)
```

### Titres dérivés (computed)

| ModalType | Mode Create | Mode Edit |
| --------- | ----------- | --------- |
| `transaction` | Nouvelle transaction | Modifier la transaction |
| `subscription` | Nouvel abonnement | Modifier l'abonnement |
| `debt` | Nouvelle dette | Modifier la dette |
| `transfer` | Nouveau virement | Modifier le virement |
| `category` | Nouvelle catégorie | Modifier la catégorie |
| `account` | Nouveau compte | Modifier le compte |

### Defaults du toggle par type (mode création)

| ModalType | Sous-type par défaut |
| --------- | -------------------- |
| `transaction` | `TransactionType.depense` |
| `subscription` | `Frequency.mensuel` |
| `debt` | `DebtType.emprunt` |
| `transfer` | null (pas de toggle) |
| `category` | null (pas de toggle) |
| `account` | null (pas de toggle) |

## Relations avec les entités existantes

Les enums existants sont réutilisés tels quels :

- `TransactionType` (`domain/enums/transaction_type.dart`) : `depense`, `recette`
- `Frequency` (`domain/enums/frequency.dart`) : `mensuel`, `annuel`
- `DebtType` (`domain/enums/debt_type.dart`) : `emprunt`, `pret`

Les modèles existants sont passés en tant qu'`entity` en mode édition :

- `Transaction` (`domain/models/transaction.dart`)
- `Subscription` (`domain/models/subscription.dart`)
- `Debt` (`domain/models/debt.dart`)
- `Account` (`domain/models/account.dart`)
- `Category` (`domain/models/category.dart`)

Aucune modification de ces fichiers existants n'est requise.
