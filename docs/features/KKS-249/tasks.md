# Tasks: Dashboard budget summary Flutter (alignement DESIGN.md v5)

**Issue**: KKS-249 | **Date**: 2026-05-14  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Phase 1 — Setup (Vérifications préliminaires)

**Objectif** : Cartographier les callers partagés et confirmer les tokens avant modification.

- [x] T-001 Grep `BudgetItem` dans tout le codebase Flutter — confirmer les callers : `budget_summary_section.dart` et `budget_list_screen.dart` uniquement : `grep -rn "BudgetItem" flutter/lib/`
- [x] T-002 [P] Vérifier `AppRadius.xl = 16.0` dans `flutter/lib/src/constants/app_radius.dart` — confirmer token utilisable pour le conteneur

**Checkpoint** : Périmètre confirmé (2 callers connus), token AppRadius.xl confirmé. Modifications peuvent commencer.

---

## Phase 2 — Fondations (Audit tokens avant modification)

**Objectif** : Identifier toutes les valeurs hardcodées avant de toucher au code.

- [x] T-011 Auditer `budget_item.dart` — grep valeurs hardcodées : `grep -n '[0-9]\+\.0\b\|fontSize:\|width:\|height:\|minHeight:' flutter/lib/src/features/budgets/presentation/widgets/budget_item.dart`
- [x] T-012 [P] Auditer `budget_summary_section.dart` — même grep sur `flutter/lib/src/features/dashboard/presentation/widgets/budget_summary_section.dart`

**Checkpoint** : Liste exhaustive des valeurs hardcodées connue avant toute modification.

---

## Phase 3 — User Stories (Implémentation)

### US1 — Alignement BudgetItem (P1)

**Goal** : `BudgetItem` fidèle à Angular — icon 32px, layout header row + barre, 3 états, pas de %, overflow marker.

- [x] T-021 [US1] Refonte layout `BudgetItem` dans `flutter/lib/src/features/budgets/presentation/widgets/budget_item.dart` : icon `space10` → `space8`, structure Column(Row(icon+nom+montants) + barre), supprimer texte `percentageText` — Réf: FR-001, FR-002, FR-003, FR-008
- [x] T-022 [US1] Implémenter 3 états couleur barre + overflow marker + couleur montants dans `budget_item.dart` : normal → `AppColors.incomeDark.withValues(alpha: 0.7)`, warning ≥80% → `AppColors.textWarning`, exceeded >100% → `AppColors.expenseDark` + Stack/Positioned marqueur 3px + montants rouge si exceeded — Réf: FR-004, FR-005, FR-006, FR-007
- [x] T-023 [US1] Adapter `_BudgetItemSkeleton` au nouveau layout dans `budget_item.dart` : cercle 32px (`space8`), barre 4px, supprimer 3ème ligne skeleton — Réf: FR-008

**Checkpoint US1** : `BudgetItem` affiche icon 32px, header row, 3 états couleur, pas de %, overflow marker rouge. `_BudgetItemSkeleton` cohérent.

---

### US2 — Section header, sous-titre et conteneur (P2)

**Goal** : `BudgetSummarySection` identique Angular — titre `sizeMd`/`onSurfaceVariant`, sous-titre en haut, pas de border, nav correcte.

- [x] T-031 [P] [US2] Corriger style titre + navigation dans `flutter/lib/src/features/dashboard/presentation/widgets/budget_summary_section.dart` : `sizeLg` → `sizeMd`, `onSurface` → `onSurfaceVariant`, `RouteNames.budgetDetails` → `RouteNames.budgets` — Réf: FR-009, FR-010
- [x] T-032 [US2] Réorganiser conteneur dans `budget_summary_section.dart` : déplacer sous-titre "MENSUEL · EN {devise}" + total EN HAUT du conteneur (premier enfant), supprimer `Border.all(outlineVariant)`, supprimer Divider + footer "Total du mois", `AppRadius.lg` → `AppRadius.xl` — Réf: FR-011, FR-012

**Checkpoint US2** : Section affiche titre correct, sous-titre en haut, conteneur sans border, "Voir tout" → `/budgets`.

---

## Phase 4 — Polish

**Objectif** : Vérifications visuelles et tests avant merge.

- [ ] T-051 Ouvrir le dashboard avec des budgets chargés → vérifier rendu visuel `BudgetSummarySection` : sous-titre en haut, items alignés, barre 3 états, pas de %, overflow marker si budget dépassé — Réf: SC-001, SC-002, SC-003, SC-004, SC-005, SC-006
- [ ] T-052 [P] Ouvrir l'écran liste budgets → vérifier que `BudgetItem` s'affiche correctement avec `onTap` (InkWell préservé) — Réf: NFR-001
- [x] T-053 [P] Lancer `flutter test flutter/test/src/features/` — tous les tests passent sans régression — Réf: NFR-002

**Checkpoint Final** : Rendu visuel conforme à la capture Angular. Aucune régression `budget_list_screen`. Tous les tests passent.

---

## Phase 5 — Dépendances & Ordre d'exécution

### Graphe de dépendances

```
T-001 ──┐
T-002 ──┤── Checkpoint Phase 1
        │
T-011 ──┤
T-012 ──┤── Checkpoint Phase 2
        │
T-021 ←─┘ (dépend T-001, T-011 — même fichier budget_item.dart)
T-022   (dépend T-021 — même fichier, suite logique)
T-023   (dépend T-021 — skeleton adapte le nouveau layout)
        │
T-031 ←─┘ (dépend T-012 — parallèle avec T-021 : fichier distinct)
T-032   (dépend T-031 — même fichier budget_summary_section.dart)
        │
T-051   (dépend T-021, T-022, T-023, T-032)
T-052   (dépend T-021, T-022) [parallèle T-051 — écran distinct]
T-053   (dépend toute Phase 3) [parallèle T-051]
```

### Table US Dependencies

| User Story | Tâches | Dépend de |
|-----------|--------|-----------|
| US1 — BudgetItem | T-021, T-022, T-023 | T-001, T-011 (Phase 1 + 2) |
| US2 — BudgetSummarySection | T-031, T-032 | T-002, T-012 (Phase 2) |

### Parallel Opportunities

| Groupe | Condition |
|--------|-----------|
| T-002, T-012 | Dès Phase 1 — fichiers distincts |
| T-021 et T-031 | Après Phase 2 — fichiers distincts (`budget_item.dart` vs `budget_summary_section.dart`) |
| T-051, T-052, T-053 | Après Phase 3 complète |

---

## Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (icon 32px) | T-021 |
| FR-002 (layout header row + barre) | T-021 |
| FR-003 (suppr % text) | T-021 |
| FR-004 (barre 4px) | T-022 |
| FR-005 (3 états couleur) | T-022 |
| FR-006 (overflow marker) | T-022 |
| FR-007 (montants rouge si exceeded) | T-022 |
| FR-008 (tokens v5, zéro hardcode) | T-021, T-022, T-023, T-032 |
| FR-009 (titre sizeMd/onSurfaceVariant) | T-031 |
| FR-010 (nav Voir tout → /budgets) | T-031 |
| FR-011 (sous-titre en haut) | T-032 |
| FR-012 (suppr border outlineVariant) | T-032 |
| NFR-001 (BudgetItem onTap préservé) | T-052 (vérif) |
| NFR-002 (tests passent) | T-053 |
| NFR-003 (pas d'extraction common_widgets) | Contrainte implicite sur toutes les tâches |

---

## Tableau résumé

| Phase | Tâches | Parallélisables |
|-------|--------|----------------|
| Phase 1 — Setup | 2 | 1 (T-002) |
| Phase 2 — Fondations | 2 | 1 (T-012) |
| Phase 3 — US1 (P1) | 3 | 0 |
| Phase 3 — US2 (P2) | 2 | 1 (T-031 vs T-021) |
| Phase 4 — Polish | 3 | 2 (T-052, T-053) |
| **Total** | **12** | **5** |

---

## Implementation Strategy

### MVP First (US1 uniquement)

1. Phase 1 : T-001, T-002
2. Phase 2 : T-011
3. US1 : T-021, T-022, T-023
4. **STOP** : Vérifier `BudgetItem` visuellement sur dashboard et liste budgets

### Incremental Delivery

1. Setup + Audit → périmètre confirmé
2. US1 (BudgetItem) → rendu fidèle Angular
3. US2 (BudgetSummarySection) → section complète alignée
4. Polish → tests, inspection visuelle, validation commits
