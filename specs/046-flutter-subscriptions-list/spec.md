# Feature Specification: Flutter — Écran Abonnements Liste

**Feature Branch**: `046-flutter-subscriptions-list`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "KKS-105 — Flutter: Écran Abonnements liste. Total mensuel par devise + filtre statut (Tous/Actifs/Inactifs) + liste avec badge Inactif. Tap ouvre formulaire édition."
**Linear**: [KKS-105](https://linear.app/kksdev/issue/KKS-105/flutter-ecran-abonnements-liste)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des abonnements (Priority: P1)

L'utilisateur ouvre l'écran Abonnements et voit l'ensemble de ses abonnements triés alphabétiquement. Chaque item affiche le nom, le montant formaté avec la fréquence (ex: "15,99 €/mois"), l'icône et la couleur de la catégorie, ainsi que la prochaine date de renouvellement en sous-titre. Les abonnements inactifs portent un badge inactif visuellement distinct (texte en couleur d'erreur du thème).

**Why this priority**: C'est la fonctionnalité fondamentale de l'écran — sans liste, rien d'autre n'a de sens.

**Independent Test**: Peut être testé en ouvrant l'écran avec des abonnements existants et en vérifiant l'affichage correct de chaque item (nom, montant/fréquence, catégorie, prochaine date, badge inactif).

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 5 abonnements (3 actifs, 2 inactifs), **When** il ouvre l'écran Abonnements, **Then** les 5 abonnements s'affichent triés alphabétiquement avec nom, montant/fréquence, icône catégorie et prochaine date de renouvellement.
2. **Given** un abonnement est inactif, **When** l'écran s'affiche, **Then** cet abonnement porte un badge inactif "Inactif" visuellement distinct (texte en couleur d'erreur du thème) affiché sous la valeur de l'item.
3. **Given** un abonnement mensuel débuté le 5 janvier, **When** la date actuelle est le 20 février, **Then** la prochaine date de renouvellement affichée est "5 mars".
4. **Given** un abonnement annuel débuté le 15 juin 2025, **When** la date actuelle est le 23 février 2026, **Then** la prochaine date de renouvellement affichée est "15 juin 2026".
5. **Given** l'utilisateur n'a aucun abonnement, **When** il ouvre l'écran, **Then** un état vide s'affiche avec une icône, le message "Aucun abonnement" et le FAB reste accessible pour en créer un.

---

### User Story 2 - Voir le total mensuel des abonnements actifs (Priority: P2)

Au-dessus de la liste, une carte récapitulative affiche le total mensuel estimé de tous les abonnements actifs. Les abonnements annuels sont ramenés au mois (montant ÷ 12). Si l'utilisateur a des abonnements dans plusieurs devises, un total est affiché par devise.

**Why this priority**: Le total mensuel donne une vision synthétique du coût récurrent — information clé pour la gestion budgétaire.

**Independent Test**: Peut être testé en créant des abonnements actifs avec différentes fréquences et devises, puis en vérifiant le calcul du total affiché.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 3 abonnements actifs mensuels (10 €, 15 €, 5 €), **When** l'écran s'affiche, **Then** la carte récapitulative montre "Total mensuel : 30,00 €".
2. **Given** l'utilisateur a un abonnement annuel actif de 120 € et un mensuel de 10 €, **When** l'écran s'affiche, **Then** le total mensuel est 20,00 € (120÷12 + 10).
3. **Given** l'utilisateur a des abonnements actifs en EUR et en USD, **When** l'écran s'affiche, **Then** deux totaux distincts sont affichés, un par devise.
4. **Given** tous les abonnements sont inactifs, **When** l'écran s'affiche, **Then** la carte récapitulative n'est pas affichée.

---

### User Story 3 - Filtrer par statut (Priority: P2)

Un filtre segmenté (Tous / Actifs / Inactifs) permet de filtrer la liste des abonnements affichés. Le filtre par défaut est "Tous". Le total mensuel ne change pas selon le filtre (il reflète toujours les actifs uniquement). Le filtrage se fait côté client sur les données déjà chargées.

**Why this priority**: Le filtre aide à identifier rapidement les abonnements inactifs à supprimer ou les actifs à gérer — complémentaire à la liste de base.

**Independent Test**: Peut être testé en sélectionnant chaque option du filtre et en vérifiant que la liste affichée correspond au statut sélectionné.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 3 actifs et 2 inactifs, **When** il sélectionne "Actifs", **Then** seuls les 3 abonnements actifs sont affichés.
2. **Given** l'utilisateur a 3 actifs et 2 inactifs, **When** il sélectionne "Inactifs", **Then** seuls les 2 abonnements inactifs sont affichés.
3. **Given** le filtre est sur "Actifs", **When** l'utilisateur sélectionne "Tous", **Then** tous les 5 abonnements s'affichent à nouveau.
4. **Given** le filtre est sur "Inactifs" et aucun abonnement inactif n'existe, **When** l'utilisateur voit la liste, **Then** un état vide adapté au filtre s'affiche (ex: "Aucun abonnement inactif").

---

### User Story 4 - Ouvrir le formulaire d'édition (Priority: P3)

Lorsque l'utilisateur tape sur un abonnement dans la liste, le formulaire d'édition s'ouvre en modal avec les données pré-remplies. Le toggle Mensuel/Annuel dans le header de la modal reflète la fréquence de l'abonnement.

**Why this priority**: L'édition existe déjà via le SubscriptionForm (branche 045) — il s'agit ici uniquement de connecter le tap au formulaire existant.

**Independent Test**: Peut être testé en tapant sur un item et en vérifiant que la modal s'ouvre avec les bonnes données pré-remplies.

**Acceptance Scenarios**:

1. **Given** un abonnement mensuel "Netflix" à 15,99 € existe, **When** l'utilisateur tape dessus, **Then** le formulaire s'ouvre en modal avec nom="Netflix", montant=15,99, fréquence=Mensuel et les autres champs pré-remplis.
2. **Given** un abonnement annuel existe, **When** l'utilisateur tape dessus, **Then** le toggle fréquence dans le header de la modal est positionné sur "Annuel".

---

### Edge Cases

- Que se passe-t-il si le chargement échoue ? → État erreur avec bouton "Réessayer" et pull-to-refresh disponible.
- Que se passe-t-il pendant le chargement ? → Affichage de skeletons (shimmer) à la place des items.
- Que se passe-t-il si un abonnement n'a pas de catégorie ? → Icône et couleur par défaut.
- Que se passe-t-il si la date de début est dans le futur ? → La prochaine date affichée est la date de début elle-même.
- Que se passe-t-il au pull-to-refresh ? → Les données sont rechargées et le filtre actif est conservé.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'écran DOIT afficher la liste de tous les abonnements de l'utilisateur, triés alphabétiquement par nom.
- **FR-002**: Chaque item DOIT afficher le nom, le montant formaté avec la fréquence ("/mois" ou "/an"), l'icône et couleur de la catégorie, et la prochaine date de renouvellement.
- **FR-003**: Les abonnements inactifs DOIVENT porter un badge inactif "Inactif" visuellement distinct (texte en couleur d'erreur du thème) affiché via le sous-titre droit de l'item.
- **FR-004**: Une carte récapitulative DOIT afficher le total mensuel estimé des abonnements actifs. Les abonnements annuels sont convertis au mois (÷12). Un total par devise si plusieurs devises.
- **FR-005**: La carte récapitulative NE DOIT PAS s'afficher si aucun abonnement actif n'existe.
- **FR-006**: Un filtre segmenté à 3 options (Tous / Actifs / Inactifs) DOIT permettre de filtrer la liste. Le filtre par défaut est "Tous".
- **FR-007**: Le filtrage DOIT être effectué côté client sur les données déjà chargées (pas de nouvel appel réseau).
- **FR-008**: La prochaine date de renouvellement DOIT être calculée en avançant depuis la date de début par incrément mensuel ou annuel selon la fréquence, jusqu'à obtenir une date strictement supérieure à aujourd'hui.
- **FR-009**: Le tap sur un item DOIT ouvrir le formulaire d'édition en modal avec les données pré-remplies.
- **FR-010**: L'écran DOIT gérer les états de chargement (skeleton shimmer), d'erreur (bouton réessayer) et vide (message adapté au filtre actif).
- **FR-011**: Le pull-to-refresh DOIT recharger les données tout en conservant le filtre actif.
- **FR-012**: Le FAB "Nouvel abonnement" DOIT rester accessible quel que soit l'état de l'écran ou le filtre sélectionné.

### Key Entities

- **Subscription**: Abonnement récurrent de l'utilisateur. Attributs principaux : nom, montant, fréquence (mensuel/annuel), date de début, statut actif/inactif, catégorie, compte, devise.
- **Category**: Catégorie associée à un abonnement, fournissant icône et couleur pour l'affichage dans la liste.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut visualiser la liste complète de ses abonnements en moins de 2 secondes après ouverture de l'écran.
- **SC-002**: Le total mensuel affiché est toujours exact par rapport aux abonnements actifs (annuels convertis ÷12, regroupés par devise).
- **SC-003**: Le changement de filtre met à jour la liste affichée de manière instantanée (sans temps de chargement perceptible).
- **SC-004**: L'utilisateur peut identifier visuellement un abonnement inactif sans lire le détail (badge visible au premier coup d'œil).
- **SC-005**: L'utilisateur peut passer de la liste à l'édition d'un abonnement en un seul tap.
- **SC-006**: La prochaine date de renouvellement affichée est toujours correcte par rapport à la date du jour et la fréquence de l'abonnement.

## Assumptions

- Le formulaire d'édition des abonnements (SubscriptionForm) est déjà implémenté et fonctionnel (branche 045).
- Les widgets communs SegmentedFilter et ListItem sont disponibles et fonctionnels.
- Le SubscriptionNotifier avec CRUD de base existe déjà.
- Le filtrage se fait côté client car le repository Flutter charge déjà tous les abonnements sans paramètre de filtre.
- Le calcul de la prochaine date de renouvellement est une logique purement locale (pas de champ API).
- La devise par défaut est EUR si non spécifiée sur l'abonnement.

## Dependencies

- **KKS-99**: Widget filtres segmentés (SegmentedFilter) — requis pour le filtre de statut.
- **KKS-93**: Widget ListItem réutilisable — requis pour l'affichage des items.
- **KKS-115**: Notifiers Riverpod CRUD — requis pour le chargement et la gestion d'état des abonnements.
