# Research: Flutter — Système Modal / Bottom Sheet

**Feature**: 036-flutter-modal-system
**Date**: 2026-02-21

## R1. Approche modale adaptative : Bottom Sheet vs Dialog

**Decision** : Utiliser `showModalBottomSheet` sur mobile et `showDialog` sur tablette, avec un wrapper unique `AppModal` qui choisit la présentation selon la largeur d'écran (seuil 768px, cohérent avec `AdaptiveScaffold._breakpoint`).

**Rationale** :
- `showModalBottomSheet` est le pattern natif Material pour les actions modales sur mobile. Il supporte nativement le swipe-to-dismiss, l'overlay, le repositionnement clavier et les animations.
- `showDialog` est le pattern natif pour les écrans larges (tablette/desktop). Il supporte nativement l'overlay tap-to-dismiss et le focus trap.
- Un wrapper unique évite la duplication de logique et offre une API cohérente au reste de l'app.

**Alternatives considered** :
- `DraggableScrollableSheet` : Plus flexible pour le sizing dynamique, mais plus complexe à gérer (snap points, drag handles). Surdimensionné pour ce cas d'usage où le contenu est un formulaire fixe.
- Route GoRouter dédiée : Permet le deep linking mais complexifie l'état (URL = état modale). La modale n'est pas une destination de navigation, c'est une action contextuelle.
- Package tiers (`modal_bottom_sheet`, `wolt_modal_sheet`) : Ajoutent une dépendance externe pour un composant simple. Le SDK Flutter natif suffit.

## R2. Gestion d'état de la modale

**Decision** : Un `ModalNotifier` (Riverpod `Notifier<ModalState>`) centralisé, avec un état `ModalState` modélisé via `freezed` sealed class.

**Rationale** :
- Cohérent avec le pattern existant (`AuthNotifier`, `ThemeNotifier`, `OnboardingNotifier`).
- `freezed` sealed class permet de distinguer clairement `ModalClosed` et `ModalOpen(type, mode, entity, subType)`.
- Le notifier expose des méthodes simples : `open(type, entity?)`, `close()`, `setSubType(value)`.
- Accessible depuis n'importe quel widget via `ref.read(modalNotifierProvider.notifier)`.

**Alternatives considered** :
- State local dans le shell (`StatefulWidget`) : Ne permet pas l'ouverture depuis des écrans enfants sans callback drilling.
- `ValueNotifier` simple : Moins typé, pas de pattern matching sur l'état. Pas cohérent avec le projet.
- Plusieurs providers (un par type de modale) : Surdimensionné. Un seul provider suffit car une seule modale est ouverte à la fois (FR-006).

## R3. Widget toggle header

**Decision** : Un widget `AppToggle` réutilisable avec 2 options, utilisant `SegmentedButton` ou un custom widget avec 2 boutons dans un conteneur arrondi.

**Rationale** :
- Le toggle a toujours exactement 2 options dans ce projet (Dépense/Recette, Mensuel/Annuel, Emprunt/Prêt).
- Un widget custom offre un contrôle total sur le design (couleurs amber, radius, animations) cohérent avec le design system existant.
- `SegmentedButton` de Material 3 est une option mais son style par défaut ne correspond pas nécessairement au design system de l'app (tokens amber, radius custom).

**Alternatives considered** :
- `ToggleButtons` (Material) : API datée, styling limité, pas Material 3.
- `SegmentedButton` (Material 3) : Bonne base mais styling custom nécessaire pour matcher les design tokens. Possible mais impose des overrides de thème.
- `TabBar` : Sémantiquement incorrect (tabs = navigation entre pages, pas sélection de type).

## R4. Intégration avec le FAB menu existant

**Decision** : Modifier `FabMenu` pour appeler `ref.read(modalNotifierProvider.notifier).open(type)` au lieu d'afficher un SnackBar placeholder. Le shell écoute l'état du notifier et affiche/masque la modale en conséquence.

**Rationale** :
- Le FAB menu existe déjà avec les 4 actions (transaction, subscription, debt, transfer). Il suffit de remplacer le callback SnackBar par l'ouverture de la modale.
- Le shell (`_ShellScaffold`) observe `modalNotifierProvider` et déclenche `showModalBottomSheet` ou `showDialog` quand l'état passe à `ModalOpen`.

**Alternatives considered** :
- Ouvrir la modale directement dans le FAB : Couplage fort entre FAB et modale. Le notifier centralise et découple.
- Naviguer vers une route : La modale n'est pas une page, c'est une action contextuelle superposée.

## R5. Bouton retour Android (back button)

**Decision** : Utiliser `PopScope` (anciennement `WillPopScope`) pour intercepter le bouton retour quand la modale est ouverte. La modale se ferme au lieu de naviguer en arrière.

**Rationale** :
- `showModalBottomSheet` et `showDialog` gèrent nativement le bouton retour (ils sont des routes overlay dans le Navigator). Le dismiss via back button est donc gratuit.
- Pas besoin de `PopScope` custom si on utilise les APIs natives Flutter.

**Alternatives considered** :
- `PopScope` manuel : Nécessaire seulement si la modale est implémentée comme un widget overlay custom (non retenu).
- `GoRouter` custom pop : Surdimensionné, les modales ne sont pas des routes GoRouter.
