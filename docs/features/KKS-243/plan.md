# Plan — KKS-243 : Phase 1 / Étape 7 — Refonte 3 écrans S Flutter

> Date : 2026-05-27
> Issue : KKS-243
> Spec : [spec.md](./spec.md)

---

## Constitution Check

| Gate | Statut | Commentaire |
|------|--------|-------------|
| I — API-First / Local-First | ✅ PASS | Aucune couche data touchée. UI-only. |
| II — Sécurité par défaut | ✅ PASS | Pas de route API, pas de données sensibles, pas de secret. |
| III — Simplicité & YAGNI | ✅ PASS | Modifications minimales sur 4 fichiers existants. Aucune abstraction nouvelle. |
| IV — Mobile-First UX | ✅ PASS | Améliore la cohérence visuelle et les patterns d'interaction (PageHeader, EmptyStateWidget, ConfirmDialogCustom). |
| V — Testabilité | ✅ PASS | Patterns existants conservés. `flutter analyze` vérifiable. |
| VI — Observabilité | ✅ PASS | Aucun `print()`. UI-only. |
| VII — Trajectoire B | ✅ PASS | Flutter UI-only, aucun impact sur la stratégie de distribution. |

### Dérogations

Aucune dérogation.

### Complexity Tracking

Aucune complexité ajoutée. Cette issue réduit la complexité en homogénéisant les tokens et en réutilisant les widgets communs (PageHeader, EmptyStateWidget, ConfirmDialogCustom).

---

## Résumé de l'approche

Alignement token-by-token de 4 fichiers de présentation Flutter sur le design system v5 et les patterns communs introduits dans KKS-238/KKS-246. Chaque fichier modifié reçoit : remplacement de l'`AppBar` générique par `PageHeader`, remplacement des tokens Material bruts par les tokens AppTypography/AppColors/AppThemeExtension, remplacement des `AlertDialog` natifs par `ConfirmDialogCustom`. `CurrencySettingsScreen` bénéficie en plus du remplacement du pattern `Card` par la liste `surface-default` + `border-default` et des boutons `OutlinedButton` par des boutons `+` circulaires 28px dans les headers de section.

---

## Contexte technique

- **Stack** : Dart >= 3.6, Flutter >= 3.27, Riverpod, go_router
- **Dépendances nouvelles** : aucune
- **Dépendances existantes impactées** :
  - `flutter/lib/src/common_widgets/page_header.dart` — `PageHeader(title, onBack, icon)`
  - `flutter/lib/src/common_widgets/empty_state_widget.dart` — `EmptyStateWidget(icon, message, ctaLabel, onCtaTap)`
  - `flutter/lib/src/common_widgets/confirm_dialog_custom.dart` — `ConfirmDialogCustom.show(context, title, message, variant)`
  - `flutter/lib/src/constants/app_typography.dart` — `AppTypography.sizeXs`, `.medium`, `.semiBold`, `.labelLetterSpacingForSize12`
  - `flutter/lib/src/theme/app_theme_extension.dart` — `AppThemeExtension.iconCircleBg`

---

## Architecture

### Structure des fichiers impactés

```
flutter/lib/src/
├── features/
│   ├── categories/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── category_list_screen.dart          (M) PageHeader + EmptyStateWidget
│   │       └── widgets/
│   │           └── category_list_tile.dart            (M) tokens iconCircleBg
│   ├── settings/
│   │   └── presentation/
│   │       └── data_settings_screen.dart              (M) PageHeader + labels + ConfirmDialogCustom
│   └── exchange_rates/
│       └── presentation/
│           └── currency_settings_screen.dart          (M) PageHeader + labels + liste + boutons + ConfirmDialogCustom
```

**Légende** : (M) Modifier. Aucun fichier à créer.

### Tokens de référence

| Token Angular | Token Flutter | Usage |
|---------------|---------------|-------|
| `--text-tertiary` | `colorScheme.onSurfaceVariant` | Labels section uppercase, icônes secondaires |
| `--text-secondary` | `colorScheme.onSurfaceVariant` | Sous-titres, valeurs secondaires |
| `--text-primary` | `colorScheme.onSurface` | Titres, valeurs principales |
| `--surface-default` | `colorScheme.surface` | Fond des conteneurs de liste |
| `--border-default` | `colorScheme.outline` | Séparateurs entre items, border des boutons |
| `--icon-circle-bg` | `themeExt.iconCircleBg` | Fond cercle icône catégorie |
| `--font-size-xs` | `AppTypography.sizeXs` (12px) | Labels section uppercase |
| `--font-weight-medium` | `AppTypography.medium` (w500) | Labels section uppercase |
| `--font-weight-semibold` | `AppTypography.semiBold` (w600) | Titres, valeurs en gras |
| `letter-spacing: 0.5px` | `AppTypography.labelLetterSpacingForSize12` (0.6) | Labels section uppercase |

---

## Approche par composant

### Composant 1 — CategoryListTile

- **Responsabilité** : Tile de liste pour une catégorie (icône emoji + nom + dot couleur)
- **Fichier** : `flutter/lib/src/features/categories/presentation/widgets/category_list_tile.dart`
- **Requirements couverts** : FR-001

**Modifications** :
```dart
// Avant
final colorScheme = Theme.of(context).colorScheme;
// fond icône fallback
color: iconColor?.withValues(alpha: 0.15) ?? colorScheme.surfaceContainerHighest,
// texte nom
color: colorScheme.onSurface,

// Après
final themeExt = Theme.of(context).extension<AppThemeExtension>();
// fond icône fallback → iconCircleBg (6% blanc dark / 4% noir light)
color: iconColor?.withValues(alpha: 0.15) ?? themeExt?.iconCircleBg ?? colorScheme.surface,
// texte nom → déjà correct (onSurface = text-primary) — aucun changement
```

Changement net : 1 ligne (fallback couleur icône).

---

### Composant 2 — CategoryListScreen

- **Responsabilité** : Écran liste des catégories utilisateur
- **Fichier** : `flutter/lib/src/features/categories/presentation/screens/category_list_screen.dart`
- **Requirements couverts** : FR-002, FR-010

**FR-010 — PageHeader** :
Supprimer `appBar: AppBar(...)` du `Scaffold`. Encapsuler le body existant dans une `Column` :
```dart
Scaffold(
  body: SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: PageHeader(
            title: 'Catégories',
            onBack: () => context.pop(),
            icon: const PhosphorIcon(PhosphorIconsRegular.tag, size: 16),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ...,
            child: CustomScrollView(slivers: _buildContent(state, l10n)),
          ),
        ),
      ],
    ),
  ),
  // Conserver le FAB (bouton +) tel quel
)
```

**FR-002 — EmptyStateWidget** :
Remplacer les 2 états ad hoc (`SliverFillRemaining` avec `Column` + `PhosphorIcon` + `Text` + bouton) par `EmptyStateWidget` :
```dart
// État vide
SliverFillRemaining(
  hasScrollBody: false,
  child: EmptyStateWidget(
    icon: PhosphorIconsRegular.tag,
    message: l10n.categoriesEmpty,
  ),
)

// État erreur
SliverFillRemaining(
  hasScrollBody: false,
  child: EmptyStateWidget(
    icon: PhosphorIconsRegular.warning,
    message: l10n.categoryErrorLoad,
    ctaLabel: l10n.categoriesRetry,
    onCtaTap: () => ref.read(categoryNotifierProvider.notifier).refresh(),
  ),
)
```

---

### Composant 3 — DataSettingsScreen

- **Responsabilité** : Configuration mode données (Local/Serveur) + URL serveur
- **Fichier** : `flutter/lib/src/features/settings/presentation/data_settings_screen.dart`
- **Requirements couverts** : FR-003, FR-004, FR-005, FR-010

**FR-010 — PageHeader** :
Supprimer `appBar: AppBar(title: const Text('Données'))`. Dans le body, ajouter `PageHeader` comme premier enfant de `ListView` :
```dart
Scaffold(
  body: SafeArea(
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      children: [
        PageHeader(
          title: 'Données',
          onBack: () => context.pop(),
          icon: const PhosphorIcon(PhosphorIconsRegular.database, size: 16),
        ),
        // reste du contenu inchangé...
      ],
    ),
  ),
)
```

**FR-003 + FR-004 — Labels de section** :
Remplacer `theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)` par le style label uppercase :
```dart
// Avant
Text(
  'Source de données',
  style: theme.textTheme.titleSmall?.copyWith(
    color: theme.colorScheme.primary,
    fontWeight: FontWeight.w600,
  ),
),
// Après
Text(
  'SOURCE DE DONNÉES',
  style: TextStyle(
    fontSize: AppTypography.sizeXs,
    fontWeight: AppTypography.medium,
    letterSpacing: AppTypography.labelLetterSpacingForSize12,
    color: colorScheme.onSurfaceVariant,
  ),
),
```
Appliquer idem pour le label "URL du serveur".

**FR-005 — ConfirmDialogCustom** :
Remplacer le `showDialog<bool>` natif dans `_onModeChanged` :
```dart
// Avant
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Changer de source ?'),
    content: const Text('...'),
    actions: [...],
  ),
);

// Après
final confirmed = await ConfirmDialogCustom.show(
  context: context,
  icon: PhosphorIconsRegular.swapHorizontal,
  title: 'Changer de source ?',
  message: 'Les sources de données sont indépendantes. '
      'Les données de la source actuelle ne seront pas visibles '
      "après le changement.\n\nL'application va redémarrer.",
  confirmLabel: 'Confirmer',
  variant: ConfirmVariant.primary,
) ?? false;
```

---

### Composant 4 — CurrencySettingsScreen

- **Responsabilité** : Configuration des devises actives + taux de conversion + calculateur
- **Fichier** : `flutter/lib/src/features/exchange_rates/presentation/currency_settings_screen.dart`
- **Requirements couverts** : FR-006, FR-007, FR-008, FR-009, FR-010, FR-011

**FR-010 — PageHeader** :
Supprimer `appBar: AppBar(title: const Text('Devises & Taux'))`. Ajouter `PageHeader` en premier item de `ListView` :
```dart
PageHeader(
  title: 'Devises & Taux',
  onBack: () => context.pop(),
  icon: const PhosphorIcon(PhosphorIconsRegular.bank, size: 16),
),
```

**FR-007 — Labels de section** :
Remplacer les 3 labels `theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)` (Mes devises, Taux de conversion, Calculateur) :
```dart
// Pattern uniforme pour les 3 sections
Text(
  'MES DEVISES',   // 'TAUX DE CONVERSION', 'CALCULATEUR'
  style: TextStyle(
    fontSize: AppTypography.sizeXs,
    fontWeight: AppTypography.medium,
    letterSpacing: AppTypography.labelLetterSpacingForSize12,
    color: colorScheme.onSurfaceVariant,
  ),
),
```

**FR-011 — Boutons + circulaires dans headers de section** :
Intégrer les boutons d'ajout dans les headers de section (pattern Angular `add-btn`). Remplacer les `OutlinedButton.icon` en pied de section :
```dart
// Widget privé réutilisable (local au fichier)
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsRegular.plus,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

Header de section restructuré :
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('MES DEVISES', style: _sectionLabelStyle),
    if (availableCurrencies.isNotEmpty)
      _AddButton(onTap: _addCurrency),
  ],
),
```

**FR-006 — Pattern liste sans Card** :
Remplacer `_RateTile` (basé sur `Card`) par un `Container` avec `Divider` :
```dart
// Wrapper de la section taux
Container(
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.xl),
  ),
  child: Column(
    children: [
      for (int i = 0; i < rates.length; i++) ...[
        _RateTile(
          rate: rates[i],
          onEdit: () => _openRateForm(existingRate: rates[i]),
          onDelete: () => _confirmDelete(rates[i]),
        ),
        if (i < rates.length - 1)
          Divider(height: 1, color: colorScheme.outline),
      ],
    ],
  ),
),
```

`_RateTile` rewrite (Row simple, plus de `Card`) :
```dart
class _RateTile extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          // paire de devises
          Expanded(
            child: Text(
              '${rate.baseCurrency.name.toUpperCase()} → ${rate.targetCurrency.name.toUpperCase()}',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // valeur du taux
          Text(
            rate.rate.toStringAsFixed(...),
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          // boutons edit/delete
          IconButton(icon: ..., onPressed: onEdit),
          IconButton(icon: ..., onPressed: onDelete, color: colorScheme.error),
        ],
      ),
    );
  }
}
```

**FR-008 — ConfirmDialogCustom** :
Remplacer les 2 `AlertDialog` natifs :

*Suppression taux :*
```dart
final confirmed = await ConfirmDialogCustom.show(
  context: context,
  icon: PhosphorIconsRegular.trash,
  title: '${rate.baseCurrency.name.toUpperCase()} → ${rate.targetCurrency.name.toUpperCase()}',
  message: 'Ce taux de conversion sera définitivement supprimé.',
  confirmLabel: 'Supprimer',
  variant: ConfirmVariant.danger,
) ?? false;
```

*Retrait devise :*
```dart
final confirmed = await ConfirmDialogCustom.show(
  context: context,
  icon: PhosphorIconsRegular.warning,
  title: 'Retirer ${currency.name.toUpperCase()} ?',
  message: hasAccounts
      ? 'Cette devise est utilisée par des comptes existants.'
      : 'Cette devise sera retirée de vos devises actives.',
  confirmLabel: 'Retirer',
  variant: ConfirmVariant.danger,
) ?? false;
```

---

## Risques et mitigations

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| `PageHeader` dans `CategoryListScreen` avec `CustomScrollView` — conflits layout si la `Column` wrapping n'est pas correctement dimensionnée | Moyen | Bas | Utiliser `Expanded` sur le `RefreshIndicator` + `CustomScrollView`. Tester sur 375px (iPhone SE). |
| `ConfirmDialogCustom` : le paramètre `message` ne supporte pas de `\n` visible si le Dialog n'a pas de wrapping | Bas | Bas | Vérifier le rendu avec un texte long avant commit. |
| `_RateTile` rewrite — le `fontFeatures: [FontFeature.tabularFigures()]` peut ne pas être supporté par la police Inter | Bas | Bas | Si non supporté, retirer `fontFeatures` — le rendu reste correct. |
| `CurrencySettingsScreen` restructuré — les boutons + dans les headers peuvent ne pas déclencher `_addCurrency` si le `GestureDetector` est dans un scroll | Bas | Bas | `GestureDetector` fonctionne indépendamment du scroll parent. Tester sur device. |

---

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | — | Non | Recherche réalisée implicitement lors des phases spec/clarify (lecture code Angular + Flutter) |
| Data Model | — | Non | Aucune entité modifiée — UI-only |
| Quickstart | [quickstart.md](./quickstart.md) | Oui | Guide de validation des 3 écrans |

---

## Hors scope

- Toute modification de la couche data (notifiers, repositories, modèles Freezed, fichiers `.g.dart`)
- La route `/settings/accounts` et l'écran `AccountListScreen` (KKS-255 déjà livré)
- Le widget `RateCalculator` (FR-009 — conserver sans modification)
- Les formulaires d'édition de catégorie (`CategoryFormScreen`) et de taux (`RateForm`)
- Les tests widget exhaustifs (à déléguer à `test-qa` si demandé)
- Toute modification côté Angular ou backend
