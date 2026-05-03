# Feature Specification: Widget SelectPicker

**Feature Branch**: `039-flutter-selectpicker-widget`
**Created**: 2026-02-21
**Status**: Planned
**Input**: Linear issue KKS-96: "Bottom sheet de sélection générique avec liste d'items, placeholder, clearable. Utilisé pour comptes, fréquences, etc. Ref: app-select-picker Angular."
**Linear**: [KKS-96](https://linear.app/kksdev/issue/KKS-96)

## User Scenarios & Testing

### User Story 1 - Sélectionner un item dans une liste (Priority: P1)

L'utilisateur interagit avec un formulaire contenant un champ de sélection (ex : compte, fréquence, devise). Il tape sur le champ, un bottom sheet s'ouvre avec la liste des options disponibles. Il tape sur l'option souhaitée, le bottom sheet se ferme et le champ affiche l'item sélectionné.

**Why this priority**: C'est la raison d'être du widget. Sans la capacité de sélectionner un item, le composant n'a aucune utilité.

**Independent Test**: Afficher le widget avec 5 items (comptes bancaires), taper sur le trigger, vérifier l'ouverture du bottom sheet, taper sur un item, vérifier la fermeture et la valeur retournée.

**Acceptance Scenarios**:

1. **Given** un SelectPicker avec 5 items et aucune sélection, **When** l'utilisateur tape sur le trigger, **Then** un bottom sheet s'ouvre via AppModal avec le titre du placeholder et la liste des items.
2. **Given** le bottom sheet ouvert avec la liste des items, **When** l'utilisateur tape sur un item, **Then** le bottom sheet se ferme, le callback `onChanged` est appelé avec l'id de l'item sélectionné, et le trigger affiche le label de l'item.
3. **Given** un SelectPicker avec l'item "Compte Courant" sélectionné, **When** l'utilisateur tape sur le trigger puis sélectionne "Compte Épargne", **Then** le callback `onChanged` est appelé avec le nouvel id et le trigger affiche "Compte Épargne".
4. **Given** le bottom sheet ouvert, **When** l'utilisateur tape sur l'item déjà sélectionné, **Then** le bottom sheet se ferme sans appeler le callback (pas de changement).

---

### User Story 2 - Affichage du trigger et du placeholder (Priority: P1)

Le champ de sélection affiche soit l'item actuellement sélectionné (avec son icône, label et texte secondaire), soit un texte placeholder grisé quand aucun item n'est sélectionné. Un chevron indique qu'il s'agit d'un champ ouvrable.

**Why this priority**: Le trigger est le point d'entrée du widget. Sans un affichage clair de l'état actuel, l'utilisateur ne sait pas ce qui est sélectionné ni qu'il peut interagir.

**Independent Test**: Afficher le widget sans sélection, vérifier le placeholder. Afficher avec une sélection, vérifier l'affichage complet de l'item.

**Acceptance Scenarios**:

1. **Given** un SelectPicker sans sélection, **When** le widget est affiché, **Then** le trigger affiche le texte placeholder en couleur atténuée et un chevron vers le bas.
2. **Given** un SelectPicker avec l'item "Compte Courant" sélectionné (icône "🏦", texte secondaire "1 234,56 €"), **When** le widget est affiché, **Then** le trigger affiche l'icône, le label et le texte secondaire de l'item.
3. **Given** un SelectPicker avec un item sélectionné ayant une couleur, **When** le widget est affiché, **Then** un indicateur coloré (pastille) est visible à côté du label.

---

### User Story 3 - Effacer la sélection (Priority: P2)

L'utilisateur souhaite retirer sa sélection pour revenir à l'état initial (aucun item sélectionné). Il tape sur le bouton de suppression (×) affiché à côté de l'item sélectionné.

**Why this priority**: Permettre de revenir à un état vide est essentiel pour les champs optionnels des formulaires.

**Independent Test**: Afficher le widget avec un item sélectionné et `clearable: true`, taper sur le bouton ×, vérifier que la sélection est effacée.

**Acceptance Scenarios**:

1. **Given** un SelectPicker clearable avec un item sélectionné, **When** l'utilisateur tape sur le bouton ×, **Then** la sélection est effacée, le callback `onChanged` est appelé avec `null`, et le trigger revient au placeholder.
2. **Given** un SelectPicker avec `clearable: false` et un item sélectionné, **When** le widget est affiché, **Then** le bouton × n'est pas visible.
3. **Given** un SelectPicker clearable sans sélection, **When** le widget est affiché, **Then** le bouton × n'est pas visible.

---

### User Story 4 - Rechercher dans les items (Priority: P2)

Quand la liste contient beaucoup d'items, un champ de recherche apparaît en haut du bottom sheet. L'utilisateur peut taper pour filtrer la liste en temps réel.

**Why this priority**: La recherche améliore significativement l'expérience quand la liste dépasse 5 items (catégories, devises, etc.).

**Independent Test**: Afficher le widget avec 10 items et `searchable: true`, ouvrir le bottom sheet, taper un terme de recherche, vérifier que la liste est filtrée.

**Acceptance Scenarios**:

1. **Given** un SelectPicker avec 10 items, **When** le bottom sheet s'ouvre, **Then** un champ de recherche est affiché en haut de la liste (car items >= seuil par défaut de 5).
2. **Given** le bottom sheet ouvert avec la recherche, **When** l'utilisateur tape "Cour", **Then** seuls les items dont le label contient "Cour" (insensible à la casse) sont affichés.
3. **Given** le bottom sheet ouvert avec un terme de recherche ne correspondant à aucun item, **When** la recherche ne retourne rien, **Then** un message vide est affiché.
4. **Given** un SelectPicker avec 3 items (< seuil), **When** le bottom sheet s'ouvre, **Then** le champ de recherche n'est PAS affiché.
5. **Given** un SelectPicker avec `searchable: true` explicite et 3 items, **When** le bottom sheet s'ouvre, **Then** le champ de recherche EST affiché (override du seuil).

---

### User Story 5 - Affichage riche des items (Priority: P2)

Chaque item dans la liste peut afficher une combinaison optionnelle d'icône (emoji), pastille de couleur, label principal et texte secondaire aligné à droite. L'item actuellement sélectionné est visuellement distingué.

**Why this priority**: L'affichage riche permet de réutiliser le widget pour les comptes (icône + solde), catégories (icône + couleur), devises, etc.

**Independent Test**: Afficher le bottom sheet avec des items ayant différentes combinaisons (icône seule, couleur seule, les deux, texte secondaire, rien), vérifier l'affichage correct.

**Acceptance Scenarios**:

1. **Given** un item avec icône "🏦", label "Compte Courant" et texte secondaire "1 234 €", **When** l'item est affiché dans la liste, **Then** l'icône, le label et le texte secondaire sont visibles dans cet ordre.
2. **Given** un item avec une couleur "#FF5733" et sans icône, **When** l'item est affiché, **Then** une pastille colorée circulaire est visible avant le label.
3. **Given** la liste ouverte avec un item sélectionné, **When** l'utilisateur voit la liste, **Then** l'item sélectionné a un fond distinct (couleur primaire claire) pour le repérer visuellement.

---

### User Story 6 - Accessibilité (Priority: P3)

Le widget est utilisable par les technologies d'assistance. Le trigger et les items de la liste sont correctement annoncés par les lecteurs d'écran.

**Why this priority**: L'accessibilité est importante mais non bloquante pour le MVP.

**Independent Test**: Vérifier les nœuds Semantics du trigger et des items via les finders Flutter.

**Acceptance Scenarios**:

1. **Given** un lecteur d'écran activé, **When** l'utilisateur explore le trigger, **Then** le label sélectionné ou le placeholder est annoncé, ainsi que l'indication "bouton" interactif.
2. **Given** le bottom sheet ouvert, **When** l'utilisateur explore la liste, **Then** chaque item est annoncé avec son label et son état de sélection.

---

### Edge Cases

- Que se passe-t-il quand la liste d'items est vide ? Le trigger est affiché avec le placeholder mais l'ouverture du bottom sheet montre le message vide configurable.
- Que se passe-t-il quand l'item sélectionné est retiré de la liste (items mis à jour dynamiquement) ? La sélection est automatiquement réinitialisée et `onChanged(null)` est appelé.
- Que se passe-t-il quand le label d'un item est très long ? Le texte est tronqué avec ellipsis dans le trigger et dans la liste.
- Que se passe-t-il quand le widget est disabled ? Le trigger est visuellement atténué et non interactif (pas d'ouverture du bottom sheet).
- Que se passe-t-il quand l'utilisateur ferme le bottom sheet via le bouton × ou en tapant à l'extérieur ? Aucun changement de sélection, le bottom sheet se ferme simplement.

## Requirements

### Functional Requirements

- **FR-001**: Le widget DOIT afficher un trigger adoptant le même style visuel qu'AppFormField (label flottant, bordure arrondie, état d'erreur rouge) montrant soit l'item sélectionné (avec icône, couleur, label, texte secondaire), soit un placeholder textuel quand aucun item n'est sélectionné.
- **FR-002**: Le widget DOIT ouvrir un bottom sheet (via AppModal) au tap sur le trigger, affichant la liste des items disponibles.
- **FR-003**: Le widget DOIT notifier le parent via un callback `onChanged` quand l'utilisateur sélectionne un item différent de l'item actif, puis fermer le bottom sheet.
- **FR-004**: Le widget NE DOIT PAS déclencher de callback quand l'utilisateur sélectionne l'item déjà actif (le bottom sheet se ferme silencieusement).
- **FR-005**: Le widget DOIT afficher un bouton × (clear) sur le trigger quand `clearable` est activé et qu'un item est sélectionné. Le tap sur × DOIT effacer la sélection et appeler `onChanged(null)`.
- **FR-006**: Le widget DOIT afficher un champ de recherche en haut du bottom sheet quand le nombre d'items atteint ou dépasse le seuil (défaut : 5), ou quand `searchable` est explicitement activé.
- **FR-007**: La recherche DOIT filtrer les items en temps réel, de manière insensible à la casse, sur le champ label.
- **FR-008**: Le widget DOIT afficher un message configurable quand la liste filtrée est vide.
- **FR-009**: Chaque item dans la liste DOIT pouvoir afficher de manière optionnelle : une icône (emoji), une pastille de couleur circulaire, un label principal, et un texte secondaire aligné à droite.
- **FR-010**: L'item actuellement sélectionné DOIT être visuellement distingué dans la liste (fond de couleur primaire claire).
- **FR-011**: Le widget DOIT réinitialiser automatiquement la sélection (appeler `onChanged(null)`) si l'item sélectionné disparaît de la liste lors d'une mise à jour dynamique des items.
- **FR-012**: Le widget DOIT supporter un état disabled rendant le trigger non interactif et visuellement atténué.
- **FR-013**: Le widget DOIT utiliser le placeholder comme titre du bottom sheet (via AppModal).
- **FR-014**: Le widget DOIT s'adapter aux thèmes clair et sombre en utilisant les tokens du design system.
- **FR-015**: Le widget DOIT exposer un callback optionnel `onSearchChanged` émettant le terme de recherche en temps réel, pour permettre des comportements avancés (ex : création dynamique d'items).
- **FR-016**: Le texte DOIT être tronqué avec ellipsis quand un label dépasse l'espace disponible, dans le trigger comme dans la liste.
- **FR-017**: Le widget DOIT exposer une sémantique d'accessibilité sur le trigger (label/placeholder annoncé) et sur chaque item de la liste (label + état de sélection).
- **FR-018**: Le widget DOIT implémenter `FormField<String?>` pour s'intégrer nativement aux formulaires Flutter (`Form.reset()`, `Form.save()`, validators, affichage d'erreur).

### Distinction avec les widgets existants

| Critère          | SelectPicker                          | SegmentedFilter                     |
|------------------|---------------------------------------|-------------------------------------|
| Nb d'options     | Illimité                              | 2 à 5                              |
| Affichage        | Bottom sheet (liste scrollable)       | Inline (segments horizontaux)       |
| Recherche        | Oui (filtrage)                        | Non                                 |
| Clearable        | Oui (optionnel)                       | Non (toujours une sélection)        |
| Richesse items   | Icône, couleur, texte secondaire      | Label texte uniquement              |
| Usage            | Formulaires (champs de sélection)     | Filtrage rapide de listes           |

### Key Entities

- **SelectPickerItem**: Un item sélectionnable, composé d'un identifiant unique (String), un label d'affichage, et optionnellement une icône (emoji), une couleur (Color), et un texte secondaire.
- **SelectPicker**: Le widget conteneur comprenant un trigger (affichage de l'état actuel) et un bottom sheet (liste de sélection).

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut sélectionner un item en 2 taps (tap trigger + tap item), avec fermeture automatique du bottom sheet.
- **SC-002**: L'utilisateur peut effacer sa sélection en 1 tap (bouton ×) quand le champ est clearable.
- **SC-003**: L'utilisateur peut trouver un item parmi 20+ options en tapant 2-3 caractères dans la recherche.
- **SC-004**: Le widget s'affiche correctement dans les thèmes clair et sombre.
- **SC-005**: Le widget est intégrable dans les formulaires de transaction, abonnement, dette et paramètres sans modification de son API.
- **SC-006**: Le widget bloquant est livré avant les 5 issues dépendantes (KKS-97, KKS-104, KKS-106, KKS-109, KKS-111).

## Clarifications

### Session 2026-02-21

- Q: Le SelectPicker doit-il implémenter FormField<String?> pour l'intégration formulaire native ? → A: Oui, implémenter FormField<String?> (validation, reset, save, affichage erreur).
- Q: Le trigger doit-il adopter le même style visuel qu'AppFormField ? → A: Oui, style AppFormField (label flottant, bordure arrondie, état d'erreur rouge) pour cohérence dans les formulaires.

## Assumptions

- Le widget implémente `FormField<String?>` et est contrôlé par le parent via `selectedId` + `onChanged`, sans dépendance à un state management externe. L'intégration FormField ajoute le support natif de la validation, du reset et du save via `FormState`.
- Le système modal AppModal (feature 036) est disponible et gère automatiquement le responsive (bottom sheet mobile / dialog tablette).
- Les tokens de design (couleurs, espacements, rayons, ombres, typographie) existent déjà dans le design system Flutter.
- Le widget sera placé dans `common_widgets/` aux côtés des autres widgets réutilisables.
- L'identifiant de chaque item est un `String` (cohérent avec le pattern Angular et les id de l'API REST).
- Le placeholder par défaut est "Sélectionner..." (configurable).
- Le seuil de recherche par défaut est 5 items (configurable).
- Le callback `onChanged` émet `String?` : l'id de l'item sélectionné ou `null` quand la sélection est effacée.
