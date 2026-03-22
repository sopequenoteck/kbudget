# Research: Formulaire Transaction (modal)

**Feature**: 009-transaction-form | **Date**: 2026-02-09

## Résumé

Aucun unknown technique majeur identifié. La feature utilise exclusivement des patterns et dépendances déjà en place dans le projet. Les recherches ci-dessous documentent les décisions de design pour les éléments spécifiques à ce formulaire.

## R1 — Toggle segmenté pour le type de transaction

**Decision**: Implémenter un toggle segmenté custom en CSS/HTML pur (2 boutons `<button>` dans un conteneur flex) piloté par le `FormControl` du type.

**Rationale**: Pas besoin de librairie externe pour 2 boutons. Le pattern est simple : deux boutons côte à côte, un `aria-pressed` pour l'accessibilité, le `FormControl` gère l'état. Cohérent avec le principe YAGNI de la constitution.

**Alternatives considered**:
- `@angular/material` toggle group : sur-dimensionné pour un projet sans Material Design
- `<select>` natif : moins intuitif sur mobile pour seulement 2 options (un tap de plus)
- Radio buttons : fonctionnel mais moins visuel et occupe plus d'espace vertical

## R2 — Chargement des catégories dans le formulaire

**Decision**: Injecter `CategoryService` dans le composant et charger les catégories via `toSignal(categoryService.getAll())` au moment de l'initialisation du composant.

**Rationale**: Pattern cohérent avec l'approche signals-first du projet. `toSignal()` convertit l'Observable en Signal, permettant un usage réactif dans le template sans `subscribe()` manuel. Le chargement est une seule requête GET légère.

**Alternatives considered**:
- Passer les catégories en `input()` depuis le Shell : déplacerait la responsabilité au parent qui n'a pas de raison de connaître les catégories
- Utiliser un resolver de route : le formulaire est dans une modal, pas une route
- Cache local (localStorage) : prématuré, YAGNI

## R3 — Gestion du mode création vs édition

**Decision**: Utiliser un `input()` optionnel `transaction` de type `Transaction | null`. Si `null` → mode création (valeurs par défaut). Si objet → mode édition (pré-remplissage).

**Rationale**: Pattern simple et explicite. Un seul composant gère les deux modes via la présence/absence de l'input. Le formulaire réactif est initialisé dans un `effect()` qui réagit au changement de l'input.

**Alternatives considered**:
- Deux composants séparés (create/edit) : duplication de code, viole DRY
- Input `mode: 'create' | 'edit'` séparé : redondant avec la nullité de `transaction`
- Service partagé avec état modal : complexité prématurée (prévu dans KKS-58 ModalService)

## R4 — Format de date pour l'input natif

**Decision**: Utiliser `<input type="date">` natif HTML5 avec le format `YYYY-MM-DD` (format ISO imposé par le standard HTML). La conversion vers le format attendu par le backend (LocalDate ISO) est transparente.

**Rationale**: L'input date natif est le meilleur choix mobile-first : il ouvre le sélecteur natif du téléphone, pas de librairie datepicker supplémentaire. Le format `YYYY-MM-DD` est identique au format ISO attendu par le backend.

**Alternatives considered**:
- Datepicker custom (Angular CDK, ng-bootstrap) : dépendance inutile, l'input natif est supérieur sur mobile
- Input texte avec masque : erreurs de saisie, mauvaise UX mobile

## R5 — Validation frontend vs backend

**Decision**: Implémenter la validation côté frontend via `Validators` d'Angular uniquement pour les règles connues (required, min, maxLength). Ne pas dupliquer la logique métier complexe côté frontend.

**Rationale**: La validation frontend est un confort UX (feedback immédiat). Le backend reste la source de vérité (Bean Validation). Les règles simples (required, > 0, maxLength) sont suffisantes côté frontend.

**Alternatives considered**:
- Validation async côté backend pour chaque champ : latence réseau, over-engineering
- Pas de validation frontend : mauvaise UX, erreurs 400 brutes
