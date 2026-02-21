# Feature Specification: Flutter — Système Modal / Bottom Sheet

**Feature Branch**: `036-flutter-modal-system`
**Created**: 2026-02-21
**Status**: Ready for Implementation
**Input**: KKS-94 — Système de modales global dans le shell. Bottom sheet sur mobile, dialog sur tablette. Header avec toggle type (Dépense/Recette, Mensuel/Annuel, Emprunt/Prêt). Ref: modal Angular + shell.html.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ouvrir une modale de création depuis le menu FAB (Priority: P1)

L'utilisateur appuie sur le bouton flottant (+) depuis n'importe quel écran de l'application, puis sélectionne le type d'élément à créer (transaction, abonnement, dette, virement). Une modale s'ouvre en bottom sheet sur mobile ou en dialog centré sur tablette, affichant un header avec le titre correspondant et un bouton de fermeture.

**Why this priority** : C'est le point d'entrée principal de toute saisie dans l'application. Sans cette modale, aucune création n'est possible sur mobile Flutter. C'est le socle sur lequel reposent toutes les autres stories.

**Independent Test** : Peut être testé en appuyant sur le FAB, en sélectionnant un type, et en vérifiant que la modale s'ouvre avec le bon titre. Délivre la structure visuelle de base pour la saisie.

**Acceptance Scenarios** :

1. **Given** l'utilisateur est sur un écran quelconque du shell, **When** il appuie sur le FAB (+) puis sélectionne "Transaction", **Then** une modale s'ouvre avec le titre "Nouvelle transaction" et un bouton de fermeture.
2. **Given** l'utilisateur est sur mobile, **When** la modale s'ouvre, **Then** elle apparaît en bottom sheet glissant depuis le bas de l'écran.
3. **Given** l'utilisateur est sur tablette, **When** la modale s'ouvre, **Then** elle apparaît en dialog centré avec un overlay sombre.
4. **Given** la modale est ouverte, **When** l'utilisateur appuie sur le bouton de fermeture (×), **Then** la modale se ferme et l'écran précédent est restauré.
5. **Given** la modale est ouverte en bottom sheet, **When** l'utilisateur glisse vers le bas (swipe down), **Then** la modale se ferme.
6. **Given** la modale est ouverte en dialog, **When** l'utilisateur appuie sur l'overlay sombre, **Then** la modale se ferme.

---

### User Story 2 - Basculer le type via le toggle dans le header (Priority: P1)

Lorsqu'une modale est ouverte pour une transaction, un abonnement ou une dette, un toggle apparaît dans le header permettant de basculer entre les sous-types : Dépense/Recette pour les transactions, Mensuel/Annuel pour les abonnements, Emprunt/Prêt pour les dettes. Le toggle reflète visuellement le choix actif.

**Why this priority** : Le toggle fait partie intégrante du header de la modale et conditionne le type de données soumises. C'est indissociable de l'ouverture de la modale pour offrir une saisie complète.

**Independent Test** : Peut être testé en ouvrant une modale de transaction et en basculant entre Dépense et Recette. Le toggle doit changer visuellement et le type doit être reflété.

**Acceptance Scenarios** :

1. **Given** la modale "Nouvelle transaction" est ouverte, **When** elle s'affiche, **Then** le toggle Dépense/Recette est visible dans le header avec "Dépense" sélectionné par défaut.
2. **Given** le toggle affiche "Dépense" comme actif, **When** l'utilisateur appuie sur "Recette", **Then** "Recette" devient actif visuellement et le type bascule.
3. **Given** la modale "Nouvel abonnement" est ouverte, **When** elle s'affiche, **Then** le toggle Mensuel/Annuel est visible avec "Mensuel" sélectionné par défaut.
4. **Given** la modale "Nouvelle dette" est ouverte, **When** elle s'affiche, **Then** le toggle Emprunt/Prêt est visible avec "Emprunt" sélectionné par défaut.
5. **Given** la modale "Virement" ou "Catégorie" ou "Compte" est ouverte, **When** elle s'affiche, **Then** aucun toggle n'apparaît dans le header.

---

### User Story 3 - Ouvrir une modale en mode édition (Priority: P2)

L'utilisateur appuie sur un élément existant (transaction, abonnement, dette) dans une liste. La modale s'ouvre en mode édition avec le titre adapté ("Modifier la transaction", etc.) et le toggle positionné sur le type de l'élément (ex. "Recette" si la transaction est de type recette).

**Why this priority** : L'édition est essentielle mais secondaire par rapport à la création. Elle réutilise la même modale avec un état initial différent.

**Independent Test** : Peut être testé en sélectionnant un élément existant dans une liste et en vérifiant que la modale s'ouvre avec le bon titre et le bon état du toggle.

**Acceptance Scenarios** :

1. **Given** l'utilisateur consulte la liste des transactions, **When** il appuie sur une transaction de type "Recette", **Then** la modale s'ouvre avec le titre "Modifier la transaction" et le toggle positionné sur "Recette".
2. **Given** l'utilisateur consulte la liste des abonnements, **When** il appuie sur un abonnement annuel, **Then** la modale s'ouvre avec le titre "Modifier l'abonnement" et le toggle positionné sur "Annuel".
3. **Given** la modale est ouverte en mode édition, **When** l'utilisateur ferme sans sauvegarder, **Then** aucune modification n'est appliquée.

---

### User Story 4 - Gestion de l'état de la modale depuis n'importe quel écran (Priority: P2)

La modale est contrôlée par un état global dans le shell. N'importe quel écran ou composant peut demander l'ouverture d'une modale de création ou d'édition. L'état centralisé garantit qu'une seule modale est ouverte à la fois.

**Why this priority** : L'architecture centralisée est nécessaire pour éviter les conflits d'état et permettre l'ouverture depuis plusieurs points de l'application (FAB, tap sur un item, action contextuelle).

**Independent Test** : Peut être testé en déclenchant l'ouverture depuis le FAB puis depuis un tap sur un item, et en vérifiant qu'une seule modale est affichée.

**Acceptance Scenarios** :

1. **Given** aucune modale n'est ouverte, **When** un écran demande l'ouverture d'une modale "transaction", **Then** la modale s'ouvre.
2. **Given** une modale est déjà ouverte, **When** une autre demande d'ouverture arrive, **Then** la modale actuelle se ferme d'abord, puis la nouvelle s'ouvre.
3. **Given** une modale est ouverte, **When** elle est fermée, **Then** l'état global reflète qu'aucune modale n'est active.

---

### User Story 5 - Accessibilité de la modale (Priority: P3)

La modale est utilisable avec les technologies d'assistance. Le focus est piégé à l'intérieur de la modale quand elle est ouverte. Les éléments sont correctement labellisés pour les lecteurs d'écran.

**Why this priority** : L'accessibilité est importante mais peut être affinée après la mise en place du système fonctionnel.

**Independent Test** : Peut être testé en activant un lecteur d'écran et en naviguant dans la modale. Le focus doit rester dans la modale et les éléments doivent être annoncés correctement.

**Acceptance Scenarios** :

1. **Given** la modale est ouverte, **When** l'utilisateur navigue avec un lecteur d'écran, **Then** le titre de la modale est annoncé et le focus est placé sur le premier élément interactif.
2. **Given** la modale est ouverte, **When** l'utilisateur tente de naviguer en dehors de la modale avec Tab, **Then** le focus reste à l'intérieur de la modale.
3. **Given** le toggle est affiché, **When** un lecteur d'écran le décrit, **Then** il annonce le rôle (groupe de boutons), l'option active et les options disponibles.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur tourne l'appareil (rotation portrait/paysage) pendant que la modale est ouverte ? La modale doit s'adapter sans se fermer ni perdre son contenu.
- Que se passe-t-il si l'utilisateur revient en arrière (bouton retour système Android) avec une modale ouverte ? La modale doit se fermer au lieu de quitter l'écran.
- Que se passe-t-il si la modale est ouverte et que l'application passe en arrière-plan puis revient au premier plan ? La modale doit rester dans son état actuel.
- Que se passe-t-il sur un écran très petit (SE / mini) ? Le bottom sheet doit occuper au maximum 90% de la hauteur de l'écran avec scroll interne si nécessaire.
- Que se passe-t-il si le clavier virtuel apparaît dans la modale (champ de saisie focus) ? La modale doit se repositionner pour que le champ actif reste visible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : Le système DOIT afficher une modale en bottom sheet sur mobile et en dialog centré sur tablette lorsque l'utilisateur déclenche une action de création ou d'édition.
- **FR-002** : Le système DOIT permettre la fermeture de la modale par le bouton ×, le swipe vers le bas (mobile), le tap sur l'overlay (tablette), et le bouton retour système (Android).
- **FR-003** : Le système DOIT afficher un toggle dans le header de la modale pour les types suivants : Dépense/Recette (transaction), Mensuel/Annuel (abonnement), Emprunt/Prêt (dette).
- **FR-004** : Le toggle DOIT être initialisé au premier choix en mode création (Dépense, Mensuel, Emprunt) et au type de l'entité en mode édition.
- **FR-005** : Le système DOIT adapter le titre de la modale selon le mode (création : "Nouveau/Nouvelle [type]", édition : "Modifier le/la [type]").
- **FR-006** : Le système DOIT garantir qu'une seule modale est ouverte simultanément.
- **FR-007** : Le système DOIT supporter les types de modale suivants : transaction, abonnement, dette, virement, catégorie, compte.
- **FR-008** : Le système DOIT animer l'ouverture et la fermeture de la modale (glissement vertical pour le bottom sheet, fade + scale pour le dialog).
- **FR-009** : Le système DOIT piéger le focus à l'intérieur de la modale et le restaurer à la fermeture.
- **FR-010** : Le bottom sheet DOIT occuper au maximum 90% de la hauteur de l'écran et permettre le scroll interne si le contenu dépasse.
- **FR-011** : La modale DOIT survivre à la rotation d'écran et au passage en arrière-plan sans perdre son état ni son contenu.
- **FR-012** : Le système DOIT repositionner la modale lorsque le clavier virtuel apparaît pour garder le champ actif visible.

### Key Entities

- **Modal** : Représente l'état d'une modale ouverte. Attributs : type (transaction, abonnement, dette, virement, catégorie, compte), mode (création ou édition), entité en cours d'édition (nullable), sous-type actif du toggle (dépend du type de modale).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : L'utilisateur peut ouvrir une modale de création en 2 taps maximum (FAB → type) depuis n'importe quel écran.
- **SC-002** : L'utilisateur peut basculer entre les sous-types (Dépense/Recette, etc.) en 1 tap sur le toggle, avec un retour visuel immédiat (< 100ms perçu).
- **SC-003** : La modale s'adapte automatiquement au format d'écran (bottom sheet mobile, dialog tablette) sans action de l'utilisateur.
- **SC-004** : La modale se ferme correctement via les 4 méthodes (bouton ×, swipe, overlay, retour système) dans 100% des cas.
- **SC-005** : L'ouverture et la fermeture de la modale sont animées de manière fluide, sans saccade perceptible sur des appareils de milieu de gamme.
- **SC-006** : Le toggle reflète correctement le type de l'entité existante en mode édition dans 100% des cas.

## Assumptions

- Le seuil de basculement entre mobile (bottom sheet) et tablette (dialog) est basé sur la largeur d'écran, cohérent avec le seuil déjà utilisé dans le shell adaptatif existant (768px).
- Les modales de virement, catégorie et compte n'ont pas de toggle dans le header (pas de sous-type).
- Le contenu des formulaires (champs de saisie) sera implémenté dans une feature ultérieure. Cette spec couvre uniquement le système de modale et son header avec toggle.
- L'animation du bottom sheet suit le pattern Material Design (glissement vertical avec courbe d'accélération standard).
- Le titre en mode édition utilise le genre grammatical adapté : "Modifier la transaction", "Modifier l'abonnement", "Modifier la dette", "Modifier le virement", "Modifier la catégorie", "Modifier le compte".
