# Data Model: Currency Rebase Propagation

**Feature**: 095-currency-rebase-propagation
**Date**: 2026-03-15

## Entités impactées

### ExchangeRate (existant, inchangé)

| Champ          | Type       | Contraintes                                      |
|----------------|------------|--------------------------------------------------|
| id             | UUID       | PK                                               |
| baseCurrency   | Currency   | NOT NULL, enum                                   |
| targetCurrency | Currency   | NOT NULL, enum                                   |
| rate           | BigDecimal | precision 20, scale 6, NOT NULL                  |
| updatedAt      | DateTime   | Auto-updated                                     |
| user           | User       | FK, NOT NULL                                     |

**Contrainte unique** : `(user_id, base_currency, target_currency)`

**Comportement lors du rebase** :
- Si `oldPrimary = EUR`, `newPrimary = XOF`, et taux `EUR→XOF = 655.957` :
  - Inversion : le taux `EUR→XOF` devient `XOF→EUR = 1/655.957`
  - Cross-rate : le taux `EUR→USD = 1.08` devient `XOF→USD = 1.08/655.957`
- Arrondi : HALF_UP, 6 décimales

### UserPreference (existant, inchangé)

| Champ              | Type             | Contraintes                            |
|--------------------|------------------|----------------------------------------|
| currencies         | List\<Currency\> | NOT NULL, min 1, [0] = devise principale |

**Comportement modifié** :
- Lors d'un `updatePreferences()` avec changement de `currencies[0]`, `rebaseRates()` est appelé automatiquement avant la sauvegarde.

## Aucune migration requise

Pas de nouvelle table, pas de nouvelle colonne. Les entités existantes sont inchangées. Le changement est purement comportemental (logique dans `PreferenceService`).
