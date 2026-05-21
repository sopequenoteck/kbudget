# Feature Specification: Dashboard budget summary Flutter (alignement DESIGN.md v5)

**Issue**: KKS-249 | **Parent**: KKS-242  
**Feature Branch**: `feature/flutter-screens-medium-v5`  
**Created**: 2026-05-14  
**Status**: Draft  
**Priority**: High  
**Labels**: Feature

---

## Contexte

Source de vérité : Angular `features/dashboard/components/budget-summary/budget-summary.ts` + `dashboard.html` + `dashboard.scss`.

La capture d'écran fournie montre le rendu Angular exact à reproduire. Le Flutter actuel diverge sur deux widgets :
- `BudgetSummarySection` (`budget_summary_section.dart`) — section header, sous-titre, conteneur
- `BudgetItem` (`flutter/lib/src/features/budgets/presentation/widgets/budget_item.dart`) — layout et états de la barre

`BudgetItem` est un widget partagé : il est utilisé dans `BudgetSummarySection` (dashboard) ET dans `budget_list_screen.dart` (KKS-252). L'alignement ici bénéficiera automatiquement à KKS-252.

---

## User Scenarios & Testing

### User Story 1 — Alignement BudgetItem sur Angular (P1)

L'utilisateur ouvre le dashboard et voit la liste des budgets. Chaque ligne de budget affiche l'icône colorée, le nom de la catégorie, les montants dépensé/budgété (droite), puis la barre de progression sous la ligne d'en-tête — exactement comme Angular.

**Why this priority**: C'est le cœur visuel de la section. Sans alignement `BudgetItem`, toute la section diverge de l'Angular. Impact direct sur 2 écrans (dashboard + liste budgets).

**Independent Test**: Ouvrir le dashboard avec des budgets chargés → vérifier qu'un item budget correspond pixel à pixel à la capture d'écran Angular fournie.

**Acceptance Scenarios**:

1. **Given** le dashboard affiche un budget non dépassé, **When** l'écran s'affiche, **Then** la ligne montre : cercle icône 32px (couleur catégorie) + nom à gauche + montant dépensé/budgété à droite (couleur `onSurfaceVariant`) + barre verte (income) 4px en dessous. Aucun texte de pourcentage.
2. **Given** le dashboard affiche un budget ≥ 80% et ≤ 100%, **When** l'écran s'affiche, **Then** la barre affiche la couleur `AppColors.textWarning` (amber). Les montants restent en couleur neutre.
3. **Given** le dashboard affiche un budget > 100% (dépassé), **When** l'écran s'affiche, **Then** la barre est rouge (`AppColors.expenseDark`) pleine + un marqueur vertical rouge 3px à l'extrémité droite. Les montants passent en rouge (`AppColors.expenseDark`).
4. **Given** l'état skeleton est actif, **When** le chargement est en cours, **Then** le squelette respecte le nouveau layout (cercle 32px, barre de remplacement 4px).

---

### User Story 2 — Section header, sous-titre et conteneur (P2)

L'utilisateur voit la section budget avec le bon en-tête, le bon sous-titre positionné au-dessus de la liste, et un conteneur sans bordure — identique à Angular.

**Why this priority**: Moins critique que le contenu des items, mais visible dès l'ouverture du dashboard. Le mauvais style du header et la présence d'une bordure créent un écart visuellement perceptible.

**Independent Test**: Ouvrir le dashboard → inspecter le header "Budgets · mai 2026" (style, couleur), le sous-titre "MENSUEL · EN EUR" positionné en haut de la carte, et l'absence de bordure sur le conteneur.

**Acceptance Scenarios**:

1. **Given** le dashboard s'affiche avec des budgets, **When** l'écran s'affiche, **Then** le titre de section "Budgets · mai 2026" est en `sizeMd` (16px), `fontWeight` semiBold, couleur `onSurfaceVariant` — identique à Angular `font-size: var(--font-size-base); color: var(--text-secondary)`.
2. **Given** le dashboard s'affiche, **When** la section budgets est visible, **Then** la ligne "MENSUEL · EN {devise}" (gauche) + totalDépensé / totalBudget (droite) est positionnée À L'INTÉRIEUR du conteneur, AVANT la liste des items — pas en pied de carte.
3. **Given** le dashboard s'affiche, **When** la section budgets est visible, **Then** le conteneur `surface` n'a aucune bordure `outlineVariant` — uniquement le fond et le `borderRadius`.
4. **Given** l'utilisateur clique sur "Voir tout", **When** la navigation se déclenche, **Then** la route `/budgets` (liste) s'ouvre — pas `/budgets/details`.

---

### Edge Cases

- Que se passe-t-il si `overview` est null mais `items` non vide ? → Ne pas afficher le sous-titre (la condition `overview` est nullable dans Flutter).
- Que se passe-t-il si `percentage` est exactement 80 ? → État warning (seuil inclusif `>= 80 && <= 100` comme Angular).
- Que se passe-t-il si `percentage` est exactement 100 ? → État warning (pas encore exceeded), pas de marqueur overflow.
- Que se passe-t-il si `percentage` est 0 ? → Barre track visible (couleur fond) mais fill vide. Pas de barre colorée.

---

## Requirements

### Functional Requirements

**BudgetItem — layout et états**
- **FR-001**: `BudgetItem` DOIT afficher l'icône catégorie dans un cercle de 32px (`AppSpacing.space8`) — actuellement 40px (`space10`).
- **FR-002**: `BudgetItem` DOIT utiliser le layout Angular : ligne header (icône + nom + montants côte à côte) puis barre pleine largeur en dessous — actuellement Flutter utilise icône + Column(nom, barre, montants).
- **FR-003**: `BudgetItem` NE DOIT PAS afficher de texte de pourcentage — actuellement Flutter affiche `"XX %"` à droite du nom.
- **FR-004**: La barre de progression DOIT avoir une hauteur de 4px (actuellement 6px dans Flutter).
- **FR-005**: La barre DOIT avoir 3 états couleur : normal (< 80%) → `AppColors.incomeDark.withValues(alpha: 0.7)`, warning (≥ 80% et ≤ 100%) → `AppColors.textWarning`, exceeded (> 100%) → `AppColors.expenseDark`.
- **FR-006**: Quand `percentage > 100`, un marqueur overflow DOIT être visible : trait vertical rouge 3px à l'extrémité droite de la barre (`AppColors.expenseDark`).
- **FR-007**: Les montants (dépensé / budgété) DOIVENT apparaître en rouge (`AppColors.expenseDark`) quand `percentage > 100`, en `onSurfaceVariant` sinon.
- **FR-008**: Toutes les valeurs de style DOIVENT utiliser les tokens v5 — aucune valeur hardcodée.

**BudgetSummarySection — section et conteneur**
- **FR-009**: Le titre de section "Budgets · {mois}" DOIT utiliser `AppTypography.sizeMd` (16px) et la couleur `colorScheme.onSurfaceVariant` — actuellement `sizeLg` (18px) et `onSurface`.
- **FR-010**: Le lien "Voir tout" DOIT naviguer vers `RouteNames.budgets` (`/budgets`) — actuellement navigue vers `RouteNames.budgetDetails` (`/budgets/details`).
- **FR-011**: La ligne de sous-titre "MENSUEL · EN {devise}" + total dépensé/budgété DOIT être affichée À L'INTÉRIEUR du conteneur, AVANT la liste des items — actuellement c'est un pied de carte sous les items.
- **FR-012**: Le conteneur DOIT ne pas avoir de bordure — supprimer `Border.all(color: colorScheme.outlineVariant)`.

### Non-Functional Requirements

- **NFR-001**: L'API publique de `BudgetItem` (paramètres du constructeur) NE DOIT PAS être modifiée — les callers existants (`budget_summary_section.dart`, `budget_list_screen.dart`) ne doivent pas être touchés, sauf la navigation dans `budget_summary_section.dart`.
- **NFR-002**: Les tests existants du dashboard et des budgets DOIVENT continuer à passer (aucun test existant sur ces widgets — pas de risque de régression test).
- **NFR-003**: Aucun nouveau widget ne doit être extrait en `common_widgets` — périmètre limité aux fichiers existants.

### Key Entities

- **BudgetOverviewItem**: `budgetId`, `categoryNom`, `categoryIcone`, `categoryCouleur`, `montantDepense`, `montantBudgetNormalise`, `percentage`, `currency`
- **BudgetOverview**: `items`, `totalSpent`, `totalBudget`, `currency`

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Le rendu d'un `BudgetItem` dépassé (>100%) est visuellement identique à la capture d'écran Angular : barre rouge pleine + marqueur 3px + montants en rouge.
- **SC-002**: Le rendu d'un `BudgetItem` en warning (≥80%) affiche la barre en amber (`AppColors.textWarning`).
- **SC-003**: Le rendu d'un `BudgetItem` normal (<80%) affiche la barre en vert income avec opacité 0.7.
- **SC-004**: La section header "Budgets · mai 2026" est en `sizeMd`/`onSurfaceVariant` — audit grep après implémentation.
- **SC-005**: Le sous-titre "MENSUEL · EN EUR" + total apparaît en haut de la carte, pas en pied de carte.
- **SC-006**: La navigation "Voir tout" ouvre `/budgets` (liste), vérifiable via inspection de la route.
- **SC-007**: Aucune valeur pixel hardcodée dans `budget_item.dart` ni `budget_summary_section.dart` — audit grep après implémentation.
