# Feature Specification: Écran Subscriptions (liste + filtre actif)

**Feature Branch**: `013-subscription-list`
**Created**: 2026-02-12
**Status**: Draft
**Input**: User description: "KKS-55 Écran Subscriptions (liste + filtre actif)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter ses abonnements (Priority: P1)

L'utilisateur accède à l'écran Subscriptions pour voir la liste de tous ses abonnements en cours et passés. Chaque abonnement affiche son nom, montant, fréquence et prochaine date de renouvellement. L'utilisateur voit d'un coup d'oeil le coût total mensuel de ses abonnements actifs.

**Why this priority**: C'est la fonctionnalité centrale de l'écran. Sans affichage de la liste, aucune autre fonctionnalité n'a de sens.

**Independent Test**: Peut être testé en naviguant vers l'écran Subscriptions et en vérifiant que les abonnements existants s'affichent avec toutes les informations attendues.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 3 abonnements actifs, **When** il accède à l'écran Subscriptions, **Then** les 3 abonnements s'affichent avec nom, montant formaté en EUR, fréquence et date de prochain renouvellement.
2. **Given** l'utilisateur a des abonnements actifs et inactifs, **When** il accède à l'écran sans filtre, **Then** tous les abonnements sont affichés (actifs et inactifs).
3. **Given** un abonnement est inactif, **When** il s'affiche dans la liste, **Then** un badge "Inactif" est visible sur cet élément.
4. **Given** l'utilisateur a des abonnements actifs, **When** la liste est affichée, **Then** un résumé en haut de page montre le total mensuel des abonnements actifs.

---

### User Story 2 - Filtrer les abonnements par statut (Priority: P2)

L'utilisateur peut filtrer la liste pour voir uniquement les abonnements actifs, uniquement les inactifs, ou tous. Le filtre met à jour la liste et le résumé en conséquence.

**Why this priority**: Le filtrage améliore la lisibilité mais n'est pas indispensable pour consulter ses abonnements.

**Independent Test**: Peut être testé en cliquant sur chaque option du filtre et en vérifiant que seuls les abonnements correspondants sont affichés.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Subscriptions, **When** il sélectionne le filtre "Actifs", **Then** seuls les abonnements actifs sont affichés.
2. **Given** l'utilisateur est sur l'écran Subscriptions, **When** il sélectionne le filtre "Inactifs", **Then** seuls les abonnements inactifs sont affichés.
3. **Given** le filtre "Actifs" est sélectionné, **When** l'utilisateur sélectionne "Tous", **Then** tous les abonnements sont à nouveau affichés.

---

### User Story 3 - Gérer les états de chargement et d'erreur (Priority: P3)

L'utilisateur voit un indicateur de chargement pendant le chargement des données, un message d'erreur avec possibilité de réessayer en cas de problème, et un message explicite si aucun abonnement n'existe.

**Why this priority**: Les états intermédiaires sont essentiels pour l'expérience utilisateur mais ne constituent pas la fonctionnalité principale.

**Independent Test**: Peut être testé en simulant les différents états (chargement, erreur réseau, liste vide) et en vérifiant les affichages correspondants.

**Acceptance Scenarios**:

1. **Given** les données sont en cours de chargement, **When** l'écran s'affiche, **Then** un indicateur de chargement (spinner) est visible.
2. **Given** le chargement échoue (erreur réseau), **When** l'écran s'affiche, **Then** un message d'erreur s'affiche avec un bouton "Réessayer".
3. **Given** l'utilisateur clique sur "Réessayer", **When** le rechargement est lancé, **Then** les données sont rechargées depuis le serveur.
4. **Given** l'utilisateur n'a aucun abonnement, **When** l'écran s'affiche, **Then** un message "Aucun abonnement" est affiché.
5. **Given** le filtre "Actifs" est sélectionné et aucun abonnement actif n'existe, **When** l'écran s'affiche, **Then** le message "Aucun abonnement" est affiché.

---

### Edge Cases

- Que se passe-t-il si un abonnement annuel a un montant élevé ? Le total mensuel doit convertir les abonnements annuels en équivalent mensuel (montant / 12).
- Que se passe-t-il si la date de début d'un abonnement est dans le futur ? Il s'affiche normalement avec sa date de renouvellement calculée.
- Que se passe-t-il si un abonnement n'a pas de catégorie ? L'élément s'affiche sans sous-titre de catégorie.
- Comment se comportent les données après création/modification via la modal ? La liste se rafraîchit automatiquement grâce au mécanisme de refresh du service.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher la liste de tous les abonnements de l'utilisateur connecté.
- **FR-002**: Chaque élément de la liste DOIT afficher : une icône de renouvellement, le nom de l'abonnement en titre, le montant combiné avec la fréquence en valeur (ex: "24,90 €/mois" ou "119,88 €/an"), et la date de prochain renouvellement en sous-titre (ex: "Renouvellement: 15 Janvier").
- **FR-003**: Les abonnements inactifs DOIVENT afficher un badge visuel "Inactif".
- **FR-004**: Le système DOIT afficher un résumé du total mensuel des abonnements actifs en haut de la liste. Les abonnements annuels sont convertis en équivalent mensuel (montant / 12).
- **FR-005**: Le système DOIT proposer un filtre à 3 options : "Tous", "Actifs", "Inactifs".
- **FR-006**: Le filtre "Actifs" et "Inactifs" DOIT interroger le serveur avec le paramètre de filtrage correspondant. Le filtre "Tous" charge tous les abonnements sans paramètre.
- **FR-007**: Le système DOIT afficher un indicateur de chargement pendant le chargement des données.
- **FR-008**: Le système DOIT afficher un message d'erreur avec un bouton "Réessayer" en cas d'échec du chargement.
- **FR-009**: Le système DOIT afficher un message "Aucun abonnement" lorsque la liste est vide (globalement ou après filtrage).
- **FR-010**: La liste DOIT se rafraîchir automatiquement après la création, modification ou suppression d'un abonnement via la modal.
- **FR-011**: Chaque élément de la liste DOIT avoir des états visuels interactifs (hover, focus) pour préparer une future action d'édition. Aucune action au clic n'est câblée dans cette feature (reporté à KKS-58).

### Key Entities

- **Subscription (Abonnement)**: Représente un abonnement récurrent de l'utilisateur. Attributs clés : nom, montant, fréquence (mensuel/annuel), date de début, statut actif/inactif, catégorie optionnelle.
- **Category (Catégorie)**: Catégorie optionnelle associée à un abonnement. Attributs clés : nom, icône.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter la liste complète de ses abonnements en moins de 2 secondes après navigation vers l'écran.
- **SC-002**: L'utilisateur peut filtrer ses abonnements par statut (actif/inactif/tous) en un seul clic.
- **SC-003**: Le total mensuel affiché est toujours cohérent avec les abonnements actifs visibles, en tenant compte de la conversion annuel vers mensuel.
- **SC-004**: L'écran gère correctement les 3 états (chargement, erreur, vide) sans blocage de l'interface.
- **SC-005**: La liste se met à jour automatiquement après toute opération CRUD sur un abonnement, sans rechargement manuel de la page.

## Clarifications

### Session 2026-02-12

- Q: Quel comportement au clic sur un élément de la liste ? → A: Interactivité visuelle seulement (hover/focus states), pas d'action au clic. L'édition est reportée à KKS-58.
- Q: Comment afficher la fréquence et le montant dans chaque élément ? → A: Montant combiné avec fréquence en valeur unique (ex: "24,90 €/mois"), date de renouvellement en sous-titre (ex: "Renouvellement: 15 Janvier").

## Assumptions

- Le filtre par défaut à l'ouverture de l'écran est "Tous" (affiche actifs et inactifs).
- Le tri par défaut est par nom alphabétique, calculé côté client (computed signal) sur les données retournées par l'API après application du filtre serveur (actif/inactif/tous). Le computed `sortedSubscriptions` prend en entrée le signal `subscriptions` (résultat brut de l'API) et non une copie pré-filtrée.
- L'icône de chaque abonnement dans la liste est fixe (emoji 🔄) et non l'icône de la catégorie.
- La prochaine date de renouvellement est calculée côté client : prochaine occurrence >= aujourd'hui, à partir de dateDebut + N * fréquence (1 mois pour MENSUEL, 12 mois pour ANNUEL). Pour les abonnements inactifs, le sous-titre affiche "Inactif" au lieu de la date de renouvellement.
- Le mécanisme de rafraîchissement après CRUD utilise le `refreshTrigger` signal du SubscriptionService (déjà câblé dans create/update/delete).
- Le résumé total mensuel ne s'affiche que s'il y a au moins un abonnement actif.
