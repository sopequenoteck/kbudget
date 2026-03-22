# Feature Specification: Feature Toggles Angular

**Feature Branch**: `064-angular-feature-toggles`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "KKS-150 — Feature toggles Angular (activation/désactivation des modules)"
**Linear**: KKS-150

## Clarifications

### Session 2026-03-01

- Q: Que se passe-t-il quand l'utilisateur active le toggle Boutique alors que le module n'est pas encore implémenté côté Angular ? → A: Les 3 toggles sont affichés normalement. Le lien Boutique dans la sidebar mène à une page placeholder "Coming soon".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Activer/désactiver des modules (Priority: P1)

L'utilisateur accède à l'écran Settings > Fonctionnalités pour voir la liste des modules optionnels (Abonnements, Dettes, Boutique). Chaque module dispose d'un toggle on/off. L'utilisateur active ou désactive un module ; le changement est immédiatement reflété dans la navigation latérale (sidebar) et persiste sur le serveur.

**Why this priority**: C'est la fonctionnalité centrale — sans elle, les toggles n'existent pas. Elle délivre la valeur principale : personnaliser quels modules sont visibles dans l'application.

**Independent Test**: Peut être testé en accédant à Settings > Fonctionnalités, en toggleant un module, puis en vérifiant que la sidebar reflète le changement et que l'API est appelée.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Fonctionnalités, **When** il désactive le module "Abonnements", **Then** le lien "Abonnements" disparaît de la sidebar et l'API `PUT /users/me/preferences` est appelée avec la liste mise à jour.
2. **Given** l'utilisateur a désactivé le module "Dettes", **When** il le réactive, **Then** le lien "Dettes" réapparaît dans la sidebar à sa position dans l'ordre de navigation.
3. **Given** l'utilisateur est sur la page d'un module qu'il vient de désactiver, **When** le toggle est désactivé, **Then** il est redirigé vers le Dashboard.
4. **Given** l'utilisateur se reconnecte après avoir désactivé des modules, **When** l'application charge, **Then** l'état des features est restauré depuis le serveur et la sidebar reflète les modules activés.

---

### User Story 2 - Navigation dynamique selon les features activées (Priority: P1)

La sidebar de l'application affiche uniquement les modules activés par l'utilisateur. Les liens "Accueil" et "Transactions" sont toujours présents (non désactivables). Les modules optionnels apparaissent dans la sidebar selon leur statut d'activation et dans l'ordre défini par l'utilisateur.

**Why this priority**: Même priorité que US1 car la navigation est le reflet direct des toggles — sans navigation dynamique, les toggles n'ont aucun effet visible.

**Independent Test**: Peut être testé en modifiant les features activées via l'API directement, puis en rechargeant l'app et en vérifiant que seuls les modules activés apparaissent dans la sidebar.

**Acceptance Scenarios**:

1. **Given** seuls "Abonnements" et "Boutique" sont activés, **When** l'utilisateur ouvre la sidebar, **Then** elle affiche : Accueil, Transactions, Abonnements, Boutique (dans cet ordre).
2. **Given** aucun module optionnel n'est activé, **When** l'utilisateur ouvre la sidebar, **Then** elle affiche uniquement Accueil et Transactions.
3. **Given** l'utilisateur navigue vers `/subscriptions` via URL directe et le module est désactivé, **When** la page tente de charger, **Then** l'utilisateur est redirigé vers le Dashboard.

---

### User Story 3 - Réordonner la navigation (Priority: P2)

L'utilisateur peut réordonner les modules optionnels dans la section navigation de l'écran Fonctionnalités. L'ordre choisi est reflété dans la sidebar et persiste sur le serveur.

**Why this priority**: Fonctionnalité secondaire qui améliore la personnalisation mais n'est pas indispensable au fonctionnement des toggles.

**Independent Test**: Peut être testé en glissant-déposant des modules dans l'écran Fonctionnalités, puis en vérifiant l'ordre dans la sidebar.

**Acceptance Scenarios**:

1. **Given** Abonnements, Dettes et Boutique sont tous activés, **When** l'utilisateur place Boutique en première position, **Then** la sidebar affiche : Accueil, Transactions, Boutique, Abonnements, Dettes.
2. **Given** l'utilisateur réordonne les modules, **When** il se reconnecte plus tard, **Then** l'ordre est conservé (persisté via l'API).
3. **Given** l'utilisateur désactive un module qui était en première position des optionnels, **When** il le réactive plus tard, **Then** le module reprend sa place selon l'ordre de navigation enregistré.

---

### User Story 4 - Protection des données à la désactivation (Priority: P3)

Lorsque l'utilisateur tente de désactiver un module pour lequel des données existent (ex. des abonnements), un dialogue de confirmation l'informe que les données ne seront pas supprimées mais simplement masquées.

**Why this priority**: Améliore l'UX en rassurant l'utilisateur, mais ne bloque pas le fonctionnement des toggles.

**Independent Test**: Peut être testé en ayant des abonnements existants, puis en tentant de désactiver le module Abonnements et en vérifiant l'apparition du dialogue.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des abonnements existants, **When** il tente de désactiver le module Abonnements, **Then** un dialogue de confirmation apparaît expliquant que les données seront masquées mais pas supprimées.
2. **Given** le dialogue de confirmation est affiché, **When** l'utilisateur confirme, **Then** le module est désactivé.
3. **Given** le dialogue de confirmation est affiché, **When** l'utilisateur annule, **Then** le module reste activé.
4. **Given** le module n'a aucune donnée existante, **When** l'utilisateur le désactive, **Then** aucun dialogue n'apparaît et le module est désactivé directement.

---

### Edge Cases

- Que se passe-t-il si l'API échoue lors de la sauvegarde des préférences ? L'état local est mis à jour de manière optimiste ; en cas d'erreur serveur, un message d'erreur est affiché mais l'état local peut diverger jusqu'au prochain chargement.
- Que se passe-t-il si l'utilisateur accède directement via URL à un module désactivé ? Il est redirigé vers le Dashboard.
- Que se passe-t-il si le FAB (bouton flottant) propose des actions liées à un module désactivé ? Les actions du FAB pour les modules désactivés ne doivent pas apparaître (ex. "Nouvel abonnement" masqué si Abonnements désactivé).
- Que se passe-t-il au premier chargement (aucune préférence existante) ? L'API crée automatiquement les préférences par défaut (les 3 features activées : Abonnements, Dettes, Boutique).
- Que se passe-t-il si l'utilisateur active le module Boutique (non encore implémenté) ? Le lien apparaît dans la sidebar et mène à une page placeholder "Coming soon" ; les données du toggle sont persistées normalement via l'API (synchro Flutter).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT fournir un service Angular pour communiquer avec l'API de préférences (`GET/PUT /users/me/preferences`).
- **FR-002**: Le système DOIT maintenir un état réactif (signal) des features activées et de l'ordre de navigation, partagé dans toute l'application.
- **FR-003**: Le système DOIT afficher un écran Settings > Fonctionnalités listant les 3 modules optionnels (Abonnements, Dettes, Boutique) avec un toggle pour chacun.
- **FR-004**: Le système DOIT afficher une section de réordonnancement des modules activés dans l'écran Fonctionnalités, avec glisser-déposer.
- **FR-005**: La sidebar DOIT afficher dynamiquement les liens de navigation selon les features activées et leur ordre.
- **FR-006**: Les liens "Accueil" et "Transactions" DOIVENT toujours être présents dans la sidebar (non désactivables).
- **FR-007**: Le système DOIT empêcher l'accès aux routes de modules désactivés et rediriger vers le Dashboard.
- **FR-008**: Le système DOIT charger les préférences depuis le serveur au démarrage de l'application (après authentification).
- **FR-009**: Le système DOIT sauvegarder les modifications de préférences sur le serveur de manière optimiste (mise à jour locale immédiate, sync serveur en arrière-plan).
- **FR-010**: Le système DOIT afficher un dialogue de confirmation avant de désactiver un module contenant des données existantes.
- **FR-011**: Le FAB DOIT masquer les actions associées aux modules désactivés (ex. "Nouvel abonnement" caché si Abonnements désactivé).
- **FR-012**: Le système DOIT afficher une page placeholder "Coming soon" pour le module Boutique (route `/shop`) tant que le module n'est pas implémenté, accessible uniquement si le toggle Boutique est activé.

### Key Entities

- **Feature**: Module optionnel de l'application — 3 valeurs possibles : Abonnements (SUBSCRIPTIONS), Dettes (DEBTS), Boutique (SHOP). Chaque feature porte un label, une icône et un état activé/désactivé.
- **UserPreference**: Préférences de l'utilisateur — contient la liste des features activées, l'ordre de navigation, le compte boutique et le flag d'inclusion boutique dans le solde.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut activer/désactiver chaque module optionnel en moins de 2 interactions (accès settings + toggle).
- **SC-002**: Le changement de toggle est reflété dans la sidebar en moins d'1 seconde (mise à jour optimiste).
- **SC-003**: Après reconnexion, l'état des features est restauré fidèlement depuis le serveur — 100% de cohérence entre l'état sauvegardé et l'état affiché.
- **SC-004**: Un utilisateur qui accède à une URL de module désactivé est toujours redirigé vers le Dashboard — aucun état orphelin visible.
- **SC-005**: Le réordonnancement des modules dans la sidebar est fidèlement reflété après reconnexion.
- **SC-006**: La parité fonctionnelle avec l'implémentation Flutter est atteinte pour les features activées/désactivées et l'ordre de navigation.

## Assumptions

- L'API backend `GET/PUT /users/me/preferences` est déjà implémentée et fonctionnelle (KKS-120).
- Le Feature enum backend contient 3 valeurs : `SUBSCRIPTIONS`, `DEBTS`, `SHOP`.
- Les préférences par défaut (créées automatiquement par le backend) activent les 3 features : Abonnements, Dettes et Boutique.
- Angular est en mode **server-only** pour les préférences (pas de stockage local — toujours depuis l'API).
- Le module Boutique Angular n'est pas encore implémenté ; le toggle est affiché normalement et le lien sidebar mène à une page placeholder "Coming soon". La préférence est persistée via l'API (synchro cross-platform avec Flutter).
- La sidebar est le seul point de navigation à conditionner (pas de bottom nav dans Angular, contrairement à Flutter).

## Dependencies

- Backend KKS-120 (API préférences) — **déjà implémenté**.
- Flutter KKS-120 (référence fonctionnelle) — **déjà implémenté**.
- Les routes `/subscriptions`, `/debts` existent déjà dans le routeur Angular.
