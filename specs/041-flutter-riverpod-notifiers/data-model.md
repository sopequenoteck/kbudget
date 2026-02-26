# Data Model: Flutter Notifiers Riverpod CRUD

**Feature**: 041-flutter-riverpod-notifiers
**Date**: 2026-02-22

## Nouveau modele : ListState\<T\>

Etat generique Freezed partage par les 5 notifiers CRUD.

```dart
@freezed
class ListState<T> with _$ListState<T> {
  const factory ListState({
    @Default([]) List<T> items,
    @Default(false) bool isLoading,
    String? error,
    @Default(0) int currentPage,
    @Default(true) bool hasMore,
    @Default({}) Set<String> mutatingIds,
  }) = _ListState<T>;
}
```

| Champ | Type | Default | Description |
|-------|------|---------|-------------|
| `items` | `List<T>` | `[]` | Elements visibles (page courante incluse) |
| `isLoading` | `bool` | `false` | Chargement initial ou rechargement en cours |
| `error` | `String?` | `null` | Message d'erreur a afficher (null = pas d'erreur) |
| `currentPage` | `int` | `0` | Derniere page chargee (0-indexed) |
| `hasMore` | `bool` | `true` | Reste-t-il des elements non affiches ? |
| `mutatingIds` | `Set<String>` | `{}` | IDs des elements en cours de mutation (create/update/delete) |

### Donnees internes au notifier (non exposees dans l'etat)

Chaque notifier maintient en memoire privee :

| Champ | Type | Description |
|-------|------|-------------|
| `_allItems` | `List<T>` | Toutes les donnees chargees via `getAll()` |
| `_pageSize` | `int` | Taille de page (20 par defaut) |

## Entites existantes (inchangees)

Les modeles Freezed suivants sont utilises tels quels, sans modification :

### Transaction
```
id: String, montant: double, libelle: String, type: TransactionType,
date: DateTime, note: String?, transferId: String?,
categoryId: String?, accountId: String?, updatedAt: DateTime?
```
**Tri** : date decroissante

### Account
```
id: String, nom: String, type: AccountType, soldeInitial: double,
icone: String, couleur: String, isDefault: bool, currency: Currency,
actif: bool, updatedAt: DateTime?
```
**Tri** : nom croissant
**Action specifique** : `setDefault(id)` via `AccountRepository.setDefault()`

### Category
```
id: String, nom: String, icone: String, couleur: String,
isSystem: bool, updatedAt: DateTime?
```
**Tri** : nom croissant
**Protection** : mutations refusees si `isSystem == true`

### Subscription
```
id: String, nom: String, montant: double, frequence: Frequency,
dateDebut: DateTime, currency: Currency, actif: bool,
categoryId: String?, accountId: String?, updatedAt: DateTime?
```
**Tri** : nom croissant
**Action specifique** : toggle `actif` via `update(subscription.copyWith(actif: !actif))`

### Debt
```
id: String, personne: String, montant: double, sens: DebtType,
date: DateTime, currency: Currency, rembourse: bool,
categoryId: String?, updatedAt: DateTime?
```
**Tri** : date decroissante
**Action specifique** : `markAsRepaid(id)` via `update(debt.copyWith(rembourse: true))`

## Relations Notifier → Repository

```
TransactionNotifier → transactionRepositoryProvider → TransactionRepository
AccountNotifier     → accountRepositoryProvider     → AccountRepository
CategoryNotifier    → categoryRepositoryProvider    → CategoryRepository
SubscriptionNotifier → subscriptionRepositoryProvider → SubscriptionRepository
DebtNotifier        → debtRepositoryProvider        → DebtRepository
```

Chaque provider resout automatiquement vers Local ou Remote selon `dataModeProvider`.

## Diagramme d'etats du notifier

```
                    ┌──────────┐
                    │ initial  │  items=[], isLoading=false
                    └────┬─────┘
                         │ loadItems()
                         ▼
                    ┌──────────┐
                    │ loading  │  isLoading=true
                    └────┬─────┘
                    ┌────┴─────┐
                    ▼          ▼
              ┌──────────┐ ┌──────────┐
              │  loaded  │ │  error   │  error="message"
              │  items=N │ └────┬─────┘
              └────┬─────┘      │ retry()
                   │            ▼
                   │       (retour a loading)
                   │
          ┌────────┼────────┐
          ▼        ▼        ▼
       create   update   delete (optimiste)
          │        │        │
     isLoading  mutatingIds   mutatingIds
     = true     += id         += id
          │        │        │── retirer de items
          ▼        ▼        ▼
       succes    succes    succes/echec
          │        │        │
     ajouter    remplacer  echec: re-inserer
     dans items dans items
          │        │        │
     isLoading  mutatingIds   mutatingIds
     = false    -= id         -= id
```
