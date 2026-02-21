# Feature Specification: Flutter — Widget CategoryPicker

**Feature Branch**: `040-flutter-categorypicker-widget`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "KKS-97 — Sélecteur de catégorie avec icônes emoji et couleurs. Ouvre un SelectPicker filtré. Ref: app-category-picker Angular."
**Linear**: KKS-97
**Bloqué par**: KKS-96 (SelectPicker)
**Bloque**: KKS-104 (Formulaire Transaction), KKS-106 (Formulaire Abonnement), KKS-108 (Formulaire Dette)

## Clarifications

### Session 2026-02-21

- Q: Le bouton "+ Créer" (création de catégorie inline) doit-il être inclus dans le périmètre ? → A: Oui, avec un callback `onCreateRequested(searchTerm)` délégué au parent. Le widget affiche le bouton mais ne gère pas la création lui-même.

### Session 2026-02-22

- Q: Où le bouton "+ Créer" apparaît-il dans le sélecteur ? → A: Uniquement quand la liste filtrée est vide, à la place du message "Aucune catégorie". Pas de bouton si des résultats partiels existent.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Sélection d'une catégorie existante (Priority: P1)

L'utilisateur remplit un formulaire (transaction, abonnement, dette) et doit choisir une catégorie. Il appuie sur le champ "Catégorie", un sélecteur s'ouvre avec la liste des catégories affichant pour chacune son icône emoji et son nom. L'utilisateur sélectionne une catégorie et le champ se met à jour.

**Why this priority**: Fonctionnalité fondamentale — sans sélection de catégorie, les formulaires de transaction, abonnement et dette ne peuvent pas fonctionner.

**Independent Test**: Peut être testé en intégrant le widget dans un formulaire de test avec une liste de catégories prédéfinies et en vérifiant que la sélection met à jour la valeur du formulaire.

**Acceptance Scenarios**:

1. **Given** un formulaire avec un champ CategoryPicker et une liste de 10 catégories, **When** l'utilisateur appuie sur le champ, **Then** un sélecteur modal s'ouvre affichant toutes les catégories avec leur icône emoji et leur nom.
2. **Given** le sélecteur de catégories est ouvert, **When** l'utilisateur appuie sur "Alimentation 🍔", **Then** le sélecteur se ferme, le champ affiche "🍔 Alimentation" et la valeur du formulaire est mise à jour avec l'identifiant de cette catégorie.
3. **Given** une catégorie est déjà sélectionnée, **When** l'utilisateur appuie à nouveau sur le champ et sélectionne une autre catégorie, **Then** la sélection est mise à jour.

---

### User Story 2 — Recherche et filtrage de catégories (Priority: P1)

L'utilisateur a beaucoup de catégories et souhaite trouver rapidement la bonne. Le sélecteur propose un champ de recherche qui filtre les catégories en temps réel par nom.

**Why this priority**: Essentiel pour l'ergonomie — un utilisateur avec 15+ catégories doit pouvoir trouver la bonne rapidement sans défiler toute la liste.

**Independent Test**: Peut être testé avec une liste de 20 catégories et en vérifiant que la saisie d'un terme réduit la liste aux catégories correspondantes.

**Acceptance Scenarios**:

1. **Given** le sélecteur est ouvert avec 10+ catégories, **When** la recherche est activée (automatiquement si >= 5 catégories), **Then** un champ de recherche est visible en haut du sélecteur.
2. **Given** le champ de recherche est visible, **When** l'utilisateur tape "ali", **Then** seules les catégories dont le nom contient "ali" sont affichées (ex: "Alimentation"), insensible à la casse.
3. **Given** l'utilisateur a tapé un terme ne correspondant à aucune catégorie, **When** la liste filtrée est vide, **Then** un message "Aucune catégorie" est affiché.

---

### User Story 3 — Affichage riche avec emoji et couleur (Priority: P2)

Chaque catégorie possède une icône emoji et une couleur associée. Le sélecteur affiche ces attributs visuels pour permettre une identification rapide et intuitive des catégories.

**Why this priority**: Améliore significativement la reconnaissance visuelle et la rapidité de sélection, mais le widget fonctionne même sans cet affichage enrichi.

**Independent Test**: Peut être testé en fournissant des catégories avec icônes et couleurs variées et en vérifiant le rendu visuel.

**Acceptance Scenarios**:

1. **Given** une catégorie avec l'icône "🍔" et la couleur rouge, **When** le sélecteur affiche cette catégorie, **Then** l'icône emoji est visible à gauche et un indicateur de couleur (pastille circulaire) est affiché.
2. **Given** une catégorie sans couleur définie, **When** le sélecteur affiche cette catégorie, **Then** l'icône emoji est affichée mais aucune pastille de couleur n'apparaît.
3. **Given** une catégorie est sélectionnée, **When** le trigger (champ fermé) l'affiche, **Then** l'icône emoji et le nom de la catégorie sont visibles dans le champ.

---

### User Story 4 — Effacement de la sélection (Priority: P2)

L'utilisateur peut effacer la catégorie sélectionnée pour laisser le champ vide, si le champ est configuré comme effaçable.

**Why this priority**: Permet la correction d'erreur de saisie et les cas où la catégorie est optionnelle dans un formulaire.

**Independent Test**: Peut être testé en sélectionnant une catégorie puis en vérifiant que le bouton d'effacement remet le champ à vide.

**Acceptance Scenarios**:

1. **Given** une catégorie est sélectionnée et le champ est configuré `clearable`, **When** l'utilisateur appuie sur le bouton d'effacement (×), **Then** la sélection est supprimée, le placeholder réapparaît et la valeur du formulaire est nulle.
2. **Given** aucune catégorie n'est sélectionnée, **When** l'utilisateur regarde le champ, **Then** le bouton d'effacement n'est pas visible.

---

### User Story 5 — Validation de formulaire (Priority: P2)

Le champ CategoryPicker s'intègre au système de validation des formulaires. Si la catégorie est requise et non renseignée, un message d'erreur s'affiche.

**Why this priority**: Garantit l'intégrité des données dans les formulaires qui l'utilisent. Le widget fonctionne sans validation mais les formulaires parents en ont besoin.

**Independent Test**: Peut être testé en soumettant un formulaire avec un CategoryPicker requis sans sélection et en vérifiant l'affichage du message d'erreur.

**Acceptance Scenarios**:

1. **Given** un CategoryPicker avec une validation "requis", **When** le formulaire est soumis sans sélection, **Then** un message d'erreur est affiché sous le champ.
2. **Given** un CategoryPicker avec une validation "requis" et un message d'erreur affiché, **When** l'utilisateur sélectionne une catégorie, **Then** le message d'erreur disparaît.

---

### User Story 6 — Création de catégorie inline (Priority: P2)

Quand l'utilisateur recherche une catégorie qui n'existe pas, un bouton "+ Créer [terme]" apparaît en bas de la liste filtrée. En appuyant dessus, le widget notifie le parent via un callback avec le terme de recherche, permettant au parent d'ouvrir un formulaire de création adapté.

**Why this priority**: Fonctionnalité clé du composant Angular de référence. Permet un flux de saisie fluide sans quitter le contexte du formulaire. Mais le widget reste fonctionnel sans cette feature (sélection parmi les existantes).

**Independent Test**: Peut être testé en fournissant un callback `onCreateRequested` et en vérifiant qu'il est appelé avec le bon terme quand le bouton est appuyé.

**Acceptance Scenarios**:

1. **Given** le sélecteur est ouvert, un callback `onCreateRequested` est fourni, et l'utilisateur tape "Voyages", **When** aucune catégorie ne correspond au terme (liste filtrée vide), **Then** un bouton "+ Créer « Voyages »" apparaît à la place du message "Aucune catégorie".
2. **Given** le bouton "+ Créer « Voyages »" est visible, **When** l'utilisateur appuie dessus, **Then** le callback `onCreateRequested` est appelé avec "Voyages" comme argument et le sélecteur se ferme.
3. **Given** le sélecteur est ouvert, un callback `onCreateRequested` est fourni, et l'utilisateur tape "ali", **When** des catégories correspondent partiellement (ex: "Alimentation"), **Then** seules les catégories filtrées sont affichées, SANS bouton "+ Créer".
4. **Given** le sélecteur est ouvert SANS callback `onCreateRequested` fourni, **When** l'utilisateur tape un terme sans résultat, **Then** le message "Aucune catégorie" est affiché (pas de bouton "+ Créer").

---

### User Story 7 — Accessibilité (Priority: P3)

Le widget est accessible aux technologies d'assistance : les éléments ont des labels sémantiques, les états de sélection sont annoncés et la navigation est cohérente.

**Why this priority**: Bonne pratique indispensable mais n'empêche pas l'utilisation du widget pour la majorité des utilisateurs.

**Independent Test**: Peut être testé via les outils de sémantique Flutter pour vérifier les labels et les états.

**Acceptance Scenarios**:

1. **Given** le CategoryPicker est rendu, **When** un lecteur d'écran parcourt le champ, **Then** il annonce le label, la valeur sélectionnée (ou le placeholder) et le rôle "bouton".
2. **Given** le sélecteur est ouvert, **When** un lecteur d'écran parcourt les catégories, **Then** chaque catégorie est identifiable par son nom et son état (sélectionné ou non).

---

### Edge Cases

- Que se passe-t-il quand la liste de catégories est vide ? Le sélecteur affiche un message "Aucune catégorie" et ne permet pas de sélection.
- Que se passe-t-il quand la catégorie actuellement sélectionnée est retirée de la liste ? La sélection est automatiquement réinitialisée à nulle et le callback de changement est appelé.
- Que se passe-t-il quand le champ est désactivé ? L'apparence est atténuée et l'appui sur le champ ne déclenche rien.
- Que se passe-t-il quand un nom de catégorie est très long ? Le texte est tronqué avec des points de suspension (ellipsis).
- Que se passe-t-il quand l'utilisateur sélectionne la même catégorie déjà choisie ? Le sélecteur se ferme sans déclencher de callback (pas de double événement).
- Que se passe-t-il en mode sombre ? Les couleurs s'adaptent au thème via les design tokens.
- Que se passe-t-il quand la recherche retourne des résultats partiels ? Seules les catégories filtrées sont affichées, sans bouton "+ Créer" (le bouton n'apparaît que quand la liste filtrée est vide).
- Que se passe-t-il quand aucun callback `onCreateRequested` n'est fourni ? Le bouton "+ Créer" n'apparaît jamais, le widget fonctionne en mode sélection pure.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le widget DOIT afficher un champ trigger avec un label, la catégorie sélectionnée (icône + nom) ou un placeholder si rien n'est sélectionné.
- **FR-002**: Le widget DOIT ouvrir un sélecteur modal (bottom sheet sur mobile, dialog sur tablette) contenant la liste des catégories lorsque l'utilisateur appuie sur le trigger.
- **FR-003**: Chaque catégorie dans le sélecteur DOIT afficher son icône emoji et son nom. Si une couleur est définie, une pastille circulaire colorée DOIT être affichée.
- **FR-004**: Le widget DOIT permettre la recherche/filtrage des catégories par nom, insensible à la casse, avec affichage automatique si le nombre de catégories atteint un seuil configurable (défaut : 5).
- **FR-005**: Le widget DOIT appeler un callback lorsqu'une catégorie différente est sélectionnée, en fournissant l'identifiant de la catégorie.
- **FR-006**: Le widget DOIT supporter le mode effaçable (clearable) via un bouton × qui remet la sélection à nulle.
- **FR-007**: Le widget DOIT s'intégrer au système de formulaire pour la validation, la sauvegarde et la réinitialisation.
- **FR-008**: Le widget DOIT surligner visuellement la catégorie actuellement sélectionnée dans la liste.
- **FR-009**: Le widget DOIT réinitialiser automatiquement la sélection si la catégorie sélectionnée n'existe plus dans la liste fournie.
- **FR-010**: Le widget DOIT supporter un état désactivé (opacity réduite via le design token standard, pas d'interaction).
- **FR-011**: Le widget DOIT exposer un callback de changement de terme de recherche permettant au parent de réagir à la saisie.
- **FR-012**: Le widget DOIT afficher un bouton "+ Créer « [terme] »" à la place du message "Aucune catégorie" lorsque : (a) un callback `onCreateRequested` est fourni, (b) un terme de recherche est saisi, et (c) la liste filtrée est vide (aucune catégorie ne contient le terme). Si des résultats partiels existent, le bouton NE DOIT PAS apparaître.
- **FR-013**: Le bouton "+ Créer" DOIT appeler le callback `onCreateRequested` avec le terme de recherche en argument, puis fermer le sélecteur.
- **FR-014**: Si aucun callback `onCreateRequested` n'est fourni, le bouton "+ Créer" NE DOIT PAS apparaître, quel que soit le terme de recherche.
- **FR-015**: Le widget DOIT respecter les design tokens existants (espacement, typographie, couleurs, rayons) et le thème clair/sombre.
- **FR-016**: Le widget DOIT fournir des informations sémantiques d'accessibilité (label du trigger, état de sélection de chaque catégorie, rôle bouton).

### Key Entities

- **Category** : Représente une catégorie de dépense/recette. Attributs clés : identifiant unique, nom textuel, icône emoji (chaîne Unicode), couleur (optionnelle), indicateur système (créée par le système vs par l'utilisateur).
- **CategoryPickerItem** : Représentation d'une catégorie adaptée pour le sélecteur. Dérivée de Category, contient les champs nécessaires à l'affichage dans le SelectPicker (id, label, icône, couleur).

## Assumptions

- Le widget réutilise le SelectPicker existant (feature 039) comme composant de sélection sous-jacent, en le configurant avec les données de catégorie.
- La liste des catégories est fournie au widget par le parent — le widget ne charge pas lui-même les données depuis une API. C'est le formulaire parent qui gère l'appel au service de catégories.
- La création de catégorie inline est gérée via un callback `onCreateRequested(searchTerm)` délégué au parent. Le widget affiche le bouton "+ Créer" et notifie le parent, mais ne contient pas de formulaire de création (CategoryForm). Le parent est responsable d'ouvrir le formulaire approprié et de mettre à jour la liste des catégories.
- Les couleurs de catégorie sont des valeurs de couleur (code hex ou équivalent) ; le widget affiche une pastille circulaire de cette couleur.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut sélectionner une catégorie parmi une liste en 2 interactions maximum (appui sur le champ + appui sur la catégorie).
- **SC-002**: La recherche filtre les catégories en temps réel dès le premier caractère saisi (filtrage local synchrone, sans latence perceptible).
- **SC-003**: 100% des scénarios d'acceptation sont couverts par des tests automatisés.
- **SC-004**: Le widget est utilisable dans au moins 3 formulaires différents (transaction, abonnement, dette) sans modification de son interface.
- **SC-005**: Le widget s'affiche correctement en thème clair et sombre sans régression visuelle.
