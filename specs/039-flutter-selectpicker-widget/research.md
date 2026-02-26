# Research: Widget SelectPicker Flutter

**Feature**: 039-flutter-selectpicker-widget
**Date**: 2026-02-21

## R1 — FormField<String?> Pattern Flutter

**Decision**: Utiliser le pattern `FormField<String?>` avec un `FormFieldState` personnalisé, suivant l'architecture de `DropdownButtonFormField` natif de Flutter.

**Rationale**: Ce pattern permet :
- Intégration native avec `Form.validate()`, `Form.reset()`, `Form.save()`
- Gestion automatique de la validation et de l'affichage d'erreur via `FormFieldState.errorText`
- Le builder a accès au state typé (cast `as _SelectPickerState`) pour accéder aux méthodes custom (ouverture modale, recherche)

**Alternatives considérées**:
- Widget stateless simple + wrapper séparé → Rejeté : doublerait le code et l'API publique
- Uniquement `StatefulWidget` avec validation manuelle → Rejeté : incompatible avec `FormState`, duplication de logique

## R2 — Réutilisation d'AppFormField (style visuel)

**Decision**: Reproduire le style visuel d'AppFormField directement dans le trigger du SelectPicker, sans wrapping d'AppFormField.

**Rationale**: AppFormField est un wrapper visuel qui gère le focus d'un enfant `Focus`. Le SelectPicker n'a pas de `TextField` enfant — il a un trigger tappable. Reproduire le même style (label sm/medium, conteneur `surfaceContainerHighest` avec `BorderRadius.circular(AppRadius.xl)`, erreur animée en dessous) est plus simple que de forcer AppFormField à gérer un non-TextField.

**Alternatives considérées**:
- Wrapper dans AppFormField → Rejeté : le `Focus` widget d'AppFormField ne s'applique pas au tap behavior du SelectPicker, causerait un état de focus incohérent
- Extraire le style d'AppFormField dans un mixin/utility → Sur-ingénierie pour 2 widgets

## R3 — AppModal comme hôte de la liste

**Decision**: Utiliser `AppModal.show()` pour afficher la liste de sélection, en passant le champ de recherche via `headerActions` et la liste des items via `child`.

**Rationale**: AppModal gère déjà le responsive (bottom sheet mobile / dialog tablette), le titre, le bouton fermer, le scroll, et le padding clavier. La recherche va dans `headerActions` (entre le titre et le body), la liste dans `child`.

**Alternatives considérées**:
- Bottom sheet custom sans AppModal → Rejeté : duplication du responsive + styling
- Cupertino picker style → Rejeté : non cohérent avec le design system

## R4 — Modèle SelectPickerItem

**Decision**: Classe simple non-générique avec `String id` comme identifiant. Pas de freezed.

**Rationale**: Les widgets existants (SegmentedFilterItem, ListItem) utilisent des classes simples avec `const` constructor. L'id est toujours un `String` (cohérent avec l'API REST et le pattern Angular). Freezed ajouterait de la complexité de build pour un modèle trivial (5 champs).

**Alternatives considérées**:
- Classe générique `SelectPickerItem<T>` → Rejeté : le callback `onChanged` émet `String?` (spec), la généricité n'apporte rien
- Freezed data class → Rejeté : overkill pour un modèle UI simple, les autres widgets du DS n'utilisent pas freezed

## R5 — Stratégie de rendu de la liste

**Decision**: Utiliser `Column` avec `List.generate` pour les items dans la modale, en s'appuyant sur le `SingleChildScrollView` d'AppModal pour le scroll.

**Rationale**: AppModal encapsule le `child` dans un `SingleChildScrollView`. Un `ListView.builder(shrinkWrap: true)` à l'intérieur construirait tous les widgets malgré le builder pattern (shrinkWrap force la mesure complète), annulant le lazy rendering. Pour les cas d'usage typiques (comptes: 5-10, catégories: 20-30, fréquences: 3-5), `Column` est performant et simple. Pour les listes très longues (devises 180+), une optimisation future pourrait remplacer AppModal par un scroll interne dédié.

**Alternatives considérées**:
- `ListView.builder` avec `shrinkWrap: true` → Rejeté : à l'intérieur d'un `SingleChildScrollView`, le shrinkWrap construit tous les widgets, annulant le lazy rendering tout en ajoutant de la complexité
- Remplacer `SingleChildScrollView` d'AppModal par le scroll du `ListView.builder` → Rejeté : nécessiterait de modifier AppModal (composant partagé) pour cette seule feature. Pourra être reconsidéré si un cas d'usage 100+ items se confirme

## R6 — Gestion du champ de recherche

**Decision**: Placer le `TextField` de recherche dans le `headerActions` d'AppModal, avec un state local dans le `_SelectPickerState`.

**Rationale**: `headerActions` est affiché entre le titre et le body scrollable — position idéale pour un champ de recherche fixe qui ne scroll pas avec la liste. Le state de recherche est éphémère (reset à chaque ouverture du modal).

**Alternatives considérées**:
- Champ de recherche dans le body (scroll avec la liste) → Rejeté : mauvaise UX, disparaît au scroll
- State de recherche dans un ValueNotifier séparé → Acceptable mais inutile : `_SelectPickerState` est déjà stateful
