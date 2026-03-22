# Quickstart: Currency Rebase Propagation

**Feature**: 095-currency-rebase-propagation
**Date**: 2026-03-15

## Résumé technique

3 couches à modifier, dans cet ordre :

### 1. Backend — Rebase automatique (~10 lignes)

**Fichier** : `api/src/main/java/.../service/PreferenceService.java`

Dans `updatePreferences()`, avant `preference.setCurrencies(request.currencies())` :
```java
Currency oldPrimary = preference.getCurrencies().get(0);
Currency newPrimary = request.currencies().get(0);
if (oldPrimary != newPrimary) {
    log.info("Devise principale changée {} → {}, rebase des taux", oldPrimary, newPrimary);
    exchangeRateService.rebaseRates(userId, oldPrimary, newPrimary);
}
```

**Test** : `PreferenceServiceTest` — ajouter `should_rebaseRates_when_primaryCurrencyChanges` et `should_notRebaseRates_when_primaryCurrencyUnchanged`.

### 2. Angular — Rechargement des taux (~5 lignes)

**Fichier** : `app/src/app/core/services/exchange-rate.ts`

Dans `ExchangeRateService`, exposer `loadRates()` (ou s'assurer qu'il est public).

**Fichier** : `app/src/app/core/services/preference.ts`

Dans `setCurrencies()`, après le PUT, appeler `this.exchangeRateService.loadRates()`.

**Fichier** : `app/src/app/features/dashboard/dashboard.ts`

Afficher un indicateur quand `hasMissingRate` est true (icône `ph-warning-circle` + tooltip).

### 3. Flutter — Rechargement des taux (~10 lignes)

**Fichier** : `flutter/.../exchange_rates/application/currency_config_notifier.dart`

Dans `reorderCurrencies()`, après le PUT preferences, appeler `ref.read(exchangeRateNotifierProvider.notifier).loadItems()`.

**Fichier** : Dashboard Flutter

Calculer `hasMissingRate` dans le dashboard state et afficher l'indicateur visuel.

## Ordre de build

1. Backend (rebase auto) → tests backend
2. Angular (reload taux + indicateur) → vérification manuelle
3. Flutter (reload taux + indicateur) → vérification manuelle

## Vérification rapide

1. Configurer 2 devises (EUR, XOF) avec un taux
2. Changer la devise principale de EUR → XOF dans les paramètres
3. Vérifier que les taux en base sont rebasés sur XOF
4. Vérifier que le dashboard affiche les montants convertis corrects
5. Supprimer un taux → vérifier que l'indicateur "taux manquant" apparaît sur le total
