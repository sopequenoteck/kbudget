# Research: Flutter Dashboard Complet

**Date**: 2026-02-22 | **Feature**: 042-flutter-dashboard

## R-001: Appel API Monthly Summary depuis Flutter

**Decision**: Ajouter une methode `getMonthlySummary(int month, int year)` dans `TransactionRemoteDataSource` et un DTO `MonthlySummaryResponse` Freezed.

**Rationale**: L'endpoint `GET /transactions/summary?month=X&year=Y` existe cote backend et retourne une `List<MonthlySummaryResponse>` groupee par devise. Le pattern data source → DTO → repository → domain model est deja en place pour les CRUD transactions. On l'etend avec une methode read-only supplementaire.

**Alternatives considered**:
- Calcul local depuis les transactions Drift : rejete car le backend fait deja l'agregation multi-devises avec gestion des ajustements.
- Provider Riverpod standalone avec `FutureProvider.family` : rejete car le pattern projet utilise des `Notifier` classes.

**Implementation**:
- DTO: `MonthlySummaryResponse` (month, year, totalRecettes, totalDepenses, solde, currency)
- Domain model: `MonthlySummary` (Freezed, memes champs mais types Dart — `double`, `Currency` enum)
- Data source: `TransactionRemoteDataSource.getMonthlySummary(int month, int year)`
- Pour le mode local (Drift): calcul via query SQL sur la table transactions locales (SUM groupé par type)

## R-002: Acces au nom de l'utilisateur (message de bienvenue)

**Decision**: Persister le `name` de l'utilisateur dans `FlutterSecureStorage` au login (cle `user_name`), expose via un provider dedie `currentUserNameProvider`.

**Rationale**: `AuthState.authenticated` ne porte aucune info utilisateur. Le JWT ne contient PAS de claim `name` (uniquement `sub`=email, `iat`, `exp`). Le `name` est retourne dans `AuthResponse` au login mais n'est actuellement pas persiste. La solution la plus simple est de le stocker dans `FlutterSecureStorage` aux cotes des tokens existants.

**Alternatives considered**:
- Decoder le claim `name` du JWT : **INVALIDE** — le JWT ne contient pas ce claim (verifie dans `JwtUtil.java`).
- Ajouter un champ `User` a `AuthAuthenticated` : rejete car necessite de modifier `AuthState` et toute la logique auth. Trop invasif.
- Endpoint `/auth/me` : rejete car le `name` est deja dans `AuthResponse`. Appel reseau inutile.
- Ajouter le claim `name` au JWT backend : rejete car modification backend hors scope de cette feature frontend.

**Implementation**:
- Modifier `AuthRepositoryImpl.saveTokens()` pour accepter et persister aussi le `name` (cle `user_name` dans `FlutterSecureStorage`).
- Provider `currentUserNameProvider` (FutureProvider<String?>) qui lit `user_name` depuis `FlutterSecureStorage`.
- Fallback : `null` en mode local ou si cle absente → message generique "Bonjour".

## R-003: Calcul du montant mensuel normalise des abonnements

**Decision**: Calcul client-side dans le `DashboardNotifier` a partir des abonnements charges via `subscriptionNotifierProvider`.

**Rationale**: Les abonnements sont deja charges en memoire par le notifier existant. Le calcul est trivial : `montant` pour `Frequency.mensuel`, `montant / 12` pour `Frequency.annuel`. Filtrer `actif == true`.

**Alternatives considered**:
- Endpoint API dedie : rejete (YAGNI — calcul simple client-side).

## R-004: Calcul du solde net des dettes

**Decision**: Calcul client-side dans le `DashboardNotifier` a partir des dettes chargees via `debtNotifierProvider`.

**Rationale**: Les dettes sont deja en memoire. Solde net = `SUM(montant WHERE sens == pret AND !rembourse) - SUM(montant WHERE sens == emprunt AND !rembourse)`. Nombre = count des dettes non remboursees.

**Alternatives considered**:
- Endpoint API dedie : rejete (YAGNI — calcul simple client-side).

## R-005: Dates relatives

**Decision**: Utiliser `RelativeDateFormatter.format()` existant dans `lib/src/utils/relative_date_formatter.dart`.

**Rationale**: L'utilitaire est deja implemente avec les regles : Aujourd'hui, Hier, il y a Xj, il y a X semaine(s), puis format long. Exactement ce dont le dashboard a besoin.

**Alternatives considered**: Aucune — l'utilitaire existe deja.

## R-006: Formatage des montants

**Decision**: Utiliser `AmountFormatter.format()` existant dans `lib/src/utils/amount_formatter.dart`.

**Rationale**: Gere deja le formatage avec devise (Currency enum), signe +/-, et locale fr_FR.

## R-007: Monthly Summary en mode local (Drift)

**Decision**: Creer une methode dans `TransactionDao` qui calcule l'agregation SQL localement (SUM par type, group by currency) pour le mois/annee donne.

**Rationale**: Le dashboard doit fonctionner en mode local (Drift) ET en mode serveur (API). En mode serveur, on utilise `GET /transactions/summary`. En mode local, on fait la meme agregation via une query Drift. Le `dataModeProvider` switchera automatiquement.

**Implementation**:
- `TransactionDao.getMonthlySummary(int month, int year)` → query Drift
- `TransactionRepositoryLocal` mappe le resultat en `MonthlySummary`
- Le provider dans `data_mode_provider.dart` switche entre local et remote
