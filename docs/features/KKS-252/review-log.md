# Review Log — KKS-252

---

## Itération 1 — 2026-05-21 | review-spec | BLOQUANT → corrigé → PASS

**Agent** : devflow-review  
**Verdict initial** : BLOQUANT (2 constats bloquants)  
**Verdict après corrections** : PASS (corrections appliquées immédiatement)  
**Constats** : 2 BLOQUANT · 5 WARNING · 4 INFO

### Bloquants (corrigés)

| ID | Localisation | Description | Correction |
|----|-------------|-------------|------------|
| B-1 | `spec.md` FR-015 | `budgetId` queryParam inexistant dans `BudgetDetailScreen` (vue graphique globale, pas par item) — CL-007 différé à tort | FR-015 corrigé : tap item = modal `ModalType.budget` (comportement actuel conservé) |
| B-2 | `spec.md` NFR-003 | "Dériver de BudgetPieChart" impossible en Dart avec une interface différente ; `color: String` incompatible avec `PieChartItem.color: Color` | NFR-003 corrigé : widget standalone indépendant, conversion hex→Color via `parseHexColor()` interne |

### Warnings (corrigés)

| ID | Localisation | Description | Correction |
|----|-------------|-------------|------------|
| W-1 | `spec.md` FR-001 | Formule `totalSpent - unbudgetedTotal` non précisée pour le mode historique | FR-001 complété : "s'applique aussi en mode historique" |
| W-2 | `spec.md` FR-011 | Définition de "catégorie système" manquante | FR-011 précisé : `isSystem=false`, exemple "Non catégorisé" |
| W-3 | `spec.md` FR-008 | Mécanisme debounce non résolu (CL-006 différé) → testabilité compromise | FR-008 précisé : `dart:async Timer` cancelable, testable via `fakeAsync` |
| W-4 | `spec.md` FR-011 US3/S3 | Rendu visuel "désactivé" non précisé | FR-011 précisé : `onPressed: null`, apparence grisée |
| W-5 | `spec.md` Key Entities | Fallback `activeCurrency` si `currencies.isEmpty` non documenté | Key Entities Currency : fallback `Currency.eur` documenté |

### Infos (corrigés)

| ID | Localisation | Description | Correction |
|----|-------------|-------------|------------|
| I-1 | `spec.md` US4, FR-003 | Terme "SVG" résiduel après correction NFR-003 | US4 titre, FR-003, US4/S1, US1/S5 nettoyés |
| I-2 | `spec.md` Edge Cases | `allCategoriesHaveBudget` absent des Edge Cases | Non corrigé (non bloquant, FR-011 suffit) |
| I-3 | `spec.md` NFR-007 | `categoryNotifierProvider` absent de la liste des overrides test | NFR-007 complété |
| I-4 | `clarify-log.md` CL-007 | Justification CL-007 circulaire ("confirmé au plan") | Résolu par correction B-1 (FR-015 clarifié) |

---

## Itération 1 — 2026-05-21 | review-tasks | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 3 WARNING · 2 INFO

### Couverture

| Vérification | Résultat |
|---|---|
| FR couverts (18/18) | ✅ PASS |
| NFR couverts (7/7) | ✅ PASS |
| Sections plan couvertes (11/11) | ✅ PASS |
| Tâches fantômes | ✅ Aucune |
| Mapping Requirements cohérent | ✅ PASS |

### Warnings (non bloquants)

| ID | Description |
|----|-------------|
| W-001 | Graphe Phase 5 : 3 arêtes manquantes — T-031 dépend de T-022 + T-030 ; T-032 et T-033 dépendent de T-021. MVP path impose l'ordre correct en pratique. |
| W-002 | T-002 absent du graphe Phase 5 (présent dans le MVP path uniquement) |
| W-003 | T-051 : test SC-003 (fakeAsync debounce) regroupé avec 4 cas simples — risque de blocage global si SC-003 difficile |

### Infos

| ID | Description |
|----|-------------|
| I-001 | T-022 granularité élevée (7 FR, ~80L) — acceptable si T-021 complété avant |
| I-002 | Tableau résumé "Parallélisables" sous-estime le total réel (7 tâches [P] vs 2 comptabilisées en phase US) |
