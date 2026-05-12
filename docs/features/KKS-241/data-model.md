# Data Model — KKS-241 : Refonte 3 formulaires XL Flutter

> Feature purement présentationnelle. Aucune migration Drift ni nouveau modèle de domaine.
> Le seul ajout data est le DTO de request pour la création de récurrence.

---

## Nouveau DTO — `RecurringTransactionCreateRequest`

**Fichier** : `flutter/lib/src/data/remote/dtos/recurring_transaction_create_request.dart`
**Type** : Freezed + json_serializable (request-only, pas de `toDomain()`)

```dart
@freezed
class RecurringTransactionCreateRequest with _$RecurringTransactionCreateRequest {
  const factory RecurringTransactionCreateRequest({
    required double montant,
    required String libelle,
    required String type,            // "DEPENSE" | "REVENU"
    required String frequency,       // "HEBDOMADAIRE" | "MENSUEL" | "ANNUEL"
    required String nextOccurrence,  // ISO 8601 — ex: "2026-06-01"
    String? categoryId,
    String? accountId,
    String? note,
  }) = _RecurringTransactionCreateRequest;

  factory RecurringTransactionCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionCreateRequestFromJson(json);
}
```

### Mapping depuis l'état du formulaire

| Champ Flutter | Champ request | Transformation |
|---------------|--------------|----------------|
| `_montantController.text` | `montant` | `double.parse()` |
| `_libelleController.text` | `libelle` | trim |
| `_selectedType` (TransactionType) | `type` | `.name.toUpperCase()` |
| `_recurringFrequency` (Frequency) | `frequency` | `.name.toUpperCase()` |
| `_recurringNextOccurrence` (DateTime) | `nextOccurrence` | `DateFormat('yyyy-MM-dd').format()` |
| `_selectedCategoryId` | `categoryId` | nullable |
| `_selectedAccountId` | `accountId` | nullable |
| `_noteController.text` | `note` | nullable si vide |

### Endpoint cible

`POST /api/transactions/recurring`

Payload exact conforme à `RecurringTransactionRequest` Spring (vérifié lors de la research — même structure que le payload Angular).

---

## Entités existantes non modifiées

| Entité | Fichier | Changement |
|--------|---------|------------|
| `Transaction` | `domain/models/transaction.dart` | Aucun |
| `Subscription` | `domain/models/subscription.dart` | Aucun |
| `Debt` | `domain/models/debt.dart` | Aucun — `includeInBalance` conservé dans le modèle, supprimé de l'UI uniquement |
| `RecurringTransaction` | `domain/models/recurring_transaction.dart` | Aucun |

---

## Schéma Drift

Aucune migration requise. `includeInBalance` reste dans le schéma Drift (table `debts`, colonne `include_in_balance BOOLEAN DEFAULT FALSE`). Sa valeur est calculée silencieusement à la soumission : `includeInBalance = accountId != null`.
