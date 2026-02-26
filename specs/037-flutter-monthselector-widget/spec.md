# Feature Specification: Flutter MonthSelector Widget

**Feature Branch**: `037-flutter-monthselector-widget`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "KKS-100 — Flutter: Widget MonthSelector. Sélecteur de mois avec boutons précédent/suivant et label formaté. Utilisé sur dashboard et transactions. Ref: month-selector Angular."
**Linear**: [KKS-100](https://linear.app/kksdev/issue/KKS-100/flutter-widget-monthselector)

## Clarifications

### Session 2026-02-21

- Q: Le widget gère-t-il son propre état (uncontrolled) ou est-il contrôlé par le parent ? → A: Interne (uncontrolled) — Le widget gère son état après initialisation, notifie via onChanged(month, year). Aligné avec la référence Angular.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Naviguer entre les mois (Priority: P1)

L'utilisateur visualise le mois courant affiché sous forme de label textuel (ex : "Février 2026") et peut naviguer vers le mois précédent ou suivant en appuyant sur les boutons fléchés de chaque côté du label.

**Why this priority** : C'est la fonctionnalité fondamentale du widget. Sans la navigation mois par mois, le composant n'a aucune utilité.

**Independent Test** : Peut être testé en affichant le widget isolément, en tapant sur les boutons et en vérifiant que le label change correctement.

**Acceptance Scenarios** :

1. **Given** le widget est affiché avec le mois de février 2026, **When** l'utilisateur appuie sur le bouton suivant, **Then** le label affiche "Mars 2026"
2. **Given** le widget est affiché avec le mois de janvier 2025, **When** l'utilisateur appuie sur le bouton précédent, **Then** le label affiche "Décembre 2024" (changement d'année)
3. **Given** le widget est affiché avec le mois de décembre 2025, **When** l'utilisateur appuie sur le bouton suivant, **Then** le label affiche "Janvier 2026" (changement d'année)
4. **Given** le widget vient d'être créé sans mois initial spécifié, **When** il s'affiche, **Then** le label affiche le mois et l'année en cours

---

### User Story 2 - Notifier le parent du changement de mois (Priority: P1)

Lorsque l'utilisateur navigue vers un autre mois, le widget notifie son parent (dashboard, transactions) du nouveau mois et de la nouvelle année sélectionnés afin que le parent puisse recharger ses données.

**Why this priority** : Sans notification au parent, la navigation de mois est purement visuelle et n'a pas d'effet sur les données affichées. Indissociable de US1.

**Independent Test** : Peut être testé en écoutant le callback du widget et en vérifiant les valeurs mois/année transmises.

**Acceptance Scenarios** :

1. **Given** le widget affiche février 2026, **When** l'utilisateur appuie sur suivant, **Then** le callback transmet mois=3, année=2026
2. **Given** le widget affiche janvier 2025, **When** l'utilisateur appuie sur précédent, **Then** le callback transmet mois=12, année=2024

---

### User Story 3 - S'intégrer visuellement au design system (Priority: P2)

Le widget respecte les tokens du design system (couleurs, typographie, espacements, ombres, rayons) et s'adapte au thème clair et sombre.

**Why this priority** : La cohérence visuelle est importante mais le widget fonctionne même sans polish stylistique parfait.

**Independent Test** : Peut être testé en rendant le widget en thème clair et sombre, en vérifiant les couleurs, tailles et espacements appliqués.

**Acceptance Scenarios** :

1. **Given** le thème clair est actif, **When** le widget est affiché, **Then** les boutons et le label utilisent les couleurs du thème clair
2. **Given** le thème sombre est actif, **When** le widget est affiché, **Then** les boutons et le label s'adaptent aux couleurs du thème sombre
3. **Given** le widget est affiché, **When** on inspecte les styles, **Then** aucune valeur n'est hardcodée (tout passe par les tokens)

---

### User Story 4 - Accessibilité (Priority: P2)

Le widget est utilisable par les technologies d'assistance (lecteurs d'écran). Les boutons ont des labels sémantiques et le label du mois est annoncé correctement.

**Why this priority** : L'accessibilité est une exigence de qualité mais ne bloque pas l'utilisation standard.

**Independent Test** : Peut être testé en vérifiant les propriétés Semantics des boutons et du label.

**Acceptance Scenarios** :

1. **Given** un lecteur d'écran est actif, **When** le focus est sur le bouton précédent, **Then** il est annoncé comme "Mois précédent"
2. **Given** un lecteur d'écran est actif, **When** le focus est sur le bouton suivant, **Then** il est annoncé comme "Mois suivant"
3. **Given** un lecteur d'écran est actif, **When** le mois change, **Then** le nouveau label est annoncé

---

### Edge Cases

- Que se passe-t-il lors du passage de décembre à janvier (incrémentation de l'année) ?
- Que se passe-t-il lors du passage de janvier à décembre (décrémentation de l'année) ?
- Comment le label s'affiche-t-il si le mois a un nom long (ex : "Septembre 2026") ou court (ex : "Mai 2026") — la largeur minimale doit être suffisante ?
- Comment le widget se comporte-t-il dans un conteneur étroit ?
- Que se passe-t-il si `initialMonth` est hors plage (0, 13, -1) ou `initialYear` est invalide ? Le widget DOIT fallback sur le mois/année courant.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : Le widget DOIT afficher un label textuel représentant le mois et l'année sélectionnés, formaté en français avec le nom complet du mois et l'année (ex : "Février 2026"), première lettre en majuscule
- **FR-002** : Le widget DOIT afficher un bouton de navigation vers le mois précédent (flèche gauche) et un bouton vers le mois suivant (flèche droite)
- **FR-003** : Appuyer sur le bouton précédent DOIT décrémenter le mois de 1, avec passage automatique de janvier à décembre de l'année précédente
- **FR-004** : Appuyer sur le bouton suivant DOIT incrémenter le mois de 1, avec passage automatique de décembre à janvier de l'année suivante
- **FR-005** : Le widget DOIT notifier son parent à chaque changement de mois via un callback transmettant le mois (1-12) et l'année
- **FR-006** : Le widget DOIT accepter un mois et une année initiaux en paramètres, avec le mois et l'année courants comme valeur par défaut. Si les valeurs sont hors plage (mois < 1 ou > 12), le widget DOIT utiliser le mois/année courants en fallback
- **FR-007** : Le widget DOIT utiliser exclusivement les tokens du design system (couleurs, typographie, espacements, ombres, rayons) sans aucune valeur hardcodée
- **FR-008** : Le widget DOIT s'adapter aux thèmes clair et sombre
- **FR-009** : Les boutons de navigation DOIVENT avoir des labels d'accessibilité sémantiques ("Mois précédent", "Mois suivant")
- **FR-010** : Le widget DOIT être un composant pur de présentation, réutilisable, sans logique métier ni dépendance à un service

### Key Entities

- **MonthYear** : Représente une sélection mois/année. Attributs : mois (entier 1-12), année (entier). Pas de persistance, valeur transitoire transmise via callback.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : L'utilisateur peut naviguer d'un mois à l'autre en un seul appui, avec retour visuel immédiat (label mis à jour)
- **SC-002** : Le passage d'année (décembre/janvier) fonctionne sans erreur ni délai perceptible
- **SC-003** : Le widget est visuellement cohérent entre thème clair et sombre en termes de lisibilité et de contraste
- **SC-004** : Le widget passe 100% des tests d'accessibilité sémantique (labels boutons, annonce du mois)
- **SC-005** : Le widget est réutilisable sur au moins 2 écrans (dashboard, transactions) sans modification

## Assumptions

- Le formatage du mois utilise la locale française (`fr_FR`) avec `intl` (déjà disponible dans le projet)
- Le widget est un composant pur sans dépendance Riverpod — il gère son propre état interne (mois/année) après initialisation et notifie le parent via callback onChanged
- Les boutons utilisent des icônes Material (chevron_left / chevron_right) conformément aux conventions Flutter du projet
- La taille de touche des boutons respecte les guidelines Material (minimum 48x48dp)
- Le label a une largeur minimale suffisante pour le mois le plus long en français ("Septembre")
