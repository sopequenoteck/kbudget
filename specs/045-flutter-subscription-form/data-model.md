# Data Model: Formulaire Abonnement (Flutter)

**Date**: 2026-02-23
**Feature**: 045-flutter-subscription-form

## Entités impliquées

### Subscription (existante — aucune modification)

| Champ | Type | Requis | Validation | Description |
|-------|------|--------|------------|-------------|
| id | String (UUID) | Oui | Auto-généré | Identifiant unique |
| nom | String | Oui | Non vide, max 255 caractères | Nom de l'abonnement |
| montant | double | Oui | Strictement positif (> 0) | Montant récurrent |
| frequence | Frequency (enum) | Oui | mensuel \| annuel | Périodicité |
| dateDebut | DateTime | Oui | Date valide | Date de début |
| currency | Currency (enum) | Non | Défaut: EUR | Devise |
| actif | bool | Non | Défaut: true | Statut actif/inactif |
| categoryId | String? | Non | UUID valide ou null | FK vers Category |
| accountId | String? | Non | UUID valide ou null | FK vers Account |
| updatedAt | DateTime? | Non | Auto-géré | Dernière mise à jour |

### Relations

```
Subscription *--1 Account (optionnel, via accountId)
Subscription *--1 Category (optionnel, via categoryId)
```

### Enums utilisés

| Enum | Valeurs | Fichier |
|------|---------|---------|
| Frequency | mensuel, annuel | `domain/enums/frequency.dart` |
| Currency | eur, xof, usd, ... | `domain/enums/currency.dart` |
| ModalType | subscription (+ autres) | `domain/enums/modal_type.dart` |
| ModalMode | create, edit | `domain/enums/modal_type.dart` |

## État du formulaire (local au widget)

| Champ | Type | Valeur initiale (création) | Source (édition) |
|-------|------|---------------------------|-----------------|
| _nomController | TextEditingController | vide | subscription.nom |
| _montantController | TextEditingController | vide | subscription.montant.toString() |
| _selectedFrequence | Frequency | Frequency.mensuel (via modal state) | subscription.frequence |
| _selectedDate | DateTime | DateTime.now() | subscription.dateDebut |
| _selectedAccountId | String? | compte par défaut (isDefault && actif) | subscription.accountId |
| _selectedCategoryId | String? | null | subscription.categoryId |
| _isActif | bool | true | subscription.actif |
| _showErrors | bool | false | false |
| _isSubmitting | bool | false | false |
| _initialized | bool | false | false |

## Flux de données

### Création

```
SubscriptionForm
  → construit Subscription(id: uuid, nom, montant, frequence, dateDebut, ...)
  → appelle onSaved(subscription)
  → SubscriptionNotifier.create(subscription)
  → SubscriptionRepository.create(subscription)
  → [Local: SubscriptionDao.insertSubscription() | Remote: POST /subscriptions]
  → Met à jour ListState<Subscription>
```

### Édition

```
SubscriptionForm (pré-rempli)
  → construit Subscription mis à jour (même id)
  → appelle onSaved(subscription)
  → SubscriptionNotifier.update(subscription)
  → SubscriptionRepository.update(subscription)
  → [Local: SubscriptionDao.updateSubscription() | Remote: PUT /subscriptions/{id}]
  → Met à jour ListState<Subscription>
```

### Suppression

```
SubscriptionForm
  → bouton Supprimer → dialogue de confirmation
  → appelle onDeleted(id)
  → SubscriptionNotifier.delete(id)
  → SubscriptionRepository.delete(id)
  → [Local: SubscriptionDao.deleteSubscription() | Remote: DELETE /subscriptions/{id}]
  → Suppression optimiste avec rollback on error
```
