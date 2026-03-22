# Research: Flutter — Widget CategoryPicker

**Feature**: 040-flutter-categorypicker-widget
**Date**: 2026-02-22

## R1 — Stratégie d'intégration avec SelectPicker

**Question** : Le CategoryPicker doit-il wrapper SelectPicker ou construire son propre picker depuis AppModal ?

**Decision** : Wrapper SelectPicker avec un paramètre supplémentaire `emptyActionBuilder` ajouté à SelectPicker.

**Rationale** :
- Évite la duplication de code (trigger, modal, recherche, highlight, validation, accessibilité)
- Changement backward-compatible sur SelectPicker (paramètre optionnel, défaut `null`)
- Le CategoryPicker reste un widget léger (~80 lignes) qui mappe Category → SelectPickerItem et configure le builder pour le bouton "+ Créer"
- Pattern de composition propre : CategoryPicker est un StatelessWidget, SelectPicker reste le FormField

**Alternatives considered** :
- CategoryPicker comme FormField indépendant utilisant AppModal directement → rejeté : duplication massive (~300 lignes de code identique)
- Fork de SelectPicker en CategorySelectPicker → rejeté : divergence de maintenance entre les deux widgets

## R2 — Paramètre emptyActionBuilder pour SelectPicker

**Question** : Comment le bouton "+ Créer" s'intègre-t-il dans le modal de SelectPicker ?

**Decision** : Ajouter `Widget Function(String searchTerm)? emptyActionBuilder` à SelectPicker. Quand fourni et liste filtrée vide, ce builder est appelé à la place du `emptyMessage`.

**Rationale** :
- Modification minimale de SelectPicker (3 lignes dans `_buildItemsList`)
- Backward-compatible : sans ce paramètre, le comportement est identique
- Extensible : d'autres wrappers pourraient réutiliser ce slot (ex: AccountPicker avec "+ Ajouter un compte")

**Alternatives considered** :
- Slot `footer` toujours visible → rejeté : la spec dit que le bouton apparaît UNIQUEMENT quand la liste est vide
- Callback qui retourne un String pour le message → rejeté : le bouton "+ Créer" est un widget interactif, pas un simple texte

## R3 — Mapping Category → SelectPickerItem

**Question** : Comment convertir le modèle Freezed Category en SelectPickerItem ?

**Decision** : Méthode statique ou fonction de mapping dans CategoryPicker :
- `id` → `category.id`
- `label` → `category.nom`
- `icon` → `category.icone` (emoji Unicode)
- `color` → Parse `category.couleur` (hex string) en `Color`
- `secondaryText` → `null` (pas de texte secondaire pour les catégories)

**Rationale** :
- Le modèle Category (Freezed) a `couleur` comme String hex. Le SelectPickerItem attend `Color?`. La conversion hex → Color est nécessaire.
- L'icône est déjà un emoji Unicode, compatible directement avec SelectPickerItem.icon

**Alternatives considered** :
- Ajouter une méthode `toPickerItem()` sur Category → rejeté : couple le domain model avec un widget UI
- Type dédié CategoryPickerItem → rejeté : SelectPickerItem suffit, pas besoin d'un type intermédiaire

## R4 — Gestion du callback onCreateRequested et fermeture du modal

**Question** : Comment fermer le modal SelectPicker quand le bouton "+ Créer" est pressé ?

**Decision** : Le `emptyActionBuilder` construit un widget qui, lors du tap, appelle `Navigator.of(context).pop()` puis `onCreateRequested(searchTerm)`. Le contexte du builder a accès au Navigator via le contexte du modal.

**Rationale** :
- Pattern identique à `_onItemSelected` dans SelectPicker
- Le modal est un route overlay, `Navigator.pop()` le ferme proprement

**Alternatives considered** :
- Callback `onClose` dans le builder → rejeté : surcharge inutile, le Navigator est disponible
