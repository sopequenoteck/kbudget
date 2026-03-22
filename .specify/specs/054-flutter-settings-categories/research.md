# Research: 054-flutter-settings-categories

**Date**: 2026-02-26

## R1: Réutilisabilité du ColorPalettePicker

**Decision**: Déplacer `ColorPalettePicker` de `features/accounts/presentation/widgets/` vers `common_widgets/`.

**Rationale**: Le widget est 100% générique — aucun import account-specific. Il accepte `selectedColor`, `onChanged` et `label` en paramètres. Deux features en ont besoin (accounts + categories), ce qui justifie la promotion en widget partagé.

**Alternatives considered**:
- Dupliquer le widget dans categories → Rejeté : violation DRY, maintenance double
- Importer directement depuis accounts/widgets → Rejeté : couplage cross-feature non conventionnel
- Créer un widget abstrait avec spécialisations → Rejeté : sur-ingénierie (YAGNI)

## R2: Distinction visuelle des catégories système

**Decision**: Les catégories système sont affichées dans la même liste triée alphabétiquement, avec une opacité réduite et un badge "Système" textuel. Elles ne sont pas cliquables (pas de navigation vers le formulaire).

**Rationale**: L'Angular masque les catégories système, mais la spec demande de les montrer. L'opacité réduite + badge texte est le pattern le plus simple et immédiatement compréhensible. Le `ListTile` utilise `enabled: !category.isSystem` pour bloquer le tap.

**Alternatives considered**:
- Section séparée "Catégories système" en haut/bas → Rejeté : complexifie le layout pour peu de valeur (3-4 catégories système max)
- Icône cadenas à côté du nom → Rejeté : surcharge visuelle sur un petit écran mobile
- Masquer comme Angular → Rejeté : contradictoire avec la spec (US5)

## R3: Couche données existante

**Decision**: Réutiliser intégralement la couche données existante sans modification.

**Rationale**: Le `CategoryNotifier`, le `CategoryRepository` (abstract + remote + local), les `CategoryDTOs`, et le `dataModeProvider` sont déjà implémentés et fonctionnels. Le notifier gère déjà la protection des catégories système (blocage update/delete avec message d'erreur). Aucune modification nécessaire.

**Alternatives considered**:
- Créer un notifier séparé pour la vue settings → Rejeté : duplication inutile, le notifier existant couvre tous les cas CRUD
- Ajouter des méthodes au notifier → Rejeté : les méthodes existantes (loadItems, create, update, delete) suffisent

## R4: Formulaire — prévisualisation catégorie

**Decision**: Créer un `CategoryPreviewCard` simple affichant l'emoji, le nom et la couleur en temps réel, suivant le pattern de `AccountPreviewCard`.

**Rationale**: Le formulaire catégorie est plus simple que celui des comptes (3 champs vs 7+). La preview montre comment la catégorie apparaîtra dans les listes (transactions, abonnements). C'est le même pattern que 053-accounts.

**Alternatives considered**:
- Pas de preview → Rejeté : incohérence avec le pattern accounts, moins bon feedback utilisateur
- Preview sous forme de chip/tag → Rejeté : trop petit pour être utile en feedback visuel

## R5: Routing — structure des sous-routes

**Decision**: Remplacer le stub par une route liste + deux sous-routes (new, edit/:id), suivant exactement le pattern accounts.

**Rationale**: Cohérence avec la navigation accounts : liste → tap + → formulaire création, liste → tap item → formulaire édition. La catégorie est passée via `state.extra` pour l'édition.

**Alternatives considered**:
- Modal bottom sheet au lieu d'écran séparé → Rejeté : formulaire trop complexe (3 champs + emoji picker + color picker) pour un bottom sheet
- Route unique avec paramètre optionnel → Rejeté : moins lisible dans le routeur, complique le deep linking
