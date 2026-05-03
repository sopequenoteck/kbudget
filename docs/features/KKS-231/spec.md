# Feature Specification: Refonte du sélecteur de catégorie en bottom-sheet inline

**Feature Branch**: `feature/KKS-231`
**Created**: 2026-04-18
**Status**: Draft
**Priority**: Medium (P3 Linear)
**Labels**: Frontend, Feature
**Input**: Issue Linear [KKS-231](https://linear.app/kksdev/issue/KKS-231/refonte-du-selecteur-de-categorie-en-bottom-sheet-inline)

---

## Contexte

Le sélecteur de catégorie actuel (`app-category-picker` → `app-select-picker`) est utilisé dans trois formulaires en bottom-sheet : `transaction-form`, `subscription-form`, `debt-form`. Un clic sur la pill catégorie ouvre un second bottom-sheet par-dessus le formulaire. Le bouton « + Créer » ouvre une `Modal` centrée par-dessus — potentiellement une troisième surface modale empilée.

Ce comportement viole :

- **Principe #4 du `DESIGN.md`** : *« Un seul niveau de surface modale : bottom sheet OU dialog centre. Jamais deux empilés. »*
- **Pattern bottom-sheet** (`DESIGN.md:92-103`) : les pills meta doivent déclencher une *section expandable* dans le sheet, pas un overlay imbriqué. Le précédent `InlineDatePicker` l'applique déjà pour les dates.
- **Précédent KKS-230** : le composant `app-autocomplete` a été conçu comme composant dédié au contexte bottom-sheet, symétrique à ce que vise ce ticket.

## Objectif

Aligner le sélecteur de catégorie sur le pattern bottom-sheet *inline expand*, et en profiter pour refondre le formulaire de création de catégorie afin qu'il s'intègre dans cet expand sans friction ni rupture visuelle.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Sélectionner une catégorie existante sans quitter le sheet (Priority: P1)

L'utilisateur saisit une transaction dans le bottom-sheet. Il clique sur la pill « catégorie » pour en associer une. La sélection se fait entièrement dans le bottom-sheet courant, sans surface modale empilée.

**Why this priority**: C'est le flow le plus fréquent (quasiment toute saisie de transaction concerne une catégorie existante) et c'est la raison d'être du ticket — corriger la violation du principe #4. Sans cette US, le chantier n'a pas de valeur livrable.

**Independent Test**: Ouvrir le formulaire de transaction, cliquer sur la pill catégorie, vérifier visuellement qu'aucun overlay ne se superpose au sheet, sélectionner une catégorie dans la liste inline, confirmer que la pill affiche la sélection et que l'expand se referme.

**Acceptance Scenarios**:

1. **Given** le bottom-sheet transaction est ouvert, **When** l'utilisateur clique sur la pill catégorie, **Then** une section expand s'ouvre *dans* le sheet sans overlay ni second bottom-sheet empilé.
2. **Given** l'expand catégorie est ouvert et une autre pill (ex. date) était précédemment expand, **When** l'utilisateur clique sur la pill catégorie, **Then** l'expand date se referme automatiquement (comportement single-expand).
3. **Given** une catégorie est sélectionnée dans la liste, **When** l'utilisateur clique dessus, **Then** la pill catégorie affiche la sélection, l'expand se collapse, et le formulaire parent reçoit la nouvelle valeur.
4. **Given** le même pattern est utilisé dans `subscription-form` et `debt-form`, **When** on y effectue la même action, **Then** le comportement est identique aux trois endroits.

---

### User Story 2 — Créer une nouvelle catégorie sans quitter le flow de saisie (Priority: P1)

L'utilisateur saisit une transaction pour un commerce qu'il n'a jamais catégorisé. Il tape le nom d'une catégorie qui n'existe pas encore ; l'expand lui propose d'en créer une directement, sans quitter le sheet. La catégorie créée est immédiatement associée à la transaction en cours.

**Why this priority**: Sans cette US, l'utilisateur doit annuler sa saisie, aller dans Settings, créer la catégorie, revenir au formulaire — rupture critique du flow mobile-first (constitution #4). De plus, supprimer le bouton « + Créer » actuel sans le remplacer régresse l'UX. La création inline doit arriver en même temps que la sélection inline, pas après.

**Independent Test**: Dans le formulaire transaction, ouvrir l'expand catégorie, taper une chaîne qui ne matche aucune catégorie existante, cliquer sur « + Créer '{terme}' », remplir le form, valider, vérifier que la nouvelle catégorie est automatiquement sélectionnée.

**Acceptance Scenarios**:

1. **Given** l'expand catégorie est ouvert avec une recherche ne matchant aucune catégorie, **When** le bouton « + Créer '{terme}' » est affiché, **Then** il prend le terme saisi comme pré-remplissage.
2. **Given** l'utilisateur clique sur « + Créer '{terme}' », **When** l'expand bascule en mode création, **Then** le contenu de l'expand est remplacé par le formulaire (champs nom/icône/couleur) avec le nom pré-rempli, et les actions `← Retour` + `✓ Créer` apparaissent en en-tête d'expand.
3. **Given** le mode création est actif, **When** l'utilisateur regarde le footer du bottom-sheet, **Then** les actions `Annuler`/`Enregistrer` du sheet sont désactivées (pas masquées) pour éviter la confusion d'intention.
4. **Given** l'utilisateur clique sur `← Retour`, **When** l'expand revient en mode liste, **Then** le terme de recherche est conservé et la liste filtrée à nouveau (aucune perte de saisie).
5. **Given** l'utilisateur valide `✓ Créer` avec un form valide, **When** l'API répond succès, **Then** la nouvelle catégorie est automatiquement sélectionnée, l'expand se collapse, et le formulaire parent reçoit la valeur.
6. **Given** l'API renvoie une erreur (nom dupliqué, réseau), **When** la création échoue, **Then** un banner d'erreur s'affiche dans l'expand sans fermer le mode création (l'utilisateur peut corriger et réessayer).

---

### User Story 3 — Filtrer la liste de catégories par recherche (Priority: P2)

L'utilisateur a accumulé de nombreuses catégories. Il tape quelques caractères pour filtrer rapidement et trouver celle qu'il cherche.

**Why this priority**: Utile mais non bloquant pour les utilisateurs avec peu de catégories (< 10). Le flow complet (US1) fonctionne sans recherche — un scroll vertical suffit. La recherche est un confort ergonomique qui devient essentiel au-delà d'un certain volume de catégories, mais elle est aussi le prérequis de US2 (la création inline s'appuie sur la présence du champ recherche). Classée P2 car la création inline peut techniquement partir sur un autre pattern si on découple.

**Independent Test**: Ouvrir l'expand catégorie, taper une chaîne, vérifier que la liste se filtre en temps réel de manière insensible à la casse et aux accents.

**Acceptance Scenarios**:

1. **Given** l'expand catégorie contient 15 catégories, **When** l'utilisateur tape « cour », **Then** seules les catégories dont le nom contient « cour » (case-insensitive) sont affichées.
2. **Given** la recherche contient « cafe » et une catégorie s'appelle « Café », **When** le filtre s'applique, **Then** « Café » apparaît dans les résultats (insensibilité aux accents via normalisation NFD).
3. **Given** la recherche ne matche aucune catégorie, **When** la liste est vide, **Then** le bouton « + Créer '{terme}' » apparaît en lieu et place des résultats.
4. **Given** la recherche est vide, **When** l'expand est ouvert, **Then** la liste complète des catégories est affichée.

---

### User Story 4 — Gérer les catégories depuis la page Settings sans régression (Priority: P2)

Un utilisateur administre ses catégories depuis la page Settings (gestion globale via `shell.html`). Le formulaire de création/édition de catégorie reste fonctionnel, avec un footer d'actions cohérent avec cet écran.

**Why this priority**: La refonte du `CategoryForm` pour externaliser son footer (prérequis pour l'intégrer dans l'expand de l'US2) impose de recâbler le consommateur actuel dans `shell.html`. Sans cette US, la refonte casse une fonctionnalité existante. P2 car c'est une non-régression requise, pas une nouvelle valeur.

**Independent Test**: Ouvrir la page de gestion des catégories depuis Settings, créer une nouvelle catégorie, la modifier, la supprimer — confirmer que tous les parcours fonctionnent comme avant la refonte.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la page de gestion des catégories, **When** il clique sur « Nouvelle catégorie », **Then** le formulaire s'affiche avec ses actions propres (footer externalisé câblé par `shell.html`).
2. **Given** le formulaire de création est affiché depuis Settings, **When** l'utilisateur valide, **Then** la catégorie est créée avec le même comportement qu'avant la refonte (pas de différence fonctionnelle perceptible).
3. **Given** le formulaire d'édition est affiché depuis Settings, **When** l'utilisateur modifie et valide, **Then** la catégorie est mise à jour sans régression.

---

### Edge Cases

- **Aucune catégorie existante (premier usage)** : que montre l'expand ? *(différé — voir clarify-log.md, point CL-006).*
- **Recherche égale à une catégorie existante** : le bouton « + Créer » ne doit *pas* apparaître (une catégorie de même nom existe déjà — comportement actuel via `hasExactMatch` dans `category-picker.ts:72-76`).
- **Liste longue dépassant la hauteur de l'expand** : scroll interne à l'expand avec hauteur max fixe (60vh). Le footer du sheet reste accessible, la liste scrolle indépendamment (pattern Revolut-like).
- **Clic hors de l'expand pendant le mode création** : si l'utilisateur tape en dehors du sheet, le comportement de fermeture du sheet s'applique. Que deviennent les données de création non sauvegardées ? *(différé — voir clarify-log.md, point CL-007).*
- **Création en mode offline** : si l'API catégories échoue pour cause réseau (cas mobile), l'erreur doit être visible sans fermer l'expand (couvert par FR-011).
- **Deux pills ouvertes simultanément** : interdit par principe (single-expand). Coordination pilotée par le form parent via `expandedSection: signal<ExpandableSection>()` — pattern déjà en place dans `transaction-form.ts:120,295`. Le composant `CategorySelect` est purement inline (dumb component), le parent gère l'activation.

---

## Requirements *(mandatory)*

### Functional Requirements

**Sélection inline (US1)**

- **FR-001**: Un composant `app-category-select` MUST rendre la liste des catégories dans un conteneur inline destiné à un `bsheet__expand`, sans overlay ni second bottom-sheet.
- **FR-002**: Cliquer sur un item de la liste MUST émettre la sélection au composant parent et collapser l'expand.
- **FR-003**: Le composant MUST respecter le comportement *single-expand* défini dans `DESIGN.md:102` — l'ouverture de l'expand catégorie ferme toute autre section expandable active dans le même sheet.
- **FR-004**: Le composant MUST être intégré dans les trois formulaires `transaction-form`, `subscription-form` et `debt-form` à la place de l'actuel `app-category-picker`.

**Création inline (US2)**

- **FR-005**: Si la recherche ne matche aucune catégorie existante (match exact), un bouton « + Créer '{terme}' » MUST s'afficher.
- **FR-006**: Cliquer sur « + Créer » MUST remplacer le contenu de l'expand par le formulaire de création, avec le nom pré-rempli à partir du terme de recherche.
- **FR-007**: Pendant le mode création, l'en-tête de l'expand MUST afficher deux actions : `← Retour` (à gauche) et `✓ Créer` (à droite).
- **FR-008**: Pendant le mode création, le footer du bottom-sheet parent (`bsheet__bottom-row`) MUST être désactivé (visible mais non interactif).
- **FR-009**: `← Retour` MUST ramener l'expand en mode liste tout en conservant le terme de recherche saisi avant création.
- **FR-010**: Après création réussie (réponse API succès), la catégorie créée MUST être automatiquement sélectionnée, et l'expand MUST se collapser.
- **FR-011**: En cas d'erreur de création (dupliqué, réseau), un banner d'erreur MUST s'afficher *dans* l'expand sans sortir du mode création.

**Recherche (US3)**

- **FR-012**: Un champ de recherche MUST filtrer la liste de catégories en temps réel, insensible à la casse et aux accents (normalisation NFD + suppression des diacritiques, cohérent avec `app-autocomplete`).

**Refonte CategoryForm (US4)**

- **FR-013**: Le composant `CategoryForm` MUST externaliser ses actions via des outputs signals-first `(save)` et `(cancel)` — la section `category-form__actions` actuelle (`category-form.html:43-48`) MUST être supprimée.
- **FR-014**: Les consommateurs de `CategoryForm` (`category-select` côté bottom-sheet, `shell.html` côté Settings) MUST câbler leurs propres actions via les outputs exposés.
- **FR-015**: Le visuel du `CategoryForm` MUST être aligné au design system actuel (tokens CSS uniquement, plus de classes `btn-outline`/`btn-primary` legacy, swatches avec état actif via `--primary-border`).

**Migration / nettoyage**

- **FR-016**: Le composant `app-category-picker` (`shared/components/category-picker/`) MUST être supprimé du code après la migration des trois consommateurs.
- **FR-017**: L'import de `Modal` dans `category-picker.ts` MUST être nettoyé ; aucune `Modal` centrée ne DOIT être empilée au-dessus d'un bottom-sheet dans les flows concernés.

**Accessibilité & navigation**

- **FR-018**: Le composant MUST exposer les rôles ARIA cohérents avec `app-autocomplete` : `role="combobox"` sur le trigger, `role="listbox"` + `role="option"` sur la liste, `aria-expanded`, `aria-activedescendant`.
- **FR-019**: La navigation clavier MUST être opérationnelle : ↑/↓ pour parcourir la liste, Enter pour sélectionner, Esc pour fermer l'expand.

**Layout & scroll**

- **FR-020**: Le conteneur de liste MUST utiliser un scroll interne avec hauteur max fixe de **60vh** (`max-height: 60vh`, `overflow-y: auto`). Le footer du bottom-sheet reste toujours accessible indépendamment du nombre d'items.
- **FR-021**: Le composant `CategorySelect` MUST être un *dumb component* inline — il ne gère pas sa propre expansion. Le form parent pilote l'ouverture/fermeture via un signal `expandedSection` existant (`transaction-form.ts:120`).

### Non-Functional Requirements

- **NFR-001**: **Tokens CSS uniquement** — aucun hex/rgba hardcodé dans les composants ajoutés ou modifiés (`DESIGN.md` principe #5).
- **NFR-002**: **Signals-first** — `signal()`, `computed()`, `input()`, `output()`, `model()`. Pas de `@Input`/`@Output`, pas de subscribe manuel.
- **NFR-003**: **Standalone + OnPush** sur tous les nouveaux composants.
- **NFR-004**: **Isolation des données** (constitution #2) — l'API `categories` consommée filtre déjà par user authentifié ; la refonte frontend ne doit introduire aucune fuite.
- **NFR-005**: **Testabilité** (constitution #5) — le nouveau composant MUST avoir des tests unitaires couvrant : ouverture/fermeture de l'expand, filtre recherche, push/pop création, sélection automatique post-création, persistance recherche au retour, comportement single-expand. Nommage `should_[résultat]_when_[condition]`.
- **NFR-006**: **Performance perçue** — l'ouverture de l'expand doit être instantanée (pas d'attente réseau bloquante ; les catégories sont déjà chargées en cache via `CategoryService`).
- **NFR-007**: **Mobile-first** (constitution #4) — tous les items cliquables respectent une zone tactile ≥ 44px de hauteur.

### Key Entities

- **Category** *(existante, non modifiée par ce ticket)* : représentation d'une catégorie de transaction — `id`, `nom`, `icone`, `couleur`, scope utilisateur. Voir `Category` (`app/src/app/core/models/category.model.ts`).
- **CategorySelectState** *(nouveau, interne au composant)* : état UI du composant `app-category-select` — `mode: 'list' | 'create'`, `searchTerm: string`, `selectedId: string`, `submitting: boolean`, `errorMessage: string | null`.

### Assumptions

- **A-001** *(validé — CL-002)*: Le composant `InlineDatePicker` sert de modèle direct pour l'intégration en bottom-sheet. Son API (`value: model`, `min/max: input`) et son rôle de *dumb component* (sans gestion interne de l'expand) sont confirmés par lecture du code (`inline-date-picker.ts:60-63`). Le composant ne gère pas lui-même son activation — le parent pilote via un signal `expandedSection`, pattern déjà appliqué dans `transaction-form.ts:120,295`.
- **A-002** *(validé — CL-003)*: Les deux seuls consommateurs de `CategoryForm` sont `category-picker` (via Modal) et `shell.html:102`. Grep exhaustif `CategoryForm|app-category-form` dans `app/` ne remonte aucun autre consommateur. La refonte globale avec externalisation des outputs `(save)`/`(cancel)` est sans risque.
- **A-003** *(non validé, différé)*: Le volume moyen de catégories par utilisateur reste modeste (< 30). *Si faux* : la liste non paginée peut devenir lente à afficher ; une virtualisation serait alors nécessaire (hors scope actuel). *Impact mitigé par FR-020 (scroll interne 60vh).*
- **A-004** *(validé — CL-004)*: Aucun backend change requis. `CategoryService` (`app/src/app/core/services/category.ts`) expose déjà `getAll()` (GET `/categories`) et `create()` (POST `/categories` avec refresh trigger). Tous les endpoints nécessaires sont en place.
- **A-005** *(partiellement validé — couvert par CL-003)*: Le flow de création de catégorie depuis Settings (via `shell.html`) tolère l'externalisation du footer. La vérification exhaustive du câblage dans `shell.html:102` se fera lors de l'implémentation (FR-014).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(vérifie US1)*: **Zéro empilement de surfaces modales** sur les trois formulaires concernés. Audit visuel + grep du code : aucun `app-select-picker` dans les composants de bottom-sheet, aucune `Modal` centrée ouverte depuis un sheet catégorie. *Méthode : inspection visuelle sur les 3 formulaires + `grep -r "SelectPicker\|CategoryPicker" app/src/app/features/`.*
- **SC-002** *(vérifie US1)*: **Temps de sélection d'une catégorie existante ≤ 2 interactions** depuis l'ouverture du bottom-sheet (clic pill → clic item). *Méthode : test manuel chronométré sur 5 cas ; interactions = taps.*
- **SC-003** *(vérifie US2)*: **Création d'une catégorie depuis la transaction en ≤ 5 interactions** (clic pill catégorie → tap recherche → saisie nom → clic « + Créer » → clic « ✓ Créer » après ajustement éventuel d'icône/couleur). *Méthode : test manuel sur 3 cas.*
- **SC-004** *(vérifie US2)*: **100 % des tentatives de création réussies aboutissent à une catégorie automatiquement sélectionnée** dans le formulaire parent, sans action supplémentaire de l'utilisateur. *Méthode : test automatisé sur le composant.*
- **SC-005** *(vérifie US3)*: **Filtre recherche insensible à la casse et aux accents vérifié** sur au moins 3 paires (ex. « cafe » matche « Café » ; « ECO » matche « économie »). *Méthode : tests unitaires.*
- **SC-006** *(vérifie US4)*: **Aucune régression dans la gestion des catégories depuis Settings** — créer, modifier, supprimer fonctionnent à l'identique. *Méthode : test manuel sur la page Settings + test d'intégration sur `shell.ts`.*
- **SC-007** *(vérifie NFR-001)*: **Aucun hex/rgba hardcodé** dans les composants ajoutés ou modifiés. *Méthode : `grep -E "#[0-9a-fA-F]{3,8}|rgba?\("` sur les fichiers `.scss` du scope.*
- **SC-008** *(vérifie NFR-005)*: **Couverture de tests unitaires ≥ 80 %** sur `app-category-select` avec les scénarios listés. *Méthode : `ng test --code-coverage`.*
- **SC-009** *(vérifie FR-016)*: **Le répertoire `app/src/app/shared/components/category-picker/` n'existe plus** après merge. *Méthode : vérification arborescence.*
- **SC-010** *(vérifie FR-019)*: **Navigation clavier complète** ↑/↓/Enter/Esc fonctionnelle, testée au clavier physique sur desktop. *Méthode : test manuel.*

---

## Contraintes & Dépendances

### Contraintes

- **Constitution du projet** (`.specify/memory/constitution.md`) : principes #2 (sécurité/isolation), #3 (simplicité/YAGNI — pas d'abstraction prématurée), #4 (mobile-first), #5 (testabilité).
- **Design system** (`DESIGN.md`) : principes #4 (surface modale unique) et #5 (tokens uniquement). Pattern bottom-sheet `_bottom-sheet.scss`.
- **Conventions Angular du projet** (`CLAUDE.md`) : signals-first, standalone, OnPush, `inject()`, pas de subscribe manuel.

### Dépendances

- `CategoryService` (`app/src/app/core/services/category.ts`) — lecture et création de catégories via les endpoints existants.
- `InlineDatePicker` — modèle de référence pour l'intégration en expand bottom-sheet.
- `app-autocomplete` (KKS-230) — modèle de référence pour normalisation NFD et patterns signals-first d'un composant dédié bottom-sheet.
- `_bottom-sheet.scss` — styles partagés pour les pills et expand.

### Hors scope (rappel du ticket Linear)

- Refonte du `SelectPicker` générique (reste utilisé hors bottom-sheet).
- Ajout de champs au `CategoryForm` (parent, budget, ordre…).
- Changement backend catégories (API, DTOs, validation).
- Support de catégories hiérarchiques dans le select.
- Flutter — ce ticket couvre uniquement l'app Angular.

---

## Questions ouvertes

| # | Question | Statut | Résolution |
|---|----------|--------|------------|
| 1 | **Empty state initial** — Que montre l'expand si l'utilisateur n'a strictement aucune catégorie (premier usage) ? Bouton « + Créer » seul ? Empty state dédié avec message + CTA ? | Différé | À résoudre lors d'une relance `/devflow.clarify` ou à la planification (cas bord rare ; MOYEN). Voir CL-006. |
| 2 | **Scroll de la liste** — Quand la liste dépasse la hauteur de l'expand : scroll interne à l'expand ou expand qui grandit jusqu'à une limite ? | ✅ Résolu | Scroll interne à l'expand, `max-height: 60vh` (FR-020). Pattern Revolut-like. Footer sheet reste accessible. |
| 3 | **Mécanisme single-expand** — Coordination entre pills pilotée par un signal dans le form parent ou par un service partagé ? | ✅ Résolu | Signal `expandedSection: signal<ExpandableSection>(null)` dans le form parent, toggle via `update((current) => current === section ? null : section)`. Pattern déjà en place (`transaction-form.ts:120,295`). Le composant `CategorySelect` reste *dumb* (FR-021). |
| 4 | **Clic hors de l'expand pendant création** — Perte silencieuse ou confirmation ? | Différé | À résoudre plus tard (HAUT). Voir CL-007. |
