# Research: Currency Dashboard

**Feature Branch**: `070-currency-dashboard`
**Date**: 2026-03-06

## R1 — Stockage des taux de conversion

**Decision**: Nouvelle entite `exchange_rates` avec contrainte d'unicite `(user_id, base_currency, target_currency)`. Type `DECIMAL(20,6)` pour le taux.

**Rationale**: Un seul taux par paire par utilisateur, pas d'historique (YAGNI). 6 decimales couvrent les inversions de taux eleves (XOF->EUR = 0.001524). `DECIMAL(20,6)` est le type PostgreSQL standard pour les taux financiers avec precision fixe.

**Alternatives considered**:
- JSON dans UserPreference : rejete — pas de validation SQL, pas de contrainte d'unicite, queries difficiles
- Table separee `currency_pairs` partagee : rejete — les taux sont par utilisateur (manuels), pas globaux

## R2 — Migration de User.defaultCurrency vers UserPreference.currencies

**Decision**: Deux migrations Flyway sequentielles :
- V13 : Ajoute `currencies VARCHAR(100)` a `user_preferences` + cree `exchange_rates`. Initialise `currencies` depuis `users.default_currency`.
- V14 : Supprime `default_currency` de `users`.

**Rationale**: Migration en deux etapes pour backward-compatibility. V13 ajoute sans casser, V14 nettoie apres adaptation du code. Le format stockage de `currencies` est une liste CSV convertie via `@Convert` (meme pattern que `FeatureListConverter`).

**Alternatives considered**:
- Migration unique : rejete — risque si le code n'est pas pret pour le nouveau champ
- Colonne JSON array : rejete — plus complexe qu'un CSV pour un enum a 7 valeurs max

## R3 — Inversion automatique des taux lors du changement de devise principale

**Decision**: Logique dans `ExchangeRateService.rebaseRates(userId, newBaseCurrency)`. Pour chaque taux existant : `newRate = 1 / oldRate`, inverser base/target, arrondir a 6 decimales. Operation atomique dans une seule transaction.

**Rationale**: Le backend est la source de verite pour les taux. L'inversion serveur garantit la coherence. Le client peut afficher temporairement via `1/rate` en attendant la confirmation serveur.

**Alternatives considered**:
- Inversion client-only : rejete — desynchronisation des taux persistes
- Stocker les deux sens (A->B et B->A) : rejete — redondance, risque d'incoherence

## R4 — Conversion cote client (Flutter & Angular)

**Decision**:
- **Flutter** : Extension `CurrencyConversion` sur `double` ou helper statique dans `utils/currency_converter.dart`. Utilise les taux charges via `exchangeRateProvider`. Appele uniquement dans la presentation layer (widgets).
- **Angular** : Pipe `convertAmount` + service `ConversionService` avec signaux. Le pipe utilise le service pour acceder aux taux.

**Rationale**: La conversion est un concern d'affichage (FR-006). Les montants stockes ne changent jamais. Les deux plateformes suivent leur pattern respectif (Riverpod providers / Angular signals).

**Alternatives considered**:
- Conversion dans les Notifiers/Services : rejete — spec explicite (presentation layer only pour Flutter)
- Backend calcule les montants convertis : rejete — viole FR-006, ajoute latence, couplage

## R5 — Taux a parite fixe pre-remplis

**Decision**: Map statique dans le code (backend + clients). Paire connue :
- `EUR/XOF = 655.957`

Le backend propose cette valeur par defaut lors de l'ajout de XOF. L'utilisateur peut la modifier (FR-019). XAF n'est pas dans l'enum actuel et n'est pas inclus dans le scope de cette feature (YAGNI — voir R6).

**Rationale**: Les parites fixes CFA sont immuables (accord monetaire). Les pre-remplir reduit la friction utilisateur (SC-004 : saisie en < 30s).

**Alternatives considered**:
- API externe de taux : rejete — viole Self-Hosted Ready (principe VII), dependency externe
- Pre-remplir tous les taux : rejete — seules les parites fixes sont fiables sans source externe

## R6 — Scope XAF dans l'enum Currency

**Decision**: Ne pas ajouter XAF a l'enum dans cette feature. La spec mentionne `EUR/XAF` comme parite fixe connue mais XAF n'est pas dans la liste des devises supportees (EUR, USD, XOF, GBP, CHF, CAD, MAD). Si un utilisateur en a besoin, ce sera une future extension de l'enum.

**Rationale**: YAGNI — l'ajout d'une devise impacte tous les selecteurs et l'UX. L'utilisateur cible utilise EUR et XOF. La map de parites fixes peut contenir XAF en reference sans l'exposer dans l'enum.

**Alternatives considered**:
- Ajouter XAF maintenant : rejete — pas de besoin utilisateur immediat, etend le scope

## R7 — Persistance differee du changement de devise principale

**Decision**: Le client (Flutter/Angular) change la devise en memoire immediatement (recalcul instantane). Un debounce de 2s (ou navigation hors dashboard) declenche un seul `PUT /users/me/preferences` avec le nouveau `currencies` order. Le backend appelle `rebaseRates()` si la premiere devise a change.

**Rationale**: UX fluide (SC-002 : < 200ms). Un seul appel API evite le spam reseau. Le backend gere l'inversion des taux de maniere atomique.

**Alternatives considered**:
- Persistance immediate a chaque tap : rejete — spam API si l'utilisateur explore plusieurs devises
- Persistance uniquement a la sortie : rejete — risque de perte si l'app est tuee
