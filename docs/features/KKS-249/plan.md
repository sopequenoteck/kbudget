# Implementation Plan: Dashboard budget summary Flutter (alignement DESIGN.md v5)

**Issue**: KKS-249 | **Branch**: `feature/flutter-screens-medium-v5` | **Date**: 2026-05-14  
**Spec**: [spec.md](spec.md)

---

## Summary

Alignement de `BudgetSummarySection` et `BudgetItem` Flutter sur le rendu Angular (source de vérité visuelle). Deux modifications concrètes : (1) refonte layout `BudgetItem` — icon 32px, header row + barre, 3 états couleur, pas de %, overflow marker ; (2) alignement `BudgetSummarySection` — sous-titre haut, pas de footer, pas de border. Aucun nouveau composant, aucune logique métier modifiée.

---

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27  
**Primary Dependencies**: flutter_riverpod, AppSpacing, AppTypography, AppColors, AppRadius (tokens v5)  
**Storage**: N/A (aucun schéma Drift modifié)  
**Testing**: flutter_test (aucun test existant sur ces widgets — vérification manuelle)  
**Target Platform**: iOS + Android (Trajectoire B — Standalone Commercial)  
**Project Type**: Mobile app  
**Performance Goals**: N/A (refonte purement visuelle)  
**Constraints**: API publique `BudgetItem` (constructeur + paramètres) non modifiable — `budget_list_screen.dart` est un caller existant

---

## Constitution Check

| Principe | Applicable | Statut | Notes |
|----------|-----------|--------|-------|
| I — API-First / Local-First | Non | ✅ N/A | Aucun endpoint modifié, aucun schéma Drift touché |
| II — Sécurité | Non | ✅ N/A | Pas de routes, pas de secrets |
| III — Simplicité & YAGNI | Oui | ✅ PASS | Suppression footer + border = simplification nette |
| IV — Mobile-First UX | Oui | ✅ PASS | Alignement fidélité visuelle sur Angular améliore l'expérience |
| V — Testabilité | Oui | ✅ PASS | API publique `BudgetItem` inchangée, aucun test existant cassé |
| VI — Observabilité | Oui | ✅ PASS | Aucun `print()` à introduire |
| VII — Two Trajectories | Non | ✅ N/A | Trajectoire B uniquement, pas d'impact sync |

**Résultat : PASS — aucune gate violée.**

---

## Architecture — Fichiers impactés

### Modifications (M)

| Fichier | Nature | FR couverts |
|---------|--------|-------------|
| `flutter/lib/src/features/budgets/presentation/widgets/budget_item.dart` | Refonte layout + 3 états barre + icon 32px + overflow marker | FR-001 à FR-008 |
| `flutter/lib/src/features/dashboard/presentation/widgets/budget_summary_section.dart` | Titre style, nav, sous-titre haut, suppr. border + footer | FR-009 à FR-012 |

### Vérification sans modification attendue

| Fichier | Vérification |
|---------|-------------|
| `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` | Caller `BudgetItem` avec `onTap` — comportement InkWell préservé après refactoring layout |
| `flutter/lib/src/features/budgets/presentation/budget_detail_screen.dart` | Utilise `_BudgetItemRow` (privé, distinct de `BudgetItem`) — non impacté |

### Aucun fichier à créer

---

## Approche détaillée par composant

### 1. Refonte `BudgetItem` — layout et états

**FR couverts** : FR-001 à FR-008

#### 1.1 Icon size

```dart
// Avant
width: AppSpacing.space10,   // 40px
height: AppSpacing.space10,

// Après
width: AppSpacing.space8,    // 32px → --space-8 Angular
height: AppSpacing.space8,
```

#### 1.2 Layout — passer de Column imbriquée à header row + barre

Layout Angular :
```
Row(icon | nom (flex:1) | montants (right))
SizedBox(height: space2)
barre 4px pleine largeur
```

Actuellement Flutter :
```
Row(icon | Column(Row(nom | %age) | barre | montants))
```

Cible Flutter :
```dart
Column(
  children: [
    Row(
      children: [
        // Icône 32px
        Container(width: space8, height: space8, ...),
        SizedBox(width: space3),
        // Nom (flex: 1)
        Expanded(child: Text(categoryNom, ...)),
        // Montants droite (rouge si exceeded)
        Text('$formattedSpent / $formattedBudget', style: TextStyle(color: amountsColor)),
      ],
    ),
    SizedBox(height: AppSpacing.space2),
    // Barre pleine largeur avec Stack pour overflow marker
    _buildProgressBar(clampedProgress, barColor, isOverBudget),
  ],
)
```

#### 1.3 Supprimer le texte de pourcentage

Retirer `percentageText` et le `Text(percentageText, ...)` dans la Row du nom.

#### 1.4 Trois états couleur de la barre

```dart
final Color barColor;
if (percentage > 100) {
  barColor = AppColors.expenseDark;   // exceeded → rouge
} else if (percentage >= 80) {
  barColor = AppColors.textWarning;   // warning → amber
} else {
  barColor = AppColors.incomeDark.withValues(alpha: 0.7);  // normal → vert
}
```

#### 1.5 Hauteur de la barre : 6px → 4px

```dart
minHeight: 4,  // était 6
```

#### 1.6 Overflow marker (> 100%)

Utiliser `Stack` + `Positioned` :
```dart
Widget _buildProgressBar(double clampedProgress, Color barColor, bool isOverBudget) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.round),
        child: LinearProgressIndicator(
          value: clampedProgress,
          minHeight: 4,
          backgroundColor: colorScheme.outlineVariant,
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ),
      if (isOverBudget)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              color: AppColors.expenseDark,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppRadius.round),
                bottomRight: Radius.circular(AppRadius.round),
              ),
            ),
          ),
        ),
    ],
  );
}
```

#### 1.7 Couleur montants

```dart
final Color amountsColor = isOverBudget
    ? AppColors.expenseDark
    : colorScheme.onSurfaceVariant;
```

#### 1.8 Skeleton — adapter au nouveau layout

Le skeleton `_BudgetItemSkeleton` doit suivre le nouveau layout : Row(cercle 32px + lignes) puis barre 4px. Supprimer la troisième ligne (montants) qui n'est plus visible séparément.

#### 1.9 Compatibilité `onTap`

Le pattern `InkWell(child: content)` est conservé tel quel — `content` reste un `Padding` wrappant le `Column`. Les callers `budget_list_screen.dart` ne voient aucun changement.

---

### 2. Alignement `BudgetSummarySection`

**FR couverts** : FR-009 à FR-012

#### 2.1 Titre de section — style

```dart
// Avant
fontSize: AppTypography.sizeLg,    // 18px
color: colorScheme.onSurface,

// Après
fontSize: AppTypography.sizeMd,    // 16px → --font-size-base Angular
color: colorScheme.onSurfaceVariant, // --text-secondary Angular
```

#### 2.2 Navigation "Voir tout"

```dart
// Avant
context.push(RouteNames.budgetDetails)  // /budgets/details

// Après
context.push(RouteNames.budgets)        // /budgets
```

#### 2.3 Sous-titre — déplacer du footer vers le haut

Supprimer le bloc footer existant (Divider + Padding "Total du mois"). Ajouter le sous-titre en PREMIER enfant du conteneur, avant la liste des items :

```dart
Container(
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    // Plus de border
  ),
  child: Column(
    children: [
      // Sous-titre en premier (si overview != null)
      if (overview != null)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MENSUEL · EN ${overview!.currency}',
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.05 * AppTypography.sizeXs,
                ),
              ),
              Text(
                '${AmountFormatter.format(...)} / ${AmountFormatter.format(...)}',
                style: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      // Items
      ...displayItems.map((item) => BudgetItem(...)),
      // Plus de Divider ni footer
    ],
  ),
)
```

#### 2.4 Supprimer le border du conteneur

```dart
// Avant
border: Border.all(color: colorScheme.outlineVariant),

// Après
// (ligne supprimée — uniquement color + borderRadius)
```

#### 2.5 Skeleton — vérifier alignement

Le skeleton header garde le même placeholder `width: 80`. Le conteneur skeleton perd aussi sa bordure. Cohérent.

---

## Risques & Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| `BudgetItem` partagé → changement layout affecte `budget_list_screen.dart` | Certaine | Acceptable | Voulu — anticipe KKS-252. Pattern `InkWell(child: content)` préservé. Inspection visuelle budget_list après changement |
| `Stack` + `Positioned` sur barre → overflow visuel si conteneur trop petit | Faible | Mineur | `Stack` clampé par la largeur naturelle de la barre, pas de débordement horizontal |
| `overview` null → crash sous-titre | Faible | Bloquant | Condition `if (overview != null)` déjà présente dans le code existant — conserver |
| `AppRadius.xl` absent → compiler error | Faible | Bloquant | Vérifier les constantes AppRadius disponibles avant usage |

---

## Hors scope

- Modification de `budget_list_screen.dart` (KKS-252)
- Modification de `budget_detail_screen.dart` (utilise `_BudgetItemRow`, widget privé distinct)
- Tri des items (déjà implémenté côté Flutter par `percentage` décroissant)
- Empty state du dashboard (déjà géré par `BudgetSummarySection`)
- Toute modification de la logique métier (calcul percentage, tri, filtrage)
- Extraction de nouveaux widgets en `common_widgets`

---

## Complexity Tracking

Aucune violation de gate.

| Éventuel | Justification |
|----------|--------------|
| `Stack` + `Positioned` pour overflow marker | Pattern minimal pour le marqueur 3px — pas de widget dédié justifié (usage unique, 3 lignes de code) |
| `_buildProgressBar` helper privé | La barre avec Stack est répétée dans `build()` uniquement. Extraction en helper privé évite le nesting excessif sans surconception |
