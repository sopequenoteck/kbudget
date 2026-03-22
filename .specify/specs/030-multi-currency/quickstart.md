# Quickstart: Gestion des devises (multi-currency)

**Feature**: 030-multi-currency | **Date**: 2026-02-17

## Séquence d'implémentation recommandée

L'ordre suit le principe API-First : backend d'abord, frontend ensuite. Chaque phase est testable indépendamment.

### Phase 1 — Backend : Fondations (enum + migration + entités)

1. **Créer l'enum `Currency`** dans `api/.../enums/Currency.java`
   - 7 valeurs : EUR, XOF, USD, GBP, CHF, CAD, MAD
   - Attributs : symbol, displayName, decimalPlaces

2. **Créer la migration `V8__add_currency_support.sql`**
   - 4 ALTER TABLE ADD COLUMN (accounts, debts, subscriptions, users)
   - Toutes NOT NULL DEFAULT 'EUR'

3. **Modifier les entités JPA** (Account, Debt, Subscription, User)
   - Ajouter `currency` / `defaultCurrency` avec `@Enumerated(EnumType.STRING)`

**Vérification** : `mvn clean compile` doit passer. Lancer l'API avec profil dev pour valider la migration.

### Phase 2 — Backend : DTOs + Endpoints existants

4. **Modifier les DTOs** : AccountRequest/Response, DebtRequest/Response, SubscriptionRequest/Response, AccountSummary, MonthlySummary
   - Ajouter `currency` à chaque DTO

5. **Créer les nouveaux DTOs** : UserResponse, UserUpdateRequest, CurrencyInfo

6. **Modifier les services** :
   - `AccountService` : currency par défaut à la création, immutabilité au update, validation transfer cross-currency
   - `DebtService` : currency par défaut à la création
   - `SubscriptionService` : currency forcée depuis account si lié
   - `TransactionService` : summary groupé par currency (modifier la query repository)

7. **Créer les nouveaux endpoints** :
   - `CurrencyController` : GET /currencies
   - `UserController` : GET/PUT /users/me

**Vérification** : Tests d'intégration sur les endpoints modifiés et nouveaux. Tester avec Swagger UI.

### Phase 3 — Backend : Tests

8. **Tests d'intégration** :
   - Transfer cross-currency → 400
   - Création compte avec/sans currency
   - Immutabilité currency au update
   - Subscription currency forcée depuis account
   - Summary groupé par currency
   - GET/PUT /users/me

### Phase 4 — Frontend : Modèles + Services

9. **Modifier les modèles TypeScript** : Account, Debt, Subscription, UserInfo, MonthlySummary
10. **Créer les nouveaux modèles** : CurrencyInfo
11. **Créer les services** : CurrencyService, UserService (preferences)

### Phase 5 — Frontend : Pipe + Formulaires

12. **Modifier AmountPipe** : paramètre currency dynamique
13. **Modifier account-form** : sélecteur devise (disabled en mode édition)
14. **Modifier debt-form** : sélecteur devise
15. **Modifier subscription-form** : devise auto si account lié, sinon sélecteur

### Phase 6 — Frontend : Settings + Dashboard

16. **Modifier profile settings** : sélecteur devise par défaut
17. **Modifier dashboard** : totaux groupés par devise

## Fichiers clés à lire avant de commencer

| Fichier | Pourquoi |
|---------|----------|
| `api/.../enums/AccountType.java` | Pattern enum existant (avec attributs) |
| `api/.../service/AccountService.java` | Logique transfer + createAccount |
| `api/.../service/SubscriptionService.java` | Logique account lié |
| `api/.../dto/request/AccountRequest.java` | Pattern DTO record existant |
| `app/.../pipes/amount.pipe.ts` | Formatage actuel (EUR hardcodé) |
| `app/.../dashboard/dashboard.ts` | Agrégation totaux actuelle |
| `api/src/main/resources/db/migration/V7__add_accounts.sql` | Pattern migration existant |

## Risques identifiés

| Risque | Mitigation |
|--------|------------|
| Breaking change MonthlySummary (objet → liste) | Frontend modifié en même temps. Pas d'API publique. |
| Enum Currency non extensible sans rebuild | Acceptable (spec: "extensible par simple ajout de code"). |
| Intl.NumberFormat comportement XOF avec locale fr-FR | Tester : `new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF' }).format(15000)` |
