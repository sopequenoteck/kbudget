# Research: Flutter Notifiers Riverpod CRUD

**Feature**: 041-flutter-riverpod-notifiers
**Date**: 2026-02-22

## R1: Pattern Notifier pour gestion de liste CRUD

**Decision**: Utiliser `Notifier<ListState<T>>` avec un etat Freezed generique.

**Rationale**: Le projet utilise deja `Notifier<T>` pour AuthNotifier, OnboardingNotifier, DataSettingsNotifier, ThemeNotifier et ModalNotifier. Ce pattern est coherent, bien teste, et n'introduit aucune nouvelle dependance. L'etat est gere via `state = state.copyWith(...)`.

**Alternatives considered**:
- `AsyncNotifier<T>` : expose `AsyncValue<T>` nativement, mais introduit un pattern different de tout l'existant. Risque d'inconsistance.
- `StateNotifier<T>` : legacy Riverpod, sera deprecie. Le projet n'en utilise aucun.
- `StreamProvider` + `watchAll()` : les repos exposent `Stream<List<T>>` via `watchAll()`, mais ce pattern ne gere pas le CRUD ni les etats de mutation per-item.

## R2: Pagination client-side vs server-side

**Decision**: Pagination client-side — `getAll()` charge toutes les donnees, le notifier decoupe en pages de 20.

**Rationale**: Les 5 repositories abstraits exposent uniquement `getAll()` sans parametre de pagination. Pour une app single-user, les volumes sont gereables en memoire (quelques centaines de transactions max par mois). Le notifier maintient `_allItems` en memoire et expose `items` comme une tranche paginee.

**Alternatives considered**:
- Etendre les repositories avec `getPage(page, size)` : necessite de modifier 10 fichiers (5 interfaces + 5 implementations locales + 5 remotees). Sur-ingenierie pour cette etape.
- Reporter la pagination : possible mais degrade l'UX pour les listes longues (transactions).

## R3: Etat de mutation per-item

**Decision**: `Set<String> mutatingIds` dans ListState.

**Rationale**: Le widget verifie `state.mutatingIds.contains(item.id)` pour afficher un spinner par element. Pattern leger, pas besoin d'envelopper chaque entite dans un wrapper. Les Set Dart sont immutables avec `{...spread}`, compatible avec Freezed.

**Alternatives considered**:
- `Map<String, MutationType>` : plus riche (distingue create/update/delete) mais aucun besoin UX identifie pour cette distinction.
- `ItemState<T>` wrapper : chaque item porte son loading/error. Plus lourd, complexifie la liste.

## R4: Suppression optimiste

**Decision**: Seule la suppression est optimiste. Creation et modification attendent la confirmation.

**Rationale**: La suppression retire un element visible — le rollback est simple (re-inserer a la meme position). La creation necessite l'ID genere par le serveur/base. La modification necessite les donnees validees. L'optimisme sur ces operations risque des inconsistances.

**Implementation pattern**:
1. Sauvegarder l'element et son index
2. Retirer l'element de la liste + ajouter l'ID dans `mutatingIds`
3. Appeler `repository.delete(id)`
4. Succes : retirer l'ID de `mutatingIds`
5. Echec : re-inserer l'element a sa position + afficher erreur + retirer de `mutatingIds`

## R5: Structure des erreurs

**Decision**: `String? error` dans ListState.

**Rationale**: Coherent avec OnboardingState et DataSettingsState qui utilisent `String? error`. Le notifier formate le message en amont, le widget l'affiche tel quel. Pour une app single-user, la distinction par type d'erreur n'apporte pas de valeur UX (l'action utilisateur est toujours "reessayer").

**Alternatives considered**:
- `AppError` classe typee (code, message, type) : extensible mais sur-engineering.
- Enum `ErrorType` + message : deux champs a synchroniser, moins propre.

## R6: Tri par defaut des listes

**Decision**: Tri applique cote notifier apres chargement.

**Rationale**: Les repositories `getAll()` ne garantissent pas d'ordre specifique. Le notifier trie les donnees apres reception :
- **Transactions, Dettes** : date decroissante (`b.date.compareTo(a.date)`)
- **Comptes, Categories, Abonnements** : nom croissant (`a.nom.compareTo(b.nom)`)

## R7: Protection des categories systeme

**Decision**: Le notifier refuse les mutations avant d'appeler le repository.

**Rationale**: Le CategoryNotifier verifie `isSystem == true` avant `update()` et `delete()`. Si vrai, il set `state.error` avec un message explicite sans appeler le repository. La guard est cote notifier (pas cote repository) car c'est une regle UI, pas une regle de persistance.

## R8: Convention de test

**Decision**: Meme pattern que auth_notifier_test.dart.

**Rationale**: Pattern existant bien etabli :
- `ProviderContainer` avec `overrides` pour injecter les mocks
- Helpers `notifier()` et `state()` pour acceder au provider
- Mockito `when/thenAnswer/verify`
- Nommage `should_[resultat]_when_[condition]`
- `setUp`/`tearDown` pour init/dispose du container
