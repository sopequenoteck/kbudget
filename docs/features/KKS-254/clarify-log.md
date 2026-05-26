# Clarify Log — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

> Date : 2026-05-22
> Issue : KKS-254
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | spec.md §Cas limites + §Questions ouvertes | Budget inactif absent de l'overview : fallback ou "Budget introuvable" ? | 6 — Edge cases | H | H | **CRITIQUE** | Fallback sur `budgetNotifierProvider.state.items` | Auto |
| CL-002 | spec.md FR-003 + §Questions ouvertes | Items inactifs de la liste : `onTap` vers détail ou `null` ? | 3 — UX/Interaction | M | M | **MOYEN** | `onTap` vers détail (aligné Angular) | Auto |
| CL-003 | spec.md FR-028 + §Questions ouvertes | `onChartsTap` de `BudgetHeroWidget` : supprimer ou no-op ? | 1 — Scope fonctionnel | M | M | **MOYEN** | Suppression (YAGNI — pie chart global retiré) | Auto |
| CL-004 | spec.md A-004 | Accounts chargés dans le notifier au moment d'afficher le détail ? | 5 — Intégrations | M | B | **BAS** | `loadItems()` à l'`initState` si liste vide + fallback devise budget | Auto |

---

## Résolutions détaillées

### CL-001 — Budget inactif : fallback vs "Budget introuvable"

- **Catégorie** : 6 — Edge cases
- **Score** : CRITIQUE
- **Contexte** : L'API `GET /budgets/overview` ne remonte que les budgets actifs. Un budget inactif tapé depuis la liste (items inactifs dans `budget_list_screen`) n'est pas trouvable via l'overview seul. La spec marquait ce cas comme NEEDS CLARIFICATION.
- **Analyse** : Angular `budget-detail.ts:229-250` implémente un fallback explicite : si l'item n'est pas trouvé dans l'overview ET que le mois est courant, un appel `getAll(true)` est effectué pour récupérer le budget complet. En Flutter, `budget_list_screen` appelle déjà `budgetNotifierProvider.notifier.loadItems(includeInactive: true)` (ligne 63) avant de naviguer vers le détail. Résultat : `budgetNotifierProvider.state.items` contient tous les budgets (actifs + inactifs) au moment où l'écran de détail s'ouvre.
- **Décision** : Fallback sur `budgetNotifierProvider.state.items` filtré par `categoryId` — aucune requête API supplémentaire. Si introuvable dans les items → afficher "Budget introuvable". Aligne avec le comportement Angular sans surcoût réseau.
- **Impact sur spec.md** : Section "Cas limites" mise à jour (NEEDS CLARIFICATION retiré, comportement précisé). Question CL-001 marquée "Résolu".

---

### CL-002 — Items inactifs : `onTap` vers détail ou `null` ?

- **Catégorie** : 3 — UX/Interaction
- **Score** : MOYEN
- **Contexte** : Dans `budget_list_screen`, les items inactifs ont actuellement `onTap: null` (ligne 449). La spec demandait si ce comportement devait changer.
- **Analyse** : Angular `budget-list.html:147` : `<button class="budget-row inactive clickable" (click)="onBudgetPressed(item)">` — les items inactifs sont cliquables et naviguent vers le détail via `onBudgetPressed`. L'opacity 0.5 est visuelle uniquement, pas comportementale.
- **Décision** : Items inactifs Flutter → `onTap` vers `/budgets/details?categoryId=X&month=YYYY-MM`. Conservation de l'opacity 0.5. FR-003 mis à jour dans la spec.
- **Impact sur spec.md** : FR-003 (marker NEEDS CLARIFICATION retiré, comportement précisé). Question CL-002 marquée "Résolu".

---

### CL-003 — `onChartsTap` de `BudgetHeroWidget` : supprimer ou no-op ?

- **Catégorie** : 1 — Scope fonctionnel
- **Score** : MOYEN
- **Contexte** : `BudgetHeroWidget` expose un callback `onChartsTap` utilisé en deux points dans `budget_list_screen.dart` (lignes 364 et 525) pour ouvrir l'ancien `BudgetDetailScreen` (pie chart global). Avec KKS-254, cet écran change de sémantique — il devient un écran de détail par catégorie, non navigable sans `categoryId`.
- **Analyse** : Constitution Principe III — YAGNI. Le callback `onChartsTap` n'a plus de cible valide après KKS-254. Garder un no-op laisserait du code mort. Supprimer = diff minimal, codebase propre.
- **Décision** : Supprimer `onChartsTap` de `BudgetHeroWidget` (paramètre + logique interne). Retirer les deux appels dans `budget_list_screen.dart`. Inclus dans US-004 (nettoyage). FR-028 mis à jour dans la spec.
- **Impact sur spec.md** : FR-028 (marker NEEDS CLARIFICATION retiré, décision précisée). Question CL-003 marquée "Résolu".

---

### CL-004 — Accounts disponibles via `accountNotifierProvider` au moment du détail

- **Catégorie** : 5 — Intégrations
- **Score** : BAS
- **Contexte** : La spec (A-004) assumait que les accounts sont déjà chargés dans Riverpod quand l'écran de détail s'ouvre. Non garanti si l'utilisateur navigue directement vers le détail.
- **Analyse** : `account_notifier.dart` expose `loadItems()` standard. Le pattern Flutter des autres écrans de détail (ex: `BudgetDetailScreen` actuel) charge les données à l'`initState` via `WidgetsBinding.instance.addPostFrameCallback`. Même pattern applicable ici : vérifier `state.items.isEmpty` → `loadItems()`.
- **Décision** : L'écran détail appelle `accountNotifierProvider.notifier.loadItems()` dans `initState` si `state.items.isEmpty`. La résolution `accountId → currency` se fait via une map construite à partir de `state.items`. Fallback : devise du budget si `accountId == null` ou compte non trouvé dans la map.
- **Impact sur spec.md** : A-004 mise à jour (assumption précisée avec le pattern d'implémentation).

---

## Points différés

> Aucun point différé — les 4 points identifiés ont tous été résolus dans cette session.

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 4 |
| Catégories couvertes | 4/11 (Edge cases, UX/Interaction, Scope fonctionnel, Intégrations) |
| Résolus automatiquement | 4 |
| Résolus interactivement | 0 |
| Différés | 0 |
| Modifications spec.md | 6 (FR-003, FR-028, §Cas limites, A-004, §Questions ouvertes ×3) |
