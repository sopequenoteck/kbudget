# Feature Specification: Page Fonctionnalités (Feature Toggles) — Flutter

**Feature Branch**: `058-flutter-settings-features`
**Created**: 2026-02-28
**Status**: Draft
**Input**: User description: "KKS-120 — Flutter: Settings — Page Fonctionnalités (feature toggles)"
**Linear**: [KKS-120](https://linear.app/kksdev/issue/KKS-120/flutter-settings-page-fonctionnalites-feature-toggles)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Activer/désactiver des fonctionnalités optionnelles (Priority: P1)

En tant qu'utilisateur, je veux pouvoir activer ou désactiver les fonctionnalités optionnelles (Abonnements, Dettes, Boutique) depuis une page dédiée dans les paramètres, afin de simplifier mon application en n'affichant que ce dont j'ai besoin.

**Why this priority**: C'est la fonctionnalité cœur — sans les toggles, la personnalisation modulaire n'existe pas. La page doit exister et les toggles doivent fonctionner.

**Independent Test**: Peut être testé en ouvrant la page Fonctionnalités depuis les paramètres, en basculant un toggle, et en vérifiant que l'état du toggle est persisté et reflété visuellement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur le hub des paramètres, **When** il appuie sur la section "Fonctionnalités", **Then** la page Fonctionnalités s'affiche avec la liste des 3 fonctionnalités optionnelles, chacune avec une icône, un libellé, une description courte et un switch.
2. **Given** toutes les fonctionnalités sont activées, **When** l'utilisateur désactive "Dettes", **Then** le switch "Dettes" passe à OFF et l'état est sauvegardé immédiatement.
3. **Given** "Abonnements" est désactivé, **When** l'utilisateur réactive "Abonnements", **Then** le switch passe à ON et l'état est sauvegardé immédiatement.
4. **Given** l'utilisateur a désactivé une fonctionnalité, **When** il quitte et revient sur la page Fonctionnalités, **Then** l'état des toggles est restauré fidèlement.

---

### User Story 2 - Impact immédiat sur la barre de navigation (Priority: P1)

En tant qu'utilisateur, je veux que la barre de navigation reflète immédiatement mes choix de fonctionnalités, afin de ne voir que les onglets des fonctionnalités que j'ai activées.

**Why this priority**: L'impact visuel immédiat est indissociable du toggle — sans lui, l'utilisateur ne comprend pas l'effet de son action. C'est le feedback essentiel.

**Independent Test**: Peut être testé en désactivant une fonctionnalité et en vérifiant que l'onglet correspondant disparaît de la barre de navigation sans redémarrage ni rechargement.

**Acceptance Scenarios**:

1. **Given** toutes les fonctionnalités sont activées (4 onglets : Accueil, Transactions, Abonnements, Dettes), **When** l'utilisateur désactive "Abonnements", **Then** la barre de navigation n'affiche plus que 3 onglets (Accueil, Transactions, Dettes) immédiatement.
2. **Given** "Dettes" et "Abonnements" sont désactivés (2 onglets : Accueil, Transactions), **When** l'utilisateur réactive "Dettes", **Then** la barre de navigation affiche 3 onglets (Accueil, Transactions, Dettes).
3. **Given** l'utilisateur est sur l'onglet "Abonnements", **When** il désactive "Abonnements" depuis les paramètres, **Then** la navigation le redirige vers un onglet valide (ex : Accueil) et l'onglet "Abonnements" disparaît.
4. **Given** la fonctionnalité "Boutique" est activée, **When** l'utilisateur consulte la barre de navigation, **Then** un onglet "Boutique" apparaît avec l'icône storefront.
5. **Given** le noyau permanent (Dashboard et Transactions), **When** l'utilisateur désactive toutes les fonctionnalités optionnelles, **Then** seuls les 2 onglets du noyau permanent restent dans la barre de navigation.

---

### User Story 3 - Persistance locale et synchronisation serveur (Priority: P2)

En tant qu'utilisateur, je veux que mes préférences de fonctionnalités soient sauvegardées localement et synchronisées avec le serveur (si connecté), afin de retrouver ma configuration sur tous mes appareils.

**Why this priority**: La persistance garantit la cohérence entre sessions. La synchronisation serveur est un enrichissement qui dépend de la configuration de données (mode local vs serveur).

**Independent Test**: Peut être testé en modifiant un toggle, en fermant et rouvrant l'application, et en vérifiant que l'état est restauré. En mode serveur, vérifier également que le serveur reçoit la mise à jour.

**Acceptance Scenarios**:

1. **Given** l'utilisateur modifie un toggle en mode local, **When** il ferme et rouvre l'application, **Then** l'état des toggles est restauré depuis le stockage local.
2. **Given** l'utilisateur est en mode serveur et modifie un toggle, **When** la modification est sauvegardée, **Then** le système envoie la mise à jour au serveur et persiste localement.
3. **Given** l'utilisateur est en mode serveur, **When** il ouvre la page Fonctionnalités, **Then** les préférences sont chargées depuis le serveur pour garantir la fraîcheur.

---

### User Story 4 - Confirmation avant désactivation avec données (Priority: P3)

En tant qu'utilisateur, je veux être averti avant de désactiver une fonctionnalité qui contient des données existantes, afin d'éviter toute confusion sur le devenir de mes données.

**Why this priority**: C'est une mesure de sécurité UX qui rassure l'utilisateur. Les données ne sont jamais supprimées, mais l'utilisateur doit le savoir.

**Independent Test**: Peut être testé en ayant des données existantes (ex : abonnements créés) et en tentant de désactiver la fonctionnalité correspondante — un dialogue de confirmation doit apparaître.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a des abonnements enregistrés, **When** il désactive "Abonnements", **Then** un dialogue de confirmation apparaît expliquant que les données existantes seront masquées mais pas supprimées.
2. **Given** le dialogue de confirmation est affiché, **When** l'utilisateur confirme, **Then** la fonctionnalité est désactivée.
3. **Given** le dialogue de confirmation est affiché, **When** l'utilisateur annule, **Then** la fonctionnalité reste activée et le toggle ne change pas.
4. **Given** l'utilisateur n'a aucune donnée pour "Boutique", **When** il désactive "Boutique", **Then** aucun dialogue de confirmation n'apparaît et le toggle se désactive directement.

---

### Edge Cases

- Que se passe-t-il si la synchronisation serveur échoue ? Le toggle reste dans l'état choisi par l'utilisateur (optimiste), un snackbar informe de l'échec de synchronisation, et une resynchronisation est effectuée au prochain chargement de la page.
- Que se passe-t-il si l'utilisateur est en mode local (hors-ligne) ? Les toggles fonctionnent normalement avec la persistance locale uniquement, sans appel serveur.
- Que se passe-t-il au premier lancement de l'application (aucune préférence) ? Les fonctionnalités Abonnements et Dettes sont activées par défaut, Boutique est désactivé par défaut.
- Que se passe-t-il si l'utilisateur navigue vers une route d'une fonctionnalité désactivée (ex : deep link) ? L'application redirige vers un onglet valide (ex : Accueil).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher une section "Fonctionnalités" dans le hub des paramètres, dans le groupe "Général".
- **FR-002**: Le système DOIT afficher la page Fonctionnalités avec la liste des 3 fonctionnalités optionnelles : Abonnements (icône autorenew, activé par défaut), Dettes (icône handshake, activé par défaut), Boutique (icône storefront, désactivé par défaut).
- **FR-003**: Chaque fonctionnalité DOIT être présentée avec une icône, un libellé, une description courte et un switch (toggle).
- **FR-004**: La bascule d'un toggle DOIT avoir un effet immédiat sur la barre de navigation — les onglets correspondant aux fonctionnalités désactivées disparaissent, ceux des fonctionnalités activées apparaissent.
- **FR-005**: Le noyau permanent (Dashboard et Transactions) DOIT toujours rester visible dans la barre de navigation, quels que soient les choix de toggles.
- **FR-006**: Le système DOIT persister les préférences de fonctionnalités localement pour qu'elles survivent à la fermeture de l'application.
- **FR-007**: En mode serveur, le système DOIT synchroniser les préférences avec le serveur via le point de gestion des préférences utilisateur.
- **FR-008**: Le système DOIT afficher un dialogue de confirmation lorsque l'utilisateur désactive une fonctionnalité contenant des données existantes. Le message DOIT préciser que les données sont masquées, pas supprimées.
- **FR-009**: Si l'utilisateur se trouve sur un onglet d'une fonctionnalité qu'il vient de désactiver, le système DOIT le rediriger vers un onglet valide.
- **FR-010**: Les préférences par défaut au premier lancement DOIVENT être : Abonnements activé, Dettes activé, Boutique désactivé.

### Key Entities

- **Feature**: Fonctionnalité optionnelle de l'application. Trois valeurs possibles : Abonnements (SUBSCRIPTIONS), Dettes (DEBTS), Boutique (SHOP). Chacune a un libellé, une icône et un état par défaut.
- **UserPreference**: Préférences de personnalisation d'un utilisateur. Contient la liste des fonctionnalités activées et l'ordre de navigation des onglets. Relation 1:1 avec l'utilisateur.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut accéder à la page Fonctionnalités depuis les paramètres en une seule interaction.
- **SC-002**: La bascule d'un toggle modifie la barre de navigation en moins de 1 seconde, sans rechargement de l'application.
- **SC-003**: Les préférences de fonctionnalités sont restituées fidèlement après fermeture et réouverture de l'application.
- **SC-004**: En mode serveur, les préférences sont synchronisées avec le serveur et disponibles sur un autre appareil.
- **SC-005**: Le dialogue de confirmation apparaît systématiquement lorsque des données existent pour la fonctionnalité désactivée.

## Assumptions

- Le backend expose déjà les endpoints de gestion des préférences (`GET/PUT /users/me/preferences`) via la feature KKS-117.
- Les fonctionnalités optionnelles actuelles sont limitées à trois : Abonnements, Dettes, Boutique. L'ajout de nouvelles fonctionnalités sera géré par extension.
- Les valeurs par défaut au premier lancement Flutter diffèrent des valeurs par défaut du serveur : côté Flutter, SHOP est désactivé par défaut (le serveur active tout par défaut). Le premier sync serveur réconcilie les deux.
- La vérification de l'existence de données pour le dialogue de confirmation est basée sur la présence de données locales ou distantes selon le mode de données actif.
- L'ordre de navigation est géré automatiquement (les fonctionnalités activées apparaissent dans l'ordre standard : Abonnements, Dettes, Boutique). La réorganisation manuelle de l'ordre fait partie d'une future feature.
