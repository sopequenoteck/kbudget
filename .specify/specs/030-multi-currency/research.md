# Research: Gestion des devises (multi-currency)

**Feature**: 030-multi-currency | **Date**: 2026-02-17

## R1 — Représentation des devises en Java

**Decision**: Enum Java `Currency` dans le package `enums/`

**Rationale**: Le projet utilise déjà des enums pour toutes les valeurs fixes du domaine (`AccountType`, `DebtType`, `Frequency`, `TransactionType`, `TokenStatus`). Un enum est cohérent avec le principe III (Simplicité) et la constitution. La liste fermée de 7 devises est bien adaptée à un enum. Le code ISO 4217 sert de nom d'enum (`EUR`, `XOF`, etc.). L'enum porte les métadonnées utiles au frontend (symbole, nombre de décimales, nom français) pour éviter de dupliquer cette logique.

**Alternatives considered**:
- `String` brut (code ISO) : Pas de validation à la compilation, nécessite des constantes séparées. Rejeté.
- `java.util.Currency` (JDK) : Disponible mais ne contient pas les métadonnées UI nécessaires (symbole custom, nom FR). Rejeté car ajouterait une couche de mapping inutile.
- Table en base `currencies` : Sur-ingénierie pour 7 valeurs fixes (violation YAGNI). Rejeté.

## R2 — Stockage en base de données

**Decision**: Colonne `VARCHAR(3)` avec `@Enumerated(EnumType.STRING)` sur les entités Account, Debt, Subscription. Colonne `default_currency` sur la table users.

**Rationale**: Pattern identique à `AccountType`, `DebtType`, etc. dans le projet. `EnumType.STRING` est plus lisible en base que `ORDINAL` et résiste aux réordonnements d'enum. `NOT NULL DEFAULT 'EUR'` sur toutes les colonnes assure la rétrocompatibilité (FR-012).

**Alternatives considered**:
- `EnumType.ORDINAL` : Fragile si l'enum est réordonné. Rejeté.
- Table de référence avec FK : YAGNI pour 7 valeurs. Rejeté.

## R3 — Migration Flyway V8

**Decision**: Migration unique `V8__add_currency_support.sql` qui :
1. Ajoute `currency VARCHAR(3) NOT NULL DEFAULT 'EUR'` à `accounts`
2. Ajoute `currency VARCHAR(3) NOT NULL DEFAULT 'EUR'` à `debts`
3. Ajoute `currency VARCHAR(3) NOT NULL DEFAULT 'EUR'` à `subscriptions`
4. Ajoute `default_currency VARCHAR(3) NOT NULL DEFAULT 'EUR'` à `users`

**Rationale**: Migration atomique. Le `DEFAULT 'EUR'` applique FR-012 (migration existants → EUR) sans script de data migration séparé. Les colonnes sont ajoutées avec une valeur par défaut, donc pas de downtime ni de migration de données complexe.

## R4 — Immutabilité devise du compte

**Decision**: Validation côté service uniquement. L'`AccountRequest` contient `currency` mais `AccountService.updateAccount()` ignore ce champ (ou lève une erreur si différent de l'existant).

**Rationale**: Pas besoin de deux DTOs séparés (CreateAccountRequest / UpdateAccountRequest) pour une seule différence. Le service fait la validation business (FR-002). Pattern cohérent avec l'existant (ex: `isDefault` a aussi des règles de mise à jour spécifiques dans le service).

**Alternatives considered**:
- DTOs séparés create/update : Duplication de code pour un seul champ différent. Rejeté (YAGNI).
- Annotation custom `@Immutable` : Sur-ingénierie. Rejeté.

## R5 — Devise des abonnements liés à un compte

**Decision**: Le `SubscriptionService` force la devise depuis `account.getCurrency()` si `accountId` est fourni. Si `accountId` est null, la devise vient du request ou de `user.getDefaultCurrency()`.

**Rationale**: Clarification spec confirmée : devise forcée = devise du compte si lié (option A). Cela se traduit par une logique dans le service : `subscription.setCurrency(account != null ? account.getCurrency() : requestCurrencyOrDefault)`. Sur update, si l'account change, la devise suit automatiquement.

## R6 — Validation transfer cross-currency

**Decision**: Ajout d'une validation dans `AccountService.transfer()` après la vérification des comptes actifs. Si `fromAccount.getCurrency() != toAccount.getCurrency()`, lever une `IllegalArgumentException` avec message explicite.

**Rationale**: FR-010 exige un blocage avec message d'erreur explicite. La validation est au même niveau que les autres (même compte, comptes inactifs). Le message d'erreur doit être clair : "Le virement entre comptes de devises différentes n'est pas autorisé".

## R7 — API summary groupé par devise

**Decision**: Modifier le retour de `GET /transactions/summary` de `MonthlySummary` à `List<MonthlySummary>` où chaque élément inclut un champ `currency`. La query repository agrège par currency via `GROUP BY`.

**Rationale**: Le dashboard (FR-011) doit afficher des totaux séparés par devise. Retourner une liste permet au frontend de boucler sur les devises. Breaking change acceptable car on contrôle les deux côtés.

**Alternatives considered**:
- Paramètre `?currency=EUR` pour filtrer : Nécessiterait N appels API pour N devises. Rejeté.
- Endpoint séparé `/transactions/summary-by-currency` : Duplication inutile. Rejeté.

## R8 — Endpoint profil utilisateur

**Decision**: Nouveau `UserController` avec :
- `GET /users/me` → `UserResponse { name, email, defaultCurrency }`
- `PUT /users/me` → `UserUpdateRequest { name?, defaultCurrency? }`

**Rationale**: Actuellement aucun endpoint pour modifier les préférences utilisateur. Le pattern `/users/me` est standard REST pour le profil authentifié. Le `UserResponse` enrichit l'existant `UserInfo` du JWT avec la devise par défaut (stockée en base, pas dans le token).

## R9 — Frontend : AmountPipe dynamique

**Decision**: Modifier `AmountPipe` pour accepter un paramètre `currency` optionnel. Utiliser `Intl.NumberFormat('fr-FR', { style: 'currency', currency: currencyCode })`. Si pas de currency fourni, fallback sur 'EUR' pour rétrocompatibilité.

**Rationale**: `Intl.NumberFormat` gère nativement le formatage par devise (symbole, décimales, séparateurs). Le locale `fr-FR` est approprié car l'app est en français. XOF avec locale fr-FR → "15 000 FCFA" (0 décimales), EUR → "150,00 €" (2 décimales). Conforme à FR-007.

**Alternatives considered**:
- Pipe Angular `CurrencyPipe` natif : Ne permet pas le contrôle fin du signDisplay existant. Rejeté.
- Bibliothèque tierce (dinero.js, currency.js) : Dépendance externe inutile pour du formatage. Rejeté (YAGNI).

## R10 — Liste des devises supportées (endpoint)

**Decision**: Nouveau `CurrencyController` avec `GET /currencies` → `List<CurrencyInfo>`. Le `CurrencyInfo` expose : code, symbol, name, decimalPlaces.

**Rationale**: Principe I (API-First) : le backend est la source de vérité pour les devises supportées. Le frontend consomme cette liste pour les sélecteurs. Évite la duplication de la liste entre backend et frontend.

**Alternatives considered**:
- Hardcoder la liste dans le frontend : Duplication, risque de désynchronisation. Rejeté.
- Inclure les devises dans un endpoint existant : Pas de candidat naturel. Rejeté.
