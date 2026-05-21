# Clarify Log — KKS-250 : Comptes liste Flutter (alignement DESIGN.md v5)

> Date : 2026-05-21
> Issue : KKS-250
> Spec : [spec.md](./spec.md)

---

## Points de clarification

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Résolution | Méthode |
|---|--------|-----------------|-----------|--------|-------------|-------|------------|---------|
| CL-001 | FR-001 | `AccountBankIcon.size` sémantique : formule `size × 1.5` → ambiguïté conteneur vs icône | 7 Contraintes | H | H | **CRITIQUE** | Modifier `AccountBankIcon`, passer `size: space8` | Auto |
| CL-002 | FR-007 | SliverList → carte surface : pas de stratégie d'implémentation Flutter spécifiée | 7 Contraintes | H | H | **CRITIQUE** | `SliverToBoxAdapter(Container(Column))` | Auto |
| CL-003 | FR-008 | Doublon AppBar `+` vs section header `+` : supprimer lequel ? | 1 Scope | M | M | **MOYEN** | Supprimer AppBar `actions`, Angular source de vérité | Auto |
| CL-004 | NFR-001 | `PEUT être étendue` ambigu si US3 dans le scope | 3 UX/Interaction | M | M | **MOYEN** | DOIT si US3, interface précisée | Auto |
| CL-005 | Edge cases | "1 comptes" : grammaticalement incorrect, intentionnel ? | 10 Placeholders | B | B | **BAS** | Alignement Angular intentionnel | Auto |
| CL-006 | FR-005 | Padding badge `6px` hardcodé (pas de token `space-1-5`) | 7 Contraintes | B | B | **BAS** | — | Différé |
| CL-007 | A-001 | Import CSV : assumption non confirmée explicitement par grep | 1 Scope | B | B | **BAS** | — | Différé |

---

## Résolutions détaillées

### CL-001 — AccountBankIcon.size : sémantique conteneur

- **Catégorie** : 7 — Contraintes techniques
- **Score** : CRITIQUE
- **Contexte** : `AccountBankIcon` Flutter utilise `width: size * 1.5, height: size * 1.5` pour le conteneur, et `size * 0.8` pour l'emoji. Ainsi `size: AppSpacing.space10 = 40` → conteneur 60px. La spec FR-001 visait un cercle de 32px (alignement Angular `[size]="32"`), mais passer `size: 32` donnerait un conteneur de 48px, pas 32px.
- **Analyse** : Grep sur l'ensemble de `flutter/lib` confirme qu'`AccountBankIcon` n'a qu'**un seul caller** (`account_list_tile.dart`). La modification de la formule interne n'a aucun impact sur d'autres composants. Le skeleton utilise aussi `AppSpacing.space10` pour son cercle — devra être aligné.
- **Décision** : Modifier `AccountBankIcon` pour que `size` = diamètre du conteneur extérieur. Nouvelle formule : `Container(width: size, height: size)`, icône intérieure = `size * 0.67` (SVG) / `size * 0.55` (emoji). Passer `size: AppSpacing.space8` (32px) dans `AccountListTile`. Skeleton: `AppSpacing.space10` → `AppSpacing.space8`.
- **Impact sur spec.md** : FR-001 mis à jour avec la stratégie de modification et les ratios internes.

---

### CL-002 — SliverList → conteneur carte `surface`

- **Catégorie** : 7 — Contraintes techniques
- **Score** : CRITIQUE
- **Contexte** : Angular enveloppe `<ul>` dans `.accounts-section__container` (`background: surface-default; border-radius: radius-xl; overflow: hidden`). Flutter actuel : `SliverList.builder` nu sans carte. La spec FR-007 dit "enveloppée dans une carte" sans préciser l'implémentation Flutter.
- **Analyse** : Flutter ne peut pas clipper un `SliverList` directement avec un `BorderRadius`. Options : (A) `SliverToBoxAdapter(Container(Column(items)))` — items non-lazy mais liste courte (<20 comptes). (B) `SliverClip` expérimental — non stable. L'option A préserve `CustomScrollView` et `RefreshIndicator`, acceptée pour la taille de liste attendue.
- **Décision** : Remplacer `SliverList.builder` par deux `SliverToBoxAdapter` : un pour la section header, un pour le `Container(surface/radius-xl/clip, Column(items + Dividers))`. `RefreshIndicator` + `CustomScrollView` préservés.
- **Impact sur spec.md** : FR-007 mis à jour avec la stratégie `SliverToBoxAdapter` et la justification lazy/non-lazy.

---

### CL-003 — AppBar `+` vs section header `+`

- **Catégorie** : 1 — Scope fonctionnel
- **Score** : MOYEN
- **Contexte** : Flutter actuel a un `IconButton(+)` dans `AppBar.actions`. La spec FR-008 ajoute un `+` circulaire dans la section header. Sans clarification, les deux existent simultanément.
- **Analyse** : Angular `accounts.html` : le `<div class="page-header">` contient uniquement le bouton back et le titre — aucun `+`. Le `+` est exclusif à `<div class="accounts-section__header">`. Angular est la source de vérité.
- **Décision** : Supprimer `AppBar.actions` dans `AccountListScreen`. La navigation de création reste identique (même route) mais déclenchée depuis le bouton de la section header.
- **Impact sur spec.md** : FR-008 mis à jour avec la note de suppression de l'AppBar `+`.

---

### CL-004 — NFR-001 : PEUT vs DOIT pour l'API AccountListTile

- **Catégorie** : 3 — UX/Interaction
- **Score** : MOYEN
- **Contexte** : NFR-001 disait "PEUT être étendue". Or US3 (delete confirm inline, P3) est dans le scope et nécessite obligatoirement ces paramètres côté tile pour le pattern lift-state.
- **Analyse** : Le mot "PEUT" créait une ambiguïté : si US3 est implémentée, l'extension de l'API est non-optionnelle. La conditionnalité (US3 dans le scope ou non) est la vraie variable.
- **Décision** : NFR-001 reformulé en "DOIT si US3 implémentée" avec l'interface complète précisée (`isConfirmingDelete`, `deleteError`, `onRequestDelete`, `onConfirmDelete`, `onCancelDelete`, `onEdit`). `AccountListTile` reste `ConsumerWidget`.
- **Impact sur spec.md** : NFR-001 mis à jour avec interface cible complète.

---

### CL-005 — "1 comptes" : pluriel dynamique

- **Catégorie** : 10 — Placeholders / Terminologie
- **Score** : BAS
- **Contexte** : Le label de section affiche "{N} comptes". Pour N=1, "1 comptes" est grammaticalement incorrect en français.
- **Analyse** : Angular `{{ accounts().length }} comptes` — aucune gestion de pluriel. Le label est affiché en uppercase (`TEXT-TRANSFORM: uppercase`) → "1 COMPTES". La cible est l'alignement visuel avec Angular, pas la correction grammaticale.
- **Décision** : "1 comptes" est accepté comme alignement intentionnel avec Angular. Pas de pluralisation dynamique (`compte` vs `comptes`). Documenté dans Edge cases.
- **Impact sur spec.md** : Edge case mis à jour pour clarifier "alignement intentionnel avec Angular".

---

## Points différés

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| CL-006 | FR-005 | Padding badge `6px` hardcodé — pas de token `space-1-5` en Flutter | 7 Contraintes | B | B | BAS | Acceptable, documenté dans FR-005 — pas de décision bloquante |
| CL-007 | A-001 | Import CSV absent en Flutter — assumption non vérifiée par grep explicite | 1 Scope | B | B | BAS | Vérification grep antérieure sans résultat confirme l'absence |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 7 |
| Catégories couvertes | 3/11 (Scope, Contraintes, UX/Interaction, Placeholders) |
| Résolus automatiquement | 5 |
| Résolus interactivement | 0 |
| Différés | 2 |
| Modifications spec.md | 5 (FR-001, FR-007, FR-008, NFR-001, Edge cases) |
