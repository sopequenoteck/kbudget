# Feature Specification: Widget filtres segmentés (SegmentedFilter)

**Feature Branch**: `038-flutter-segmentedfilter-widget`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "Style iOS Segmented Control. Container bgTertiary, tab active surfaceRaised avec shadow. Utilisé pour filtrer par type/statut sur transactions, abonnements, dettes."
**Linear**: [KKS-99](https://linear.app/kksdev/issue/KKS-99)

## Clarifications

### Session 2026-02-21

- Q: Quel type d'animation lors du changement de segment (cross-fade, sliding pill, ou cross-fade + scale) ? → A: Cross-fade — le fond et le texte de chaque segment changent indépendamment avec une animation de fondu.

## User Scenarios & Testing

### User Story 1 - Filtrer une liste par catégorie (Priority: P1)

L'utilisateur consulte une liste (transactions, abonnements ou dettes) et souhaite la filtrer rapidement par type ou statut. Il tape sur un segment du filtre pour afficher uniquement les éléments correspondants. Le segment sélectionné se distingue visuellement par un fond surélevé avec ombre.

**Why this priority**: C'est la raison d'être du widget. Sans cette capacité de filtrage, le composant n'a aucune utilité.

**Independent Test**: Peut être testé en affichant le widget avec 3 segments (Tous / Dépenses / Recettes), en tapant sur chaque segment et en vérifiant que le callback renvoie la bonne valeur.

**Acceptance Scenarios**:

1. **Given** un SegmentedFilter avec les segments ["Tous", "Dépenses", "Recettes"] et la valeur initiale "Tous", **When** l'utilisateur tape sur "Dépenses", **Then** le segment "Dépenses" devient visuellement actif (fond surélevé + ombre) et le callback `onChanged` est appelé avec la valeur correspondante.
2. **Given** un SegmentedFilter avec le segment "Dépenses" actif, **When** l'utilisateur tape sur "Dépenses" (déjà sélectionné), **Then** rien ne se passe (pas de callback, pas de changement visuel).
3. **Given** un SegmentedFilter avec le segment "Recettes" actif, **When** l'utilisateur tape sur "Tous", **Then** le segment "Tous" devient actif et "Recettes" reprend son apparence inactive.

---

### User Story 2 - Cohérence visuelle et thèmes (Priority: P2)

Le widget adopte le style iOS Segmented Control : conteneur avec fond tertiaire, segment actif avec fond de surface surélevé et ombre légère. Les transitions entre segments sont animées de manière fluide. Le widget s'adapte aux thèmes clair et sombre.

**Why this priority**: La cohérence visuelle avec le design system existant et l'app Angular de référence est essentielle pour une expérience utilisateur unifiée.

**Independent Test**: Peut être testé en affichant le widget dans les deux thèmes (clair/sombre) et en vérifiant visuellement les couleurs, ombres et animations.

**Acceptance Scenarios**:

1. **Given** le thème clair, **When** le widget est affiché, **Then** le conteneur a un fond gris clair, le segment actif a un fond blanc avec une ombre légère, le texte actif est mis en valeur, le texte inactif est atténué.
2. **Given** le thème sombre, **When** le widget est affiché, **Then** les couleurs s'adaptent aux tokens du thème sombre.
3. **Given** un segment actif, **When** l'utilisateur change de segment, **Then** la transition est animée de manière fluide (fond et texte).

---

### User Story 3 - Adaptabilité à différents contextes (Priority: P2)

Le widget est générique et réutilisable. Il accepte un nombre variable de segments (2 à 5) et fonctionne avec n'importe quel ensemble de valeurs de filtrage (types de transaction, statuts d'abonnement, statuts de dette, etc.).

**Why this priority**: Le widget doit être réutilisable sur au moins 3 écrans différents avec des options de filtrage distinctes.

**Independent Test**: Peut être testé en instanciant le widget avec 2 segments, puis 3, puis 5, et en vérifiant que tous s'affichent correctement et se répartissent équitablement.

**Acceptance Scenarios**:

1. **Given** un SegmentedFilter avec 2 segments, **When** le widget est affiché, **Then** chaque segment occupe la moitié de la largeur disponible.
2. **Given** un SegmentedFilter avec 4 segments, **When** le widget est affiché, **Then** chaque segment occupe un quart de la largeur et le texte reste lisible.
3. **Given** un SegmentedFilter utilisé avec des valeurs typées (enum), **When** le développeur l'intègre, **Then** l'API générique permet de passer n'importe quel type de valeur avec son label associé.

---

### User Story 4 - Accessibilité (Priority: P3)

Le widget est utilisable par les technologies d'assistance. Les segments sont annoncés correctement par les lecteurs d'écran avec leur état (sélectionné ou non).

**Why this priority**: L'accessibilité est importante mais n'est pas bloquante pour le MVP du widget.

**Independent Test**: Peut être testé avec un lecteur d'écran (TalkBack/VoiceOver) en vérifiant l'annonce de chaque segment et son état.

**Acceptance Scenarios**:

1. **Given** un lecteur d'écran activé, **When** l'utilisateur explore le widget, **Then** le groupe de segments est identifié comme un groupe de contrôle, chaque segment est annoncé avec son label et son état (sélectionné/non sélectionné).
2. **Given** un lecteur d'écran activé, **When** l'utilisateur active un segment, **Then** le changement d'état est annoncé.

---

### Edge Cases

- Que se passe-t-il quand un seul segment est fourni ? Une assertion erreur est levée en debug — le widget requiert au minimum 2 segments (FR-006).
- Que se passe-t-il quand les labels sont très longs ? Le texte est tronqué avec ellipsis pour rester sur une ligne.
- Que se passe-t-il quand la valeur sélectionnée initiale ne correspond à aucun segment ? Le premier segment est sélectionné par défaut.
- Que se passe-t-il quand 5 segments sont affichés sur un petit écran ? Les segments se répartissent équitablement, le texte se réduit ou se tronque si nécessaire.

## Requirements

### Functional Requirements

- **FR-001**: Le widget DOIT afficher une liste de segments horizontaux avec un segment visuellement actif à tout moment.
- **FR-002**: Le widget DOIT notifier le parent via un callback quand l'utilisateur sélectionne un segment différent du segment actif.
- **FR-003**: Le widget NE DOIT PAS déclencher de callback quand l'utilisateur tape sur le segment déjà actif.
- **FR-004**: Le widget DOIT occuper toute la largeur disponible, chaque segment ayant une largeur égale (répartition équitable), séparés par un espacement de 4px.
- **FR-005**: Le widget DOIT animer la transition entre segments en cross-fade : le fond et le style de texte de chaque segment changent indépendamment avec une animation de fondu (pas de sliding pill ni de translation d'indicateur).
- **FR-006**: Le widget DOIT supporter un nombre variable de segments (de 2 à 5 inclus).
- **FR-007**: Le widget DOIT accepter une API générique typée permettant de passer des valeurs de n'importe quel type avec leurs labels d'affichage associés. Le label de chaque segment NE DOIT PAS être vide (assertion en debug).
- **FR-008**: Le widget DOIT s'adapter aux thèmes clair et sombre en utilisant les tokens du design system.
- **FR-009**: Le conteneur DOIT avoir un fond tertiaire avec des coins arrondis.
- **FR-010**: Le segment actif DOIT avoir un fond de surface avec une ombre légère et des coins arrondis.
- **FR-011**: Le texte du segment actif DOIT être mis en valeur (couleur `onSurface` du thème, poids semi-bold), le texte inactif DOIT être atténué (couleur `onSurfaceVariant` du thème, poids medium).
- **FR-012**: Le widget DOIT exposer une sémantique d'accessibilité avec un groupe annoté et chaque segment identifié avec son état de sélection.
- **FR-013**: Quand un label de segment dépasse l'espace disponible, le texte DOIT être tronqué avec ellipsis sur une seule ligne.

### Distinction avec AppToggle existant

Le widget SegmentedFilter se distingue de AppToggle sur les points suivants :

| Critère            | SegmentedFilter               | AppToggle                    |
|--------------------|-------------------------------|------------------------------|
| Nb de segments     | 2 à 5                        | Exactement 2                 |
| Style actif        | Surface + ombre (style iOS)   | Couleur primaire (amber)     |
| Largeur            | Pleine largeur (flex)         | Taille minimale (min)        |
| Usage              | Filtrage de listes de données | Choix binaire (paramètres)   |

### Key Entities

- **Segment**: Un choix dans le filtre, composé d'une valeur typée et d'un label d'affichage.
- **SegmentedFilter**: Le conteneur visuel qui affiche les segments et gère la sélection.

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut changer de filtre en un seul tap, avec un retour visuel animé immédiat.
- **SC-002**: Le widget s'affiche correctement avec 2, 3, 4 et 5 segments sans déformation visuelle ni troncature excessive.
- **SC-003**: Le widget s'affiche correctement dans les thèmes clair et sombre avec les bonnes couleurs et contrastes.
- **SC-004**: Les lecteurs d'écran (VoiceOver/TalkBack) annoncent correctement chaque segment et son état de sélection.
- **SC-005**: Le widget est intégrable sur les 3 écrans cibles (transactions, abonnements, dettes) sans modification de son API.

## Assumptions

- Le widget est un composant contrôlé par le parent (état géré à l'extérieur), sans dépendance à un state management externe.
- Les tokens de design (couleurs, espacements, rayons, ombres, typographie, durées d'animation) existent déjà dans le design system Flutter.
- Le mapping des tokens visuels Angular vers Flutter est : `--bg-tertiary` → `surfaceContainerHighest`, `--surface-default` → `surface`, `--shadow-sm` → `AppShadows.sm`.
- Le widget sera placé aux côtés des autres widgets réutilisables du projet Flutter.
- L'API générique utilise un type paramétré pour permettre la réutilisation avec différents types de valeurs (enum, String, etc.).
- Le widget est bloquant pour 3 issues Linear : KKS-103 (Transactions liste), KKS-105 (Abonnements liste), KKS-107 (Dettes liste).
