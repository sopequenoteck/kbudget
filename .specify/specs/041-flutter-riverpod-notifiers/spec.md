# Feature Specification: Flutter Notifiers Riverpod CRUD

> **Pattern retenu** : `Notifier<ListState<T>>` (Riverpod 2.x), cohérent avec les notifiers existants du projet. Pas de `StateNotifier` (legacy) ni `AsyncNotifier`.

**Feature Branch**: `041-flutter-riverpod-notifiers`
**Created**: 2026-02-22
**Status**: Draft
**Input**: User description: "KKS-115 — Flutter: Notifiers Riverpod CRUD - Créer les StateNotifiers pour transactions, subscriptions, debts, accounts, categories. Chaque notifier: liste paginée, CRUD, loading/error states. Brancher sur les repositories local/remote existants."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter une liste d'entités avec retour visuel (Priority: P1)

L'utilisateur ouvre un écran (transactions, abonnements, dettes, comptes ou catégories). Il voit immédiatement un indicateur de chargement, puis la liste de ses données apparaît. Si aucune donnée n'existe, un état vide est affiché. Si une erreur survient (réseau, base locale corrompue), un message d'erreur clair s'affiche avec une option pour réessayer.

**Why this priority**: Sans affichage fiable des listes avec gestion des états (chargement, erreur, vide), aucun écran de l'application ne peut fonctionner. C'est le socle de toute interaction utilisateur.

**Independent Test**: Peut être testé en ouvrant n'importe quel écran de liste et en vérifiant la séquence : chargement → données (ou vide/erreur).

**Acceptance Scenarios**:

1. **Given** l'utilisateur ouvre l'écran des transactions, **When** les données sont en cours de récupération, **Then** un indicateur de chargement est visible
2. **Given** les données sont chargées avec succès, **When** l'affichage se met à jour, **Then** la liste des éléments est affichée
3. **Given** aucune donnée n'existe pour l'utilisateur, **When** le chargement est terminé, **Then** un état vide est affiché
4. **Given** une erreur survient lors du chargement, **When** l'affichage se met à jour, **Then** un message d'erreur est affiché avec un bouton "Réessayer"
5. **Given** l'utilisateur appuie sur "Réessayer", **When** l'action est déclenchée, **Then** le chargement redémarre

---

### User Story 2 - Créer un élément et voir la liste se mettre à jour (Priority: P1)

L'utilisateur remplit un formulaire de création (transaction, abonnement, dette, compte ou catégorie) et valide. L'élément est créé et la liste se met à jour automatiquement pour refléter l'ajout, sans rechargement manuel de l'écran.

**Why this priority**: La création est l'action fondamentale de l'application (saisir une dépense, ajouter un compte). Sans mise à jour réactive de la liste, l'expérience est dégradée.

**Independent Test**: Créer un élément via le formulaire et vérifier qu'il apparaît dans la liste sans navigation supplémentaire.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur le formulaire de création, **When** il valide les données, **Then** un indicateur d'opération en cours est affiché
2. **Given** la création réussit, **When** la réponse est reçue, **Then** le nouvel élément apparaît dans la liste et le formulaire se ferme
3. **Given** la création échoue (erreur réseau, validation serveur), **When** l'erreur est reçue, **Then** un message d'erreur est affiché et le formulaire reste ouvert avec les données saisies

---

### User Story 3 - Modifier un élément existant (Priority: P1)

L'utilisateur sélectionne un élément dans la liste, modifie ses informations dans le formulaire d'édition, et valide. L'élément est mis à jour et la liste reflète les changements immédiatement.

**Why this priority**: La modification est une opération quotidienne (corriger un montant, changer une catégorie). Elle doit être fluide et fiable.

**Independent Test**: Modifier un champ d'un élément existant et vérifier que la liste affiche les nouvelles valeurs.

**Acceptance Scenarios**:

1. **Given** l'utilisateur modifie un élément, **When** il valide, **Then** un indicateur d'opération en cours est affiché
2. **Given** la modification réussit, **When** la réponse est reçue, **Then** l'élément mis à jour apparaît dans la liste avec les nouvelles valeurs
3. **Given** la modification échoue, **When** l'erreur est reçue, **Then** un message d'erreur est affiché et les anciennes valeurs sont conservées dans la liste

---

### User Story 4 - Supprimer un élément (Priority: P2)

L'utilisateur supprime un élément. L'élément disparaît de la liste immédiatement. Si la suppression échoue, l'élément réapparaît avec un message d'erreur.

**Why this priority**: La suppression est moins fréquente que la création/modification mais reste nécessaire pour la gestion courante.

**Independent Test**: Supprimer un élément et vérifier qu'il n'apparaît plus dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur supprime un élément, **When** l'action est confirmée, **Then** l'élément disparaît de la liste (suppression optimiste)
2. **Given** la suppression réussit côté serveur/base, **When** la confirmation est reçue, **Then** l'élément reste supprimé
3. **Given** la suppression échoue, **When** l'erreur est reçue, **Then** l'élément réapparaît dans la liste et un message d'erreur est affiché

---

### User Story 5 - Charger des données par lots (pagination) (Priority: P2)

L'utilisateur fait défiler une longue liste (ex. transactions sur plusieurs mois). Lorsqu'il atteint la fin de la liste visible, les éléments suivants se chargent automatiquement. Un indicateur de chargement apparaît en bas de liste pendant le chargement.

**Why this priority**: La pagination est essentielle pour les performances avec de grands volumes de données, mais l'application peut fonctionner sans (chargement complet) dans un premier temps.

**Independent Test**: Créer plus d'éléments que la taille d'une page, faire défiler la liste et vérifier que les éléments suivants se chargent.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a plus d'éléments que la taille d'une page, **When** il fait défiler jusqu'en bas, **Then** les éléments suivants se chargent automatiquement
2. **Given** le chargement de la page suivante est en cours, **When** l'utilisateur voit la liste, **Then** un indicateur de chargement est visible en bas de liste
3. **Given** il n'y a plus d'éléments à charger, **When** l'utilisateur atteint la fin, **Then** aucun chargement supplémentaire n'est déclenché

---

### User Story 6 - Actions spécifiques par entité (Priority: P3)

Certaines entités ont des actions spécifiques : définir un compte comme compte par défaut, marquer une dette comme remboursée, activer/désactiver un abonnement. Ces actions sont disponibles et mettent à jour la liste en temps réel.

**Why this priority**: Ce sont des actions secondaires qui enrichissent l'expérience mais ne sont pas bloquantes pour les écrans de base.

**Independent Test**: Exécuter une action spécifique (ex. marquer un compte comme défaut) et vérifier que l'état est mis à jour dans la liste.

**Acceptance Scenarios**:

1. **Given** l'utilisateur définit un compte comme compte par défaut, **When** l'action réussit, **Then** ce compte est marqué comme défaut et l'ancien compte par défaut est mis à jour
2. **Given** l'utilisateur marque une dette comme remboursée, **When** l'action réussit, **Then** le statut de la dette passe à "remboursé" dans la liste
3. **Given** l'utilisateur désactive un abonnement, **When** l'action réussit, **Then** l'abonnement apparaît comme inactif dans la liste

---

### Edge Cases

- Que se passe-t-il quand l'utilisateur crée un élément alors que la liste n'a jamais été chargée (premier lancement) ?
- Comment le système réagit-il quand le mode de données change (local → serveur) alors qu'une opération est en cours ?
- Que se passe-t-il quand l'utilisateur tente de supprimer un élément qui a déjà été supprimé (double-tap, conflit) ?
- Comment gérer une erreur réseau intermittente pendant la pagination (page 1 ok, page 2 échoue) ?
- Que se passe-t-il quand la base locale est vide et le serveur inaccessible ?
- Comment gérer les conflits de mise à jour (l'élément a été modifié entre le chargement et la sauvegarde) ?
- Que se passe-t-il quand l'utilisateur tente de modifier ou supprimer une catégorie système ? Le notifier refuse l'opération et retourne une erreur explicite sans appeler le repository.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT fournir un notifier par entité (transactions, abonnements, dettes, comptes, catégories) exposant l'état courant de la liste (chargement, données, erreur, vide)
- **FR-002**: Chaque notifier DOIT supporter les opérations CRUD : création, lecture (liste paginée), modification, suppression. Le détail d'un élément est accessible via `state.items` sans méthode dédiée
- **FR-003**: Chaque notifier DOIT gérer trois états distincts : chargement en cours, données disponibles, erreur
- **FR-004**: La liste DOIT se mettre à jour automatiquement après chaque opération CRUD réussie, sans intervention de l'utilisateur
- **FR-005**: Les erreurs d'opération CRUD DOIVENT être remontées avec un message exploitable par l'interface utilisateur
- **FR-006**: Chaque notifier DOIT supporter la pagination (chargement par lots) pour les listes volumineuses
- **FR-007**: Les notifiers DOIVENT fonctionner de manière identique quel que soit le mode de données actif (local ou serveur), en s'appuyant sur les repositories existants
- **FR-008**: La suppression DOIT être optimiste : l'élément disparaît immédiatement de la liste et réapparaît en cas d'échec. La création et la modification ne sont PAS optimistes : elles attendent la confirmation avant de mettre à jour la liste
- **FR-009**: Le notifier des comptes DOIT supporter l'action "définir comme compte par défaut"
- **FR-010**: Le notifier des dettes DOIT supporter l'action "marquer comme remboursé"
- **FR-011**: Le notifier des abonnements DOIT supporter l'action "activer/désactiver"
- **FR-012**: Les opérations de modification et suppression DOIVENT indiquer un état "en cours" **par élément** via `mutatingIds` : chaque élément porte son propre état de mutation, les autres éléments restent interactifs. La création utilise `isLoading` global car l'élément n'existe pas encore dans la liste
- **FR-013**: Le rechargement de la liste DOIT être possible via une action explicite (pull-to-refresh ou bouton réessayer)
- **FR-014**: Chaque notifier DOIT appliquer un tri par défaut adapté à l'entité : transactions et dettes par date décroissante (plus récent en premier), comptes, catégories et abonnements par nom croissant (ordre alphabétique)
- **FR-015**: Le notifier des catégories DOIT refuser les opérations de modification et suppression sur les catégories système (`isSystem = true`) et retourner une erreur explicite

### Key Entities

- **Transaction** : Opération financière (dépense ou recette) avec montant, libellé, date, catégorie optionnelle, compte optionnel. Peut être liée à un virement (transferId).
- **Account** : Compte bancaire ou portefeuille avec nom, type (courant/épargne/espèces), solde initial, devise, statut actif/inactif, et possibilité d'être le compte par défaut.
- **Category** : Classement des opérations avec nom, icône (emoji), couleur. Certaines catégories sont système (non modifiables par l'utilisateur).
- **Subscription** : Charge récurrente avec nom, montant, fréquence (mensuelle/annuelle), date de début, statut actif/inactif, compte et catégorie optionnels.
- **Debt** : Somme due ou prêtée à une personne, avec montant, date, type (emprunt/prêt), statut remboursé ou non, catégorie optionnelle.
- **ListState** : État générique d'une liste paginée contenant : les éléments chargés (`items`), l'indicateur de chargement (`isLoading`), l'erreur éventuelle (`error`), la page courante (`currentPage`), l'indicateur de fin de liste (`hasMore`), et un `Set<String> mutatingIds` des IDs d'éléments en cours de mutation — utilisé pour update et delete (le widget vérifie `mutatingIds.contains(item.id)` pour afficher un indicateur par élément). La création utilise `isLoading` car l'élément n'est pas encore dans la liste.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur voit un indicateur de chargement en moins d'une seconde après l'ouverture d'un écran de liste
- **SC-002**: Après une opération CRUD, la liste se met à jour visuellement en moins de 500ms (hors latence réseau)
- **SC-003**: 100% des opérations CRUD échouées affichent un message d'erreur compréhensible à l'utilisateur
- **SC-004**: Les 5 entités (transactions, comptes, catégories, abonnements, dettes) disposent chacune d'un notifier fonctionnel avec les mêmes capacités
- **SC-005**: La pagination charge les éléments suivants sans blocage de l'interface utilisateur
- **SC-006**: Le basculement entre mode local et serveur ne nécessite aucune modification des notifiers — les mêmes notifiers fonctionnent dans les deux modes

## Clarifications

### Session 2026-02-22

- Q: L'état de mutation est-il global par notifier ou par élément ? → A: Par élément — chaque élément porte son propre état de mutation, les autres restent interactifs.
- Q: Quel est le tri par défaut des listes ? → A: Par pertinence temporelle — transactions et dettes par date décroissante, comptes/catégories/abonnements par nom croissant.
- Q: Les notifiers doivent-ils protéger les catégories système contre la modification/suppression ? → A: Oui — le notifier refuse les mutations sur les catégories système et retourne une erreur explicite.
- Q: Quel type de Notifier Riverpod utiliser (StateNotifier legacy, Notifier, ou AsyncNotifier) ? → A: Notifier<ListState<T>> — cohérent avec le pattern existant (AuthNotifier, OnboardingNotifier, etc.), état custom Freezed.
- Q: Quelle stratégie de pagination adopter vu que les repositories n'ont que getAll() ? → A: Pagination client-side — getAll() charge tout, le notifier découpe en pages de 20 pour l'affichage progressif.
- Q: Les créations et modifications sont-elles aussi optimistes comme la suppression (FR-008) ? → A: Non — seule la suppression est optimiste. Création et modification attendent la confirmation avant de mettre à jour la liste.
- Q: Comment modéliser l'état de mutation par élément (FR-012) dans ListState ? → A: Set<String> mutatingIds — le widget vérifie mutatingIds.contains(item.id) pour afficher un indicateur par élément.
- Q: Comment structurer les erreurs remontées par les notifiers (FR-005) ? → A: String? error dans ListState — simple, cohérent avec l'existant (OnboardingState, DataSettingsState). Le notifier formate le message, le widget l'affiche tel quel.

## Assumptions

- Les repositories abstraits et leurs implémentations (local et remote) existent déjà et sont fonctionnels.
- Les providers Riverpod pour les repositories existent déjà et gèrent le basculement local/serveur.
- La taille de page par défaut pour la pagination est de 20 éléments (standard mobile).
- Les repositories actuels utilisent `getAll()` sans paramètre de pagination — la pagination est gérée côté notifier : `getAll()` charge toutes les données, le notifier les découpe en pages de 20 pour un affichage progressif (scroll infini client-side).
- Le pattern de notifier existant (AuthNotifier, OnboardingNotifier, ThemeNotifier) sert de référence pour la structure et les conventions.
- Les modèles Freezed existants sont utilisés tels quels — aucune modification de modèle n'est requise.

## Out of Scope

- Synchronisation bidirectionnelle entre mode local et serveur (offline-first avec sync)
- Cache intelligent ou invalidation de cache
- Recherche et filtrage avancés dans les notifiers (sera géré par les écrans)
- Notifications push ou mise à jour en temps réel depuis le serveur
- Gestion des conflits multi-utilisateur (application single-user)
