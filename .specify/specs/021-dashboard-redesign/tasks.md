# Tasks: Réorganisation complète du Dashboard

**Input**: Design documents from `/specs/021-dashboard-redesign/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Non demandés — aucune tâche de test générée.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3)
- Chemins exacts inclus dans chaque description

## Path Conventions

- **Frontend**: `app/src/` (projet Angular)
- **Styles**: `app/src/styles/` (design system SCSS)

---

## Phase 1: Setup (Design Token `--color-subscription`)

**Purpose**: Ajouter le token sémantique bleu pour les abonnements — prérequis pour les mini-cards US1.

- [x] T001 [P] Ajouter les variables SCSS `$subscription` (#2563eb) et `$subscription-light` (#dbeafe) dans `app/src/styles/tokens/_primitives.scss`
- [x] T002 [P] Ajouter le token `--color-subscription: #2563eb` dans la section business tokens de `app/src/styles/themes/_light.scss`
- [x] T003 [P] Ajouter le token `--color-subscription: #60a5fa` dans la section business tokens de `app/src/styles/themes/_dark.scss`

---

## Phase 2: User Story 1 — Vue d'ensemble financière instantanée (Priority: P1) :dart: MVP

**Goal**: Regrouper les 6 KPI en haut du dashboard (rang 1 : recettes/dépenses/solde, rang 2 : abos/je dois/on me doit) avec mini-cards cliquables et séparateur.

**Independent Test**: Vérifier que les 6 indicateurs sont visibles au-dessus de la ligne de flottaison sur mobile 375px. Changer de mois → seul rang 1 change. Cliquer mini-card → navigation vers page dédiée.

### Implementation for User Story 1

- [x] T004 [US1] Ajouter le computed signal `miniCardsLoading` (combine `subscriptionsLoading` et `debtsLoading`) dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T005 [US1] Restructurer le template : envelopper le sélecteur de mois + cards résumé dans `<section class="kpi-zone">`, ajouter rang 2 avec 3 mini-cards (`<a routerLink>`) utilisant `monthlySubTotal()`, `totalJeDois()`, `totalOnMeDoit()`, ajouter état loading rang 2 (si `miniCardsLoading()` → spinner, sinon mini-cards ; pas d'état d'erreur dédié — les mini-cards affichent 0 € en cas d'échec, le feedback erreur est dans les sections listes correspondantes), ajouter séparateur `<hr class="kpi-separator">` dans `app/src/app/features/dashboard/dashboard.html`
- [x] T006 [US1] Ajouter les styles : `.kpi-zone` (CSS Grid 2 rangées — cf. research R2), `.kpi-zone__row` (flex row interne pour les cards de chaque rangée), `.mini-card` (barre colorée 3px en haut via `border-top`, compact, hover), `.mini-card--subscription`/`--debt-owe`/`--debt-owed` (couleurs via tokens), `.kpi-separator`, état loading mini dans `app/src/app/features/dashboard/dashboard.scss`

**Checkpoint**: Les 6 KPI sont visibles en haut. Mini-cards cliquables. Rang 2 indépendant du sélecteur de mois.

---

## Phase 3: User Story 2 — Listes de détail épurées (Priority: P2)

**Goal**: Supprimer les résumés texte dupliqués des sections liste et afficher les dettes en positif avec label contextuel.

**Independent Test**: Vérifier l'absence de "Total mensuel" dans la section abonnements et de "Je dois / On me doit" dans la section dettes. Vérifier que les items dette affichent montant positif + "Emprunt" ou "Prêt".

### Implementation for User Story 2

- [x] T007 [US2] Supprimer le bloc `dashboard-section__subtitle` de la section abonnements et le bloc `dashboard-section__subtitle--debts` de la section dettes, modifier les items dette : `[value]` sans paramètre type (`debt.montant | amount`), `[subtitle]` avec label contextuel (`debt.sens === 'EMPRUNT' ? 'Emprunt' : 'Prêt'`), `[rightSubtitle]` avec date relative dans `app/src/app/features/dashboard/dashboard.html`
- [x] T008 [US2] Supprimer les styles orphelins `.dashboard-section__subtitle`, `.dashboard-section__subtitle--debts`, `.debt-summary`, `.debt-summary--owe`, `.debt-summary--owed` dans `app/src/app/features/dashboard/dashboard.scss`

**Checkpoint**: Aucun résumé texte dans les sections liste. Dettes affichées en positif avec label.

---

## Phase 4: User Story 3 — Cohérence visuelle mini-cards (Priority: P3)

**Goal**: Harmoniser visuellement les mini-cards avec les cards rang 1 et garantir le responsive 375px.

**Independent Test**: Comparer visuellement mini-cards vs cards rang 1 (arrondis, ombres, typo). Tester en thème clair et sombre. Vérifier 375px : 3 mini-cards côte à côte sans débordement ni troncature.

### Implementation for User Story 3

- [x] T009 [US3] Affiner les mini-cards : mêmes `border-radius` (`var(--radius-xl)`) et `box-shadow` (`var(--shadow-md)`) que `.summary__card`, typographie label cohérente (`font-size-xs`, `uppercase`), vérifier alignement vertical entre rangées, media query 375px garantissant 3 colonnes sans overflow dans `app/src/app/features/dashboard/dashboard.scss`

**Checkpoint**: Mini-cards visuellement cohérentes avec rang 1. Rendu correct en thème clair/sombre. Pas de débordement sur 375px.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale multi-critères.

- [x] T010 Exécuter la validation quickstart.md : (1) 6 KPI en haut, (2) mini-cards cliquables, (3) sections listes sans résumé, (4) dettes positives + label, (5) thème clair et sombre, (6) viewport 375px sans débordement

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendance — peut démarrer immédiatement
- **US1 (Phase 2)**: Dépend de Phase 1 (token `--color-subscription` requis pour les mini-cards)
- **US2 (Phase 3)**: Dépend de Phase 2 (le template restructuré est la base pour les suppressions)
- **US3 (Phase 4)**: Dépend de Phase 2 (les styles mini-cards doivent exister pour être affinés)
- **Polish (Phase 5)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Peut démarrer après Setup — aucune dépendance sur autres stories
- **US2 (P2)**: Dépend de US1 (template restructuré en Phase 2 — même fichier HTML)
- **US3 (P3)**: Dépend de US1 (styles mini-cards créés en Phase 2 — même fichier SCSS)
- **US2 et US3 sont indépendantes entre elles** mais dépendent toutes deux de US1

### Within Each User Story

- TS avant HTML (signals avant template)
- HTML avant SCSS (structure avant style)
- Core implementation avant polish

### Parallel Opportunities

- T001, T002, T003 en parallèle (fichiers différents)
- US2 (T007-T008) et US3 (T009) peuvent théoriquement être parallélisées (fichiers HTML vs SCSS) mais partagent dashboard.scss — recommandé séquentiel

---

## Parallel Example: Phase 1 Setup

```bash
# Les 3 tâches de setup en parallèle (3 fichiers SCSS différents) :
Task: "Ajouter $subscription dans _primitives.scss"
Task: "Ajouter --color-subscription dans _light.scss"
Task: "Ajouter --color-subscription dans _dark.scss"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (3 tâches token)
2. Compléter Phase 2: US1 (3 tâches KPI zone)
3. **STOP et VALIDER**: 6 KPI visibles en haut, mini-cards cliquables
4. Deploy/demo si prêt

### Incremental Delivery

1. Setup (T001-T003) → Tokens prêts
2. US1 (T004-T006) → KPI zone fonctionnelle (MVP!)
3. US2 (T007-T008) → Listes épurées
4. US3 (T009) → Cohérence visuelle
5. Polish (T010) → Validation finale
6. Chaque story ajoute de la valeur sans casser les précédentes

---

## Notes

- Feature purement frontend — aucune modification backend
- 6 fichiers modifiés : 3 SCSS tokens + 3 fichiers dashboard
- Computed signals existants (`monthlySubTotal`, `totalJeDois`, `totalOnMeDoit`) réutilisés
- Mini-card interne au dashboard (pas de composant shared — YAGNI)
- `routerLink` déjà importé dans le dashboard
