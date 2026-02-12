# Feature Specification: Fix checkboxes non fonctionnelles dans les formulaires

**Feature Branch**: `020-fix-checkbox-forms`
**Created**: 2026-02-12
**Status**: Draft
**Input**: KKS-68 — Fix checkboxes non fonctionnelles dans les formulaires
**Linear**: KKS-68 (Phase 6 — Fix & Polish UX)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Activer/désactiver un abonnement via la checkbox (Priority: P1)

L'utilisateur ouvre le formulaire d'abonnement (création ou édition) et souhaite cocher ou décocher la case "Abonnement actif". Le clic sur la checkbox ou son label doit immédiatement basculer l'état visuel (coché/décoché), et cet état doit être correctement transmis lors de la soumission du formulaire.

**Why this priority**: La checkbox "actif" est essentielle pour gérer le cycle de vie des abonnements. Sans elle, l'utilisateur ne peut pas désactiver un abonnement récurrent.

**Independent Test**: Ouvrir le formulaire abonnement, cliquer la checkbox "actif", soumettre le formulaire, et vérifier que la valeur `actif` correspond à l'état visuel.

**Acceptance Scenarios**:

1. **Given** le formulaire abonnement est ouvert en mode création, **When** l'utilisateur clique sur la checkbox "actif", **Then** la checkbox change d'état visuel (cochée vers décochée ou inversement)
2. **Given** la checkbox "actif" est décochée, **When** l'utilisateur soumet le formulaire, **Then** l'abonnement est créé avec `actif = false`
3. **Given** un abonnement existant avec `actif = true` est ouvert en édition, **When** le formulaire se charge, **Then** la checkbox est visuellement cochée
4. **Given** l'utilisateur clique sur le label "Abonnement actif" (pas directement sur la checkbox), **When** le clic est enregistré, **Then** la checkbox bascule son état

---

### User Story 2 - Marquer une dette comme remboursée via la checkbox (Priority: P1)

L'utilisateur ouvre le formulaire de dette (création ou édition) et souhaite cocher ou décocher la case "Remboursé". Le comportement attendu est identique : bascule visuelle immédiate et valeur correcte à la soumission.

**Why this priority**: La checkbox "remboursé" est le seul mécanisme pour clôturer une dette. Sans elle, l'utilisateur ne peut pas suivre l'état de remboursement.

**Independent Test**: Ouvrir le formulaire dette, cliquer la checkbox "remboursé", soumettre, et vérifier que `rembourse` reflète l'état visuel.

**Acceptance Scenarios**:

1. **Given** le formulaire dette est ouvert en mode création, **When** l'utilisateur clique sur la checkbox "Remboursé", **Then** la checkbox change d'état visuel
2. **Given** la checkbox "Remboursé" est cochée, **When** l'utilisateur soumet le formulaire, **Then** la dette est créée avec `rembourse = true`
3. **Given** une dette existante avec `rembourse = true` est ouverte en édition, **When** le formulaire se charge, **Then** la checkbox est visuellement cochée

---

### User Story 3 - Apparence visuelle cohérente des checkboxes (Priority: P2)

Les checkboxes doivent avoir une apparence cohérente avec le design system de l'application (couleur primaire Amber, taille lisible, zone de clic confortable sur mobile).

**Why this priority**: L'apparence visuelle est secondaire par rapport au fonctionnement, mais nécessaire pour une expérience mobile cohérente.

**Independent Test**: Inspecter visuellement les checkboxes dans les deux formulaires et vérifier qu'elles respectent le style attendu (taille, couleur, espacement).

**Acceptance Scenarios**:

1. **Given** une checkbox est affichée dans un formulaire, **When** l'utilisateur la voit, **Then** elle a une taille confortable pour un tap mobile (minimum 20x20px)
2. **Given** une checkbox est cochée, **When** l'utilisateur la voit, **Then** la couleur primaire (Amber) indique l'état actif

---

### Edge Cases

- Soumission sans interaction : la valeur par défaut doit être correctement envoyée (`true` pour actif, `false` pour remboursé)
- Mode édition avec valeur `null` ou `undefined` : la checkbox doit se comporter comme décochée (`false`)
- Double-clic rapide : l'état final doit rester cohérent entre le visuel et la valeur du formulaire
- Navigation clavier : Tab pour atteindre la checkbox, Space pour basculer son état

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Les checkboxes doivent réagir au clic utilisateur par une bascule visuelle immédiate (cochée vers décochée et inversement)
- **FR-002**: L'état visuel de la checkbox doit être synchronisé avec la valeur du formulaire réactif à tout moment
- **FR-003**: La soumission du formulaire doit transmettre la valeur booléenne correcte correspondant à l'état de la checkbox
- **FR-004**: En mode édition, la checkbox doit refléter la valeur existante de l'entité chargée
- **FR-005**: Les styles globaux de l'application ne doivent pas interférer avec le rendu natif des checkboxes
- **FR-006**: Les checkboxes doivent être accessibles : cliquables via leur label associé et navigables au clavier (Tab + Space)

### Cause racine identifiée

Les styles globaux dans `_forms.scss` ciblent le sélecteur `input` sans exclure les checkboxes. Cela applique :
- `appearance: none` — supprime le rendu natif de la checkbox (plus de case visible)
- `width: 100%` — étire la checkbox en pleine largeur
- `padding`, `border-radius`, `background-color` — styles de champ texte appliqués à tort

La checkbox devient un rectangle invisible pleine largeur, inutilisable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des checkboxes (abonnement "actif", dette "remboursé") basculent visuellement au clic
- **SC-002**: 100% des soumissions de formulaire transmettent la valeur booléenne correspondant à l'état visuel de la checkbox
- **SC-003**: En mode édition, les checkboxes affichent l'état correct de l'entité dans 100% des cas
- **SC-004**: Les checkboxes sont utilisables sur mobile (zone de tap confortable, pas de comportement inattendu)

## Assumptions

- Le bug est causé par les styles CSS globaux qui écrasent le rendu natif des checkboxes (confirmé par analyse du code)
- La logique TypeScript / ReactiveForm est correcte (les `formControlName` sont bien liés, les valeurs par défaut correctement définies)
- Le correctif se limite aux styles CSS — pas de modification de la logique métier
- Seuls deux formulaires sont concernés : SubscriptionForm (champ "actif") et DebtForm (champ "remboursé")
