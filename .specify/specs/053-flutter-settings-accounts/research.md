# Research: 053-flutter-settings-accounts

**Date**: 2026-02-23

## R1: Pattern de formulaire pour un écran settings full-screen

**Decision**: Formulaire full-screen via navigation push (pas modal), avec save dans l'AppBar.

**Rationale**: Les formulaires des features principales (transactions, dettes, abonnements) utilisent le pattern modal via `ModalNotifier`. Mais les écrans settings (profil, apparence) utilisent un pattern full-screen avec `Scaffold` + `AppBar` + bouton save dans l'AppBar. Le formulaire de compte, étant une sous-page des réglages, doit suivre le pattern settings.

**Alternatives considered**:
- Modal bottom sheet (pattern transaction/debt) — rejeté car le formulaire compte a plus de champs et nécessite un scroll vertical complet
- Dialog — rejeté car trop petit pour un formulaire complexe

## R2: Extension du repository Account pour adjustBalance

**Decision**: Ajouter `adjustBalance(String id, double newBalance)` au `AccountRepository`, `AccountRepositoryRemote` et `AccountRemoteDataSource`.

**Rationale**: L'API expose `POST /accounts/{id}/adjust-balance` avec body `{ newBalance }`. L'endpoint existe côté backend mais n'est pas encore consommé côté Flutter. Le remote data source a déjà les patterns CRUD + `setDefault` + `transfer`. L'ajout suit le même pattern Dio.

**Alternatives considered**:
- Créer un service séparé pour l'ajustement — rejeté car c'est une opération sur Account, pas un domaine distinct
- Inclure dans le `update()` — rejeté car l'API a un endpoint distinct et le backend crée une transaction d'ajustement

## R3: Routage des écrans compte

**Decision**: Trois routes imbriquées sous `/settings/accounts` :
- `/settings/accounts` → `AccountListScreen` (remplace `StubSettingsScreen`)
- `/settings/accounts/new` → `AccountFormScreen` (création)
- `/settings/accounts/:id` → `AccountFormScreen` (édition, Account passé via `extra`)

**Rationale**: Suit le pattern GoRouter existant (routes imbriquées sous settings). L'Account est passé via `state.extra` pour l'édition (pattern déjà utilisé dans l'app). Les routes nommées suivent la convention existante (`settingsAccountsNewName`, etc.).

**Alternatives considered**:
- Route unique avec paramètre optionnel — rejeté car GoRouter gère mieux les routes distinctes
- Passer l'ID et re-fetcher — rejeté car l'objet est déjà en mémoire dans le notifier

## R4: Palette de couleurs pour le formulaire

**Decision**: Palette fixe de 12 couleurs hexadécimales, identique à celle de l'implémentation Angular.

**Rationale**: Cohérence cross-platform entre PWA et app mobile. Les couleurs sont :
- `#3b82f6` (blue), `#10b981` (green), `#f59e0b` (amber)
- `#ef4444` (red), `#f97316` (orange), `#84cc16` (lime)
- `#22c55e` (green-light), `#06b6d4` (cyan), `#6366f1` (indigo)
- `#8b5cf6` (purple), `#ec4899` (pink), `#6b7280` (gray)

**Alternatives considered**:
- Color picker libre (HSL/RGB) — rejeté car sur-ingénierie pour un usage simple
- Palette étendue (20+ couleurs) — rejeté car 12 suffit et garde la cohérence

## R5: Gestion du save combiné (edit + adjustBalance)

**Decision**: Un seul bouton "Enregistrer" dans le formulaire déclenche séquentiellement :
1. `accountNotifier.update(account)` si des champs ont changé
2. `accountNotifier.adjustBalance(id, newBalance)` si le nouveau solde diffère de l'actuel

**Rationale**: UX mobile — l'utilisateur s'attend à un seul bouton save. Le pattern Angular fait les deux appels séparément mais de manière transparente pour l'utilisateur. Le formulaire Flutter fait pareil.

**Alternatives considered**:
- Deux boutons distincts — rejeté car confusion UX
- Ajustement dans un écran séparé — rejeté car ajoute un écran inutile

## R6: Mode data pour les comptes

**Decision**: Mode serveur uniquement (API REST via Dio). Pas de fallback local (Drift).

**Rationale**: La spec assume que les données comptes doivent toujours être fraîches depuis l'API. Le profil settings utilise déjà ce pattern (pas de Drift). L'AccountRepositoryRemote existe déjà et sera utilisé directement.

**Alternatives considered**:
- Strategy pattern local/remote (comme transactions) — rejeté car les comptes sont des données de configuration, pas des données transactionnelles. Pas de besoin offline.
