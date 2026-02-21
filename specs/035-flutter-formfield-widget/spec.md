# Feature Specification: Widget FormField

**Feature Branch**: `035-flutter-formfield-widget`
**Created**: 2026-02-21
**Status**: Draft
**Linear**: KKS-95
**Input**: Wrapper de champ de formulaire avec label, message d'erreur, style iOS (bg gris, pas de bordure, radius xl). Ref: app-form-field Angular.

## Clarifications

### Session 2026-02-21

- Q: Le conteneur doit-il changer visuellement quand le champ enfant a le focus ? → A: Oui, bordure subtile couleur primaire (amber) au focus.

## User Scenarios & Testing

### User Story 1 - Affichage d'un champ de formulaire avec label (Priority: P1)

Un développeur intègre le widget FormField dans un écran de saisie. Le widget affiche un label au-dessus du champ, le champ enfant (texte, sélecteur, etc.) dans un conteneur au style iOS (fond gris secondaire, pas de bordure visible, coins arrondis xl), et aucun message d'erreur par défaut.

**Why this priority**: C'est le cas d'usage principal — sans le rendu de base avec label et conteneur stylé, le widget n'a aucune utilité.

**Independent Test**: Peut être testé en plaçant un champ texte dans le widget et en vérifiant que le label s'affiche, que le conteneur a le bon style (fond, radius, pas de bordure), et que le champ enfant est visible.

**Acceptance Scenarios**:

1. **Given** un widget FormField avec un label "Montant" et un champ texte enfant, **When** le widget est rendu, **Then** le label "Montant" apparaît au-dessus du champ, le champ est dans un conteneur à fond gris sans bordure avec des coins arrondis xl (16px).
2. **Given** un widget FormField sans erreur, **When** le widget est rendu, **Then** aucun message d'erreur n'est visible.
3. **Given** un widget FormField en thème sombre, **When** le widget est rendu, **Then** le conteneur utilise la couleur de surface secondaire du thème sombre, et le label reste lisible.
4. **Given** un widget FormField avec un champ texte enfant, **When** le champ reçoit le focus, **Then** le conteneur affiche une bordure subtile de couleur primaire (amber).
5. **Given** un widget FormField avec un champ texte enfant focusé, **When** le champ perd le focus, **Then** la bordure disparaît et le conteneur revient à son état normal (sans bordure).

---

### User Story 2 - Affichage des erreurs de validation (Priority: P2)

Lorsqu'un champ est en erreur (validation échouée), le widget affiche un message d'erreur sous le conteneur du champ, dans une couleur d'alerte. Le message n'apparaît que lorsqu'on le demande explicitement.

**Why this priority**: L'affichage des erreurs est essentiel pour guider l'utilisateur mais dépend du rendu de base (US1).

**Independent Test**: Peut être testé en passant un message d'erreur et un indicateur d'erreur active, puis en vérifiant que le texte d'erreur apparaît sous le champ avec la bonne couleur.

**Acceptance Scenarios**:

1. **Given** un widget FormField avec `showError` activé et un message "Ce champ est requis", **When** le widget est rendu, **Then** le message "Ce champ est requis" apparaît sous le conteneur en couleur d'erreur (rouge).
2. **Given** un widget FormField avec `showError` désactivé, **When** le widget est rendu, **Then** aucun message d'erreur n'est visible, même si un message est fourni.
3. **Given** un widget FormField qui passe de l'état sans erreur à l'état avec erreur, **When** `showError` est activé, **Then** le message d'erreur apparaît avec une transition fluide.

---

### User Story 3 - Composition avec différents types de champs (Priority: P3)

Le widget FormField accepte n'importe quel widget enfant comme contenu du champ (champ texte, sélecteur, switch, widget personnalisé). Il se comporte comme un conteneur générique qui ne connaît pas le type de champ qu'il enveloppe.

**Why this priority**: La flexibilité de composition est importante pour la réutilisabilité dans toute l'application, mais nécessite que le rendu de base fonctionne d'abord.

**Independent Test**: Peut être testé en plaçant différents types de widgets enfants (texte, dropdown, switch) et en vérifiant qu'ils s'affichent correctement dans le conteneur.

**Acceptance Scenarios**:

1. **Given** un widget FormField contenant un champ texte, **When** le widget est rendu, **Then** le champ texte est affiché à l'intérieur du conteneur stylé avec le label au-dessus.
2. **Given** un widget FormField contenant un sélecteur (dropdown), **When** le widget est rendu, **Then** le sélecteur est affiché à l'intérieur du conteneur stylé avec le même espacement et style.
3. **Given** un widget FormField contenant un widget personnalisé, **When** le widget est rendu, **Then** le widget est affiché sans conflit de style avec le conteneur parent.

---

### User Story 4 - Accessibilité (Priority: P4)

Le widget FormField associe sémantiquement le label au champ enfant pour les lecteurs d'écran. Lorsqu'un message d'erreur est affiché, il est annoncé aux technologies d'assistance.

**Why this priority**: L'accessibilité est indispensable mais constitue une couche d'enrichissement au-dessus du rendu visuel.

**Independent Test**: Peut être testé via les outils d'accessibilité en vérifiant que le label est associé au champ et que les erreurs sont annoncées.

**Acceptance Scenarios**:

1. **Given** un widget FormField avec le label "Email", **When** un lecteur d'écran parcourt le formulaire, **Then** le champ est annoncé avec son label "Email".
2. **Given** un widget FormField en état d'erreur avec le message "Format invalide", **When** l'erreur apparaît, **Then** le message est annoncé par le lecteur d'écran via une notification live region.

---

### Edge Cases

- Que se passe-t-il quand le label est vide ou très long (>50 caractères) ? Le label doit être tronqué avec ellipsis si nécessaire, sans casser la mise en page.
- Que se passe-t-il quand le message d'erreur est très long (>100 caractères) ? Le message doit s'afficher sur plusieurs lignes sans débordement.
- Que se passe-t-il quand le widget enfant a une hauteur variable (ex: champ texte multiligne) ? Le conteneur doit s'adapter à la hauteur du contenu.
- Que se passe-t-il quand le widget est dans un espace très étroit (<200px de large) ? Le widget doit rester utilisable sans chevauchement.
- Comment le widget se comporte-t-il pendant les animations de transition de page ? Le widget ne doit pas avoir de glitch visuel.

## Requirements

### Functional Requirements

- **FR-001**: Le widget DOIT afficher un label textuel au-dessus du champ enfant, séparé par un espacement de 8px.
- **FR-002**: Le widget DOIT envelopper le champ enfant dans un conteneur avec un fond de couleur secondaire (gris clair en thème clair, gris foncé en thème sombre).
- **FR-003**: Le conteneur DOIT avoir des coins arrondis xl (16px) et aucune bordure visible en état normal (repos).
- **FR-004**: Le conteneur DOIT afficher une bordure de 1.5px de couleur primaire (amber) lorsque le champ enfant a le focus, et la retirer lorsque le focus est perdu.
- **FR-005**: Le widget DOIT accepter n'importe quel widget enfant via composition (slot de contenu), sans imposer de type spécifique.
- **FR-006**: Le widget DOIT afficher conditionnellement un message d'erreur sous le conteneur, contrôlé par un indicateur booléen (`showError`).
- **FR-007**: Le message d'erreur DOIT être affiché en couleur d'erreur du thème (rouge) avec une taille de texte réduite (12px).
- **FR-008**: Le label DOIT utiliser la couleur de texte secondaire du thème et une taille de texte de 14px avec un poids medium.
- **FR-009**: Le conteneur DOIT avoir un padding interne de 12px vertical et 16px horizontal.
- **FR-010**: Le widget DOIT supporter les thèmes clair et sombre sans configuration supplémentaire, en utilisant les couleurs sémantiques du thème.
- **FR-011**: Le widget DOIT fournir une sémantique d'accessibilité associant le label au champ et annonçant les erreurs.
- **FR-012**: Le widget DOIT être un composant purement visuel, sans logique métier ni gestion d'état interne.
- **FR-013**: Le widget DOIT s'adapter à la largeur disponible (100% de la largeur du parent).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Le widget est utilisable dans au moins 3 contextes de formulaire différents (texte, sélecteur, switch) sans modification.
- **SC-002**: 100% des tests unitaires passent couvrant les 4 user stories (rendu label, erreurs, composition, accessibilité).
- **SC-003**: Le widget s'affiche correctement en thème clair et sombre sans régression visuelle.
- **SC-004**: L'analyse statique du code ne produit aucun avertissement lié au widget.
- **SC-005**: Le widget respecte les guidelines d'accessibilité : label sémantique associé et erreurs annoncées.

## Assumptions

- Le widget utilise exclusivement les tokens de design existants du projet (espacement, radius, couleurs, typographie) sans en créer de nouveaux.
- Le style "iOS" mentionné dans la description fait référence au pattern visuel (fond gris, pas de bordure, radius arrondi) et non à l'utilisation de composants Cupertino.
- Le widget ne gère pas la validation lui-même — il reçoit `showError` et `errorMessage` de l'extérieur.
- Le padding interne (12px/16px) correspond aux tokens existants `space3` et `space4`.
- Le widget suit le même pattern architectural que le `ListItem` existant : composant immutable, sans logique métier, acceptant des données pré-formatées.
