# Tasks: Redesign page Dettes

**Input**: Design documents from `/specs/022-debt-page-redesign/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Non demandés dans la spec — pas de tâches de test générées.

**Organization**: Tasks groupées par user story. US3 (filtre simplifié) est fusionnée avec US1 car la suppression du filtre sens est inséparable de l'ajout des sections groupées dans le template.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

```text
app/src/app/features/debts/
├── debts.ts        # Component class
├── debts.html      # Template
└── debts.scss      # Styles
```

---

## Phase 1: Foundational (Refactoring computed signals)

**Purpose**: Restructurer la logique du composant pour supporter le groupement par sections et les KPI en cours uniquement. Changement bloquant pour toutes les user stories.

**Contexte important** : Le composant actuel charge les dettes filtrées par statut via l'API (`getAll(rembourse)`), filtre par sens côté client, et calcule les KPI sur les dettes filtrées par sens. La refonte passe à un chargement complet (toutes les dettes) avec filtrage 100% client-side.

- [x] T001 Refactorer les signals et le chargement dans `app/src/app/features/debts/debts.ts` :
  - Supprimer le type `SensFilter`, le signal `sensFilter`, et la méthode `setSensFilter()`
  - Modifier `loadData()` : appeler `this.debtService.getAll()` sans paramètre (charger toutes les dettes)
  - Modifier le `effect()` dans le constructeur : ne tracker que `this.debtService.refreshTrigger()` (plus `this.statusFilter()`)
  - Remplacer `filteredDebts` : filtrer `debts()` par `statusFilter` côté client (ALL = toutes, EN_COURS = `!rembourse`, REMBOURSE = `rembourse`)
  - Ajouter computed `activeDebts` : `debts().filter(d => !d.rembourse)` (dettes en cours uniquement)
  - Modifier `totalJeDois` : calculer depuis `activeDebts()` au lieu de `filteredDebts()` → `activeDebts().filter(d => d.sens === DebtType.EMPRUNT).reduce(sum)`
  - Modifier `totalOnMeDoit` : idem depuis `activeDebts()` → `activeDebts().filter(d => d.sens === DebtType.PRET).reduce(sum)`
  - Ajouter computed `debtsOnMeDoit` : `filteredDebts().filter(d => d.sens === DebtType.PRET)` trié par date desc
  - Ajouter computed `debtsJeDois` : `filteredDebts().filter(d => d.sens === DebtType.EMPRUNT)` trié par date desc
  - Ajouter computed `sectionTotalOnMeDoit` : somme des montants de `debtsOnMeDoit()`
  - Ajouter computed `sectionTotalJeDois` : somme des montants de `debtsJeDois()`
  - Ajouter méthode `getSubtitle(debt: Debt): string` : retourne `debt.category?.nom` ou `"Emprunt"`/`"Prêt"` selon `debt.sens`. Si `debt.rembourse`, append ` · Remboursé`
    - **Validation US4** : vérifier que `getSubtitle()` retourne bien `"<catégorie> · Remboursé"` pour une dette remboursée et `"<catégorie>"` sans badge pour une dette en cours
  - Conserver : `hasDebts`, `netBalance`, `getIcon()`, `getValueClass()`, `onDebtPressed()`, `loading`, `error`

**Checkpoint** : Le fichier TS compile sans erreur. Les computed signals sont prêts. Le template va casser temporairement (références supprimées).

---

## Phase 2: US1 — Distinction sections + US3 — Suppression filtre sens (Priority: P1+P2)

**Goal US1**: L'utilisateur voit immédiatement deux sections "On me doit" et "Je dois" avec accents colorés et totaux par section.

**Goal US3**: Un seul filtre segmenté (statut), le filtre par sens est supprimé.

**Independent Test**: Ouvrir `/debts` avec des dettes mixtes → 2 sections distinctes, 1 seul filtre, accents vert/rouge, totaux par section.

### Implementation

- [x] T002 [US1] Réécrire le template `app/src/app/features/debts/debts.html` :
  - Conserver le bloc KPI cards (3 cartes summary, inchangé structurellement)
  - Conserver le bloc status-filter (filtre segmenté Tous/En cours/Remboursé)
  - Supprimer entièrement le bloc `<section class="sens-filter">` (lignes 44-66 du template actuel) → FR-003
  - Remplacer le `<ul class="debt-list">` plate par 2 sections conditionnelles :
    - `@if (debtsOnMeDoit().length > 0)` → `<section class="debt-section debt-section--owed">` contenant :
      - `<div class="section-header">` avec `<span class="section-header__title">On me doit</span>` + `<span class="section-header__total debt-owed">{{ sectionTotalOnMeDoit() | amount }}</span>`
      - `<ul class="debt-list">` avec `@for (debt of debtsOnMeDoit(); track debt.id)` → items `<app-list-item>`
    - `@if (debtsJeDois().length > 0)` → `<section class="debt-section debt-section--owe">` contenant :
      - `<div class="section-header">` avec `<span class="section-header__title">Je dois</span>` + `<span class="section-header__total debt-owe">{{ sectionTotalJeDois() | amount }}</span>`
      - `<ul class="debt-list">` avec `@for (debt of debtsJeDois(); track debt.id)` → items `<app-list-item>`
  - Conserver la condition empty state : `filteredDebts().length === 0` (couvre le cas où les 2 sections sont vides après filtre)
  - Conserver les blocs loading, error, empty states inchangés
  - Chaque `<li>` : ajouter `[class.debt-item--rembourse]="debt.rembourse"`
  - Supprimer le `<span class="badge-rembourse">` des items (badge inline via `getSubtitle()`)
    - **Validation US4** : les items remboursés DOIVENT être visuellement atténués (opacité) et afficher "· Remboursé" dans le sous-titre

- [x] T003 [P] [US1] Mettre à jour les styles `app/src/app/features/debts/debts.scss` :
  - Supprimer le bloc `.sens-filter` et `.sens-filter__btn` entièrement
  - Supprimer le bloc `.badge-rembourse` entièrement
  - Ajouter `.debt-section` : `display: flex; flex-direction: column; border-radius: var(--radius-xl); background-color: var(--surface-default); box-shadow: var(--shadow-sm); overflow: hidden; border-left: 3px solid transparent;`
  - Ajouter `.debt-section--owed` : `border-left-color: var(--color-debt-owed);`
  - Ajouter `.debt-section--owe` : `border-left-color: var(--color-debt-owe);`
  - Ajouter `.section-header` : `display: flex; justify-content: space-between; align-items: center; padding: var(--space-3) var(--space-4);`
  - Ajouter `.section-header__title` : `font-size: var(--font-size-sm); font-weight: var(--font-weight-semibold); color: var(--text-secondary);`
  - Ajouter `.section-header__total` : `font-size: var(--font-size-sm); font-weight: var(--font-weight-bold);`
  - Modifier `.debt-list` : retirer `background-color`, `border-radius`, `box-shadow` (maintenant sur `.debt-section` parent)
  - Ajouter `.debt-item--rembourse` : `opacity: 0.5;` (préparation US4)

**Checkpoint** : La page affiche 2 sections groupées avec accents colorés, 1 seul filtre, headers avec totaux. US1 et US3 sont vérifiables.

---

## Phase 3: US2 — KPI en cours uniquement (Priority: P1)

**Goal**: Les 3 KPI (Je dois, On me doit, Solde net) affichent toujours le total des dettes en cours (non remboursées), indépendamment du filtre statut actif.

**Independent Test**: Activer le filtre "Remboursé" → la liste montre les dettes remboursées, mais les KPI affichent toujours les montants en cours. Comparer visuellement avec la page transactions → même style de cards.

### Implementation

- [x] T004 [US2] Valider et corriger les KPI dans `app/src/app/features/debts/debts.html` et `app/src/app/features/debts/debts.scss` :
  - **Pass/fail** : les KPI DOIVENT utiliser `totalJeDois()`, `totalOnMeDoit()`, `netBalance()` basés sur `activeDebts` (dettes en cours uniquement) — corriger si le template référence d'autres signals
  - **Pass/fail** : les KPI DOIVENT être visibles conditionnellement sur `hasDebts()` — corriger si la condition manque ou est différente
  - **Pass/fail** : comparer `.summary__card` dans `debts.scss` avec `app/src/app/features/transactions/transactions.scss` — les tokens DOIVENT être identiques (`--surface-default`, `--shadow-md`, `--radius-xl`, `--space-5`, labels `--font-size-xs` uppercase, valeurs `--font-size-2xl` + `--font-weight-bold`, PAS de border-top coloré) — corriger tout écart dans `debts.scss`

**Checkpoint** : KPI affichent les dettes en cours uniquement. Changer le filtre statut ne modifie pas les KPI. Style identique à la page transactions.

---

## Phase 4: US5 — Items enrichis catégorie et date (Priority: P3)

**Goal**: Chaque item affiche : icône catégorie (ou fallback), personne en titre, catégorie/type en sous-titre, montant coloré, date relative à droite.

**Independent Test**: Un item avec catégorie affiche l'emoji + nom catégorie en sous-titre. Un item sans catégorie affiche le fallback emoji + "Emprunt"/"Prêt". La date relative apparaît à droite.

### Implementation

- [x] T006 [US5] Mettre à jour les bindings `<app-list-item>` dans `app/src/app/features/debts/debts.html` :
  - `[icon]="getIcon(debt)"` — emoji catégorie ou fallback 💸 (emprunt) / 💰 (prêt) — déjà en place via `getIcon()`
  - `[title]="debt.personne"` — nom de la personne (déjà en place)
  - `[subtitle]="getSubtitle(debt)"` — catégorie ou "Emprunt"/"Prêt" + "· Remboursé" si applicable (remplace l'ancien `debt.date | relativeDate`)
  - `[rightSubtitle]="debt.date | relativeDate"` — date relative à droite (NOUVEAU — déplace la date de subtitle à rightSubtitle)
  - `[value]="debt.montant | amount"` — montant formaté (inchangé)
  - `[valueClass]="getValueClass(debt)"` — coloration selon sens (inchangé)
  - `(pressed)="onDebtPressed(debt)"` — ouverture modale (inchangé)

**Checkpoint** : Tous les items affichent icône, personne, catégorie/type, montant coloré, et date relative. US5 vérifiable.

---

## Phase 5: Polish & Validation

**Purpose**: Vérification des edge cases, conformité design system, lint.

- [x] T007 Vérifier les edge cases et états dans `app/src/app/features/debts/debts.html` :
  - Aucune dette → état vide global affiché, pas de KPI, pas de sections
  - Toutes les dettes du même sens → seule la section correspondante visible
  - Filtre "Remboursé" actif sans dettes remboursées → état vide affiché
  - Filtre rend une section vide mais pas l'autre → section vide disparaît
  - Loading → spinner affiché (comportement existant)
  - Erreur → message + bouton Réessayer (comportement existant)
  - Clic sur item → modale s'ouvre (comportement existant via `onDebtPressed`)
  - FAB (+) → créer une dette (comportement existant, pas géré dans ce composant)

- [x] T008 Exécuter lint et format dans `app/` : `cd app && npx ng lint && npm run format:check`

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (T001) ──────► Phase 2 (T002, T003) ──────► Phase 3 (T004) ──► Phase 4 (T006) ──► Phase 5 (T007, T008)
```

- **Phase 1** : Aucune dépendance — peut démarrer immédiatement. BLOQUE tout le reste.
- **Phase 2** : Dépend de Phase 1 (computed signals requis). T002 et T003 sont [P] (HTML et SCSS, fichiers différents). Inclut la validation US4 (opacité + badge remboursé).
- **Phase 3** : Dépend de Phase 2 (template doit être en place pour vérifier les KPI).
- **Phase 4** : Dépend de Phase 3 (bindings enrichis catégorie/date).
- **Phase 5** : Dépend de toutes les phases précédentes (polish + lint).

### User Story Dependencies

- **US1 (P1)** : Dépend de Phase 1 uniquement → peut démarrer dès Phase 1 terminée
- **US2 (P1)** : Dépend de US1 (template doit être restructuré pour vérifier les KPI)
- **US3 (P2)** : Fusionnée avec US1 (suppression sens-filter faite dans T002)
- **US4 (P2)** : Fusionnée avec US1 (opacité + badge validés dans T001/T002/T003)
- **US5 (P3)** : Dépend de Phase 3 (getSubtitle et template doivent être en place)

### Parallel Opportunities

- T002 et T003 sont [P] (HTML et SCSS — fichiers différents, mais logiquement couplés)
- T007 et T008 sont [P] dans Phase 5

---

## Implementation Strategy

### MVP (US1 + US2 — les 2 stories P1)

1. Compléter Phase 1 : refactoring signals (T001)
2. Compléter Phase 2 : sections groupées (T002, T003)
3. Compléter Phase 3 : KPI en cours (T004)
4. **STOP et VALIDER** : tester les sections et KPI → SC-001, SC-002, SC-003

### Incrémental

1. MVP (ci-dessus) → valider
2. US3 + US4 déjà intégrées dans Phase 2 (T002/T003)
3. Ajouter US5 (T006) → valider l'enrichissement items
4. Polish (T007, T008) → validation finale

---

## Notes

- Tous les changements sont dans 3 fichiers : `debts.ts`, `debts.html`, `debts.scss`
- Aucun nouveau fichier créé, aucun composant partagé modifié
- US3 et US4 sont fusionnées avec US1 dans T001/T002/T003 (suppression sens-filter + opacité/badge remboursé)
- `ListItem` est réutilisé tel quel — les bindings changent mais pas le composant
- Commit recommandé après chaque phase complétée
