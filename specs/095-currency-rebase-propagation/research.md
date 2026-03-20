# Research: Currency Rebase Propagation

**Feature**: 095-currency-rebase-propagation
**Date**: 2026-03-15

## R1: Mécanisme de rebase existant

**Decision**: Utiliser `ExchangeRateService.rebaseRates(userId, oldPrimary, newPrimary)` existant.

**Rationale**: La méthode existe déjà et gère correctement l'inversion des taux et le calcul de cross-rates. Elle est testée et utilisée dans d'autres contextes (feature 070). Il manque uniquement le déclencheur automatique.

**Alternatives considered**:
- Recalculer les taux côté frontend → Rejeté (viole API-First, source de vérité dupliquée)
- Créer un endpoint dédié `/exchange-rates/rebase` → Rejeté (YAGNI, le rebase est un effet de bord du changement de devise, pas une action utilisateur explicite)

## R2: Point d'injection du rebase automatique

**Decision**: Ajouter la détection du changement de devise principale dans `PreferenceService.updatePreferences()`, juste avant la sauvegarde de la nouvelle liste de devises.

**Rationale**: `PreferenceService.updatePreferences()` est le seul point d'entrée pour modifier les devises. C'est déjà `@Transactional` (via Spring), donc si `rebaseRates()` échoue, le rollback est automatique (FR-002 satisfait nativement).

**Code path existant** (PreferenceService.java, lignes 72-87) :
```
if (request.currencies() != null) {
    // validation (non-vide, pas de doublons, primaire stable parmi enabled)
    ...
    preference.setCurrencies(request.currencies());
}
```

**Injection point** : entre la validation et le `setCurrencies()`, comparer `preference.getCurrencies().get(0)` (ancien) avec `request.currencies().get(0)` (nouveau). Si différents → appeler `rebaseRates()`.

**Alternatives considered**:
- Listener JPA `@PreUpdate` sur `UserPreference` → Rejeté (les listeners n'ont pas accès aux anciennes valeurs facilement, et injection de service dans un listener est un anti-pattern Spring)
- Event-driven avec `ApplicationEventPublisher` → Rejeté (YAGNI pour single-user, ajoute de la complexité sans bénéfice)

## R3: Propagation frontend Angular

**Decision**: Après `setCurrencies()` dans `PreferenceService` Angular, appeler `ExchangeRateService.loadRates()` pour recharger les taux depuis le serveur.

**Rationale**: `ExchangeRateService._rates` est un signal. Quand il change, `ConversionService.convert()` utilise les nouveaux taux. Le dashboard a des `computed()` qui dépendent de `ConversionService`, donc la mise à jour est automatique via le graphe de signaux Angular.

**Chain de propagation**:
```
PreferenceService.setCurrencies()
  → ExchangeRateService.loadRates()  [GET /exchange-rates]
  → _rates signal updated
  → ConversionService.convert() uses new rates
  → Dashboard.convertedTotalBalance computed() recalculates
  → UI updates automatically
```

**Alternatives considered**:
- Recharger toute la page → Rejeté (mauvaise UX, perte d'état)
- WebSocket push des nouveaux taux → Rejeté (YAGNI, la latence d'un GET supplémentaire est négligeable pour single-user)

## R4: Propagation frontend Flutter

**Decision**: Après `reorderCurrencies()` dans `CurrencyConfigNotifier`, appeler `ref.read(exchangeRateNotifierProvider.notifier).loadItems()` pour recharger les taux.

**Rationale**: `ExchangeRateNotifier` est un `Notifier<ListState<ExchangeRate>>`. Les écrans qui observent ce provider (via `ref.watch`) se reconstruisent automatiquement quand l'état change. Le pattern est identique à celui utilisé pour les comptes et catégories.

**Chain de propagation**:
```
CurrencyConfigNotifier.reorderCurrencies()
  → PUT /users/me/preferences (backend rebase les taux)
  → ExchangeRateNotifier.loadItems()  [GET /exchange-rates]
  → state updated (ListState<ExchangeRate>)
  → DashboardNotifier/DebtListScreen ref.watch() triggers rebuild
  → UI updates automatically
```

**Alternatives considered**:
- Invalider manuellement chaque provider dépendant → Rejeté (fragile, oubli possible de providers)
- Utiliser `ref.invalidate()` sur l'exchange rate provider → Acceptable mais `loadItems()` est plus explicite et déjà le pattern utilisé

## R5: Indicateur visuel taux manquant

**Decision**: Utiliser le flag `hasMissingRate` existant sur Angular (déjà calculé dans `dashboard.ts` ligne 106) et l'ajouter côté Flutter. Afficher une icône Phosphor `warning-circle` avec tooltip à côté du solde total.

**Rationale**: Angular calcule déjà `hasMissingRate` dans le `convertedTotalBalance` computed mais ne l'affiche pas. Il suffit d'ajouter le rendu conditionnel. Côté Flutter, le dashboard doit calculer ce flag de la même manière.

**Alternatives considered**:
- Toast/Snackbar → Rejeté (disparaît, l'utilisateur peut le manquer)
- Banner permanent en haut → Rejeté (trop intrusif pour une info secondaire)

## R6: Transactionalité

**Decision**: S'appuyer sur le `@Transactional` existant de Spring sur `updatePreferences()`.

**Rationale**: `PreferenceService.updatePreferences()` est déjà `@Transactional`. Si `rebaseRates()` lève une exception, Spring rollback automatiquement toute la transaction (préférences + taux). Pas besoin d'ajouter de gestion transactionnelle supplémentaire.

**Vérification nécessaire**: Confirmer que `rebaseRates()` ne fait pas de `flush()` ou `saveAndFlush()` qui pourrait forcer un commit partiel. D'après le code existant, il utilise `saveAll()` qui reste dans la transaction courante.
